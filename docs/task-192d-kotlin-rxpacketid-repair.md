# Task #192D — Kotlin rxPacketId Conflict Repair

## Fixed

EAS release build failed at:

- `:app:compileReleaseKotlin`
- duplicate local declaration: `val rxPacketId: String`

Cause:
- #192 native proof event patch was applied more than once.
- This created duplicate RX/ACK emit blocks inside `MauriMeshBleModule.kt`.

Expected final native state:

- exactly one `val rxPacketId = extractPacketIdFromBytes(event.bytes)`
- exactly one `"rx_packet"` emit block
- exactly one `"ack_sent"` emit block
- native event name remains `MauriMeshRawPacketProofEvent`

## Truth boundary

This fixes native compilation. Physical proof still requires a two-phone RX/ACK run after the APK builds.
