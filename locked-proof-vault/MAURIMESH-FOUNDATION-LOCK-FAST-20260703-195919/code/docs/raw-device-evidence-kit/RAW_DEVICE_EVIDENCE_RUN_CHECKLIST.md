
# Raw-Device Evidence Run Checklist

## Before Starting

* [ ] A06 has MauriMesh installed.
* [ ] S10 has MauriMesh installed.
* [ ] A16 has MauriMesh installed.
* [ ] ADB sees all three phones.
* [ ] Screen recording is ready on all three phones.
* [ ] Battery level is safe on all devices.
* [ ] Packet ID will be visible or copied.
* [ ] Replit/project folder is synced to the Mac if needed.

## Terminal Setup

Run:

```bash
adb devices -l
```

Set:

```bash
export PHONE_A_SERIAL="A06_SERIAL_HERE"
export PHONE_B_SERIAL="S10_SERIAL_HERE"
export PHONE_C_SERIAL="A16_SERIAL_HERE"
```

Start capture:

```bash
bash scripts/proof-capture/maurimesh-raw-device-evidence-run.sh
```

## During Proof

* [ ] Start screen recording on A06.
* [ ] Start screen recording on S10.
* [ ] Start screen recording on A16.
* [ ] Open Store-Forward Delay Proof screen.
* [ ] Confirm one packet ID.
* [ ] Complete every store-forward stage.
* [ ] Approve the proof.
* [ ] Return to terminal and press ENTER.

## After Proof

* [ ] Confirm RAW EVIDENCE VERDICT.
* [ ] Save the evidence folder.
* [ ] Save the tar.gz archive.
* [ ] Copy packet ID into the master archive.
* [ ] Do not overwrite the raw logs.
  MDEOF

cat > "$BOUNDARY" <<'MDEOF'

# Raw-Device Evidence Boundary

## What This Kit Proves After Capture

When the capture run passes, it proves that the selected packet ID and required store-forward proof stages were found in raw ADB/logcat captures from the three-device evidence folder.

## What It Does Not Prove Yet

It does not prove:

* Independent third-party certification.
* RF-layer laboratory capture.
* Carrier approval.
* Emergency-service approval.
* Full production security audit.
* Long-duration unattended reliability.

## Correct Claim After PASS

The correct claim after a successful raw-device evidence run is:

**MauriMesh has a synchronized raw-device evidence folder showing the Store-Forward proof sequence across A06, S10, and A16 logs for one selected packet ID.**
