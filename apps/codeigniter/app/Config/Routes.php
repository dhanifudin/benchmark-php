<?php

use CodeIgniter\Router\RouteCollection;

/** @var RouteCollection $routes */
$routes->get('/', 'Benchmark::hello');
$routes->get('healthz', 'Benchmark::healthz');
$routes->get('hello', 'Benchmark::hello');
$routes->get('json', 'Benchmark::json');
$routes->get('db-read', 'Benchmark::dbRead');
$routes->get('db-read-cache-warm', 'Benchmark::dbReadCacheWarm');
$routes->get('db-list', 'Benchmark::dbList');
$routes->get('db-list-cache-warm', 'Benchmark::dbListCacheWarm');
$routes->get('compute', 'Benchmark::compute');
$routes->get('template', 'Benchmark::template');
$routes->get('middleware', 'Benchmark::middleware');
