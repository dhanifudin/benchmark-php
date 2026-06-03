#!/bin/sh
set -eu

profile_name="${1:-laravel-minimal}"

mkdir -p obfuscation/build/laravel/minimal
sudo rm -rf obfuscation/build/laravel/minimal/app-obfuscated

cp -a apps/laravel obfuscation/build/laravel/minimal/app-obfuscated

case "$profile_name" in
  laravel-minimal)
    config_path="obfuscation/yakpro/profiles/laravel-minimal.cnf"
    manifest_path="obfuscation/yakpro/manifests/laravel-minimal.json"
    ;;
  *)
    echo "Unsupported laravel obfuscation profile: $profile_name" >&2
    exit 1
    ;;
esac

docker build \
  -f docker/services/yakpro/Dockerfile \
  -t benchmark-php-yakpro:2.0.17 \
  . >/dev/null

docker run --rm \
  -v "$PWD:/workspace" \
  -w /workspace \
  benchmark-php-yakpro:2.0.17 \
  --config-file "/workspace/${config_path}" \
  "apps/laravel/routes/web.php" -o "/workspace/obfuscation/build/laravel/minimal/web.obfuscated.php" >/dev/null

cp obfuscation/build/laravel/minimal/web.obfuscated.php obfuscation/build/laravel/minimal/app-obfuscated/routes/web.php

cat > "$manifest_path" <<EOF
{
  "profile": "${profile_name}",
  "tool": {
    "name": "yakpro-po",
    "version_ref": "2.0.17",
    "php_parser_ref": "v4.9.1"
  },
  "source_directory": "apps/laravel",
  "output_directory": "obfuscation/build/laravel/minimal/app-obfuscated",
  "code_form": "obfuscated-supported-minimal",
  "notes": [
    "Only routes/web.php is obfuscated (handler logic).",
    "Variable names and string literals are scrambled.",
    "The rest of the Laravel app is copied unmodified from apps/laravel.",
    "Function/class/method renaming disabled for Laravel compatibility."
  ]
}
EOF

printf 'Obfuscated Laravel app written to %s\n' "obfuscation/build/laravel/minimal/app-obfuscated"
printf 'Manifest written to %s\n' "$manifest_path"
