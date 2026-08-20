# OS Eligibility / feature gates — `eligibilityd` (eligibilityd-off)

## Basics

| Field         | Value                                                         |
|---------------|---------------------------------------------------------------|
| Feature group | `eligibilityd` only                                           |
| Category      | OS Eligibility / regional feature gates disabled                |
| Risk Level    | **2–3** — central feature-gating daemon; headless clean here  |
| Profile       | **keep disabled on AI-off / no-compliance-gates coding target** |

## What OS Eligibility Does (за что отвечает)

**System** daemon (`os_eligibility-319`) — central Apple **feature eligibility engine**:

| Role | Detail |
|------|--------|
| Policy evaluation | Decides whether device/user is eligible for region- and account-gated features |
| API surface | Mach `com.apple.eligibilityd`; consumers use `libsystem_eligibility` / `os_eligibility_*` |
| Inputs | `countryd` regulatory country, billing storefronts (App Store/Music/iCloud), locale, device region, languages (incl. Siri), precise location, age/teen status, hardware model, `MobileAsset.OSEligibility` asset |
| Outputs | Cached answers per **domain** in `/var/db/os_eligibility/eligibility.plist` and `/var/db/eligibilityd/eligibility.plist` |
| Maintenance | Daily recompute (`com.apple.eligibility.recompute`), refresh on language/session/OSEligibility asset download |

**Not touched in this test (per plan):** `countryd`, `geod`, `mobileassetd`, `appstoreagent`, `akd`, `accountsd`, `FeatureAccessAgent`.

| Label | Domain | Process | Plist |
|-------|--------|---------|-------|
| `com.apple.eligibilityd` | system | `eligibilityd` | `/System/Library/LaunchDaemons/com.apple.eligibilityd.plist` |

**Binary:** `/usr/libexec/eligibilityd`

## Domains Visible in DB/Cache (before disable)

### `/var/db/eligibilityd/eligibility.plist` (7 domains — AI/Siri-focused subset)

| Domain | answer_t (cached) |
|--------|-------------------|
| `OS_ELIGIBILITY_DOMAIN_FOUNDATION_MODELS` | 4 |
| `OS_ELIGIBILITY_DOMAIN_GREYMATTER` | 4 |
| `OS_ELIGIBILITY_DOMAIN_PERSONAL_QA` | 4 |
| `OS_ELIGIBILITY_DOMAIN_SIRI_WITH_APP_INTENTS` | 4 |
| `OS_ELIGIBILITY_DOMAIN_TERBIUM` | 4 |
| `OS_ELIGIBILITY_DOMAIN_CALCIUM` | 2 |
| `OS_ELIGIBILITY_DOMAIN_FORCED_SHUTTER_SOUND` | 2 |

### `/var/db/os_eligibility/eligibility.plist` (150+ domains)

**Named / high-signal groups observed:**

| Group | Example domains |
|-------|-----------------|
| Apple Intelligence / LLM | `XCODE_LLM`, `SWIFT_ASSIST`, `AI_LABELING`, `SIRI_MODE`, `SIRI_MODE_NEEDS_CONSENT` |
| DMA / marketplaces / browsers / payments | `HYDROGEN`, `HELIUM`, `LITHIUM`, `BORON`, `CARBON`, `NITROGEN`, `PHOSPHORUS`, `SODIUM`, `MAGNESIUM`, `ALUMINUM`, `SILICON`, `SEARCH_MARKETPLACES`, `HIGHLIGHTS_MARKETPLACES` |
| Age / child / teen / Screen Time | `ADULT_AGE_VERIFICATION_REQUIRED*`, `CHILD_AND_TEEN_RESTRICTION_REQUIRED*`, `AGE_ASSURANCE_*`, `DECLARED_AGE_RANGE_*`, `APP_STORE_LAUNCH_AGE_VERIFICATION`, `FORCE_ASK_TO_BUY_ON`, `BLOCK_ASK_TO_BUY_DISABLE` |
| Regional compliance misc | `FORCED_SHUTTER_SOUND` analogs, `COMM_SAFETY_FORCE_ON`, `WEB_CONTENT_FILTER_FORCE_ON`, `CORE_NFC_PAYMENT_TAG_READER` |
| Element codenames | ~100+ `OS_ELIGIBILITY_DOMAIN_<ELEMENT>` entries (Apple obscured DMA/regulatory feature map) |

Cached `answer_t` values on target were mostly **2** (not eligible) or **4** (eligible) depending on domain — DB was live and recently updated at reboot.

## Observed Cost (before disable)

| Process | RSS |
|---------|-----|
| `eligibilityd` | ~12.7 MB |

## Disable (system only)

```bash
sudo launchctl bootout system/com.apple.eligibilityd 2>/dev/null || true
sudo launchctl disable system/com.apple.eligibilityd
```

## Rollback

```bash
sudo launchctl enable system/com.apple.eligibilityd
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-23 — experiment **eligibilityd-off**

**Before:** processes **319**, total RSS **5569 MB**, `eligibilityd` running (~12.7 MB).

1. Bootout/disable `system/com.apple.eligibilityd` — gone immediately.
2. Reboot — SSH back ~21 s.
3. **Post-reboot (headless, no GUI tests):**
   - SSH: OK
   - Route: default via `en0`, gateway present
   - `eligibilityd`: **not running**; system disable flag intact; job not loaded
   - **Delayed 25 s:** no respawn, no crash loop
   - **Log storm:** 0 lines for eligibility/os_eligibility/libsystem_eligibility; 0 error/fail/retry/denied/connection invalid
   - **Protected neighbors — still running, quiet:**
     - `countryd` (~11 MB), `geod` (×2), `mobileassetd` (~38 MB), `appstoreagent` (~45 MB), `akd` (~24 MB), `accountsd` (~65 MB) — no new eligibility-tied error/retry logs
   - **AI/cloud neighbors — unchanged:**
     - `generativeexperiencesd`, `intelligenceplatformd`, `FeatureAccessAgent` remain disabled, not running, quiet
4. **After metrics:** processes **318**, total RSS **5988 MB** (~13 MB from daemon removed; total RSS boot variance up)

**Verdict: keep disabled on this coding experimental target** (AI stack already off; headless clean). **Rollback** if needing Apple Intelligence eligibility, DMA/regulatory gates, or age-assurance APIs.

## Exact Breakage Notes (expected, GUI not tested)

| Area | Impact when `eligibilityd` disabled |
|------|-------------------------------------|
| `os_eligibility_*` consumers | XPC queries fail / stale — any feature asking eligibilityd gets no fresh answers |
| Apple Intelligence / foundation models | `FOUNDATION_MODELS`, `GREYMATTER`, `PERSONAL_QA`, `XCODE_LLM`, `SWIFT_ASSIST` gates stop updating |
| Regional compliance | DMA/browser choice/alternative stores/payment domains cannot recompute |
| Age / child / teen | Age assurance, declared age range, Ask To Buy force domains inactive |
| Siri / app intents | `SIRI_WITH_APP_INTENTS`, `SIRI_MODE*` eligibility stale |
| App Store / accounts | May affect age-verification-at-launch decisions indirectly — **no headless breakage observed** on `appstoreagent`/`akd`/`accountsd` |

**Not broken (verified headless):** SSH; protected neighbors did not log storm; no eligibilityd respawn.

## Clients / Neighbors After Disable

| Component | Noise after disable + reboot |
|-----------|------------------------------|
| `countryd` | running, **quiet** |
| `geod` | running, **quiet** |
| `mobileassetd` | running, **quiet** (still hosts OSEligibility assets) |
| `appstoreagent` | running, **quiet** |
| `akd` / `accountsd` | running, **quiet** |
| `FeatureAccessAgent` | disabled, not running, **quiet** |
| `generativeexperiencesd` / `intelligenceplatformd` | disabled, **quiet** |
| `eligibilityd` | **gone**, no respawn |

**Active XPC client churn:** none visible in 5m logs post-reboot.

## Notes

- Higher infrastructure weight than consumer tails; project previously marked **defer without test plan**.
- On this target AI/intelligence already disabled — practical headless risk lower than generic risk 3.
- `mobileassetd` may still download `OSEligibility` assets; without `eligibilityd` they are not applied live.
- Re-enable before testing Apple Intelligence eligibility, Xcode LLM eligibility tools, or regulatory feature surfaces.