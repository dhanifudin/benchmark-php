<?php

declare(strict_types=1);

use Nyholm\Psr7\Factory\Psr17Factory;
use Spiral\RoadRunner\Http\PSR7Worker;
use Spiral\RoadRunner\Worker;

require __DIR__ . '/../src/bootstrap.php';
require __DIR__ . '/vendor/autoload.php';

try {
    $factory = new Psr17Factory();
    $worker = new PSR7Worker(
        Worker::create(),
        $factory,
        $factory,
        $factory,
    );

    while ($request = $worker->waitRequest()) {
        try {
            $_SERVER['REQUEST_METHOD'] = $request->getMethod();
            $_SERVER['REQUEST_URI'] = (string) $request->getUri();
            $_SERVER['QUERY_STRING'] = $request->getUri()->getQuery();
            $_SERVER['SERVER_PROTOCOL'] = 'HTTP/1.1';
            $_SERVER['HTTP_HOST'] = $request->getUri()->getHost();

            foreach ($request->getHeaders() as $name => $values) {
                $key = 'HTTP_' . strtoupper(str_replace('-', '_', $name));
                $_SERVER[$key] = implode(', ', $values);
            }

            ob_start();
            app_handle_request();
            $body = ob_get_clean();
            $status = http_response_code() ?: 200;

            $response = $factory->createResponse($status);
            $response->getBody()->write($body);

            foreach (headers_list() as $headerLine) {
                $parts = explode(':', $headerLine, 2);
                if (count($parts) === 2) {
                    $response = $response->withHeader(trim($parts[0]), trim($parts[1]));
                }
            }

            $worker->respond($response);
        } catch (Throwable $exception) {
            $response = $factory->createResponse(500);
            $response->getBody()->write(json_encode([
                'error' => 'internal_error',
                'message' => $exception->getMessage(),
            ]));
            $worker->respond($response);
        }
    }
} catch (Throwable $e) {
    $response = (new Psr17Factory())->createResponse(500);
    $response->getBody()->write(json_encode([
        'error' => 'worker_startup_error',
        'message' => $e->getMessage(),
    ]));
    file_put_contents('php://stderr', 'Worker error: ' . $e->getMessage() . "\n");
}
