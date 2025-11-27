#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "[deploy] Building images..."
docker compose build --pull

echo "[deploy] Starting containers..."
docker compose up -d --remove-orphans

echo "[deploy] Cleaning dangling images..."
docker image prune -f >/dev/null

echo "[deploy] Done."

