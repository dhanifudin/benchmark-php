#!/bin/sh
set -eu

docker compose --env-file .env.example -f docker/compose.yml down -v
