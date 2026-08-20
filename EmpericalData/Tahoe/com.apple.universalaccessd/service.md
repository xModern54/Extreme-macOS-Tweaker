# Universal Access session daemon — `com.apple.universalaccessd` (DO NOT DISABLE)

## Basics

| Field         | Value                                                                 |
|---------------|-----------------------------------------------------------------------|
| Process       | `universalaccessd`                                                    |
| Binary        | `/usr/sbin/universalaccessd`                                          |
| Signing ID    | `com.apple.universalaccessd`                                          |
| Plist         | `/System/Library/LaunchAgents/com.apple.universalaccessd.plist`       |
| Domain        | `gui/<uid>`                                                           |
| Owner         | Apple (system)                                                        |
| Category      | `ui_required` — Universal Access / accessibility session plumbing       |
| Risk Level    | **3** — breaks accessibility init and persistence after reboot        |
| Profile       | **protected — keep enabled**                                            |

**Command line:** `/usr/sbin/universalaccessd launchd -s` (`-s` = session startup coordinator)

## What It Does

Per-user daemon that **initializes and applies Universal Access settings at login**. Not only VoiceOver / Screen Reader — also everyday display and pointer customization.

| Responsibility | Detail |
|----------------|--------|
| Session bootstrap | Applies saved accessibility prefs when GUI session starts (`RunAtLoad: true`) |
| Display | **Increase Contrast**, **Reduce Transparency**, related display filters |
| Pointer | **Cursor color**, **cursor size**, pointer/UI scaling hooks |
| Input / motion | Sticky Keys, Slow Keys, Mouse Keys, Reduce Motion plumbing |
| XPC | `com.apple.universalaccessd.running`, `com.apple.universalaccessd.startup` |

Works with the broader accessibility UI stack:

| Related process | Role |
|-----------------|------|
| `AccessibilityUIServer` | Accessibility UI server (LaunchAngel) |
| `AccessibilityVisualsAgent` | Visual overlays / accessibility visuals |
| `axassetsd` | Accessibility asset loader |

**Not the same as** `com.apple.accessibility.heard` (Hearing / Live Listen) — that narrow slice was disabled separately and validated.

## Observed Cost

| Metric   | Value (target idle) |
|----------|---------------------|
| RSS      | ~40–42 MB           |
| CPU idle | 0%                  |
| Disk     | 0 MB/s              |
| Network  | 0 Mbps              |

Collateral when disabled after reboot: `AccessibilityUIServer` (~63 MB) and `AccessibilityVisualsAgent` (~57 MB) also failed to start on target — ~120 MB stack absent, not a safe win.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.universalaccessd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.universalaccessd"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.universalaccessd"
launchctl bootstrap "gui/$uid" /System/Library/LaunchAgents/com.apple.universalaccessd.plist
sudo shutdown -r now
```

## Test Result (2026-06-28, target `codexadmin` uid 502)

### Phase 1 — bootout only (no disable, no reboot)

- `universalaccessd` exited and did not respawn within ~30s.
- `AccessibilityUIServer` and `AccessibilityVisualsAgent` **remained running**.
- **GUI-confirmed:** contrast and other accessibility toggles still worked when changed manually in System Settings.

### Phase 2 — disable + clean reboot

- `launchctl disable gui/502/com.apple.universalaccessd` + reboot.
- `universalaccessd` did not return; label stayed disabled.
- `AccessibilityUIServer` and `AccessibilityVisualsAgent` **did not start** after reboot (only `axassetsd` remained).
- **GUI-confirmed breakage pattern:**
  - Accessibility features **appear broken at session level** after reboot.
  - Manual changes in Settings (e.g. **Increase Contrast**) can still apply in the current session.
  - **Settings do not persist across reboot** — revert to default until daemon is restored.
  - **Cursor customization** (color, size) also depends on this init path.
- Headless health after reboot: SSH, Wi‑Fi, DNS, `audiomxd`, `audioaccessoryd`, `replayd`, `bluetoothd` OK.
- No universalaccess error storm in unified logs.

### Rollback — enable + bootstrap + reboot

- `universalaccessd`, `AccessibilityUIServer`, `AccessibilityVisualsAgent` all returned.
- Label `com.apple.universalaccessd` => **enabled**.

**Conclusion:** keep enabled. Required for **boot-time initialization and persistence** of basic accessibility/display/pointer settings — not optional VoiceOver-only infrastructure.

## Expected Breakage If Disabled

| Area | Effect |
|------|--------|
| Increase Contrast / Reduce Transparency | May toggle manually in-session; **lost after reboot** |
| Cursor color / size | Customization **not restored** at login |
| Zoom, motion, input accessibility | Init/persistence broken |
| Accessibility UI stack | `AccessibilityUIServer` / `AccessibilityVisualsAgent` may fail to start after reboot |
| SSH / Wi‑Fi / audio / screenshots | Not broken in our test |

For a coding machine, basic contrast and cursor customization are still legitimate needs — do not disable to save ~40 MB.

## Notes

- Task Manager diagnostics may be captured on Control Mac; validation was performed on target via `ssh c`.
- `heard` remains a separate, narrower disable candidate; do not batch-disable the whole accessibility stack.
- Future tweaker: group under **“Do you need accessibility/display/pointer settings to persist at login?”** → default **yes** → keep `com.apple.universalaccessd` enabled.