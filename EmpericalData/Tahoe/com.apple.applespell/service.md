# System Spell Checking & Autocorrect Engine — AppleSpell

## Basics

- **Main label:** `gui/<uid>/com.apple.applespell`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.applespell.plist`
- **Binary:** `/System/Library/Services/AppleSpell.service/Contents/MacOS/AppleSpell`
- **Domain:** `gui/<uid>`
- **Category:** `ui_text_input_spelling`
- **Risk:** `1` (for standard coding profiles)
- **Verdict:** `disable for coding profile`

## What It Does

`AppleSpell` (Apple Spell Checker & Grammar Daemon) is Apple's primary system-wide spell checking, grammar verification, and text autocorrection service (`ProofReader.framework` / `NSSpellServer`):

1. **System Spell Check & Red Underline Engine**: Analyzes typed text across macOS applications (Safari, Notes, TextEdit, input fields) against language dictionary databases (`ru`, `en_US`, `de`, `fr`, etc.), highlighting typos with red squiggly underlines.
2. **Text Autocorrection & Suggestions**: Provides automated word replacements and predictive text suggestions during typing.

## What Is NOT Affected

- **Text Input & Keyboard Switching**: Keyboard typing across all languages, input methods, keyboard shortcut switching (`Cmd+Space` via `TextInputSwitcher`), VSCode, Xcode, Terminal, Git, Docker, SSH, Wi-Fi, and audio operate **100% normally**.
- **System Memory**: Eliminates persistent XPC service, freeing **~35MB RSS RAM**.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.applespell" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.applespell"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.applespell"
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502/com.apple.applespell`.
2. Process `AppleSpell` terminated, releasing **~35MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 11 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `AppleSpell` process remains stopped permanently.
   - Keyboard typing, layout switching, Terminal, Git, VSCode, Docker, and system stability operate 100% normally.
   - Log audit confirmed 0 errors or retry loops.
