#!/bin/sh
set -eu

runtime_config="${PHP_RUNTIME_CONFIG:-baseline}"
runtime_ini="/usr/local/etc/php/conf.d/zz-benchmark-runtime.ini"

case "$runtime_config" in
  baseline)
    cat > "$runtime_ini" <<'EOF'
opcache.enable=0
opcache.enable_cli=0
EOF
    ;;
  opcache)
    cat > "$runtime_ini" <<'EOF'
opcache.enable=1
opcache.enable_cli=0
opcache.memory_consumption=192
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=20000
opcache.validate_timestamps=0
opcache.jit=disable
EOF
    ;;
  opcache-jit-tracing)
    cat > "$runtime_ini" <<'EOF'
opcache.enable=1
opcache.enable_cli=0
opcache.memory_consumption=192
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=20000
opcache.validate_timestamps=0
opcache.jit_buffer_size=128M
opcache.jit=tracing
EOF
    ;;
  *)
    echo "Unsupported PHP_RUNTIME_CONFIG: $runtime_config" >&2
    exit 1
    ;;
esac

exec docker-php-entrypoint "$@"
