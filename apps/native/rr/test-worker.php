<?php
// Minimal test worker
file_put_contents('/tmp/rr-test.log', 'worker started' . PHP_EOL, FILE_APPEND);
while (true) {
    sleep(1);
}
