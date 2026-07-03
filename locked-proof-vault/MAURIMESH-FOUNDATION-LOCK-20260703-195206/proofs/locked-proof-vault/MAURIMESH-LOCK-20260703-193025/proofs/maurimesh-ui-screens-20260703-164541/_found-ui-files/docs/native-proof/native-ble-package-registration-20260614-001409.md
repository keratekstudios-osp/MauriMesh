# MauriMesh Native BLE Package Registration

Generated: 20260614-001409

## Registration search
```txt
android/app/src/main/java/com/maurimesh/messenger/MainApplication.kt:            add(MauriMeshNativeBlePacketPackage())
android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketPackage.java:public class MauriMeshNativeBlePacketPackage implements ReactPackage {
```

## Truth
If MainApplication contains MauriMeshNativeBlePacketPackage(), the native bridge can be reached by NativeModules.
If not, the app may still export but packet logs may fall back to REACT_NATIVE_FALLBACK.
