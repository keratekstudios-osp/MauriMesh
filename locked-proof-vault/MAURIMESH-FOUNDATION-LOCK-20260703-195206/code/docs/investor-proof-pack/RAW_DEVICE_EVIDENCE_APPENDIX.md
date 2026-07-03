# MauriMesh Raw Device Evidence Appendix

## Executive Proof Statement

MauriMesh completed a three-device Store-Forward raw-device evidence capture using Mac ADB/logcat capture for packet ID `MMSF-RAW-LIVE-001`.

The result was:

`RAW DEVICE EVIDENCE VERDICT: PASS`

## Why This Matters

This moves the Store-Forward milestone beyond screenshots and app-screen proof. The packet ID was used in the phone proof flow and captured through raw device evidence collection.

## Devices

| Role | Device | Function |
|---|---|---|
| PHONE_A | Samsung Galaxy A06 | Sender |
| PHONE_B | Samsung Galaxy S10 | Store-Forward Relay |
| PHONE_C | Samsung Galaxy A16 | Delayed Receiver + ACK |

## Evidence Location

Raw evidence folder on Mac:

`/Users/maurimesh/maurimesh-raw-evidence/run-20260613T194329Z-MMSF-RAW-LIVE-001`

Archive file on Mac:

`/Users/maurimesh/maurimesh-raw-evidence/maurimesh-raw-device-proof-MMSF-RAW-LIVE-001.tar.gz`

## SHA-256 Seal

`6088e2bb906df9f7c4bd2c1246715b047e43b698db40b1026a7bfe981208afe8`

## Storage Status

- Archive created: PASS
- SHA-256 hash verified: PASS
- Manifest copied to raw-evidence folder, Desktop, and Documents: PASS
- Archive copied to Desktop and Documents: PASS

## Boundary

This certificate records the verified raw-device evidence milestone for the current APK/proof flow. Future APKs should repeat this proof after major runtime, BLE, routing, or native bridge changes.
