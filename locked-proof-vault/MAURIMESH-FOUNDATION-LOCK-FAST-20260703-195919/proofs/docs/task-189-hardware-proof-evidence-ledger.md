# Task #189 — Save Hardware Proof Evidence to Server-Side Proof Ledger

Marker: `TASK_189_HARDWARE_EVIDENCE_LEDGER_20260608_A`

## Installed

- `POST /api/proof/evidence`
- `GET /api/proof/evidence?type=two_phone_hardware_evidence`
- server-side JSONL proof ledger fallback
- schema patch attempts to add `proofLedger.type`
- mobile proof evidence client
- Two-Phone Proof screen save button patch attempt
- web hardware evidence ledger panel
- hardware evidence type filter

## Truth boundary

This stores submitted evidence JSON on the server side.

It does not prove:
- BLE packet was physically received
- ACK was physically returned
- relay completed

Those require APK/two-phone or three-phone hardware logs.
