#!/bin/sh
set -eu
cd "$(dirname "$0")"
backend_port="${PORT:-}"
if [ -z "$backend_port" ] && [ -f .env ]; then
  backend_port=$(sed -n 's/^[[:space:]]*PORT[[:space:]]*=[[:space:]]*\([0-9][0-9]*\)[[:space:]]*$/\1/p' .env | head -n 1)
fi
backend_port="${backend_port:-8080}"
case "$backend_port" in
  *[!0-9]*|'') echo 'PORT trong backend/.env phải là số.' >&2; exit 2 ;;
esac
exec dart_frog dev --port "$backend_port" "$@"
