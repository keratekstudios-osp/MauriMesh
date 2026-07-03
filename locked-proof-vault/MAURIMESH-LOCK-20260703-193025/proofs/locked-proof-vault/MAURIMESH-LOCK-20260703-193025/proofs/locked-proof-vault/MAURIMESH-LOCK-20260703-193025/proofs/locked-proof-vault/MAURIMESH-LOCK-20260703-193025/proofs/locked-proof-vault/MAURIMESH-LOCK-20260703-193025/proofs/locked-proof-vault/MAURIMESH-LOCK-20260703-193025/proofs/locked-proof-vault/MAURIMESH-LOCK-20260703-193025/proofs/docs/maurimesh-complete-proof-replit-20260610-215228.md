# MauriMesh Complete Proof Replit Wiring Report

Generated: 20260610-215228

This report wires:
- /wifi-two-phone-detector
- /two-three-hop-proof-lab
- Wi-Fi 2-phone proof labels
- 2-hop hotspot proof labels
- 3-hop app-readiness proof labels
- route/build verification

app/dashboard.tsx:170:// MauriMesh route installed: /two-three-hop-proof-lab
app/two-three-hop-proof-lab.tsx:16:      setTimeout(() => push(proofLine("MauriMeshWifiProof", stage)), i * 80);
app/two-three-hop-proof-lab.tsx:22:    setTimeout(() => push("[MauriMeshRouteAutoTest] status=PASS route=/two-three-hop-proof-lab"), 2400);
app/wifi-two-phone-detector.tsx:12:  "PHONE_A_WIFI_GATEWAY_SELECTED",
app/wifi-two-phone-detector.tsx:36:  const [role, setRole] = useState<WifiPhoneRole>("PHONE_A_WIFI_GATEWAY");
app/wifi-two-phone-detector.tsx:40:    return role === "PHONE_A_WIFI_GATEWAY" ? phoneAStages : phoneBStages;
app/wifi-two-phone-detector.tsx:62:          ? "PHONE_A_WIFI_GATEWAY"
app/wifi-two-phone-detector.tsx:83:          MauriMeshWifiProof lines into logcat for physical proof capture.
app/wifi-two-phone-detector.tsx:99:        style={[styles.button, role === "PHONE_A_WIFI_GATEWAY" && styles.active]}
app/wifi-two-phone-detector.tsx:100:        onPress={() => setRole("PHONE_A_WIFI_GATEWAY")}
src/maurimesh/total-proof/totalProofEngine.ts:4:    "MauriMeshWifiProof",
src/maurimesh/total-proof/totalProofEngine.ts:5:    "PHONE_A_WIFI_GATEWAY_SELECTED",
src/maurimesh/wifi-two-phone/wifiTwoPhoneProof.ts:2:  | "PHONE_A_WIFI_GATEWAY"
src/maurimesh/wifi-two-phone/wifiTwoPhoneProof.ts:8:  | "PHONE_A_WIFI_GATEWAY_SELECTED"
src/maurimesh/wifi-two-phone/wifiTwoPhoneProof.ts:27:  path: "PHONE_B_WIFI_CLIENT -> PHONE_A_WIFI_GATEWAY -> INTERNET_OR_API",
src/maurimesh/wifi-two-phone/wifiTwoPhoneProof.ts:30:    "PHONE_A_WIFI_GATEWAY_SELECTED",
src/maurimesh/wifi-two-phone/wifiTwoPhoneProof.ts:50:    "[MauriMeshWifiProof]",
Starting Metro Bundler
Android node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js ░░░░░░░░░░░░░░░░  0.0% (0/1)
Android Bundled 2798ms node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js (1143 modules)

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
_expo/static/js/android/entry-ff216e7e356cde473be28cdf26d3837d.hbc (3.06 MB)

› Files (1):
metadata.json (1.79 kB)

Exported: .complete-proof-export-20260610-215228

## Next Required Build

Run:

```bash
npx eas-cli build --platform android --profile preview-apk --clear-cache --non-interactive
```

Then install the new APK on A06 and S10.

