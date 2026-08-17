# Accounts Framework Daemon — accountsd

## Basics

- **Main label:** `gui/<uid>/com.apple.accountsd`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.accountsd.plist`
- **Binary:** `/System/Library/Frameworks/Accounts.framework/Versions/A/Support/accountsd`
- **Domain:** `gui/<uid>`
- **Category:** `system_accounts_icloud_sso`
- **Risk:** `4` (Critical System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`accountsd` (Accounts Daemon) is Apple's per-user Accounts Framework (`Accounts.framework`) daemon:

1. **Account Store & Credentials Manager (`com.apple.accountsd.accountmanager`)**: Stores and serves authentication tokens for Apple ID, iCloud, Google, Exchange, CalDAV, CardDAV, and internet accounts.
2. **OAuth Signer Engine (`com.apple.accountsd.oauthsigner`)**: Signs OAuth 2.0 authorization tokens for web and app logins.
3. **Xcode Developer Signing Account Service**: Serves Apple Developer Account credentials for Xcode code signing profiles.

## Why It Must Remain Enabled

- Disabling `accountsd` **completely breaks all macOS user accounts** (Apple ID, Google, Exchange logins fail) and disables Xcode application code signing capabilities.

## Status

**KEPT ENABLED AND PROTECTED.**
