# Implementation Status

**Last updated**: 2026-06-03 07:51 UTC
**Total**: 178 cells, 207 runs

## Scenario Coverage (out of 11)
| Framework | Runtime | Config | Code Form | Coverage |
|-----------|---------|--------|-----------|----------|
| codeigniter | php-fpm                | baseline | obfuscated-supported-minimal   |  6/11 ███ |
| codeigniter | php-fpm                | opcache | obfuscated-supported-minimal   |  6/11 ███ |
| codeigniter | php-fpm                | baseline | plain                          |  9/11 ████▌ |
| codeigniter | php-fpm                | opcache | plain                          |  9/11 ████▌ |
| laravel   | php-fpm                | baseline | obfuscated-supported-minimal   |  6/11 ███ |
| laravel   | php-fpm                | opcache | obfuscated-supported-minimal   |  6/11 ███ |
| laravel   | php-fpm                | baseline | plain                          |  9/11 ████▌ |
| laravel   | php-fpm                | opcache | plain                          |  9/11 ████▌ |
| laravel   | swoole                 | baseline | plain                          |  6/11 ███ |
| native    | frankenphp-classic     | baseline | plain                          |  6/11 ███ |
| native    | frankenphp-classic     | opcache | plain                          |  6/11 ███ |
| native    | frankenphp-worker      | baseline | plain                          |  6/11 ███ |
| native    | frankenphp-worker      | opcache | plain                          |  6/11 ███ |
| native    | mod_php                | baseline | plain                          |  9/11 ████▌ |
| native    | mod_php                | opcache | plain                          |  6/11 ███ |
| native    | php-fpm                | baseline | obfuscated-supported-maximal   |  6/11 ███ |
| native    | php-fpm                | baseline | obfuscated-supported-minimal   |  6/11 ███ |
| native    | php-fpm                | opcache | obfuscated-supported-minimal   |  6/11 ███ |
| native    | php-fpm                | baseline | plain                          | 11/11 █████▌ |
| native    | php-fpm                | opcache | plain                          | 11/11 █████▌ |
| native    | php-fpm                | opcache-jit-tracing | plain                          |  3/11 █▌ |
| native    | roadrunner             | baseline | plain                          |  9/11 ████▌ |
| native    | roadrunner             | opcache | plain                          |  6/11 ███ |
| native    | swoole                 | baseline | plain                          |  9/11 ████▌ |
| native    | swoole                 | opcache | plain                          |  6/11 ███ |

## Remaining Gaps
- Cold-cache (db-read-cache-cold, db-list-cache-cold): missing on most non-native targets
- Extended scenarios on obfuscated code forms: low priority
- JIT tracing: native plain only (3/11)
- Framework runtimes beyond php-fpm: Laravel Swoole Octane done, CI incompatible