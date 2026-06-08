package com.maurimesh.messenger

import java.util.UUID

object MeshRawPacketUuids {
  val SERVICE_UUID: UUID =
    UUID.fromString("7c7a0001-4d41-5552-494d-455348000001")

  val RAW_PACKET_CHARACTERISTIC_UUID: UUID =
    UUID.fromString("7c7a0002-4d41-5552-494d-455348000002")
}

data class MeshPeerCacheEntry(
  val nodeId: String,
  val address: String,
  val name: String?,
  val lastSeenAtMs: Long,
  val rssi: Int?
)
