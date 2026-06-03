#!/bin/sh
set -eu

profile_path="${1:-config/profiles/pilot.yaml}"

if [ ! -f "$profile_path" ]; then
  echo "Profile not found: $profile_path" >&2
  exit 1
fi

eval "$(ruby -e '
require "yaml"
profile = YAML.load_file(ARGV[0])
puts "profile_name=#{profile.fetch("name")}" 
puts "php_profile=#{profile.fetch("php_profile")}" 
puts "php_version=#{profile.fetch("php_versions").first}" 
puts "repetitions=#{profile.fetch("repetitions")}" 
puts "frameworks=#{profile.fetch("frameworks").join(",")}" 
puts "scenarios=#{profile.fetch("scenarios").map { |s| s.fetch("name") }.join(",")}" 
puts "code_forms=#{profile.fetch("code_forms").join(",")}" 
runtime = profile.fetch("runtimes").find { |item| item.fetch("name") == "php-fpm" } or abort("php-fpm runtime missing")
puts "runtime_configs=#{runtime.fetch("configs").join(",")}" 
' "$profile_path")"

OLDIFS="$IFS"
IFS=','
set -- $frameworks
framework_list="$*"
set -- $scenarios
scenario_list="$*"
set -- $runtime_configs
runtime_config_list="$*"
set -- $code_forms
code_form_list="$*"
IFS="$OLDIFS"

run_framework_case() {
  framework="$1"
  scenario="$2"
  runtime_config="$3"
  repetition="$4"
  code_form="$5"

  case "$framework" in
    native)
      scripts/run/native-pilot-benchmark.sh "$scenario" "$runtime_config" "$repetition" "$profile_name" "$php_profile" "$php_version" "$code_form"
      ;;
    laravel)
      scripts/run/laravel-pilot-benchmark.sh "$scenario" "$runtime_config" "$repetition" "$profile_name" "$php_profile" "$php_version" "$code_form"
      ;;
    codeigniter)
      scripts/run/codeigniter-pilot-benchmark.sh "$scenario" "$runtime_config" "$repetition" "$profile_name" "$php_profile" "$php_version" "$code_form"
      ;;
    *)
      echo "Unsupported framework: $framework" >&2
      exit 1
      ;;
  esac
}

for framework in $(printf '%s' "$framework_list" | tr ' ' '\n'); do
  for scenario in $(printf '%s' "$scenario_list" | tr ' ' '\n'); do
    for runtime_config in $(printf '%s' "$runtime_config_list" | tr ' ' '\n'); do
      for code_form in $(printf '%s' "$code_form_list" | tr ' ' '\n'); do
        repetition=1
        while [ "$repetition" -le "$repetitions" ]; do
          printf 'Running %s %s %s %s repetition %s\n' "$framework" "$scenario" "$runtime_config" "$code_form" "$repetition"
          run_framework_case "$framework" "$scenario" "$runtime_config" "$repetition" "$code_form"
          repetition=$((repetition + 1))
        done
      done
    done
  done
done
