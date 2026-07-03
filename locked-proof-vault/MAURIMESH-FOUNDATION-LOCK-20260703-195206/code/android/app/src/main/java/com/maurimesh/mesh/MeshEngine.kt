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
