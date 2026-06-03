#!/bin/sh
set -eu

port="${NATIVE_HTTP_PORT:-8080}"
base_url="http://127.0.0.1:${port}"
scenario="${1:-hello}"
requests="${2:-25}"

warm_url="${base_url}/${scenario}"

case "$scenario" in
  db-read-cache-warm)
    docker compose --env-file .env.example -f docker/compose.yml exec -T redis redis-cli FLUSHALL >/dev/null
    ;;
esac

i=1
while [ "$i" -le "$requests" ]; do
  curl -fsS "$warm_url" >/dev/null
  i=$((i + 1))
done
