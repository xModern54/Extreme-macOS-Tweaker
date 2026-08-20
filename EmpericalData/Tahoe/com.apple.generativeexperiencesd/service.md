# Apple Generative AI / Model Runtime Stack

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | Generative Experiences + Model Manager + Model Catalog + Intelligence Platform (GUI) |
| Category      | `siri` / `analytics_telemetry` / `routine_proactive_intelligence` |
| Risk Level    | 2 — disables on-device Apple Intelligence / generative features |

## What It Does

macOS on-device generative AI and model-serving infrastructure:

- **generativeexperiencesd** — Generative Experiences runtime (availability, internal generative APIs)
- **modelmanagerd** — system model manager (download/load/serve ML models)
- **modelcatalogd** + **ModelCatalogAgent** — model catalog subscriptions and per-user catalog agent
- **intelligenceplatformd** — Intelligence Platform core (asset registry, entity resolution); was idle before disable
- **textcomposerd** — external text composition for generative features; was idle before disable

Related already-disabled sibling: `com.apple.knowledgeconstructiond` (Knowledge Construction for Intelligence Platform).

**IntelligencePlatformComputeService** is an XPC child (no launchd label). Before reboot it was briefly held by `BiomeAgent`; after disabling this group and rebooting it did not return.

Not required for SSH, coding tools, compilers, or basic desktop operation.

## Observed Cost (before disable)

| Process                          | Domain | RSS     |
|----------------------------------|--------|---------|
| `modelmanagerd`                  | system | ~23.7 MB |
| `generativeexperiencesd`         | gui    | ~22.9 MB |
| `modelcatalogd`                  | system | ~21.4 MB |
| `IntelligencePlatformComputeService` | XPC (user) | ~20.1 MB |
| `ModelCatalogAgent`              | gui    | ~18.5 MB |
| **Total**                        |        | **~106 MB** |

## Launchd Labels

### GUI domain (4 labels)

| Label                              | Binary / role |
|------------------------------------|---------------|
| `com.apple.generativeexperiencesd` | `.../GenerativeExperiencesRuntime.framework/.../generativeexperiencesd` |
| `com.apple.ModelCatalogAgent`      | `.../ModelCatalogRuntime.framework/.../ModelCatalogAgent` |
| `com.apple.intelligenceplatformd`  | `.../IntelligencePlatformCore.framework/.../intelligenceplatformd` |
| `com.apple.textcomposerd`          | `/usr/libexec/textcomposerd` |

### System domain (2 labels)

| Label                     | Binary / role |
|---------------------------|---------------|
| `com.apple.modelmanagerd` | `/usr/libexec/modelmanagerd` |
| `com.apple.modelcatalogd` | `.../ModelCatalogRuntime.framework/.../modelcatalogd` |

### Notable endpoints

```text
generativeexperiencesd: com.apple.generativeexperiences.availability.internal, .availabilityService
modelmanagerd:          com.apple.modelmanager
modelcatalogd:          com.apple.modelcatalog.catalog, .subscriptions
ModelCatalogAgent:      com.apple.modelcatalog.subscriptions
intelligenceplatformd:  com.apple.intelligenceplatform.AssetRegistry, .EntityResolution
textcomposerd:          com.apple.generativeexperiences.externaltextcomposition
```

## Disable

```bash
uid=$(id -u)

gui_labels=(
  com.apple.generativeexperiencesd
  com.apple.ModelCatalogAgent
  com.apple.textcomposerd
  com.apple.intelligenceplatformd
)
for label in "${gui_labels[@]}"; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done

sys_labels=(
  com.apple.modelcatalogd
  com.apple.modelmanagerd
)
for label in "${sys_labels[@]}"; do
  sudo launchctl bootout "system/$label" 2>/dev/null || true
  sudo launchctl disable "system/$label"
done
```

## Rollback

```bash
uid=$(id -u)

for label in \
  com.apple.generativeexperiencesd \
  com.apple.ModelCatalogAgent \
  com.apple.textcomposerd \
  com.apple.intelligenceplatformd; do
  launchctl enable "gui/$uid/$label"
done

for label in com.apple.modelcatalogd com.apple.modelmanagerd; do
  sudo launchctl enable "system/$label"
done

sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Pre-disable: 5 generative processes running (~106 MB RSS). `intelligenceplatformd` and `textcomposerd` idle.
2. Bootout 4 gui + 2 system labels — all 5 main processes disappeared immediately.
3. `IntelligencePlatformComputeService` XPC lingered briefly (~20 MB); `responsible` was `BiomeAgent` (pid domain). No launchd label to disable.
4. No errors in logs after bootout.
5. 30-second delayed check — core generative processes did not return.
6. Disabled all 6 labels — confirmed in `launchctl print-disabled`.
7. Rebooted target; SSH back in ~23 seconds.
8. Post-reboot health: SSH, login, gateway, DNS, memory pressure OK.
9. **No generative/model/intelligence-platform processes after reboot** — including `IntelligencePlatformComputeService`.
10. No related error log entries during boot.
11. Process count: **342** (down from 350).

**Verdict: safe to disable on coding experimental target.** ~106 MB saved.

## Expected Breakage

- Apple Intelligence / on-device generative features (Writing Tools, summarization, generative availability checks).
- Model download/update via Model Manager and Model Catalog.
- Intelligence Platform asset registry / entity resolution for Apple ML features.
- Text composition services tied to generative experiences.

Does not affect SSH, Wi-Fi, `locationd`, compilers, or Git.

## Notes

- `com.apple.knowledgeconstructiond` was already disabled earlier; left disabled.
- `triald` / `triald_system` are **not** part of this group (~37 MB, separate experiment).
- `BiomeAgent` (~35 MB) can spawn `IntelligencePlatformComputeService` XPC; after this disable + reboot the XPC stayed gone, but Biome remains a future candidate if the XPC returns under load.
- Protected: do not bundle-disable `BiomeAgent` in the same step without separate research.