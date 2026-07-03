# MauriMesh EAS Native BLE/GATT Cloud Compile Check

Generated: 2026-06-14T02:16:52Z

## Build ID

```txt
MM-EAS-NATIVE-BLE-GATT-COMPILE-20260614-015844
```

## EAS Command Status

```txt
EAS_COMMAND_FAILED
```

Exit code:

```txt
1
```

## Profile

```txt
preview
```

## Purpose

This EAS build is a **cloud native compile check**.

It is not a final native BLE/GATT packet-bound proof.

## Build Links Found In Log

```txt
https://docs.expo.dev/eas/environment-variables/#setting-the-environment-for-your-builds https://expo.dev/accounts/maurimesh-network/projects/mauri-mesh/builds/7a497833-eb1d-4a55-96a1-ff197313f154 https://expo.dev/accounts/maurimesh-network/projects/mauri-mesh/builds/7a497833-eb1d-4a55-96a1-ff197313f154#run-gradlew) https://expo.fyi/eas-build-archive 
```

## Files

Precheck:

```txt
/home/runner/workspace/docs/build-gates/eas-native-ble-gatt-compile-precheck-20260614-015844.txt
```

Log:

```txt
/home/runner/workspace/docs/build-gates/eas-native-ble-gatt-compile-check-20260614-015844.log
```

Git status before build:

```txt
/home/runner/workspace/docs/build-gates/git-status-before-eas-compile-20260614-015844.txt
```

Readiness gate:

```txt
/home/runner/workspace/docs/build-gates/MAURIMESH_EAS_NATIVE_BLE_GATT_READINESS_20260614-015651.json
```

## Native Proof Truth

Native BLE/GATT packet-bound PASS is **NOT CLAIMED**.

A PASS can only be claimed after real device logs show the same packetId across:

```txt
advertise_start_packetId
scan_result_packetId
gatt_write_packetId
gatt_read_packetId
characteristic_changed_packetId
relay_packetId
ack_packetId
```

## Next Step

If EAS build succeeds:
1. Download/install APK.
2. Run the native BLE/GATT packet-bound validator on device logs.
3. Do not claim PASS unless packetId appears in required native stages.

If EAS build fails:
1. Read EAS failure lines.
2. Patch only the exact failing native/Kotlin/config issue.
3. Re-run readiness gate before another build.
