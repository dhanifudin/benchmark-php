# Benchmark PHP Implementation Plan

## Scope

Framework targets:

1. `native`
2. `laravel`
3. `codeigniter`

Runtime families:

1. Classic runtimes
   - `mod_php`
   - `php-fpm`
   - `frankenphp-classic`
2. Persistent runtimes
   - `frankenphp-worker`
   - `roadrunner`
   - `swoole`

Data stack:

1. `MariaDB`
2. `Redis`

Obfuscator:

1. `YAK Pro`

Load generator:

1. `wrk`

Configuration model:

1. Version-controlled YAML benchmark profiles
2. `.env` local overrides for machine-specific values

PHP version-tier profiles:

1. `latest` -> PHP `8.4`
2. `modern-lts` -> PHP `8.3`
3. `legacy-lts` -> PHP `7.4`

## Study Positioning

This study benchmarks obfuscated and non-obfuscated PHP web applications using frameworks selected for Indonesian ecosystem relevance: Laravel, CodeIgniter, and native PHP. Performance is evaluated across classic and persistent PHP runtimes under stateless and data-backed HTTP workloads.

Docker is the benchmark control plane. Every benchmark case must be reproducible from container images, a benchmark profile, runtime configuration, dataset version, and obfuscation manifest.

The benchmark uses version-tier profiles rather than a single monolithic PHP-version matrix. This keeps the modern study comparable while allowing a separate legacy profile for still-common PHP 7.4 deployments in Indonesia.

## Version Profiles

Main study profiles:

1. `modern-lts`
   - PHP `8.3`
   - latest supported Laravel and CodeIgniter versions on PHP `8.3`
2. `latest`
   - PHP `8.4`
   - latest supported Laravel and CodeIgniter versions on PHP `8.4`

Legacy study profile:

1. `legacy-lts`
   - PHP `7.4`
   - Laravel `8.x` latest patch
   - latest CodeIgniter version that still supports PHP `7.4`
   - runtime scope intentionally reduced to `mod_php` and `php-fpm` by default

## Scenario Set

Main scenarios:

1. `hello`
2. `json`
3. `db-read`
4. `db-list`
5. `db-read-cache-warm`
6. `db-list-cache-warm`

Extended scenarios:

1. `compute`
2. `template`
3. `middleware`
4. `db-read-cache-cold`
5. `db-list-cache-cold`

## Obfuscation Profiles

1. `plain`
2. `obfuscated-supported-minimal`
3. `obfuscated-supported-maximal` later

Validation must be performed per:

1. framework
2. runtime
3. obfuscation profile

## Runtime Configurations

Main study:

1. Classic runtimes
   - `baseline`
   - `opcache`
   - `opcache-jit-tracing`
2. Persistent runtimes
   - `baseline`
   - `opcache`

Extended study:

1. Classic runtimes
   - `opcache-jit-function`
   - `opcache-preload`
   - `opcache-preload-jit-tracing`

## Main Matrix

Dimensions per main profile:

1. 3 frameworks
2. 6 runtimes
3. 2 code forms
4. 6 main scenarios
5. 15 runtime-config combinations

Total per main profile:

1. `3 x 2 x 6 x 15 = 540 benchmark cases`
2. With 5 repetitions: `2700 runs`

The full modern study is executed by running both `modern-lts` and `latest` profiles separately.

## Pilot Matrix

1. Frameworks
   - `native`
   - `laravel`
   - `codeigniter`
2. Runtime
   - `php-fpm`
3. Runtime configs
   - `baseline`
   - `opcache`
4. Code forms
   - `plain`
   - `obfuscated-supported-minimal`
5. Scenarios
   - `hello`
   - `json`
   - `db-read`
   - `db-read-cache-warm`

Total:

1. `3 x 1 x 2 x 2 x 4 = 48 cases`
2. With 5 repetitions: `240 runs`

## Docker-First Architecture

The benchmark should run entirely through Docker so benchmark campaigns are reproducible and configurable without changing application code.

Core containers:

1. app/runtime container for the selected target
2. `MariaDB` container
3. `Redis` container
4. `wrk` runner container
5. optional collector/analyzer container

Control flow per case:

1. select benchmark profile
2. compose required services
3. seed MariaDB
4. reset or warm Redis depending on scenario state
5. boot target runtime
6. run verification
7. run `wrk`
8. export raw results with config metadata
9. reset or tear down before next case

## Configuration Strategy

Use YAML for canonical experiment definitions and `.env` for local overrides.

### YAML Profiles

Store in `config/profiles/*.yaml`.

Responsibilities:

1. PHP profile tier
2. PHP versions enabled for a benchmark campaign
3. framework versions pinned for the profile
4. frameworks enabled for a benchmark campaign
5. runtimes enabled
6. runtime configuration set names
7. scenarios enabled
8. code forms enabled
9. repetition count
10. warmup rules
11. cache state rules
12. benchmark duration and concurrency defaults

Example profile names:

1. `pilot.yaml`
2. `modern-lts.yaml`
3. `latest.yaml`
4. `legacy-lts.yaml`
5. `extended.yaml`

### `.env` Overrides

Use `.env` for Compose interpolation and local machine defaults.

Responsibilities:

1. default `PHP_VERSION` when a profile does not override it
2. `MARIADB_VERSION`
3. `REDIS_VERSION`
4. image tags
5. port mappings
6. host paths
7. optional CPU and memory limits
8. default `wrk` settings for local runs

Recommended local-only file:

1. `.env.local` or `.env.override`

This file should be ignored from git.

## Runtime Configuration Inventory

Runtime-specific settings should be adjustable without editing code.

Classic runtime settings:

1. `OPcache` on or off
2. JIT mode
3. preload on or off
4. FPM pool settings
5. Apache worker or prefork settings

Persistent runtime settings:

1. worker count
2. max requests per worker
3. recycle policy
4. runtime memory limits
5. `OPcache` on or off

Data settings:

1. seed size
2. cache TTL
3. reset strategy
4. warmup strategy

Obfuscation settings:

1. YAK Pro profile name
2. ignored symbols
3. excluded paths
4. enabled transforms

## Result Reproducibility Requirements

Each benchmark result must be traceable to:

1. benchmark profile name
2. PHP profile tier
3. PHP version
4. framework version
5. benchmark profile contents or fingerprint
6. `.env` values relevant to execution
7. container image tag or digest
8. framework
9. runtime family
10. runtime
11. runtime config
12. scenario
13. code form
14. obfuscation profile and manifest
15. repetition number
16. dataset version
17. host machine metadata

Host metadata should include:

1. CPU model
2. RAM
3. OS and kernel
4. Docker version
5. CPU and memory limits applied to containers

## Repository Structure

```text
benchmark-php/
  apps/
    native/
    laravel/
    codeigniter/
  config/
    profiles/
    runtime/
    scenarios/
  docker/
    compose.yml
    runtimes/
      mod-php/
      php-fpm/
      frankenphp-classic/
      frankenphp-worker/
      roadrunner/
      swoole/
    services/
      mariadb/
      redis/
      wrk/
  obfuscation/
    yakpro/
      profiles/
      manifests/
      ignore-lists/
  bench/
    scenarios/
    warmup/
    verification/
  scripts/
    matrix/
    run/
    collect/
    analyze/
  results/
    raw/
    processed/
    reports/
    figures/
  docs/
    implementation-plan.md
    methodology/
    runtime-notes/
    obfuscation-compatibility/
    threats-to-validity/
```

## Milestones

### M1 Benchmark Contract

Goal: freeze naming, schemas, and Docker-oriented benchmark definitions.

Deliverables:

1. repository directory structure
2. benchmark naming conventions
3. raw result schema
4. processed result schema
5. study overview document
6. pilot and main matrix definitions

Acceptance criteria:

1. every benchmark case can be uniquely named from framework, runtime, config, scenario, code form, and repetition
2. raw and processed result fields are documented and stable
3. classic vs persistent runtime split is explicit
4. Docker execution model is documented as the standard benchmark path

### M2 Docker Infrastructure Baseline

Goal: define the reproducible service layer for all benchmark runs.

Deliverables:

1. Docker Compose architecture
2. `MariaDB` service definition
3. `Redis` service definition
4. `wrk` runner service definition
5. benchmark profile schema
6. `.env` override strategy

Acceptance criteria:

1. service responsibilities are clearly separated
2. benchmark profiles define experiment structure
3. `.env` only carries machine-specific or override values
4. no benchmark case requires manual configuration edits in app code

### M3 Data and Cache Contract

Goal: define the shared data-backed workload used by all apps.

Deliverables:

1. seed dataset design
2. reset script design
3. warm-cache procedure design
4. `db-read` query contract
5. `db-list` query contract

Acceptance criteria:

1. schema is fixed and identical for all framework targets
2. seed data is deterministic
3. cache key strategy is documented
4. warm and cold cache states are explicitly distinguishable

### M4 Native Pilot on `php-fpm`

Goal: prove one end-to-end benchmark path with the lowest-complexity app.

Deliverables:

1. native PHP app
2. `php-fpm` runtime definition
3. pilot endpoints
   - `hello`
   - `json`
   - `db-read`
   - `db-read-cache-warm`
4. verification checklist
5. `wrk` execution contract

Acceptance criteria:

1. all four endpoints are defined with stable response shapes
2. DB-backed endpoint semantics are documented
3. warm-cache path behavior is documented
4. benchmark profile can run the native pilot through Docker only

### M5 Laravel Pilot on `php-fpm`

Goal: replicate the native pilot in the main Indonesian framework target.

Deliverables:

1. Laravel app plan
2. route and controller mapping for pilot scenarios
3. `MariaDB` integration design
4. `Redis` integration design
5. response equivalence mapping against native app

Acceptance criteria:

1. Laravel pilot endpoints are semantically equivalent to native endpoints
2. data access path is idiomatic Laravel and documented
3. cache path is idiomatic Laravel and documented
4. benchmark profile can switch between native and Laravel without changing scenario semantics

### M6 CodeIgniter Pilot on `php-fpm`

Goal: replicate the pilot in the lightweight Indonesia-relevant comparator.

Deliverables:

1. CodeIgniter app plan
2. route and controller mapping for pilot scenarios
3. `MariaDB` integration design
4. `Redis` integration design
5. response equivalence mapping against native app

Acceptance criteria:

1. CodeIgniter pilot endpoints are semantically equivalent to native endpoints
2. data access path is idiomatic CodeIgniter and documented
3. cache path is idiomatic CodeIgniter and documented
4. benchmark profile can switch between native and CodeIgniter without changing scenario semantics

### M7 Verification Layer

Goal: define correctness checks before any performance claims.

Deliverables:

1. HTTP smoke-test plan
2. response-shape validation plan
3. DB seed verification plan
4. Redis reset and warm verification plan
5. warm runtime verification rules

Acceptance criteria:

1. each scenario has expected status, content type, and response structure
2. DB scenarios have fixed expected data
3. warm-cache scenarios have a documented prewarm step
4. benchmark execution is blocked unless verification passes

### M8 YAK Pro Minimal Profile

Goal: define the first deployable obfuscation profile.

Deliverables:

1. `obfuscated-supported-minimal` profile spec
2. initial ignore-list strategy
3. per-target compatibility checklist
4. obfuscation manifest format

Acceptance criteria:

1. minimal profile is conservative and clearly bounded
2. profile rules are documented separately from maximal profile goals
3. each target has a place to record exclusions and ignored symbols
4. supported obfuscation is explicitly defined in the methodology

### M9 `php-fpm` Pilot Benchmark

Goal: produce the first real dataset.

Matrix:

1. frameworks
   - `native`
   - `laravel`
   - `codeigniter`
2. runtime
   - `php-fpm`
3. configs
   - `baseline`
   - `opcache`
4. code forms
   - `plain`
   - `obfuscated-supported-minimal`
5. scenarios
   - `hello`
   - `json`
   - `db-read`
   - `db-read-cache-warm`

Acceptance criteria:

1. pilot matrix is fully enumerated in a YAML profile
2. at least 5 repetitions per case are planned
3. raw outputs map cleanly into the result schema
4. aggregation rules are defined: median, p95, error count, percent delta

### M10 Classic Runtime Expansion

Goal: complete the main classic-runtime study.

Add:

1. `mod_php`
2. `frankenphp-classic`
3. scenarios
   - `db-list`
   - `db-list-cache-warm`
4. config
   - `opcache-jit-tracing`

Acceptance criteria:

1. runtime-family reporting remains separate
2. classic runtime configuration differences are documented
3. scenario parity across all three frameworks is maintained
4. any unsupported combinations are recorded rather than silently skipped

### M11 Persistent Runtime Expansion

Goal: complete the main persistent-runtime study.

Add:

1. `frankenphp-worker`
2. `roadrunner`
3. `swoole`

Acceptance criteria:

1. worker lifecycle behavior is documented per runtime
2. warm-state rules are explicit and separate from classic runtimes
3. per-runtime compatibility validation exists for YAK Pro
4. state leakage risks are documented and checked

### M12 Extended Matrix

Goal: broaden the study only after stable main results.

Add:

1. scenarios
   - `compute`
   - `template`
   - `middleware`
   - `db-read-cache-cold`
   - `db-list-cache-cold`
2. code form
   - `obfuscated-supported-maximal`
3. classic configs
   - `opcache-jit-function`
   - `opcache-preload`
   - `opcache-preload-jit-tracing`

Acceptance criteria:

1. extended cases are clearly marked as secondary analysis
2. cold-cache and warm-cache results are never mixed
3. maximal obfuscation is only used where validated
4. extended results never overwrite main-matrix interpretation

### M13 Reporting

Goal: turn the benchmark into a publishable research artifact.

Deliverables:

1. methodology document
2. threats to validity
3. obfuscation compatibility notes
4. classic runtime results section
5. persistent runtime results section
6. raw result index
7. processed tables and figures

Acceptance criteria:

1. results are separated by runtime family
2. Indonesian framework-selection rationale is stated clearly
3. limitations of YAK Pro compatibility are explicit
4. conclusions stay bounded to observed workloads

## Acceptance Summary

1. pilot is successful when `native`, `laravel`, and `codeigniter` are comparable on `php-fpm` for the 4 pilot scenarios in `plain` and minimal-obfuscated forms
2. main study is successful when all 3 frameworks run on all 6 runtimes for the 6 main scenarios with stable raw data collection
3. extended study is successful when additional scenarios and configs are added without weakening the methodological clarity of the main study

## Immediate Next Step

Start with `M1` through `M4` only:

1. freeze schemas and names
2. freeze YAML profile structure and `.env` override responsibilities
3. freeze `MariaDB` and `Redis` scenario semantics
4. define the native `php-fpm` pilot path

## Pending Locks Before Implementation

1. `MariaDB` exact version: recommend `11.x`
2. `wrk` pilot load profile: start with one medium fixed concurrency and duration profile before adding multiple levels
