<?php

declare(strict_types=1);

use OpenSwoole\Http\Request as SwooleRequest;
use OpenSwoole\Http\Response as SwooleResponse;
use OpenSwoole\Http\Server;

$port = (int) (getenv('SWOOLE_PORT') ?: 80);

$server = new Server('0.0.0.0', $port);
$server->set([
    'worker_num' => 4,
    'max_request' => 0,
]);

$server->on('request', function (SwooleRequest $swooleRequest, SwooleResponse $swooleResponse): void {
    try {
        $env = [];
        $env['REQUEST_METHOD'] = $swooleRequest->server['request_method'] ?? 'GET';
        $env['REQUEST_URI'] = $swooleRequest->server['request_uri'] ?? '/';
        $env['QUERY_STRING'] = $swooleRequest->server['query_string'] ?? '';
        $env['SERVER_PROTOCOL'] = 'HTTP/1.1';
        $env['HTTP_HOST'] = $swooleRequest->header['host'] ?? 'localhost';
        $env['SCRIPT_FILENAME'] = '/app/public/index.php';
        $env['SCRIPT_NAME'] = '/index.php';
        $env['DOCUMENT_ROOT'] = '/app/public';
        $env['CI_ENVIRONMENT'] = getenv('CI_ENVIRONMENT') ?: 'production';
        $env['argv'] = ['index.php', $env['REQUEST_URI']];
        $env['argc'] = 2;
        $env['DB_HOST'] = getenv('DB_HOST') ?: 'mariadb';
        $env['DB_DATABASE'] = getenv('DB_DATABASE') ?: 'benchmark_php';
        $env['DB_USERNAME'] = getenv('DB_USERNAME') ?: 'benchmark';
        $env['DB_PASSWORD'] = getenv('DB_PASSWORD') ?: 'benchmark';
        $env['DB_DRIVER'] = getenv('DB_DRIVER') ?: 'MySQLi';
        $env['DB_PORT'] = getenv('DB_PORT') ?: '3306';
        $env['REDIS_HOST'] = getenv('REDIS_HOST') ?: 'redis';
        $env['REDIS_PORT'] = getenv('REDIS_PORT') ?: '6379';
        $env['app.baseURL'] = getenv('app.baseURL') ?: 'http://codeigniter-swoole/';

        foreach (($swooleRequest->header ?? []) as $name => $value) {
            $key = 'HTTP_' . strtoupper(str_replace('-', '_', (string) $name));
            $env[$key] = (string) $value;
        }

        $descriptors = [
            0 => ['pipe', 'r'],
            1 => ['pipe', 'w'],
            2 => ['pipe', 'w'],
        ];

        $process = proc_open(
            ['php', '/app/public/index.php'],
            $descriptors,
            $pipes,
            '/app/public',
            $env
        );

        if (!is_resource($process)) {
            throw new RuntimeException('Failed to start PHP process');
        }

        fclose($pipes[0]);

        $output = stream_get_contents($pipes[1]);
        $errorOutput = stream_get_contents($pipes[2]);

        fclose($pipes[1]);
        fclose($pipes[2]);

        $exitCode = proc_close($process);

        if ($exitCode !== 0 && $exitCode !== -1) {
            $swooleResponse->status(500);
            $swooleResponse->header('Content-Type', 'application/json');
            $swooleResponse->end(json_encode([
                'error' => 'process_error',
                'exit_code' => $exitCode,
                'stderr' => substr((string) $errorOutput, 0, 500),
            ]));
            return;
        }

        $output = (string) $output;

        $status = 200;
        $headers = [];

        while (true) {
            $pos = strpos($output, "\r\n\r\n");
            if ($pos === false) break;

            $headerPart = substr($output, 0, $pos);
            $output = substr($output, $pos + 4);

            foreach (explode("\r\n", $headerPart) as $line) {
                if (stripos($line, 'HTTP/') === 0) {
                    $parts = explode(' ', $line, 3);
                    $status = (int) ($parts[1] ?? 200);
                    continue;
                }
                $colonPos = strpos($line, ':');
                if ($colonPos !== false) {
                    $name = trim(substr($line, 0, $colonPos));
                    $value = trim(substr($line, $colonPos + 1));
                    if (!in_array(strtolower($name), ['content-length', 'transfer-encoding', 'connection'])) {
                        $swooleResponse->header($name, $value);
                    }
                }
            }
            break;
        }

        $swooleResponse->status($status);
        $swooleResponse->end($output);
    } catch (Throwable $exception) {
        $swooleResponse->status(500);
        $swooleResponse->header('Content-Type', 'application/json');
        $swooleResponse->end(json_encode([
            'error' => 'internal_error',
            'message' => $exception->getMessage(),
        ]));
    }
});

$server->start();
