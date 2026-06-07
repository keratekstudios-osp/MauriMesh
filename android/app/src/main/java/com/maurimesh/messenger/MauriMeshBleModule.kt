package com.maurimesh.messenger

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod

class MauriMeshBleModule(
  private val reactContext: ReactApplicationContext
) : ReactContextBaseJavaModule(reactContext) {

  override fun getName(): String {
    return "MauriMeshBle"
  }

  @ReactMethod
  fun getStatus(promise: Promise) {
    try {
      val status = Arguments.createMap()
      status.putString("module", "MauriMeshBle")
      status.putString("mode", "read_only")
      status.putBoolean("modulePresent", true)
      status.putBoolean("liveBleActive", false)
      status.putString(
        "truth",
        "Native module is registered. This method does not scan, advertise, connect, send, receive, ACK, or relay."
      )
      promise.resolve(status)
    } catch (error: Exception) {
      promise.reject("MAURIMESH_BLE_STATUS_ERROR", error)
    }
  }
}
