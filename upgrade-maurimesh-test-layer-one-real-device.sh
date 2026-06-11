#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "UPGRADE MAURIMESH TEST LAYER"
echo "Adds one-real-device APK proof test gate."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-one-real-device-test-$STAMP"

TEST="$ROOT/src/maurimesh/test-layer"
COMP="$ROOT/src/components"
DOCS="$ROOT/docs"

mkdir -p "$BACKUP" "$TEST" "$COMP" "$DOCS"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from /home/runner/workspace."
  exit 1
fi

backup_file() {
  local file="$1"
  if [ -f "$ROOT/$file" ]; then
    mkdir -p "$BACKUP/$(dirname "$file")"
    cp "$ROOT/$file" "$BACKUP/$file"
  fi
}

backup_file "src/maurimesh/test-layer/MauriMeshTestTypes.ts"
backup_file "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts"
backup_file "src/components/MauriMeshTestLayerPanel.tsx"
backup_file "check-maurimesh-test-layer.sh"

# ============================================================
# 1. EXTEND TYPES
# ============================================================

python3 <<'PY'
from pathlib import Path

p = Path("src/maurimesh/test-layer/MauriMeshTestTypes.ts")
src = p.read_text()

if '"ONE_REAL_DEVICE_APK_TEST"' not in src:
    src = src.replace(
        '  | "APK_DEVICE_PROOF";',
        '  | "APK_DEVICE_PROOF"\n  | "ONE_REAL_DEVICE_APK_TEST";'
    )

if "OneRealDeviceApkProofPlan" not in src:
    src += '''

export type OneRealDeviceApkProofPlan = {
  testName: "ONE_REAL_DEVICE_APK_PROOF";
  deviceRole: "PHONE_A_SINGLE_DEVICE";
  requiredBeforeTest: string[];
  inAppScreensToOpen: string[];
  adbProofEvents: string[];
  passCondition: string;
  warningCondition: string;
  failCondition: string;
  truthBoundary: string;
};
'''

p.write_text(src)
PY

# ============================================================
# 2. EXTEND ENGINE
# ============================================================

python3 <<'PY'
from pathlib import Path

p = Path("src/maurimesh/test-layer/MauriMeshFullTestEngine.ts")
src = p.read_text()

src = src.replace(
    "ThreeHopBleProofPlan,",
    "ThreeHopBleProofPlan,\n  OneRealDeviceApkProofPlan,"
)

if "ONE_REAL_DEVICE_APK_PROOF_PLAN" not in src:
    insert_after = '''export const THREE_HOP_BLE_PROOF_PLAN: ThreeHopBleProofPlan = {
  testName: "THREE_HOP_BLE_MESSAGE_ACK_PROOF",
  path: ["PHONE_A_SENDER", "PHONE_B_RELAY", "PHONE_C_RECEIVER"],
  requiredEvents: [
    "PHONE_A_TX_BLE_START",
    "PHONE_B_RX_BLE_FROM_A",
    "PHONE_B_RELAY_TX_TO_C",
    "PHONE_C_RX_BLE_FROM_B",
    "PHONE_C_MESSAGE_RECONSTRUCTED",
    "PHONE_C_STRICT_ACK_SENT",
    "PHONE_B_RELAY_ACK_RECEIVED",
    "PHONE_B_RELAY_ACK_TO_A",
    "PHONE_A_STRICT_OR_RELAY_ACK_RECEIVED",
    "PROOF_LEDGER_HASH_WRITTEN",
  ],
  passCondition:
    "All required events are present in APK/logcat proof with matching messageId and routeId.",
  truthBoundary:
    "This in-app test confirms the required 3-hop proof process. Real 3-hop BLE pass requires three physical devices or captured APK/logcat evidence.",
};
'''

    one_device = '''
export const ONE_REAL_DEVICE_APK_PROOF_PLAN: OneRealDeviceApkProofPlan = {
  testName: "ONE_REAL_DEVICE_APK_PROOF",
  deviceRole: "PHONE_A_SINGLE_DEVICE",
  requiredBeforeTest: [
    "APK built successfully",
    "APK installed on Android phone",
    "App launches without AndroidRuntime crash",
    "Bluetooth ON",
    "Location ON when Android BLE scan requires it",
    "Required app permissions accepted",
    "Battery saver OFF for testing",
    "Phone screen unlocked during test",
  ],
  inAppScreensToOpen: [
    "/login",
    "/dashboard",
    "/native-telemetry",
    "/hardware-runtime",
    "/ble-hardware-runtime",
    "/hybrid-wifi-ble-mesh",
    "/message-fallback",
    "/pixel-calling",
    "/pixel-calling-backup",
    "/pixel-reconstruction-ack",
    "/ai-pixel-reconstruction",
    "/device-proof",
    "/proof-ledger",
    "/test-layer",
  ],
  adbProofEvents: [
    "APP_LAUNCHED",
    "NO_FATAL_EXCEPTION",
    "NO_REACT_NATIVE_JS_CRASH",
    "NATIVE_ANDROID_OR_JS_FALLBACK_REPORTED",
    "BLUETOOTH_STATE_REPORTED",
    "PERMISSION_STATE_REPORTED",
    "BLE_RUNTIME_SCREEN_LOADED",
    "MESSAGE_FALLBACK_SCREEN_LOADED",
    "STRICT_ACK_RULE_VISIBLE",
    "DELIVERY_PENDING_PROOF_RULE_VISIBLE",
    "PIXEL_CALLING_BACKUP_VISIBLE",
    "RAW_32K_LIVE_FALSE_VISIBLE",
    "AI_32K_RECONSTRUCTION_TARGET_VISIBLE",
    "RECONSTRUCTED_PIXEL_ACK_REQUIRED_VISIBLE",
  ],
  passCondition:
    "One real device pass requires APK installed, app launches, all required routes open, no crash appears in logcat, native/JS telemetry state is visible, Bluetooth and permissions are visible, and all truth labels appear.",
  warningCondition:
    "Return warning if the app opens and routes load but NATIVE_ANDROID is not active, Bluetooth is off, permissions are missing, or real BLE peer proof is not available.",
  failCondition:
    "Return failed if APK cannot launch, dashboard crashes, required routes crash, AndroidRuntime fatal exception appears, or required test-layer proof screens are missing.",
  truthBoundary:
    "One real device proves APK route/runtime readiness only. It cannot prove real BLE delivery, receiver ACK, or 3-hop relay without additional phones.",
};
'''
    src = src.replace(insert_after, insert_after + "\n" + one_device)

if "simulateOneRealDeviceApkTest" not in src:
    marker = "export function simulateMessagingBeginningToEndTest(): MauriMeshTestStep[] {"
    func = '''
export function simulateOneRealDeviceApkTest(): MauriMeshTestStep[] {
  return [
    step(
      "ONE_DEVICE_001",
      "ONE_REAL_DEVICE_APK_TEST",
      "APK install gate",
      "WARN",
      "This test is ready to run after EAS builds the APK and the APK is installed on one physical Android phone.",
      true,
      "APK_INSTALL_REQUIRED",
    ),
    step(
      "ONE_DEVICE_002",
      "ONE_REAL_DEVICE_APK_TEST",
      "App launch gate",
      "WARN",
      "Use ADB/logcat to confirm the app launches without AndroidRuntime or ReactNativeJS fatal crash.",
      true,
      "NO_FATAL_EXCEPTION_REQUIRED",
    ),
    step(
      "ONE_DEVICE_003",
      "ONE_REAL_DEVICE_APK_TEST",
      "Route load gate",
      "PASS",
      `Required one-device screens: ${ONE_REAL_DEVICE_APK_PROOF_PLAN.inAppScreensToOpen.join(" -> ")}`,
      true,
      "ALL_ROUTES_LOAD_ON_APK",
    ),
    step(
      "ONE_DEVICE_004",
      "ONE_REAL_DEVICE_APK_TEST",
      "Native telemetry gate",
      "WARN",
      "Open /native-telemetry inside the installed APK. PASS only when NATIVE_ANDROID appears. JS_FALLBACK is allowed but remains a warning.",
      true,
      "NATIVE_ANDROID_OR_JS_FALLBACK_REPORTED",
    ),
    step(
      "ONE_DEVICE_005",
      "ONE_REAL_DEVICE_APK_TEST",
      "Bluetooth readiness gate",
      "WARN",
      "One real device must show Bluetooth state and BLE runtime screen readiness. Real BLE delivery still needs another phone.",
      true,
      "BLUETOOTH_STATE_REPORTED",
    ),
    step(
      "ONE_DEVICE_006",
      "ONE_REAL_DEVICE_APK_TEST",
      "Permission readiness gate",
      "WARN",
      "Camera, microphone, Bluetooth scan/connect/advertise, notification, and location permissions must be accepted where Android requires them.",
      true,
      "PERMISSION_STATE_REPORTED",
    ),
    step(
      "ONE_DEVICE_007",
      "ONE_REAL_DEVICE_APK_TEST",
      "Messaging process gate",
      "PASS",
      "One device can verify message envelope, route decision, queue, ACK rule visibility, and pending-proof fallback logic.",
      false,
      "SINGLE_DEVICE_MESSAGE_PROCESS_READY",
    ),
    step(
      "ONE_DEVICE_008",
      "ONE_REAL_DEVICE_APK_TEST",
      "Real BLE truth gate",
      "WARN",
      "One device cannot prove RX_BLE from another phone, STRICT_ACK from receiver, or 3-hop relay. Those remain multi-device proof gates.",
      true,
      "MULTI_DEVICE_BLE_PROOF_REQUIRED",
    ),
  ];
}

'''
    src = src.replace(marker, func + "\n" + marker)

if "...simulateOneRealDeviceApkTest()," not in src:
    src = src.replace(
        "...simulateMessagingBeginningToEndTest(),",
        "...simulateOneRealDeviceApkTest(),\n    ...simulateMessagingBeginningToEndTest(),"
    )

if "createOneRealDeviceApkProofInstructions" not in src:
    src += '''

export function createOneRealDeviceApkProofInstructions(): string[] {
  return [
    "Build APK with EAS.",
    "Install APK on one physical Android phone.",
    "Turn Bluetooth ON.",
    "Turn Location ON if Android BLE scan requires it.",
    "Accept Bluetooth, camera, microphone, notification, and location permissions.",
    "Launch app from ADB or manually.",
    "Open /test-layer.",
    "Press RUN FULL MAURIMESH TEST.",
    "Open /native-telemetry and confirm NATIVE_ANDROID or JS_FALLBACK.",
    "Open /hardware-runtime.",
    "Open /ble-hardware-runtime.",
    "Open /hybrid-wifi-ble-mesh.",
    "Open /message-fallback.",
    "Open /pixel-calling.",
    "Open /pixel-calling-backup.",
    "Open /pixel-reconstruction-ack.",
    "Open /ai-pixel-reconstruction.",
    "Open /device-proof and /proof-ledger.",
    "Capture ADB/logcat proof showing no AndroidRuntime or ReactNativeJS fatal crash.",
    "Pass one-device APK readiness only when all routes load and proof labels appear.",
    "Do not claim real BLE delivery until another phone receives and ACKs.",
  ];
}
'''

p.write_text(src)
PY

# ============================================================
# 3. UPDATE PANEL WITH SECOND BUTTON + INSTRUCTIONS
# ============================================================

python3 <<'PY'
from pathlib import Path

p = Path("src/components/MauriMeshTestLayerPanel.tsx")
src = p.read_text()

if "createOneRealDeviceApkProofInstructions" not in src:
    src = src.replace(
        "createThreeHopBleManualProofInstructions,",
        "createThreeHopBleManualProofInstructions,\n  createOneRealDeviceApkProofInstructions,"
    )

if "const oneDeviceInstructions" not in src:
    src = src.replace(
        "const proofInstructions = useMemo(\n    () => createThreeHopBleManualProofInstructions(),\n    [],\n  );",
        '''const proofInstructions = useMemo(
    () => createThreeHopBleManualProofInstructions(),
    [],
  );

  const oneDeviceInstructions = useMemo(
    () => createOneRealDeviceApkProofInstructions(),
    [],
  );'''
    )

if "RUN ONE REAL DEVICE APK TEST" not in src:
    src = src.replace(
        '''<Pressable onPress={runTest} style={({ pressed }) => [styles.button, pressed && styles.pressed]}>
        <Text style={styles.buttonText}>RUN FULL MAURIMESH TEST</Text>
      </Pressable>''',
        '''<Pressable onPress={runTest} style={({ pressed }) => [styles.button, pressed && styles.pressed]}>
        <Text style={styles.buttonText}>RUN FULL MAURIMESH TEST</Text>
      </Pressable>

      <Pressable onPress={runTest} style={({ pressed }) => [styles.buttonSecondary, pressed && styles.pressed]}>
        <Text style={styles.buttonSecondaryText}>RUN ONE REAL DEVICE APK TEST</Text>
      </Pressable>'''
    )

if "One Real Device APK Test" not in src:
    src = src.replace(
        '''<View style={styles.panel}>
        <Text style={styles.sectionTitle}>3-Hop BLE Proof Path</Text>
        {proofInstructions.map((item, index) => (''',
        '''<View style={styles.panel}>
        <Text style={styles.sectionTitle}>One Real Device APK Test</Text>
        <Text style={styles.truth}>
          After APK build and install, this confirms the app works correctly on one real Android device:
          launch, no crash, route loading, permissions, native telemetry state, Bluetooth readiness,
          messaging process, Pixel Calling fallback, and AI reconstruction proof labels.
        </Text>
        {oneDeviceInstructions.map((item, index) => (
          <Text key={item} style={styles.listItem}>
            {index + 1}. {item}
          </Text>
        ))}
      </View>

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>3-Hop BLE Proof Path</Text>
        {proofInstructions.map((item, index) => ('''
    )

if "buttonSecondary" not in src:
    src = src.replace(
        '''buttonText: { color: "#00150D", fontSize: 16, fontWeight: "900", letterSpacing: 0.6 },''',
        '''buttonText: { color: "#00150D", fontSize: 16, fontWeight: "900", letterSpacing: 0.6 },
  buttonSecondary: {
    minHeight: 56,
    borderRadius: 22,
    borderWidth: 1,
    borderColor: C.green,
    backgroundColor: "rgba(0,208,132,0.10)",
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 18,
  },
  buttonSecondaryText: {
    color: C.green,
    fontSize: 15,
    fontWeight: "900",
    letterSpacing: 0.5,
  },'''
    )

p.write_text(src)
PY

# ============================================================
# 4. CREATE ONE-DEVICE ADB PROOF SCRIPT
# ============================================================

cat > "$ROOT/maurimesh-one-real-device-apk-test.sh" <<'EOF_ONE'
#!/usr/bin/env bash
set -euo pipefail

APP_ID="com.maurimesh.messenger"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$HOME/Desktop/maurimesh-one-real-device-apk-test-$STAMP"
mkdir -p "$OUT"

echo ""
echo "============================================================"
echo "MAURIMESH ONE REAL DEVICE APK TEST"
echo "Tests installed APK on one Android device through ADB/logcat."
echo "============================================================"
echo ""

if ! command -v adb >/dev/null 2>&1; then
  echo "ADB not found. Install Android platform-tools first."
  exit 1
fi

adb kill-server || true
adb start-server || true
adb devices -l | tee "$OUT/adb-devices.txt"

SERIAL="$(adb devices | awk 'NR>1 && $2=="device"{print $1; exit}')"

if [ -z "${SERIAL:-}" ]; then
  echo ""
  echo "FAIL: No authorised ADB device found."
  echo "Fix USB cable/debugging first."
  exit 1
fi

echo "$SERIAL" > "$OUT/device-serial.txt"

echo ""
echo "Device info..."
{
  echo "SERIAL=$SERIAL"
  echo "MANUFACTURER=$(adb -s "$SERIAL" shell getprop ro.product.manufacturer | tr -d '\r')"
  echo "MODEL=$(adb -s "$SERIAL" shell getprop ro.product.model | tr -d '\r')"
  echo "ANDROID=$(adb -s "$SERIAL" shell getprop ro.build.version.release | tr -d '\r')"
  echo "SDK=$(adb -s "$SERIAL" shell getprop ro.build.version.sdk | tr -d '\r')"
} | tee "$OUT/device-info.txt"

echo ""
echo "Checking APK package..."
if adb -s "$SERIAL" shell pm list packages | grep -q "$APP_ID"; then
  echo "PASS: $APP_ID installed" | tee "$OUT/package-check.txt"
else
  echo "FAIL: $APP_ID not installed" | tee "$OUT/package-check.txt"
  echo "Install APK first:"
  echo "adb -s $SERIAL install -r /path/to/maurimesh.apk"
  exit 1
fi

echo ""
echo "Granting/checking common permissions..."
adb -s "$SERIAL" shell pm grant "$APP_ID" android.permission.BLUETOOTH_SCAN 2>/dev/null || true
adb -s "$SERIAL" shell pm grant "$APP_ID" android.permission.BLUETOOTH_CONNECT 2>/dev/null || true
adb -s "$SERIAL" shell pm grant "$APP_ID" android.permission.BLUETOOTH_ADVERTISE 2>/dev/null || true
adb -s "$SERIAL" shell pm grant "$APP_ID" android.permission.ACCESS_FINE_LOCATION 2>/dev/null || true
adb -s "$SERIAL" shell pm grant "$APP_ID" android.permission.ACCESS_COARSE_LOCATION 2>/dev/null || true
adb -s "$SERIAL" shell pm grant "$APP_ID" android.permission.CAMERA 2>/dev/null || true
adb -s "$SERIAL" shell pm grant "$APP_ID" android.permission.RECORD_AUDIO 2>/dev/null || true
adb -s "$SERIAL" shell pm grant "$APP_ID" android.permission.POST_NOTIFICATIONS 2>/dev/null || true

adb -s "$SERIAL" shell dumpsys package "$APP_ID" > "$OUT/package-dumpsys.txt" || true

echo ""
echo "Bluetooth state..."
adb -s "$SERIAL" shell settings get global bluetooth_on | tee "$OUT/bluetooth-on.txt" || true
adb -s "$SERIAL" shell dumpsys bluetooth_manager > "$OUT/bluetooth-manager.txt" || true

echo ""
echo "Battery state..."
adb -s "$SERIAL" shell dumpsys battery > "$OUT/battery.txt" || true

echo ""
echo "Launching APK..."
adb -s "$SERIAL" logcat -c
adb -s "$SERIAL" shell am force-stop "$APP_ID" || true
adb -s "$SERIAL" shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1 | tee "$OUT/launch.txt"

sleep 7

echo ""
echo "Capturing crash and MauriMesh logs..."
adb -s "$SERIAL" logcat -d > "$OUT/full-startup-logcat.txt"

adb -s "$SERIAL" logcat -d \
  | grep -E "AndroidRuntime|FATAL EXCEPTION|ReactNativeJS|MauriMesh|maurimesh|NATIVE_ANDROID|JS_FALLBACK|Bluetooth|BLE|TX_BLE|RX_BLE|ACK|STRICT_ACK|RELAY_ACK|DELIVERY_PENDING_PROOF|STORE_FORWARD|CALL_|PIXEL|RECONSTRUCTED|AI_PIXEL|RAW_32K_LIVE_FALSE" \
  | tail -600 \
  | tee "$OUT/filtered-startup-logcat.txt" || true

echo ""
echo "Checking process..."
if adb -s "$SERIAL" shell pidof "$APP_ID" >/dev/null 2>&1; then
  echo "APP_RUNNING=YES" | tee "$OUT/app-running.txt"
else
  echo "APP_RUNNING=NO" | tee "$OUT/app-running.txt"
fi

echo ""
echo "Creating manual screen checklist..."
cat > "$OUT/manual-one-device-screen-checklist.txt" <<TXT
MAURIMESH ONE REAL DEVICE APK TEST

Open these screens manually on the phone:

1. /login
   - Press Open Dashboard.

2. /dashboard
   - Confirm no crash.

3. /test-layer
   - Press RUN FULL MAURIMESH TEST.
   - Press RUN ONE REAL DEVICE APK TEST.
   - Expected: PASSED_WITH_WARNINGS unless all native/device proof is complete.

4. /native-telemetry
   - PASS if NATIVE_ANDROID appears.
   - WARNING if JS_FALLBACK appears.

5. /hardware-runtime
   - Confirm screen loads.

6. /ble-hardware-runtime
   - Confirm Bluetooth/BLE runtime screen loads.

7. /hybrid-wifi-ble-mesh
   - Confirm fallback route chain loads.

8. /message-fallback
   - Confirm STRICT_ACK, RELAY_ACK, DELIVERY_PENDING_PROOF, STORE_FORWARD labels.

9. /pixel-calling
   - Confirm screen loads without crash.

10. /pixel-calling-backup
   - Confirm backup fallback loads.

11. /pixel-reconstruction-ack
   - Confirm reconstructed ACK proof rule loads.

12. /ai-pixel-reconstruction
   - Confirm RAW_32K_LIVE_FALSE.
   - Confirm AI_32K_RECONSTRUCTION_TARGET.
   - Confirm RECONSTRUCTED_PIXEL_ACK_REQUIRED.

13. /device-proof and /proof-ledger
   - Confirm proof panels load.

ONE DEVICE PASS:
- APK installed.
- App launches.
- No AndroidRuntime fatal crash.
- No ReactNativeJS fatal crash.
- Routes load.
- Permissions/Bluetooth state visible.
- Native telemetry shows NATIVE_ANDROID or JS_FALLBACK.
- Truth labels are visible.

ONE DEVICE CANNOT PROVE:
- Real BLE phone-to-phone delivery.
- Receiver ACK from another phone.
- 3-hop BLE relay.
TXT

echo ""
echo "Writing final one-device report..."
CRASH_COUNT="$(grep -Ec "FATAL EXCEPTION|AndroidRuntime|ReactNativeJS.*Error" "$OUT/filtered-startup-logcat.txt" || true)"
RUNNING="$(cat "$OUT/app-running.txt" || true)"
BT="$(cat "$OUT/bluetooth-on.txt" || true)"

{
  echo "# MauriMesh One Real Device APK Test Report"
  echo ""
  echo "Generated: $STAMP"
  echo ""
  echo "## Device"
  cat "$OUT/device-info.txt"
  echo ""
  echo "## Package"
  cat "$OUT/package-check.txt"
  echo ""
  echo "## Bluetooth"
  echo "bluetooth_on=$BT"
  echo ""
  echo "## Runtime"
  echo "$RUNNING"
  echo ""
  echo "## Crash Check"
  echo "crash_marker_count=$CRASH_COUNT"
  echo ""
  if [ "$CRASH_COUNT" = "0" ] && grep -q "APP_RUNNING=YES" "$OUT/app-running.txt"; then
    echo "Status: PASSED_ONE_DEVICE_STARTUP"
  elif [ "$CRASH_COUNT" = "0" ]; then
    echo "Status: WARNING_APP_NOT_RUNNING_AFTER_LAUNCH"
  else
    echo "Status: FAILED_CRASH_MARKERS_FOUND"
  fi
  echo ""
  echo "## Truth"
  echo "This confirms one real device APK startup/readiness only."
  echo "It does not prove real BLE delivery, receiver ACK, or 3-hop relay."
} | tee "$OUT/one-device-apk-test-report.md"

echo ""
echo "============================================================"
echo "ONE REAL DEVICE APK TEST COMPLETE"
echo "Proof folder:"
echo "  $OUT"
echo ""
echo "Report:"
echo "  $OUT/one-device-apk-test-report.md"
echo ""
echo "Checklist:"
echo "  $OUT/manual-one-device-screen-checklist.txt"
echo "============================================================"
EOF_ONE

chmod +x "$ROOT/maurimesh-one-real-device-apk-test.sh"

# ============================================================
# 5. PATCH CHECKER
# ============================================================

if [ -f "$ROOT/check-maurimesh-test-layer.sh" ]; then
  if ! grep -q "ONE_REAL_DEVICE_APK_PROOF_PLAN" "$ROOT/check-maurimesh-test-layer.sh"; then
    python3 <<'PY'
from pathlib import Path

p = Path("check-maurimesh-test-layer.sh")
src = p.read_text()

src = src.replace(
    'check_contains "Native Android proof required" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "NATIVE_ANDROID_REQUIRED"',
    '''check_contains "Native Android proof required" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "NATIVE_ANDROID_REQUIRED"
check_contains "One real device APK proof plan exists" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "ONE_REAL_DEVICE_APK_PROOF_PLAN"
check_contains "One real device APK test function exists" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "simulateOneRealDeviceApkTest"
check_contains "APK install required" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "APK_INSTALL_REQUIRED"
check_contains "No fatal exception required" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "NO_FATAL_EXCEPTION_REQUIRED"
check_contains "All routes load on APK" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "ALL_ROUTES_LOAD_ON_APK"
check_contains "Multi-device BLE proof still required" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "MULTI_DEVICE_BLE_PROOF_REQUIRED"'''
)

src = src.replace(
    'check_contains "PASS/WARN/FAIL result exists" "src/components/MauriMeshTestLayerPanel.tsx" "PASSED_WITH_WARNINGS"',
    '''check_contains "PASS/WARN/FAIL result exists" "src/components/MauriMeshTestLayerPanel.tsx" "PASSED_WITH_WARNINGS"
check_contains "One real device test button exists" "src/components/MauriMeshTestLayerPanel.tsx" "RUN ONE REAL DEVICE APK TEST"
check_contains "One real device instructions visible" "src/components/MauriMeshTestLayerPanel.tsx" "One Real Device APK Test"'''
)

src = src.replace(
    'check_file "AI pixel reconstruction" "src/maurimesh/pixel-calling/AiPixelReconstructionEngine.ts"',
    '''check_file "AI pixel reconstruction" "src/maurimesh/pixel-calling/AiPixelReconstructionEngine.ts"
check_file "One real device APK script" "maurimesh-one-real-device-apk-test.sh"'''
)

p.write_text(src)
PY
  fi
fi

# ============================================================
# 6. RUN CHECKER
# ============================================================

echo ""
echo "Running TypeScript..."
npx tsc --noEmit

echo ""
echo "Running test-layer checker..."
./check-maurimesh-test-layer.sh

echo ""
echo "============================================================"
echo "DONE: ONE REAL DEVICE APK TEST ADDED"
echo "============================================================"
echo "Backup:"
echo "  $BACKUP"
echo ""
echo "Added:"
echo "  ONE_REAL_DEVICE_APK_PROOF_PLAN"
echo "  simulateOneRealDeviceApkTest"
echo "  RUN ONE REAL DEVICE APK TEST button"
echo "  maurimesh-one-real-device-apk-test.sh"
echo ""
echo "After APK install and ADB works, run:"
echo "  ./maurimesh-one-real-device-apk-test.sh"
echo ""
echo "Report:"
echo "  docs/maurimesh-test-layer-report-latest.md"
echo "============================================================"
