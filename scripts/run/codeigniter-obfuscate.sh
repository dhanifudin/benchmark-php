#!/bin/sh
set -eu

profile_name="${1:-codeigniter-minimal}"

mkdir -p obfuscation/build/codeigniter/minimal
sudo rm -rf obfuscation/build/codeigniter/minimal/app-obfuscated

cp -a apps/codeigniter obfuscation/build/codeigniter/minimal/app-obfuscated

case "$profile_name" in
  codeigniter-minimal)
    config_path="obfuscation/yakpro/profiles/codeigniter-minimal.cnf"
    manifest_path="obfuscation/yakpro/manifests/codeigniter-minimal.json"
    ;;
  *)
    echo "Unsupported codeigniter obfuscation profile: $profile_name" >&2
    exit 1
    ;;
esac

docker build \
  -f docker/services/yakpro/Dockerfile \
  -t benchmark-php-yakpro:2.0.17 \
  . >/dev/null

for source_file in \
  apps/codeigniter/app/Controllers/Benchmark.php \
  apps/codeigniter/app/Config/Routes.php \
  apps/codeigniter/app/Config/Database.php \
; do
  target_rel="${source_file#apps/codeigniter/}"
  target_dir="obfuscation/build/codeigniter/minimal/$(dirname "$target_rel")"
  mkdir -p "$target_dir"
  docker run --rm \
    -v "$PWD:/workspace" \
    -w /workspace \
    benchmark-php-yakpro:2.0.17 \
    --config-file "/workspace/${config_path}" \
    "$source_file" -o "/workspace/obfuscation/build/codeigniter/minimal/${target_rel}" >/dev/null
  cp "obfuscation/build/codeigniter/minimal/${target_rel}" "obfuscation/build/codeigniter/minimal/app-obfuscated/${target_rel}"
done

cat > "$manifest_path" <<EOF
{
  "profile": "${profile_name}",
  "tool": {
    "name": "yakpro-po",
    "version_ref": "2.0.17",
    "php_parser_ref": "v4.9.1"
  },
  "source_directory": "apps/codeigniter",
  "output_directory": "obfuscation/build/codeigniter/minimal/app-obfuscated",
  "code_form": "obfuscated-supported-minimal",
  "notes": [
    "Obfuscated files: Controllers/Benchmark.php, Config/Routes.php, Config/Database.php",
    "Variable names and string literals are scrambled.",
    "The rest of the CodeIgniter app is copied unmodified.",
    "Function/class/method renaming disabled for CodeIgniter compatibility."
  ]
}
EOF

printf 'Obfuscated CodeIgniter app written to %s\n' "obfuscation/build/codeigniter/minimal/app-obfuscated"
printf 'Manifest written to %s\n' "$manifest_path"
