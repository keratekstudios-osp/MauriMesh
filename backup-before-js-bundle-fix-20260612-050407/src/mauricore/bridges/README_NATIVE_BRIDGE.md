# MauriCore Native Bridge

Required production bridges:

- Android Kotlin bridge
- iOS Swift bridge
- React Native Native Module bridge
- BLE scan/send/receive bridge
- Device battery/runtime bridge
- Secure storage / keystore bridge
- Native crypto bridge
- Native proof log capture

Rule:

UI must not call BLE directly.

Correct path:

UI → TypeScript Core → Rust/Core Decision → Native Bridge → Device Runtime → Proof Ledger
