# MauriMesh Android Background Runtime Plan

> **Canonical contract** — defines every requirement for keeping MauriMesh
> scanning and listening when the app is backgrounded on Android.
> Status column uses RuntimeTruthEngine vocabulary:
> `real_native` | `partial` | `unavailable`.

---

## Capability Status Table

| Capability | Current Status | Requires |
|---|---|---|
| Foreground Service | `partial` | Scaffold in `plugins/android-src/MeshForegroundService.kt` (START_STICKY + startForeground); deployed via expo prebuild; unverified on physical hardware |
| Persistent Notification | `partial` | `buildNotification()` in MeshForegroundService.kt (ONGOING=true, "MauriMesh Active"); deployed via plugin; unverified on physical hardware |
| Background BLE Scan | `unavailable` | Foreground Service + `BLUETOOTH_SCAN` |
| Background BLE Advertise | `unavailable` | Foreground Service + `BLUETOOTH_ADVERTISE` |
| Battery Optimisation Bypass | `unavailable` | OS Settings prompt (Kotlin intent) |
| Crash Restart (START_STICKY) | `unavailable` | Native `onStartCommand` return value |
| JS Heartbeat (foreground only) | `partial` | AppState + setInterval (implemented) |

No capability may claim `real_native` until verified by the Two-Phone Proof task
on physical Android hardware.

---

## 1. Foreground Service

A foreground service is **mandatory** for background BLE. Without it Android
will kill the process within minutes when the screen locks.

### Kotlin scaffold (to be added to `android/app/src/main/java/`)

```kotlin
class MauriMeshForegroundService : Service() {

    companion object {
        const val NOTIFICATION_ID = 1001
        const val CHANNEL_ID      = "maurimesh_mesh"
        const val ACTION_STOP     = "com.maurimesh.STOP_SERVICE"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) { stopSelf(); return START_NOT_STICKY }
        startForeground(NOTIFICATION_ID, buildPersistentNotification())
        startBleOperations()
        scheduleHeartbeat()
        return START_STICKY   // OS restarts the service if killed
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startBleOperations() {
        // Wire BLE scan + advertise here once native modules land
    }

    private fun scheduleHeartbeat() {
        val handler = Handler(Looper.getMainLooper())
        val tick = object : Runnable {
            override fun run() {
                logHeartbeat()
                handler.postDelayed(this, 2 * 60 * 1000L)  // every 2 min
            }
        }
        handler.post(tick)
    }

    private fun logHeartbeat() {
        // Bridge call into JS RuntimeErrorLedger or write directly to SQLite
    }
}
```

### AndroidManifest.xml additions

```xml
<!-- Permissions -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE" />

<!-- Service declaration -->
<service
    android:name=".MauriMeshForegroundService"
    android:foregroundServiceType="connectedDevice"
    android:exported="false"
    android:stopWithTask="false" />
```

---

## 2. Persistent Notification

Required to keep the foreground service alive. Must always be visible.

### Notification spec

| Field | Value |
|---|---|
| Title | "MauriMesh Mesh Active" |
| Body | "Scanning for peers… / X peers connected" |
| Icon | mesh icon (small, monochrome) |
| Channel ID | `maurimesh_mesh` |
| Importance | `IMPORTANCE_LOW` (silent, no sound) |
| Ongoing | `true` (cannot be swiped away) |
| Tap action | Deep-link back to app main screen |

### Kotlin notification builder

```kotlin
private fun buildPersistentNotification(): Notification {
    val pendingIntent = PendingIntent.getActivity(
        this, 0,
        Intent(this, MainActivity::class.java),
        PendingIntent.FLAG_IMMUTABLE
    )
    return NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle("MauriMesh Mesh Active")
        .setContentText("Scanning for peers…")
        .setSmallIcon(R.drawable.ic_mesh)
        .setOngoing(true)
        .setContentIntent(pendingIntent)
        .build()
}

private fun createNotificationChannel() {
    val channel = NotificationChannel(
        CHANNEL_ID, "Mesh Service",
        NotificationManager.IMPORTANCE_LOW
    )
    channel.description = "Keeps MauriMesh alive in background"
    getSystemService(NotificationManager::class.java)
        .createNotificationChannel(channel)
}
```

---

## 3. BLE Scan Constraints (Android 12+)

Android 7+ throttles unfiltered background BLE scans to 5 scans per 30 seconds.
Android 12 adds mandatory `BLUETOOTH_SCAN` permission.

### Strategy

```kotlin
val scanSettings = ScanSettings.Builder()
    .setScanMode(ScanSettings.SCAN_MODE_LOW_POWER)  // background-safe
    .setCallbackType(ScanSettings.CALLBACK_TYPE_ALL_MATCHES)
    .setMatchMode(ScanSettings.MATCH_MODE_STICKY)
    .build()

val scanFilter = ScanFilter.Builder()
    .setServiceUuid(ParcelUuid(MAURIMESH_SERVICE_UUID))
    .build()

bleScanner.startScan(listOf(scanFilter), scanSettings, scanCallback)
```

### Error handling

```kotlin
override fun onScanFailed(errorCode: Int) {
    when (errorCode) {
        SCAN_FAILED_APPLICATION_REGISTRATION_FAILED ->
            // Too many apps scanning — back off and retry in 30 s
        SCAN_FAILED_OUT_OF_HARDWARE_RESOURCES ->
            // Reduce concurrent scans
    }
}
```

### Duty cycling

- Background: scan 5 s, pause 25 s (stay under throttle limit)
- Foreground: scan continuously at `SCAN_MODE_BALANCED`
- OEM power-saving (Samsung/Xiaomi): detect and warn user

---

## 4. BLE Advertise Restart Policy

Advertising can continue in background via the foreground service, but some OEM
devices (Samsung, Xiaomi) disable BLE advertising in aggressive power-saving mode.

```kotlin
val advertiseSettings = AdvertiseSettings.Builder()
    .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_POWER)
    .setConnectable(true)
    .setTimeout(0)  // Advertise indefinitely
    .build()

// On advertise failure — restart after backoff
override fun onStartFailure(errorCode: Int) {
    handler.postDelayed({
        bleAdvertiser.startAdvertising(advertiseSettings, advertiseData, advertiseCallback)
    }, 5_000L)
}
```

---

## 5. Battery Optimisation Bypass

Without whitelisting, Android Doze mode will throttle/kill BLE operations.

### Detection and prompt (Kotlin)

```kotlin
val pm = getSystemService(POWER_SERVICE) as PowerManager
if (!pm.isIgnoringBatteryOptimizations(packageName)) {
    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
    intent.data = Uri.parse("package:$packageName")
    startActivity(intent)
}
```

### JS-level detection (current approach via expo-battery)

```typescript
import * as Battery from "expo-battery";
const mode = await Battery.getPowerStateAsync();
// mode.lowPowerMode === true → warn user
```

The JS approach cannot request the OS whitelist directly — only the Kotlin path
above can. The UI check surfaces a "Go to Settings" button as a workaround.

---

## 6. Crash Restart Behaviour

`START_STICKY` makes Android restart the service after process death.
Additional watchdog:

```kotlin
// In Application.onCreate() — monitor if service is alive
Handler(Looper.getMainLooper()).postDelayed({
    if (!isServiceRunning(MauriMeshForegroundService::class.java)) {
        startForegroundService(
            Intent(this, MauriMeshForegroundService::class.java)
        )
    }
}, 10_000L)

fun isServiceRunning(serviceClass: Class<*>): Boolean {
    val am = getSystemService(ACTIVITY_SERVICE) as ActivityManager
    return am.getRunningServices(Int.MAX_VALUE)
        .any { it.service.className == serviceClass.name }
}
```

---

## 7. Background Heartbeat

A heartbeat event logged every 2 minutes proves the service is alive during testing.

### JS-level (partial — foreground only)

```typescript
// BackgroundRuntimeService.ts — runs while AppState === "active"
setInterval(() => {
  runtimeErrorLedger.record({
    severity: "info",
    source:   "background_heartbeat",
    message:  `Heartbeat @ ${new Date().toISOString()} — AppState: active`,
    recoveryHint: "If heartbeats stop while screen is locked, native foreground service is required.",
  });
}, HEARTBEAT_INTERVAL_MS);
```

### Native-level (real_native — to be implemented)

The Kotlin `scheduleHeartbeat()` in `MauriMeshForegroundService` logs to a
SQLite table that the JS layer can read on next app open.

---

## 8. OEM-Specific Considerations

| OEM | Known Issue | Mitigation |
|---|---|---|
| Samsung (OneUI 5+) | Adaptive Battery kills unwhitelisted BLE | Battery Settings → Never sleeping apps |
| Xiaomi (MIUI 14+) | Background app restrictor kills services | App Settings → No restrictions |
| Huawei | Power-genie kills background processes | Protected apps whitelist |
| OnePlus | Aggressive idle mode | Battery Optimisation → Unrestricted |

---

## Implementation Order (priority before release)

1. ✅ Scaffold typed `BackgroundRuntimeContract` (this task)
2. ✅ JS heartbeat (partial — foreground only, this task)
3. ⬜ Convert to bare workflow (`expo eject`) to add native Kotlin
4. ⬜ Implement `MauriMeshForegroundService` in Kotlin
5. ⬜ Implement persistent notification
6. ⬜ Add battery optimisation Kotlin prompt
7. ⬜ Wire BLE scan + advertise into service
8. ⬜ Two-phone proof with screen off (physical device)
9. ⬜ Verify heartbeat survives screen lock (≥ 10 minutes)

---

## Current Honest Status

Background runtime is **NOT YET IMPLEMENTED** at the native level.

The foreground service, persistent notification, and battery optimisation bypass
require either a bare Expo workflow + Kotlin implementation or a native module.

The `BackgroundRuntimeContract` module (TypeScript) enforces honest status
reporting: no capability claims `real_native` until two-phone proof exists.
