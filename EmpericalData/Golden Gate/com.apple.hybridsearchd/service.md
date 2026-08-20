# Hybrid Semantic & Vector Search Daemon — `com.apple.hybridsearchd`

## Basics

| Field         | Value                                                         |
|---------------|---------------------------------------------------------------|
| Feature group | Generative Search & Spotlight Hybrid Indexing (macOS 27)      |
| Category      | `search_desktop` / `apple_intelligence`                      |
| Risk Level    | **2** — Disables hybrid vector/neural search queries           |
| Profile       | **safe to disable on coding / power-user target**             |
| Verdict       | **disable** (frees ~50 MB RAM)                               |

- **Main label:** `gui/<uid>/com.apple.hybridsearchd`
- **Plist:** `/System/Library/LaunchAgents/com.apple.hybridsearchd.plist`
- **Binary:** `/usr/libexec/hybridsearchd`
- **Domain:** `gui/<uid>`
- **Mach Services:** 
  - `com.apple.generativesearch.server.indexing`
  - `com.apple.generativesearch.server.search`
- **Feature Flags:** `GenerativeLearningPlatform/PlatformDaemons`, `GenerativeLearningPlatform/ObservationIndexing`, `GenerativeLearningPlatform/MailIndexing`

## What It Does (За что отвечает)

`com.apple.hybridsearchd` is the background semantic and vector index engine for **macOS Golden Gate 27**.

1. **HNSW Vector Indexing:** Builds and maintains Hierarchical Navigable Small World (HNSW) graphs (`IncrementalHNSWCreationTask`) for local embedding search across user content.
2. **Cascade Event Ingestion:** Subscribes to `com.apple.cascade.xpc_event.setChange` donation stores from Mail, Messages, Notes, Reminders, Calendar, Contacts, Siri Transcripts, and TextUnderstanding extraction entities.
3. **Database Maintenance:** Runs periodic SQLite database integrity checks and vacuum tasks (`FullVacuumTask`, `IncrementalVacuumTask`, `CorruptDatabasesCleanupTask`).

Traditional Spotlight filename and metadata search (via `mds` / `mdworker`) functions independently. Disabling `hybridsearchd` only disables on-device neural/semantic natural language indexing.

## Observed Cost (macOS 27 Golden Gate Baseline)

| Process | Domain | RSS RAM | CPU Idle |
|---|---|---|---|
| `hybridsearchd` (`/usr/libexec/hybridsearchd`) | `gui/<uid>` | **~49.8 MB** | 0.0% |

## Disable

```bash
uid=$(id -u)

launchctl bootout "gui/$uid/com.apple.hybridsearchd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.hybridsearchd"
```

## Rollback

```bash
uid=$(id -u)

launchctl enable "gui/$uid/com.apple.hybridsearchd"
launchctl bootstrap "gui/$uid" /System/Library/LaunchAgents/com.apple.hybridsearchd.plist
```

## Test Result

**Date:** 2026-08-20  
**Target:** macOS 27.0 Golden Gate (Build 26A5416b, ARM64)

1. Pre-disable: `hybridsearchd` was resident at **49,856 KB RSS**.
2. Executed `launchctl bootout gui/$uid/com.apple.hybridsearchd` and `launchctl disable`.
3. Process terminated immediately, releasing **~50 MB RAM**.
4. Basic Spotlight file queries continue working without issues.
