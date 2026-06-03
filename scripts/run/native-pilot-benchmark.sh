#!/bin/sh
set -eu

scenario="${1:-hello}"
runtime_config="${2:-${NATIVE_PHP_RUNTIME_CONFIG:-baseline}}"
repetition="${3:-1}"
profile_name="${4:-pilot}"
php_profile="${5:-latest}"
php_version="${6:-${PHP_VERSION:-8.4}}"
code_form="${7:-plain}"

mkdir -p results/raw

compose="env PHP_VERSION=${php_version} docker compose --env-file .env.example -f docker/compose.yml"

case "$code_form" in
  plain)
    app_host="${NATIVE_APP_HOST:-native-nginx}"
    app_port="${NATIVE_APP_PORT:-80}"
    health_port="${NATIVE_HTTP_PORT:-8080}"
    framework_version="plain-php"
    compose_service_php="native-php-fpm"
    compose_service_nginx="native-nginx"
    compose_rt_config_var="NATIVE_PHP_RUNTIME_CONFIG"
    ;;
  obfuscated-supported-minimal)
    scripts/run/native-obfuscate.sh native-minimal >/dev/null
    app_host="${NATIVE_OBFUSCATED_APP_HOST:-native-obfuscated-nginx}"
    app_port="${NATIVE_OBFUSCATED_APP_PORT:-80}"
    health_port="${NATIVE_OBFUSCATED_HTTP_PORT:-8083}"
    framework_version="native-yakpro-minimal"
    compose_service_php="native-obfuscated-php-fpm"
    compose_service_nginx="native-obfuscated-nginx"
    compose_rt_config_var="NATIVE_OBFUSCATED_PHP_RUNTIME_CONFIG"
    ;;
  obfuscated-supported-maximal)
    scripts/run/native-obfuscate.sh native-maximal >/dev/null
    app_host="${NATIVE_MAXIMAL_APP_HOST:-native-maximal-nginx}"
    app_port="${NATIVE_MAXIMAL_APP_PORT:-80}"
    health_port="${NATIVE_MAXIMAL_HTTP_PORT:-8091}"
    framework_version="native-yakpro-maximal"
    compose_service_php="native-maximal-php-fpm"
    compose_service_nginx="native-maximal-nginx"
    compose_rt_config_var="NATIVE_MAXIMAL_RUNTIME_CONFIG"
    ;;
  *)
    echo "Unsupported native code_form: $code_form" >&2
    exit 1
    ;;
esac

base_url="http://127.0.0.1:${health_port}"
target_url="http://${app_host}:${app_port}/${scenario}"

# Map cold-cache scenarios to warm-cache endpoints
case "$scenario" in
  db-read-cache-cold) target_url="http://${app_host}:${app_port}/db-read-cache-warm" ;;
  db-list-cache-cold) target_url="http://${app_host}:${app_port}/db-list-cache-warm" ;;
esac
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
case_id="native__${php_version}__php-fpm__${runtime_config}__${scenario}__${code_form}__r${repetition}"
raw_output_path="results/raw/${timestamp}__${case_id}.wrk.txt"
metadata_path="results/raw/${timestamp}__${case_id}.json"

env "${compose_rt_config_var}=${runtime_config}" ${compose} up -d --build "$compose_service_php" "$compose_service_nginx" >/dev/null

until curl -fsS "${base_url}/healthz" >/dev/null 2>&1; do
  sleep 1
done

cache_state="$(case "$scenario" in db-read-cache-warm|db-list-cache-warm) printf warm ;; db-read-cache-cold|db-list-cache-cold) printf cold ;; *) printf none ;; esac)"

[ "$cache_state" != "none" ] && env env ${compose} exec -T redis redis-cli FLUSHALL >/dev/null

if [ "$cache_state" = "warm" ]; then
  warm_url="${base_url}/${scenario}"
  [ "$scenario" = "db-read-cache-cold" ] && warm_url="${base_url}/db-read-cache-warm"
  [ "$scenario" = "db-list-cache-cold" ] && warm_url="${base_url}/db-list-cache-warm"
  i=1
  while [ "$i" -le 25 ]; do
    curl -fsS "$warm_url" >/dev/null || true
    i=$((i + 1))
  done
elif [ "$cache_state" = "cold" ]; then
  env ${compose} exec -T redis redis-cli FLUSHALL >/dev/null
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
    "framework": "native",
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
    "cache_state": "$(case "$scenario" in db-read-cache-warm) printf warm ;; *) printf none ;; esac)",
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
