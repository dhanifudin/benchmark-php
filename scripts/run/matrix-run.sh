#!/bin/sh
set -eu

profile_path=""
runtime_name=""
repetitions_override=""
wrk_connections=""

while [ $# -gt 0 ]; do
  case "$1" in
    --runtime) runtime_name="$2"; shift 2 ;;
    --repetitions) repetitions_override="$2"; shift 2 ;;
    --connections) wrk_connections="$2"; shift 2 ;;
    *) profile_path="$1"; shift ;;
  esac
done

if [ -z "$profile_path" ] || [ ! -f "$profile_path" ]; then
  echo "Usage: $0 <profile.yaml> --runtime <name> [--repetitions N]" >&2
  echo "Example: $0 config/profiles/pilot.yaml --runtime php-fpm --repetitions 5" >&2
  exit 1
fi

if [ -z "$runtime_name" ]; then
  echo "Error: --runtime is required" >&2
  exit 1
fi

eval "$(ruby -e '
require "yaml"
profile = YAML.load_file(ARGV[0])
runtime_name = ARGV[1]
puts "profile_name=#{profile.fetch("name")}" 
puts "php_profile=#{profile.fetch("php_profile")}" 
puts "php_version=#{profile.fetch("php_versions").first}" 
reps = ARGV[2] ? ARGV[2].to_i : profile.fetch("repetitions")
puts "repetitions=#{reps}" 
puts "frameworks=#{profile.fetch("frameworks").join(",")}" 
puts "scenarios=#{profile.fetch("scenarios").map { |s| s.fetch("name") }.join(",")}" 
puts "code_forms=#{profile.fetch("code_forms").join(",")}" 
runtime = profile.fetch("runtimes").find { |item| item.fetch("name") == runtime_name }
if runtime
  puts "runtime_family=#{runtime.fetch("family")}" 
  puts "runtime_configs=#{runtime.fetch("configs").join(",")}" 
else
  $stderr.puts "Runtime not found in profile: #{runtime_name}"
  exit 1
end
' "$profile_path" "$runtime_name" "${repetitions_override:-}")"

OLDIFS="$IFS"
set -f  # disable globbing
IFS=','
# read into arrays using positional params for compatibility
set -- $frameworks
framework_args="$*"
set -- $scenarios
scenario_args="$*"
set -- $runtime_configs
runtime_config_args="$*"
set -- $code_forms
code_form_args="$*"
IFS="$OLDIFS"
set +f

find_runner() {
  fw="$1"
  rt="$2"
  case "$fw" in
    native)
      case "$rt" in
        php-fpm) printf 'scripts/run/native-pilot-benchmark.sh' ;;
        mod_php) printf 'scripts/run/native-modphp-benchmark.sh' ;;
        frankenphp-classic) printf 'scripts/run/native-frankenphp-benchmark.sh' ;;
        frankenphp-worker) printf 'scripts/run/native-frankenphp-worker-benchmark.sh' ;;
        roadrunner) printf 'scripts/run/native-roadrunner-benchmark.sh' ;;
        swoole) printf 'scripts/run/native-swoole-benchmark.sh' ;;
      esac
      ;;
    laravel)
      case "$rt" in
        php-fpm) printf 'scripts/run/laravel-pilot-benchmark.sh' ;;
        swoole) printf 'scripts/run/laravel-swoole-benchmark.sh' ;;
      esac
      ;;
    codeigniter)
      case "$rt" in
        php-fpm) printf 'scripts/run/codeigniter-pilot-benchmark.sh' ;;
      esac
      ;;
  esac
}

run_case() {
  fw="$1"
  sc="$2"
  rtc="$3"
  rep="$4"
  cf="$5"

  runner="$(find_runner "$fw" "$runtime_name")"

  if [ -z "$runner" ]; then
    printf 'SKIP %s + %s: no runner for runtime %s\n' "$fw" "scenario" "$runtime_name"
    return 0
  fi

  if [ ! -f "$runner" ] || [ ! -x "$runner" ]; then
    printf 'SKIP %s: runner not found or not executable: %s\n' "$fw" "$runner"
    return 0
  fi

  "$runner" "$sc" "$rtc" "$rep" "$profile_name" "$php_profile" "$php_version" "$cf"
}

inner_IFS="$IFS"
IFS=','
for framework in $framework_args; do
  for scenario in $scenario_args; do
    for runtime_config in $runtime_config_args; do
      for code_form in $code_form_args; do
        IFS="$inner_IFS"
        rep=1
        while [ "$rep" -le "$repetitions" ]; do
          printf '[%s] %s %s %s %s r%s\n' "$runtime_name" "$framework" "$scenario" "$runtime_config" "$code_form" "$rep"
          run_case "$framework" "$scenario" "$runtime_config" "$rep" "$code_form"
          rep=$((rep + 1))
        done
        IFS=','
      done
    done
  done
done
IFS="$inner_IFS"
