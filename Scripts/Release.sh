#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_SCRIPT="$PROJECT_ROOT/Scripts/Build.sh"
APP_PATH="$PROJECT_ROOT/Tweaker.app"
APP_BINARY="$APP_PATH/Contents/MacOS/Tweaker"
VOLUME_NAME="Extreme Mac Tweaker"
MOUNT_POINT="/Volumes/${VOLUME_NAME}"
STAGE=""
RW_DMG=""
LOG="$(mktemp -t extreme-mac-tweaker-release.XXXXXX)"

cleanup() {
  if [[ -d "$MOUNT_POINT" ]]; then
    /usr/bin/hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || \
      /usr/bin/hdiutil detach -force "$MOUNT_POINT" >/dev/null 2>&1 || true
  fi
  if [[ -n "$STAGE" && -d "$STAGE" ]]; then
    rm -rf "$STAGE"
  fi
  if [[ -n "$RW_DMG" && -f "$RW_DMG" ]]; then
    rm -f "$RW_DMG"
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
RW_DMG="${STAGE}.udrw.dmg"
if ! /usr/bin/ditto "$APP_PATH" "$STAGE/Tweaker.app"; then
  fail "Failed to stage Tweaker.app for the disk image."
fi
ln -s /Applications "$STAGE/Applications"
VOLUME_ICON="$APP_PATH/Contents/Resources/AppIcon.icns"

/usr/bin/hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || true
rm -f "$DMG_PATH" "$RW_DMG"
if ! /usr/bin/hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDRW \
  -fs HFS+ \
  "$RW_DMG" >"$LOG" 2>&1; then
  fail "Failed to create the writable disk image."
fi

if ! /usr/bin/hdiutil resize -size 64m "$RW_DMG" >"$LOG" 2>&1; then
  fail "Failed to resize the writable disk image."
fi

if ! /usr/bin/hdiutil attach \
  -readwrite \
  -noverify \
  -noautoopen \
  "$RW_DMG" >"$LOG" 2>&1; then
  fail "Failed to mount the writable disk image."
fi

for _ in $(seq 1 50); do
  if [[ -d "$MOUNT_POINT/Tweaker.app" && -e "$MOUNT_POINT/Applications" ]]; then
    break
  fi
  sleep 0.1
done
if [[ ! -d "$MOUNT_POINT/Tweaker.app" ]]; then
  fail "The writable disk image did not mount at ${MOUNT_POINT}."
fi

if [[ -f "$VOLUME_ICON" ]]; then
  cp "$VOLUME_ICON" "$MOUNT_POINT/.VolumeIcon.icns"
  if [[ -x /usr/bin/SetFile ]]; then
    /usr/bin/SetFile -c icnC "$MOUNT_POINT/.VolumeIcon.icns" >/dev/null 2>&1 || true
    /usr/bin/SetFile -a C "$MOUNT_POINT" >/dev/null 2>&1 || true
  fi
fi

if ! /usr/bin/osascript >"$LOG" 2>&1 <<EOF
tell application "Finder"
  tell disk "$VOLUME_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set sidebar width of container window to 0
    set the bounds of container window to {360, 180, 960, 580}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 128
    delay 0.4
    set position of item "Tweaker.app" of container window to {160, 200}
    set position of item "Applications" of container window to {440, 200}
    delay 0.4
    set position of item "Tweaker.app" of container window to {160, 200}
    set position of item "Applications" of container window to {440, 200}
    close
    open
    update without registering applications
    delay 2
    close
  end tell
end tell
EOF
then
  fail "Failed to apply the Finder window layout. Allow Automation access for Finder if prompted."
fi

if [[ -x /usr/sbin/bless ]]; then
  /usr/sbin/bless --folder "$MOUNT_POINT" --openfolder "$MOUNT_POINT" >/dev/null 2>&1 || true
fi

sync
/usr/bin/osascript -e "tell application \"Finder\" to eject disk \"${VOLUME_NAME}\"" >/dev/null 2>&1 || true
sleep 1
if [[ -d "$MOUNT_POINT" ]]; then
  if ! /usr/bin/hdiutil detach "$MOUNT_POINT" >"$LOG" 2>&1; then
    /usr/bin/hdiutil detach -force "$MOUNT_POINT" >"$LOG" 2>&1 || \
      fail "Failed to unmount the writable disk image."
  fi
fi

if ! /usr/bin/hdiutil convert \
  "$RW_DMG" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -ov \
  -o "$DMG_PATH" >"$LOG" 2>&1; then
  fail "Failed to create $DMG_NAME."
fi

if ! /usr/bin/codesign --force --sign - --timestamp=none "$DMG_PATH" >"$LOG" 2>&1; then
  fail "Failed to adhoc-sign $DMG_NAME."
fi

if ! /usr/bin/codesign --verify "$DMG_PATH" >"$LOG" 2>&1; then
  fail "Adhoc signature verification failed for $DMG_NAME."
fi

echo "complete"
