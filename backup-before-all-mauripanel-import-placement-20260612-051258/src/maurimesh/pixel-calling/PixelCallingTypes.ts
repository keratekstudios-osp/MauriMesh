export type PixelCallState =
  | "CALL_IDLE"
  | "CALL_RINGING"
  | "CALL_ACCEPTED"
  | "CALL_CONNECTED"
  | "STREAMING_READY"
  | "PUSH_TO_TALK_FALLBACK"
  | "VOICE_NOTE_FALLBACK"
  | "TEXT_FALLBACK"
  | "STORE_FORWARD_FALLBACK"
  | "CALL_ENDED"
  | "CALL_FAILED_SAFE";

export type PixelCallTransport =
  | "BLE_CONTROL"
  | "WIFI_LOCAL_AUDIO"
  | "WIFI_DIRECT_READY"
  | "INTERNET_GATEWAY_AUDIO"
  | "PUSH_TO_TALK"
  | "VOICE_NOTE"
  | "TEXT_MESSAGE"
  | "STORE_FORWARD"
  | "UNAVAILABLE";

export type PixelCallProofStage =
  | "CALL_INVITE_CREATED"
  | "CALL_RINGING_PROOF"
  | "CALL_ACCEPTED_PROOF"
  | "CALL_CONNECTED_PROOF"
  | "STREAMING_READY_PROOF"
  | "CALL_FALLBACK_PROOF"
  | "CALL_ENDED_PROOF"
  | "CALL_NOT_PROVEN";

export type PixelCallInput = {
  callId: string;
  from: string;
  to: string;
  microphonePermission: boolean;
  speakerReady: boolean;
  bleControlAvailable: boolean;
  wifiLocalAvailable: boolean;
  wifiDirectReady: boolean;
  internetGatewayAvailable: boolean;
  strictAckReceived: boolean;
  relayAckReceived: boolean;
  hardwarePressure: "low" | "medium" | "high" | "critical";
  batteryPercent: number;
  userAccepted: boolean;
  timestamp: number;
};

export type PixelCallProofEvent = {
  id: string;
  callId: string;
  stage: PixelCallProofStage;
  state: PixelCallState;
  transport: PixelCallTransport;
  canClaimLiveCall: boolean;
  reason: string;
  timestamp: number;
};

export type PixelCallDecision = {
  callId: string;
  state: PixelCallState;
  selectedTransport: PixelCallTransport;
  fallbackOrder: PixelCallTransport[];
  canAttemptLiveCall: boolean;
  canClaimConnected: boolean;
  shouldFallback: boolean;
  proofEvents: PixelCallProofEvent[];
  uiTruthLabel: "UI_SHELL" | "TRY_OUT_READY" | "APK_PROOF_REQUIRED" | "LIVE_CALL_PROVEN";
  reason: string;
  finalTruth: string;
};
