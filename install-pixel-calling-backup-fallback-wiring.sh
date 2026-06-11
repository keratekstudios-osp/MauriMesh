#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "INSTALL PIXEL CALLING BACKUP FALLBACK WIRING"
echo "Adds fallback-backup for Pixel Calling:"
echo "Primary call runtime -> backup call control -> push-to-talk"
echo "-> voice note -> text message -> store-forward hold."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-pixel-calling-backup-fallback-$STAMP"

APP="$ROOT/app"
SRC="$ROOT/src"
CALL="$SRC/maurimesh/pixel-calling"
COMP="$SRC/components"
DOCS="$ROOT/docs"

mkdir -p "$BACKUP" "$APP" "$CALL" "$COMP" "$DOCS"

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

backup_file "app/dashboard.tsx"
backup_file "app/pixel-calling.tsx"
backup_file "app/pixel-calling-backup.tsx"
backup_file "app/device-proof.tsx"
backup_file "app/proof-ledger.tsx"
backup_file "app/message-fallback.tsx"
backup_file "src/lib/uiBackupRoutes.ts"
backup_file "check-maurimesh-master-readiness.sh"

echo "Backup saved:"
echo "  $BACKUP"

# ============================================================
# 1. Backup fallback types
# ============================================================

cat > "$CALL/PixelCallingBackupTypes.ts" <<'TS'
export type PixelCallingBackupStage =
  | "PRIMARY_CALL_RUNTIME"
  | "BACKUP_CALL_CONTROL"
  | "PUSH_TO_TALK_BACKUP"
  | "VOICE_NOTE_BACKUP"
  | "TEXT_MESSAGE_BACKUP"
  | "STORE_FORWARD_BACKUP"
  | "SAFE_CALL_HOLD";

export type PixelCallingBackupReason =
  | "PRIMARY_RUNTIME_FAILED"
  | "NO_STRICT_ACK"
  | "NO_AUDIO_PERMISSION"
  | "HARDWARE_PRESSURE"
  | "NO_LIVE_TRANSPORT"
  | "USER_NOT_ACCEPTED"
  | "UNKNOWN_SAFE_FALLBACK";

export type PixelCallingBackupInput = {
  callId: string;
  primaryRuntimeReady: boolean;
  strictAckReceived: boolean;
  relayAckReceived: boolean;
  microphonePermission: boolean;
  speakerReady: boolean;
  bleControlAvailable: boolean;
  wifiAudioAvailable: boolean;
  internetGatewayAvailable: boolean;
  messageFallbackAvailable: boolean;
  storeForwardAvailable: boolean;
  hardwarePressure: "low" | "medium" | "high" | "critical";
  userAccepted: boolean;
};

export type PixelCallingBackupDecision = {
  callId: string;
  selectedStage: PixelCallingBackupStage;
  reason: PixelCallingBackupReason;
  fallbackBackupOrder: PixelCallingBackupStage[];
  canUsePrimaryCallRuntime: boolean;
  canUseBackupControl: boolean;
  canUsePushToTalk: boolean;
  canUseVoiceNote: boolean;
  canUseTextFallback: boolean;
  canUseStoreForward: boolean;
  canClaimLiveCall: boolean;
  proofLabel: string;
  finalTruth: string;
};
TS

# ============================================================
# 2. Backup fallback engine
# ============================================================

cat > "$CALL/PixelCallingBackupFallback.ts" <<'TS'
import {
  PixelCallingBackupDecision,
  PixelCallingBackupInput,
  PixelCallingBackupReason,
  PixelCallingBackupStage,
} from "./PixelCallingBackupTypes";

export function createPixelCallingFallbackBackupOrder(
  input: PixelCallingBackupInput
): PixelCallingBackupStage[] {
  const order: PixelCallingBackupStage[] = [];

  order.push("PRIMARY_CALL_RUNTIME");

  if (input.bleControlAvailable || input.relayAckReceived) {
    order.push("BACKUP_CALL_CONTROL");
  }

  if (
    input.microphonePermission &&
    input.speakerReady &&
    input.hardwarePressure !== "critical"
  ) {
    order.push("PUSH_TO_TALK_BACKUP");
    order.push("VOICE_NOTE_BACKUP");
  }

  order.push("TEXT_MESSAGE_BACKUP");

  if (input.messageFallbackAvailable || input.storeForwardAvailable) {
    order.push("STORE_FORWARD_BACKUP");
  }

  order.push("SAFE_CALL_HOLD");

  return order;
}

function decideReason(input: PixelCallingBackupInput): PixelCallingBackupReason {
  if (!input.primaryRuntimeReady) return "PRIMARY_RUNTIME_FAILED";
  if (!input.userAccepted) return "USER_NOT_ACCEPTED";
  if (!input.strictAckReceived) return "NO_STRICT_ACK";
  if (!input.microphonePermission || !input.speakerReady) return "NO_AUDIO_PERMISSION";
  if (input.hardwarePressure === "critical" || input.hardwarePressure === "high") {
    return "HARDWARE_PRESSURE";
  }
  if (!input.wifiAudioAvailable && !input.internetGatewayAvailable) {
    return "NO_LIVE_TRANSPORT";
  }
  return "UNKNOWN_SAFE_FALLBACK";
}

export function decidePixelCallingBackupFallback(
  input: PixelCallingBackupInput
): PixelCallingBackupDecision {
  const fallbackBackupOrder = createPixelCallingFallbackBackupOrder(input);

  const canUsePrimaryCallRuntime =
    input.primaryRuntimeReady &&
    input.userAccepted &&
    input.strictAckReceived &&
    input.microphonePermission &&
    input.speakerReady &&
    input.hardwarePressure !== "critical" &&
    (input.wifiAudioAvailable || input.internetGatewayAvailable);

  if (canUsePrimaryCallRuntime) {
    return {
      callId: input.callId,
      selectedStage: "PRIMARY_CALL_RUNTIME",
      reason: "UNKNOWN_SAFE_FALLBACK",
      fallbackBackupOrder,
      canUsePrimaryCallRuntime: true,
      canUseBackupControl: true,
      canUsePushToTalk: true,
      canUseVoiceNote: true,
      canUseTextFallback: true,
      canUseStoreForward: input.storeForwardAvailable,
      canClaimLiveCall: false,
      proofLabel: "PRIMARY_RUNTIME_READY_APK_AUDIO_PROOF_REQUIRED",
      finalTruth:
        "Pixel Calling primary runtime is ready to try. It still cannot claim a real live call until installed APK audio and strict device ACK proof exist.",
    };
  }

  const reason = decideReason(input);

  const canUseBackupControl =
    input.bleControlAvailable || input.relayAckReceived;

  const canUsePushToTalk =
    input.microphonePermission &&
    input.speakerReady &&
    input.hardwarePressure !== "critical" &&
    canUseBackupControl;

  const canUseVoiceNote =
    input.microphonePermission &&
    input.hardwarePressure !== "critical";

  const canUseTextFallback = true;

  const canUseStoreForward =
    input.messageFallbackAvailable || input.storeForwardAvailable;

  let selectedStage: PixelCallingBackupStage = "SAFE_CALL_HOLD";

  if (canUseBackupControl) {
    selectedStage = "BACKUP_CALL_CONTROL";
  }

  if (canUsePushToTalk) {
    selectedStage = "PUSH_TO_TALK_BACKUP";
  } else if (canUseVoiceNote) {
    selectedStage = "VOICE_NOTE_BACKUP";
  } else if (canUseTextFallback) {
    selectedStage = "TEXT_MESSAGE_BACKUP";
  }

  if (
    reason === "NO_LIVE_TRANSPORT" &&
    canUseStoreForward
  ) {
    selectedStage = "STORE_FORWARD_BACKUP";
  }

  return {
    callId: input.callId,
    selectedStage,
    reason,
    fallbackBackupOrder,
    canUsePrimaryCallRuntime: false,
    canUseBackupControl,
    canUsePushToTalk,
    canUseVoiceNote,
    canUseTextFallback,
    canUseStoreForward,
    canClaimLiveCall: false,
    proofLabel: "PIXEL_CALLING_BACKUP_FALLBACK_ACTIVE",
    finalTruth:
      "Pixel Calling fallback-backup is active. It protects the call attempt by falling back to backup control, push-to-talk, voice note, text, or store-forward, but it does not claim a live call without installed APK audio proof and strict device ACK.",
  };
}

export function runPixelCallingBackupFallbackDemo(): PixelCallingBackupDecision {
  return decidePixelCallingBackupFallback({
    callId: "MM-CALL-BACKUP-DEMO-001",
    primaryRuntimeReady: false,
    strictAckReceived: false,
    relayAckReceived: true,
    microphonePermission: true,
    speakerReady: true,
    bleControlAvailable: true,
    wifiAudioAvailable: false,
    internetGatewayAvailable: false,
    messageFallbackAvailable: true,
    storeForwardAvailable: true,
    hardwarePressure: "medium",
    userAccepted: true,
  });
}
TS

# Patch index export
if [ -f "$CALL/index.ts" ]; then
  if ! grep -Fq 'PixelCallingBackupFallback' "$CALL/index.ts"; then
    cat >> "$CALL/index.ts" <<'TS'
export * from "./PixelCallingBackupTypes";
export * from "./PixelCallingBackupFallback";
TS
  fi
else
  cat > "$CALL/index.ts" <<'TS'
export * from "./PixelCallingBackupTypes";
export * from "./PixelCallingBackupFallback";
TS
fi

# ============================================================
# 3. UI backup panel
# ============================================================

cat > "$COMP/PixelCallingBackupFallbackPanel.tsx" <<'TSX'
import React, { useMemo, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import {
  decidePixelCallingBackupFallback,
  PixelCallingBackupInput,
} from "../maurimesh/pixel-calling";
import { mauriTheme } from "../theme/mauriTheme";
import { MauriButton } from "./MauriButton";
import { MauriPanel } from "./MauriPanel";
import { StatusPill } from "./StatusPill";

type Scenario = "primaryFailed" | "noAudio" | "storeForward" | "primaryReady";

export function PixelCallingBackupFallbackPanel() {
  const [scenario, setScenario] = useState<Scenario>("primaryFailed");

  const input: PixelCallingBackupInput = useMemo(() => {
    const base: PixelCallingBackupInput = {
      callId: `MM-CALL-BACKUP-${scenario.toUpperCase()}`,
      primaryRuntimeReady: false,
      strictAckReceived: false,
      relayAckReceived: true,
      microphonePermission: true,
      speakerReady: true,
      bleControlAvailable: true,
      wifiAudioAvailable: false,
      internetGatewayAvailable: false,
      messageFallbackAvailable: true,
      storeForwardAvailable: true,
      hardwarePressure: "medium",
      userAccepted: true,
    };

    if (scenario === "noAudio") {
      return {
        ...base,
        microphonePermission: false,
        speakerReady: false,
      };
    }

    if (scenario === "storeForward") {
      return {
        ...base,
        bleControlAvailable: false,
        relayAckReceived: false,
        wifiAudioAvailable: false,
        internetGatewayAvailable: false,
      };
    }

    if (scenario === "primaryReady") {
      return {
        ...base,
        primaryRuntimeReady: true,
        strictAckReceived: true,
        wifiAudioAvailable: true,
        internetGatewayAvailable: true,
        hardwarePressure: "low",
      };
    }

    return base;
  }, [scenario]);

  const decision = decidePixelCallingBackupFallback(input);

  return (
    <View style={styles.wrap}>
      <MauriPanel glow>
        <StatusPill
          label={decision.proofLabel}
          tone={decision.selectedStage === "PRIMARY_CALL_RUNTIME" ? "success" : "warning"}
        />
        <Text style={styles.title}>Pixel Calling Backup Fallback</Text>
        <Text style={styles.detail}>{decision.finalTruth}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Selected Backup Stage</Text>
        <Text style={styles.big}>{decision.selectedStage}</Text>
        <Text style={styles.rowText}>Reason: {decision.reason}</Text>
        <Text style={styles.rowText}>
          Can claim live call: {decision.canClaimLiveCall ? "yes" : "no"}
        </Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Fallback-Backup Order</Text>
        {decision.fallbackBackupOrder.map((stage, index) => (
          <Text key={`${stage}-${index}`} style={styles.rowText}>
            {index + 1}. {stage}
          </Text>
        ))}
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Backup Capabilities</Text>
        <Text style={styles.rowText}>Primary runtime: {decision.canUsePrimaryCallRuntime ? "ready" : "fallback"}</Text>
        <Text style={styles.rowText}>Backup control: {decision.canUseBackupControl ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Push-to-talk: {decision.canUsePushToTalk ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Voice note: {decision.canUseVoiceNote ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Text fallback: {decision.canUseTextFallback ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Store-forward: {decision.canUseStoreForward ? "yes" : "no"}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Try-Out Scenarios</Text>
        <View style={styles.buttons}>
          <MauriButton title="Primary Failed" onPress={() => setScenario("primaryFailed")} />
          <MauriButton title="No Audio" onPress={() => setScenario("noAudio")} />
          <MauriButton title="Store Forward" onPress={() => setScenario("storeForward")} />
          <MauriButton title="Primary Ready" onPress={() => setScenario("primaryReady")} />
        </View>
      </MauriPanel>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    gap: mauriTheme.spacing.md,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 24,
    fontWeight: "900",
    marginTop: mauriTheme.spacing.sm,
  },
  sectionTitle: {
    color: mauriTheme.colors.greenstone,
    fontSize: 18,
    fontWeight: "900",
  },
  big: {
    color: mauriTheme.colors.white,
    fontSize: 24,
    fontWeight: "900",
  },
  detail: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  rowText: {
    color: mauriTheme.colors.white,
    lineHeight: 22,
  },
  buttons: {
    gap: mauriTheme.spacing.sm,
    marginTop: mauriTheme.spacing.md,
  },
});
TSX

# ============================================================
# 4. Backup route screen
# ============================================================

cat > "$APP/pixel-calling-backup.tsx" <<'TSX'
import React from "react";
import { AppShell } from "../src/components/AppShell";
import { MauriPageHeader } from "../src/components/MauriPageHeader";
import { PixelCallingBackupFallbackPanel } from "../src/components/PixelCallingBackupFallbackPanel";

export default function PixelCallingBackupScreen() {
  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="PIXEL CALLING BACKUP"
        title="Pixel Calling Backup Fallback"
        subtitle="Fallback-backup path for failed call runtime: backup control, push-to-talk, voice note, text fallback, and store-forward hold."
        tone="warning"
      />
      <PixelCallingBackupFallbackPanel />
    </AppShell>
  );
}
TSX

# ============================================================
# 5. Wire into screens + registry + dashboard
# ============================================================

node <<'NODE'
const fs = require("fs");

function patchScreen(file, importLine, componentLine) {
  if (!fs.existsSync(file)) return;
  let src = fs.readFileSync(file, "utf8");

  if (!src.includes("PixelCallingBackupFallbackPanel")) {
    src = `${importLine}\n${src}`;
    if (src.includes("</AppShell>")) {
      src = src.replace("</AppShell>", `      ${componentLine}\n    </AppShell>`);
    } else {
      src += `\n// Pixel Calling Backup Fallback route: /pixel-calling-backup\n`;
    }
    fs.writeFileSync(file, src);
  }
}

patchScreen(
  "app/pixel-calling.tsx",
  'import { PixelCallingBackupFallbackPanel } from "../src/components/PixelCallingBackupFallbackPanel";',
  "<PixelCallingBackupFallbackPanel />"
);

patchScreen(
  "app/device-proof.tsx",
  'import { PixelCallingBackupFallbackPanel } from "../src/components/PixelCallingBackupFallbackPanel";',
  "<PixelCallingBackupFallbackPanel />"
);

patchScreen(
  "app/proof-ledger.tsx",
  'import { PixelCallingBackupFallbackPanel } from "../src/components/PixelCallingBackupFallbackPanel";',
  "<PixelCallingBackupFallbackPanel />"
);

patchScreen(
  "app/message-fallback.tsx",
  'import { PixelCallingBackupFallbackPanel } from "../src/components/PixelCallingBackupFallbackPanel";',
  "<PixelCallingBackupFallbackPanel />"
);

const registry = "src/lib/uiBackupRoutes.ts";
if (fs.existsSync(registry)) {
  let src = fs.readFileSync(registry, "utf8");

  if (!src.includes("/pixel-calling-backup")) {
    const entry = `,
  {
    key: "pixelCallingBackup",
    title: "Pixel Calling Backup Fallback",
    route: "/pixel-calling-backup",
    fallbackRoute: "/message-fallback",
    critical: true,
    purpose: "Fallback-backup route for failed Pixel Calling runtime.",
  }`;
    src = src.replace(/\n\];/, `${entry}\n];`);
  }

  if (!src.includes('"pixelCallingBackup"')) {
    src = src.replace(/;\s*$/, '\n  | "pixelCallingBackup";');
  }

  fs.writeFileSync(registry, src);
}

const dashboard = "app/dashboard.tsx";
if (fs.existsSync(dashboard)) {
  let src = fs.readFileSync(dashboard, "utf8");

  if (!src.includes("/pixel-calling-backup")) {
    const button = `          <MauriButton title="Pixel Calling Backup" onPress={() => router.push("/pixel-calling-backup")} />`;

    if (src.includes("/pixel-calling")) {
      src = src.replace(
        /(\s*<MauriButton title="Pixel Calling"[\s\S]*?\/>)/,
        `$1\n${button}`
      );
    } else if (src.includes("</AppShell>")) {
      src = src.replace("</AppShell>", `      ${button}\n    </AppShell>`);
    } else {
      src += `\n// Pixel Calling Backup route marker: /pixel-calling-backup\n`;
    }

    fs.writeFileSync(dashboard, src);
  }
}
NODE

# ============================================================
# 6. Checker
# ============================================================

cat > "$ROOT/check-maurimesh-pixel-calling-backup-fallback.sh" <<'CHECK'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-pixel-calling-backup-fallback-report-$STAMP.md"
LATEST="$DOCS/maurimesh-pixel-calling-backup-fallback-report-latest.md"

PASS=0
FAIL=0
WARN=0

line(){ echo "$1" | tee -a "$REPORT"; }
pass(){ PASS=$((PASS+1)); line "- [x] $1"; }
fail(){ FAIL=$((FAIL+1)); line "- [ ] MISSING: $1"; }
warn(){ WARN=$((WARN+1)); line "- [!] PARTIAL: $1"; }

has_file(){ [ -f "$ROOT/$1" ]; }
has_text(){ [ -f "$ROOT/$1" ] && grep -Fq "$2" "$ROOT/$1"; }

: > "$REPORT"

line "# MauriMesh Pixel Calling Backup Fallback Report"
line ""
line "Generated: $STAMP"
line ""

line "## Files"
for file in \
  "src/maurimesh/pixel-calling/PixelCallingBackupTypes.ts" \
  "src/maurimesh/pixel-calling/PixelCallingBackupFallback.ts" \
  "src/components/PixelCallingBackupFallbackPanel.tsx" \
  "app/pixel-calling-backup.tsx"
do
  if has_file "$file"; then pass "$file exists"; else fail "$file missing"; fi
done

line ""
line "## Backup Fallback Capabilities"
for token in \
  "PRIMARY_CALL_RUNTIME" \
  "BACKUP_CALL_CONTROL" \
  "PUSH_TO_TALK_BACKUP" \
  "VOICE_NOTE_BACKUP" \
  "TEXT_MESSAGE_BACKUP" \
  "STORE_FORWARD_BACKUP" \
  "SAFE_CALL_HOLD" \
  "PRIMARY_RUNTIME_FAILED" \
  "NO_STRICT_ACK" \
  "NO_AUDIO_PERMISSION" \
  "HARDWARE_PRESSURE" \
  "NO_LIVE_TRANSPORT" \
  "createPixelCallingFallbackBackupOrder" \
  "decidePixelCallingBackupFallback" \
  "runPixelCallingBackupFallbackDemo"
do
  if grep -R "$token" "$ROOT/src/maurimesh/pixel-calling" "$ROOT/src/components/PixelCallingBackupFallbackPanel.tsx" >/dev/null 2>&1; then
    pass "Capability found: $token"
  else
    fail "Capability missing: $token"
  fi
done

line ""
line "## Route + Backup Wiring"
if has_text "app/dashboard.tsx" "/pixel-calling-backup"; then pass "Dashboard has /pixel-calling-backup"; else fail "Dashboard missing /pixel-calling-backup"; fi
if has_text "src/lib/uiBackupRoutes.ts" "/pixel-calling-backup"; then pass "Backup registry has /pixel-calling-backup"; else fail "Backup registry missing /pixel-calling-backup"; fi
if has_text "app/pixel-calling-backup.tsx" "PixelCallingBackupFallbackPanel"; then pass "Backup screen uses PixelCallingBackupFallbackPanel"; else fail "Backup screen missing panel"; fi
if has_text "app/pixel-calling.tsx" "PixelCallingBackupFallbackPanel"; then pass "Pixel Calling screen embeds backup fallback panel"; else warn "Pixel Calling screen embed not confirmed"; fi

line ""
line "## Embedded Proof Wiring"
if has_text "app/device-proof.tsx" "PixelCallingBackupFallbackPanel"; then pass "Device Proof includes PixelCallingBackupFallbackPanel"; else warn "Device Proof embed not confirmed"; fi
if has_text "app/proof-ledger.tsx" "PixelCallingBackupFallbackPanel"; then pass "Proof Ledger includes PixelCallingBackupFallbackPanel"; else warn "Proof Ledger embed not confirmed"; fi
if has_text "app/message-fallback.tsx" "PixelCallingBackupFallbackPanel"; then pass "Message Fallback includes PixelCallingBackupFallbackPanel"; else warn "Message Fallback embed not confirmed"; fi

line ""
line "## Truth Protection"
if has_text "src/maurimesh/pixel-calling/PixelCallingBackupFallback.ts" "does not claim a live call without installed APK audio proof and strict device ACK"; then
  pass "Pixel Calling backup truth boundary present"
else
  warn "Pixel Calling backup truth boundary not confirmed"
fi

line ""
line "## TypeScript"
if npx tsc --noEmit >> "$REPORT" 2>&1; then
  pass "TypeScript passed"
else
  fail "TypeScript failed"
fi

TOTAL=$((PASS + FAIL + WARN))
if [ "$TOTAL" -gt 0 ]; then SCORE=$((PASS * 100 / TOTAL)); else SCORE=0; fi

if [ "$FAIL" -eq 0 ] && [ "$WARN" -eq 0 ]; then
  STATUS="COMPLETE"
elif [ "$FAIL" -eq 0 ]; then
  STATUS="COMPLETE_WITH_WARNINGS"
else
  STATUS="INCOMPLETE"
fi

line ""
line "## Summary"
line ""
line "- Total: $TOTAL"
line "- Complete: $PASS"
line "- Partial: $WARN"
line "- Missing/failed: $FAIL"
line "- Score: $SCORE%"
line "- Status: **$STATUS**"

cp "$REPORT" "$LATEST"

echo ""
echo "============================================================"
echo "PIXEL CALLING BACKUP FALLBACK CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
CHECK

chmod +x "$ROOT/check-maurimesh-pixel-calling-backup-fallback.sh"

# ============================================================
# 7. Update master checker
# ============================================================

MASTER="$ROOT/check-maurimesh-master-readiness.sh"

if [ -f "$MASTER" ]; then
  cp "$MASTER" "$BACKUP/check-maurimesh-master-readiness.sh"

  python3 <<'PY'
from pathlib import Path

path = Path("check-maurimesh-master-readiness.sh")
src = path.read_text()

route_line = '  "/pixel-calling-backup:app/pixel-calling-backup.tsx"'
if route_line not in src:
    if '  "/message-fallback:app/message-fallback.tsx"\n)' in src:
        src = src.replace(
            '  "/message-fallback:app/message-fallback.tsx"\n)',
            '  "/message-fallback:app/message-fallback.tsx"\n'
            '  "/pixel-calling-backup:app/pixel-calling-backup.tsx"\n)'
        )
    elif '"/pixel-calling:app/pixel-calling.tsx"' in src:
        src = src.replace(
            '"/pixel-calling:app/pixel-calling.tsx"',
            '"/pixel-calling:app/pixel-calling.tsx"\n  "/pixel-calling-backup:app/pixel-calling-backup.tsx"'
        )

layer_files = [
    '  "src/maurimesh/pixel-calling/PixelCallingBackupTypes.ts"',
    '  "src/maurimesh/pixel-calling/PixelCallingBackupFallback.ts"',
    '  "src/components/PixelCallingBackupFallbackPanel.tsx"',
]

for lf in layer_files:
    if lf not in src:
        if '  "src/components/MessageFallbackPanel.tsx"\n)' in src:
            src = src.replace(
                '  "src/components/MessageFallbackPanel.tsx"\n)',
                '  "src/components/MessageFallbackPanel.tsx"\n' + lf + '\n)'
            )
        else:
            src += f'\n# master marker file {lf}\n'

markers = [
    '  "src/maurimesh/pixel-calling/PixelCallingBackupFallback.ts:createPixelCallingFallbackBackupOrder"',
    '  "src/maurimesh/pixel-calling/PixelCallingBackupFallback.ts:decidePixelCallingBackupFallback"',
    '  "src/maurimesh/pixel-calling/PixelCallingBackupTypes.ts:PUSH_TO_TALK_BACKUP"',
    '  "src/maurimesh/pixel-calling/PixelCallingBackupTypes.ts:VOICE_NOTE_BACKUP"',
    '  "src/maurimesh/pixel-calling/PixelCallingBackupTypes.ts:STORE_FORWARD_BACKUP"',
]

for marker in markers:
    if marker not in src:
        if '  "src/maurimesh/message-fallback/MessageFallbackQueue.ts:createRetryPlan"\n)' in src:
            src = src.replace(
                '  "src/maurimesh/message-fallback/MessageFallbackQueue.ts:createRetryPlan"\n)',
                '  "src/maurimesh/message-fallback/MessageFallbackQueue.ts:createRetryPlan"\n' + marker + '\n)'
            )
        else:
            src += f'\n# master marker {marker}\n'

truth = '  "src/maurimesh/pixel-calling/PixelCallingBackupFallback.ts:does not claim a live call without installed APK audio proof and strict device ACK"'
if truth not in src:
    if '  "src/maurimesh/message-fallback/MessageAckFallbackEngine.ts:does not claim real delivery until strict device ACK proof exists"\n)' in src:
        src = src.replace(
            '  "src/maurimesh/message-fallback/MessageAckFallbackEngine.ts:does not claim real delivery until strict device ACK proof exists"\n)',
            '  "src/maurimesh/message-fallback/MessageAckFallbackEngine.ts:does not claim real delivery until strict device ACK proof exists"\n' + truth + '\n)'
        )
    else:
        src += f'\n# master truth {truth}\n'

checker = 'run_checker "check-maurimesh-pixel-calling-backup-fallback.sh" "Pixel Calling Backup Fallback"'
if checker not in src:
    if 'run_checker "check-maurimesh-message-ack-fallback.sh" "Message Queue + ACK Fallback"' in src:
        src = src.replace(
            'run_checker "check-maurimesh-message-ack-fallback.sh" "Message Queue + ACK Fallback"',
            'run_checker "check-maurimesh-message-ack-fallback.sh" "Message Queue + ACK Fallback"\n'
            'run_checker "check-maurimesh-pixel-calling-backup-fallback.sh" "Pixel Calling Backup Fallback"'
        )
    else:
        src += '\n' + checker + '\n'

path.write_text(src)
PY
else
  echo "WARN: check-maurimesh-master-readiness.sh not found. Skipping master update."
fi

# ============================================================
# 8. Run checks
# ============================================================

echo ""
echo "Running TypeScript..."
npx tsc --noEmit

echo ""
echo "Running Pixel Calling Backup Fallback checker..."
./check-maurimesh-pixel-calling-backup-fallback.sh

echo ""
if [ -f "$MASTER" ]; then
  echo "Running master readiness checker..."
  ./check-maurimesh-master-readiness.sh
fi

echo ""
echo "============================================================"
echo "DONE: PIXEL CALLING BACKUP FALLBACK WIRING INSTALLED"
echo "============================================================"
echo "Backup:"
echo "  $BACKUP"
echo ""
echo "Created:"
echo "  src/maurimesh/pixel-calling/PixelCallingBackupTypes.ts"
echo "  src/maurimesh/pixel-calling/PixelCallingBackupFallback.ts"
echo "  src/components/PixelCallingBackupFallbackPanel.tsx"
echo "  app/pixel-calling-backup.tsx"
echo "  check-maurimesh-pixel-calling-backup-fallback.sh"
echo ""
echo "Reports:"
echo "  docs/maurimesh-pixel-calling-backup-fallback-report-latest.md"
echo "  docs/maurimesh-master-readiness-report-latest.md"
echo "============================================================"
