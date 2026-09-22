#!/bin/sh
set -eu
cd "$(dirname "$0")"
mode="${1:-run}"
if [ "$#" -gt 0 ]; then shift; fi

# Read only PORT from backend/.env. Secrets stay in the backend process.
backend_port="${PORT:-}"
if [ -z "$backend_port" ] && [ -f ../backend/.env ]; then
  backend_port=$(sed -n 's/^[[:space:]]*PORT[[:space:]]*=[[:space:]]*\([0-9][0-9]*\)[[:space:]]*$/\1/p' ../backend/.env | head -n 1)
fi
backend_port="${backend_port:-8080}"
case "$backend_port" in
  *[!0-9]*|'') echo 'PORT trong backend/.env phải là số.' >&2; exit 2 ;;
esac

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
backend_define="--dart-define=BACKEND_URL=http://localhost:$backend_port"
case "$mode" in
  run) exec flutter run -d macos "$backend_define" "$@" ;;
  build) exec flutter build macos --release "$backend_define" "$@" ;;
  *) echo 'Dùng: ./desktop.sh run | build' >&2; exit 2 ;;
esac
