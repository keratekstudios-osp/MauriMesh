# MauriMesh Raw-Device Evidence Run Kit

## Status

**READY TO CAPTURE**

This kit prepares the next live proof run using real device logs from:

- PHONE_A: Samsung Galaxy A06 / Sender
- PHONE_B: Samsung Galaxy S10 / Store-forward relay
- PHONE_C: Samsung Galaxy A16 / Delayed receiver + ACK

## Important

Run the capture script on the Mac terminal where ADB can see the phones.

## Setup

On the Mac:

```bash
adb devices -l
````

Set the three serials:

```bash
export PHONE_A_SERIAL="A06_SERIAL_HERE"
export PHONE_B_SERIAL="S10_SERIAL_HERE"
export PHONE_C_SERIAL="A16_SERIAL_HERE"
```

Then run from project root:

```bash
bash scripts/proof-capture/maurimesh-raw-device-evidence-run.sh
```

## What It Captures

* ADB device list before and after
* Device identity files
* Raw logcat from A06
* Raw logcat from S10
* Raw logcat from A16
* Filtered MauriMesh proof logs
* Packet ID candidates
* Selected packet ID
* Raw evidence verifier report
* SHA-256 sums
* Compressed evidence archive

## Target Proof

Store-forward delayed delivery:

A06 sender → S10 stores packet → A16 unavailable → S10 hold delay → A16 returns → S10 forwards stored packet → A16 receives → A16 ACKs S10 → S10 relays ACK → A06 receives final ACK.
