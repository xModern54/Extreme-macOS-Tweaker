# FinanceKit / Wallet / PassKit / Apple Pay NFC

## Basics

- **Main label:** `com.apple.financed`
- **Related labels:** `com.apple.passd`, `com.apple.nfcd`, `com.apple.seld`
- **Processes:** `financed`, `passd`, `nfcd`, `seld`, `NFStorageServer`
- **Domains:** `gui/<uid>`, `system`
- **Category:** `wallet_finance_applepay`
- **Risk:** `2`
- **Verdict:** `likely safe if Wallet, Apple Pay, passes, orders, and FinanceKit are unused`

## What It Does

This group covers Apple's FinanceKit, Wallet / PassKit, and Apple Pay near-field runtime.

Observed roles:

```text
financed  - FinanceKit storage, financial data, orders, background maintenance
passd     - Wallet / PassKit agent, passes, payments, Apple Pay push/XPC endpoints
nfcd      - NFC / near-field daemon running as _applepay
seld      - Secure element daemon running as _applepay
```

`NFStorageServer` was also observed, but it is an XPC service under NearFieldPrivateServices and disappeared when `nfcd` / `seld` were unloaded.

## Observed Cost

Observed on 2026-06-20 under `codexadmin`:

```text
financed        ~22 MB RSS
nfcd            ~13 MB RSS
seld            ~10 MB RSS
NFStorageServer  ~7 MB RSS
passd             not running at capture time, but launchable
```

Total observed active RSS: about `52 MB`.

The user-provided `xmodern` snapshot showed `financed` at about `13.7 MB`.

## Launchd Labels

```text
gui/<uid>/com.apple.financed
gui/<uid>/com.apple.passd
system/com.apple.nfcd
system/com.apple.seld
```

Important XPC endpoints:

```text
com.apple.financed.service.coredatastore
com.apple.financed.service.financestore
com.apple.financed.service.store
com.apple.aps.financed
com.apple.aps.financed.store

com.apple.passd.account
com.apple.passd.aps
com.apple.passd.assertions
com.apple.passd.bulletins
com.apple.passd.cloud-store
com.apple.passd.device-registration
com.apple.passd.in-app-payment
com.apple.passd.library
com.apple.passd.payment
com.apple.passd.payment-continuity
com.apple.passd.sharing-channel
com.apple.passd.trusted-device-enrollment-info-provider
com.apple.usernotifications.delegate.com.apple.Passbook
com.apple.private.alloy.applepay-idswake

com.apple.nfcd
com.apple.nfcd.hwmanager
com.apple.seld.aps
com.apple.seld.tsmmanager
```

## Disable

```bash
uid=$(id -u)

for svc in \
com.apple.financed \
com.apple.passd
do
  launchctl bootout gui/$uid/$svc 2>/dev/null || true
  launchctl disable gui/$uid/$svc
done

for svc in \
com.apple.nfcd \
com.apple.seld
do
  sudo launchctl bootout system/$svc 2>/dev/null || true
  sudo launchctl disable system/$svc
done
```

## Rollback

```bash
uid=$(id -u)

for svc in \
com.apple.financed \
com.apple.passd
do
  launchctl enable gui/$uid/$svc
done

for svc in \
com.apple.nfcd \
com.apple.seld
do
  sudo launchctl enable system/$svc
done

sudo shutdown -r now
```

## Test Result

2026-06-20: persistent disable was applied on the target Mac.

Before:

```text
financed        running
nfcd            running
seld            running
NFStorageServer running
passd           not running, but enabled
```

Applied:

```bash
launchctl bootout gui/502/com.apple.financed
launchctl disable gui/502/com.apple.financed

launchctl bootout gui/502/com.apple.passd
launchctl disable gui/502/com.apple.passd

sudo launchctl bootout system/com.apple.nfcd
sudo launchctl disable system/com.apple.nfcd

sudo launchctl bootout system/com.apple.seld
sudo launchctl disable system/com.apple.seld
```

Immediate result:

```text
financed absent
passd absent
nfcd absent
seld absent
NFStorageServer absent
```

Post-reboot result:

```text
No FinanceKit / Wallet / PassKit / Apple Pay NFC processes observed.
Disabled overrides persisted in gui/502 and system domains.
SSH/network/route check OK.
No FinanceKit/Wallet/PassKit/nfcd/seld log noise observed after boot.
```

## Expected Breakage

This disables:

```text
Wallet app backend
PassKit passes
Apple Pay flows
FinanceKit data/order integrations
NFC secure element Apple Pay support
Wallet / Passbook notifications and push endpoints
```

Expected impact for current coding-only profile:

```text
Low, if Wallet, Apple Pay, passes, and FinanceKit integrations are unused on this Mac.
```
