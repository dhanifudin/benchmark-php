#!/bin/sh
set -eu

input_file="$1"

latency_avg_ms=$(awk '/^    Latency/ {print $2; exit}' "$input_file")
req_per_sec=$(awk '/^Requests\/sec:/ {print $2; exit}' "$input_file")
transfer_per_sec=$(awk '/^Transfer\/sec:/ {print $2; exit}' "$input_file")
non_2xx_count=$(awk '/Non-2xx or 3xx responses:/ {print $5; exit}' "$input_file")
socket_errors_line=$(awk '/Socket errors:/ {print; exit}' "$input_file")
latency_p50_ms=$(awk '/^[[:space:]]*50%/ {print $2; exit}' "$input_file")
latency_p99_ms=$(awk '/^[[:space:]]*99%/ {print $2; exit}' "$input_file")

if [ -z "$non_2xx_count" ]; then
  non_2xx_count=0
fi

if [ -n "$socket_errors_line" ]; then
  error_count=$(printf '%s\n' "$socket_errors_line" | awk -F'[:, ]+' '{sum=0; for (i = 4; i <= NF; i++) if ($i ~ /^[0-9]+$/) sum += $i; print sum}')
else
  error_count=0
fi

convert_to_ms() {
  value="$1"

  if [ -z "$value" ]; then
    printf 'null'
    return
  fi

  case "$value" in
    *us)
      number="${value%us}"
      awk "BEGIN { printf \"%.6f\", ${number} / 1000 }"
      ;;
    *ms)
      number="${value%ms}"
      awk "BEGIN { printf \"%.6f\", ${number} }"
      ;;
    *s)
      number="${value%s}"
      awk "BEGIN { printf \"%.6f\", ${number} * 1000 }"
      ;;
    *)
      printf 'null'
      ;;
  esac
}

convert_transfer_to_bytes() {
  value="$1"

  if [ -z "$value" ]; then
    printf 'null'
    return
  fi

  case "$value" in
    *KB)
      number="${value%KB}"
      awk "BEGIN { printf \"%.6f\", ${number} * 1024 }"
      ;;
    *MB)
      number="${value%MB}"
      awk "BEGIN { printf \"%.6f\", ${number} * 1024 * 1024 }"
      ;;
    *GB)
      number="${value%GB}"
      awk "BEGIN { printf \"%.6f\", ${number} * 1024 * 1024 * 1024 }"
      ;;
    *B)
      number="${value%B}"
      awk "BEGIN { printf \"%.6f\", ${number} }"
      ;;
    *)
      printf 'null'
      ;;
  esac
}

printf 'requests_per_second=%s\n' "${req_per_sec:-0}"
printf 'latency_avg_ms=%s\n' "$(convert_to_ms "$latency_avg_ms")"
printf 'latency_p50_ms=%s\n' "$(convert_to_ms "$latency_p50_ms")"
printf 'latency_p95_ms=null\n'
printf 'latency_p99_ms=%s\n' "$(convert_to_ms "$latency_p99_ms")"
printf 'non_2xx_count=%s\n' "$non_2xx_count"
printf 'error_count=%s\n' "$error_count"
printf 'bytes_per_second=%s\n' "$(convert_transfer_to_bytes "$transfer_per_sec")"
