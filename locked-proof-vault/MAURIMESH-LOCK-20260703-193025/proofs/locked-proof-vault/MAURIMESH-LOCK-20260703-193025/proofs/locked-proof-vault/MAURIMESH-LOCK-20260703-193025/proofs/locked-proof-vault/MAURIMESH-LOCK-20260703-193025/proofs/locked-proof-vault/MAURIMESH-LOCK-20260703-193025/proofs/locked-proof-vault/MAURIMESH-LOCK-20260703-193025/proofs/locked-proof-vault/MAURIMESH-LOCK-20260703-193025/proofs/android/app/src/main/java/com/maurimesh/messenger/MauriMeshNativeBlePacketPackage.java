package com.maurimesh.messenger;

import android.util.Log;
import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class MauriMeshNativeBlePacketPackage implements ReactPackage {
  @Override
  public List<NativeModule> createNativeModules(ReactApplicationContext reactContext) {
    Log.i(
      "MAURIMESH_NATIVE_BLE_GATT",
      "GATT_PACKAGE_CREATE_NATIVE_MODULES_V7 | package=MauriMeshNativeBlePacketPackage | module=MauriMeshNativeBlePacket | finalPassClaimed=false"
    );

    List<NativeModule> modules = new ArrayList<>();
    modules.add(new MauriMeshNativeBlePacketModule(reactContext));

    Log.i(
      "MAURIMESH_NATIVE_BLE_GATT",
      "GATT_PACKAGE_MODULE_ADDED_V7 | package=MauriMeshNativeBlePacketPackage | count=" + modules.size() + " | module=MauriMeshNativeBlePacket | finalPassClaimed=false"
    );

    return modules;
  }

  @Override
  public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {
    return Collections.emptyList();
  }
}
