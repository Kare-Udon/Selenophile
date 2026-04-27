#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

assert_file_exists() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    echo "ASSERTION FAILED: expected path to exist: $path" >&2
    exit 1
  fi
}

assert_symlink_target() {
  local path="$1"
  local expected="$2"
  local actual
  actual="$(readlink "$path")"
  if [[ "$actual" != "$expected" ]]; then
    echo "ASSERTION FAILED: expected symlink $path -> $expected, got $actual" >&2
    exit 1
  fi
}

STUB_BIN="$TEMP_DIR/bin"
mkdir -p "$STUB_BIN"

cat > "$STUB_BIN/hdiutil" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" > "$HDIUTIL_LOG"

output=""
srcfolder=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -srcfolder)
      srcfolder="$2"
      shift 2
      ;;
    *)
      output="$1"
      shift
      ;;
  esac
done

if [[ -z "$srcfolder" ]]; then
  echo "missing -srcfolder" >&2
  exit 1
fi

if [[ -z "$output" ]]; then
  echo "missing output path" >&2
  exit 1
fi

assert_path="$srcfolder/Selenophile.app"
if [[ ! -d "$assert_path" ]]; then
  echo "missing staged app bundle at $assert_path" >&2
  exit 1
fi

if [[ ! -L "$srcfolder/Applications" ]]; then
  echo "missing Applications symlink" >&2
  exit 1
fi

touch "$output"
EOF
chmod +x "$STUB_BIN/hdiutil"

PACKAGE_STUB="$TEMP_DIR/package_app.sh"
cat > "$PACKAGE_STUB" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ROOT="${PROJECT_ROOT:?}"
APP_NAME="${APP_NAME:-Selenophile}"
APP_PATH="$ROOT/${APP_NAME}.app"
mkdir -p "$APP_PATH/Contents/MacOS"
touch "$APP_PATH/Contents/MacOS/$APP_NAME"
printf '%s\n' "$*" > "${PACKAGE_LOG:?}"
EOF
chmod +x "$PACKAGE_STUB"

HDIUTIL_LOG="$TEMP_DIR/hdiutil.log"
PACKAGE_LOG="$TEMP_DIR/package.log"
OUTPUT_DIR="$TEMP_DIR/output"
mkdir -p "$OUTPUT_DIR"

PATH="$STUB_BIN:$PATH" \
PROJECT_ROOT="$TEMP_DIR/project" \
PACKAGE_APP_SCRIPT="$PACKAGE_STUB" \
HDIUTIL_LOG="$HDIUTIL_LOG" \
PACKAGE_LOG="$PACKAGE_LOG" \
OUTPUT_DIR="$OUTPUT_DIR" \
KEEP_DMG_STAGING=1 \
/bin/bash "$ROOT/Scripts/build_dmg.sh" >/dev/null

EXPECTED_DMG="$OUTPUT_DIR/Selenophile-0.1.0.dmg"
assert_file_exists "$EXPECTED_DMG"
assert_file_exists "$HDIUTIL_LOG"
assert_file_exists "$PACKAGE_LOG"

STAGING_DIR="$(sed -n 's/.*-srcfolder \([^ ]*\).*/\1/p' "$HDIUTIL_LOG")"
assert_file_exists "$STAGING_DIR/Selenophile.app"
assert_symlink_target "$STAGING_DIR/Applications" "/Applications"

if ! grep -q -- "release" "$PACKAGE_LOG"; then
  echo "ASSERTION FAILED: expected package_app to receive release configuration" >&2
  exit 1
fi

if ! grep -q -- "Selenophile-0.1.0.dmg" "$HDIUTIL_LOG"; then
  echo "ASSERTION FAILED: expected hdiutil output path in log" >&2
  exit 1
fi

echo "build_dmg_test.sh: ok"
