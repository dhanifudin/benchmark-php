# benchmark-php

Reproducible Docker-first benchmark suite for comparing plain and YAK Pro obfuscated PHP applications across Indonesian-relevant targets:

1. `native`
2. `laravel`
3. `codeigniter`

The benchmark is controlled by versioned YAML profiles in `config/profiles/` and machine-specific `.env` overrides.

Current version-tier profiles:

1. `latest` -> PHP `8.4`
2. `modern-lts` -> PHP `8.3`
3. `legacy-lts` -> PHP `7.4` with Laravel `8.x` latest patch

Current state:

1. **228 cells, 294 runs** across 6 runtimes, 3 frameworks, 15 scenarios
2. Multi-rep validation with RSD metrics on 8 key cells
3. 4 CRUD scenarios (POST/PUT/DELETE) across all frameworks
4. Statistical aggregation with median, stdev, RSD, IQR

Start here:

1. `docs/implementation-plan.md`
2. **`docs/pipeline.md`** — full pipeline architecture and execution flow
3. `config/profiles/pilot.yaml`
4. `config/profiles/latest.yaml`
