export type BleProofEventKind =
  | "tx_packet"
  | "rx_packet"
  | "ack_sent"
  | "ack_received"
  | "scan_started"
  | "scan_result"
  | "advertise_started"
  | "native_status"
  | "unknown";

export type BleProofEvent = {
  id: string;
  timestamp: string;
  kind: BleProofEventKind;
  packetId?: string;
  peerId?: string;
  transport: "BLE" | "UNKNOWN";
  source: "android_native" | "typescript_bridge" | "simulation";
  raw?: Record<string, unknown>;
  proofReady: boolean;
};

const events: BleProofEvent[] = [];

function id(): string {
  return `ble_evt_${Date.now()}_${Math.random().toString(36).slice(2)}`;
}

export function normaliseBleProofEvent(raw: Record<string, unknown>): BleProofEvent {
  const stage = String(raw.stage ?? raw.type ?? raw.event ?? "unknown").toLowerCase();

  let kind: BleProofEventKind = "unknown";
  if (stage.includes("rx_packet") || stage.includes("rx")) kind = "rx_packet";
  if (stage.includes("tx_packet") || stage.includes("tx")) kind = "tx_packet";
  if (stage.includes("ack_sent")) kind = "ack_sent";
  if (stage.includes("ack_received") || stage.includes("ack_ok")) kind = "ack_received";
  if (stage.includes("scan_started")) kind = "scan_started";
  if (stage.includes("scan_result")) kind = "scan_result";
  if (stage.includes("advertise")) kind = "advertise_started";
  if (stage.includes("status")) kind = "native_status";

  const packetId =
    typeof raw.packetId === "string"
      ? raw.packetId
      : typeof raw.packet_id === "string"
        ? raw.packet_id
        : typeof raw.rxPacketId === "string"
          ? raw.rxPacketId
          : undefined;

  const peerId =
    typeof raw.peerId === "string"
      ? raw.peerId
      : typeof raw.deviceId === "string"
        ? raw.deviceId
        : typeof raw.from === "string"
          ? raw.from
          : undefined;

  return {
    id: id(),
    timestamp: new Date().toISOString(),
    kind,
    packetId,
    peerId,
    transport: "BLE",
    source: "android_native",
    raw,
    proofReady: Boolean(packetId || kind === "scan_started" || kind === "native_status"),
  };
}

export function ingestBleProofEvent(raw: Record<string, unknown>): BleProofEvent {
  const event = normaliseBleProofEvent(raw);
  events.unshift(event);
  if (events.length > 300) events.pop();
  return event;
}

export function getBleProofEvents(): BleProofEvent[] {
  return [...events];
}

export function getBleProofSummary() {
  const all = getBleProofEvents();

  return {
    total: all.length,
    rxPackets: all.filter((event) => event.kind === "rx_packet").length,
    txPackets: all.filter((event) => event.kind === "tx_packet").length,
    ackSent: all.filter((event) => event.kind === "ack_sent").length,
    ackReceived: all.filter((event) => event.kind === "ack_received").length,
    scanEvents: all.filter((event) => event.kind === "scan_started" || event.kind === "scan_result").length,
    proofReady: all.filter((event) => event.proofReady).length,
    lastEvent: all[0] ?? null,
  };
}

export function clearBleProofEvents(): void {
  events.length = 0;
}
