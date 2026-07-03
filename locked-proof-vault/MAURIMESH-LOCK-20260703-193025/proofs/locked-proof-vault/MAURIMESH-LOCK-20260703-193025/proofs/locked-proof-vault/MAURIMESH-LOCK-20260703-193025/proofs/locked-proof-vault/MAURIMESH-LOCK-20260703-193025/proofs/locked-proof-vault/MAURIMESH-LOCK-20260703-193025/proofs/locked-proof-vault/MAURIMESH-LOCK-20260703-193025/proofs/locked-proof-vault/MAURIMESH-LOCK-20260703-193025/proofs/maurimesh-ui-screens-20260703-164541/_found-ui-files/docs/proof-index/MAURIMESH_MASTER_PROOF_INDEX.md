# MauriMesh Master Proof Index

## Status

- Project: **MauriMesh**
- Archive status: **ACTIVE_PROOF_ARCHIVE**
- Created at: 2026-06-13T17:00:01.063Z
- Passed milestones recorded: **5**

## Proof Standard

A proof is strongest when packet identity, stage order, device role, ACK path, archive clone, external verification, and hash seal are preserved.

## Milestone Summary

| ID | Title | Status | Proof Level | Packet ID |
|---|---|---|---|---|
| MM-PROOF-001 | MauriMesh 2-Device BLE Relay Proof | PASSED | APP_UI_PASS_SCREENSHOT_ARCHIVED | `SOURCE_SCREENSHOT_OR_DEVICE_LOG_REQUIRED_FOR_EXACT_PACKET_ID` |
| MM-PROOF-002 | MauriMesh 3-Device Hop Relay Proof | PASSED | APP_UI_PASS_SCREENSHOT_ARCHIVED | `MM3-JSY73G-JKDXYR` |
| MM-PROOF-003 | MauriMesh Store-Forward Delay Proof | PASSED | APP_UI_PASS_LOG_CLONED | `MMSF-TEJFNH-K3FKYM` |
| MM-PROOF-004 | MauriMesh Store-Forward External Verifier | PASSED | EXTERNAL_VERIFIER_PASS_CERTIFICATE_GENERATED | `MMSF-TEJFNH-K3FKYM` |
| MM-PROOF-005 | MauriMesh Store-Forward Hash Manifest | PASSED | HASH_MANIFEST_PASS | `MMSF-TEJFNH-K3FKYM` |

## MM-PROOF-001 — MauriMesh 2-Device BLE Relay Proof

- Status: **PASSED**
- Proof level: **APP_UI_PASS_SCREENSHOT_ARCHIVED**
- Packet ID: `SOURCE_SCREENSHOT_OR_DEVICE_LOG_REQUIRED_FOR_EXACT_PACKET_ID`

### Devices

- PHONE_A: Samsung Galaxy A06 / Sender
- PHONE_B: Samsung Galaxy S10 / Relay

### Verified Chain

1. PHONE_A -> TX packet
2. PHONE_B -> RX packet
3. PHONE_B -> ACK back to PHONE_A
4. PHONE_A -> ACK received

### Meaning

MauriMesh proved a two-device sender-to-relay ACK chain at app proof level.

### Archive Files

- Source screenshots / copied proof report / device logs

## MM-PROOF-002 — MauriMesh 3-Device Hop Relay Proof

- Status: **PASSED**
- Proof level: **APP_UI_PASS_SCREENSHOT_ARCHIVED**
- Packet ID: `MM3-JSY73G-JKDXYR`

### Devices

- PHONE_A: Samsung Galaxy A06 / Sender / Wi-Fi ADB
- PHONE_B: Samsung Galaxy S10 / Relay / Wi-Fi ADB
- PHONE_C: Samsung Galaxy A16 / Receiver + ACK / USB Debugging

### Verified Chain

1. PHONE_A/A06 -> PACKET_ID_GENERATED
2. PHONE_A/A06 -> TX_A06_TO_S10
3. PHONE_B/S10 -> RX_S10_FROM_A06
4. PHONE_B/S10 -> RELAY_S10_TO_A16
5. PHONE_C/A16 -> RX_A16_FROM_S10
6. PHONE_C/A16 -> ACK_A16_TO_S10
7. PHONE_B/S10 -> ACK_RELAY_S10_TO_A06
8. PHONE_A/A06 -> ACK_RECEIVED_A06

### Meaning

MauriMesh proved a three-device hop relay path with ACK return at app proof level.

### Archive Files

- Source screenshots / copied proof report / device logs

## MM-PROOF-003 — MauriMesh Store-Forward Delay Proof

- Status: **PASSED**
- Proof level: **APP_UI_PASS_LOG_CLONED**
- Packet ID: `MMSF-TEJFNH-K3FKYM`

### Devices

- PHONE_A: Samsung Galaxy A06 / Sender
- PHONE_B: Samsung Galaxy S10 / Store-Forward Relay
- PHONE_C: Samsung Galaxy A16 / Delayed Receiver + ACK

### Verified Chain

1. PHONE_A/A06 -> PACKET_ID_CONFIRMED
2. PHONE_A/A06 -> TX_A06_TO_S10_STORE_REQUEST
3. PHONE_B/S10 -> S10_STORE_PACKET
4. PHONE_C/A16 -> A16_OFFLINE_CONFIRMED
5. PHONE_B/S10 -> S10_HOLD_DELAY
6. PHONE_C/A16 -> A16_RETURNS
7. PHONE_B/S10 -> S10_FORWARD_STORED_TO_A16
8. PHONE_C/A16 -> RX_A16_STORED_PACKET
9. PHONE_C/A16 -> ACK_A16_TO_S10_STORED
10. PHONE_B/S10 -> ACK_RELAY_S10_TO_A06_STORED
11. PHONE_A/A06 -> ACK_RECEIVED_A06_STORED

### Meaning

MauriMesh proved packet identity survives delayed receiver loss, relay holding, receiver return, stored delivery, and ACK relay back to sender.

### Archive Files

- `docs/proof-archives/store-forward/store_forward_MMSF-TEJFNH-K3FKYM.log`

## MM-PROOF-004 — MauriMesh Store-Forward External Verifier

- Status: **PASSED**
- Proof level: **EXTERNAL_VERIFIER_PASS_CERTIFICATE_GENERATED**
- Packet ID: `MMSF-TEJFNH-K3FKYM`

### Devices

- N/A

### Verified Chain

N/A

### Meaning

Independent project-side verifier confirmed packetId, stage order, device roles, delay condition, rediscovery, and final ACK.

### Archive Files

- `tools/proof-verifiers/verify-store-forward-proof.js`
- `docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_certificate.md`
- `docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_verifier_report.json`

## MM-PROOF-005 — MauriMesh Store-Forward Hash Manifest

- Status: **PASSED**
- Proof level: **HASH_MANIFEST_PASS**
- Packet ID: `MMSF-TEJFNH-K3FKYM`

### Devices

- N/A

### Verified Chain

N/A

### Meaning

Store-forward proof files are now tamper-evident through SHA-256 sealing.

### Archive Files

- `tools/proof-verifiers/verify-store-forward-hash-manifest.js`
- `docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_hash_manifest.json`
- `docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_hash_manifest.md`


## Store-Forward Verification Commands

Run these from project root:

```bash
node tools/proof-verifiers/verify-store-forward-proof.js
node tools/proof-verifiers/verify-store-forward-hash-manifest.js
node tools/proof-verifiers/verify-maurimesh-master-proof-index.js
```

Expected results:

```text
Verdict: PASS
HASH VERDICT: PASS
MASTER INDEX VERDICT: PASS
```

## Archive Discipline

Keep screenshots, copied proof reports, logcat captures, verifier outputs, certificate files, and hash manifests together.

This protects the proof chain from memory loss, accidental overwrite, and later dispute.

<!-- RAW_DEVICE_STORE_FORWARD_MMSF_RAW_LIVE_001_START -->

## Protected Milestone: Store-Forward Raw Device Evidence PASS + Archive Hash Seal

| Field | Value |
|---|---|
| Packet ID | `MMSF-RAW-LIVE-001` |
| Verdict | `PASS` |
| Proof Type | Three-device Store-Forward raw ADB/logcat evidence capture |
| PHONE_A | Samsung Galaxy A06 / Sender |
| PHONE_B | Samsung Galaxy S10 / Store-Forward Relay |
| PHONE_C | Samsung Galaxy A16 / Delayed Receiver + ACK |
| Raw Evidence Folder | `/Users/maurimesh/maurimesh-raw-evidence/run-20260613T194329Z-MMSF-RAW-LIVE-001` |
| Archive File | `/Users/maurimesh/maurimesh-raw-evidence/maurimesh-raw-device-proof-MMSF-RAW-LIVE-001.tar.gz` |
| SHA-256 | `6088e2bb906df9f7c4bd2c1246715b047e43b698db40b1026a7bfe981208afe8` |
| Certificate | `docs/proof-certificates/raw_device_MMSF-RAW-LIVE-001_certificate.md` |

Storage verification:
- Raw evidence capture: PASS
- Archive hash verification: PASS
- Manifest copy verification: PASS
- Archive copy verification: PASS
- Final proof storage status: PASS

<!-- RAW_DEVICE_STORE_FORWARD_MMSF_RAW_LIVE_001_END -->
