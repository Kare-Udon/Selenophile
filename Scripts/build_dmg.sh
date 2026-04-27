#!/usr/bin/env bash
set -euo pipefail

CONF="${1:-release}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

APP_NAME="${APP_NAME:-Selenophile}"
BUNDLE_ID="${BUNDLE_ID:-com.udon.selenophile}"
SIGNING_MODE="${SIGNING_MODE:-adhoc}"
MENU_BAR_APP="${MENU_BAR_APP:-1}"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT/dist}"
VOLUME_NAME="${VOLUME_NAME:-$APP_NAME}"
KEEP_DMG_STAGING="${KEEP_DMG_STAGING:-0}"
PACKAGE_APP_SCRIPT="${PACKAGE_APP_SCRIPT:-$ROOT/Scripts/package_app.sh}"

if [[ -f "$ROOT/version.env" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT/version.env"
else
  MARKETING_VERSION="${MARKETING_VERSION:-0.1.0}"
  BUILD_NUMBER="${BUILD_NUMBER:-1}"
fi

MARKETING_VERSION="${MARKETING_VERSION:-0.1.0}"
APP_PATH="$ROOT/${APP_NAME}.app"
DMG_NAME="${DMG_NAME:-${APP_NAME}-${MARKETING_VERSION}.dmg}"
DMG_PATH="$OUTPUT_DIR/$DMG_NAME"

mkdir -p "$OUTPUT_DIR"
rm -f "$DMG_PATH"

APP_NAME="$APP_NAME" \
BUNDLE_ID="$BUNDLE_ID" \
MENU_BAR_APP="$MENU_BAR_APP" \
SIGNING_MODE="$SIGNING_MODE" \
"$PACKAGE_APP_SCRIPT" "$CONF"

if [[ ! -d "$APP_PATH" ]]; then
  echo "ERROR: missing app bundle at $APP_PATH" >&2
  exit 1
fi

STAGING_DIR="$(mktemp -d "$OUTPUT_DIR/.dmg-staging.XXXXXX")"
cleanup() {
  if [[ "$KEEP_DMG_STAGING" != "1" ]]; then
    rm -rf "$STAGING_DIR"
  fi
}
trap cleanup EXIT

cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

printf '已创建 DMG：%s\n' "$DMG_PATH"
