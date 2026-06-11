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
