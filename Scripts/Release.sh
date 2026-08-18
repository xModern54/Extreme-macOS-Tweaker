#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_SCRIPT="$PROJECT_ROOT/Scripts/Build.sh"
APP_PATH="$PROJECT_ROOT/Tweaker.app"
APP_BINARY="$APP_PATH/Contents/MacOS/Tweaker"
VOLUME_NAME="Extreme Mac Tweaker"
MOUNT_POINT=""
STAGE=""
RW_DMG=""
LOG="$(mktemp -t extreme-mac-tweaker-release.XXXXXX)"

cleanup() {
  eject_release_volumes
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

eject_release_volumes() {
  local vol
  for vol in \
    "/Volumes/Extreme Mac Tweaker" \
    "/Volumes/Extreme Mac Tweaker 1" \
    "/Volumes/Extreme Mac Tweaker 2"; do
    if [[ -d "$vol" ]]; then
      /usr/bin/hdiutil detach "$vol" >/dev/null 2>&1 || \
        /usr/bin/hdiutil detach -force "$vol" >/dev/null 2>&1 || true
    fi
  done
}

mount_point_from_plist() {
  /usr/bin/python3 - "$1" <<'PY'
import plistlib
import sys

with open(sys.argv[1], "rb") as handle:
    payload = plistlib.load(handle)
for entity in payload.get("system-entities", []):
    mount_point = entity.get("mount-point")
    if mount_point:
        print(mount_point)
        raise SystemExit(0)
raise SystemExit(1)
PY
}

set_disk_image_icon() {
  local target="$1"
  local source="$2"
  if ! /usr/bin/osascript - "$source" "$target" >"$LOG" 2>&1 <<'APPLESCRIPT'
use framework "AppKit"
use scripting additions
on run argv
  set sourcePath to item 1 of argv
  set targetPath to item 2 of argv
  set workspace to current application's NSWorkspace's sharedWorkspace()
  set iconImage to workspace's iconForFile:sourcePath
  if iconImage is missing value then error "Failed to read the application icon"
  iconImage's setSize:(current application's NSMakeSize(512, 512))
  if (workspace's setIcon:iconImage forFile:targetPath options:0) as boolean is false then
    error "Failed to assign the disk image icon"
  end if
end run
APPLESCRIPT
  then
    fail "Failed to set the disk image icon."
  fi
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
VOLUME_ICON="$APP_PATH/Contents/Resources/AppIcon.icns"
if [[ ! -f "$VOLUME_ICON" ]]; then
  fail "AppIcon.icns is missing from Tweaker.app."
fi

STAGE="$(mktemp -d -t extreme-mac-tweaker-dmg)"
RW_DMG="${STAGE}.udrw.dmg"

eject_release_volumes
rm -f "$DMG_PATH" "$RW_DMG"
if ! /usr/bin/hdiutil create \
  -volname "$VOLUME_NAME" \
  -size 64m \
  -fs HFS+ \
  -layout SPUD \
  -ov \
  "$RW_DMG" >"$LOG" 2>&1; then
  fail "Failed to create the writable disk image."
fi

if ! /usr/bin/hdiutil attach \
  -readwrite \
  -noverify \
  -noautoopen \
  -plist \
  "$RW_DMG" >"$LOG" 2>&1; then
  fail "Failed to mount the writable disk image."
fi

MOUNT_POINT="$(mount_point_from_plist "$LOG" || true)"
if [[ -z "$MOUNT_POINT" || ! -d "$MOUNT_POINT" ]]; then
  fail "The writable disk image did not mount."
fi
if ! /usr/bin/ditto "$APP_PATH" "$MOUNT_POINT/Tweaker.app"; then
  fail "Failed to copy Tweaker.app onto the disk image."
fi
ln -s /Applications "$MOUNT_POINT/Applications"

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
    try
      set position of item ".fseventsd" of container window to {10000, 10000}
    end try
    try
      set position of item ".DS_Store" of container window to {10000, 10000}
    end try
    try
      set position of item ".VolumeIcon.icns" of container window to {10000, 10000}
    end try
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

/usr/bin/osascript -e "tell application \"Finder\" to close every window of disk \"${VOLUME_NAME}\"" >/dev/null 2>&1 || true

if ! /usr/bin/ditto "$VOLUME_ICON" "$MOUNT_POINT/.VolumeIcon.icns"; then
  fail "Failed to copy the volume icon."
fi
if [[ -x /usr/bin/SetFile ]]; then
  /usr/bin/SetFile -c icnC "$MOUNT_POINT/.VolumeIcon.icns" >/dev/null 2>&1 || true
  /usr/bin/SetFile -a C "$MOUNT_POINT" >/dev/null 2>&1 || true
fi
if [[ ! -f "$MOUNT_POINT/.VolumeIcon.icns" ]]; then
  fail "The volume icon was not written to the disk image."
fi
/usr/bin/osascript >"$LOG" 2>&1 <<EOF || true
tell application "Finder"
  tell disk "$VOLUME_NAME"
    open
    try
      set position of item ".VolumeIcon.icns" of container window to {10000, 10000}
    end try
    close
  end tell
end tell
EOF

rm -rf \
  "$MOUNT_POINT/.fseventsd" \
  "$MOUNT_POINT/.Spotlight-V100" \
  "$MOUNT_POINT/.Trashes" \
  "$MOUNT_POINT/.TemporaryItems" \
  "$MOUNT_POINT/.DocumentRevisions-V100"
sync

eject_release_volumes
if [[ -d "$MOUNT_POINT" ]]; then
  fail "Failed to unmount the writable disk image."
fi

if ! /usr/bin/hdiutil convert \
  "$RW_DMG" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -ov \
  -o "$DMG_PATH" >"$LOG" 2>&1; then
  fail "Failed to create $DMG_NAME."
fi

if ! /usr/bin/hdiutil attach -readonly -nobrowse -noautoopen -plist "$DMG_PATH" >"$LOG" 2>&1; then
  fail "Failed to verify $DMG_NAME."
fi
VERIFY_MOUNT="$(mount_point_from_plist "$LOG" || true)"
if [[ -z "$VERIFY_MOUNT" ]]; then
  fail "Failed to mount $DMG_NAME for verification."
fi
if [[ -e "$VERIFY_MOUNT/.fseventsd" ]]; then
  /usr/bin/hdiutil detach "$VERIFY_MOUNT" >/dev/null 2>&1 || true
  fail ".fseventsd must not be included in the disk image."
fi
if [[ ! -f "$VERIFY_MOUNT/.VolumeIcon.icns" ]]; then
  /usr/bin/hdiutil detach "$VERIFY_MOUNT" >/dev/null 2>&1 || true
  fail "The volume icon is missing from the disk image."
fi
/usr/bin/hdiutil detach "$VERIFY_MOUNT" >/dev/null 2>&1 || \
  /usr/bin/hdiutil detach -force "$VERIFY_MOUNT" >/dev/null 2>&1 || true

set_disk_image_icon "$DMG_PATH" "$APP_PATH"

if ! /usr/bin/codesign --force --sign - --timestamp=none "$DMG_PATH" >"$LOG" 2>&1; then
  fail "Failed to adhoc-sign $DMG_NAME."
fi

if ! /usr/bin/codesign --verify "$DMG_PATH" >"$LOG" 2>&1; then
  fail "Adhoc signature verification failed for $DMG_NAME."
fi

echo "complete"
