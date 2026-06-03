# Benchmark Contract

This document freezes the initial benchmark contract for repository scaffolding and the first pilot implementation.

## Naming

Each benchmark case must be uniquely identified by:

1. framework
2. PHP version
3. runtime family
4. runtime
5. runtime config
6. scenario
7. code form
8. repetition

Recommended case id format:

`<framework>__<php-version>__<runtime>__<runtime-config>__<scenario>__<code-form>__r<repetition>`

Example:

`laravel__8.4__php-fpm__opcache__db-read-cache-warm__plain__r3`

Profiles should also declare a PHP tier so benchmark campaigns can be grouped by support intent:

1. `latest`
2. `modern-lts`
3. `legacy-lts`
4. `custom`

## Canonical Enums

Frameworks:

1. `native`
2. `laravel`
3. `codeigniter`

PHP version tiers:

1. `latest` -> PHP `8.4`
2. `modern-lts` -> PHP `8.3`
3. `legacy-lts` -> PHP `7.4`

Framework version pins:

1. `latest` uses the latest supported framework releases on PHP `8.4`
2. `modern-lts` uses the latest supported framework releases on PHP `8.3`
3. `legacy-lts` uses Laravel `8.x` latest patch because Laravel `9+` requires PHP `8.0+`

Runtime families:

1. `classic`
2. `persistent`

Runtimes:

1. `mod_php`
2. `php-fpm`
3. `frankenphp-classic`
4. `frankenphp-worker`
5. `roadrunner`
6. `swoole`

Code forms:

1. `plain`
2. `obfuscated-supported-minimal`
3. `obfuscated-supported-maximal`

Main runtime configs:

1. `baseline`
2. `opcache`
3. `opcache-jit-tracing`

Extended classic runtime configs:

1. `opcache-jit-function`
2. `opcache-preload`
3. `opcache-preload-jit-tracing`

Scenarios:

1. `hello`
2. `json`
3. `db-read`
4. `db-list`
5. `db-read-cache-warm`
6. `db-list-cache-warm`
7. `compute`
8. `template`
9. `middleware`
10. `db-read-cache-cold`
11. `db-list-cache-cold`

Cache states:

1. `none`
2. `cold`
3. `warm`

## Machine-Readable Sources

The contract is implemented in:

1. `config/schemas/benchmark-profile.schema.json`
2. `config/schemas/raw-run.schema.json`
3. `config/schemas/processed-results.schema.json`
4. `config/profiles/pilot.yaml`
5. `config/profiles/latest.yaml`
6. `config/profiles/modern-lts.yaml`
7. `config/profiles/legacy-lts.yaml`

These files are the source of truth for the first implementation phase.
