# MauriMesh Final Route Crash Guard v1

Generated: 20260614-045232

## Route file check
- PASS: app/dashboard.tsx
- PASS: app/locked-proof-vault.tsx
- PASS: app/proof-vault-health.tsx
- PASS: app/learner-core.tsx
- PASS: app/store-forward-proof.tsx
- PASS: app/3-device-proof.tsx
- PASS: app/ble-3-device-proof.tsx
- PASS: app/ble-2-hop-proof.tsx
## Dashboard route references
104:      router.push(route as never);
163:          onPress={() => router.push("/learner-core")}
168:          onPress={() => router.push("/proof-vault-health")}
## Risk marker scan
/home/runner/workspace/src/operating/validateMauri155OperatingRuntime.ts:    throw new Error("Layer count is below 155.");
/home/runner/workspace/src/integration/validateMauriRuntimeIntegrationBridge.ts:    throw new Error("Runtime layer count is below 155.");
/home/runner/workspace/src/mesh/validateBluetoothMeshSuperEngine.ts:    throw new Error("JumpCode failed.");
/home/runner/workspace/src/mesh/validateBluetoothMeshSuperEngine.ts:    throw new Error("Route decisions not recorded.");
/home/runner/workspace/src/mesh/validateBluetoothMeshSuperEngine.ts:    throw new Error("√2 Bluetooth balance failed.");
/home/runner/workspace/src/mesh/validateBluetoothMeshSuperEngine.ts:    throw new Error("Bluetooth peers not recorded.");
/home/runner/workspace/src/mesh/validateBluetoothMeshSuperEngine.ts:    throw new Error("Tikanga/cultural intelligence block test failed.");
/home/runner/workspace/src/maurimesh/api/intelligentApiDriver.ts.bak-api-base-fix-20260603-142044:    throw new Error(
/home/runner/workspace/src/maurimesh/api/intelligentApiDriver.ts.bak-api-base-fix-20260603-142044:      throw new Error(
/home/runner/workspace/src/maurimesh/api/intelligentApiDriver.ts.bak-api-base-fix-20260603-142044:      throw new Error(`MauriMesh API failed ${response.status}: ${text}`);
/home/runner/workspace/src/maurimesh/api/publicIntelligenceClient.ts.bak-public-mesh-api-20260603-145405:    throw new Error(`MauriMesh public intelligence API failed ${response.status}: ${text}`);
/home/runner/workspace/src/maurimesh/api/publicIntelligenceClient.ts:    throw new Error(`MauriMesh public intelligence API failed ${response.status}: ${text}`);
/home/runner/workspace/src/maurimesh/ble/rawPacketClient.ts:  throw new Error("Base64 encoder unavailable");
/home/runner/workspace/src/maurimesh/ble/rawPacketClient.ts:    throw new Error("MauriMeshBle.sendRawPacket is unavailable");
/home/runner/workspace/src/maurimesh/ble/rawPacketClient.ts:    throw new Error("MauriMeshBle.broadcastRawPacket is unavailable");
/home/runner/workspace/src/maurimesh/ble/rawPacketProofClient.ts:    throw new Error("MauriMeshBle.startRawPacketReceiver unavailable");
/home/runner/workspace/src/maurimesh/ble/rawPacketProofClient.ts:    throw new Error("MauriMeshBle.stopRawPacketReceiver unavailable");
/home/runner/workspace/src/maurimesh/ble/rawPacketProofClient.ts:    throw new Error("MauriMeshBle.getRawPacketReceiverStatus unavailable");
/home/runner/workspace/src/mauricore/builder/layerRegistry.ts:  if (!existing) throw new Error(`Layer not found: ${id}`);
## TypeScript check
## Expo Android export
[33m[1mWarning: [22mRoot-level [1m"expo"[22m object found. Ignoring extra keys in Expo config: "owner", "extra"
[90mLearn more: https://expo.fyi/root-expo-object[0m[0m
Starting Metro Bundler
warning: Bundler cache is empty, rebuilding (this may take a minute)
Android node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js ░░░░░░░░░░░░░░░░  0.0% (0/1)
Android node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js ▓▓▓░░░░░░░░░░░░░ 21.8% (103/291)
Android node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js ▓▓▓▓▓▓▓░░░░░░░░░ 48.0% (559/807)
Android node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js ▓▓▓▓▓▓▓▓▓▓▓▓▓░░░ 84.0% ( 930/1015)
Android node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░ 99.9% (1168/1168)
Android Bundled 15899ms node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js (1168 modules)
Android node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░ 99.9% (1168/1168)

› Assets (24):
node_modules/.pnpm/@react-navigation+elements@2.9.19_@react-navigation+native@7.2.5_react-native@0.81.5_@babel+c_o5xhxhhziuspmnzkys54devyi4/node_modules/@react-navigation/elements/lib/module/assets/back-icon-mask.png (653 B)
node_modules/.pnpm/@react-navigation+elements@2.9.19_@react-navigation+native@7.2.5_react-native@0.81.5_@babel+c_o5xhxhhziuspmnzkys54devyi4/node_modules/@react-navigation/elements/lib/module/assets/back-icon.png (4 variations | 152 B)
node_modules/.pnpm/@react-navigation+elements@2.9.19_@react-navigation+native@7.2.5_react-native@0.81.5_@babel+c_o5xhxhhziuspmnzkys54devyi4/node_modules/@react-navigation/elements/lib/module/assets/clear-icon.png (4 variations | 425 B)
node_modules/.pnpm/@react-navigation+elements@2.9.19_@react-navigation+native@7.2.5_react-native@0.81.5_@babel+c_o5xhxhhziuspmnzkys54devyi4/node_modules/@react-navigation/elements/lib/module/assets/close-icon.png (4 variations | 235 B)
node_modules/.pnpm/@react-navigation+elements@2.9.19_@react-navigation+native@7.2.5_react-native@0.81.5_@babel+c_o5xhxhhziuspmnzkys54devyi4/node_modules/@react-navigation/elements/lib/module/assets/search-icon.png (4 variations | 599 B)
node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/assets/arrow_down.png (9.46 kB)
node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/assets/error.png (469 B)
node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/assets/file.png (138 B)
node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/assets/forward.png (188 B)
node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/assets/pkg.png (364 B)
node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/assets/sitemap.png (465 B)
node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/assets/unmatched.png (4.75 kB)

› android bundles (1):
_expo/static/js/android/entry-ea1ba0cd32de6b2254ba690170f95aa8.hbc (3.2 MB)

› Files (1):
metadata.json (1.79 kB)

Exported: dist
