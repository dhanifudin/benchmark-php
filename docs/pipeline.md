# Benchmark Pipeline Documentation

## Overview

The benchmark suite is a **Docker-first, profile-driven HTTP benchmarking framework** for PHP applications. It measures throughput and latency across runtime/framework/obfuscation combinations using reproducible containerized environments.

### Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    BENCHMARK PIPELINE                               │
│                                                                     │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────────┐  │
│  │ Profile  │───▶│  Matrix  │───▶│  Runner  │───▶│  Raw Results │  │
│  │  YAML    │    │  Runner  │    │ (per FW) │    │  .txt + .json│  │
│  └──────────┘    └──────────┘    └──────────┘    └──────┬───────┘  │
│                                                          │          │
│                                                          ▼          │
│  ┌──────────────┐    ┌──────────┐    ┌──────────────────────────┐  │
│  │   Research   │◀───│ Computed │◀───│  Aggregation Script      │  │
│  │   Report     │    │  Tables  │    │  stats.py                │  │
│  └──────────────┘    └──────────┘    └──────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Stage 1: Profile Definition

Benchmark campaigns are defined in **YAML profiles** under `config/profiles/`.

A profile declares:
- **Frameworks** to benchmark (native, laravel, codeigniter)
- **Runtime(s)** with their configuration modes (php-fpm, mod_php, swoole, etc.)
- **Scenarios** — the HTTP endpoints exercised
- **Code forms** — plain, obfuscated-supported-minimal, obfuscated-supported-maximal
- **Repetitions** — how many times each cell runs
- **Load parameters** — threads, connections, duration, timeout
- **Cache behavior** — when to reset/flush Redis

```
Profile (YAML)                      Example
────────────────────────────────────────────────────────
frameworks:  [native, laravel]      # 2 targets
runtimes:    [{name: php-fpm,       # 1 runtime
               configs: [baseline, opcache]}]   # 2 configs
scenarios:   [{name: hello},         # 4 scenarios
              {name: json},
              {name: db-read},
              {name: db-create}]
code_forms:  [plain]                # 1 code form
repetitions: 5                      # 5 runs per cell
                                    → 2 × 2 × 4 × 1 × 5 = 80 benchmark runs
```

### Profile Schema

Profiles are validated against `config/schemas/benchmark-profile.schema.json`. Allowed values for each axis are defined in `docs/benchmark-contract.md`.

---

## Stage 2: Matrix Expansion

The **matrix-run.sh** script reads a profile and expands it into individual benchmark cases.

```
$ scripts/run/matrix-run.sh config/profiles/pilot.yaml \
    --runtime php-fpm --repetitions 5

[php-fpm] native hello baseline plain r1
[php-fpm] native hello baseline plain r2
[php-fpm] native hello baseline plain r3
...
[php-fpm] codeigniter db-create baseline plain r5
```

**Expansion algorithm**:

```
for framework ∈ profile.frameworks:
    for scenario ∈ profile.scenarios:
        for config ∈ runtime.configs:
            for code_form ∈ profile.code_forms:
                for rep ∈ 1..profile.repetitions:
                    run_case(framework, scenario, config, rep, code_form)
```

The matrix runner routes each case to the correct benchmark script using a routing table:

| Framework | Runtime | Runner Script |
|---|---|---|
| native | php-fpm | `native-pilot-benchmark.sh` |
| native | swoole | `native-swoole-benchmark.sh` |
| laravel | php-fpm | `laravel-pilot-benchmark.sh` |
| laravel | swoole | `laravel-swoole-benchmark.sh` |

Incompatible pairs (e.g., codeigniter + swoole) produce a `SKIP` log line and exit 0.

---

## Stage 3: Single Case Benchmark

Each benchmark run follows a strict 9-step sequence:

```
┌──────────────────────────────────────────────────────────────┐
│                SINGLE BENCHMARK CASE FLOW                    │
│                                                              │
│  1. COMPOSE UP                                              │
│     docker compose up -d --build <php-service> <nginx-svc>  │
│                          │                                   │
│  2. HEALTH POLL                                            │
│     curl http://localhost:8080/healthz → 200 OK             │
│     (loops every 1s until healthy, max ∞)                   │
│                          │                                   │
│  3. SETUP CACHE STATE                                       │
│     ┌─ cache_state=none  → skip                             │
│     ├─ cache_state=cold  → redis-cli FLUSHALL               │
│     └─ cache_state=warm  → FLUSHALL + 25 warmup curls       │
│                          │                                   │
│  4. WARMUP (for cache=warm only)                            │
│     for i in 1..25: curl $url > /dev/null                   │
│                          │                                   │
│  5. BENCHMARK                                               │
│     docker compose run wrk --latency -t2 -c32 -d30s $url    │
│     output captured to results/raw/<timestamp>__<id>.wrk.txt│
│                          │                                   │
│  6. PARSE OUTPUT                                            │
│     parse-wrk-output.sh extracts:                           │
│       req/s, avg/p50/p99 latency, errors, transfer bytes    │
│                          │                                   │
│  7. BUILD METADATA                                          │
│     JSON written to results/raw/<id>.json:                  │
│       framework, runtime, config, scenario, code_form       │
│       PHP version, timestamps, repetition number            │
│                          │                                   │
│  8. SAVE ARTIFACTS                                          │
│     wrk raw output → .wrk.txt                               │
│     metadata JSON  → .json                                  │
│                          │                                   │
│  9. RESET (for cache-warm between reps)                     │
│     redis-cli FLUSHALL                                      │
└──────────────────────────────────────────────────────────────┘
```

### Case ID Format

Each run produces a unique, machine-parsable ID:

```
native__8.4__php-fpm__opcache__db-read__plain__r3
  │      │      │       │         │        │   │
  │      │      │       │         │        │   └── repetition number
  │      │      │       │         │        └────── code form
  │      │      │       │         └─────────────── scenario name
  │      │      │       └───────────────────────── runtime config
  │      │      └───────────────────────────────── runtime name
  │      └──────────────────────────────────────── PHP version
  └─────────────────────────────────────────────── framework
```

### Raw Output Schema

Each run produces two files:

**`results/raw/<ts>__<id>.wrk.txt`** — raw wrk stdout:

```
Running 30s test @ http://native-nginx:80/hello
  2 threads and 32 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     3.31ms  673.89us   9.86ms   79.21%
    Req/Sec     4.85k   464.65    10.21k    85.19%
  Latency Distribution
     50%    3.13ms
     75%    3.60ms
     90%    4.22ms
     99%    5.57ms
  289958 requests in 30.10s, 60.28MB read
Requests/sec:   9633.23
Transfer/sec:      2.00MB
```

**`results/raw/<ts>__<id>.json`** — structured metadata:

```json
{
  "benchmark_case_id": "native__8.4__php-fpm__baseline__hello__plain__r1",
  "profile": {"name": "pilot", "php_profile": "latest"},
  "environment": {
    "framework": "native",
    "runtime": "php-fpm",
    "runtime_config": "baseline",
    "code_form": "plain",
    "php_version": "8.4",
    "repetition": 1
  },
  "workload": {
    "scenario": "hello",
    "cache_state": "none",
    "threads": 2, "connections": 32, "duration": "30s"
  },
  "metrics": {
    "requests_per_second": 9633.23,
    "latency_avg_ms": 3.31,
    "latency_p50_ms": 3.13,
    "latency_p99_ms": 5.57,
    "non_2xx_count": 0, "error_count": 0
  },
  "timing": {"started_at": "...", "finished_at": "..."},
  "artifacts": {"wrk_stdout_path": "..."}
}
```

---

## Stage 4: Aggregation

The **aggregation script** (`scripts/collect/aggregate-repetitions.py`) reads all raw JSON files and produces statistical summaries.

```
$ python3 scripts/collect/aggregate-repetitions.py

Generated 2026-06-03 20:43 UTC: 228 rows from 294 raw files
Multi-rep cells (n>=3): 8
  Mean RSD: 12.2%  Median RSD: 10.2%
```

**Algorithm**:

```
1. glob results/raw/*.json

2. group by key = (framework, runtime, runtime_config,
                    scenario, code_form, connections)

3. for each group:
     rps_values = [r.metrics.requests_per_second for r in group]
     median_rps = statistics.median(rps_values)
     stdev_rps = statistics.stdev(rps_values)  [if n>=2]
     rsd_pct   = stdev_rps / median_rps * 100  [if n>=2]
     iqr_rps   = Q3 - Q1                        [if n>=4]
     min_rps, max_rps = min/max of rps_values

4. write results/processed/pilot-aggregated.json
```

**Output schema**:

```json
{
  "framework": "native",
  "runtime": "swoole",
  "runtime_config": "baseline",
  "scenario": "hello",
  "code_form": "plain",
  "connections": 32,
  "repetitions": 4,
  "median_rps": 167264.0,
  "stdev_rps": 3290.6,
  "rsd_pct": 2.0,
  "iqr_rps": 6876.1,
  "min_rps": 161218.0,
  "max_rps": 169582.0,
  "median_p50_ms": 0.11,
  "median_p99_ms": 3.05,
  "error_count_total": 0
}
```

### Statistical Metrics

| Metric | Definition | Use |
|---|---|---|
| median_rps | Median of all repetitions | Primary throughput metric |
| stdev_rps | Standard deviation | Absolute dispersion |
| rsd_pct | (stdev/median) × 100 | Relative stability (<5% = excellent, >20% = unstable) |
| iqr_rps | Q3 − Q1 | Outlier-resistant spread |
| min_rps / max_rps | Full range | Worst/best-case spread |

---

## Stage 5: Report Generation

Reports are generated by Python scripts that read the processed aggregation and produce markdown tables.

Key reports:
- `results/reports/comprehensive-report.md` — full tables and key findings
- `results/reports/research-analysis.md` — academic paper with context and citations
- `results/reports/implementation-status.md` — coverage matrix

---

## Docker Service Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    DOCKER COMPOSE NETWORK                        │
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌────────────┐                    │
│  │ mariadb  │  │  redis   │  │    wrk     │  (shared services)  │
│  │ :3306    │  │  :6379   │  │ (runner)   │                    │
│  └────┬─────┘  └────┬─────┘  └────────────┘                    │
│       │              │                                           │
│       │    ┌─────────┴──────────┐                               │
│       │    │                    │                               │
│       ▼    ▼                    ▼                               │
│  ┌──────────────────────────────────────┐                      │
│  │       APP + RUNTIME PAIR              │   (one active at    │
│  │                                       │    a time per run)  │
│  │  ┌──────────────┐   ┌─────────────┐  │                     │
│  │  │  web server  │◀──│  php runtime │  │                     │
│  │  │  (nginx/     │   │  (fpm/       │  │                     │
│  │  │   apache/    │   │   apache/    │  │                     │
│  │  │   caddy/     │   │   swoole/    │  │                     │
│  │  │   rr/sw)     │   │   rr)        │  │                     │
│  │  └──────┬───────┘   └─────────────┘  │                     │
│  │         │                             │                     │
│  │    ports: $PORT:80                    │                     │
│  └─────────┴─────────────────────────────┘                     │
│                                                                  │
│  13 runtime variants running simultaneously over                │
│  shared mariadb + redis:                                        │
│                                                                  │
│  Port 8080 → native-nginx + native-php-fpm                     │
│  Port 8081 → laravel-nginx + laravel-php-fpm                   │
│  Port 8082 → codeigniter-nginx + codeigniter-php-fpm           │
│  Port 8083 → native-obfuscated-nginx + native-obfuscated-fpm   │
│  Port 8084 → laravel-obfuscated-nginx + laravel-obfuscated-fpm│
│  Port 8085 → codeigniter-obfuscated-nginx                      │
│  Port 8086 → native-modphp (Apache standalone)                  │
│  Port 8087 → native-frankenphp (Caddy standalone)              │
│  Port 8088 → native-frankenphp-worker (Caddy worker)            │
│  Port 8089 → native-roadrunner (Go + PHP workers)               │
│  Port 8090 → native-swoole (OpenSwoole HTTP server)             │
│  Port 8091 → native-maximal-nginx + native-maximal-fpm          │
│  Port 8092 → laravel-swoole (Laravel Octane)                    │
│  Port 8093 → codeigniter-swoole (not compatible)                │
└─────────────────────────────────────────────────────────────────┘
```

### Runtime-to-Image Mapping

| Runtime | PHP SAPI | Web Server | Image |
|---|---|---|---|
| php-fpm | fpm-fcgi | nginx | `php:${PV}-fpm` |
| mod_php | apache2handler | Apache (embedded) | `php:${PV}-apache` |
| frankenphp-classic | cgi-fcgi | Caddy (embedded) | `dunglas/frankenphp:1-php${PV}` |
| frankenphp-worker | cgi-fcgi | Caddy (embedded) | `dunglas/frankenphp:1-php${PV}` + worker script |
| roadrunner | cli | RoadRunner (Go) | `php:${PV}-cli` + rr binary |
| swoole | cli | OpenSwoole (C ext) | `php:${PV}-cli` + openswoole extension |

### Per-Case Lifecycle

Each benchmark case follows this Docker lifecycle:

```
1. docker compose up -d --build <target-services>
   → rebuild if source changed, restart if config changed
   → nginx healthcheck polls /healthz every 10s

2. [benchmark runs via docker compose run --rm wrk]

3. Services stay running between cases (warm cache state)
   → only rebuilt when runtime_config changes
   → Redis not reset between cases unless cache_state requires it

4. docker compose down -v (manual, only at end of campaign)
```

### Obfuscation Pipeline

For obfuscated code forms, an additional stage runs before the Docker build:

```
┌─────────────┐     ┌──────────────┐     ┌────────────────┐
│ apps/native │────▶│ YAK Pro      │────▶│ obfuscation/   │
│  (source)   │     │ container    │     │ build/native/  │
│             │     │ (2.0.17)     │     │ minimal/       │
│             │     │ PHP-Parser   │     │ yakpro-po/     │
│             │     │ v4.9.1       │     │ obfuscated/    │
└─────────────┘     └──────────────┘     └───────┬────────┘
                                                  │
                                                  ▼
                    ┌─────────────────────────────────────┐
                    │ Dockerfile.native-obfuscated        │
                    │ COPY obfuscation/build/... → /app  │
                    │ → native-obfuscated-php-fpm image  │
                    └─────────────────────────────────────┘
```

### DB Seed and Reset

```
┌────────────────────────────────────────────────────┐
│              DATA LIFECYCLE                        │
│                                                    │
│  Initial: docker-compose up mariadb                │
│    → /docker-entrypoint-initdb.d/*.sql auto-runs   │
│    → creates users (5 rows) + posts (20 rows)      │
│                                                    │
│  Between write-scenario cases:                     │
│    → scripts/run/reset-db.sh                       │
│    → DELETE FROM posts; re-INSERT 20 rows          │
│    → ensures reproducible state                    │
│                                                    │
│  Redis:                                            │
│    → FLUSHALL before cache-warm/cache-cold cases   │
│    → cache-warm cases: FLUSHALL + 25 warmup curls  │
└────────────────────────────────────────────────────┘
```

---

## Multi-Rep Statistical Validation Flow

```
┌────────────────────────────────────────────────┐
│          MULTI-REP VALIDATION                   │
│                                                 │
│  matrix-run.sh --runtime swoole --reps 5        │
│       │                                         │
│       ├─ r1: wrk → raw/...__r1.wrk.txt         │
│       ├─ r2: wrk → raw/...__r2.wrk.txt         │
│       ├─ r3: wrk → raw/...__r3.wrk.txt         │
│       ├─ r4: wrk → raw/...__r4.wrk.txt         │
│       └─ r5: wrk → raw/...__r5.wrk.txt         │
│                         │                       │
│                         ▼                       │
│         aggregate-repetitions.py               │
│         5 req/s values → median, stdev, RSD     │
│                         │                       │
│                         ▼                       │
│         processed/pilot-aggregated.json         │
│         { "repetitions": 5,                    │
│           "median_rps": 167264,                │
│           "rsd_pct": 2.0 }                     │
└────────────────────────────────────────────────┘
```

**Interpretation guidelines**:

| RSD | Reliability | Action |
|---|---|---|
| < 3% | Excellent | Results are highly reproducible |
| 3-10% | Good | Minor environmental noise |
| 10-20% | Moderate | Investigate source of variance |
| > 20% | Unstable | Runtime may have inconsistent performance |

---

## File Inventory

```
benchmark-php/
├── config/
│   ├── profiles/         ← benchmark campaign definitions (YAML)
│   ├── schemas/           ← JSON schemas for profiles and results
│   └── runtime/           ← runtime-specific PHP configs
├── apps/
│   ├── native/            ← native PHP app (no framework)
│   ├── laravel/           ← Laravel 13.x app
│   └── codeigniter/       ← CodeIgniter 4.x app
├── docker/
│   ├── compose.yml        ← all services defined
│   ├── runtimes/          ← per-runtime Dockerfiles
│   └── services/          ← mariadb, redis, wrk, yakpro
├── obfuscation/
│   ├── yakpro/profiles/   ← YAK Pro config files (minimal, maximal)
│   ├── yakpro/manifests/  ← obfuscation metadata per build
│   └── build/             ← generated obfuscated code
├── scripts/
│   ├── run/               ← benchmark runners and matrix
│   ├── collect/           ← output parsing and aggregation
│   └── analyze/           ← report generation helpers
├── results/
│   ├── raw/               ← wrk output + JSON metadata (gitignored)
│   ├── processed/         ← aggregated statistical data
│   └── reports/           ← generated markdown reports
└── docs/
    ├── pipeline.md         ← this document
    ├── implementation-plan.md
    └── benchmark-contract.md
```

---

## Running a Full Campaign

```bash
# 1. Start shared services
docker compose --env-file .env.example -f docker/compose.yml up -d mariadb redis

# 2. Run a campaign using the matrix runner
scripts/run/matrix-run.sh config/profiles/pilot.yaml \
    --runtime php-fpm \
    --repetitions 5

# 3. Run on another runtime
scripts/run/matrix-run.sh config/profiles/pilot.yaml \
    --runtime swoole \
    --repetitions 5

# 4. Aggregate results
python3 scripts/collect/aggregate-repetitions.py

# 5. View reports
cat results/reports/comprehensive-report.md

# 6. Cleanup
scripts/run/native-pilot-down.sh
```

---

## Reproducibility Guarantees

1. **Pinned image versions** — `mariadb:11.4`, `redis:7.4`, `php:8.4-fpm`
2. **Docker isolation** — each runtime runs in its own container with controlled dependencies
3. **Deterministic seed data** — MariaDB init SQL and reset scripts produce identical state
4. **Profile-driven config** — all benchmark parameters are in version-controlled YAML
5. **Full provenance** — each result file includes profile name, PHP version, timestamps, and case ID
6. **No external network calls** — benchmarks only access local Docker services
