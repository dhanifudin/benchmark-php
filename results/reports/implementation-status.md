# Implementation Status

**Last updated**: 2026-06-03 20:43 UTC
**Total**: 228 cells, 294 runs

## Scenario Coverage (out of 15)

| Framework | Runtime | Config | Code Form | Coverage |
|-----------|---------|--------|-----------|----------|
| native | php-fpm | baseline | plain | 15/15 ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ |
| native | php-fpm | opcache | plain | 13/15 ▓▓▓▓▓▓▓▓▓▓▓▓▓░░ |
| native | mod_php | baseline | plain | 13/15 ▓▓▓▓▓▓▓▓▓▓▓▓▓░░ |
| native | swoole | baseline | plain | 13/15 ▓▓▓▓▓▓▓▓▓▓▓▓▓░░ |
| native | roadrunner | baseline | plain | 11/15 ▓▓▓▓▓▓▓▓▓▓▓░░░░ |
| native | frankenphp-classic | baseline + opcache | plain | 13/15 ▓▓▓▓▓▓▓▓▓▓▓▓▓░░ |
| native | frankenphp-worker | baseline + opcache | plain | 13/15 ▓▓▓▓▓▓▓▓▓▓▓▓▓░░ |
| laravel | php-fpm | baseline + opcache | plain | 13/15 ▓▓▓▓▓▓▓▓▓▓▓▓▓░░ |
| codeigniter | php-fpm | baseline + opcache | plain | 13/15 ▓▓▓▓▓▓▓▓▓▓▓▓▓░░ |

## Multi-Rep Validation (n≥5)

| Cell | RSD |
|---|---|
| swoole × hello | 2.0% |
| swoole × db-read | 0.2% |
| php-fpm × db-create | 1.4% |
| php-fpm × json | 4.8% |
| php-fpm × hello | 15.6% |
| mod_php × hello | 18.1% |
| php-fpm × db-read | 19.6% |
| mod_php × db-read | 35.9% |

## New in v2

| Item | Status |
|---|---|
| Matrix runner (multi-runtime, profile-driven) | Done |
| Aggregation script (median, stdev, RSD, IQR) | Done |
| DB seed reset for write benchmarks | Done |
| 4 CRUD scenarios across 3 frameworks | Done |
| 35 multi-rep runs across 3 runtimes | Done |
| Container telemetry | Not started |
| Concurrency-level benchmarks (8/32/128) | Not started |

## Remaining

| Item | Status |
|---|---|
| Multi-PHP-version for frameworks | Not started |
| Maximal obfuscation for frameworks | Not started |
| Full multi-rep for all cells | 8 cells with n≥5 |
| RoadRunner + Swoole framework targets | Laravel Swoole Octane done |
| JIT tracing full coverage | 3/15 |
