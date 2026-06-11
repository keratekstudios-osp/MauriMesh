# MauriMesh Build + Rust + JS Diagnostic

Generated: 20260610-112731

## 1. Project

- [x] package.json found

## 2. Rust File Presence

- [x] Rust files found
  - rust/maurimesh-core/src/types.rs
  - rust/maurimesh-core/src/hash.rs
  - rust/maurimesh-core/src/packet.rs
  - rust/maurimesh-core/src/route.rs
  - rust/maurimesh-core/src/ack.rs
  - rust/maurimesh-core/src/queue.rs
  - rust/maurimesh-core/src/proof.rs
  - rust/maurimesh-core/src/simulation.rs
  - rust/maurimesh-core/src/truth.rs
  - rust/maurimesh-core/src/ffi.rs
  - rust/maurimesh-core/src/lib.rs
  - rust/maurimesh-core/src/main.rs
  - rust/maurimesh-core/Cargo.toml
  - rust/mauricore/src/lib.rs
  - rust/mauricore/src/decision.rs
  - rust/mauricore/src/routing.rs
  - rust/mauricore/src/health.rs
  - rust/mauricore/src/proof.rs
  - rust/mauricore/Cargo.toml

## 3. Cargo Check

- [ ] cargo not found in Replit environment

## 4. Android Rust Integration Proof

- [ ] No MauriMesh Rust System.loadLibrary reference found
- [ ] No native .so files found in android/app/src/main/jniLibs
android/app/build.gradle:125:        jniLibs {
package.json:26:    "mauricore:rust:check": "cd rust/mauricore && cargo check"
- [x] Rust/JNI references exist in android/package config

## 5. TypeScript Check

- [x] TypeScript passed

## 6. Expo Export / JS Bundle Check

This reproduces the EAS Bundle JavaScript phase locally.
[33m[1mWarning: [22mRoot-level [1m"expo"[22m object found. Ignoring extra keys in Expo config: "owner", "extra"
[90mLearn more: https://expo.fyi/root-expo-object[0m[0m
Starting Metro Bundler
Android node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js ░░░░░░░░░░░░░░░░  0.0% (0/1)
Android node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js ▓▓▓░░░░░░░░░░░░░ 21.8% (16/56)
Android node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js ▓▓▓▓▓▓▓░░░░░░░░░ 44.9% (511/763)
Android node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░ 97.2% ( 996/1010)
Android Bundling failed 11219ms node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js (1119 modules)
SyntaxError: SyntaxError: /home/runner/workspace/src/maurimesh/test-layer/MauriMeshFullTestEngine.ts: Identifier 'OneRealDeviceApkProofPlan' has already been declared. (6:2)

[0m [90m 4 |[39m   [33mThreeHopBleProofPlan[39m[33m,[39m
 [90m 5 |[39m   [33mOneRealDeviceApkProofPlan[39m[33m,[39m
[31m[1m>[22m[39m[90m 6 |[39m   [33mOneRealDeviceApkProofPlan[39m[33m,[39m
 [90m   |[39m   [31m[1m^[22m[39m
 [90m 7 |[39m } [36mfrom[39m [32m"./MauriMeshTestTypes"[39m[33m;[39m
 [90m 8 |[39m
 [90m 9 |[39m [36mexport[39m [36mconst[39m [33mREQUIRED_ROUTES[39m [33m=[39m [[0m
- [ ] Expo Android JS bundle export failed

### Last 120 lines from export failure

[33m[1mWarning: [22mRoot-level [1m"expo"[22m object found. Ignoring extra keys in Expo config: "owner", "extra"
[90mLearn more: https://expo.fyi/root-expo-object[0m[0m
Starting Metro Bundler
Android node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js ░░░░░░░░░░░░░░░░  0.0% (0/1)
Android Bundling failed 1315ms node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js (1119 modules)
SyntaxError: SyntaxError: /home/runner/workspace/src/maurimesh/test-layer/MauriMeshFullTestEngine.ts: Identifier 'OneRealDeviceApkProofPlan' has already been declared. (6:2)

[0m [90m 4 |[39m   [33mThreeHopBleProofPlan[39m[33m,[39m
 [90m 5 |[39m   [33mOneRealDeviceApkProofPlan[39m[33m,[39m
[31m[1m>[22m[39m[90m 6 |[39m   [33mOneRealDeviceApkProofPlan[39m[33m,[39m
 [90m   |[39m   [31m[1m^[22m[39m
 [90m 7 |[39m } [36mfrom[39m [32m"./MauriMeshTestTypes"[39m[33m;[39m
 [90m 8 |[39m
 [90m 9 |[39m [36mexport[39m [36mconst[39m [33mREQUIRED_ROUTES[39m [33m=[39m [[0m

## 7. Metro Bundle Check

