#!/bin/sh
set -eu

docker compose --env-file .env.example -f docker/compose.yml up -d --build \
  mariadb redis codeigniter-php-fpm codeigniter-nginx
