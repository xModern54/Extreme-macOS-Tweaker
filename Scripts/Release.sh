#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_SCRIPT="$PROJECT_ROOT/Scripts/Build.sh"
APP_PATH="$PROJECT_ROOT/Tweaker.app"
APP_BINARY="$APP_PATH/Contents/MacOS/Tweaker"
STAGE=""
LOG="$(mktemp -t extreme-mac-tweaker-release.XXXXXX)"

cleanup() {
  if [[ -n "$STAGE" && -d "$STAGE" ]]; then
    rm -rf "$STAGE"
  fi
  rm -f "$LOG"
}
trap cleanup EXIT

fail() {
  echo "$1" >&2
  if [[ -s "$LOG" ]]; then
    cat "$LOG" >&2
  fi
  exit "${2:-1}"
}

if [[ ! -x "$BUILD_SCRIPT" ]]; then
  fail "Build.sh is missing or not executable."
fi

if ! "$BUILD_SCRIPT" >"$LOG" 2>&1; then
  cat "$LOG" >&2
  exit 1
fi

if [[ ! -d "$APP_PATH" || ! -x "$APP_BINARY" ]]; then
  fail "Tweaker.app was not produced by the release build."
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist" 2>/dev/null || true)"
if [[ -z "$VERSION" ]]; then
  fail "CFBundleShortVersionString is missing from Tweaker.app."
fi
VERSION="${VERSION#v}"

ARCHS="$(/usr/bin/lipo -archs "$APP_BINARY" 2>/dev/null || true)"
case "$ARCHS" in
  arm64)
    DMG_ARCH="aarch64"
    ;;
  *)
    fail "Release packaging currently supports aarch64 only. Binary arch: ${ARCHS:-unknown}."
    ;;
esac

DMG_NAME="ExtremeMacTweaker-v${VERSION}-${DMG_ARCH}.dmg"
DMG_PATH="$PROJECT_ROOT/$DMG_NAME"

STAGE="$(mktemp -d -t extreme-mac-tweaker-dmg)"
if ! /usr/bin/ditto "$APP_PATH" "$STAGE/Tweaker.app"; then
  fail "Failed to stage Tweaker.app for the disk image."
fi
ln -s /Applications "$STAGE/Applications"

hdiutil detach "/Volumes/Extreme Mac Tweaker" >/dev/null 2>&1 || true
rm -f "$DMG_PATH"
if ! /usr/bin/hdiutil create \
  -volname "Extreme Mac Tweaker" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  "$DMG_PATH" >"$LOG" 2>&1; then
  fail "Failed to create $DMG_NAME."
fi

if ! /usr/bin/codesign --force --sign - --timestamp=none "$DMG_PATH" >"$LOG" 2>&1; then
  fail "Failed to adhoc-sign $DMG_NAME."
fi

if ! /usr/bin/codesign --verify "$DMG_PATH" >"$LOG" 2>&1; then
  fail "Adhoc signature verification failed for $DMG_NAME."
fi

echo "complete"
