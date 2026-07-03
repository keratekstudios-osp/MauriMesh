# MauriMesh Unified Intelligence Spine v1

## Purpose

This structure wires all major MauriMesh runtime intelligence layers into one auditable system.

## Layers

1. Proof Layer
   - packetId chain validation
   - proof verdicts
   - native BLE/GATT truth gate

2. Routing Layer
   - trust scoring
   - latency scoring
   - resilience scoring
   - governance scoring
   - best route selection

3. Resilience Layer
   - dashboard crash recovery
   - vault stability checks
   - packet mismatch recovery
   - native BLE/GATT missing-evidence recovery

4. Governance Layer
   - tikanga truth protection
   - false native PASS refusal
   - exam approval warnings
   - protected proof claim handling

5. Exam Layer
   - simple pass/fail checks
   - one final score
   - simple decision state
   - lockability result

6. Spine Layer
   - combines proof, routing, resilience, governance, and exam into one result

## Truth Rule

Native BLE/GATT packet-bound PASS is never claimed unless the same packetId appears inside native BLE/GATT transport logs.

APK proof-screen workflow and local proof vault storage are valid milestones, but they are not native BLE/GATT packet-bound proof by themselves.
