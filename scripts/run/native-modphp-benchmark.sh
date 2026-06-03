#!/bin/sh
set -eu

scenario="${1:-hello}"
runtime_config="${2:-${NATIVE_MODPHP_RUNTIME_CONFIG:-baseline}}"
repetition="${3:-1}"
profile_name="${4:-latest}"
php_profile="${5:-latest}"
php_version="${6:-${PHP_VERSION:-8.4}}"

mkdir -p results/raw

compose="env PHP_VERSION=${php_version} docker compose --env-file .env.example -f docker/compose.yml"
base_url="http://127.0.0.1:${NATIVE_MODPHP_HTTP_PORT:-8086}"
target_url="http://${NATIVE_MODPHP_APP_HOST:-native-modphp}:${NATIVE_MODPHP_APP_PORT:-80}/${scenario}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
case_id="native__${php_version}__mod_php__${runtime_config}__${scenario}__plain__r${repetition}"
raw_output_path="results/raw/${timestamp}__${case_id}.wrk.txt"
metadata_path="results/raw/${timestamp}__${case_id}.json"

env NATIVE_MODPHP_RUNTIME_CONFIG="${runtime_config}" ${compose} up -d --build native-modphp >/dev/null

until curl -fsS "${base_url}/healthz" >/dev/null 2>&1; do
  sleep 1
done

cache_state="$(case "$scenario" in db-read-cache-warm|db-list-cache-warm) printf warm ;; db-read-cache-cold|db-list-cache-cold) printf cold ;; *) printf none ;; esac)"
[ "$cache_state" != "none" ] && env ${compose} exec -T redis redis-cli FLUSHALL >/dev/null

if [ "$cache_state" = "warm" ]; then
  warm_url="${base_url}/${scenario}"
  [ "$scenario" = "db-read-cache-cold" ] && warm_url="${base_url}/db-read-cache-warm"
  [ "$scenario" = "db-list-cache-cold" ] && warm_url="${base_url}/db-list-cache-warm"
  i=1
  while [ "$i" -le 25 ]; do
    curl -fsS "$warm_url" >/dev/null || true
    i=$((i + 1))
  done
fi

started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
env ${compose} run --rm -T wrk \
  "wrk --latency -t${WRK_THREADS:-2} -c${WRK_CONNECTIONS:-32} -d${WRK_DURATION:-30s} --timeout ${WRK_TIMEOUT:-10s} ${target_url}" \
  > "$raw_output_path"
finished_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

eval "$(scripts/collect/parse-wrk-output.sh "$raw_output_path")"

cat > "$metadata_path" <<EOF
{
  "benchmark_case_id": "${case_id}",
  "profile": {
    "name": "${profile_name}",
    "php_profile": "${php_profile}",
    "fingerprint": "manual-${profile_name}"
  },
  "environment": {
    "framework": "native",
    "framework_version": "plain-php",
    "php_version": "${php_version}",
    "runtime_family": "classic",
    "runtime": "mod_php",
    "runtime_config": "${runtime_config}",
    "code_form": "plain",
    "obfuscation_profile": "plain",
    "dataset_version": "v1",
    "repetition": ${repetition}
  },
  "workload": {
    "scenario": "${scenario}",
    "cache_state": "${cache_state}",
    "threads": ${WRK_THREADS:-2},
    "connections": ${WRK_CONNECTIONS:-32},
    "duration": "${WRK_DURATION:-30s}",
    "timeout": "${WRK_TIMEOUT:-10s}"
  },
  "timing": {
    "started_at": "${started_at}",
    "finished_at": "${finished_at}"
  },
  "metrics": {
    "requests_per_second": ${requests_per_second},
    "latency_avg_ms": ${latency_avg_ms},
    "latency_p50_ms": ${latency_p50_ms},
    "latency_p95_ms": ${latency_p95_ms},
    "latency_p99_ms": ${latency_p99_ms},
    "non_2xx_count": ${non_2xx_count},
    "error_count": ${error_count},
    "bytes_per_second": ${bytes_per_second},
    "memory_peak_mb": null
  },
  "artifacts": {
    "wrk_stdout_path": "${raw_output_path}",
    "runtime_log_path": null,
    "verification_log_path": null
  }
}
EOF

printf 'Saved raw output to %s\n' "$raw_output_path"
printf 'Saved metadata to %s\n' "$metadata_path"
