#!/usr/bin/env bash

set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$PROJECT_ROOT/ExtremeMacTweaker.xcodeproj"
CONFIGURATION="Release"
DERIVED_DATA_PATH="$PROJECT_ROOT/.build/DerivedData"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/Tweaker.app"
EMBEDDED_HELPER="$APP_PATH/Contents/Resources/Helpers/RootTweakAction"
BUILD_LOG="$(mktemp -t extreme-mac-tweaker-build.XXXXXX)"

cleanup() {
  rm -f "$BUILD_LOG"
}
trap cleanup EXIT

sign_adhoc() {
  local target="$1"
  local output
  if ! output="$(codesign --force --sign - --timestamp=none --options runtime "$target" 2>&1)"; then
    echo "Failed to adhoc-sign $target." >&2
    [[ -n "$output" ]] && echo "$output" >&2
    exit 1
  fi
}

if xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme ExtremeMacTweaker \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=YES \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGN_STYLE=Manual \
  AD_HOC_CODE_SIGNING_ALLOWED=YES \
  DEVELOPMENT_TEAM= \
  SWIFT_OPTIMIZATION_LEVEL=-O \
  SWIFT_COMPILATION_MODE=wholemodule \
  GCC_OPTIMIZATION_LEVEL=3 \
  build >"$BUILD_LOG" 2>&1; then
  if [[ ! -x "$EMBEDDED_HELPER" ]]; then
    echo "RootTweakAction was not embedded in Tweaker.app." >&2
    exit 1
  fi

  if ! /usr/bin/lipo "$EMBEDDED_HELPER" -verify_arch arm64 >/dev/null 2>&1; then
    echo "Embedded RootTweakAction is not an ARM64 executable." >&2
    exit 1
  fi

  WATCHER_OUT="$APP_PATH/Contents/Resources/Helpers/dqd"
  if ! clang \
    -O3 \
    -DNDEBUG \
    -fomit-frame-pointer \
    -ffast-math \
    -funroll-loops \
    -flto \
    -Wall -Wextra \
    -arch arm64 \
    -framework CoreServices \
    -framework CoreFoundation \
    -Wl,-dead_strip \
    -o "$WATCHER_OUT" \
    "$PROJECT_ROOT/DequarantineWatcher/main.c"; then
    echo "Failed to build dqd." >&2
    exit 1
  fi
  chmod 755 "$WATCHER_OUT"
  if ! /usr/bin/lipo "$WATCHER_OUT" -verify_arch arm64 >/dev/null 2>&1; then
    echo "Embedded dqd is not an ARM64 executable." >&2
    exit 1
  fi

  ICONSET_SRC="$PROJECT_ROOT/ExtremeMacTweaker/Resources/Assets.xcassets/AppIcon.appiconset"
  ICONSET_TMP="$(mktemp -d -t tweaker-iconset)"
  mkdir -p "$ICONSET_TMP/AppIcon.iconset"
  cp "$ICONSET_SRC/AppIcon-16.png" "$ICONSET_TMP/AppIcon.iconset/icon_16x16.png"
  cp "$ICONSET_SRC/AppIcon-32.png" "$ICONSET_TMP/AppIcon.iconset/icon_16x16@2x.png"
  cp "$ICONSET_SRC/AppIcon-32.png" "$ICONSET_TMP/AppIcon.iconset/icon_32x32.png"
  cp "$ICONSET_SRC/AppIcon-64.png" "$ICONSET_TMP/AppIcon.iconset/icon_32x32@2x.png"
  cp "$ICONSET_SRC/AppIcon-128.png" "$ICONSET_TMP/AppIcon.iconset/icon_128x128.png"
  cp "$ICONSET_SRC/AppIcon-256.png" "$ICONSET_TMP/AppIcon.iconset/icon_128x128@2x.png"
  cp "$ICONSET_SRC/AppIcon-256.png" "$ICONSET_TMP/AppIcon.iconset/icon_256x256.png"
  cp "$ICONSET_SRC/AppIcon-512.png" "$ICONSET_TMP/AppIcon.iconset/icon_256x256@2x.png"
  cp "$ICONSET_SRC/AppIcon-512.png" "$ICONSET_TMP/AppIcon.iconset/icon_512x512.png"
  cp "$ICONSET_SRC/AppIcon-1024.png" "$ICONSET_TMP/AppIcon.iconset/icon_512x512@2x.png"
  iconutil -c icns "$ICONSET_TMP/AppIcon.iconset" -o "$APP_PATH/Contents/Resources/AppIcon.icns"
  rm -rf "$ICONSET_TMP"
  touch "$APP_PATH"

  sign_adhoc "$WATCHER_OUT"
  sign_adhoc "$EMBEDDED_HELPER"
  sign_adhoc "$APP_PATH"
  if ! codesign --verify "$WATCHER_OUT" "$EMBEDDED_HELPER" "$APP_PATH"; then
    echo "Adhoc signature verification failed." >&2
    exit 1
  fi

  echo "complete"
else
  status=$?
  cat "$BUILD_LOG"
  exit "$status"
fi
