# MauriMesh Native Telemetry Kotlin Target

Native module expected by JavaScript:

MauriMeshHardwareTelemetry

Expected method:

getHardwareTelemetry()

Expected fields:

batteryPercent
isCharging
memoryUsedMb
memoryTotalMb
storageFreeMb
storageTotalMb
thermalRisk
bleAvailable
bleEnabled
blePressure
appCrashRisk
foreground
timestamp

This JS bridge safely falls back until the Android Kotlin module is installed.
