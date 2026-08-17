# Security Trust Framework File Caching Helper — trustdFileHelper

## Basics

- **Main label:** `system/com.apple.trustdFileHelper`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.trustdFileHelper.plist`
- **Binary:** `/usr/libexec/trustdFileHelper`
- **Domain:** `system`
- **Category:** `auth_security_trust`
- **Risk:** `4` (Critical System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`trustdFileHelper` (Trust Daemon File Helper) is Apple's Security Trust framework file caching and database helper daemon:

1. **SSL/TLS Certificate Store Helper**: Acts as the isolated database helper for `trustd`, reading, validating, and updating local SQLite databases for trusted Root Certificates, Certificate Revocation Lists (CRLs), and OCSP responses in `/var/db/tls/` and `/private/var/protected/trustd/`.
2. **HTTPS & Code-Signing Validation Engine**: Supports `trustd` in verifying SSL/TLS certificates for all HTTPS connections (`git`, `curl`, `npm`, `pip`, web browsers) and application code-signing certificates.

## Why It Must Remain Enabled

- Disabling `trustdFileHelper` **completely breaks SSL/TLS certificate validation across macOS**: Web browsers, `git`, `curl`, package managers (`npm`, `pip`, Homebrew), and Xcode fail all HTTPS/TLS connections with certificate verification errors (`SSL_ERROR`).
- Explicitly protected in `AGENTS.md` core security guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
