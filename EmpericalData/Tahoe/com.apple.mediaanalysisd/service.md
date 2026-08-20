# Media / Photo Analysis

## Basics

- **Main labels:** `com.apple.mediaanalysisd`, `com.apple.photoanalysisd`
- **Related label:** `com.apple.revisiond`
- **Processes:** `mediaanalysisd`, `photoanalysisd`, `revisiond`
- **Domains:** `gui/<uid>`, `system`
- **Category:** `photos_media_analysis`
- **Risk:** `1-2`
- **Verdict:** `disable for coding profile`

## What It Does

Apple media/photo analysis stack: photo library analysis, face/object/media analysis, visual embeddings, Photos memories/featured content, wallpaper/photo processing, video analysis sessions, and HomeKit/mediaanalysis hooks.

Not needed for this coding-only machine because Photos/HomeKit/media intelligence features are not part of the workflow.

## Current Cost

Observed on 2026-06-19 under `codexadmin`:

```text
mediaanalysisd   49.3 MB
photoanalysisd   17.8 MB
revisiond        10.1 MB
```

The user-provided snapshot from `xmodern` showed `mediaanalysisd` at about `87.1 MB`.

Physical payload:

```text
/System/Library/PrivateFrameworks/MediaAnalysis.framework   249 MB
/System/Library/PrivateFrameworks/PhotoAnalysis.framework   6.5 MB
/System/Library/PrivateFrameworks/GenerationalStorage.framework 352 KB
/System/Library/AssetsV2/com_apple_MobileAsset_VCPMobileAssets 7.2 MB
/System/Library/Photos 31 MB
```

## Known Launchd Labels

Core media/photo analysis:

```text
gui/<uid>/com.apple.mediaanalysisd
gui/<uid>/com.apple.photoanalysisd
```

Related system daemon:

```text
system/com.apple.revisiond
```

## Related Endpoints

Seen under `mediaanalysisd`:

```text
com.apple.mediaanalysisd.photos
com.apple.mediaanalysisd.analysis
com.apple.mediaanalysisd.computeservice
com.apple.mediaanalysisd.embeddingstore
com.apple.mediaanalysisd.realtime
com.apple.mediaanalysisd.service.public
com.apple.mediaanalysisd.videosession.public
com.apple.mediaanalysisd.xpcstore.spl.vuindex
com.apple.mediaanalysisd.homekit
com.apple.mediaanalysisd.homekitsession
```

Seen under `photoanalysisd`:

```text
com.apple.photoanalysisd
```

Notable background tasks:

```text
com.apple.mediaanalysisd.background.scheduler
com.apple.photoanalysisd.backgroundanalysis
com.apple.photoanalysisd.highlightenrichment
com.apple.photoanalysisd.libraryprocessing
com.apple.photoanalysisd.wallpaper
com.apple.photoanalysisd.featuredcontent
```

Several `photoanalysisd` tasks require external power and can prevent sleep.

## Candidate Disable

Stage 1, core media/photo analysis:

```bash
uid=$(id -u)

for svc in \
com.apple.mediaanalysisd \
com.apple.photoanalysisd
do
  launchctl disable gui/$uid/$svc
  launchctl bootout gui/$uid/$svc 2>/dev/null || true
done
```

Stage 2, related revision daemon, only if needed after separate testing:

```bash
sudo launchctl disable system/com.apple.revisiond
sudo launchctl bootout system/com.apple.revisiond 2>/dev/null || true
```

## Rollback

```bash
uid=$(id -u)

for svc in \
com.apple.mediaanalysisd \
com.apple.photoanalysisd
do
  launchctl enable gui/$uid/$svc
done

sudo launchctl enable system/com.apple.revisiond
```

Reboot after rollback.

## Test Result

2026-06-19 temporary bootout test succeeded.

Before:

```text
mediaanalysisd  49.2 MB
photoanalysisd  17.8 MB

BEFORE_MEDIA_ANALYSIS_RSS: 2 processes, 67.0 MB
```

Commands:

```bash
uid=$(id -u)

for svc in \
com.apple.mediaanalysisd \
com.apple.photoanalysisd
do
  launchctl bootout gui/$uid/$svc 2>/dev/null || true
done
```

After:

```text
AFTER_MEDIA_ANALYSIS_RSS: 0 processes, 0.0 MB
```

They did not restart after 5 seconds. `revisiond` was not touched.

2026-06-19 persistent disable reboot test succeeded.

Commands:

```bash
uid=$(id -u)

for svc in \
com.apple.mediaanalysisd \
com.apple.photoanalysisd
do
  launchctl disable gui/$uid/$svc
  launchctl bootout gui/$uid/$svc 2>/dev/null || true
done
```

After reboot at 12 seconds uptime:

```text
MEDIA_ANALYSIS_RSS: 0 processes, 0.0 MB

com.apple.photoanalysisd => disabled
com.apple.mediaanalysisd => disabled
```

Console login and passwordless sudo still worked. `revisiond` was not disabled.
