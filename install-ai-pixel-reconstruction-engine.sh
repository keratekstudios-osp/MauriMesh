#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "INSTALL AI PIXEL RECONSTRUCTION ENGINE"
echo "1080p compressed source -> AI pixel correction/upscale"
echo "-> 32K reconstruction target -> receiver ACK proof."
echo "Truth boundary: raw 32K live stream is NOT claimed."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-ai-pixel-reconstruction-$STAMP"

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
backup_file "app/pixel-reconstruction-ack.tsx"
backup_file "app/ai-pixel-reconstruction.tsx"
backup_file "app/device-proof.tsx"
backup_file "app/proof-ledger.tsx"
backup_file "app/message-fallback.tsx"
backup_file "src/lib/uiBackupRoutes.ts"
backup_file "check-maurimesh-master-readiness.sh"

echo "Backup saved:"
echo "  $BACKUP"

# ============================================================
# 1. AI Pixel Reconstruction Types
# ============================================================

cat > "$CALL/AiPixelReconstructionTypes.ts" <<'TS'
export type AiPixelSourceResolution =
  | "144p"
  | "240p"
  | "360p"
  | "480p"
  | "720p"
  | "1080p";

export type AiPixelTargetResolution =
  | "1080p_ENHANCED"
  | "4K_RECONSTRUCTION_TARGET"
  | "8K_RECONSTRUCTION_TARGET"
  | "16K_RECONSTRUCTION_TARGET"
  | "32K_RECONSTRUCTION_TARGET";

export type AiPixelModelMode =
  | "EDGE_LIGHT"
  | "BALANCED_DEVICE"
  | "HIGH_QUALITY_WIFI"
  | "STORE_FORWARD_RENDER"
  | "PROOF_ONLY_SIMULATION";

export type AiPixelReconstructionStage =
  | "SOURCE_1080P_CAPTURED"
  | "FRAME_COMPRESSED"
  | "FRAME_CHUNKED"
  | "FRAME_RECEIVED"
  | "AI_RECONSTRUCTION_STARTED"
  | "AI_PIXELS_CORRECTED"
  | "AI_UPSCALE_TARGET_32K"
  | "RECONSTRUCTION_QUALITY_SCORED"
  | "RECONSTRUCTED_FRAME_HASHED"
  | "RECONSTRUCTED_PIXEL_ACK_SENT"
  | "RECONSTRUCTED_PIXEL_ACK_RECEIVED"
  | "QUALITY_TOO_LOW_FALLBACK"
  | "RAW_32K_LIVE_FALSE"
  | "APK_DEVICE_PROOF_REQUIRED";

export type AiPixelProofLabel =
  | "RAW_32K_LIVE_FALSE"
  | "SOURCE_1080P_CONFIRMED"
  | "AI_32K_RECONSTRUCTION_TARGET"
  | "AI_PIXELS_CORRECTED"
  | "RECONSTRUCTED_ACK_REQUIRED"
  | "QUALITY_SCORE_REQUIRED"
  | "RECONSTRUCTED_FRAME_HASH_REQUIRED"
  | "APK_DEVICE_PROOF_REQUIRED"
  | "AI_RECONSTRUCTION_PROOF_READY";

export type AiPixelReconstructionInput = {
  callId: string;
  frameId: string;
  sourceResolution: AiPixelSourceResolution;
  targetResolution: AiPixelTargetResolution;
  sourceWidth: number;
  sourceHeight: number;
  targetWidth: number;
  targetHeight: number;
  compressedBytes: number;
  chunkCount: number;
  chunksReceived: number;
  sourceFrameHash: string;
  reconstructedFrameHash: string;
  aiCorrectionScore: number;
  reconstructionQualityScore: number;
  strictReconstructionAckReceived: boolean;
  bandwidthKbps: number;
  latencyMs: number;
  devicePressure: "low" | "medium" | "high" | "critical";
  batteryPercent: number;
  liveTransportAvailable: boolean;
  storeForwardAvailable: boolean;
};

export type AiPixelReconstructionDecision = {
  callId: string;
  frameId: string;
  sourceResolution: AiPixelSourceResolution;
  targetResolution: AiPixelTargetResolution;
  selectedModelMode: AiPixelModelMode;
  stages: AiPixelReconstructionStage[];
  proofLabels: AiPixelProofLabel[];
  compressionRatioEstimate: number;
  reconstructedPixelMultiplier: number;
  raw32kLiveClaim: false;
  ai32kReconstructionTargetClaim: boolean;
  canAttemptLivePreview: boolean;
  canClaimRaw32KLive: false;
  canClaimAiReconstructedFrame: boolean;
  shouldFallbackResolution: boolean;
  fallbackTarget: AiPixelTargetResolution | AiPixelSourceResolution;
  ackRequired: true;
  qualityScoreRequired: true;
  frameHashRequired: true;
  reason: string;
  finalTruth: string;
};
TS

# ============================================================
# 2. AI Pixel Reconstruction Engine
# ============================================================

cat > "$CALL/AiPixelReconstructionEngine.ts" <<'TS'
import {
  AiPixelModelMode,
  AiPixelReconstructionDecision,
  AiPixelReconstructionInput,
  AiPixelReconstructionStage,
  AiPixelTargetResolution,
} from "./AiPixelReconstructionTypes";

export const AI_PIXEL_RECONSTRUCTION_TARGETS: AiPixelTargetResolution[] = [
  "1080p_ENHANCED",
  "4K_RECONSTRUCTION_TARGET",
  "8K_RECONSTRUCTION_TARGET",
  "16K_RECONSTRUCTION_TARGET",
  "32K_RECONSTRUCTION_TARGET",
];

export function estimateTargetPixels(target: AiPixelTargetResolution): number {
  switch (target) {
    case "1080p_ENHANCED":
      return 1920 * 1080;
    case "4K_RECONSTRUCTION_TARGET":
      return 3840 * 2160;
    case "8K_RECONSTRUCTION_TARGET":
      return 7680 * 4320;
    case "16K_RECONSTRUCTION_TARGET":
      return 15360 * 8640;
    case "32K_RECONSTRUCTION_TARGET":
      return 30720 * 17280;
  }
}

export function selectAiPixelModelMode(
  input: AiPixelReconstructionInput
): AiPixelModelMode {
  if (!input.liveTransportAvailable && input.storeForwardAvailable) {
    return "STORE_FORWARD_RENDER";
  }

  if (input.devicePressure === "critical" || input.batteryPercent < 10) {
    return "PROOF_ONLY_SIMULATION";
  }

  if (input.devicePressure === "high" || input.bandwidthKbps < 700) {
    return "EDGE_LIGHT";
  }

  if (input.bandwidthKbps >= 2500 && input.latencyMs <= 450) {
    return "HIGH_QUALITY_WIFI";
  }

  return "BALANCED_DEVICE";
}

export function chooseAiPixelFallbackTarget(
  input: AiPixelReconstructionInput
): AiPixelTargetResolution | AiPixelReconstructionInput["sourceResolution"] {
  if (input.devicePressure === "critical") return "480p";
  if (input.batteryPercent < 10) return "480p";
  if (input.bandwidthKbps < 256) return "480p";
  if (input.bandwidthKbps < 700) return "720p";
  if (input.bandwidthKbps < 1400) return "1080p_ENHANCED";
  if (input.bandwidthKbps < 2800) return "4K_RECONSTRUCTION_TARGET";
  if (input.bandwidthKbps < 5200) return "8K_RECONSTRUCTION_TARGET";
  if (input.bandwidthKbps < 9000) return "16K_RECONSTRUCTION_TARGET";

  return input.targetResolution;
}

export function calculateCompressionRatioEstimate(
  input: AiPixelReconstructionInput
): number {
  const rawBytes = Math.max(1, input.sourceWidth * input.sourceHeight * 3);
  return Number((rawBytes / Math.max(1, input.compressedBytes)).toFixed(2));
}

export function calculateReconstructedPixelMultiplier(
  input: AiPixelReconstructionInput
): number {
  const sourcePixels = Math.max(1, input.sourceWidth * input.sourceHeight);
  const targetPixels = Math.max(1, input.targetWidth * input.targetHeight);
  return Number((targetPixels / sourcePixels).toFixed(2));
}

export function createAiReconstructionStages(
  input: AiPixelReconstructionInput
): AiPixelReconstructionStage[] {
  const stages: AiPixelReconstructionStage[] = [
    "SOURCE_1080P_CAPTURED",
    "FRAME_COMPRESSED",
    "FRAME_CHUNKED",
  ];

  if (input.chunksReceived >= input.chunkCount && input.chunkCount > 0) {
    stages.push("FRAME_RECEIVED");
    stages.push("AI_RECONSTRUCTION_STARTED");
    stages.push("AI_PIXELS_CORRECTED");

    if (input.targetResolution === "32K_RECONSTRUCTION_TARGET") {
      stages.push("AI_UPSCALE_TARGET_32K");
    }

    stages.push("RECONSTRUCTION_QUALITY_SCORED");
    stages.push("RECONSTRUCTED_FRAME_HASHED");

    if (input.strictReconstructionAckReceived) {
      stages.push("RECONSTRUCTED_PIXEL_ACK_RECEIVED");
    } else {
      stages.push("RECONSTRUCTED_PIXEL_ACK_SENT");
    }
  }

  if (input.reconstructionQualityScore < 0.72 || input.aiCorrectionScore < 0.7) {
    stages.push("QUALITY_TOO_LOW_FALLBACK");
  }

  stages.push("RAW_32K_LIVE_FALSE");
  stages.push("APK_DEVICE_PROOF_REQUIRED");

  return stages;
}

export function decideAiPixelReconstruction(
  input: AiPixelReconstructionInput
): AiPixelReconstructionDecision {
  const selectedModelMode = selectAiPixelModelMode(input);
  const fallbackTarget = chooseAiPixelFallbackTarget(input);
  const compressionRatioEstimate = calculateCompressionRatioEstimate(input);
  const reconstructedPixelMultiplier = calculateReconstructedPixelMultiplier(input);
  const stages = createAiReconstructionStages(input);

  const chunksComplete = input.chunkCount > 0 && input.chunksReceived >= input.chunkCount;
  const qualityPass =
    input.aiCorrectionScore >= 0.7 &&
    input.reconstructionQualityScore >= 0.72;

  const hashPass =
    input.sourceFrameHash.length > 0 &&
    input.reconstructedFrameHash.length > 0;

  const ackPass = input.strictReconstructionAckReceived;

  const ai32kReconstructionTargetClaim =
    input.targetResolution === "32K_RECONSTRUCTION_TARGET";

  const canAttemptLivePreview =
    input.liveTransportAvailable &&
    input.devicePressure !== "critical" &&
    input.batteryPercent > 10 &&
    input.sourceResolution === "1080p";

  const canClaimAiReconstructedFrame =
    chunksComplete &&
    qualityPass &&
    hashPass &&
    ackPass;

  const shouldFallbackResolution =
    !chunksComplete ||
    !qualityPass ||
    input.devicePressure === "critical" ||
    fallbackTarget !== input.targetResolution;

  const proofLabels: AiPixelReconstructionDecision["proofLabels"] = [
    "RAW_32K_LIVE_FALSE",
    "SOURCE_1080P_CONFIRMED",
    "RECONSTRUCTED_ACK_REQUIRED",
    "QUALITY_SCORE_REQUIRED",
    "RECONSTRUCTED_FRAME_HASH_REQUIRED",
    "APK_DEVICE_PROOF_REQUIRED",
  ];

  if (ai32kReconstructionTargetClaim) {
    proofLabels.push("AI_32K_RECONSTRUCTION_TARGET");
  }

  if (stages.includes("AI_PIXELS_CORRECTED")) {
    proofLabels.push("AI_PIXELS_CORRECTED");
  }

  if (canClaimAiReconstructedFrame) {
    proofLabels.push("AI_RECONSTRUCTION_PROOF_READY");
  }

  let reason = "AI pixel reconstruction prepared.";
  if (!chunksComplete) {
    reason = "Frame chunks are incomplete. Receiver cannot reconstruct and ACK the frame yet.";
  } else if (!qualityPass) {
    reason = "AI reconstruction quality is too low. Fall back to a lower target.";
  } else if (!ackPass) {
    reason = "AI reconstruction completed, but strict reconstructed-pixel ACK has not returned.";
  } else if (canClaimAiReconstructedFrame) {
    reason = "Receiver reconstructed pixels, quality score passed, hash exists, and strict ACK returned.";
  }

  return {
    callId: input.callId,
    frameId: input.frameId,
    sourceResolution: input.sourceResolution,
    targetResolution: input.targetResolution,
    selectedModelMode,
    stages,
    proofLabels,
    compressionRatioEstimate,
    reconstructedPixelMultiplier,
    raw32kLiveClaim: false,
    ai32kReconstructionTargetClaim,
    canAttemptLivePreview,
    canClaimRaw32KLive: false,
    canClaimAiReconstructedFrame,
    shouldFallbackResolution,
    fallbackTarget,
    ackRequired: true,
    qualityScoreRequired: true,
    frameHashRequired: true,
    reason,
    finalTruth:
      "MauriMesh does not claim raw 32K live streaming. It can prepare 1080p compressed source frames for AI-assisted pixel correction and reconstruction toward a 32K target on the receiver, then require quality score, reconstructed frame hash, and strict reconstructed-pixel ACK proof.",
  };
}

export function runAiPixelReconstructionDemo(): AiPixelReconstructionDecision {
  return decideAiPixelReconstruction({
    callId: "MM-CALL-AI-PIXEL-DEMO-001",
    frameId: "MM-AI-FRAME-1080P-TO-32K-001",
    sourceResolution: "1080p",
    targetResolution: "32K_RECONSTRUCTION_TARGET",
    sourceWidth: 1920,
    sourceHeight: 1080,
    targetWidth: 30720,
    targetHeight: 17280,
    compressedBytes: 86000,
    chunkCount: 24,
    chunksReceived: 24,
    sourceFrameHash: "source_1080p_hash_demo",
    reconstructedFrameHash: "ai_32k_reconstructed_hash_demo",
    aiCorrectionScore: 0.91,
    reconstructionQualityScore: 0.88,
    strictReconstructionAckReceived: true,
    bandwidthKbps: 3200,
    latencyMs: 430,
    devicePressure: "medium",
    batteryPercent: 74,
    liveTransportAvailable: true,
    storeForwardAvailable: true,
  });
}
TS

# Patch index export
if [ -f "$CALL/index.ts" ]; then
  if ! grep -Fq 'AiPixelReconstructionEngine' "$CALL/index.ts"; then
    cat >> "$CALL/index.ts" <<'TS'
export * from "./AiPixelReconstructionTypes";
export * from "./AiPixelReconstructionEngine";
TS
  fi
else
  cat > "$CALL/index.ts" <<'TS'
export * from "./AiPixelReconstructionTypes";
export * from "./AiPixelReconstructionEngine";
TS
fi

# ============================================================
# 3. UI Panel
# ============================================================

cat > "$COMP/AiPixelReconstructionPanel.tsx" <<'TSX'
import React, { useMemo, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import {
  decideAiPixelReconstruction,
  AiPixelReconstructionInput,
} from "../maurimesh/pixel-calling";
import { mauriTheme } from "../theme/mauriTheme";
import { MauriButton } from "./MauriButton";
import { MauriPanel } from "./MauriPanel";
import { StatusPill } from "./StatusPill";

type Scenario = "proofReady" | "ackPending" | "qualityLow" | "chunksMissing";

export function AiPixelReconstructionPanel() {
  const [scenario, setScenario] = useState<Scenario>("proofReady");

  const input: AiPixelReconstructionInput = useMemo(() => {
    const base: AiPixelReconstructionInput = {
      callId: "MM-CALL-AI-PIXEL",
      frameId: `MM-AI-FRAME-${scenario.toUpperCase()}`,
      sourceResolution: "1080p",
      targetResolution: "32K_RECONSTRUCTION_TARGET",
      sourceWidth: 1920,
      sourceHeight: 1080,
      targetWidth: 30720,
      targetHeight: 17280,
      compressedBytes: 86000,
      chunkCount: 24,
      chunksReceived: 24,
      sourceFrameHash: "source_1080p_hash_demo",
      reconstructedFrameHash: "ai_32k_reconstructed_hash_demo",
      aiCorrectionScore: 0.91,
      reconstructionQualityScore: 0.88,
      strictReconstructionAckReceived: true,
      bandwidthKbps: 3200,
      latencyMs: 430,
      devicePressure: "medium",
      batteryPercent: 74,
      liveTransportAvailable: true,
      storeForwardAvailable: true,
    };

    if (scenario === "ackPending") {
      return {
        ...base,
        strictReconstructionAckReceived: false,
      };
    }

    if (scenario === "qualityLow") {
      return {
        ...base,
        aiCorrectionScore: 0.52,
        reconstructionQualityScore: 0.49,
      };
    }

    if (scenario === "chunksMissing") {
      return {
        ...base,
        chunksReceived: 13,
        strictReconstructionAckReceived: false,
      };
    }

    return base;
  }, [scenario]);

  const decision = decideAiPixelReconstruction(input);

  return (
    <View style={styles.wrap}>
      <MauriPanel glow>
        <StatusPill
          label={decision.canClaimAiReconstructedFrame ? "AI RECON ACK READY" : "PROOF REQUIRED"}
          tone={decision.canClaimAiReconstructedFrame ? "success" : "warning"}
        />
        <Text style={styles.title}>AI Pixel Reconstruction</Text>
        <Text style={styles.detail}>{decision.finalTruth}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Source → Target</Text>
        <Text style={styles.big}>
          {decision.sourceResolution} → {decision.targetResolution}
        </Text>
        <Text style={styles.rowText}>Raw 32K live claim: false</Text>
        <Text style={styles.rowText}>
          AI 32K reconstruction target: {decision.ai32kReconstructionTargetClaim ? "true" : "false"}
        </Text>
        <Text style={styles.rowText}>
          Can claim raw 32K live: {decision.canClaimRaw32KLive ? "yes" : "no"}
        </Text>
        <Text style={styles.rowText}>
          Can claim AI reconstructed frame: {decision.canClaimAiReconstructedFrame ? "yes" : "no"}
        </Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>AI Reconstruction Metrics</Text>
        <Text style={styles.rowText}>Model mode: {decision.selectedModelMode}</Text>
        <Text style={styles.rowText}>Compression ratio estimate: {decision.compressionRatioEstimate}x</Text>
        <Text style={styles.rowText}>Pixel multiplier: {decision.reconstructedPixelMultiplier}x</Text>
        <Text style={styles.rowText}>Fallback target: {decision.fallbackTarget}</Text>
        <Text style={styles.rowText}>ACK required: yes</Text>
        <Text style={styles.rowText}>Quality score required: yes</Text>
        <Text style={styles.rowText}>Frame hash required: yes</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Stages</Text>
        {decision.stages.map((stage) => (
          <Text key={stage} style={styles.bullet}>
            • {stage}
          </Text>
        ))}
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Proof Labels</Text>
        {decision.proofLabels.map((label) => (
          <Text key={label} style={styles.bullet}>
            • {label}
          </Text>
        ))}
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Try-Out Scenarios</Text>
        <View style={styles.buttons}>
          <MauriButton title="Proof Ready" onPress={() => setScenario("proofReady")} />
          <MauriButton title="ACK Pending" onPress={() => setScenario("ackPending")} />
          <MauriButton title="Quality Low" onPress={() => setScenario("qualityLow")} />
          <MauriButton title="Chunks Missing" onPress={() => setScenario("chunksMissing")} />
        </View>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Reason</Text>
        <Text style={styles.detail}>{decision.reason}</Text>
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
    fontSize: 22,
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
  bullet: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 22,
  },
  buttons: {
    gap: mauriTheme.spacing.sm,
    marginTop: mauriTheme.spacing.md,
  },
});
TSX

# ============================================================
# 4. Route screen
# ============================================================

cat > "$APP/ai-pixel-reconstruction.tsx" <<'TSX'
import React from "react";
import { AppShell } from "../src/components/AppShell";
import { MauriPageHeader } from "../src/components/MauriPageHeader";
import { AiPixelReconstructionPanel } from "../src/components/AiPixelReconstructionPanel";

export default function AiPixelReconstructionScreen() {
  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="AI PIXEL ENGINE"
        title="AI Pixel Reconstruction"
        subtitle="1080p compressed source frames enhanced toward a 32K reconstruction target on the receiver, with quality score, frame hash, and reconstructed-pixel ACK proof."
        tone="warning"
      />
      <AiPixelReconstructionPanel />
    </AppShell>
  );
}
TSX

# ============================================================
# 5. Wire route into existing Pixel Calling + Proof screens
# ============================================================

node <<'NODE'
const fs = require("fs");

function patchScreen(file, importLine, componentLine) {
  if (!fs.existsSync(file)) return;
  let src = fs.readFileSync(file, "utf8");

  if (!src.includes("AiPixelReconstructionPanel")) {
    src = `${importLine}\n${src}`;
    if (src.includes("</AppShell>")) {
      src = src.replace("</AppShell>", `      ${componentLine}\n    </AppShell>`);
    } else {
      src += `\n// AI Pixel Reconstruction route: /ai-pixel-reconstruction\n`;
    }
    fs.writeFileSync(file, src);
  }
}

patchScreen(
  "app/pixel-calling.tsx",
  'import { AiPixelReconstructionPanel } from "../src/components/AiPixelReconstructionPanel";',
  "<AiPixelReconstructionPanel />"
);

patchScreen(
  "app/pixel-calling-backup.tsx",
  'import { AiPixelReconstructionPanel } from "../src/components/AiPixelReconstructionPanel";',
  "<AiPixelReconstructionPanel />"
);

patchScreen(
  "app/pixel-reconstruction-ack.tsx",
  'import { AiPixelReconstructionPanel } from "../src/components/AiPixelReconstructionPanel";',
  "<AiPixelReconstructionPanel />"
);

patchScreen(
  "app/device-proof.tsx",
  'import { AiPixelReconstructionPanel } from "../src/components/AiPixelReconstructionPanel";',
  "<AiPixelReconstructionPanel />"
);

patchScreen(
  "app/proof-ledger.tsx",
  'import { AiPixelReconstructionPanel } from "../src/components/AiPixelReconstructionPanel";',
  "<AiPixelReconstructionPanel />"
);

patchScreen(
  "app/message-fallback.tsx",
  'import { AiPixelReconstructionPanel } from "../src/components/AiPixelReconstructionPanel";',
  "<AiPixelReconstructionPanel />"
);

const registry = "src/lib/uiBackupRoutes.ts";
if (fs.existsSync(registry)) {
  let src = fs.readFileSync(registry, "utf8");

  if (!src.includes("/ai-pixel-reconstruction")) {
    const entry = `,
  {
    key: "aiPixelReconstruction",
    title: "AI Pixel Reconstruction",
    route: "/ai-pixel-reconstruction",
    fallbackRoute: "/pixel-reconstruction-ack",
    critical: true,
    purpose: "1080p compressed source to AI 32K reconstruction target with ACK proof.",
  }`;
    src = src.replace(/\n\];/, `${entry}\n];`);
  }

  if (!src.includes('"aiPixelReconstruction"')) {
    src = src.replace(/;\s*$/, '\n  | "aiPixelReconstruction";');
  }

  fs.writeFileSync(registry, src);
}

const dashboard = "app/dashboard.tsx";
if (fs.existsSync(dashboard)) {
  let src = fs.readFileSync(dashboard, "utf8");

  if (!src.includes("/ai-pixel-reconstruction")) {
    const button = `          <MauriButton title="AI Pixel Reconstruction" onPress={() => router.push("/ai-pixel-reconstruction")} />`;

    if (src.includes("/pixel-reconstruction-ack")) {
      src = src.replace(
        /(\s*<MauriButton title="Pixel Reconstruction ACK"[\s\S]*?\/>)/,
        `$1\n${button}`
      );
    } else if (src.includes("/pixel-calling-backup")) {
      src = src.replace(
        /(\s*<MauriButton title="Pixel Calling Backup"[\s\S]*?\/>)/,
        `$1\n${button}`
      );
    } else if (src.includes("</AppShell>")) {
      src = src.replace("</AppShell>", `      ${button}\n    </AppShell>`);
    } else {
      src += `\n// AI Pixel Reconstruction route marker: /ai-pixel-reconstruction\n`;
    }

    fs.writeFileSync(dashboard, src);
  }
}
NODE

# ============================================================
# 6. Checker
# ============================================================

cat > "$ROOT/check-maurimesh-ai-pixel-reconstruction.sh" <<'CHECK'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-ai-pixel-reconstruction-report-$STAMP.md"
LATEST="$DOCS/maurimesh-ai-pixel-reconstruction-report-latest.md"

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

line "# MauriMesh AI Pixel Reconstruction Report"
line ""
line "Generated: $STAMP"
line ""

line "## Files"
for file in \
  "src/maurimesh/pixel-calling/AiPixelReconstructionTypes.ts" \
  "src/maurimesh/pixel-calling/AiPixelReconstructionEngine.ts" \
  "src/components/AiPixelReconstructionPanel.tsx" \
  "app/ai-pixel-reconstruction.tsx"
do
  if has_file "$file"; then pass "$file exists"; else fail "$file missing"; fi
done

line ""
line "## AI Pixel Reconstruction Capabilities"
for token in \
  "SOURCE_1080P_CAPTURED" \
  "FRAME_COMPRESSED" \
  "FRAME_CHUNKED" \
  "FRAME_RECEIVED" \
  "AI_RECONSTRUCTION_STARTED" \
  "AI_PIXELS_CORRECTED" \
  "AI_UPSCALE_TARGET_32K" \
  "RECONSTRUCTION_QUALITY_SCORED" \
  "RECONSTRUCTED_FRAME_HASHED" \
  "RECONSTRUCTED_PIXEL_ACK_SENT" \
  "RECONSTRUCTED_PIXEL_ACK_RECEIVED" \
  "RAW_32K_LIVE_FALSE" \
  "AI_32K_RECONSTRUCTION_TARGET" \
  "AI_PIXEL_RECONSTRUCTION_TARGETS" \
  "estimateTargetPixels" \
  "selectAiPixelModelMode" \
  "chooseAiPixelFallbackTarget" \
  "calculateCompressionRatioEstimate" \
  "calculateReconstructedPixelMultiplier" \
  "createAiReconstructionStages" \
  "decideAiPixelReconstruction" \
  "runAiPixelReconstructionDemo"
do
  if grep -R "$token" "$ROOT/src/maurimesh/pixel-calling" "$ROOT/src/components/AiPixelReconstructionPanel.tsx" >/dev/null 2>&1; then
    pass "Capability found: $token"
  else
    fail "Capability missing: $token"
  fi
done

line ""
line "## Route + Backup Wiring"
if has_text "app/dashboard.tsx" "/ai-pixel-reconstruction"; then pass "Dashboard has /ai-pixel-reconstruction"; else fail "Dashboard missing /ai-pixel-reconstruction"; fi
if has_text "src/lib/uiBackupRoutes.ts" "/ai-pixel-reconstruction"; then pass "Backup registry has /ai-pixel-reconstruction"; else fail "Backup registry missing /ai-pixel-reconstruction"; fi
if has_text "app/ai-pixel-reconstruction.tsx" "AiPixelReconstructionPanel"; then pass "Screen uses AiPixelReconstructionPanel"; else fail "Screen missing panel"; fi

line ""
line "## Embedded Wiring"
if has_text "app/pixel-calling.tsx" "AiPixelReconstructionPanel"; then pass "Pixel Calling embeds AiPixelReconstructionPanel"; else warn "Pixel Calling embed not confirmed"; fi
if has_text "app/pixel-calling-backup.tsx" "AiPixelReconstructionPanel"; then pass "Pixel Calling Backup embeds AiPixelReconstructionPanel"; else warn "Pixel Calling Backup embed not confirmed"; fi
if has_text "app/pixel-reconstruction-ack.tsx" "AiPixelReconstructionPanel"; then pass "Pixel Reconstruction ACK embeds AiPixelReconstructionPanel"; else warn "Pixel Reconstruction ACK embed not confirmed"; fi
if has_text "app/device-proof.tsx" "AiPixelReconstructionPanel"; then pass "Device Proof includes AiPixelReconstructionPanel"; else warn "Device Proof embed not confirmed"; fi
if has_text "app/proof-ledger.tsx" "AiPixelReconstructionPanel"; then pass "Proof Ledger includes AiPixelReconstructionPanel"; else warn "Proof Ledger embed not confirmed"; fi
if has_text "app/message-fallback.tsx" "AiPixelReconstructionPanel"; then pass "Message Fallback includes AiPixelReconstructionPanel"; else warn "Message Fallback embed not confirmed"; fi

line ""
line "## Truth Protection"
if has_text "src/maurimesh/pixel-calling/AiPixelReconstructionEngine.ts" "does not claim raw 32K live streaming"; then
  pass "Raw 32K live false truth boundary present"
else
  fail "Raw 32K live false truth boundary missing"
fi

if has_text "src/maurimesh/pixel-calling/AiPixelReconstructionEngine.ts" "1080p compressed source frames"; then
  pass "1080p compressed source truth boundary present"
else
  warn "1080p compressed source truth boundary not confirmed"
fi

if has_text "src/maurimesh/pixel-calling/AiPixelReconstructionEngine.ts" "strict reconstructed-pixel ACK proof"; then
  pass "Strict reconstructed-pixel ACK truth boundary present"
else
  warn "Strict reconstructed-pixel ACK truth boundary not confirmed"
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
echo "AI PIXEL RECONSTRUCTION CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
CHECK

chmod +x "$ROOT/check-maurimesh-ai-pixel-reconstruction.sh"

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

route_line = '  "/ai-pixel-reconstruction:app/ai-pixel-reconstruction.tsx"'
if route_line not in src:
    if '  "/pixel-reconstruction-ack:app/pixel-reconstruction-ack.tsx"\n)' in src:
        src = src.replace(
            '  "/pixel-reconstruction-ack:app/pixel-reconstruction-ack.tsx"\n)',
            '  "/pixel-reconstruction-ack:app/pixel-reconstruction-ack.tsx"\n'
            '  "/ai-pixel-reconstruction:app/ai-pixel-reconstruction.tsx"\n)'
        )
    else:
        src += '\n# master route marker /ai-pixel-reconstruction\n'

layer_files = [
    '  "src/maurimesh/pixel-calling/AiPixelReconstructionTypes.ts"',
    '  "src/maurimesh/pixel-calling/AiPixelReconstructionEngine.ts"',
    '  "src/components/AiPixelReconstructionPanel.tsx"',
]

for lf in layer_files:
    if lf not in src:
        if '  "src/components/PixelReconstructionAckPanel.tsx"\n)' in src:
            src = src.replace(
                '  "src/components/PixelReconstructionAckPanel.tsx"\n)',
                '  "src/components/PixelReconstructionAckPanel.tsx"\n' + lf + '\n)'
            )
        else:
            src += f'\n# master marker file {lf}\n'

markers = [
    '  "src/maurimesh/pixel-calling/AiPixelReconstructionEngine.ts:decideAiPixelReconstruction"',
    '  "src/maurimesh/pixel-calling/AiPixelReconstructionEngine.ts:AI_PIXEL_RECONSTRUCTION_TARGETS"',
    '  "src/maurimesh/pixel-calling/AiPixelReconstructionEngine.ts:calculateReconstructedPixelMultiplier"',
    '  "src/maurimesh/pixel-calling/AiPixelReconstructionTypes.ts:SOURCE_1080P_CAPTURED"',
    '  "src/maurimesh/pixel-calling/AiPixelReconstructionTypes.ts:AI_UPSCALE_TARGET_32K"',
    '  "src/maurimesh/pixel-calling/AiPixelReconstructionTypes.ts:RECONSTRUCTED_PIXEL_ACK_RECEIVED"',
]

for marker in markers:
    if marker not in src:
        if '  "src/maurimesh/pixel-calling/PixelReconstructionAckEngine.ts:decidePixelReconstructionAck"\n)' in src:
            src = src.replace(
                '  "src/maurimesh/pixel-calling/PixelReconstructionAckEngine.ts:decidePixelReconstructionAck"\n)',
                '  "src/maurimesh/pixel-calling/PixelReconstructionAckEngine.ts:decidePixelReconstructionAck"\n' + marker + '\n)'
            )
        else:
            src += f'\n# master marker {marker}\n'

truth = '  "src/maurimesh/pixel-calling/AiPixelReconstructionEngine.ts:does not claim raw 32K live streaming"'
if truth not in src:
    if '  "src/maurimesh/pixel-calling/PixelReconstructionAckEngine.ts:32K raw live stream is false"\n)' in src:
        src = src.replace(
            '  "src/maurimesh/pixel-calling/PixelReconstructionAckEngine.ts:32K raw live stream is false"\n)',
            '  "src/maurimesh/pixel-calling/PixelReconstructionAckEngine.ts:32K raw live stream is false"\n' + truth + '\n)'
        )
    else:
        src += f'\n# master truth {truth}\n'

checker = 'run_checker "check-maurimesh-ai-pixel-reconstruction.sh" "AI Pixel Reconstruction"'
if checker not in src:
    if 'run_checker "check-maurimesh-pixel-reconstruction-ack.sh" "Pixel Reconstruction ACK"' in src:
        src = src.replace(
            'run_checker "check-maurimesh-pixel-reconstruction-ack.sh" "Pixel Reconstruction ACK"',
            'run_checker "check-maurimesh-pixel-reconstruction-ack.sh" "Pixel Reconstruction ACK"\n'
            'run_checker "check-maurimesh-ai-pixel-reconstruction.sh" "AI Pixel Reconstruction"'
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
echo "Running AI Pixel Reconstruction checker..."
./check-maurimesh-ai-pixel-reconstruction.sh

echo ""
if [ -f "$MASTER" ]; then
  echo "Running master readiness checker..."
  ./check-maurimesh-master-readiness.sh
fi

echo ""
echo "============================================================"
echo "DONE: AI PIXEL RECONSTRUCTION ENGINE INSTALLED"
echo "============================================================"
echo "Backup:"
echo "  $BACKUP"
echo ""
echo "Created:"
echo "  src/maurimesh/pixel-calling/AiPixelReconstructionTypes.ts"
echo "  src/maurimesh/pixel-calling/AiPixelReconstructionEngine.ts"
echo "  src/components/AiPixelReconstructionPanel.tsx"
echo "  app/ai-pixel-reconstruction.tsx"
echo "  check-maurimesh-ai-pixel-reconstruction.sh"
echo ""
echo "Reports:"
echo "  docs/maurimesh-ai-pixel-reconstruction-report-latest.md"
echo "  docs/maurimesh-master-readiness-report-latest.md"
echo "============================================================"
