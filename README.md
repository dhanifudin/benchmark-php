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

1. Repository scaffold and benchmark contract are in place.
2. Pilot implementation target is `php-fpm` with `hello`, `json`, `db-read`, and `db-read-cache-warm` scenarios.
3. Result schemas are defined in `config/schemas/`.

Start here:

1. `docs/implementation-plan.md`
2. `config/profiles/pilot.yaml`
3. `config/profiles/latest.yaml`
4. `config/profiles/modern-lts.yaml`
5. `config/profiles/legacy-lts.yaml`
6. `config/schemas/benchmark-profile.schema.json`
