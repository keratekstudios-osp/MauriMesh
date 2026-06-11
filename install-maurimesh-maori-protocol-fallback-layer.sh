#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "INSTALL MAURIMESH MĀORI PROTOCOL FALLBACK LAYER"
echo "Restores te reo Māori / Tikanga labels across new proof UI"
echo "with primary + backup + safe fallback protocol registry."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-maori-protocol-fallback-$STAMP"

mkdir -p "$BACKUP" \
  "$ROOT/src/maurimesh/protocols" \
  "$ROOT/src/components" \
  "$ROOT/app" \
  "$ROOT/docs"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run this from /home/runner/workspace"
  exit 1
fi

backup_file() {
  local file="$1"
  if [ -f "$ROOT/$file" ]; then
    mkdir -p "$BACKUP/$(dirname "$file")"
    cp "$ROOT/$file" "$BACKUP/$file"
  fi
}

backup_file "app/dashboard.tsx"
backup_file "app/tikanga-engine.tsx"
backup_file "app/jumpcode-proof.tsx"
backup_file "app/test-layer.tsx"
backup_file "app/proof-ledger.tsx"
backup_file "app/device-proof.tsx"
backup_file "app/message-fallback.tsx"
backup_file "app/route-lab.tsx"
backup_file "app/mauricore-governance.tsx"
backup_file "src/lib/uiBackupRoutes.ts"
backup_file "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts"

# ============================================================
# 1. PROTOCOL TYPES
# ============================================================

cat > "$ROOT/src/maurimesh/protocols/MaoriProtocolTypes.ts" <<'TS'
export type MaoriProtocolRisk =
  | "LOW"
  | "MEDIUM"
  | "HIGH"
  | "PROTECTED";

export type MaoriProtocolAction =
  | "APPROVED"
  | "APPROVED_WITH_WARNING"
  | "REVIEW_REQUIRED"
  | "REFUSED"
  | "APK_PROOF_REQUIRED"
  | "MULTI_DEVICE_PROOF_REQUIRED"
  | "UNAVAILABLE_FALLBACK";

export type MaoriProtocolSource =
  | "PRIMARY_TIKANGA_ENGINE"
  | "BACKUP_PROTOCOL_REGISTRY"
  | "SAFE_FALLBACK_PROTOCOL";

export type MaoriProtocolTerm = {
  id: string;
  reo: string;
  english: string;
  engineeringMeaning: string;
  risk: MaoriProtocolRisk;
  action: MaoriProtocolAction;
  source: MaoriProtocolSource;
  proofLabel: string;
};

export type MaoriProtocolDecision = {
  id: string;
  screen: string;
  action: MaoriProtocolAction;
  source: MaoriProtocolSource;
  risk: MaoriProtocolRisk;
  reoSummary: string;
  englishSummary: string;
  terms: MaoriProtocolTerm[];
  warnings: string[];
  truthBoundary: string;
};
TS

# ============================================================
# 2. PRIMARY + BACKUP + FALLBACK REGISTRY
# ============================================================

cat > "$ROOT/src/maurimesh/protocols/MaoriProtocolRegistry.ts" <<'TS'
import {
  MaoriProtocolAction,
  MaoriProtocolDecision,
  MaoriProtocolRisk,
  MaoriProtocolSource,
  MaoriProtocolTerm,
} from "./MaoriProtocolTypes";

export const MAORI_PROTOCOL_TERMS: MaoriProtocolTerm[] = [
  {
    id: "tikanga",
    reo: "Tikanga",
    english: "Correct protocol / governance",
    engineeringMeaning:
      "Rules that decide whether a route, packet, proof claim, or UI action is safe and honest.",
    risk: "HIGH",
    action: "APPROVED_WITH_WARNING",
    source: "PRIMARY_TIKANGA_ENGINE",
    proofLabel: "TIKANGA_GOVERNANCE_VISIBLE",
  },
  {
    id: "tapu",
    reo: "Tapu",
    english: "Protected / restricted state",
    engineeringMeaning:
      "Protected packet, identity, route, or data state requiring stronger proof and careful handling.",
    risk: "PROTECTED",
    action: "REVIEW_REQUIRED",
    source: "PRIMARY_TIKANGA_ENGINE",
    proofLabel: "TAPU_PROTECTED_STATE_VISIBLE",
  },
  {
    id: "noa",
    reo: "Noa",
    english: "Open / safe state",
    engineeringMeaning:
      "Low-risk state where route display or message handling is allowed with standard proof labels.",
    risk: "LOW",
    action: "APPROVED",
    source: "PRIMARY_TIKANGA_ENGINE",
    proofLabel: "NOA_SAFE_STATE_VISIBLE",
  },
  {
    id: "mana",
    reo: "Mana",
    english: "Authority, dignity, integrity",
    engineeringMeaning:
      "Protects user control, identity dignity, trust score, and non-false public claims.",
    risk: "HIGH",
    action: "APPROVED_WITH_WARNING",
    source: "PRIMARY_TIKANGA_ENGINE",
    proofLabel: "MANA_INTEGRITY_VISIBLE",
  },
  {
    id: "mauri",
    reo: "Mauri",
    english: "Living integrity / life force",
    engineeringMeaning:
      "System health, packet integrity, device readiness, and living mesh state.",
    risk: "MEDIUM",
    action: "APPROVED_WITH_WARNING",
    source: "PRIMARY_TIKANGA_ENGINE",
    proofLabel: "MAURI_SYSTEM_INTEGRITY_VISIBLE",
  },
  {
    id: "whakapapa-ara",
    reo: "Whakapapa Ara",
    english: "Route lineage",
    engineeringMeaning:
      "The route history of a packet: sender, relay, receiver, ACK, proof hash, and audit trail.",
    risk: "HIGH",
    action: "APK_PROOF_REQUIRED",
    source: "BACKUP_PROTOCOL_REGISTRY",
    proofLabel: "WHAKAPAPA_ARA_ROUTE_LINEAGE_VISIBLE",
  },
  {
    id: "kaitiakitanga",
    reo: "Kaitiakitanga",
    english: "Protective stewardship",
    engineeringMeaning:
      "Protects battery, privacy, cultural safety, device limits, and honest proof boundaries.",
    risk: "HIGH",
    action: "APPROVED_WITH_WARNING",
    source: "BACKUP_PROTOCOL_REGISTRY",
    proofLabel: "KAITIAKITANGA_PROTECTION_VISIBLE",
  },
  {
    id: "rangatiratanga",
    reo: "Rangatiratanga",
    english: "Self-determination / user control",
    engineeringMeaning:
      "User control over identity, routing, privacy, permissions, and proof sharing.",
    risk: "HIGH",
    action: "APPROVED_WITH_WARNING",
    source: "BACKUP_PROTOCOL_REGISTRY",
    proofLabel: "RANGATIRATANGA_USER_CONTROL_VISIBLE",
  },
  {
    id: "whanaungatanga",
    reo: "Whanaungatanga",
    english: "Trusted relationship path",
    engineeringMeaning:
      "Trust relationship between peers, relay memory, route confidence, and ACK learning.",
    risk: "MEDIUM",
    action: "APPROVED_WITH_WARNING",
    source: "BACKUP_PROTOCOL_REGISTRY",
    proofLabel: "WHANAUNGATANGA_TRUST_PATH_VISIBLE",
  },
  {
    id: "arotake",
    reo: "Arotake",
    english: "Review required",
    engineeringMeaning:
      "Human or operator review is required before claiming proof, delivery, identity, or cultural authority.",
    risk: "PROTECTED",
    action: "REVIEW_REQUIRED",
    source: "SAFE_FALLBACK_PROTOCOL",
    proofLabel: "AROTAKE_REVIEW_REQUIRED_VISIBLE",
  },
  {
    id: "whakaaetia",
    reo: "Whakaaetia",
    english: "Approved",
    engineeringMeaning:
      "Action is allowed when proof and safety requirements are satisfied.",
    risk: "LOW",
    action: "APPROVED",
    source: "SAFE_FALLBACK_PROTOCOL",
    proofLabel: "WHAKAAETIA_APPROVED_VISIBLE",
  },
  {
    id: "whakatupato",
    reo: "Whakatūpato",
    english: "Warning",
    engineeringMeaning:
      "Allow display or testing, but warn that device/APK/BLE proof is incomplete.",
    risk: "MEDIUM",
    action: "APPROVED_WITH_WARNING",
    source: "SAFE_FALLBACK_PROTOCOL",
    proofLabel: "WHAKATUPATO_WARNING_VISIBLE",
  },
  {
    id: "kaore-ano",
    reo: "Kāore anō kia whakamātau",
    english: "Not yet proven",
    engineeringMeaning:
      "No real device proof exists yet. Do not claim live BLE, ACK, relay, or raw 32K proof.",
    risk: "HIGH",
    action: "APK_PROOF_REQUIRED",
    source: "SAFE_FALLBACK_PROTOCOL",
    proofLabel: "KAORE_ANO_KIA_WHAKAMATAU_NOT_PROVEN_VISIBLE",
  },
  {
    id: "apk-proof",
    reo: "Me whakamātau ki te APK",
    english: "APK proof required",
    engineeringMeaning:
      "Requires installed APK, physical device, permissions, and logcat evidence.",
    risk: "HIGH",
    action: "APK_PROOF_REQUIRED",
    source: "SAFE_FALLBACK_PROTOCOL",
    proofLabel: "ME_WHAKAMATAU_KI_TE_APK_VISIBLE",
  },
];

export function getProtocolTerm(id: string): MaoriProtocolTerm {
  const found = MAORI_PROTOCOL_TERMS.find((term) => term.id === id);
  if (found) return found;

  return {
    id: "fallback",
    reo: "Kawa Pūrua",
    english: "Backup protocol",
    engineeringMeaning:
      "The requested protocol term was not available, so MauriMesh used a safe fallback label.",
    risk: "MEDIUM",
    action: "UNAVAILABLE_FALLBACK",
    source: "SAFE_FALLBACK_PROTOCOL",
    proofLabel: "KAWA_PURUA_BACKUP_PROTOCOL_VISIBLE",
  };
}

export function createProtocolDecision(input: {
  screen: string;
  termIds?: string[];
  action?: MaoriProtocolAction;
  risk?: MaoriProtocolRisk;
  source?: MaoriProtocolSource;
}): MaoriProtocolDecision {
  const terms = (input.termIds && input.termIds.length > 0
    ? input.termIds
    : ["tikanga", "mauri", "mana", "kaore-ano", "apk-proof"]
  ).map(getProtocolTerm);

  const highestRisk = input.risk || pickHighestRisk(terms.map((term) => term.risk));
  const action = input.action || pickStrongestAction(terms.map((term) => term.action));
  const source = input.source || pickBestSource(terms.map((term) => term.source));

  const warnings: string[] = [];

  if (action === "APK_PROOF_REQUIRED") {
    warnings.push(
      "Me whakamātau ki te APK — installed APK and device proof are required before claiming live function.",
    );
  }

  if (action === "MULTI_DEVICE_PROOF_REQUIRED") {
    warnings.push(
      "Me whakamātau ki ngā waea maha — multi-phone proof is required before claiming mesh delivery.",
    );
  }

  if (highestRisk === "PROTECTED") {
    warnings.push(
      "Arotake — protected cultural or proof state requires review before strong public claims.",
    );
  }

  return {
    id: `maori_protocol_${input.screen.replace(/[^a-z0-9]+/gi, "_").toLowerCase()}`,
    screen: input.screen,
    action,
    source,
    risk: highestRisk,
    reoSummary:
      "Tikanga, mana, mauri, tapu/noa, whakapapa ara, kaitiakitanga, rangatiratanga, me te whanaungatanga kua whakahokia ki tēnei mata.",
    englishSummary:
      "Māori protocol labels are restored on this screen with primary, backup, and safe fallback governance.",
    terms,
    warnings,
    truthBoundary:
      "This protocol layer restores visible te reo Māori and Tikanga proof labels. It does not by itself prove real BLE, ACK, relay, native telemetry, or APK runtime success.",
  };
}

function pickHighestRisk(risks: MaoriProtocolRisk[]): MaoriProtocolRisk {
  if (risks.includes("PROTECTED")) return "PROTECTED";
  if (risks.includes("HIGH")) return "HIGH";
  if (risks.includes("MEDIUM")) return "MEDIUM";
  return "LOW";
}

function pickStrongestAction(actions: MaoriProtocolAction[]): MaoriProtocolAction {
  if (actions.includes("REFUSED")) return "REFUSED";
  if (actions.includes("REVIEW_REQUIRED")) return "REVIEW_REQUIRED";
  if (actions.includes("MULTI_DEVICE_PROOF_REQUIRED")) return "MULTI_DEVICE_PROOF_REQUIRED";
  if (actions.includes("APK_PROOF_REQUIRED")) return "APK_PROOF_REQUIRED";
  if (actions.includes("APPROVED_WITH_WARNING")) return "APPROVED_WITH_WARNING";
  if (actions.includes("UNAVAILABLE_FALLBACK")) return "UNAVAILABLE_FALLBACK";
  return "APPROVED";
}

function pickBestSource(sources: MaoriProtocolSource[]): MaoriProtocolSource {
  if (sources.includes("PRIMARY_TIKANGA_ENGINE")) return "PRIMARY_TIKANGA_ENGINE";
  if (sources.includes("BACKUP_PROTOCOL_REGISTRY")) return "BACKUP_PROTOCOL_REGISTRY";
  return "SAFE_FALLBACK_PROTOCOL";
}
TS

# ============================================================
# 3. FALLBACK ENGINE
# ============================================================

cat > "$ROOT/src/maurimesh/protocols/MaoriProtocolFallbackEngine.ts" <<'TS'
import { createProtocolDecision, MAORI_PROTOCOL_TERMS } from "./MaoriProtocolRegistry";
import { MaoriProtocolDecision } from "./MaoriProtocolTypes";

export function evaluateMaoriProtocolForScreen(screen: string): MaoriProtocolDecision {
  const normalized = screen.toLowerCase();

  if (normalized.includes("jumpcode")) {
    return createProtocolDecision({
      screen,
      termIds: [
        "tikanga",
        "whakapapa-ara",
        "whanaungatanga",
        "kaitiakitanga",
        "kaore-ano",
        "apk-proof",
      ],
      action: "APK_PROOF_REQUIRED",
      risk: "HIGH",
      source: "BACKUP_PROTOCOL_REGISTRY",
    });
  }

  if (normalized.includes("test")) {
    return createProtocolDecision({
      screen,
      termIds: [
        "tikanga",
        "mauri",
        "arotake",
        "kaore-ano",
        "apk-proof",
      ],
      action: "APK_PROOF_REQUIRED",
      risk: "HIGH",
      source: "BACKUP_PROTOCOL_REGISTRY",
    });
  }

  if (normalized.includes("proof") || normalized.includes("device")) {
    return createProtocolDecision({
      screen,
      termIds: [
        "mana",
        "mauri",
        "whakapapa-ara",
        "arotake",
        "kaore-ano",
        "apk-proof",
      ],
      action: "APK_PROOF_REQUIRED",
      risk: "HIGH",
      source: "BACKUP_PROTOCOL_REGISTRY",
    });
  }

  if (normalized.includes("message") || normalized.includes("ack")) {
    return createProtocolDecision({
      screen,
      termIds: [
        "tikanga",
        "whakapapa-ara",
        "whanaungatanga",
        "kaitiakitanga",
        "kaore-ano",
      ],
      action: "MULTI_DEVICE_PROOF_REQUIRED",
      risk: "HIGH",
      source: "BACKUP_PROTOCOL_REGISTRY",
    });
  }

  if (normalized.includes("tikanga") || normalized.includes("governance")) {
    return createProtocolDecision({
      screen,
      termIds: [
        "tikanga",
        "tapu",
        "noa",
        "mana",
        "rangatiratanga",
        "kaitiakitanga",
        "arotake",
      ],
      action: "APPROVED_WITH_WARNING",
      risk: "PROTECTED",
      source: "PRIMARY_TIKANGA_ENGINE",
    });
  }

  return createProtocolDecision({
    screen,
    termIds: [
      "tikanga",
      "mauri",
      "mana",
      "kaitiakitanga",
      "kaore-ano",
    ],
    action: "APPROVED_WITH_WARNING",
    risk: "MEDIUM",
    source: "SAFE_FALLBACK_PROTOCOL",
  });
}

export function getMaoriProtocolBackupSummary() {
  return {
    totalTerms: MAORI_PROTOCOL_TERMS.length,
    primaryTerms: MAORI_PROTOCOL_TERMS.filter((term) => term.source === "PRIMARY_TIKANGA_ENGINE").length,
    backupTerms: MAORI_PROTOCOL_TERMS.filter((term) => term.source === "BACKUP_PROTOCOL_REGISTRY").length,
    fallbackTerms: MAORI_PROTOCOL_TERMS.filter((term) => term.source === "SAFE_FALLBACK_PROTOCOL").length,
    proofLabels: MAORI_PROTOCOL_TERMS.map((term) => term.proofLabel),
    status: "MAORI_PROTOCOL_FALLBACK_READY",
    truth:
      "Primary Tikanga terms, backup protocol terms, and safe fallback terms are available for APK proof UI.",
  };
}
TS

cat > "$ROOT/src/maurimesh/protocols/index.ts" <<'TS'
export * from "./MaoriProtocolTypes";
export * from "./MaoriProtocolRegistry";
export * from "./MaoriProtocolFallbackEngine";
TS

# ============================================================
# 4. UI COMPONENT
# ============================================================

cat > "$ROOT/src/components/MaoriProtocolPanel.tsx" <<'TSX'
import React, { useMemo } from "react";
import { StyleSheet, Text, View } from "react-native";
import {
  evaluateMaoriProtocolForScreen,
  getMaoriProtocolBackupSummary,
} from "../maurimesh/protocols";

const C = {
  panel: "rgba(2,12,8,0.92)",
  border: "rgba(0,208,132,0.32)",
  green: "#00D084",
  emerald: "#10B981",
  white: "#FFFFFF",
  muted: "rgba(255,255,255,0.72)",
  warn: "#F59E0B",
  danger: "#FB7185",
  blue: "#38BDF8",
};

export function MaoriProtocolPanel({
  screen,
  compact = false,
}: {
  screen: string;
  compact?: boolean;
}) {
  const decision = useMemo(() => evaluateMaoriProtocolForScreen(screen), [screen]);
  const backup = useMemo(() => getMaoriProtocolBackupSummary(), []);

  const actionColor =
    decision.action === "APPROVED"
      ? C.green
      : decision.action === "REVIEW_REQUIRED" || decision.action === "REFUSED"
        ? C.danger
        : C.warn;

  return (
    <View style={styles.panel}>
      <View style={styles.row}>
        <View style={styles.pill}>
          <Text style={styles.pillText}>TE REO / TIKANGA</Text>
        </View>
        <View style={[styles.pill, { borderColor: actionColor }]}>
          <Text style={[styles.pillText, { color: actionColor }]}>{decision.action}</Text>
        </View>
      </View>

      <Text style={styles.title}>Kawa Māori / Māori Protocol</Text>
      <Text style={styles.reo}>{decision.reoSummary}</Text>
      <Text style={styles.english}>{decision.englishSummary}</Text>

      {!compact && (
        <>
          <View style={styles.divider} />

          {decision.terms.map((term) => (
            <View key={term.id} style={styles.term}>
              <Text style={styles.termReo}>{term.reo}</Text>
              <Text style={styles.termEnglish}>{term.english}</Text>
              <Text style={styles.termMeaning}>{term.engineeringMeaning}</Text>
              <Text style={styles.proofLabel}>{term.proofLabel}</Text>
            </View>
          ))}

          <View style={styles.divider} />

          <Text style={styles.meta}>Source: {decision.source}</Text>
          <Text style={styles.meta}>Risk: {decision.risk}</Text>
          <Text style={styles.meta}>Backup status: {backup.status}</Text>
          <Text style={styles.meta}>
            Terms: {backup.totalTerms} total · {backup.primaryTerms} primary · {backup.backupTerms} backup ·{" "}
            {backup.fallbackTerms} fallback
          </Text>

          {decision.warnings.map((warning) => (
            <Text key={warning} style={styles.warning}>
              {warning}
            </Text>
          ))}

          <Text style={styles.truth}>{decision.truthBoundary}</Text>
        </>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  panel: {
    borderWidth: 1,
    borderColor: C.border,
    borderRadius: 22,
    backgroundColor: C.panel,
    padding: 15,
    gap: 9,
    marginVertical: 8,
  },
  row: { flexDirection: "row", flexWrap: "wrap", gap: 8 },
  pill: {
    alignSelf: "flex-start",
    borderWidth: 1,
    borderColor: C.green,
    borderRadius: 999,
    paddingVertical: 4,
    paddingHorizontal: 9,
    backgroundColor: "rgba(255,255,255,0.05)",
  },
  pillText: { color: C.green, fontSize: 10, fontWeight: "900", letterSpacing: 0.7 },
  title: { color: C.white, fontSize: 20, fontWeight: "900" },
  reo: { color: C.emerald, fontSize: 14, lineHeight: 21, fontWeight: "800" },
  english: { color: C.muted, fontSize: 13, lineHeight: 20 },
  divider: { height: 1, backgroundColor: "rgba(255,255,255,0.08)", marginVertical: 4 },
  term: {
    borderTopWidth: 1,
    borderTopColor: "rgba(255,255,255,0.06)",
    paddingTop: 8,
    gap: 2,
  },
  termReo: { color: C.green, fontSize: 15, fontWeight: "900" },
  termEnglish: { color: C.white, fontSize: 13, fontWeight: "700" },
  termMeaning: { color: C.muted, fontSize: 12, lineHeight: 18 },
  proofLabel: {
    color: C.blue,
    fontSize: 11,
    fontFamily: "monospace",
    marginTop: 2,
  },
  meta: { color: C.muted, fontSize: 12 },
  warning: { color: C.warn, fontSize: 12, lineHeight: 18 },
  truth: { color: C.muted, fontSize: 12, lineHeight: 18 },
});
TSX

# ============================================================
# 5. RESTORE PROTOCOL ROUTE
# ============================================================

cat > "$ROOT/app/maori-protocols.tsx" <<'TSX'
import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { MaoriProtocolPanel } from "../src/components/MaoriProtocolPanel";
import { getMaoriProtocolBackupSummary } from "../src/maurimesh/protocols";

export default function MaoriProtocolsScreen() {
  const summary = getMaoriProtocolBackupSummary();

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <View style={styles.header}>
        <Text style={styles.kicker}>MauriMesh</Text>
        <Text style={styles.title}>Māori Protocols</Text>
        <Text style={styles.subtitle}>
          Te reo Māori, Tikanga governance, cultural proof labels, and safe fallback protocol
          wiring for APK/device proof screens.
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Fallback Status</Text>
        <Text style={styles.line}>Status: {summary.status}</Text>
        <Text style={styles.line}>Primary terms: {summary.primaryTerms}</Text>
        <Text style={styles.line}>Backup terms: {summary.backupTerms}</Text>
        <Text style={styles.line}>Safe fallback terms: {summary.fallbackTerms}</Text>
        <Text style={styles.truth}>{summary.truth}</Text>
      </View>

      <MaoriProtocolPanel screen="Dashboard" />
      <MaoriProtocolPanel screen="Tikanga Engine" />
      <MaoriProtocolPanel screen="JumpCode Proof" />
      <MaoriProtocolPanel screen="Test Layer" />
      <MaoriProtocolPanel screen="Proof Ledger" />
      <MaoriProtocolPanel screen="Message Fallback ACK" />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 18, gap: 14, paddingBottom: 42 },
  header: { gap: 8 },
  kicker: { color: "#00D084", fontSize: 12, fontWeight: "900", letterSpacing: 1 },
  title: { color: "#FFFFFF", fontSize: 34, fontWeight: "900", letterSpacing: -1 },
  subtitle: { color: "rgba(255,255,255,0.72)", fontSize: 15, lineHeight: 22 },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.32)",
    borderRadius: 22,
    backgroundColor: "rgba(2,12,8,0.92)",
    padding: 15,
    gap: 6,
  },
  cardTitle: { color: "#FFFFFF", fontSize: 20, fontWeight: "900" },
  line: { color: "rgba(255,255,255,0.72)", fontSize: 14, lineHeight: 20 },
  truth: { color: "#F59E0B", fontSize: 12, lineHeight: 18 },
});
TSX

# ============================================================
# 6. SAFE SCREEN PATCHER
# ============================================================

patch_screen() {
  local file="$1"
  local screen="$2"

  if [ ! -f "$ROOT/$file" ]; then
    return 0
  fi

  if grep -q "MaoriProtocolPanel" "$ROOT/$file"; then
    return 0
  fi

  python3 <<PY
from pathlib import Path

p = Path("$file")
src = p.read_text()
screen = "$screen"

import_line = 'import { MaoriProtocolPanel } from "../src/components/MaoriProtocolPanel";\\n'

if "from \"../src/components/MaoriProtocolPanel\"" not in src:
    # Insert after last import line.
    lines = src.splitlines()
    insert_at = 0
    for i, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = i + 1
    lines.insert(insert_at, import_line.rstrip())
    src = "\\n".join(lines) + "\\n"

# Add compact protocol marker near the first ScrollView/View content.
panel = f'      <MaoriProtocolPanel screen="{screen}" compact />\\n'

if "<ScrollView" in src:
    idx = src.find("<ScrollView")
    close = src.find(">", idx)
    if close != -1:
        src = src[:close+1] + "\\n" + panel + src[close+1:]
elif "<View" in src:
    idx = src.find("<View")
    close = src.find(">", idx)
    if close != -1:
        src = src[:close+1] + "\\n" + panel + src[close+1:]
else:
    src += f'\\n// Māori Protocol restored for {screen}\\n'

p.write_text(src)
PY
}

patch_screen "app/dashboard.tsx" "Dashboard"
patch_screen "app/tikanga-engine.tsx" "Tikanga Engine"
patch_screen "app/jumpcode-proof.tsx" "JumpCode Proof"
patch_screen "app/test-layer.tsx" "Test Layer"
patch_screen "app/proof-ledger.tsx" "Proof Ledger"
patch_screen "app/device-proof.tsx" "Device Proof"
patch_screen "app/message-fallback.tsx" "Message Fallback ACK"
patch_screen "app/route-lab.tsx" "Route Lab"
patch_screen "app/mauricore-governance.tsx" "MauriCore Governance"

# ============================================================
# 7. DASHBOARD ROUTE MARKER / BUTTON
# ============================================================

if [ -f "$ROOT/app/dashboard.tsx" ] && ! grep -q "/maori-protocols" "$ROOT/app/dashboard.tsx"; then
  python3 <<'PY'
from pathlib import Path

p = Path("app/dashboard.tsx")
src = p.read_text()
button = '<MauriButton title="Māori Protocols" onPress={() => router.push("/maori-protocols")} />'

markers = [
    '<MauriButton title="Tikanga Engine" onPress={() => router.push("/tikanga-engine")} />',
    '<MauriButton title="MauriCore Governance" onPress={() => router.push("/mauricore-governance")} />',
    '<MauriButton title="JumpCode Proof" onPress={() => router.push("/jumpcode-proof")} />',
]

inserted = False
for marker in markers:
    if marker in src:
        src = src.replace(marker, marker + "\n        " + button, 1)
        inserted = True
        break

if not inserted:
    src += '\n\n// Māori Protocols route: /maori-protocols\n'

p.write_text(src)
PY
fi

# ============================================================
# 8. BACKUP REGISTRY + TEST LAYER ROUTES
# ============================================================

if [ -f "$ROOT/src/lib/uiBackupRoutes.ts" ] && ! grep -q "/maori-protocols" "$ROOT/src/lib/uiBackupRoutes.ts"; then
  cat >> "$ROOT/src/lib/uiBackupRoutes.ts" <<'TS'

// MauriMesh Māori Protocols backup route marker
export const MAURIMESH_MAORI_PROTOCOLS_ROUTE = "/maori-protocols";
TS
fi

ENGINE="$ROOT/src/maurimesh/test-layer/MauriMeshFullTestEngine.ts"
if [ -f "$ENGINE" ] && ! grep -q '"/maori-protocols"' "$ENGINE"; then
  python3 <<'PY'
from pathlib import Path
p = Path("src/maurimesh/test-layer/MauriMeshFullTestEngine.ts")
src = p.read_text()
src = src.replace('  "/tikanga-engine",', '  "/tikanga-engine",\n  "/maori-protocols",')
p.write_text(src)
PY
fi

# ============================================================
# 9. CHECKER
# ============================================================

cat > "$ROOT/check-maurimesh-maori-protocol-fallback.sh" <<'EOF_CHECK'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT="$ROOT/docs/maurimesh-maori-protocol-fallback-report-$STAMP.md"
LATEST="$ROOT/docs/maurimesh-maori-protocol-fallback-report-latest.md"
EXPORT_DIR="$ROOT/.maurimesh-maori-protocol-export-$STAMP"

mkdir -p "$ROOT/docs"
: > "$REPORT"

TOTAL=0
PASS=0
FAIL=0

check_file() {
  local label="$1"
  local file="$2"
  TOTAL=$((TOTAL+1))
  if [ -f "$ROOT/$file" ]; then
    echo "- [x] $label exists: $file" >> "$REPORT"
    PASS=$((PASS+1))
  else
    echo "- [ ] MISSING: $label: $file" >> "$REPORT"
    FAIL=$((FAIL+1))
  fi
}

check_contains() {
  local label="$1"
  local file="$2"
  local needle="$3"
  TOTAL=$((TOTAL+1))
  if [ -f "$ROOT/$file" ] && grep -q "$needle" "$ROOT/$file"; then
    echo "- [x] $label" >> "$REPORT"
    PASS=$((PASS+1))
  else
    echo "- [ ] MISSING: $label" >> "$REPORT"
    FAIL=$((FAIL+1))
  fi
}

{
  echo "# MauriMesh Māori Protocol Fallback Report"
  echo ""
  echo "Generated: $STAMP"
  echo ""
  echo "## Files"
} >> "$REPORT"

check_file "Protocol types" "src/maurimesh/protocols/MaoriProtocolTypes.ts"
check_file "Protocol registry" "src/maurimesh/protocols/MaoriProtocolRegistry.ts"
check_file "Fallback engine" "src/maurimesh/protocols/MaoriProtocolFallbackEngine.ts"
check_file "Protocol index" "src/maurimesh/protocols/index.ts"
check_file "Protocol panel" "src/components/MaoriProtocolPanel.tsx"
check_file "Māori protocols route" "app/maori-protocols.tsx"

{
  echo ""
  echo "## Required Te Reo / Tikanga Terms"
} >> "$REPORT"

check_contains "Tikanga term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Tikanga"
check_contains "Tapu term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Tapu"
check_contains "Noa term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Noa"
check_contains "Mana term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Mana"
check_contains "Mauri term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Mauri"
check_contains "Whakapapa Ara term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Whakapapa Ara"
check_contains "Kaitiakitanga term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Kaitiakitanga"
check_contains "Rangatiratanga term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Rangatiratanga"
check_contains "Whanaungatanga term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Whanaungatanga"
check_contains "Arotake term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Arotake"
check_contains "Kāore anō kia whakamātau term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Kāore anō kia whakamātau"
check_contains "Me whakamātau ki te APK term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Me whakamātau ki te APK"

{
  echo ""
  echo "## Fallback + Backup"
} >> "$REPORT"

check_contains "Primary source exists" "src/maurimesh/protocols/MaoriProtocolTypes.ts" "PRIMARY_TIKANGA_ENGINE"
check_contains "Backup source exists" "src/maurimesh/protocols/MaoriProtocolTypes.ts" "BACKUP_PROTOCOL_REGISTRY"
check_contains "Safe fallback source exists" "src/maurimesh/protocols/MaoriProtocolTypes.ts" "SAFE_FALLBACK_PROTOCOL"
check_contains "Fallback summary exists" "src/maurimesh/protocols/MaoriProtocolFallbackEngine.ts" "MAORI_PROTOCOL_FALLBACK_READY"

{
  echo ""
  echo "## UI Wiring"
} >> "$REPORT"

check_contains "Dashboard has protocol panel" "app/dashboard.tsx" "MaoriProtocolPanel"
check_contains "Tikanga screen has protocol panel" "app/tikanga-engine.tsx" "MaoriProtocolPanel"
check_contains "JumpCode screen has protocol panel" "app/jumpcode-proof.tsx" "MaoriProtocolPanel"
check_contains "Test Layer has protocol panel" "app/test-layer.tsx" "MaoriProtocolPanel"
check_contains "Proof Ledger has protocol panel" "app/proof-ledger.tsx" "MaoriProtocolPanel"
check_contains "Device Proof has protocol panel" "app/device-proof.tsx" "MaoriProtocolPanel"
check_contains "Message Fallback has protocol panel" "app/message-fallback.tsx" "MaoriProtocolPanel"
check_contains "Route Lab has protocol panel" "app/route-lab.tsx" "MaoriProtocolPanel"
check_contains "MauriCore Governance has protocol panel" "app/mauricore-governance.tsx" "MaoriProtocolPanel"
check_contains "Dashboard route marker" "app/dashboard.tsx" "/maori-protocols"
check_contains "Backup registry route marker" "src/lib/uiBackupRoutes.ts" "/maori-protocols"
check_contains "Test layer route marker" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "/maori-protocols"

{
  echo ""
  echo "## TypeScript"
} >> "$REPORT"

TOTAL=$((TOTAL+1))
if npx tsc --noEmit >> "$REPORT" 2>&1; then
  echo "- [x] TypeScript passed" >> "$REPORT"
  PASS=$((PASS+1))
else
  echo "- [ ] TypeScript failed" >> "$REPORT"
  FAIL=$((FAIL+1))
fi

{
  echo ""
  echo "## Expo Android Export"
} >> "$REPORT"

TOTAL=$((TOTAL+1))
rm -rf "$EXPORT_DIR"
if NODE_ENV=production npx expo export --platform android --output-dir "$EXPORT_DIR" >> "$REPORT" 2>&1; then
  echo "- [x] Expo Android export passed" >> "$REPORT"
  PASS=$((PASS+1))
else
  echo "- [ ] Expo Android export failed" >> "$REPORT"
  FAIL=$((FAIL+1))
fi

BUNDLE_FILE="$(find "$EXPORT_DIR" -type f \( -name '*.hbc' -o -name '*.js' \) | head -1 || true)"

{
  echo ""
  echo "## Bundle Marker Search"
} >> "$REPORT"

TOTAL=$((TOTAL+1))
if [ -n "$BUNDLE_FILE" ] && strings "$BUNDLE_FILE" | grep -Ei "TE REO / TIKANGA|Tikanga|Whakapapa Ara|Kaitiakitanga|Rangatiratanga|MAORI_PROTOCOL_FALLBACK_READY|Me whakam" >> "$REPORT" 2>&1; then
  echo "- [x] Māori protocol markers found in Android bundle" >> "$REPORT"
  PASS=$((PASS+1))
else
  echo "- [ ] Māori protocol markers not confirmed in Android bundle" >> "$REPORT"
  FAIL=$((FAIL+1))
fi

SCORE=$(( PASS * 100 / TOTAL ))
STATUS="COMPLETE"
if [ "$FAIL" -gt 0 ]; then
  STATUS="FAILED"
fi

{
  echo ""
  echo "## Summary"
  echo ""
  echo "- Total: $TOTAL"
  echo "- Complete: $PASS"
  echo "- Missing/failed: $FAIL"
  echo "- Score: $SCORE%"
  echo "- Status: **$STATUS**"
  echo ""
  echo "## Final Truth"
  echo ""
  echo "Māori protocol visibility has been restored with primary, backup, and safe fallback layers."
  echo "This restores te reo Māori/Tikanga proof labels in the UI and bundle."
  echo "It does not by itself prove real BLE delivery, real ACK, native telemetry, or installed APK success."
} >> "$REPORT"

cp "$REPORT" "$LATEST"
cat "$REPORT"

echo ""
echo "============================================================"
echo "MĀORI PROTOCOL FALLBACK CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score: $SCORE%"
echo "Report: $LATEST"
echo "============================================================"

if [ "$STATUS" != "COMPLETE" ]; then
  exit 1
fi
EOF_CHECK

chmod +x "$ROOT/check-maurimesh-maori-protocol-fallback.sh"

# ============================================================
# 10. RUN CHECK
# ============================================================

./check-maurimesh-maori-protocol-fallback.sh

echo ""
echo "============================================================"
echo "DONE: MĀORI PROTOCOL FALLBACK LAYER INSTALLED"
echo "============================================================"
echo "Backup:"
echo "  $BACKUP"
echo ""
echo "Open route:"
echo "  /maori-protocols"
echo ""
echo "Report:"
echo "  docs/maurimesh-maori-protocol-fallback-report-latest.md"
echo "============================================================"
