#!/bin/sh
set -eu

scenario="${1:-hello}"
runtime_config="${2:-${CODEIGNITER_PHP_RUNTIME_CONFIG:-baseline}}"
repetition="${3:-1}"
profile_name="${4:-pilot}"
php_profile="${5:-latest}"
php_version="${6:-${PHP_VERSION:-8.4}}"
code_form="${7:-plain}"

mkdir -p results/raw

compose="env PHP_VERSION=${php_version} docker compose --env-file .env.example -f docker/compose.yml"

case "$code_form" in
  plain)
    app_host="${CODEIGNITER_APP_HOST:-codeigniter-nginx}"
    app_port="${CODEIGNITER_APP_PORT:-80}"
    health_port="${CODEIGNITER_HTTP_PORT:-8082}"
    compose_service_php="codeigniter-php-fpm"
    compose_service_nginx="codeigniter-nginx"
    compose_rt_config_var="CODEIGNITER_PHP_RUNTIME_CONFIG"
    framework_version="latest-supported"
    ;;
  obfuscated-supported-minimal)
    scripts/run/codeigniter-obfuscate.sh codeigniter-minimal >/dev/null
    app_host="${CODEIGNITER_OBFUSCATED_APP_HOST:-codeigniter-obfuscated-nginx}"
    app_port="${CODEIGNITER_OBFUSCATED_APP_PORT:-80}"
    health_port="${CODEIGNITER_OBFUSCATED_HTTP_PORT:-8085}"
    compose_service_php="codeigniter-obfuscated-php-fpm"
    compose_service_nginx="codeigniter-obfuscated-nginx"
    compose_rt_config_var="CODEIGNITER_OBFUSCATED_PHP_RUNTIME_CONFIG"
    framework_version="ci-yakpro-minimal"
    ;;
  *)
    printf 'SKIPPED CodeIgniter code_form not yet implemented: %s\n' "$code_form"
    exit 0
    ;;
esac

target_url="http://${app_host}:${app_port}/${scenario}"
case "$scenario" in
  db-read-cache-cold) target_url="http://${app_host}:${app_port}/db-read-cache-warm" ;;
  db-list-cache-cold) target_url="http://${app_host}:${app_port}/db-list-cache-warm" ;;
esac
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
case_id="codeigniter__${php_version}__php-fpm__${runtime_config}__${scenario}__${code_form}__r${repetition}"
raw_output_path="results/raw/${timestamp}__${case_id}.wrk.txt"
metadata_path="results/raw/${timestamp}__${case_id}.json"

env "${compose_rt_config_var}=${runtime_config}" ${compose} up -d --build "$compose_service_php" "$compose_service_nginx" >/dev/null

until curl -fsS "http://127.0.0.1:${health_port}/healthz" >/dev/null 2>&1; do
  sleep 1
done

if [ "$scenario" = "db-read-cache-warm" ] || [ "$scenario" = "db-list-cache-warm" ] || [ "$scenario" = "db-read-cache-cold" ] || [ "$scenario" = "db-list-cache-cold" ]; then
  env ${compose} exec -T redis redis-cli FLUSHALL >/dev/null
fi

cache_state="none"
case "$scenario" in
  db-read-cache-warm|db-list-cache-warm) cache_state="warm" ;;
  db-read-cache-cold|db-list-cache-cold) cache_state="cold" ;;
esac

if [ "$cache_state" = "warm" ]; then
  warm_url="http://127.0.0.1:${health_port}/${scenario}"
  [ "$scenario" = "db-read-cache-cold" ] && warm_url="http://127.0.0.1:${health_port}/db-read-cache-warm"
  [ "$scenario" = "db-list-cache-cold" ] && warm_url="http://127.0.0.1:${health_port}/db-list-cache-warm"
  i=1
  while [ "$i" -le 25 ]; do
    curl -fsS "$warm_url" >/dev/null || true
    i=$((i + 1))
  done
fi

started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
env ${compose} run --rm \
  -T \
  wrk \
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
    "framework": "codeigniter",
    "framework_version": "${framework_version}",
    "php_version": "${php_version}",
    "runtime_family": "classic",
    "runtime": "php-fpm",
    "runtime_config": "${runtime_config}",
    "code_form": "${code_form}",
    "obfuscation_profile": "${code_form}",
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
