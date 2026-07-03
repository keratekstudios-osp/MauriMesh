package com.maurimesh.messenger

import android.util.Log
import java.nio.charset.Charset

/**
 * MauriMesh native BLE/GATT packet-bound proof logger.
 *
 * Truth rule:
 * Native BLE/GATT packet-bound PASS is not claimed unless the same packetId appears
 * directly inside native Android BLE/GATT logs across advertise, scan, GATT write/read,
 * characteristic changed, relay, and ACK events.
 */
object MauriMeshNativeBlePacketLogger {
    private const val TAG = "MAURIMESH_NATIVE_BLE_GATT"

    private val packetRegex = Regex(
        pattern = "(MM[A-Z0-9-]*-[A-Z0-9]{4,}-[A-Z0-9]{4,})",
        options = setOf(RegexOption.IGNORE_CASE)
    )

    @JvmStatic
    fun extractPacketId(text: String?): String {
        if (text.isNullOrBlank()) return "UNKNOWN_PACKET_ID"
        return packetRegex.find(text)?.value ?: "UNKNOWN_PACKET_ID"
    }

    @JvmStatic
    fun extractPacketId(bytes: ByteArray?): String {
        if (bytes == null || bytes.isEmpty()) return "UNKNOWN_PACKET_ID"

        val utf8 = try {
            bytes.toString(Charsets.UTF_8)
        } catch (_: Throwable) {
            ""
        }

        val direct = extractPacketId(utf8)
        if (direct != "UNKNOWN_PACKET_ID") return direct

        val hex = bytes.joinToString("") { "%02X".format(it) }
        return extractPacketId(hex)
    }

    @JvmStatic
    fun event(stage: String, packetId: String?, detail: String? = null) {
        val safePacketId = if (packetId.isNullOrBlank()) "UNKNOWN_PACKET_ID" else packetId
        val safeStage = if (stage.isBlank()) "unknown_stage" else stage
        val safeDetail = detail ?: ""
        Log.i(TAG, "stage=$safeStage packetId=$safePacketId detail=$safeDetail")
    }

    @JvmStatic
    fun eventFromText(stage: String, text: String?, detail: String? = null) {
        event(stage, extractPacketId(text), detail)
    }

    @JvmStatic
    fun eventFromBytes(stage: String, bytes: ByteArray?, detail: String? = null) {
        event(stage, extractPacketId(bytes), detail)
    }

    @JvmStatic
    fun advertiseStart(packetId: String?, detail: String? = null) {
        event("advertise_start_packetId", packetId, detail)
    }

    @JvmStatic
    fun scanResult(packetId: String?, detail: String? = null) {
        event("scan_result_packetId", packetId, detail)
    }

    @JvmStatic
    fun gattWrite(bytes: ByteArray?, detail: String? = null) {
        eventFromBytes("gatt_write_packetId", bytes, detail)
    }

    @JvmStatic
    fun gattRead(bytes: ByteArray?, detail: String? = null) {
        eventFromBytes("gatt_read_packetId", bytes, detail)
    }

    @JvmStatic
    fun characteristicChanged(bytes: ByteArray?, detail: String? = null) {
        eventFromBytes("characteristic_changed_packetId", bytes, detail)
    }

    @JvmStatic
    fun relay(packetId: String?, detail: String? = null) {
        event("relay_packetId", packetId, detail)
    }

    @JvmStatic
    fun ack(packetId: String?, detail: String? = null) {
        event("ack_packetId", packetId, detail)
    }
}
