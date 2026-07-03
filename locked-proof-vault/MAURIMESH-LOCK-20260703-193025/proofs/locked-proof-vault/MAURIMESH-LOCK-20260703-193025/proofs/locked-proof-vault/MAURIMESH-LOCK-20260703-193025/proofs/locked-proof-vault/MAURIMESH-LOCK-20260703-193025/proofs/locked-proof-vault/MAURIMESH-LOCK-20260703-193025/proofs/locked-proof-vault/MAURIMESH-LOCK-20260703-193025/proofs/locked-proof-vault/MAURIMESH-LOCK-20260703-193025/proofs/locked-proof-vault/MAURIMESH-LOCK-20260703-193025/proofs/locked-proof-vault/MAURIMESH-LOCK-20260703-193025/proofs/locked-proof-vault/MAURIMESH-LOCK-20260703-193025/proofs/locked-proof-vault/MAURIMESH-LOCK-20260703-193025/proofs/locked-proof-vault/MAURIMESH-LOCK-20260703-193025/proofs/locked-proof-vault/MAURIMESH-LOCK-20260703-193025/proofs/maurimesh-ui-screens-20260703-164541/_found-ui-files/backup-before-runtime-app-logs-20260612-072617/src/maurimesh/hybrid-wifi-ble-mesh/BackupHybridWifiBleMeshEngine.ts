import {
  HybridLinkState,
  HybridMeshDecision,
  HybridMeshPacket,
  HybridMeshProofEvent,
  HybridTransport,
} from "./HybridWifiBleMeshTypes";

function pressureRank(value: HybridLinkState["routePressure"]) {
  if (value === "critical") return 4;
  if (value === "high") return 3;
  if (value === "medium") return 2;
  return 1;
}

function createProofEvent(
  packetId: string,
  stage: HybridMeshProofEvent["stage"],
  transport: HybridTransport,
  status: HybridMeshProofEvent["status"],
  reason: string
): HybridMeshProofEvent {
  return {
    id: `${packetId}-${stage}-${transport}-${Date.now()}`,
    packetId,
    stage,
    transport,
    status,
    reason,
    timestamp: Date.now(),
  };
}

export function createHybridFallbackOrder(
  link: HybridLinkState
): HybridTransport[] {
  const order: HybridTransport[] = [];

  const pressure =
    Math.max(
      pressureRank(link.routePressure),
      pressureRank(link.batteryPressure),
      pressureRank(link.thermalPressure)
    );

  if (link.payloadUrgency === "emergency") {
    if (link.bleDirectAvailable) order.push("BLE_DIRECT");
    if (link.bleRelayAvailable) order.push("BLE_RELAY");
    if (link.wifiLocalAvailable) order.push("WIFI_LOCAL");
    if (link.wifiDirectAvailable) order.push("WIFI_DIRECT_READY");
    if (link.internetGatewayAvailable) order.push("INTERNET_GATEWAY");
    order.push("STORE_FORWARD");
    order.push("OFFLINE_HOLD");
    return order;
  }

  if (pressure >= 4) {
    if (link.internetGatewayAvailable) order.push("INTERNET_GATEWAY");
    order.push("STORE_FORWARD");
    order.push("OFFLINE_HOLD");
    return order;
  }

  if (pressure >= 3) {
    if (link.wifiLocalAvailable) order.push("WIFI_LOCAL");
    if (link.internetGatewayAvailable) order.push("INTERNET_GATEWAY");
    if (link.bleDirectAvailable) order.push("BLE_DIRECT");
    order.push("STORE_FORWARD");
    order.push("OFFLINE_HOLD");
    return order;
  }

  if (link.payloadSizeBytes > 128_000) {
    if (link.wifiLocalAvailable) order.push("WIFI_LOCAL");
    if (link.wifiDirectAvailable) order.push("WIFI_DIRECT_READY");
    if (link.internetGatewayAvailable) order.push("INTERNET_GATEWAY");
    if (link.bleRelayAvailable) order.push("BLE_RELAY");
    if (link.bleDirectAvailable) order.push("BLE_DIRECT");
    order.push("STORE_FORWARD");
    order.push("OFFLINE_HOLD");
    return order;
  }

  if (link.bleDirectAvailable) order.push("BLE_DIRECT");
  if (link.bleRelayAvailable) order.push("BLE_RELAY");
  if (link.wifiLocalAvailable) order.push("WIFI_LOCAL");
  if (link.wifiDirectAvailable) order.push("WIFI_DIRECT_READY");
  if (link.internetGatewayAvailable) order.push("INTERNET_GATEWAY");
  order.push("STORE_FORWARD");
  order.push("OFFLINE_HOLD");

  return order;
}

export function decideBackupHybridWifiBleRoute(
  packet: HybridMeshPacket,
  link: HybridLinkState
): HybridMeshDecision {
  const fallbackOrder = createHybridFallbackOrder(link);
  const selectedTransport = fallbackOrder[0] ?? "OFFLINE_HOLD";
  const proofEvents: HybridMeshProofEvent[] = [];

  proofEvents.push(
    createProofEvent(
      packet.packetId,
      "HYBRID_ROUTE_DECISION",
      selectedTransport,
      selectedTransport === "OFFLINE_HOLD" ? "DEFERRED" : "READY",
      `Selected ${selectedTransport} from hybrid BLE/Wi-Fi fallback order.`
    )
  );

  for (const fallback of fallbackOrder.slice(1, 5)) {
    proofEvents.push(
      createProofEvent(
        packet.packetId,
        "HYBRID_FAILOVER",
        fallback,
        "FALLBACK",
        `${fallback} available as backup path if ${selectedTransport} fails.`
      )
    );
  }

  if (fallbackOrder.includes("STORE_FORWARD")) {
    proofEvents.push(
      createProofEvent(
        packet.packetId,
        "HYBRID_STORE_FORWARD",
        "STORE_FORWARD",
        "DEFERRED",
        "Store-forward queue available if no live path is stable."
      )
    );
  }

  if (fallbackOrder.includes("INTERNET_GATEWAY")) {
    proofEvents.push(
      createProofEvent(
        packet.packetId,
        "HYBRID_GATEWAY_READY",
        "INTERNET_GATEWAY",
        "READY",
        "Internet gateway fallback can complete delivery when online path appears."
      )
    );
  }

  if (selectedTransport === "OFFLINE_HOLD") {
    proofEvents.push(
      createProofEvent(
        packet.packetId,
        "HYBRID_OFFLINE_HOLD",
        "OFFLINE_HOLD",
        "BLOCKED",
        "No active route. Packet must remain offline until a peer, relay, Wi-Fi, or gateway appears."
      )
    );
  }

  const criticalPressure =
    link.routePressure === "critical" ||
    link.batteryPressure === "critical" ||
    link.thermalPressure === "critical";

  const highTrust = link.peerTrustScore >= 80;

  const confidence = Math.max(
    35,
    Math.min(
      98,
      55 +
        (highTrust ? 15 : 0) +
        (selectedTransport === "BLE_DIRECT" ? 18 : 0) +
        (selectedTransport === "WIFI_LOCAL" ? 16 : 0) +
        (selectedTransport === "INTERNET_GATEWAY" ? 12 : 0) -
        (criticalPressure ? 25 : 0)
    )
  );

  return {
    selectedTransport,
    fallbackOrder,
    shouldStoreForward:
      selectedTransport === "STORE_FORWARD" ||
      fallbackOrder.includes("STORE_FORWARD"),
    shouldUseGateway: selectedTransport === "INTERNET_GATEWAY",
    shouldUseRelay: selectedTransport === "BLE_RELAY",
    shouldHoldOffline: selectedTransport === "OFFLINE_HOLD",
    maxHops:
      selectedTransport === "BLE_DIRECT"
        ? 1
        : selectedTransport === "BLE_RELAY"
          ? 8
          : selectedTransport === "STORE_FORWARD"
            ? 12
            : 4,
    ttlMs:
      packet.urgency === "emergency"
        ? 120_000
        : selectedTransport === "STORE_FORWARD"
          ? 86_400_000
          : 600_000,
    retryLimit:
      selectedTransport === "OFFLINE_HOLD"
        ? 0
        : criticalPressure
          ? 1
          : packet.urgency === "emergency"
            ? 5
            : 3,
    proofEvents,
    confidence,
    reason:
      `Hybrid Wi-Fi/BLE mesh selected ${selectedTransport}. ` +
      `Fallback order: ${fallbackOrder.join(" -> ")}.`,
    finalTruth:
      "Hybrid Wi-Fi/BLE Mesh is a routing and failover decision layer. It does not prove real radio delivery until an installed APK produces device TX/RX/ACK logs.",
  };
}

export function runHybridWifiBleMeshDemo(): HybridMeshDecision {
  return decideBackupHybridWifiBleRoute(
    {
      packetId: "MM-HYBRID-DEMO-001",
      from: "PHONE-A",
      to: "PHONE-B",
      createdAt: Date.now(),
      payloadSizeBytes: 4096,
      urgency: "normal",
      requiresAck: true,
    },
    {
      bleDirectAvailable: true,
      bleRelayAvailable: true,
      wifiLocalAvailable: true,
      wifiDirectAvailable: false,
      internetGatewayAvailable: true,
      peerTrustScore: 91,
      routePressure: "low",
      batteryPressure: "low",
      thermalPressure: "low",
      payloadUrgency: "normal",
      payloadSizeBytes: 4096,
      timestamp: Date.now(),
    }
  );
}
