#!/bin/sh
set -eu

profile_name="${1:-native-minimal}"

case "$profile_name" in
  native-minimal)
    config_path="obfuscation/yakpro/profiles/native-minimal.cnf"
    output_root="obfuscation/build/native/minimal"
    manifest_path="obfuscation/yakpro/manifests/native-minimal.json"
    app_output_directory="${output_root}/yakpro-po/obfuscated"
    code_form="obfuscated-supported-minimal"
    notes='"Only variable names and string literals are obfuscated. Function and control-flow renaming disabled."'
    ;;
  native-maximal)
    config_path="obfuscation/yakpro/profiles/native-maximal.cnf"
    output_root="obfuscation/build/native/maximal"
    manifest_path="obfuscation/yakpro/manifests/native-maximal.json"
    app_output_directory="${output_root}/yakpro-po/obfuscated"
    code_form="obfuscated-supported-maximal"
    notes='"All obfuscation features enabled: function renaming, control-flow goto, statement shuffling."'
    ;;
  *)
    echo "Unsupported native obfuscation profile: $profile_name" >&2
    exit 1
    ;;
esac

sudo rm -rf "$output_root/yakpro-po"

docker build \
  -f docker/services/yakpro/Dockerfile \
  -t benchmark-php-yakpro:2.0.17 \
  . >/dev/null

docker run --rm \
  -v "$PWD:/workspace" \
  benchmark-php-yakpro:2.0.17 \
  --config-file "/workspace/${config_path}" \
  "/workspace/apps/native" -o "/workspace/${output_root}" >/dev/null

cat > "$manifest_path" <<EOF
{
  "profile": "${profile_name}",
  "tool": {
    "name": "yakpro-po",
    "version_ref": "2.0.17",
    "php_parser_ref": "v4.9.1"
  },
  "source_directory": "apps/native",
  "output_directory": "${app_output_directory}",
  "code_form": "${code_form}",
  "notes": [${notes}]
}
EOF

printf 'Obfuscated native app (%s) written to %s\n' "$profile_name" "$app_output_directory"
printf 'Manifest written to %s\n' "$manifest_path"
