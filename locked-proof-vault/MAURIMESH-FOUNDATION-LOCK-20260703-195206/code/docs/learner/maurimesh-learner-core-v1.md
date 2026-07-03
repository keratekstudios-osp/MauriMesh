# MauriMesh Learner Core v1

## Purpose

The learner turns proof logs, crash logs, ADB states, Gradle results, EAS outcomes, and packet evidence into structured memory.

## It can classify

- APK workflow proof
- ReactNativeJS monitor proof
- bridge-only native log request
- native BLE/GATT packet-bound evidence
- inconclusive evidence

## It can recommend recovery

Known patterns:

- ADB offline or host down
- Java missing
- Android SDK missing
- syntax import error
- incomplete proof path
- native BLE/GATT not confirmed

## Truth rule

The learner does not claim native BLE/GATT PASS unless the same packetId appears in native transport evidence.
