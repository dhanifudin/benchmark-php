<?php

declare(strict_types=1);

require __DIR__ . '/src/bootstrap.php';

use OpenSwoole\Http\Server;
use OpenSwoole\Http\Request;
use OpenSwoole\Http\Response;

$port = (int) (getenv('SWOOLE_PORT') ?: 80);

$server = new Server('0.0.0.0', $port);

$server->set([
    'worker_num' => 4,
    'max_request' => 0,
]);

$server->on('request', function (Request $request, Response $response): void {
    try {
        $_SERVER['REQUEST_METHOD'] = $request->server['request_method'] ?? 'GET';
        $_SERVER['REQUEST_URI'] = $request->server['request_uri'] ?? '/';
        $_SERVER['QUERY_STRING'] = $request->server['query_string'] ?? '';
        $_SERVER['SERVER_PROTOCOL'] = 'HTTP/1.1';
        $_SERVER['HTTP_HOST'] = $request->header['host'] ?? 'localhost';

        foreach (($request->header ?? []) as $name => $value) {
            $key = 'HTTP_' . strtoupper(str_replace('-', '_', (string) $name));
            $_SERVER[$key] = (string) $value;
        }

        ob_start();
        app_handle_request();

        $output = ob_get_clean();
        $status = http_response_code() ?: 200;

        $response->status($status);

        foreach (headers_list() as $headerLine) {
            $parts = explode(':', $headerLine, 2);

            if (count($parts) === 2) {
                $response->header(trim($parts[0]), trim($parts[1]));
            }
        }

        $response->end($output);
    } catch (Throwable $exception) {
        $response->status(500);
        $response->header('Content-Type', 'application/json');
        $response->end(json_encode([
            'error' => 'internal_error',
            'message' => $exception->getMessage(),
        ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
    }
});

$server->start();
