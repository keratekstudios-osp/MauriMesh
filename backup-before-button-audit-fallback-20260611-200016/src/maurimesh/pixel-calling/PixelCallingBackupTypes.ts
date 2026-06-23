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
