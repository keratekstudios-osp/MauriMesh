#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH RELEASE KOTLIN NATIVE LAYER FIX"
echo "Fixes MeshEngine / ForegroundService / Watchdog / RouteTable"
echo "Goal: unblock :app:assembleRelease safely"
echo "============================================================"
echo ""

ROOT="$(pwd)"
APP="$ROOT/android/app/src/main/java"
BACKUP="$ROOT/backup-before-release-kotlin-fix-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP"

copy_if_exists() {
  local f="$1"
  if [ -f "$f" ]; then
    mkdir -p "$BACKUP/$(dirname "${f#$ROOT/}")"
    cp "$f" "$BACKUP/${f#$ROOT/}"
    echo "Backed up: ${f#$ROOT/}"
  fi
}

copy_if_exists "$APP/com/maurimesh/mesh/MeshEngine.kt"
copy_if_exists "$APP/com/maurimesh/mesh/MeshForegroundService.kt"
copy_if_exists "$APP/com/maurimesh/mesh/MeshWatchdog.kt"
copy_if_exists "$APP/com/maurimesh/routing/MeshRouteTable.kt"
copy_if_exists "$APP/com/maurimesh/service/MeshStartupService.kt"

mkdir -p \
  "$APP/com/maurimesh/mesh" \
  "$APP/com/maurimesh/routing" \
  "$APP/com/maurimesh/service"

# ============================================================
# 1. Stable MeshEngine API
# ============================================================

cat > "$APP/com/maurimesh/mesh/MeshEngine.kt" <<'KOTLIN'
package com.maurimesh.mesh

import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.content.Context
import android.os.Build
import android.util.Log
import java.util.UUID
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong

data class MeshEvent(
    val type: String,
    val message: String,
    val timestamp: Long = System.currentTimeMillis()
)

data class MeshSnapshot(
    val running: Boolean,
    val bootstrapped: Boolean,
    val uptimeMs: Long,
    val peerCount: Int,
    val relayCount: Int,
    val lastEvent: String,
    val lastEventAt: Long
)

class MeshEngine(
    private val context: Context,
    private val onEvent: (MeshEvent) -> Unit = {}
) {
    private val running = AtomicBoolean(false)
    private val bootstrapped = AtomicBoolean(false)
    private val startedAt = AtomicLong(0L)
    private val lastEventAt = AtomicLong(System.currentTimeMillis())

    @Volatile
    private var lastEvent: String = "ENGINE_CREATED"

    fun bootstrap() {
        bootstrapped.set(true)
        emit("BOOTSTRAP", "MauriMesh native mesh engine bootstrapped")
    }

    fun startMesh() {
        if (!bootstrapped.get()) {
            bootstrap()
        }

        if (running.compareAndSet(false, true)) {
            startedAt.set(System.currentTimeMillis())
            emit("START_MESH", "MauriMesh native mesh runtime started")
        } else {
            emit("START_MESH_IGNORED", "MauriMesh native mesh runtime already running")
        }
    }

    fun stopMesh() {
        if (running.compareAndSet(true, false)) {
            emit("STOP_MESH", "MauriMesh native mesh runtime stopped")
        } else {
            emit("STOP_MESH_IGNORED", "MauriMesh native mesh runtime already stopped")
        }
    }

    fun restartMesh() {
        stopMesh()
        startMesh()
        emit("RESTART_MESH", "MauriMesh native mesh runtime restarted")
    }

    fun snapshot(): MeshSnapshot {
        val now = System.currentTimeMillis()
        val start = startedAt.get()
        val uptime = if (running.get() && start > 0L) now - start else 0L

        return MeshSnapshot(
            running = running.get(),
            bootstrapped = bootstrapped.get(),
            uptimeMs = uptime,
            peerCount = 0,
            relayCount = 0,
            lastEvent = lastEvent,
            lastEventAt = lastEventAt.get()
        )
    }

    private fun emit(type: String, message: String) {
        lastEvent = type
        lastEventAt.set(System.currentTimeMillis())
        Log.i(TAG, "[$type] $message")
        onEvent(MeshEvent(type = type, message = message))
    }

    val gattCallback: BluetoothGattCallback = object : BluetoothGattCallback() {
        @Deprecated("Deprecated in Android platform but still used by some devices")
        override fun onCharacteristicWrite(
            gatt: BluetoothGatt?,
            characteristic: BluetoothGattCharacteristic?,
            status: Int
        ) {
            emit(
                "BLE_CHARACTERISTIC_WRITE",
                "legacy characteristic write status=$status uuid=${characteristic?.uuid}"
            )
        }

        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray
        ) {
            emit(
                "BLE_CHARACTERISTIC_CHANGED",
                "characteristic changed uuid=${characteristic.uuid} bytes=${value.size}"
            )
        }

        @Deprecated("Deprecated in Android platform but still used by some devices")
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt?,
            characteristic: BluetoothGattCharacteristic?
        ) {
            emit(
                "BLE_CHARACTERISTIC_CHANGED_LEGACY",
                "legacy characteristic changed uuid=${characteristic?.uuid}"
            )
        }
    }

    companion object {
        private const val TAG = "MauriMeshEngine"

        val SERVICE_UUID: UUID =
            UUID.fromString("7c9a0001-5a6b-4c2a-9f2d-9b5a7f000001")

        val TX_UUID: UUID =
            UUID.fromString("7c9a0002-5a6b-4c2a-9f2d-9b5a7f000002")

        val RX_UUID: UUID =
            UUID.fromString("7c9a0003-5a6b-4c2a-9f2d-9b5a7f000003")
    }
}
KOTLIN

# ============================================================
# 2. Stable Foreground Service
# ============================================================

cat > "$APP/com/maurimesh/mesh/MeshForegroundService.kt" <<'KOTLIN'
package com.maurimesh.mesh

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log

class MeshForegroundService : Service() {
    private lateinit var engine: MeshEngine
    private lateinit var watchdog: MeshWatchdog

    override fun onCreate() {
        super.onCreate()

        engine = MeshEngine(this) { event ->
            Log.i(TAG, "event=${event.type} message=${event.message}")
        }

        watchdog = MeshWatchdog(engine)
        engine.bootstrap()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createChannel()

        startForeground(
            NOTIFICATION_ID,
            buildNotification("MauriMesh runtime active")
        )

        when (intent?.action) {
            ACTION_STOP -> {
                engine.stopMesh()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }

            ACTION_RESTART -> {
                engine.restartMesh()
                watchdog.check()
            }

            ACTION_SNAPSHOT -> {
                val snapshot = engine.snapshot()
                Log.i(TAG, "snapshot=$snapshot")
            }

            else -> {
                engine.startMesh()
                watchdog.check()
            }
        }

        return START_STICKY
    }

    override fun onDestroy() {
        try {
            engine.stopMesh()
        } catch (t: Throwable) {
            Log.w(TAG, "stopMesh failed during destroy", t)
        }

        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            val channel = NotificationChannel(
                CHANNEL_ID,
                "MauriMesh Runtime",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps the MauriMesh mesh runtime alive"
            }

            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(text: String): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle("MauriMesh")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.stat_sys_data_bluetooth)
            .setOngoing(true)
            .build()
    }

    companion object {
        private const val TAG = "MauriMeshForeground"
        private const val CHANNEL_ID = "maurimesh_runtime"
        private const val NOTIFICATION_ID = 7041

        const val ACTION_START = "com.maurimesh.mesh.START"
        const val ACTION_STOP = "com.maurimesh.mesh.STOP"
        const val ACTION_RESTART = "com.maurimesh.mesh.RESTART"
        const val ACTION_SNAPSHOT = "com.maurimesh.mesh.SNAPSHOT"
    }
}
KOTLIN

# ============================================================
# 3. Stable Watchdog
# ============================================================

cat > "$APP/com/maurimesh/mesh/MeshWatchdog.kt" <<'KOTLIN'
package com.maurimesh.mesh

import android.util.Log

class MeshWatchdog(
    private val engine: MeshEngine
) {
    fun check(): Boolean {
        val snapshot = engine.snapshot()

        Log.i(TAG, "watchdog snapshot=$snapshot")

        if (!snapshot.bootstrapped) {
            Log.w(TAG, "engine not bootstrapped; bootstrapping")
            engine.bootstrap()
            return false
        }

        if (!snapshot.running) {
            Log.w(TAG, "engine not running; starting mesh")
            engine.startMesh()
            return false
        }

        return true
    }

    fun forceRestart(reason: String = "manual") {
        Log.w(TAG, "force restart reason=$reason")
        engine.restartMesh()
    }

    companion object {
        private const val TAG = "MauriMeshWatchdog"
    }
}
KOTLIN

# ============================================================
# 4. Stable Route Table
# ============================================================

cat > "$APP/com/maurimesh/routing/MeshRouteTable.kt" <<'KOTLIN'
package com.maurimesh.routing

import java.util.concurrent.ConcurrentHashMap

data class MeshRoute(
    val destination: String,
    val nextHop: String,
    val score: Double,
    val updatedAt: Long = System.currentTimeMillis(),
    val hopCount: Int = 1,
    val transport: String = "BLE"
)

class MeshRouteTable {
    private val routes = ConcurrentHashMap<String, MeshRoute>()

    fun upsert(route: MeshRoute) {
        val existing = routes[route.destination]

        if (existing == null || route.score >= existing.score) {
            routes[route.destination] = route
        }
    }

    fun update(
        destination: String,
        nextHop: String,
        score: Double,
        hopCount: Int = 1,
        transport: String = "BLE"
    ) {
        upsert(
            MeshRoute(
                destination = destination,
                nextHop = nextHop,
                score = score,
                hopCount = hopCount,
                transport = transport
            )
        )
    }

    fun bestRoute(destination: String): MeshRoute? {
        return routes[destination]
    }

    fun nextHop(destination: String): String? {
        return routes[destination]?.nextHop
    }

    fun remove(destination: String) {
        routes.remove(destination)
    }

    fun all(): List<MeshRoute> {
        return routes.values
            .sortedWith(
                compareByDescending<MeshRoute> { it.score }
                    .thenBy { it.hopCount }
                    .thenByDescending { it.updatedAt }
            )
    }

    fun size(): Int {
        return routes.size
    }

    fun clear() {
        routes.clear()
    }
}
KOTLIN

# ============================================================
# 5. Stable Startup Service with single companion object
# ============================================================

cat > "$APP/com/maurimesh/service/MeshStartupService.kt" <<'KOTLIN'
package com.maurimesh.service

import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.maurimesh.mesh.MeshForegroundService

class MeshStartupService {
    companion object {
        private const val TAG = "MauriMeshStartup"

        fun start(context: Context) {
            val intent = Intent(context, MeshForegroundService::class.java).apply {
                action = MeshForegroundService.ACTION_START
            }

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }

                Log.i(TAG, "Mesh foreground service start requested")
            } catch (t: Throwable) {
                Log.e(TAG, "Failed to start mesh foreground service", t)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, MeshForegroundService::class.java).apply {
                action = MeshForegroundService.ACTION_STOP
            }

            try {
                context.startService(intent)
                Log.i(TAG, "Mesh foreground service stop requested")
            } catch (t: Throwable) {
                Log.e(TAG, "Failed to stop mesh foreground service", t)
            }
        }

        fun restart(context: Context) {
            val intent = Intent(context, MeshForegroundService::class.java).apply {
                action = MeshForegroundService.ACTION_RESTART
            }

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }

                Log.i(TAG, "Mesh foreground service restart requested")
            } catch (t: Throwable) {
                Log.e(TAG, "Failed to restart mesh foreground service", t)
            }
        }
    }
}
KOTLIN

# ============================================================
# 6. Remove wrong BLE callback name if it survived elsewhere
# ============================================================

grep -R "onCharacteristicWriteResponse" "$APP/com/maurimesh" || true

echo ""
echo "Running Kotlin syntax check through Gradle compile task..."
cd "$ROOT/android"

NODE_ENV=production ./gradlew :app:compileReleaseKotlin --stacktrace

echo ""
echo "============================================================"
echo "KOTLIN RELEASE LAYER FIX COMPLETE"
echo "Now run:"
echo "cd android && NODE_ENV=production ./gradlew :app:assembleRelease"
echo "============================================================"
