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

  echo "complete"
else
  status=$?
  cat "$BUILD_LOG"
  exit "$status"
fi
