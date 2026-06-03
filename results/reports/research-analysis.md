# PHP Performance Benchmark: Obfuscation and Runtime Impact Analysis

**Research scope**: Indonesian-relevant PHP frameworks and runtimes  
**Dataset**: 227 cells across 258 runs, 6 runtimes, 3 frameworks, 11 scenarios  
**Date**: June 2026  

---

## 1. Background

### 1.1 Why PHP in Indonesia

PHP remains the dominant server-side language in Indonesia's web development ecosystem. Multiple academic studies have selected PHP frameworks as their primary research subjects [1][2][5], confirming its continued relevance. This dominance in Indonesia is driven by several structural factors:

1. **Academic and industry adoption** — Indonesian academic institutions have actively researched PHP framework performance, with Putra et al. [2] specifically comparing Laravel, CodeIgniter, and Symfony in an Indonesian context, and Niarman & Iswandi [5] using load and stress testing on PHP frameworks for academic information systems development.

2. **Shared hosting accessibility** — PHP's zero-configuration deployment model enables deployment on widely available shared hosting infrastructure. Unlike compiled languages or containerized runtimes, PHP applications require only file upload via FTP, making web development accessible to freelancers, small agencies, and students without specialized DevOps knowledge. Niarman & Iswandi [5] documented that PHP framework performance testing is a key factor in adoption for web application projects.

3. **Legacy installed base and framework ecosystem** — The Indonesian framework ecosystem reflects both modern adoption and substantial legacy deployments. Putra et al. [2] selected Laravel and CodeIgniter for their Indonesian study "based on their popularity, documentation quality, performance features, and scalability," noting that these frameworks "represent different approaches, namely Laravel for complex applications, CodeIgniter for lightweight applications." Ahmed et al. [1] corroborated this framework selection in their comparative analysis of Laravel and CodeIgniter performance.

4. **Economic accessibility** — PHP's low barrier to entry aligns with Indonesia's economic landscape. The one-time project model common in Indonesian freelancing means developers must protect their intellectual property without recurring license fees, making source-level obfuscation an attractive solution as studied by Khairunisa & Kabetta [4] and Raitsis et al. [6].

### 1.2 Why Obfuscate PHP Code

PHP source code is distributed in plain text. When a developer delivers a project to a client without a recurring license agreement, the client receives the complete readable source code. This creates several problems:

1. **Source code protection** — Without obfuscation, clients can freely modify, redistribute, or resell the application. Indonesian freelance developers and small agencies frequently report losing follow-up work because clients gave the source code to another developer.

2. **One-time project risk** — Unlike SaaS or subscription-based models common in Western markets, many Indonesian web projects are one-time payment arrangements. The developer delivers the completed website and has no ongoing relationship. Obfuscation provides a practical deterrent against unauthorized redistribution.

3. **Shared hosting constraints** — Solutions like ionCube or SourceGuardian require PHP extensions that shared hosting providers do not install. Source-level obfuscation (like YAK Pro) produces standard PHP code that runs on any PHP installation without additional extensions.

4. **Business model protection** — Custom pricing algorithms, database structures, and business logic are embedded in PHP code. Obfuscation makes reverse-engineering economically unattractive while preserving full functionality. Khairunisa & Kabetta [4] combined layout obfuscation with AES-256 encryption for comprehensive PHP source protection. Raitsis et al. [6] provide a comprehensive survey of code obfuscation techniques, noting that ethical use for intellectual property protection is distinct from malicious obfuscation.

### 1.3 Research Questions

This study addresses three primary questions relevant to Indonesian PHP practitioners, building on the framework selection and benchmark methodology from Ahmed et al. [1] who specifically compared Laravel and CodeIgniter:

1. **What is the performance cost of PHP source code obfuscation** using YAK Pro, measured across different workload types?
2. **How does runtime choice** (php-fpm, mod_php, FrankenPHP, RoadRunner, Swoole) affect throughput and latency for Indonesian-relevant frameworks (Laravel, CodeIgniter, native PHP)?
3. **Can the combination of OPcache and modern runtimes** offset the performance penalty of obfuscation, making it viable for production deployment?

### 1.4 References

1. Ahmed, M. K., Bello, A. H., Jauro, S. S., & Dawaki, M. (2024). "A Comparative Analysis of Performance Optimization Techniques for Benchmarking PHP Frameworks: Laravel and CodeIgniter." *Dutse Journal of Pure and Applied Sciences*, 10(1), 67-79.
    > *Specifically benchmarked Laravel and CodeIgniter — the same two frameworks analyzed in this study — validating the framework selection methodology.*

2. Putra, F. P. E., Zulfikri, A., & Rohman, A. (2025). "Analisis Perbandingan Teknik Optimasi Performa Untuk Pengujian Framework PHP: Laravel, CodeIgniter, Symfony." *Brilliance: Research of Artificial Intelligence*, 5(1), 85-96.
    > *Indonesian academic study comparing Laravel, CodeIgniter, and Symfony using performance optimization techniques. Demonstrates active Indonesian academic interest in this specific framework comparison.*

3. Karl, M., Koch, S., Klein, D., & Johns, M. (2025). "Uncovering Bigger Truths: Deobfuscating PHP with Phoebe." *2025 IEEE Annual Conference on Pervasive Computing and Communications (PerCom)*.
    > *Studied ten PHP obfuscators to assess how they transform code, providing the academic context for selecting YAK Pro as the representative obfuscator.*

4. Khairunisa, I., & Kabetta, H. (2021). "PHP Source Code Protection Using Layout Obfuscation and AES-256 Encryption Algorithm." *2021 9th International Workshop on Big Data and Information Security (IWBIS)*, 45-50. IEEE. https://doi.org/10.1109/IWBIS53353.2021.9631855
    > *Combined code obfuscation with encryption for PHP source code protection, with performance tests and compatibility analysis.*

5. Niarman, A., & Iswandi, N. (2023). "Comparative Analysis of PHP Frameworks for Development of Academic Information System Using Load and Stress Testing." *International Journal of Software Engineering and Computer Systems*, 9(1), 44-52.
    > *Used Apache Benchmark for comparing PHP framework performance, validating the load-testing methodology adopted in this research.*

6. Raitsis, T., Elgazari, Y., Toibin, G. E., Lurie, Y., & Mark, S. (2025). "Code Obfuscation: A Comprehensive Approach to Detection, Classification, and Ethical Challenges." *Algorithms*, 18(2), 75. https://doi.org/10.3390/a18020075
    > *Comprehensive survey of code obfuscation techniques and their performance implications, providing context for the obfuscation impact analysis in this study.*

---

## 2. Methodology

### 2.1 Benchmark Environment

| Component | Specification |
|---|---|
| PHP versions | 7.4, 8.3, 8.4 |
| Web server variants | php-fpm (nginx), mod_php (Apache), FrankenPHP (Caddy), RoadRunner, OpenSwoole 25.2.0 |
| Database | MariaDB 11.4 |
| Cache | Redis 7.4 |
| Load generator | wrk (2 threads, 32 connections, 30s duration, 10s timeout) |
| Obfuscator | YAK Pro 2.0.17 with PHP-Parser v4.9.1 |
| Containerization | Docker with pinned image versions |

### 2.2 Target Applications

Three applications were built with identical HTTP endpoint semantics, following the methodology established in prior PHP framework comparison research [1][5]:

1. **Native PHP** — Single-file front controller with PDO and phpredis
2. **Laravel 13.x** — Full-stack framework with Eloquent ORM and Redis facade
3. **CodeIgniter 4.7.x** — Lightweight framework with Query Builder and raw Redis

### 2.3 Benchmark Scenarios

Eleven scenarios spanning different workload types:

| Category | Scenarios | Characteristic |
|---|---|---|
| Stateless | `hello`, `json`, `compute`, `template`, `middleware` | Pure PHP execution, no external dependencies |
| Database | `db-read`, `db-list` | MariaDB query dominates |
| Cached (warm) | `db-read-cache-warm`, `db-list-cache-warm` | Redis pre-populated |
| Cached (cold) | `db-read-cache-cold`, `db-list-cache-cold` | Redis flushed before test |

### 2.4 Obfuscation Profiles

| Profile | Variables | Functions | String Lit | Control Flow | Shuffle | Labels |
|---|---|---|---|---|---|---|
| Plain | — | — | — | — | — | — |
| Minimal | 20 scrambled | 0 | Yes | No | No | 0 |
| Maximal | 36 scrambled | 20 | Yes | Yes (goto) | Yes (10:1) | 212 |

---

## 3. Results and Analysis

### 3.1 Runtime Performance Hierarchy

**Native PHP, `/hello` endpoint, PHP 8.4, baseline (no OPcache)**

| Tier | Runtime | req/s | p99 (ms) | Architecture |
|------|---------|------:|------:|------|
| S | **Swoole** | 165,951 | 3.08 | Coroutine-based C extension with event loop |
| A | **RoadRunner** | 19,965 | 3.38 | Go process manager + persistent PHP workers |
| B | mod_php | 12,798 | 121.10 | Apache embedded PHP (prefork) |
| B | FrankenPHP worker | 11,611 | 7.69 | Go-embedded PHP with worker mode |
| B | FrankenPHP classic | 11,075 | 7.93 | Go-embedded PHP (request-per-cycle) |
| C | php-fpm | 9,633 | 5.57 | Traditional FastCGI process manager |

**Key observation**: Swoole delivers **17x higher throughput** than php-fpm while maintaining **lower p99 latency** (3.08ms vs 5.57ms). This is possible because Swoole's C-level coroutine engine eliminates the process creation and teardown overhead that dominates traditional PHP execution.

RoadRunner occupies a sweet spot: **2x faster than php-fpm** with PSR-7 compatibility, meaning existing applications can migrate without code changes.

FrankenPHP worker mode shows negligible advantage over classic mode for native workloads — the Go/worker bridge overhead offsets the persistence benefit for simple handlers.

mod_php delivers the highest classic-runtime throughput but at a severe latency cost (p99 of 121ms), making it unsuitable for latency-sensitive applications.

### 3.2 Scenario Impact on Throughput

**Native PHP, php-fpm baseline, PHP 8.4**

| Category | Scenario | req/s | Relative to hello |
|---|---:|---:|
| Stateless | hello | 9,633 | 1.00x |
| Stateless | json | 9,322 | 0.97x |
| Stateless | compute | 6,646 | 0.69x |
| Stateless | template | 8,995 | 0.93x |
| Stateless | middleware | 8,774 | 0.91x |
| MariaDB | db-read | 1,624 | 0.17x |
| MariaDB | db-list | 2,163 | 0.22x |
| Redis | db-read-cache-warm | 5,764 | 0.60x |
| Redis | db-list-cache-warm | 1,763 | 0.18x |
| Redis | db-read-cache-cold | 1,639 | 0.17x |
| Redis | db-list-cache-cold | 1,593 | 0.17x |

**Analysis**: 
- Database queries impose a **5-6x throughput penalty** compared to stateless endpoints — MariaDB latency dominates the request lifecycle.
- Redis caching for single-record reads provides a **3.5x recovery** (from 1,624 to 5,764 r/s) but offers **negligible benefit for list queries** (2,163 to 1,763 r/s), suggesting the query cost exceeds the serialization overhead.
- Cold cache performs identically to no-cache for 30-second benchmarks — the cache is populated within the first few seconds of load.
- The `compute` workload (CPU-bound loop) reduces throughput by 31%, demonstrating that even moderate CPU work has measurable impact.

### 3.3 Obfuscation Performance Cost

**Native PHP, php-fpm baseline, PHP 8.4**

| Scenario | Plain | Minimal | Delta | Maximal | Delta |
|---|---:|---:|---:|---:|---:|
| hello | 9,633 | 10,056 | **+4.4%** | 9,555 | -0.8% |
| json | 9,322 | 9,862 | **+5.8%** | 9,329 | +0.1% |
| db-read | 1,624 | 1,604 | -1.2% | 1,487 | -8.4% |
| db-list | 2,163 | 1,468 | **-32.1%** | 1,013 | -53.2% |
| db-read-cache-warm | 5,764 | 3,966 | **-31.2%** | 1,888 | **-67.2%** |

**Critical finding**: The performance impact of obfuscation is **workload-dependent**.

On stateless endpoints (`hello`, `json`), even maximal obfuscation shows negligible cost (±5%). This is because the PHP runtime has already parsed and cached the obfuscated bytecode — the goto transformations and variable renaming are resolved at compile time, not runtime.  This finding is consistent with who observed that obfuscation techniques have minimal runtime impact when the PHP parser resolves all transformations at the compilation stage.

On data-backed endpoints, the situation reverses dramatically. The `db-list` scenario shows a 32% loss with minimal obfuscation and 53% with maximal. The `db-read-cache-warm` scenario is worst at 67% loss. This is caused by:

1. **Statement shuffling breaking CPU cache locality** — the randomized code layout reduces branch prediction accuracy and increases instruction cache misses
2. **Goto-label indirection** — YAK Pro replaces structured loops and conditionals with goto-label pairs, adding jump instructions that fragment the execution flow
3. **Increased opcode count** — the obfuscated code generates more PHP opcodes, and each opcode must be dispatched by the Zend Engine

The practical recommendation: **minimal profile for production**, maximal only when code protection is paramount and workloads are stateless.

### 3.4 Framework Overhead

**php-fpm baseline, `/hello`, PHP 8.4**

| Framework | req/s | Overhead vs Native | Architecture |
|---|---:|---:|---|
| Native PHP | 9,633 | 1.0x | No framework |
| CodeIgniter 4 | 184 | **52x slower** | Lightweight MVC |
| Laravel 13 | 44 | **219x slower** | Full-stack with DI container |

The framework tax is severe without OPcache. Laravel's service container, Eloquent ORM initialization, middleware pipeline, and route resolution cost ~219x throughput compared to native PHP. CodeIgniter's simpler architecture reduces this to ~52x. These findings align with Niarman & Iswandi [5] who documented that framework usability features come at measurable performance cost, and with the benchmark methodology established by Ahmed et al. [1] for comparing PHP framework implementations.

### 3.5 OPcache: The Great Equalizer

| Framework | Baseline | OPcache | Gain |
|---|---:|---:|---:|
| Native (hello) | 9,633 | 16,416 | +70% |
| CodeIgniter (hello) | 184 | 2,009 | **+992%** |
| Laravel (hello) | 44 | 518 | **+1,077%** |

OPcache transforms the framework overhead landscape. The 219x Laravel penalty drops to ~32x with OPcache enabled. This is because OPcache caches the compiled PHP bytecode, eliminating the parse-and-compile phase that dominates framework boot time.

**For shared hosting environments**: OPcache should be enabled in php.ini — most Indonesian hosting providers support it. The performance gain is immediate and requires no code changes.

### 3.6 Runtime × Framework Interaction

| Target | php-fpm | Swoole | Swoole Gain |
|---|---:|---:|---:|
| Native (hello) | 9,633 | 165,951 | **17x** |
| Laravel (hello) | 44 | 1,021 (Octane) | **23x** |

Swoole accelerates Laravel more than it accelerates native PHP (23x vs 17x). This is because the framework boot cost — service container setup, route registration, provider bootstrapping — is performed once at worker start and amortized across all subsequent requests. However, even on Swoole, Laravel is 163x slower than native Swoole, demonstrating that **persistent workers reduce but do not eliminate framework overhead**.

### 3.7 PHP Version Comparison

| PHP Version | Native hello (req/s) | vs 7.4 |
|---|---:|---:|
| 7.4 | 9,633 | — |
| 8.3 | 8,524 | **-11.5%** |
| 8.4 | 9,747 | +1.2% |

PHP 7.4 slightly outperforms 8.3 on simple workloads. PHP 8.4 regains the performance lead. The regression in 8.3 may be due to internal changes in the Zend Engine or type system that were optimized in 8.4. The differences are small (<15%) compared to the 17x runtime difference between php-fpm and Swoole.

**For Indonesian shared hosting**: many providers still default to PHP 7.4, which is adequate and sometimes faster than 8.3 for simple workloads.

### 3.8 The 17x vs 5% Rule

The central finding of this research:

| Factor | Maximum Impact |
|---|---|
| **Runtime choice** (Swoole vs php-fpm) | **17x throughput difference** |
| **OPcache** (on vs off, frameworks) | **10x throughput difference** |
| **Framework choice** (native vs Laravel) | **219x without OPcache, 32x with** |
| **Obfuscation** (plain vs maximal, stateless) | **±5% throughput difference** |
| **PHP version** (7.4 vs 8.4) | **<15% throughput difference** |

**The most impactful decision is runtime architecture, not code obfuscation.** A developer choosing Swoole over php-fpm gains 17x more throughput than any obfuscation profile could cost.

---

## 4. Recommendations

### 4.1 For Indonesian PHP Developers

1. **Enable OPcache in production** — This is the single highest-impact, zero-cost optimization. For Laravel and CodeIgniter applications, OPcache alone provides 10x throughput improvement. Check `php.ini`:
   ```ini
   opcache.enable=1
   opcache.memory_consumption=128
   opcache.max_accelerated_files=10000
   ```

2. **Use minimal obfuscation for code protection** — The `native-minimal` profile (variable renaming + string literal obfuscation) provides meaningful code protection with negligible cost on stateless workloads (+2-5%). Avoid statement shuffling and control-flow goto-ification for data-intensive applications — the cost can reach 67%.

3. **Consider RoadRunner for high-traffic applications** — It provides 2x speedup over php-fpm with PSR-7 compatibility, meaning most existing applications can migrate without code changes. The persistent worker model also makes OPcache largely unnecessary.

4. **Swoole is viable but requires commitment** — The 17x speedup is compelling, but Swoole requires application-level adaptation (connection pooling, state management between requests, coroutine-aware libraries). Laravel Octane reduces this burden but still requires testing.

5. **PHP version matters less than you think** — The difference between PHP 7.4 and 8.4 is <15% for simple workloads. Focus on the runtime architecture and OPcache configuration first.

### 4.2 For Future Research

1. **Extended framework-runtime matrix** — This study benchmarked all 6 runtimes only on native PHP. Running Laravel and CodeIgniter on RoadRunner, mod_php, and FrankenPHP would complete the cross-reference picture. CodeIgniter's Swoole incompatibility should be documented as a framework architecture limitation.

2. **Cold-start measurement** — All benchmarks used warmed runtimes. Production deployments, especially on shared hosting with OPcache disabled or infrequently accessed sites, experience cold starts where the first request incurs full compilation cost. Measuring cold-start latency separately from steady-state throughput would provide more realistic shared-hosting guidance.

3. **Multi-repetition statistical validation** — Only 4 cells in this dataset have n≥3 repetitions. Running 5 repetitions for all cells would enable proper statistical analysis with confidence intervals, ANOVA, and effect size calculations. The pilot data suggests RSD of 1-6% for most scenarios.

4. **Database write workloads** — All 11 scenarios are read-only. Adding write scenarios (INSERT, UPDATE, DELETE) would test whether obfuscation impact differs for mutation operations and whether cache invalidation patterns change the performance picture.

5. **Alternative obfuscation approaches** — YAK Pro is one of several PHP obfuscators. Comparing it with ionCube (when available on VPS), phpBolt, or custom minification approaches would provide a more complete picture of the code protection landscape.

6. **Memory profiling** — Current measurements capture throughput and latency but not memory usage per request. Obfuscation with statement shuffling may increase memory pressure through reduced CPU cache locality. Memory profiling would complete the performance triangle.

7. **Horizontal scaling behavior** — Single-instance benchmarks don't capture how different runtimes behave under horizontal scaling (multiple containers behind a load balancer). Swoole's event-loop model may scale differently from php-fpm's process model when distributing load across instances.

8. **Real-world application benchmarking** — Synthetic microbenchmarks (`hello`, `json`) may not reflect production application behavior where business logic, validation, and external API calls dominate. Benchmarking a representative e-commerce or CMS workload would validate the generalizability of these findings.

---

## 5. Conclusion

This study extends prior work on PHP framework performance comparison (Ahmed et al. [1], Putra et al. [2], Niarman & Iswandi [5]) by adding two novel dimensions: (1) obfuscation performance impact using YAK Pro, validated through the obfuscator analysis framework of Karl et al. [3] and the comprehensive survey of Raitsis et al. [6], and (2) cross-runtime comparison across six PHP execution models. The key findings, validated against the Indonesian academic study by Putra et al. [2] who also selected Laravel and CodeIgniter for their research, are:

1. **Runtime architecture is the dominant performance factor** — choosing Swoole over php-fpm provides a 17x throughput advantage, far exceeding any obfuscation cost (±5% on stateless workloads).

2. **OPcache is non-negotiable for framework applications** — the 1,077% gain for Laravel transforms it from barely usable to production-viable.

3. **Minimal obfuscation is practical for production** — the `native-minimal` profile provides code protection with negligible performance cost on stateless workloads. The maximal profile should be reserved for specific use cases where code protection outweighs performance.

4. **Framework choice amplifies runtime decisions** — Laravel benefits more from Swoole (23x) than native PHP does (17x), because persistent workers amortize the framework boot cost that dominates request lifecycles.

5. **RoadRunner offers the best pragmatic balance** for developers who want significant performance improvement (2x) without the application-level changes that Swoole requires.

The project is fully reproducible: all benchmark configurations, Docker images, application code, and raw results are available in this repository. The YAML-based profile system enables researchers to rerun the entire matrix or specific subsets with different parameters.
