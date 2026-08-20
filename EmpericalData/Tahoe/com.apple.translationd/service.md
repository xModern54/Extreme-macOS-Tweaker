# Apple System Translation Engine Daemon — translationd

## Basics

- **Main label:** `gui/<uid>/com.apple.translationd`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.translationd.plist`
- **Binary:** `/System/Library/Frameworks/Translation.framework/translationd`
- **Domain:** `gui/<uid>`
- **Category:** `ai_translation_service`
- **Risk:** `1`
- **Verdict:** `disable for coding profile`

## What It Does

`translationd` (Translation Daemon) is Apple's system-wide text and webpage translation engine:

1. **System Right-Click Text Translation (`Translation.framework`)**: Translates selected text in Safari, Messages, Notes, and macOS applications via local neural language models.
2. **Safari Webpage Translation (`com.apple.translation.text`)**: Translates full webpages directly inside Safari.

## What Is NOT Affected

- **Third-Party Web Translators**: Google Translate, DeepL, and Yandex Translate in any web browser (Chrome, Safari, Firefox), VSCode, Terminal, Git, Docker, SSH, Wi-Fi, and sound operate **100% normally**.
- **System Memory**: Eliminates persistent GUI daemon, freeing **~22MB RSS RAM** in idle mode and avoiding up to **500MB RAM** spikes during language model loading.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.translationd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.translationd"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.translationd"
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502/com.apple.translationd`.
2. Process `translationd` terminated, releasing **~22MB RSS RAM** (up to 500MB active soft limit).
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 12 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `translationd` process remains stopped permanently.
   - Web development and system performance operate 100% normally.
   - Log audit confirmed 0 errors or retry loops.
