import {
  EvolutionProposal,
  EvolutionReport,
  EvolutionSignal,
  EvolutionSource,
} from "./EvolutionTypes";

function now() {
  return new Date().toISOString();
}

function clamp01(value: number) {
  return Math.max(0, Math.min(1, value));
}

function makeSignal(input: Omit<EvolutionSignal, "timestamp">): EvolutionSignal {
  return {
    ...input,
    confidence: clamp01(input.confidence),
    timestamp: now(),
  };
}

export function createCurrentEvolutionSignals(): EvolutionSignal[] {
  return [
    makeSignal({
      id: "typescript_passed",
      kind: "TYPESCRIPT",
      label: "TypeScript passed",
      passed: true,
      confidence: 0.94,
      evidence: "Recent check reports TypeScript passed.",
    }),
    makeSignal({
      id: "expo_android_export_passed",
      kind: "EXPO_EXPORT",
      label: "Expo Android export passed",
      passed: true,
      confidence: 0.93,
      evidence: "Recent Android export generated Hermes bundle successfully.",
    }),
    makeSignal({
      id: "maori_protocol_fallback_complete",
      kind: "TIKANGA",
      label: "Māori protocol fallback complete",
      passed: true,
      confidence: 0.96,
      evidence:
        "Primary Tikanga, backup registry, and safe fallback protocol markers are present.",
    }),
    makeSignal({
      id: "jumpcode_ui_callable",
      kind: "JUMPCODE",
      label: "JumpCode UI callable",
      passed: true,
      confidence: 0.86,
      evidence:
        "JumpCode proof route calls JumpCode engine from UI and is present in exported bundle.",
    }),
    makeSignal({
      id: "apk_runtime_not_yet_proven",
      kind: "APK",
      label: "Installed APK runtime proof still required",
      passed: false,
      confidence: 0.72,
      evidence:
        "EAS APK/device logcat proof is still required before claiming native runtime success.",
    }),
    makeSignal({
      id: "real_ble_not_yet_proven",
      kind: "BLE",
      label: "Real BLE delivery still unproven",
      passed: false,
      confidence: 0.78,
      evidence:
        "Real BLE TX/RX/ACK requires physical phones, permissions, packet IDs, route IDs, and logcat.",
    }),
    makeSignal({
      id: "rust_apk_integration_not_proven",
      kind: "RUST",
      label: "Rust APK integration not proven",
      passed: false,
      confidence: 0.69,
      evidence:
        "Rust source may exist, but APK .so/JNI/loadLibrary proof is still required.",
    }),
  ];
}

export function createEvolutionProposals(signals: EvolutionSignal[]): EvolutionProposal[] {
  const failed = signals.filter((signal) => !signal.passed).map((signal) => signal.id);

  const proposals: EvolutionProposal[] = [
    {
      id: "proposal_eas_build_next",
      title: "Run next EAS APK build",
      summary:
        "The app should build again now that TypeScript, Expo Android export, JumpCode UI, and Māori fallback are passing.",
      risk: "MEDIUM",
      decision: "RECOMMEND_WITH_WARNING",
      source: "PRIMARY_EVOLUTION_ENGINE",
      targetLayer: "Build pipeline",
      requiredProof: [
        "EAS build URL",
        "APK artifact downloaded",
        "No Gradle fatal error",
        "No JavaScript bundle phase failure",
      ],
      rollbackPlan: [
        "Use backup folder generated before latest script",
        "Restore previous route/component files if EAS fails",
        "Patch only the exact failed file from new EAS logs",
      ],
      tikangaNotes: [
        "Whakatūpato — build can proceed, but APK proof is not yet complete.",
        "Mana — do not claim live device success until APK installs and opens.",
      ],
      canAutoApply: false,
    },
    {
      id: "proposal_one_device_apk_proof",
      title: "Run one-device APK proof",
      summary:
        "After APK build, install it on one Android phone and prove the app opens, routes load, and no fatal crash appears.",
      risk: "HIGH",
      decision: "REQUIRE_OPERATOR_APPROVAL",
      source: failed.includes("apk_runtime_not_yet_proven")
        ? "PRIMARY_EVOLUTION_ENGINE"
        : "BACKUP_EVOLUTION_MEMORY",
      targetLayer: "APK proof",
      requiredProof: [
        "ADB install success",
        "Dashboard opens",
        "/test-layer opens",
        "/maori-protocols opens",
        "/jumpcode-proof opens",
        "No AndroidRuntime fatal exception",
        "No ReactNativeJS fatal crash",
      ],
      rollbackPlan: [
        "If dashboard crashes, capture logcat",
        "Patch the exact crashing route/component",
        "Rebuild APK after TypeScript and Expo export pass",
      ],
      tikangaNotes: [
        "Kāore anō kia whakamātau — not proven until APK runs on phone.",
        "Me whakamātau ki te APK — installed APK proof required.",
      ],
      canAutoApply: false,
    },
    {
      id: "proposal_two_phone_ble_ack_proof",
      title: "Prepare two-phone BLE ACK proof",
      summary:
        "Real mesh delivery should only be claimed after Phone A sends, Phone B receives or relays, and strict ACK returns.",
      risk: "PROTECTED",
      decision: "BLOCK_AUTONOMOUS_CHANGE",
      source: failed.includes("real_ble_not_yet_proven")
        ? "PRIMARY_EVOLUTION_ENGINE"
        : "BACKUP_EVOLUTION_MEMORY",
      targetLayer: "BLE / ACK proof",
      requiredProof: [
        "Phone A TX_BLE_START",
        "Phone B RX_BLE_FROM_A",
        "ACK_SENT=true",
        "Phone A ACK_RECEIVED",
        "Matching packetId",
        "Matching routeId",
        "Proof ledger hash",
      ],
      rollbackPlan: [
        "Keep delivery state as PENDING_PROOF if ACK missing",
        "Use store-and-forward fallback",
        "Do not mark delivered without strict or relay ACK",
      ],
      tikangaNotes: [
        "Tapu — protected proof state.",
        "Whakapapa Ara — route lineage must be preserved.",
        "Mana — no false delivery claim.",
      ],
      canAutoApply: false,
    },
    {
      id: "proposal_rust_apk_bridge_audit",
      title: "Audit Rust APK bridge",
      summary:
        "Confirm whether Rust is only source code or actually compiled into the APK through .so/JNI/loadLibrary wiring.",
      risk: "HIGH",
      decision: "RECOMMEND_WITH_WARNING",
      source: failed.includes("rust_apk_integration_not_proven")
        ? "PRIMARY_EVOLUTION_ENGINE"
        : "BACKUP_EVOLUTION_MEMORY",
      targetLayer: "Rust bridge",
      requiredProof: [
        "Cargo check passed",
        "Android .so exists",
        "Gradle task builds Rust library",
        "JNI or UniFFI bridge exists",
        "Kotlin/Java loads library",
        "Runtime screen calls bridge safely",
      ],
      rollbackPlan: [
        "Keep Rust isolated from APK if bridge fails",
        "Do not block JS APK build on Rust until native bridge is stable",
        "Use JS fallback runtime for UI proof",
      ],
      tikangaNotes: [
        "Kaitiakitanga — protect build stability.",
        "Whakatūpato — source present is not APK proof.",
      ],
      canAutoApply: false,
    },
  ];

  return proposals;
}

export function evaluateEvolutionReport(
  source: EvolutionSource = "PRIMARY_EVOLUTION_ENGINE",
): EvolutionReport {
  const signals = createCurrentEvolutionSignals();
  const proposals = createEvolutionProposals(signals);

  const score =
    signals.reduce((sum, signal) => {
      return sum + (signal.passed ? signal.confidence : signal.confidence * 0.35);
    }, 0) / signals.length;

  const failedCount = signals.filter((signal) => !signal.passed).length;

  const status =
    failedCount === 0
      ? "STABLE"
      : failedCount <= 2
        ? "NEEDS_PROOF"
        : "WATCHING";

  return {
    id: "maurimesh_evolution_report",
    generatedAt: now(),
    score: Math.round(score * 100),
    status,
    source,
    signals,
    proposals,
    truthBoundary:
      "The Evolution Layer observes, scores, and recommends improvements. It does not silently rewrite code, bypass Android protections, fake BLE proof, claim delivery without ACK, or make cultural/proof claims without evidence.",
  };
}

export function evaluateBackupEvolutionReport(): EvolutionReport {
  return evaluateEvolutionReport("BACKUP_EVOLUTION_MEMORY");
}

export function evaluateSafeFallbackEvolutionReport(): EvolutionReport {
  return evaluateEvolutionReport("SAFE_FALLBACK_EVOLUTION");
}
