# MauriMesh Unified Spine Verify Gate v1

Generated: 20260616-174805

## Result

**PASS_READY_FOR_FRESH_APK_BUILD**

## Counts

| Status | Count |
|---|---:|
| PASS | 20 |
| WARN | 1 |
| FAIL | 0 |
| PENDING | 1 |

## Truth

Native BLE/GATT packet-bound PASS is **not claimed**.

Final native BLE/GATT PASS requires the same packetId inside native BLE/GATT transport logs from physical devices.

## Next Checklist

- [ ] Open /maurimesh-spine-exam in APK or preview
- [ ] Confirm route does not crash
- [ ] Confirm route shows routing, resilience, governance, proof, learner/exam result
- [ ] Build fresh APK only if this report says PASS_READY_FOR_FRESH_APK_BUILD
- [ ] Install fresh APK on A06, S10, and A16
- [ ] Open /native-ble-gatt-proof on phones
- [ ] Run Mac logcat capture helper
- [ ] Lock final archive with screenshots, logs, packet IDs, checksum, and vault export

## Files

- Raw verification: /home/runner/workspace/docs/intelligence/UNIFIED_SPINE_VERIFY_RAW_20260616-174805.txt
- TypeScript log: /home/runner/workspace/docs/intelligence/UNIFIED_SPINE_TSC_20260616-174805.log
- Export log: /home/runner/workspace/docs/intelligence/UNIFIED_SPINE_EXPORT_20260616-174805.log
