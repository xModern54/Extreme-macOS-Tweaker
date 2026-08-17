#!/usr/bin/env bash

set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_PATH="$PROJECT_ROOT/ExtremeMacTweaker.xcodeproj"
DERIVED_DATA_PATH="$PROJECT_ROOT/.build/DerivedData"
EMBEDDED_HELPER="$DERIVED_DATA_PATH/Build/Products/Release/Tweaker.app/Contents/Resources/Helpers/RootTweakAction"
BUILD_LOG="$(mktemp -t extreme-mac-tweaker-build.XXXXXX)"

cleanup() {
  rm -f "$BUILD_LOG"
}
trap cleanup EXIT

if xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme ExtremeMacTweaker \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=YES \
  CODE_SIGNING_ALLOWED=NO \
  build >"$BUILD_LOG" 2>&1; then
  if [[ ! -x "$EMBEDDED_HELPER" ]]; then
    echo "RootTweakAction was not embedded in Tweaker.app." >&2
    exit 1
  fi

  if ! /usr/bin/lipo "$EMBEDDED_HELPER" -verify_arch arm64 >/dev/null 2>&1; then
    echo "Embedded RootTweakAction is not an ARM64 executable." >&2
    exit 1
  fi

  APP_PATH="$DERIVED_DATA_PATH/Build/Products/Release/Tweaker.app"
  WATCHER_OUT="$APP_PATH/Contents/Resources/Helpers/dequarantine-watcher"
  if ! clang -O2 -Wall -Wextra -arch arm64 \
    -framework CoreServices \
    -framework CoreFoundation \
    -o "$WATCHER_OUT" \
    "$PROJECT_ROOT/DequarantineWatcher/main.c"; then
    echo "Failed to build dequarantine-watcher." >&2
    exit 1
  fi
  chmod 755 "$WATCHER_OUT"
  if ! /usr/bin/lipo "$WATCHER_OUT" -verify_arch arm64 >/dev/null 2>&1; then
    echo "Embedded dequarantine-watcher is not an ARM64 executable." >&2
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

  echo "complete"
else
  status=$?
  cat "$BUILD_LOG"
  exit "$status"
fi
