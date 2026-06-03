<?php

declare(strict_types=1);

use Illuminate\Http\Request;
use OpenSwoole\Http\Request as SwooleRequest;
use OpenSwoole\Http\Response as SwooleResponse;
use OpenSwoole\Http\Server;
use Symfony\Component\HttpFoundation\Request as SymfonyRequest;

require __DIR__ . '/../vendor/autoload.php';

$app = require_once __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);

$port = (int) (getenv('SWOOLE_PORT') ?: 80);

$server = new Server('0.0.0.0', $port);
$server->set([
    'worker_num' => 4,
    'max_request' => 0,
]);

$server->on('request', function (SwooleRequest $swooleRequest, SwooleResponse $swooleResponse) use ($kernel, $app): void {
    try {
        $symfonyRequest = new SymfonyRequest(
            $swooleRequest->get ?? [],
            $swooleRequest->post ?? [],
            [],
            $swooleRequest->cookie ?? [],
            $swooleRequest->files ?? [],
            array_merge($swooleRequest->server ?? [], [
                'REQUEST_METHOD' => $swooleRequest->server['request_method'] ?? 'GET',
                'REQUEST_URI' => $swooleRequest->server['request_uri'] ?? '/',
                'QUERY_STRING' => $swooleRequest->server['query_string'] ?? '',
                'SERVER_PROTOCOL' => 'HTTP/1.1',
            ]),
            $swooleRequest->rawContent() ?: null
        );

        foreach (($swooleRequest->header ?? []) as $name => $value) {
            $symfonyRequest->headers->set($name, $value);
        }

        $request = Request::createFromBase($symfonyRequest);
        $laravelResponse = $kernel->handle($request);

        $swooleResponse->status($laravelResponse->getStatusCode());

        foreach ($laravelResponse->headers->allPreserveCaseWithoutCookies() as $name => $values) {
            foreach ($values as $value) {
                $swooleResponse->header($name, $value);
            }
        }

        $swooleResponse->end($laravelResponse->getContent());

        $kernel->terminate($request, $laravelResponse);
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
