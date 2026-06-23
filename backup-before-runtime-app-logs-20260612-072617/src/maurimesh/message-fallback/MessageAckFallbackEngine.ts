import { decideAckFallback } from "./AckFallbackEngine";
import {
  createMessageQueueRecord,
  createRetryPlan,
} from "./MessageFallbackQueue";
import {
  AckFallbackInput,
  FallbackMessagePacket,
  MessageFallbackDecision,
  MessageFallbackTransport,
} from "./MessageFallbackTypes";

export function decideMessageAckFallback(
  packet: FallbackMessagePacket,
  failedTransport: MessageFallbackTransport,
  failureReason: string,
  ackInput: AckFallbackInput
): MessageFallbackDecision {
  const retryPlan = createRetryPlan(packet.preferredTransport);
  const queueRecord = createMessageQueueRecord(
    packet,
    failedTransport,
    failureReason
  );
  const ackDecision = decideAckFallback(ackInput);

  const shouldQueue = !ackDecision.canClaimDelivered;
  const shouldRetryLater =
    shouldQueue &&
    queueRecord.state !== "OFFLINE_HOLD" &&
    retryPlan.includes("STORE_FORWARD_QUEUE");

  const shouldEscalateToOperator =
    packet.urgency === "emergency" &&
    !ackDecision.canClaimDelivered &&
    failedTransport === "OFFLINE_HOLD";

  return {
    packetId: packet.packetId,
    selectedState: ackDecision.canClaimDelivered
      ? ackDecision.deliveryState
      : queueRecord.state,
    queueRecord,
    ackDecision,
    retryPlan,
    shouldQueue,
    shouldRetryLater,
    shouldEscalateToOperator,
    finalTruth:
      "Message Queue + ACK Fallback protects delivery honesty. It queues and retries failed packets, but it does not claim real delivery until strict device ACK proof exists.",
  };
}

export function runMessageAckFallbackDemo(): MessageFallbackDecision {
  return decideMessageAckFallback(
    {
      packetId: "MM-MSG-FALLBACK-DEMO-001",
      from: "PHONE-A",
      to: "PHONE-B",
      bodyPreview: "Kia ora — fallback proof packet",
      payloadSizeBytes: 2048,
      createdAt: Date.now(),
      urgency: "high",
      requiresAck: true,
      preferredTransport: "BLE_DIRECT",
    },
    "BLE_DIRECT",
    "BLE direct send failed or peer moved out of range.",
    {
      packetId: "MM-MSG-FALLBACK-DEMO-001",
      strictAckReceived: false,
      relayAckReceived: true,
      routeObserved: true,
      elapsedMs: 14_000,
      requiresAck: true,
    }
  );
}
