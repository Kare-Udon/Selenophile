#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME=${APP_NAME:-Selenophile}
CONFIGURATION=${CONFIGURATION:-Debug}
DERIVED_DATA_PATH="${ROOT_DIR}/.build/tuist-derived"
APP_PATH="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}/${APP_NAME}.app"
PROJECT_PATH="${ROOT_DIR}/${APP_NAME}.xcodeproj"

log() { printf '%s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

stop_existing() {
  pkill -f "${APP_NAME}.app/Contents/MacOS/${APP_NAME}" 2>/dev/null || true
  pkill -x "${APP_NAME}" 2>/dev/null || true
}

stop_existing

if command -v tuist >/dev/null 2>&1; then
  log "==> tuist generate"
  (cd "$ROOT_DIR" && tuist generate --no-open)

  log "==> xcodebuild ${CONFIGURATION}"
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$APP_NAME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    build
else
  log "WARN: tuist not found, falling back to Scripts/package_app.sh"
  FALLBACK_CONFIGURATION="release"
  case "$CONFIGURATION" in
    Debug|debug) FALLBACK_CONFIGURATION="debug" ;;
    Release|release) FALLBACK_CONFIGURATION="release" ;;
    *) FALLBACK_CONFIGURATION="release" ;;
  esac
  (cd "$ROOT_DIR" && APP_NAME="$APP_NAME" MENU_BAR_APP=1 ./Scripts/package_app.sh "$FALLBACK_CONFIGURATION")
  APP_PATH="${ROOT_DIR}/${APP_NAME}.app"
fi

if [[ ! -d "$APP_PATH" ]]; then
  fail "App bundle not found at ${APP_PATH}"
fi

log "==> launching ${APP_NAME}"
open -n "$APP_PATH"

for _ in {1..20}; do
  if pgrep -f "${APP_NAME}.app/Contents/MacOS/${APP_NAME}" >/dev/null 2>&1; then
    log "OK: ${APP_NAME} is running."
    exit 0
  fi
  sleep 0.3
done

fail "App exited immediately. Check Console.app for crash logs."
