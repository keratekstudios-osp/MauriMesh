package com.maurimesh.messenger

import android.util.Log
import java.nio.charset.Charset
import java.util.Locale

/**
 * MauriMesh GATT packet payload proof logger.
 *
 * Truth:
 * - This logs packetId extracted from native GATT payload bytes.
 * - This does not claim final native BLE/GATT packet-bound PASS.
 * - Final PASS still requires same packetId across required physical-device GATT logs.
 */
object MauriMeshGattPacketProof {
  private const val TAG = "MAURIMESH_NATIVE_BLE_GATT"

  fun logGattPayload(stage: String, value: ByteArray?, context: String) {
    val text = decodePayload(value)
    val packetId = extractPacketId(text)
    val len = value?.size ?: 0
    val hex = toHex(value, 96)
    val packetSeen = packetId != "NONE"

    Log.i(
      TAG,
      "GATT_PACKET_PAYLOAD" +
        " | stage=${clean(stage)}" +
        " | packetId=$packetId" +
        " | nativePacketBoundCandidate=$packetSeen" +
        " | nativePacketBound=false" +
        " | len=$len" +
        " | hex=$hex" +
        " | text=${clean(text)}" +
        " | context=${clean(context)}"
    )
  }

  fun logGattEvent(stage: String, packetId: String?, context: String) {
    val safePacketId = packetId?.takeIf { it.isNotBlank() } ?: "NONE"

    Log.i(
      TAG,
      "GATT_PACKET_EVENT" +
        " | stage=${clean(stage)}" +
        " | packetId=${clean(safePacketId)}" +
        " | nativePacketBound=false" +
        " | context=${clean(context)}"
    )
  }

  fun extractPacketId(text: String): String {
    val regex = Regex("""MM[A-Z0-9]*-[A-Z0-9]{3,}-[A-Z0-9]{3,}""")
    return regex.find(text)?.value ?: "NONE"
  }

  private fun decodePayload(value: ByteArray?): String {
    if (value == null || value.isEmpty()) return ""

    return try {
      value.toString(Charsets.UTF_8)
    } catch (_: Throwable) {
      try {
        value.toString(Charset.forName("ISO-8859-1"))
      } catch (_: Throwable) {
        ""
      }
    }
  }

  private fun toHex(value: ByteArray?, maxBytes: Int): String {
    if (value == null || value.isEmpty()) return ""
    return value.take(maxBytes).joinToString("") {
      String.format(Locale.US, "%02X", it.toInt() and 0xff)
    }
  }

  private fun clean(value: String): String {
    return value
      .replace("\n", " ")
      .replace("\r", " ")
      .replace("|", "/")
      .take(220)
  }
}
