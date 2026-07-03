import { GENERATED_APP_ROUTES } from "./GeneratedRouteRegistry";
import { FullMeshCheck, FullMeshReport } from "./FullMeshTestTypes";

function nowIso() {
  return new Date().toISOString();
}

function check(
  id: string,
  title: string,
  status: FullMeshCheck["status"],
  detail: string,
  proofRequired: string[] = [],
): FullMeshCheck {
  return {
    id,
    title,
    status,
    detail,
    proofRequired,
  };
}

function statusScore(status: FullMeshCheck["status"]) {
  switch (status) {
    case "PASS":
      return 1;
    case "WARN":
      return 0.7;
    case "APK_REQUIRED":
      return 0.55;
    case "NATIVE_REQUIRED":
      return 0.45;
    case "TWO_PHONE_REQUIRED":
      return 0.35;
    case "THREE_PHONE_REQUIRED":
      return 0.25;
    case "NOT_PROVEN":
      return 0.2;
    case "FAIL":
      return 0;
    default:
      return 0;
  }
}

export function runFullMeshTestReport(): FullMeshReport {
  const generatedAt = nowIso();

  const routeLines = GENERATED_APP_ROUTES.map((route) => {
    const required = route.required ? "REQUIRED" : "OPTIONAL";
    return `${route.status.padEnd(7)} | ${required.padEnd(8)} | ${route.route} | ${route.file}`;
  });

  const requiredRoutes = GENERATED_APP_ROUTES.filter((route) => route.required);
  const requiredMissing = requiredRoutes.filter((route) => route.status === "MISSING");

  const checks: FullMeshCheck[] = [
    check(
      "app_bundle_loaded",
      "APK JavaScript bundle loaded",
      "PASS",
      "This screen is running inside the app bundle, so the React Native JS bundle loaded far enough to render the report UI.",
      ["Screenshot of this screen inside installed APK"],
    ),
    check(
      "route_inventory_generated",
      "Route inventory generated",
      requiredMissing.length === 0 ? "PASS" : "WARN",
      `Generated route inventory contains ${GENERATED_APP_ROUTES.length} routes. Required missing routes: ${requiredMissing.length}.`,
      ["GeneratedRouteRegistry.ts", "Visible route list in this report"],
    ),
    check(
      "dashboard_present",
      "Dashboard route present",
      hasRoute("/dashboard") ? "PASS" : "FAIL",
      "Dashboard is required as the main operator hub.",
      ["Open /dashboard inside APK"],
    ),
    check(
      "test_layer_present",
      "Test Layer route present",
      hasRoute("/test-layer") ? "PASS" : "FAIL",
      "Test Layer is required for in-app proof checks.",
      ["Open /test-layer inside APK"],
    ),
    check(
      "full_mesh_report_present",
      "Full Mesh Test Report route present",
      hasRoute("/full-mesh-test-report") ? "PASS" : "FAIL",
      "This screen provides the copyable full app activity/proof report.",
      ["Open /full-mesh-test-report inside APK"],
    ),
    check(
      "maori_protocol_layer",
      "Māori protocol fallback visible",
      hasRoute("/maori-protocols") ? "PASS" : "WARN",
      "Tikanga, Tapu, Noa, Mana, Mauri, Whakapapa Ara, Kaitiakitanga, Rangatiratanga, Whanaungatanga, Arotake, and APK-proof labels are expected.",
      ["Open /maori-protocols", "Confirm te reo/Tikanga labels visible"],
    ),
    check(
      "jumpcode_layer",
      "JumpCode proof route visible",
      hasRoute("/jumpcode-proof") ? "PASS" : "WARN",
      "JumpCode UI can be loaded from the APK. Real routing proof still requires packet/ACK evidence.",
      ["Open /jumpcode-proof", "Copy generated JumpCode", "Match routeId in logs later"],
    ),
    check(
      "evolution_layer",
      "Evolution Layer route visible",
      hasRoute("/evolution-layer") ? "PASS" : "WARN",
      "Evolution layer must observe, score, and recommend only. It must not silently rewrite code or fake proof.",
      ["Open /evolution-layer", "Confirm canAutoApply=false", "Confirm operator approval required"],
    ),
    check(
      "native_telemetry",
      "Native telemetry proof",
      "NATIVE_REQUIRED",
      "The APK must prove native telemetry through the installed Android app. JS fallback is allowed but remains a warning.",
      ["Open /native-telemetry", "Look for NATIVE_ANDROID or JS_FALLBACK", "Capture logcat"],
    ),
    check(
      "ble_runtime_screen",
      "BLE runtime screen",
      hasRoute("/mauricore-ble-runtime") ? "APK_REQUIRED" : "FAIL",
      "BLE runtime UI is present, but real BLE scan/advertise/connect/send/receive/ACK must be proven on physical devices.",
      ["Open /mauricore-ble-runtime", "Bluetooth ON", "Nearby Devices permission accepted"],
    ),
    check(
      "device_proof_screen",
      "Device Proof screen",
      hasRoute("/device-proof") ? "APK_REQUIRED" : "FAIL",
      "Device proof screen must show APK/device readiness without false live-BLE claims.",
      ["Open /device-proof", "Screenshot permissions and device checklist"],
    ),
    check(
      "proof_ledger_screen",
      "Proof Ledger screen",
      hasRoute("/proof-ledger") ? "PASS" : "WARN",
      "Proof Ledger route exists. Server persistence requires EXPO_PUBLIC_MESH_API_URL, otherwise local/UI proof only.",
      ["Open /proof-ledger", "Confirm proof entries or API fallback label"],
    ),
    check(
      "message_ack_fallback",
      "Message fallback / ACK rules",
      hasRoute("/message-fallback") ? "PASS" : "WARN",
      "Message fallback protects delivery honesty: pending proof remains pending until strict ACK or relay ACK evidence exists.",
      ["Open /message-fallback", "Confirm pending-proof labels"],
    ),
    check(
      "route_lab",
      "Route Lab decision screen",
      hasRoute("/route-lab") ? "PASS" : "WARN",
      "Route Lab should show BLE, relay, store-forward, Wi-Fi, gateway, trust, TTL, and path-score logic.",
      ["Open /route-lab", "Confirm selected route and fallback labels"],
    ),
    check(
      "hybrid_wifi_ble",
      "Hybrid Wi-Fi/BLE mesh layer",
      hasRoute("/hybrid-wifi-ble-mesh") ? "PASS" : "WARN",
      "Hybrid routing can select BLE, relay, store-forward, Wi-Fi local, Wi-Fi Direct-ready, and internet gateway fallback. Real radio proof still requires devices.",
      ["Open /hybrid-wifi-ble-mesh", "Confirm fallback ordering"],
    ),
    check(
      "living_mesh",
      "Living Mesh screen",
      hasRoute("/living-mesh") ? "PASS" : "WARN",
      "Living Mesh can show simulation/API/native status. It must clearly label simulation versus device proof.",
      ["Open /living-mesh", "Confirm no false live claim"],
    ),
    check(
      "self_healing",
      "Self-healing / homeostasis",
      hasRoute("/self-healing") ? "PASS" : "WARN",
      "Self-healing should recommend safe runtime changes and repairs. It must not claim physical repair or bypass Android protections.",
      ["Open /self-healing", "Confirm safe-mode and repair queue labels"],
    ),
    check(
      "pixel_calling",
      "Pixel Calling proof gate",
      hasRoute("/pixel-calling") ? "APK_REQUIRED" : "WARN",
      "Pixel Calling UI can be present, but real audio calling proof requires two phones, receiver acceptance, audio permission, and log evidence.",
      ["Open /pixel-calling", "Accept microphone permission", "Two-phone audio proof"],
    ),
    check(
      "ai_pixel_reconstruction",
      "AI Pixel Reconstruction proof gate",
      hasRoute("/ai-pixel-reconstruction") ? "APK_REQUIRED" : "WARN",
      "AI pixel reconstruction must not claim raw 32K live. It can claim reconstruction only with source frame hash, quality score, reconstructed frame hash, and ACK.",
      ["Open /ai-pixel-reconstruction", "Confirm RAW_32K_LIVE_FALSE", "Capture ACK proof later"],
    ),
    check(
      "one_device_apk",
      "One real device APK test",
      "APK_REQUIRED",
      "One phone can prove APK install, launch, route loading, Bluetooth state, permission visibility, and no fatal crash. It cannot prove phone-to-phone delivery.",
      ["Install APK", "Open required routes", "ADB logcat no AndroidRuntime/FATAL/ReactNativeJS fatal"],
    ),
    check(
      "two_phone_ble_ack",
      "Two-phone BLE ACK proof",
      "TWO_PHONE_REQUIRED",
      "Real BLE delivery requires Phone A sender and Phone B receiver with matching packetId, routeId, TX/RX, and ACK evidence.",
      [
        "PHONE_A_TX_BLE_START",
        "PHONE_B_RX_BLE_FROM_A",
        "PHONE_B_ACK_SENT",
        "PHONE_A_ACK_RECEIVED",
        "matching packetId",
        "matching routeId",
      ],
    ),
    check(
      "three_hop_ble_relay",
      "Three-hop BLE relay proof",
      "THREE_PHONE_REQUIRED",
      "Three-hop proof requires Phone A sender, Phone B relay, Phone C receiver, forwarded packet proof, and strict ACK path.",
      [
        "PHONE_A_TX_BLE_START",
        "PHONE_B_RX_BLE_FROM_A",
        "PHONE_B_RELAY_TX_TO_C",
        "PHONE_C_RX_BLE_FROM_B",
        "PHONE_C_STRICT_ACK_SENT",
        "PHONE_A_STRICT_OR_RELAY_ACK_RECEIVED",
      ],
    ),
    check(
      "rust_apk_bridge",
      "Rust APK bridge proof",
      "NOT_PROVEN",
      "Rust source is not enough. APK proof requires Android .so, Gradle wiring, JNI/UniFFI bridge, loadLibrary, and runtime call evidence.",
      ["Android .so exists", "System.loadLibrary exists", "Runtime bridge screen calls Rust safely"],
    ),
    check(
      "no_false_claims",
      "No false proof claims",
      "PASS",
      "The report keeps unproven BLE, ACK, relay, native telemetry, Pixel Calling, and Rust as APK/device proof gates.",
      ["Truth labels visible", "Unproven items remain NOT_PROVEN/APK_REQUIRED"],
    ),
  ];

  const weighted = checks.reduce((sum, item) => sum + statusScore(item.status), 0);
  const score = Math.round((weighted / checks.length) * 100);

  const passCount = checks.filter((item) => item.status === "PASS").length;
  const warnCount = checks.filter((item) => item.status === "WARN").length;
  const failCount = checks.filter((item) => item.status === "FAIL").length;
  const apkRequiredCount = checks.filter((item) => item.status === "APK_REQUIRED" || item.status === "NATIVE_REQUIRED").length;
  const deviceProofRequiredCount = checks.filter((item) =>
    item.status === "TWO_PHONE_REQUIRED" ||
    item.status === "THREE_PHONE_REQUIRED" ||
    item.status === "NOT_PROVEN",
  ).length;

  const finalTruth =
    "This is an in-APK full mesh test report. It proves the APK can render the report and validates route/proof readiness from bundled app data. It does not by itself prove real BLE TX/RX, receiver ACK, relay delivery, native telemetry, Rust JNI, or Pixel Calling audio. Those require physical devices and logcat evidence.";

  const copyBlock = buildCopyBlock({
    generatedAt,
    score,
    passCount,
    warnCount,
    failCount,
    apkRequiredCount,
    deviceProofRequiredCount,
    checks,
    routeLines,
    finalTruth,
  });

  return {
    id: "MAURIMESH_FULL_MESH_TEST_REPORT",
    generatedAt,
    appMode: "APK_IN_APP_REPORT",
    score,
    passCount,
    warnCount,
    failCount,
    apkRequiredCount,
    deviceProofRequiredCount,
    checks,
    routeInventory: {
      total: GENERATED_APP_ROUTES.length,
      present: GENERATED_APP_ROUTES.filter((route) => route.status === "PRESENT").length,
      missing: GENERATED_APP_ROUTES.filter((route) => route.status === "MISSING").length,
      requiredPresent: requiredRoutes.filter((route) => route.status === "PRESENT").length,
      requiredMissing: requiredMissing.length,
      lines: routeLines,
    },
    finalTruth,
    copyBlock,
  };
}

function hasRoute(route: string) {
  return GENERATED_APP_ROUTES.some((item) => item.route === route && item.status === "PRESENT");
}

function buildCopyBlock(input: {
  generatedAt: string;
  score: number;
  passCount: number;
  warnCount: number;
  failCount: number;
  apkRequiredCount: number;
  deviceProofRequiredCount: number;
  checks: FullMeshCheck[];
  routeLines: string[];
  finalTruth: string;
}) {
  const lines: string[] = [];

  lines.push("============================================================");
  lines.push("MAURIMESH FULL MESH TEST REPORT");
  lines.push("============================================================");
  lines.push(`Generated: ${input.generatedAt}`);
  lines.push("Mode: APK_IN_APP_REPORT");
  lines.push(`Score: ${input.score}%`);
  lines.push(`PASS: ${input.passCount}`);
  lines.push(`WARN: ${input.warnCount}`);
  lines.push(`FAIL: ${input.failCount}`);
  lines.push(`APK/NATIVE REQUIRED: ${input.apkRequiredCount}`);
  lines.push(`DEVICE PROOF REQUIRED: ${input.deviceProofRequiredCount}`);
  lines.push("");

  lines.push("------------------------------------------------------------");
  lines.push("CHECKS");
  lines.push("------------------------------------------------------------");

  input.checks.forEach((item, index) => {
    lines.push(`${index + 1}. [${item.status}] ${item.title}`);
    lines.push(`   ID: ${item.id}`);
    lines.push(`   Detail: ${item.detail}`);
    if (item.proofRequired.length > 0) {
      lines.push("   Proof required:");
      item.proofRequired.forEach((proof) => {
        lines.push(`   - ${proof}`);
      });
    }
    lines.push("");
  });

  lines.push("------------------------------------------------------------");
  lines.push("ROUTE INVENTORY");
  lines.push("------------------------------------------------------------");
  input.routeLines.forEach((line) => lines.push(line));

  lines.push("");
  lines.push("------------------------------------------------------------");
  lines.push("REAL DEVICE PROOF STILL REQUIRED");
  lines.push("------------------------------------------------------------");
  lines.push("- Installed APK no-crash logcat");
  lines.push("- Native telemetry state");
  lines.push("- Bluetooth permission/state proof");
  lines.push("- Phone A TX_BLE_START");
  lines.push("- Phone B RX_BLE_FROM_A");
  lines.push("- Phone B ACK_SENT");
  lines.push("- Phone A ACK_RECEIVED");
  lines.push("- Matching packetId");
  lines.push("- Matching routeId");
  lines.push("- Proof ledger hash");
  lines.push("- Three-hop relay if claiming 3-hop mesh");
  lines.push("- Pixel Calling real audio proof if claiming live call");
  lines.push("- Rust .so/JNI/loadLibrary proof if claiming Rust inside APK");

  lines.push("");
  lines.push("------------------------------------------------------------");
  lines.push("FINAL TRUTH");
  lines.push("------------------------------------------------------------");
  lines.push(input.finalTruth);
  lines.push("============================================================");

  return lines.join("\n");
}
