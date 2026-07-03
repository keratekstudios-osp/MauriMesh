# Android Build Checklist — MauriMesh

> Real BLE proof CANNOT be done inside Replit web preview.
> All steps below require a Mac or Linux machine with Android tooling and a physical Android device.

---

## Prerequisites

- [ ] Node.js 20+, pnpm installed
- [ ] Java 17+ installed (`java -version`)
- [ ] Android SDK installed (`ANDROID_HOME` set)
- [ ] ADB installed and in PATH (`adb version`)
- [ ] EAS CLI installed (`npm install -g eas-cli`)
- [ ] Expo account + `EXPO_TOKEN` set in Replit secrets
- [ ] Two physical Android phones (for peer-to-peer BLE testing)

---

## Step 1 — Clone and install

```sh
git clone <repo-url>
cd <repo>
pnpm install
```

---

## Step 2 — Configure environment

```sh
cp .env.example .env
# Fill in: MAURIMESH_API_URL pointing to your deployed API or local tunnel
```

---

## Step 3 — Start the API server locally (or use deployed URL)

```sh
pnpm mauri:api
# Or use the deployed Replit URL from the API server artifact
```

---

## Step 4 — Build the Expo dev client APK

```sh
cd artifacts/messenger-mobile
eas build --platform android --profile development --local
# Or submit to EAS cloud build:
eas build --platform android --profile development
```

---

## Step 5 — Install APK on device

```sh
adb install -r path/to/build.apk
# Or use EAS: eas build --platform android --profile preview
```

---

## Step 6 — Start Metro bundler

```sh
pnpm --filter @workspace/messenger-mobile run dev
```

---

## Step 7 — BLE permissions (Android Manifest)

Ensure these permissions are in `artifacts/messenger-mobile/android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

---

## Step 8 — BLE proof via logcat

```sh
adb logcat | grep -E "MauriMeshBLE|BleScanProof|TransportAdapter"
```

Expected log lines:
- `[BleScanProof] Scan started`
- `[MauriMeshBLE][Transport] Device registered: <MAC>`
- `[MauriMeshBLE][Transport] Sent packet <id> → <peer> Nms`

---

## Step 9 — Native module verification

In Diagnostics screen on the physical device:
- **Native BLE Module**: Must show `MauriMeshBle` or `MauriMeshBleModule` (not "Not linked")
- **Runtime Mode**: Must show `native_android` (not `native_missing`)
- **API Bridge**: Must show `pass` (Connected)

---

## Step 10 — Two-device BLE test

1. Open app on Phone A — tap **Scan**
2. Open app on Phone B — confirm it appears in peer list on Phone A
3. Send a message from Phone A to Phone B
4. Verify delivery in logcat on both devices

---

## What is NOT tested in Replit

| Feature | Replit web | Physical device |
|---|---|---|
| BLE scanning | ✗ (simulation) | ✓ |
| GATT write/read | ✗ | ✓ |
| NativeModules.MauriMeshBle | ✗ (null) | ✓ |
| AES-256-GCM encrypt | ✗ (planned) | ✓ (when implemented) |
| Push notifications | ✗ | ✓ |
| Background BLE | ✗ | ✓ |
