<?php

declare(strict_types=1);

function env_value(string $key, ?string $default = null): ?string
{
    $value = $_ENV[$key] ?? $_SERVER[$key] ?? getenv($key);

    if ($value === false || $value === null || $value === '') {
        return $default;
    }

    return (string) $value;
}

function app_metadata(): array
{
    return [
        'framework' => 'native',
        'framework_version' => env_value('BENCHMARK_FRAMEWORK_VERSION', 'plain-php'),
        'php_version' => PHP_VERSION,
    ];
}

function db_connection(): PDO
{
    static $pdo = null;

    if ($pdo instanceof PDO) {
        return $pdo;
    }

    $dsn = sprintf(
        'mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',
        env_value('DB_HOST', 'mariadb'),
        env_value('DB_PORT', '3306'),
        env_value('DB_DATABASE', 'benchmark_php')
    );

    $pdo = new PDO(
        $dsn,
        env_value('DB_USERNAME', 'benchmark'),
        env_value('DB_PASSWORD', 'benchmark'),
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]
    );

    return $pdo;
}

function redis_connection(): Redis
{
    static $redis = null;

    if ($redis instanceof Redis) {
        return $redis;
    }

    $redis = new Redis();
    $redis->connect(
        env_value('REDIS_HOST', 'redis'),
        (int) env_value('REDIS_PORT', '6379')
    );

    return $redis;
}

function json_response(array $payload, int $status = 200, array $headers = []): void
{
    http_response_code($status);
    header('Content-Type: application/json');

    foreach ($headers as $name => $value) {
        header($name . ': ' . $value);
    }

    echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
}

function text_response(string $body, int $status = 200, array $headers = []): void
{
    http_response_code($status);
    header('Content-Type: text/plain; charset=utf-8');

    foreach ($headers as $name => $value) {
        header($name . ': ' . $value);
    }

    echo $body;
}

function fetch_user_by_id(int $id): array
{
    $statement = db_connection()->prepare(
        'SELECT id, name, email, country_code, created_at FROM users WHERE id = :id LIMIT 1'
    );
    $statement->execute(['id' => $id]);

    $user = $statement->fetch();

    if (!is_array($user)) {
        throw new RuntimeException('User not found');
    }

    return $user;
}

function fetch_posts_list(): array
{
    $statement = db_connection()->query(
        'SELECT id, user_id, title, body, is_published, created_at FROM posts ORDER BY created_at DESC LIMIT 20'
    );

    return $statement->fetchAll();
}

function app_handle_request(): void
{
    $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
    $path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';

    if ($method !== 'GET') {
        json_response([
            'error' => 'method_not_allowed',
        ], 405);
        return;
    }

    try {
        switch ($path) {
            case '/healthz':
                text_response('ok');
                return;

            case '/hello':
                text_response('hello world');
                return;

            case '/json':
                json_response([
                    'meta' => app_metadata(),
                    'data' => [
                        'message' => 'hello world',
                        'numbers' => [1, 2, 3, 4, 5],
                        'active' => true,
                    ],
                ]);
                return;

            case '/db-read':
                json_response([
                    'meta' => app_metadata(),
                    'data' => [
                        'user' => fetch_user_by_id(1),
                        'cache' => 'none',
                    ],
                ]);
                return;

            case '/db-read-cache-warm':
                $cacheKey = 'benchmark:db-read:user:1';
                $redis = redis_connection();
                $cached = $redis->get($cacheKey);

                if (is_string($cached) && $cached !== '') {
                    $payload = json_decode($cached, true);
                    if (is_array($payload)) {
                        json_response($payload, 200, ['X-Cache' => 'HIT']);
                        return;
                    }
                }

                $payload = [
                    'meta' => app_metadata(),
                    'data' => [
                        'user' => fetch_user_by_id(1),
                        'cache' => 'warm',
                    ],
                ];

                $redis->setex($cacheKey, 3600, json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
                json_response($payload, 200, ['X-Cache' => 'MISS']);
                return;

            case '/db-list':
                json_response([
                    'meta' => app_metadata(),
                    'data' => [
                        'posts' => fetch_posts_list(),
                        'cache' => 'none',
                    ],
                ]);
                return;

            case '/db-list-cache-warm':
                $listCacheKey = 'benchmark:db-list:posts:20';
                $redis = redis_connection();
                $cached = $redis->get($listCacheKey);

                if (is_string($cached) && $cached !== '') {
                    $payload = json_decode($cached, true);
                    if (is_array($payload)) {
                        json_response($payload, 200, ['X-Cache' => 'HIT']);
                        return;
                    }
                }

                $payload = [
                    'meta' => app_metadata(),
                    'data' => [
                        'posts' => fetch_posts_list(),
                        'cache' => 'warm',
                    ],
                ];

                $redis->setex($listCacheKey, 3600, json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
                json_response($payload, 200, ['X-Cache' => 'MISS']);
                return;

            case '/compute':
                $result = 0;
                for ($i = 0; $i < 1000; $i++) {
                    $result += sqrt($i) * sin($i) * cos($i) + pow($i % 100, 2) + log($i + 1);
                }
                json_response([
                    'meta' => app_metadata(),
                    'data' => ['result' => round($result, 4), 'iterations' => 1000],
                ]);
                return;

            case '/template':
                header('Content-Type: text/html; charset=utf-8');
                echo '<!DOCTYPE html><html><head><title>Benchmark</title></head>'
                    . '<body><h1>Benchmark PHP</h1><p>Native template rendered.</p>'
                    . '<ul><li>Item 1</li><li>Item 2</li><li>Item 3</li></ul>'
                    . '<p>PHP ' . PHP_VERSION . '</p></body></html>';
                return;

            case '/middleware':
                $started = hrtime(true);
                $context = ['request_id' => uniqid('req-', true), 'steps' => 3];
                json_response([
                    'meta' => app_metadata(),
                    'data' => [
                        'context' => $context,
                        'elapsed_ns' => hrtime(true) - $started,
                    ],
                ]);
                return;

            default:
                json_response([
                    'error' => 'not_found',
                    'path' => $path,
                ], 404);
                return;
        }
    } catch (Throwable $exception) {
        json_response([
            'error' => 'internal_error',
            'message' => $exception->getMessage(),
        ], 500);
    }
}
