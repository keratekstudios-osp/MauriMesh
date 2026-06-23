import {
  AckFallbackDecision,
  AckFallbackInput,
} from "./MessageFallbackTypes";

export function decideAckFallback(input: AckFallbackInput): AckFallbackDecision {
  if (!input.requiresAck) {
    return {
      ackState: "ROUTE_OBSERVED_ACK",
      deliveryState: "DELIVERED_PENDING_ACK",
      canClaimDelivered: false,
      canClaimPending: true,
      proofLabel: "ACK_NOT_REQUIRED_BUT_NOT_STRICTLY_PROVEN",
      reason:
        "Packet does not require strict ACK, but MauriMesh still avoids claiming full delivery without proof.",
    };
  }

  if (input.strictAckReceived) {
    return {
      ackState: "STRICT_ACK",
      deliveryState: "DELIVERED_WITH_STRICT_ACK",
      canClaimDelivered: true,
      canClaimPending: false,
      proofLabel: "DELIVERED_STRICT_ACK_CONFIRMED",
      reason: "Strict ACK received from destination. Delivery can be claimed.",
    };
  }

  if (input.relayAckReceived) {
    return {
      ackState: "RELAY_ACK",
      deliveryState: "DELIVERED_WITH_RELAY_ACK",
      canClaimDelivered: false,
      canClaimPending: true,
      proofLabel: "RELAY_ACK_ONLY_PENDING_DESTINATION_ACK",
      reason:
        "Relay ACK exists, but destination strict ACK is missing. Delivery remains pending proof.",
    };
  }

  if (input.routeObserved && input.elapsedMs < 120_000) {
    return {
      ackState: "DELAYED_ACK",
      deliveryState: "DELIVERY_PENDING_PROOF",
      canClaimDelivered: false,
      canClaimPending: true,
      proofLabel: "ROUTE_OBSERVED_WAITING_FOR_ACK",
      reason:
        "Route activity was observed, but ACK is delayed. Keep proof as pending rather than delivered.",
    };
  }

  return {
    ackState: "NO_ACK_YET",
    deliveryState: "DELIVERY_PENDING_PROOF",
    canClaimDelivered: false,
    canClaimPending: true,
    proofLabel: "NO_ACK_YET_DELIVERY_NOT_PROVEN",
    reason:
      "No strict ACK, no relay ACK, and no usable route confirmation. Delivery cannot be claimed.",
  };
}
