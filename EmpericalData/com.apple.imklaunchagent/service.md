# Input Method Kit Launch Agent — imklaunchagent

## Basics

- **Main label:** `gui/<uid>/com.apple.imklaunchagent`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.imklaunchagent.plist`
- **Binary:** `/System/Library/Frameworks/InputMethodKit.framework/Resources/imklaunchagent`
- **Domain:** `gui/<uid>`
- **Category:** `ui_input_method_kit`
- **Risk:** `1` (for users not relying on text replacement shortcuts or CJK IME input methods)
- **Verdict:** `disable for coding profile`

## What It Does

`imklaunchagent` (Input Method Kit Launch Agent) is Apple's InputMethodKit framework dispatcher:

1. **Text Replacement Dispatcher**: Processes custom text replacement rules and text shortcuts configured in *System Settings -> Keyboard -> Text Replacement*.
2. **CJK IME & Custom Input Method Launcher**: Serves as the launch coordinator for complex character input methods (Chinese Pinyin/Zhuyin, Japanese Kana/Romaji, Korean Hangul) and custom input method plugins located in `/Library/Input Methods/`.

## What Is NOT Affected

- **Standard Keyboard Typing & Layout Switching**: Standard English and Russian text typing, single-key layout switching (Caps Lock / `Cmd+Space`), Menu Bar language flags, typing in Terminal, VSCode, Git, Docker, SSH, Wi-Fi, and sound operate **100% normally**.
- **System Memory**: Eliminates persistent GUI agent, freeing **~12.5MB RSS RAM**.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.imklaunchagent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.imklaunchagent"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.imklaunchagent"
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502/com.apple.imklaunchagent`.
2. Process `imklaunchagent` terminated, releasing **~12.5MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 11 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `imklaunchagent` process remains stopped permanently.
   - Standard English/Russian text input and layout switching operate 100% normally.
   - Log audit confirmed 0 errors or retry loops.
