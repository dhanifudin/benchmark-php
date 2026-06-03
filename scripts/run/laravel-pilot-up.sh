#!/bin/sh
set -eu

docker compose --env-file .env.example -f docker/compose.yml up -d --build \
  mariadb redis laravel-php-fpm laravel-nginx
