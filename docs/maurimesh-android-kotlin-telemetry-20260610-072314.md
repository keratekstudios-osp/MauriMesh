# MauriMesh Android Kotlin Telemetry Module

Generated: 20260610-072314

## Added

- MauriMeshHardwareTelemetryModule.kt
- MauriMeshHardwareTelemetryPackage.kt
- MainApplication registration patch
- Native battery telemetry
- Native memory telemetry
- Native storage telemetry
- Native thermal risk telemetry
- Native BLE adapter telemetry
- JS bridge compatibility with NativeHardwareTelemetry.ts

## Native module name

MauriMeshHardwareTelemetry

## JS method

getHardwareTelemetry()

## Truth

This reads device state from Android APIs.
It does not repair physical hardware.
It does not bypass Android restrictions.
It does not prove BLE message delivery by itself.
BLE proof still requires TX/RX/ACK logcat evidence.
