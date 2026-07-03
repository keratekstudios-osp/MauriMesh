package com.maurimesh.messenger

import android.content.Intent
import android.os.Build
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import java.io.File

class MauriMeshBackgroundRuntimeModule(
  private val reactContext: ReactApplicationContext
) : ReactContextBaseJavaModule(reactContext) {

  override fun getName(): String = "MauriMeshBackgroundRuntime"

  @ReactMethod
  fun startForegroundMeshRuntime(promise: Promise) {
    try {
      val intent = Intent(reactContext, MauriMeshForegroundService::class.java)
      intent.action = MauriMeshForegroundService.ACTION_START

      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        reactContext.startForegroundService(intent)
      } else {
        reactContext.startService(intent)
      }

      promise.resolve(true)
    } catch (error: Throwable) {
      promise.reject("MAURIMESH_FOREGROUND_START_FAILED", error)
    }
  }

  @ReactMethod
  fun stopForegroundMeshRuntime(promise: Promise) {
    try {
      val intent = Intent(reactContext, MauriMeshForegroundService::class.java)
      intent.action = MauriMeshForegroundService.ACTION_STOP
      reactContext.startService(intent)
      promise.resolve(true)
    } catch (error: Throwable) {
      promise.reject("MAURIMESH_FOREGROUND_STOP_FAILED", error)
    }
  }

  @ReactMethod
  fun getForegroundMeshRuntimeStatus(promise: Promise) {
    try {
      val heartbeat = File(
        reactContext.filesDir,
        "maurimesh-runtime-ledger/foreground-service-heartbeat.json"
      )

      val map = com.facebook.react.bridge.Arguments.createMap()
      map.putString("marker", MauriMeshForegroundService.MARKER)
      map.putBoolean("heartbeatPresent", heartbeat.exists())
      map.putString("heartbeat", if (heartbeat.exists()) heartbeat.readText() else "")
      map.putString("capability", "real_native")
      map.putString(
        "truth",
        "Foreground service exists and heartbeat file proves native service execution. Screen-off survival still requires physical phone proof."
      )

      promise.resolve(map)
    } catch (error: Throwable) {
      promise.reject("MAURIMESH_FOREGROUND_STATUS_FAILED", error)
    }
  }
}
