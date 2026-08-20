# Image Capture Devices Discovery Daemon — icdd

## Basics

- **Main label:** `gui/<uid>/com.apple.icdd`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.icdd.plist`
- **Binary:** `/System/Library/Image Capture/Support/icdd`
- **Domain:** `gui/<uid>`
- **Category:** `hardware_image_capture_scanners_cameras`
- **Risk:** `1` (for non-users of Image Capture.app with cameras/scanners)
- **Verdict:** `disable for coding profile`

## What It Does

`icdd` (Image Capture Devices Daemon) is Apple's per-user background scanner and camera discovery agent:

1. **Hardware & Network Camera/Scanner Discovery (`com.apple.icdd`)**: Polls USB buses and Bonjour network services to detect DSLR cameras (Canon, Nikon, Sony), flatbed scanners, and MFU devices for image importing via Apple's default *Image Capture.app*.
2. **Persistent Daemon Process**: Runs persistently (`KeepAlive: true` & `RunAtLoad: true`) with a 175MB Jetsam memory limit.

## What Is NOT Affected

- **FaceTime Webcams & USB Webcams**: FaceTime HD camera, external USB webcams, printing, USB flash drives, and iPhone/iPad device connections operate **100% normally**.
- **System Performance & Developer Tools**: Xcode, Terminal, Git, Docker, SSH, Wi-Fi, and sound run without any degradation.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.icdd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.icdd"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.icdd"
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502/com.apple.icdd`.
2. Process `icdd` terminated, releasing **~15MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 10 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `icdd` process remains stopped.
   - FaceTime camera, printing, and system stability operate normally.
   - Log audit confirmed 0 errors or retry loops.
