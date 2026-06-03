#!/bin/sh
set -eu

port="${CODEIGNITER_HTTP_PORT:-8082}"
base_url="http://127.0.0.1:${port}"

expect() {
  actual="$1"
  expected="$2"
  message="$3"

  if [ "$actual" != "$expected" ]; then
    echo "Verification failed: ${message}" >&2
    echo "Expected: ${expected}" >&2
    echo "Actual:   ${actual}" >&2
    exit 1
  fi
}

health=$(curl -fsS "${base_url}/healthz")
expect "$health" "ok" "health endpoint"

hello=$(curl -fsS "${base_url}/hello")
expect "$hello" "hello world" "hello endpoint"

json_message=$(curl -fsS "${base_url}/json" | php -r '$data = json_decode(stream_get_contents(STDIN), true); echo $data["data"]["message"] ?? "";')
expect "$json_message" "hello world" "json endpoint message"

db_email=$(curl -fsS "${base_url}/db-read" | php -r '$data = json_decode(stream_get_contents(STDIN), true); echo $data["data"]["user"]["email"] ?? "";')
expect "$db_email" "benchmark@example.test" "db-read endpoint email"

db_framework=$(curl -fsS "${base_url}/db-read" | php -r '$data = json_decode(stream_get_contents(STDIN), true); echo $data["meta"]["framework"] ?? "";')
expect "$db_framework" "codeigniter" "db-read framework marker"

docker compose --env-file .env.example -f docker/compose.yml exec -T redis redis-cli FLUSHALL >/dev/null

first_cache=$(curl -fsS -D - -o /dev/null "${base_url}/db-read-cache-warm" | tr -d '\r' | awk -F': ' '/^X-Cache:/ {print $2}')
expect "$first_cache" "MISS" "db-read-cache-warm first response cache header"

second_cache=$(curl -fsS -D - -o /dev/null "${base_url}/db-read-cache-warm" | tr -d '\r' | awk -F': ' '/^X-Cache:/ {print $2}')
expect "$second_cache" "HIT" "db-read-cache-warm second response cache header"

db_list_count=$(curl -fsS "${base_url}/db-list" | php -r '$data = json_decode(stream_get_contents(STDIN), true); echo count($data["data"]["posts"] ?? []);')
expect "$db_list_count" "20" "db-list post count"

docker compose --env-file .env.example -f docker/compose.yml exec -T redis redis-cli FLUSHALL >/dev/null

first_list_cache=$(curl -fsS -D - -o /dev/null "${base_url}/db-list-cache-warm" | tr -d '\r' | awk -F': ' '/^X-Cache:/ {print $2}')
expect "$first_list_cache" "MISS" "db-list-cache-warm first response cache header"

second_list_cache=$(curl -fsS -D - -o /dev/null "${base_url}/db-list-cache-warm" | tr -d '\r' | awk -F': ' '/^X-Cache:/ {print $2}')
expect "$second_list_cache" "HIT" "db-list-cache-warm second response cache header"

echo "CodeIgniter pilot verification passed."
