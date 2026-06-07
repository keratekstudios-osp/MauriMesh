# MauriMesh APK Build + Signing Pipeline

## Safety Rules — Never Commit

- `*.keystore` or `*.jks`
- `*.p12`, `*.pem`
- `.env`, `.env.*`
- `*service-account*.json`
- Signing passwords or key aliases
- Any credential in source control

## Build Architecture

MauriMesh is an Expo managed workflow app with native BLE Kotlin modules.

### Option A — EAS Build (Recommended)

```bash
npm install -g eas-cli
eas login
eas build -p android --profile development   # debug APK
eas build -p android --profile production    # release APK
```

Requires `eas.json` at project root.

### Option B — Local Gradle Build (After Expo Prebuild)

```bash
cd artifacts/messenger-mobile
npx expo prebuild --platform android        # generates android/ folder
cd android
./gradlew :app:assembleDebug                # debug APK
./gradlew :app:assembleRelease              # release APK (requires keystore)
```

## Keystore Setup (Release Only)

```bash
keytool -genkey -v -keystore maurimesh.keystore \
  -alias maurimesh -keyalg RSA -keysize 2048 -validity 10000
```

Store the keystore OUTSIDE the git repository. Reference via environment variables:

```properties
# android/gradle.properties (git-ignored)
MAURIMESH_STORE_FILE=/path/to/maurimesh.keystore
MAURIMESH_STORE_PASSWORD=<from-secrets-manager>
MAURIMESH_KEY_ALIAS=maurimesh
MAURIMESH_KEY_PASSWORD=<from-secrets-manager>
```

## Android Permissions Required for BLE

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE" />
```

## BLE Proof Before Shipping

A release is **not complete** until all of the following are confirmed:

1. APK installs on target device
2. App opens without crash
3. BLE permissions granted at runtime
4. Native scan starts (confirm in logcat: `BLE scan started`)
5. Native advertise starts (confirm in logcat: `BLE advertising`)
6. Peer discovered on second phone
7. Packet sent and reverse ACK received
8. Proof Ledger entry recorded
9. Two-phone proof export generated

### Logcat Proof Commands

```bash
adb logcat -s MauriMeshBle:D ReactNativeJS:D
```

Expected output pattern:
```
MauriMeshBle: BLE scan started
MauriMeshBle: BLE advertising started
MauriMeshBle: Peer found: MM-XXXX
MauriMeshBle: Connect attempt → MM-XXXX
MauriMeshBle: Packet sent: pkt-XXXX
MauriMeshBle: Reverse ACK received: pkt-XXXX
```

## Version Management

App version is set in `app.json`:

```json
{
  "expo": {
    "version": "1.4.2",
    "android": {
      "versionCode": 14
    }
  }
}
```

Increment `versionCode` for every Play Store submission.

## Android Build Check Script

```bash
bash scripts/android-build-check.sh
```
