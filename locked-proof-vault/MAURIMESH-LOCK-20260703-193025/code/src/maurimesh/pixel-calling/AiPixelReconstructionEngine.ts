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
