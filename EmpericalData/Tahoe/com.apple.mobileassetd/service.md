# MobileAsset System Assets Downloader — mobileassetd

## Basics

- **Main label:** `com.apple.mobileassetd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.mobileassetd.plist`
- **Binary:** `/usr/libexec/mobileassetd`
- **Domain:** `system`
- **Category:** `background_asset_downloads`
- **Risk:** `2`
- **Verdict:** `disable for coding profile`

## What It Does

`mobileassetd` is Apple's MobileAsset framework daemon. It handles background querying, downloading, caching, and updating of supplemental system asset bundles from Apple CDNs (`mesu.apple.com`, `appldnld.apple.com`):

- High-quality Siri voices and speech synthesis models.
- Supplemental fonts and language asset packs.
- System dictionaries and spellcheck update files.
- Aerial wallpaper video catalog metadata.
- CoreML / Neural Engine vision & OCR assets.

Disabling `mobileassetd` does **NOT** break macOS system updates (`softwareupdated` is a separate daemon), SSH, Wi-Fi, developer tools, or basic desktop functionality. It prevents unneeded background asset downloads and frees **~41-48MB RAM**.

## Disable

```bash
sudo launchctl bootout system/com.apple.mobileassetd
sudo launchctl disable system/com.apple.mobileassetd
```

## Rollback

```bash
sudo launchctl enable system/com.apple.mobileassetd
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `sudo launchctl bootout` and `sudo launchctl disable` applied for `system/com.apple.mobileassetd`.
2. Process `mobileassetd` terminated, releasing **~42MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 10 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed: `mobileassetd` remains stopped after reboot, no retry loops, SSH/Wi-Fi/networking fully operational.
