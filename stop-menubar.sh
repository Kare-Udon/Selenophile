#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME=${APP_NAME:-Selenophile}

log() { printf '%s\n' "$*"; }

log "==> stopping ${APP_NAME}"
pkill -f "${APP_NAME}.app/Contents/MacOS/${APP_NAME}" 2>/dev/null || true
pkill -x "${APP_NAME}" 2>/dev/null || true
pkill -f "${ROOT_DIR}/.build/tuist-derived" 2>/dev/null || true
log "OK: stop signal sent."
