# CoreRoutine / CoreDuet / Proactive Suggestions

## Basics

- **Main label:** `com.apple.routined`
- **Related labels:** `com.apple.coreduetd`, `com.apple.contextstored`, `com.apple.ContextStoreAgent`, `com.apple.duetexpertd`, `com.apple.proactived`, `com.apple.proactiveeventtrackerd`
- **Processes:** `routined`, `coreduetd`, `contextstored`, `ContextStoreAgent`, `duetexpertd`, `proactived`, `proactiveeventtrackerd`
- **Domains:** `gui/<uid>`, `system`
- **Category:** `routine_proactive_intelligence`
- **Risk:** `2-3`
- **Verdict:** `good aggressive-profile candidate if proactive suggestions and routine learning are unused`

## What It Does

This group covers user routine learning, CoreDuet context storage, app/action prediction, and proactive suggestions.

Observed roles:

```text
routined              - CoreRoutine user habits, locations, routine store/cache/cloud
coreduetd             - CoreDuet knowledge/people/proactive request backend
contextstored         - system CoreDuet context store
ContextStoreAgent     - per-user CoreDuet context agent
duetexpertd           - app prediction, action prediction, notification categorization, time intelligence
proactived            - proactive suggestion model/client service
proactiveeventtrackerd - proactive event tracking
```

This is not required for basic desktop, SSH, networking, coding tools, or app launching.

## Observed Cost

Observed on 2026-06-20 under `codexadmin`:

```text
duetexpertd        ~54 MB RSS
routined           ~32 MB RSS
coreduetd          ~25 MB RSS
ContextStoreAgent  ~25 MB RSS
contextstored      ~20 MB RSS
```

Total observed active RSS: about `156 MB`.

`proactived` and `proactiveeventtrackerd` were enabled but not running at the capture time.

## Launchd Labels

```text
gui/<uid>/com.apple.routined
gui/<uid>/com.apple.ContextStoreAgent
gui/<uid>/com.apple.duetexpertd
gui/<uid>/com.apple.proactived
gui/<uid>/com.apple.proactiveeventtrackerd
system/com.apple.coreduetd
system/com.apple.contextstored
```

Important XPC endpoints include:

```text
com.apple.routined.event
com.apple.routined.internal
com.apple.routined.registration
com.apple.routined.safetyMonitor
com.apple.routined.store.cache
com.apple.routined.store.cloud

com.apple.coreduetd.knowledge
com.apple.coreduetd.people
com.apple.coreduetd.context
com.apple.corespotlight.receiver.coreduet

com.apple.duet.expertcenter
com.apple.duet.appPreference.prediction
com.apple.duet.appPrediction.inspection
com.apple.proactive.AppPrediction.predictions
com.apple.proactive.ActionPrediction.predictions
com.apple.proactive.client.predictions
com.apple.proactive.ContextualEngine.suggestions.xpc
com.apple.proactive.ProactiveSuggestionClientModel.xpc
```

## Disable

```bash
uid=$(id -u)

for svc in \
com.apple.routined \
com.apple.ContextStoreAgent \
com.apple.duetexpertd \
com.apple.proactived \
com.apple.proactiveeventtrackerd
do
  launchctl bootout gui/$uid/$svc 2>/dev/null || true
  launchctl disable gui/$uid/$svc
done

for svc in \
com.apple.coreduetd \
com.apple.contextstored
do
  sudo launchctl bootout system/$svc 2>/dev/null || true
  sudo launchctl disable system/$svc
done
```

Do not include these in this tweak by default:

```text
system/com.apple.locationd
system/com.apple.dasd
system/com.apple.biomed
gui/<uid>/com.apple.suggestd
```

Those are broader systems and should be tested separately.

## Rollback

```bash
uid=$(id -u)

for svc in \
com.apple.routined \
com.apple.ContextStoreAgent \
com.apple.duetexpertd \
com.apple.proactived \
com.apple.proactiveeventtrackerd
do
  launchctl enable gui/$uid/$svc
done

for svc in \
com.apple.coreduetd \
com.apple.contextstored
do
  sudo launchctl enable system/$svc
done

sudo shutdown -r now
```

## Test Result

2026-06-20: persistent disable was applied on the target Mac.

Before:

```text
coreduetd         running
contextstored     running
routined          running
ContextStoreAgent running
duetexpertd       running
proactived        not running, but enabled
proactiveeventtrackerd not running, but enabled
```

Applied:

```bash
launchctl bootout gui/502/com.apple.routined
launchctl disable gui/502/com.apple.routined

launchctl bootout gui/502/com.apple.ContextStoreAgent
launchctl disable gui/502/com.apple.ContextStoreAgent

launchctl bootout gui/502/com.apple.duetexpertd
launchctl disable gui/502/com.apple.duetexpertd

launchctl bootout gui/502/com.apple.proactived
launchctl disable gui/502/com.apple.proactived

launchctl bootout gui/502/com.apple.proactiveeventtrackerd
launchctl disable gui/502/com.apple.proactiveeventtrackerd

sudo launchctl bootout system/com.apple.coreduetd
sudo launchctl disable system/com.apple.coreduetd

sudo launchctl bootout system/com.apple.contextstored
sudo launchctl disable system/com.apple.contextstored
```

Immediate result:

```text
All observed CoreRoutine/CoreDuet/Proactive processes absent.
No immediate log noise observed.
SSH/network/route check OK.
```

Post-reboot result:

```text
No CoreRoutine/CoreDuet/Proactive processes observed.
Disabled overrides persisted in gui/502 and system domains.
SSH/network/route check OK.
No related post-boot log noise observed.
Process count after boot check: 374.
```

## Expected Breakage

Disables or degrades:

```text
Routine learning
Proactive app suggestions
Action predictions
Siri suggestions
Contextual suggestions
Notification categorization/personalization
Time intelligence / sleep schedule intelligence hooks
Some CoreDuet-backed Apple feature personalization
```

Expected impact for current coding-only profile:

```text
Acceptable for aggressive profile if the user does not use Siri suggestions, routine learning, proactive shortcuts, or Apple personalization features.
```
