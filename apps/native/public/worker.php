<?php

declare(strict_types=1);

require __DIR__ . '/../src/bootstrap.php';

$handler = static function (): void {
    app_handle_request();
};

$maxRequests = (int) ($_SERVER['MAX_REQUESTS'] ?? 0);
for ($handled = 0; !$maxRequests || $handled < $maxRequests; ++$handled) {
    $keepRunning = frankenphp_handle_request($handler);

    gc_collect_cycles();

    if (!$keepRunning) {
        break;
    }
}
