# Task: fold ignored EmpiricalData services into a new TweakCatalog

You are working in `/Users/xmodern/Documents/ExtremeMacTweaker`.

Read `AGENTS.md` first. Do **not** run ripgrep / content search from the repo root. That hits `EmpericalData/` and drowns source results. Search `ExtremeMacTweaker/`, `PrivilegedProtocol/`, `Catalog/`, `EmpericalData/` as separate roots.

Do **not** delete or overwrite `ExtremeMacTweaker/Resources/TweakCatalog.json`. Create a **new catalog version** beside it.

## What happened

An older, more aggressive disable set was applied on a test Mac (`codex`, uid 502). After a later Tweaker run with the **current** catalog, fewer services stay disabled. Startup process count went from ~142–149 to ~156.

The gap is not “unknown Apple daemons”. Almost all missing labels already exist inside `EmpericalData/**/service.md` as related / disable-list entries. The previous catalog pass only imported labels that had **their own folder** under `EmpericalData/`. Companion labels mentioned in other notes were dropped.

## Data already in this repo

### Old launchd override snapshot (the “previous database”)

`LaunchdSnapshots/old-20260818/`

Authoritative binary plists:

- `LaunchdSnapshots/old-20260818/com.apple.xpc.launchd/disabled.plist` — **system** domain
- `LaunchdSnapshots/old-20260818/com.apple.xpc.launchd/disabled.502.plist` — **gui/502** (`codex`)

`true` = service was **disabled**. `false` = explicitly left enabled (example: `com.openssh.sshd => false` must stay enabled; do not add sshd to the catalog).

Ignore `disabled.501.plist` (user `xmodern`, 4 old keys, not this test run).

Readable dumps: `*.plist.txt` in the same folder.

### Current launchd override snapshot (after latest Tweaker apply + Security tab)

`LaunchdSnapshots/current/`

- `disabled.plist` — system, now
- `disabled.502.plist` — gui/502, now

Taken from the live test Mac after the user applied all current tweaks **including** Security.

### Current catalog

- `ExtremeMacTweaker/Resources/TweakCatalog.json` — do not delete
- Schema: `Catalog/TweakCatalog.schema.json`
- Security-only labels (XProtect / syspolicyd / Gatekeeper) live in `PrivilegedProtocol/SecurityProtectionCatalog.swift`, not in TweakCatalog. Do not move those into TweakCatalog unless a note clearly belongs to a System Tweaker feature instead.

### Empirical notes

`EmpericalData/` (spelling is `EmpericalData`, not Empirical).

- One folder per **primary** service, usually `EmpericalData/<launchd-label>/service.md`
- Related labels are listed **inside** those notes (tables, disable scripts, “also disable”). That is the source of the ignored services.

## What you must compute

1. Build set **OLD** = labels with `true` in old `disabled.plist` ∪ old `disabled.502.plist`.
2. Build set **NOW** = labels with `true` in current `disabled.plist` ∪ current `disabled.502.plist`.
3. Build set **CATALOG** = every `services[].label` in the current TweakCatalog.json, plus SecurityProtectionCatalog labels.
4. The work list is:

   **GAP = OLD − NOW**

   After Security was applied, GAP should be labels that are **still enabled now** but **were disabled in the old snapshot**. Expected size is about **111**. None of those 111 are in CATALOG (except naming mismatches below).

5. Also list **OLD − CATALOG** even if some are still disabled now. Those are labels the catalog never absorbed.

### Known naming mismatches (treat as catalog bugs, fix in the new version)

| Old disabled label | Current catalog label |
|---|---|
| `com.apple.triald.system` | `com.apple.triald_system` |
| `com.apple.useractivityd` | `com.apple.coreservices.useractivityd` |
| `com.apple.speech.speechsynthesisd.x86_64` | only `.arm64` exists |
| `com.apple.WiFiAgent` | `com.apple.wifi.WiFiAgent` |

Add the real launchd label that the old machine actually disabled. Do not leave underscore/dot mistakes.

### Almost all GAP labels are already in EmpiricalData

They will **not** have their own folder. Grep **inside** `EmpericalData/**/service.md` (path: `EmpericalData` only).

Last check: 107 / 111 appear in notes. Own folder: only `com.apple.useractivityd`. No mention at all:

- `com.apple.CoreServicesUIAgent`
- `com.apple.ManagedClientAgent.enrollagent`
- `com.apple.ftpd`

For those three, still try to place them if the Empirical text around neighbors makes the purpose obvious. If not, put them in a clearly marked “unverified, from old disable set” group rather than inventing a story.

Do **not** add: `com.openssh.sshd`, anything that would break login, WindowServer, or SSH.

## What to do with each GAP label

For every label in GAP:

1. Find it in `EmpericalData/**/service.md`.
2. Read what it does, which primary feature it belongs to, disable/rollback notes, risk.
3. Attach it to an **existing** category / feature / service group in TweakCatalog. Do **not** invent new categories.
4. Add a `services[]` entry (id, label, domain, kind) if missing.
5. Add the service id to the right `serviceGroups[]`.
6. Point an existing `features[].disableServiceGroups` at that group, or extend the group the feature already uses.

Existing categories (ids) in the current catalog:

- `search-intelligence`
- `apple-intelligence-siri`
- `communication`
- `continuity-sharing`
- `icloud-store`
- `photos-media`
- `location-findmy`
- `privacy-telemetry`
- `consumer-apps`
- `accessibility`
- `system-maintenance`

Place by Empirical description, not by name vibes. Examples of expected homes (verify against notes, do not blindly trust):

- Siri extras (`siriactionsd`, `siriinferenced`, `siriknowledged`, `sirittsd`, intelligence*) → `apple-intelligence-siri`
- Spotlight extras (`mdworker.*`, `corespotlightservice`, `spotlightknowledged.importer/updater`, `mds.spindump`) → `search-intelligence`
- Maps / navd / newsd / watchlistd → existing Maps / location / consumer features
- Safari extra agents → existing Safari feature
- AirPlay / sidecar / cmio capture → `continuity-sharing`
- parsecd / suggestd / wifianalyticsd / diagnostics* → `privacy-telemetry`
- iCloud mail/web/sync leftovers → `icloud-store`
- screensharing / RemoteManagement → `system-maintenance` or existing remote/management feature

If a label clearly belongs to two features, put it in one group and reuse that group from both features only if the current catalog already works that way.

## Output: new catalog version

- Keep `ExtremeMacTweaker/Resources/TweakCatalog.json` as-is (old version).
- Write a new file, for example:
  - `ExtremeMacTweaker/Resources/TweakCatalog.next.json`
  - bump `catalogVersion` (current is `2026.08.12.1` → use a new date/patch, e.g. `2026.08.18.1`)
  - keep `schemaVersion: 1` unless the schema file requires otherwise
- Follow `Catalog/TweakCatalog.schema.json`.
- English only for titles/questions/descriptions.
- Unique ids for new services and groups. Do not collide with existing ids.
- Domain: `system` if it was in old `disabled.plist`; `gui` if only in `disabled.502.plist`. If both, prefer the domain used by the sibling services in that feature (often both a system daemon and a gui agent exist as two service entries).
- `kind`: `daemon` for system, `agent` for gui, unless Empirical notes say otherwise.

Also write a short `LaunchdSnapshots/GAP_REPORT.md`:

- counts: OLD, NOW, GAP, how many added to the new catalog
- table: label, domain(s) in old snapshot, Empirical source file, target feature id / group id
- labels you refused to add, and why

## Do not

- Do not delete the old TweakCatalog.json.
- Do not search the repo from `/` of the project (use explicit paths).
- Do not add new top-level categories.
- Do not “fix” launchd on the test Mac.
- Do not touch `/var/db/com.apple.xpc.launchd` on any machine.
- Do not set `uchg` / immutable flags.
- Do not disable SSH / `com.openssh.sshd`.
- Do not run `Deploy.sh` unless the human explicitly asks after review.

## Done when

- New catalog JSON validates against the schema.
- Every GAP label is either attached to an existing feature **or** listed in GAP_REPORT.md with a reason.
- Old catalog file is still present and unchanged in content (except you may leave it untouched entirely).
