import React, { useMemo, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import {
  decideAiPixelReconstruction,
  AiPixelReconstructionInput,
} from "../maurimesh/pixel-calling";
import { mauriTheme } from "../theme/mauriTheme";
import { MauriButton } from "./MauriButton";
import { StatusPill } from "./StatusPill";

import { MauriPanel } from "./MauriPanel";
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
