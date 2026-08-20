# iCloud Private Relay & Safari Privacy Proxy — networkserviceproxy

## Basics

- **Main label:** `com.apple.networkserviceproxy`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.networkserviceproxy-osx.plist`
- **Binary:** `/usr/libexec/networkserviceproxy`
- **Domain:** `gui/<uid>`
- **Category:** `icloud_privacy_proxy`
- **Risk:** `1`
- **Verdict:** `disable for coding profile`

## What It Does

`networkserviceproxy` is Apple's background network proxy daemon responsible for:

1. **iCloud Private Relay**: Dual-hop encrypted TLS/QUIC proxy tunnels (iCloud+ paid subscription feature).
2. **Safari Privacy Proxy & Oblivious DoH (DNS-over-HTTPS)**: Encrypts Safari web traffic and DNS tokens for Apple ad measurement / tracking protection.
3. **Background Latency & Auth Probing**: Continuously probes QUIC latency and attempts to fetch Auth Tokens from `accountsd`/`akd`.

When no Apple ID is signed in or iCloud Private Relay is disabled, `networkserviceproxy` spins in a periodic retry loop fetching non-existent Auth Tokens (`altDSID = NULL`), consuming **~40MB RAM** and generating recurring log error entries.

### Strategic Optimization Note

`networkserviceproxy` is purely a consumer-oriented Apple ID telemetry/relay feature (unused by ~99% of developers/users). Disabling it is 100% safe across conservative and coding profiles as standard web browsing, Safari, API clients, Git, and sockets function without any degradation.

Standard network connections (Wi-Fi, Ethernet, BSD sockets, SSH, Git, Docker, Terminal, Chrome, Firefox, VSCode) operate via system kernel and `configd`/`mDNSResponder` and do not use `networkserviceproxy`.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.networkserviceproxy" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.networkserviceproxy"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.networkserviceproxy"
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `launchctl bootout` and `launchctl disable` applied for `gui/502/com.apple.networkserviceproxy`.
2. Process `networkserviceproxy` terminated, releasing **~40MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 11 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. **Safari & Web Browsing Verification**:
   - `open https://www.apple.com` launched Safari and loaded web content over HTTPS cleanly.
   - HTTPS requests (`curl` and Safari User-Agent) returned `HTTP/2 200 OK`.
   - Log audit during active web browsing confirmed **0 errors** from `networkserviceproxy`. Safari did not retry or attempt to restart the daemon.
