# MauriMesh Production Readiness Gate

## Purpose

The Production Readiness Gate (`GET /api/production-readiness`) is a hard, nine-category
evaluation layer that **objectively scores MauriMesh's readiness to ship**. It cannot pass
while native BLE is simulation-only, encryption is a placeholder, or no verified two-phone
proof exists in the Proof Ledger.

The gate is visible in the web dashboard at **Advanced → Production Readiness Gate** and
auto-refreshes every 60 seconds.

---

## Overall Verdicts

| Verdict | Meaning |
|---------|---------|
| **NOT PRODUCTION READY** (fail) | One or more blocking checks failed. |
| **PRE-PRODUCTION** (warn) | No blockers — warnings must be addressed before release. |
| **PRODUCTION READY** (pass) | All nine categories pass. |

There is no ambiguity: a single blocking failure marks the gate as `fail`.

---

## Nine Categories

### 1. UI
**Checks:** Web dashboard is reachable and serving the SPA.
**Hard fail:** No
**Status:** Passes automatically when the API is live (dashboard is co-hosted).
**Resolution:** Ensure the Vite dev server or static build is running on the expected port.

---

### 2. API ⛔ BLOCKING
**Checks:** `GET /api/healthz` returns 200.
**Hard fail:** Yes — if the API is down, all other checks are unreliable.
**Resolution:** Restart the API server workflow. Check for port conflicts and PostgreSQL connection errors in the server logs.

---

### 3. Runtime
**Checks:** RuntimeTruthEngine has ≥ 10 subsystem features registered.
**Hard fail:** No (fail below 5 features, warn below 10).
**Why 10:** MauriMesh has 12 registered subsystems (BLE scan, advertise, P2P send, relay, ACK, store-forward, encryption, mesh audio, push notify, OTA, native bridge, API health). All should be registered before production.
**Resolution:** Verify `RuntimeTruthEngine` initialization registers all subsystems. Missing features indicate an incomplete engine setup.

---

### 4. Native BLE ⛔ BLOCKING
**Checks:** At least one subsystem feature is in `real_native` mode (confirmed via physical device).
**Hard fail:** Yes — BLE simulation **never** satisfies this gate.
**How to satisfy:**
1. Build the MauriMesh APK (`eas build --platform android --profile development`)
2. Install on a physical Android device (API level 23+, Bluetooth enabled)
3. Confirm BLE scan + advertise in logcat (`adb logcat | grep MauriMesh`)
4. Complete the two-phone proof protocol on both devices
5. The API evaluates `real_native` features from RuntimeTruthEngine

No amount of Replit/web simulation or manual flag overrides satisfies this check.

---

### 5. Security
**Checks:** End-to-end encryption is active in the transport layer.
**Hard fail:** No (currently `warn` — encryption is planned but not yet active).
**Status:** Messages transit in plaintext. This is acceptable for pre-production testing but **must be resolved before any deployment handling sensitive data**.
**Resolution:** Implement the key-exchange handshake and activate the encryption layer in the BLE transport pipeline.

---

### 6. Persistence
**Checks (two):**
- `Trust/Reputation DB records` — At least one trust record exists in PostgreSQL.
- `Store-forward queue PostgreSQL-backed` — Queue survives API restarts.

**Hard fail:** Store-forward persistence failure is `fail`; zero trust records is `warn`.
**Resolution:**
- Trust records: Complete BLE peer discovery on a physical device to generate records via the trust engine.
- Store-forward: Run the DB migration (`pnpm --filter @workspace/db run push`) to ensure the `store_forward_queue` table exists.

---

### 7. Proof ⛔ BLOCKING
**Checks:** At least one entry with `eventType = "two_phone_proof"` exists in the Proof Ledger.
**Hard fail:** Yes — this is the primary engineering milestone gate.
**How to satisfy:**
1. Open the MauriMesh app on **two physical Android devices**
2. Navigate to **Platform → Two-Phone Proof** on each device
3. Assign Phone A (Sender) and Phone B (Receiver) roles
4. Complete the guided proof flow end-to-end (BLE scan → peer select → send → ACK)
5. Confirm the proof entry appears via `GET /api/proof-ledger`
6. The gate reads this table directly — no manual confirmation needed.

---

### 8. Android Build
**Checks:** APK has been built and installed on a physical Android device.
**Hard fail:** No (`warn` until confirmed).
**Status:** Currently `warn` — automatic APK build detection is not yet implemented. Confirmation is manual.
**Resolution:** Run `eas build --platform android --profile development`, install the resulting APK, launch the app, and manually record the confirmation via the Build Variant panel.

---

### 9. Documentation
**Checks:** Core docs (build, packet format, readiness gate, proof protocol) are present in `docs/`.
**Hard fail:** No (`warn` if missing).
**Status:** Currently `pass` — all required docs are present.
**Resolution:** Ensure `docs/PRODUCTION_READINESS_GATE.md`, `docs/MAURIMESH_PACKET_FORMAT.md`, `docs/APK_BUILD_SIGNING_PIPELINE.md`, and `docs/TWO_PHONE_PROOF_PROTOCOL.md` all exist.

---

## Blocking Conditions (summary)

These three conditions **individually block** an overall `pass` verdict and cannot be bypassed:

| Condition | Category | How to resolve |
|-----------|----------|----------------|
| API not responding | API | Restart API server |
| Native BLE not confirmed | Native BLE | Build APK + physical device + logcat proof |
| No two-phone proof in ledger | Proof | Complete two-phone proof protocol |

---

## Viewing the Gate

**Web dashboard:**
Navigate to **Advanced → Production Readiness Gate** in the sidebar. The panel auto-refreshes every 60 seconds and shows a color-coded category scorecard with a large verdict banner.

**API:**
```bash
curl -H "Authorization: Bearer <token>" https://<domain>/api/production-readiness
```

**Response shape:**
```json
{
  "ok": true,
  "generatedAt": "2026-06-02T10:00:00.000Z",
  "overallStatus": "fail",
  "summary": "NOT PRODUCTION READY — 2 blocking failures...",
  "passCount": 7,
  "warnCount": 1,
  "failCount": 2,
  "checks": [ ... ],
  "blockingFails": [ ... ],
  "categories": ["UI", "API", "Runtime", ...]
}
```

---

## Important Notes

- The gate is **advisory**, not a CI gate. It does not block deployments automatically (that is a future task).
- The gate is **system-wide**, not per-user.
- Scheduled automatic re-evaluation is not yet implemented (planned in task #84 — QA scheduling).
- PDF export is out of scope. Use `GET /api/reports/latest?format=markdown` for a Markdown snapshot that includes the gate result.
