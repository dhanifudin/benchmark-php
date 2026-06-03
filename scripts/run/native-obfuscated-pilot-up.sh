#!/bin/sh
set -eu

scripts/run/native-obfuscate.sh native-minimal >/dev/null

docker compose --env-file .env.example -f docker/compose.yml up -d --build \
  mariadb redis native-obfuscated-php-fpm native-obfuscated-nginx
