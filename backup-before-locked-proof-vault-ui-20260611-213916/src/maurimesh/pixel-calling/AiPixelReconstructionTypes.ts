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
