# MauriMesh Runtime Truth System

> **Status:** Active  
> **Governs:** `RuntimeTruthEngine`, `BuildVariantEngine`, production readiness enforcement

---

## Overview

MauriMesh uses a layered truth system to ensure that:
1. Every runtime capability (BLE scan, encryption, relay, etc.) is classified with
   an honest mode — never silently simulated when real native operation is required.
2. Each build type (development, proof, release, production) enforces its own
   capability rules at startup — a release APK cannot ship with simulation logic.

The two core engines are:

| Engine | Responsibility |
|---|---|
| `RuntimeTruthEngine` | Tracks the current mode of each named feature at runtime |
| `BuildVariantEngine` | Defines which modes are permitted per build type; CI guard |

---

## Build Variants

Five build variants are defined. The active variant is selected by the
`MAURIMESH_BUILD_VARIANT` environment variable at server startup.
**Default: `web-preview`.**

| Variant ID | Label | Simulation | Native BLE | Encryption | Proof | Strictness | Log Level | Color |
|---|---|---|---|---|---|---|---|---|
| `web-preview` | Web Preview | ✅ allowed | optional | optional | optional | relaxed | debug | 🔵 blue |
| `android-dev` | Android Dev | ✅ allowed | optional | optional | optional | standard | debug | 🟡 amber |
| `android-proof` | Android Proof | ❌ forbidden | required | optional | required | standard | info | 🟣 purple |
| `android-release` | Android Release | ❌ forbidden | required | required | required | strict | warn | 🟢 green |
| `production` | Production | ❌ forbidden | required | required | required | strict | error | 🟢 green |

### Variant Config Fields

```typescript
interface BuildVariantConfig {
  id:                    BuildVariantId;
  label:                 string;
  simulationAllowed:     boolean;   // May any feature be in simulation mode?
  nativeBleRequired:     boolean;   // Must ble_scan/ble_advertise/native_bridge be real_native?
  encryptionRequired:    boolean;   // Must encryption be real_native?
  proofRequired:         boolean;   // Must two-phone proof have been completed?
  diagnosticsStrictness: "relaxed" | "standard" | "strict";
  loggingLevel:          "debug" | "info" | "warn" | "error";
  color:                 "blue" | "amber" | "purple" | "green";
}
```

### Selecting a Variant

**Development (default):**
```
# No env var needed — defaults to web-preview
```

**Android dev APK:**
```
MAURIMESH_BUILD_VARIANT=android-dev pnpm --filter @workspace/api-server run dev
```

**Two-phone proof session:**
```
MAURIMESH_BUILD_VARIANT=android-proof pnpm --filter @workspace/api-server run dev
```

**Release / Production:**
```
MAURIMESH_BUILD_VARIANT=android-release   # or: production
```

---

## CI Guard

`BuildVariantEngine` includes a **startup guard** that runs in the singleton
constructor. If a `release` or `production` variant is active but
`simulationAllowed: true` is detected in the config, the server **throws
immediately and refuses to start**:

```
[BuildVariantEngine] FATAL: variant "android-release" has simulationAllowed: true.
Release and production builds must NEVER ship simulation logic. …
```

This prevents accidental release builds from shipping simulation code even if the
config objects are edited. To add a new release variant, you must also ensure
`simulationAllowed: false`; otherwise the guard fires.

---

## RuntimeTruthEngine Feature Modes

Each named feature tracks one of five modes:

| Mode | Meaning |
|---|---|
| `real_native` | Verified on physical hardware with native Kotlin/Rust code |
| `partial` | Scaffold exists; full native not yet verified on physical device |
| `unavailable` | Capability not yet implemented |
| `web_simulation` | Browser simulation — no real hardware or network |
| `api_simulation` | API-level simulation — routes exist, real delivery unproven |

### Current Feature Registry

| Feature Name | Default Mode | Proof Required |
|---|---|---|
| `ble_scan` | `web_simulation` | Physical Android + NativeModules confirmation |
| `ble_advertise` | `web_simulation` | Physical Android + MeshAdvertiser.kt logcat |
| `p2p_send` | `api_simulation` | Two-phone proof: Phone A→B packet + ACK |
| `relay` | `api_simulation` | Three-phone relay proof with route trace |
| `ack` | `api_simulation` | ACK event in proof ledger with matching packetId |
| `store_forward` | `partial` | Queue survives API restart (PostgreSQL-backed) |
| `encryption` | `unavailable` | Key exchange + encrypted packet on physical device |
| `mesh_audio` | `web_simulation` | Native Android mic capture + opus frame delivery |
| `push_notify` | `api_simulation` | Mesh notification delivered + ACKed across two devices |
| `ota` | `web_simulation` | Valid OTA manifest URL + version mismatch test |
| `native_bridge` | `web_simulation` | Physical Android APK with MauriMeshBleModule loaded |
| `api_health` | `real_native` | GET /api/healthz → 200 |
| `trust_reputation` | `partial` | Trust records persist after API restart |

### Promoting Feature Mode

Features are promoted via `POST /truth/report-engine-status` from the mobile APK:

```json
{
  "subsystems": {
    "ble_scan": "real_native",
    "ble_advertise": "real_native",
    "background_ble_scan": "partial"
  }
}
```

The backend `ENGINE_SUBSYSTEM_MAP` maps subsystem keys → feature names.
Only whitelisted keys and valid mode values are accepted.

---

## Build Variant Violations

When `simulationAllowed: false`, `BuildVariantEngine.getSimulationViolations()`
returns features currently in simulation mode that violate the variant's rules.
`getNativeBleViolations()` flags BLE features not yet `real_native` when
`nativeBleRequired: true`.

Violations are surfaced via:
- `GET /api/build-variant` — returns `{ active, violations, violationCount }`
- The web dashboard sidebar header badge (color-coded; shows ⚠ count if violations exist)
- The mobile Settings screen footer (variant label + violation count)

---

## API Endpoints

| Endpoint | Auth | Description |
|---|---|---|
| `GET /api/build-variant` | public | Active variant config + current violations |
| `GET /api/truth/status` | public | All feature modes + summary |
| `POST /api/truth/report-engine-status` | public | Mobile APK reports native subsystem status |

---

## Web Dashboard Badge

The active build variant badge appears in the web app's sidebar header, next to
the version string. Color codes match the table above. If violations exist, a
warning icon and count are shown. Clicking the badge navigates to `/network/runtime-truth`.

## Mobile Settings Badge

The build variant is embedded in the mobile APK as `EXPO_PUBLIC_BUILD_VARIANT`
(an Expo Metro build-time constant). It is displayed in the Settings footer,
next to the app version string, in a color-matched pill.

---

## Adding a New Build Variant

1. Add a new entry to the `VARIANTS` record in `BuildVariantEngine.ts`.
2. If it is a release-type variant (simulationAllowed: false), add its ID to
   `RELEASE_VARIANT_IDS` so the CI guard applies.
3. Document it in this file's table.

## Adding a New Feature

1. Add an entry to the `features` record in `RuntimeTruthEngine.ts`.
2. If it should be reportable from the mobile APK, add its key to `ENGINE_SUBSYSTEM_MAP`
   in both `routes/truth.ts` and `routes/index.ts`.
3. Add it to this doc's feature registry table.
