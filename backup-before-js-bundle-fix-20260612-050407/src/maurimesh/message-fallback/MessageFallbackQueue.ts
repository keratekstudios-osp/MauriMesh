import {
  FallbackMessagePacket,
  MessageFallbackTransport,
  MessageQueueRecord,
} from "./MessageFallbackTypes";

export function createRetryPlan(
  preferredTransport: MessageFallbackTransport
): MessageFallbackTransport[] {
  const base: MessageFallbackTransport[] = [
    "BLE_DIRECT",
    "BLE_RELAY",
    "WIFI_LOCAL",
    "WIFI_DIRECT_READY",
    "INTERNET_GATEWAY",
    "STORE_FORWARD_QUEUE",
    "OFFLINE_HOLD",
  ];

  return [
    preferredTransport,
    ...base.filter((transport) => transport !== preferredTransport),
  ];
}

export function createMessageQueueRecord(
  packet: FallbackMessagePacket,
  failedTransport: MessageFallbackTransport,
  reason: string,
  attemptCount = 0
): MessageQueueRecord {
  const emergency = packet.urgency === "emergency";
  const backoffMs = emergency
    ? Math.min(30_000, 2_000 * Math.max(1, attemptCount + 1))
    : Math.min(300_000, 10_000 * Math.max(1, attemptCount + 1));

  return {
    packet,
    state: failedTransport === "OFFLINE_HOLD" ? "OFFLINE_HOLD" : "QUEUED_FOR_RETRY",
    attemptCount: attemptCount + 1,
    nextRetryAt: Date.now() + backoffMs,
    lastTransportTried: failedTransport,
    fallbackReason: reason,
    queueTtlMs: emergency ? 3_600_000 : 86_400_000,
    proofHashStatus: "READY",
  };
}

export function shouldRetryQueueRecord(record: MessageQueueRecord, now = Date.now()) {
  return record.state === "QUEUED_FOR_RETRY" && now >= record.nextRetryAt;
}

export function markQueueRecordWaiting(record: MessageQueueRecord): MessageQueueRecord {
  return {
    ...record,
    state: "RETRY_WAITING",
  };
}

export function markQueueRecordProofCache(record: MessageQueueRecord): MessageQueueRecord {
  return {
    ...record,
    proofHashStatus: "FAILED_SAFE_CACHE",
    fallbackReason:
      record.fallbackReason +
      " Proof ledger write failed safely; event kept in exportable local cache.",
  };
}
