<?php

namespace App\Controllers;

use CodeIgniter\Database\BaseConnection;
use CodeIgniter\HTTP\ResponseInterface;
use Config\Database;
use Redis;
use RuntimeException;
use Throwable;

class Benchmark extends BaseController
{
    private ?BaseConnection $database = null;
    private ?Redis $redis = null;

    public function healthz(): ResponseInterface
    {
        return $this->response
            ->setStatusCode(200)
            ->setContentType('text/plain', 'utf-8')
            ->setBody('ok');
    }

    public function hello(): ResponseInterface
    {
        return $this->response
            ->setStatusCode(200)
            ->setContentType('text/plain', 'utf-8')
            ->setBody('hello world');
    }

    public function json(): ResponseInterface
    {
        return $this->response->setJSON([
            'meta' => $this->metadata(),
            'data' => [
                'message' => 'hello world',
                'numbers' => [1, 2, 3, 4, 5],
                'active' => true,
            ],
        ]);
    }

    public function dbRead(): ResponseInterface
    {
        try {
            return $this->response->setJSON([
                'meta' => $this->metadata(),
                'data' => [
                    'user' => $this->fetchBenchmarkUser(),
                    'cache' => 'none',
                ],
            ]);
        } catch (Throwable $exception) {
            return $this->errorResponse($exception);
        }
    }

    public function dbReadCacheWarm(): ResponseInterface
    {
        try {
            $cacheKey = 'benchmark:db-read:user:1';
            $cached = $this->redis()->get($cacheKey);

            if (is_string($cached) && $cached !== '') {
                $payload = json_decode($cached, true);

                if (is_array($payload)) {
                    return $this->response
                        ->setHeader('X-Cache', 'HIT')
                        ->setJSON($payload);
                }
            }

            $payload = [
                'meta' => $this->metadata(),
                'data' => [
                    'user' => $this->fetchBenchmarkUser(),
                    'cache' => 'warm',
                ],
            ];

            $this->redis()->setex($cacheKey, 3600, json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));

            return $this->response
                ->setHeader('X-Cache', 'MISS')
                ->setJSON($payload);
        } catch (Throwable $exception) {
            return $this->errorResponse($exception);
        }
    }

    public function dbList(): ResponseInterface
    {
        try {
            return $this->response->setJSON([
                'meta' => $this->metadata(),
                'data' => [
                    'posts' => $this->fetchPostsList(),
                    'cache' => 'none',
                ],
            ]);
        } catch (Throwable $exception) {
            return $this->errorResponse($exception);
        }
    }

    public function dbListCacheWarm(): ResponseInterface
    {
        try {
            $listCacheKey = 'benchmark:db-list:posts:20';
            $cached = $this->redis()->get($listCacheKey);

            if (is_string($cached) && $cached !== '') {
                $payload = json_decode($cached, true);

                if (is_array($payload)) {
                    return $this->response
                        ->setHeader('X-Cache', 'HIT')
                        ->setJSON($payload);
                }
            }

            $payload = [
                'meta' => $this->metadata(),
                'data' => [
                    'posts' => $this->fetchPostsList(),
                    'cache' => 'warm',
                ],
            ];

            $this->redis()->setex($listCacheKey, 3600, json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));

            return $this->response
                ->setHeader('X-Cache', 'MISS')
                ->setJSON($payload);
        } catch (Throwable $exception) {
            return $this->errorResponse($exception);
        }
    }

    private function metadata(): array
    {
        return [
            'framework' => 'codeigniter',
            'framework_version' => \CodeIgniter\CodeIgniter::CI_VERSION,
            'php_version' => PHP_VERSION,
        ];
    }

    private function fetchBenchmarkUser(): array
    {
        $row = $this->db()
            ->table('users')
            ->select(['id', 'name', 'email', 'country_code', 'created_at'])
            ->where('id', 1)
            ->get()
            ->getRowArray();

        if (!is_array($row)) {
            throw new RuntimeException('User not found');
        }

        return $row;
    }

    private function fetchPostsList(): array
    {
        return $this->db()
            ->table('posts')
            ->select(['id', 'user_id', 'title', 'body', 'is_published', 'created_at'])
            ->orderBy('created_at', 'desc')
            ->limit(20)
            ->get()
            ->getResultArray();
    }

    private function db(): BaseConnection
    {
        if ($this->database instanceof BaseConnection) {
            return $this->database;
        }

        $this->database = Database::connect();

        return $this->database;
    }

    private function redis(): Redis
    {
        if ($this->redis instanceof Redis) {
            return $this->redis;
        }

        $redis = new Redis();
        $redis->connect(
            (string) env('REDIS_HOST', 'redis'),
            (int) env('REDIS_PORT', 6379)
        );

        $this->redis = $redis;

        return $this->redis;
    }

    private function errorResponse(Throwable $exception): ResponseInterface
    {
        return $this->response
            ->setStatusCode(500)
            ->setJSON([
                'error' => 'internal_error',
                'message' => $exception->getMessage(),
            ]);
    }

    public function compute(): ResponseInterface
    {
        $result = 0;
        for ($i = 0; $i < 1000; $i++) {
            $result += sqrt($i) * sin($i) * cos($i) + pow($i % 100, 2) + log($i + 1);
        }
        return $this->response->setJSON([
            'meta' => $this->metadata(),
            'data' => ['result' => round($result, 4), 'iterations' => 1000],
        ]);
    }

    public function template(): ResponseInterface
    {
        return $this->response
            ->setStatusCode(200)
            ->setContentType('text/html', 'utf-8')
            ->setBody('<!DOCTYPE html><html><head><title>Benchmark</title></head>'
                . '<body><h1>Benchmark PHP</h1><p>CI template rendered.</p>'
                . '<ul><li>Item 1</li><li>Item 2</li><li>Item 3</li></ul>'
                . '<p>PHP ' . PHP_VERSION . '</p></body></html>');
    }

    public function middleware(): ResponseInterface
    {
        $started = hrtime(true);
        return $this->response->setJSON([
            'meta' => $this->metadata(),
            'data' => [
                'context' => ['request_id' => uniqid('req-', true), 'steps' => 3],
                'elapsed_ns' => hrtime(true) - $started,
            ],
        ]);
    }
}
