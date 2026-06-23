import {
  PixelCallDecision,
  PixelCallInput,
  PixelCallProofEvent,
  PixelCallProofStage,
  PixelCallState,
  PixelCallTransport,
} from "./PixelCallingTypes";

function proof(
  input: PixelCallInput,
  stage: PixelCallProofStage,
  state: PixelCallState,
  transport: PixelCallTransport,
  canClaimLiveCall: boolean,
  reason: string
): PixelCallProofEvent {
  return {
    id: `${input.callId}-${stage}-${Date.now()}`,
    callId: input.callId,
    stage,
    state,
    transport,
    canClaimLiveCall,
    reason,
    timestamp: Date.now(),
  };
}

export function createPixelCallFallbackOrder(
  input: PixelCallInput
): PixelCallTransport[] {
  const order: PixelCallTransport[] = [];

  if (input.bleControlAvailable) order.push("BLE_CONTROL");

  if (
    input.microphonePermission &&
    input.speakerReady &&
    input.hardwarePressure !== "critical"
  ) {
    if (input.wifiLocalAvailable) order.push("WIFI_LOCAL_AUDIO");
    if (input.wifiDirectReady) order.push("WIFI_DIRECT_READY");
    if (input.internetGatewayAvailable) order.push("INTERNET_GATEWAY_AUDIO");
  }

  order.push("PUSH_TO_TALK");
  order.push("VOICE_NOTE");
  order.push("TEXT_MESSAGE");
  order.push("STORE_FORWARD");

  if (order.length === 0) order.push("UNAVAILABLE");

  return order;
}

export function decidePixelCallingRuntime(
  input: PixelCallInput
): PixelCallDecision {
  const fallbackOrder = createPixelCallFallbackOrder(input);
  const selectedTransport = fallbackOrder[0] ?? "UNAVAILABLE";
  const proofEvents: PixelCallProofEvent[] = [];

  proofEvents.push(
    proof(
      input,
      "CALL_INVITE_CREATED",
      "CALL_RINGING",
      selectedTransport,
      false,
      "Call invite created. Live call is not proven yet."
    )
  );

  if (!input.userAccepted) {
    proofEvents.push(
      proof(
        input,
        "CALL_RINGING_PROOF",
        "CALL_RINGING",
        selectedTransport,
        false,
        "Call is ringing. Waiting for receiver acceptance."
      )
    );

    return {
      callId: input.callId,
      state: "CALL_RINGING",
      selectedTransport,
      fallbackOrder,
      canAttemptLiveCall: false,
      canClaimConnected: false,
      shouldFallback: false,
      proofEvents,
      uiTruthLabel: "TRY_OUT_READY",
      reason: "Receiver has not accepted yet. Show ringing state only.",
      finalTruth:
        "Pixel Calling is prepared for APK try-out. It cannot claim a real live call until receiver acceptance, transport readiness, and strict call ACK proof exist.",
    };
  }

  proofEvents.push(
    proof(
      input,
      "CALL_ACCEPTED_PROOF",
      "CALL_ACCEPTED",
      selectedTransport,
      false,
      "Receiver accepted call. Transport proof still required."
    )
  );

  const liveTransportReady =
    input.microphonePermission &&
    input.speakerReady &&
    input.bleControlAvailable &&
    (input.wifiLocalAvailable ||
      input.wifiDirectReady ||
      input.internetGatewayAvailable) &&
    input.hardwarePressure !== "critical" &&
    input.batteryPercent > 10;

  const strictProofReady = liveTransportReady && input.strictAckReceived;

  if (strictProofReady) {
    proofEvents.push(
      proof(
        input,
        "CALL_CONNECTED_PROOF",
        "CALL_CONNECTED",
        selectedTransport,
        true,
        "Strict ACK and live transport readiness confirmed."
      )
    );

    proofEvents.push(
      proof(
        input,
        "STREAMING_READY_PROOF",
        "STREAMING_READY",
        selectedTransport,
        true,
        "Streaming can be attempted. Real audio still requires APK/device runtime proof."
      )
    );

    return {
      callId: input.callId,
      state: "STREAMING_READY",
      selectedTransport,
      fallbackOrder,
      canAttemptLiveCall: true,
      canClaimConnected: true,
      shouldFallback: false,
      proofEvents,
      uiTruthLabel: "APK_PROOF_REQUIRED",
      reason:
        "Call is accepted and strict ACK exists. Streaming path can be attempted in APK.",
      finalTruth:
        "Pixel Calling can attempt a live call path, but real audio calling is only proven by installed APK device logs and audible two-phone test evidence.",
    };
  }

  const fallbackTransport: PixelCallTransport =
    input.relayAckReceived || input.bleControlAvailable
      ? "PUSH_TO_TALK"
      : input.microphonePermission
        ? "VOICE_NOTE"
        : "TEXT_MESSAGE";

  const fallbackState: PixelCallState =
    fallbackTransport === "PUSH_TO_TALK"
      ? "PUSH_TO_TALK_FALLBACK"
      : fallbackTransport === "VOICE_NOTE"
        ? "VOICE_NOTE_FALLBACK"
        : "TEXT_FALLBACK";

  proofEvents.push(
    proof(
      input,
      "CALL_FALLBACK_PROOF",
      fallbackState,
      fallbackTransport,
      false,
      "Strict live call proof is missing. Falling back without claiming connected call."
    )
  );

  return {
    callId: input.callId,
    state: fallbackState,
    selectedTransport: fallbackTransport,
    fallbackOrder,
    canAttemptLiveCall: liveTransportReady,
    canClaimConnected: false,
    shouldFallback: true,
    proofEvents,
    uiTruthLabel: "TRY_OUT_READY",
    reason:
      "Call can be tried, but strict ACK/live audio proof is missing. Use safe fallback path.",
    finalTruth:
      "Pixel Calling fallback protects honesty: no real connected call claim is allowed unless strict ACK and APK/device audio proof exist.",
  };
}

export function runPixelCallingDemo(): PixelCallDecision {
  return decidePixelCallingRuntime({
    callId: "MM-CALL-DEMO-001",
    from: "PHONE-A",
    to: "PHONE-B",
    microphonePermission: true,
    speakerReady: true,
    bleControlAvailable: true,
    wifiLocalAvailable: true,
    wifiDirectReady: false,
    internetGatewayAvailable: true,
    strictAckReceived: false,
    relayAckReceived: true,
    hardwarePressure: "low",
    batteryPercent: 77,
    userAccepted: true,
    timestamp: Date.now(),
  });
}
