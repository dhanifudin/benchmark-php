#!/bin/sh
set -eu

port="${NATIVE_FRANKENPHP_WORKER_HTTP_PORT:-8088}"
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

echo "Native FrankenPHP worker verification passed."
