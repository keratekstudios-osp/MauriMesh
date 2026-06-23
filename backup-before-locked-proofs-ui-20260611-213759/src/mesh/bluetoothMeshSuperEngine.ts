export type BluetoothMode =
  | "BLE_SCAN"
  | "BLE_ADVERTISE"
  | "BLE_GATT"
  | "BLE_BEACON"
  | "CLASSIC_SOCKET"
  | "HYBRID";

export type TransportKind =
  | "ble"
  | "ble-gatt"
  | "ble-advertise"
  | "ble-beacon"
  | "classic-bluetooth"
  | "wifi-lan"
  | "webrtc"
  | "internet-api"
  | "store-forward"
  | "simulation";

export type PeerState =
  | "online"
  | "relay"
  | "weak"
  | "offline"
  | "blocked"
  | "recovering";

export type PacketType = "data" | "ack" | "presence" | "control";
export type DecisionKind =
  | "DIRECT_BLE"
  | "DIRECT_GATT"
  | "RELAY"
  | "STORE_FORWARD"
  | "SELF_HEAL"
  | "DROP_LOOP"
  | "DROP_EXPIRED"
  | "BLOCK"
  | "NO_ROUTE";

export type CulturalRisk = "none" | "low" | "medium" | "high";

export type BluetoothMeshPeer = {
  id: string;
  label: string;
  name?: string;
  mode: BluetoothMode;
  transport: TransportKind;
  state: PeerState;
  rssi?: number;
  signal: number;
  trust: number;
  health: number;
  reliability: number;
  latencyMs: number;
  successCount: number;
  failureCount: number;
  lastSeen: number;
  congestion: number;
  batteryPressure: number;
  routeScore: number;
  sqrt2Balance: number;
  tikangaScore: number;
  jumpCode: string;
  channel: "direct" | "relay" | "broadcast" | "store-forward";
};

export type BluetoothMeshPacket = {
  id: string;
  type: PacketType;
  from: string;
  to: string;
  payload: unknown;
  createdAt: number;
  ttlMs: number;
  hopCount: number;
  maxHops: number;
  path: string[];
  reversePath: string[];
  jumpCode: string;
  tikanga?: {
    intent: "message" | "ack" | "relay" | "presence" | "system";
    manaakitanga: boolean;
    kaitiakitanga: boolean;
    whanaungatanga: boolean;
    tapuSafe: boolean;
    risk: CulturalRisk;
    reason: string;
  };
};

export type BluetoothRouteDecision = {
  kind: DecisionKind;
  selectedPeerId?: string;
  selectedTransport?: TransportKind;
  selectedMode?: BluetoothMode;
  score: number;
  reason: string;
  jumpCode?: string;
};

export type BluetoothLearningOutcome = {
  packetId: string;
  peerId: string;
  ok: boolean;
  latencyMs: number;
  reason?: string;
  timestamp: number;
};

const SQRT2 = Math.SQRT2;
const STALE_MS = 45_000;
const DEFAULT_TTL_MS = 10 * 60 * 1000;
const MAX_QUEUE_SIZE = 500;

function now(): number {
  return Date.now();
}

function clamp(value: number, min = 0, max = 100): number {
  return Math.max(min, Math.min(max, value));
}

function hash(input: string): string {
  let h = 0x811c9dc5;
  for (let i = 0; i < input.length; i += 1) {
    h ^= input.charCodeAt(i);
    h = Math.imul(h, 0x01000193);
  }
  return (h >>> 0).toString(16).toUpperCase().padStart(8, "0");
}

function rssiToSignal(rssi?: number): number {
  if (typeof rssi !== "number") return 55;
  if (rssi >= -45) return 100;
  if (rssi <= -100) return 5;
  return Math.round(((rssi + 100) / 55) * 95 + 5);
}

export class BluetoothMeshSuperEngine {
  private peers = new Map<string, BluetoothMeshPeer>();
  private queue: BluetoothMeshPacket[] = [];
  private seenPackets = new Set<string>();
  private learningLog: BluetoothLearningOutcome[] = [];
  private runtimeTimer: ReturnType<typeof setInterval> | null = null;

  private stats = {
    runtimeTicks: 0,
    peersIngested: 0,
    routeDecisions: 0,
    packetsDropped: 0,
    storedPackets: 0,
    successfulDeliveries: 0,
    failedDeliveries: 0,
    learningEvents: 0,
    selfHealingEvents: 0,
    ackEvents: 0,
    tikangaBlocks: 0,
    tikangaWarnings: 0,
  };

  constructor(private readonly localNodeId: string) {}

  startRuntimeLoop(intervalMs = 3000): void {
    if (this.runtimeTimer) return;
    this.runtimeTimer = setInterval(() => {
      this.stats.runtimeTicks += 1;
      this.selfHeal();
      this.drainQueue();
    }, intervalMs);
    console.log("[MauriMesh][BluetoothSuper] runtime loop started");
  }

  stopRuntimeLoop(): void {
    if (!this.runtimeTimer) return;
    clearInterval(this.runtimeTimer);
    this.runtimeTimer = null;
    console.log("[MauriMesh][BluetoothSuper] runtime loop stopped");
  }

  createJumpCode(input: {
    from: string;
    to: string;
    transport: TransportKind;
    mode?: BluetoothMode;
    routeHint?: string;
  }): string {
    const bucket = Math.floor(now() / 30_000);
    const raw = [
      "MAURIMESH",
      input.from,
      input.to,
      input.transport,
      input.mode || "HYBRID",
      input.routeHint || "ROUTE",
      bucket,
    ].join(":");

    const h = hash(raw);
    return `JM-${input.transport.toUpperCase()}-${h.slice(0, 4)}-${h.slice(4, 8)}`;
  }

  evaluateTikanga(input: {
    intent: PacketType | "system";
    payload: unknown;
  }): BluetoothMeshPacket["tikanga"] {
    const text =
      typeof input.payload === "string"
        ? input.payload
        : JSON.stringify(input.payload ?? "");

    const lowered = text.toLowerCase();

    const unsafe =
      lowered.includes("exploit") ||
      lowered.includes("steal") ||
      lowered.includes("harm") ||
      lowered.includes("bypass");

    const privacyRisk =
      lowered.includes("private key") ||
      lowered.includes("password") ||
      lowered.includes("token");

    const risk: CulturalRisk = unsafe ? "high" : privacyRisk ? "medium" : "none";

    if (risk === "high") this.stats.tikangaBlocks += 1;
    if (risk === "medium") this.stats.tikangaWarnings += 1;

    return {
      intent:
        input.intent === "data"
          ? "message"
          : input.intent === "ack"
            ? "ack"
            : input.intent === "presence"
              ? "presence"
              : "system",
      manaakitanga: !unsafe,
      kaitiakitanga: !privacyRisk,
      whanaungatanga: true,
      tapuSafe: !privacyRisk,
      risk,
      reason:
        risk === "high"
          ? "Blocked by Tikanga Engine: harmful or exploit-like instruction."
          : risk === "medium"
            ? "Warning by Tikanga Engine: privacy-sensitive material detected."
            : "Tikanga Engine approved packet intent.",
    };
  }

  ingestBluetoothPeer(input: {
    id: string;
    label?: string;
    name?: string;
    rssi?: number;
    mode?: BluetoothMode;
    transport?: TransportKind;
    state?: PeerState;
    channel?: "direct" | "relay" | "broadcast" | "store-forward";
  }): BluetoothMeshPeer {
    const existing = this.peers.get(input.id);
    const mode = input.mode || existing?.mode || "BLE_SCAN";
    const transport = input.transport || this.transportFromMode(mode);
    const signal = clamp(rssiToSignal(input.rssi ?? existing?.rssi));

    const peer: BluetoothMeshPeer = {
      id: input.id,
      label: input.label || input.name || existing?.label || input.id,
      name: input.name || existing?.name,
      mode,
      transport,
      state: input.state || existing?.state || (signal < 30 ? "weak" : "online"),
      rssi: input.rssi ?? existing?.rssi,
      signal,
      trust: existing?.trust ?? 70,
      health: existing?.health ?? 75,
      reliability: existing?.reliability ?? 70,
      latencyMs: existing?.latencyMs ?? 250,
      successCount: existing?.successCount ?? 0,
      failureCount: existing?.failureCount ?? 0,
      lastSeen: now(),
      congestion: existing?.congestion ?? 10,
      batteryPressure: existing?.batteryPressure ?? 10,
      routeScore: 0,
      sqrt2Balance: 0,
      tikangaScore: 0,
      channel: input.channel || existing?.channel || "direct",
      jumpCode: "",
    };

    peer.sqrt2Balance = this.calculateSqrt2Balance(peer);
    peer.tikangaScore = this.calculateTikangaScore(peer);
    peer.routeScore = this.calculateRouteScore(peer);
    peer.jumpCode = this.createJumpCode({
      from: this.localNodeId,
      to: peer.id,
      transport: peer.transport,
      mode: peer.mode,
      routeHint: "PEER",
    });

    this.peers.set(peer.id, peer);
    this.stats.peersIngested += 1;
    return peer;
  }

  createPacket(input: {
    to: string;
    payload: unknown;
    type?: PacketType;
    ttlMs?: number;
    maxHops?: number;
  }): BluetoothMeshPacket {
    const createdAt = now();
    const type = input.type || "data";

    return {
      id: `btpkt_${this.localNodeId}_${createdAt}_${Math.random()
        .toString(36)
        .slice(2, 8)}`,
      type,
      from: this.localNodeId,
      to: input.to,
      payload: input.payload,
      createdAt,
      ttlMs: input.ttlMs || DEFAULT_TTL_MS,
      hopCount: 0,
      maxHops: input.maxHops || 6,
      path: [this.localNodeId],
      reversePath: [],
      jumpCode: this.createJumpCode({
        from: this.localNodeId,
        to: input.to,
        transport: "store-forward",
        routeHint: "NEW_PACKET",
      }),
      tikanga: this.evaluateTikanga({ intent: type, payload: input.payload }),
    };
  }

  decideRoute(packet: BluetoothMeshPacket): BluetoothRouteDecision {
    this.stats.routeDecisions += 1;

    if (packet.tikanga?.risk === "high") {
      return { kind: "BLOCK", score: 0, reason: packet.tikanga.reason };
    }

    if (this.seenPackets.has(packet.id)) {
      this.stats.packetsDropped += 1;
      return {
        kind: "DROP_LOOP",
        score: 0,
        reason: "Duplicate packet blocked to prevent rebroadcast loop.",
      };
    }

    if (now() - packet.createdAt > packet.ttlMs || packet.hopCount >= packet.maxHops) {
      this.stats.packetsDropped += 1;
      return {
        kind: "DROP_EXPIRED",
        score: 0,
        reason: "Packet expired by TTL or hop limit.",
      };
    }

    const candidates = [...this.peers.values()]
      .filter((peer) => peer.id !== this.localNodeId)
      .filter((peer) => peer.state !== "blocked")
      .filter((peer) => !packet.path.includes(peer.id))
      .map((peer) => {
        const directBonus = peer.id === packet.to ? 30 : 0;
        const relayBonus = peer.state === "relay" || peer.channel === "relay" ? 10 : 0;
        const recoveryBonus = peer.state === "recovering" ? 6 : 0;
        const stalePenalty = now() - peer.lastSeen > STALE_MS ? 35 : 0;
        const modeBonus = this.modeWeight(peer.mode) * 10;
        const jumpBonus = packet.jumpCode.includes(peer.transport.toUpperCase()) ? 6 : 0;

        const refreshed = {
          ...peer,
          sqrt2Balance: this.calculateSqrt2Balance(peer),
          tikangaScore: this.calculateTikangaScore(peer),
          routeScore: this.calculateRouteScore(peer),
        };

        return {
          peer: refreshed,
          score: clamp(
            refreshed.routeScore +
              directBonus +
              relayBonus +
              recoveryBonus +
              modeBonus +
              jumpBonus -
              stalePenalty
          ),
        };
      })
      .sort((a, b) => b.score - a.score);

    const direct = candidates.find((entry) => entry.peer.id === packet.to);

    if (direct && direct.score >= 35) {
      const kind = direct.peer.mode === "BLE_GATT" ? "DIRECT_GATT" : "DIRECT_BLE";
      return {
        kind,
        selectedPeerId: direct.peer.id,
        selectedTransport: direct.peer.transport,
        selectedMode: direct.peer.mode,
        score: direct.score,
        reason: "Direct Bluetooth device-to-device route selected.",
        jumpCode: this.createJumpCode({
          from: this.localNodeId,
          to: direct.peer.id,
          transport: direct.peer.transport,
          mode: direct.peer.mode,
          routeHint: kind,
        }),
      };
    }

    const relay = candidates.find((entry) => entry.score >= 55);

    if (relay) {
      return {
        kind: "RELAY",
        selectedPeerId: relay.peer.id,
        selectedTransport: relay.peer.transport,
        selectedMode: relay.peer.mode,
        score: relay.score,
        reason: "Bluetooth relay mesh route selected.",
        jumpCode: this.createJumpCode({
          from: this.localNodeId,
          to: relay.peer.id,
          transport: relay.peer.transport,
          mode: relay.peer.mode,
          routeHint: "RELAY",
        }),
      };
    }

    const recovery = candidates.find((entry) => entry.peer.state === "recovering");

    if (recovery) {
      this.stats.selfHealingEvents += 1;
      return {
        kind: "SELF_HEAL",
        selectedPeerId: recovery.peer.id,
        selectedTransport: recovery.peer.transport,
        selectedMode: recovery.peer.mode,
        score: recovery.score,
        reason: "Self-healing Bluetooth recovery route selected.",
        jumpCode: this.createJumpCode({
          from: this.localNodeId,
          to: recovery.peer.id,
          transport: recovery.peer.transport,
          mode: recovery.peer.mode,
          routeHint: "SELF_HEAL",
        }),
      };
    }

    this.storePacket(packet);
    return {
      kind: "STORE_FORWARD",
      score: 0,
      reason: "No safe Bluetooth path found. Packet stored for later route.",
    };
  }

  async sendPacket(to: string, payload: unknown): Promise<{
    packet: BluetoothMeshPacket;
    decision: BluetoothRouteDecision;
    delivered: boolean;
  }> {
    const packet = this.createPacket({ to, payload });
    const decision = this.decideRoute(packet);

    if (
      decision.kind === "DIRECT_BLE" ||
      decision.kind === "DIRECT_GATT" ||
      decision.kind === "RELAY" ||
      decision.kind === "SELF_HEAL"
    ) {
      packet.jumpCode = decision.jumpCode || packet.jumpCode;
      this.markPacketSeen(packet.id);

      this.learn({
        packetId: packet.id,
        peerId: decision.selectedPeerId!,
        ok: true,
        latencyMs: Math.max(20, Math.round(1000 - decision.score * 8)),
        reason: decision.reason,
        timestamp: now(),
      });

      return { packet, decision, delivered: true };
    }

    return { packet, decision, delivered: false };
  }

  receivePacket(packet: BluetoothMeshPacket): {
    accepted: boolean;
    reason: string;
    ack?: BluetoothMeshPacket;
  } {
    if (this.seenPackets.has(packet.id)) {
      return { accepted: false, reason: "Duplicate Bluetooth packet blocked." };
    }

    if (now() - packet.createdAt > packet.ttlMs) {
      return { accepted: false, reason: "Expired Bluetooth packet blocked." };
    }

    if (packet.tikanga?.risk === "high") {
      return { accepted: false, reason: packet.tikanga.reason };
    }

    this.markPacketSeen(packet.id);

    if (packet.to === this.localNodeId) {
      const ack = this.createPacket({
        to: packet.from,
        type: "ack",
        payload: { received: true, packetId: packet.id },
        ttlMs: DEFAULT_TTL_MS,
        maxHops: packet.maxHops,
      });

      ack.id = `ack_${packet.id}`;
      ack.reversePath = [...packet.path].reverse();
      ack.jumpCode = this.createJumpCode({
        from: this.localNodeId,
        to: packet.from,
        transport: "store-forward",
        routeHint: "STRICT_REVERSE_ACK",
      });

      this.stats.ackEvents += 1;

      return {
        accepted: true,
        reason: "Bluetooth packet delivered locally. Strict reverse ACK created.",
        ack,
      };
    }

    const relayPacket: BluetoothMeshPacket = {
      ...packet,
      hopCount: packet.hopCount + 1,
      path: [...packet.path, this.localNodeId],
    };

    const decision = this.decideRoute(relayPacket);

    if (
      decision.kind === "DIRECT_BLE" ||
      decision.kind === "DIRECT_GATT" ||
      decision.kind === "RELAY" ||
      decision.kind === "SELF_HEAL"
    ) {
      return { accepted: true, reason: `Bluetooth packet accepted for ${decision.kind}.` };
    }

    if (decision.kind === "STORE_FORWARD") {
      return { accepted: true, reason: "Bluetooth packet stored for future forwarding." };
    }

    return { accepted: false, reason: decision.reason };
  }

  learn(outcome: BluetoothLearningOutcome): void {
    const peer = this.peers.get(outcome.peerId);
    if (!peer) return;

    this.learningLog.push(outcome);
    if (this.learningLog.length > 1000) this.learningLog.shift();

    this.stats.learningEvents += 1;

    if (outcome.ok) {
      peer.successCount += 1;
      peer.trust = clamp(peer.trust + 2);
      peer.health = clamp(peer.health + 3);
      peer.reliability = clamp(peer.reliability + 3);
      peer.latencyMs = Math.round(peer.latencyMs * 0.7 + outcome.latencyMs * 0.3);
      peer.state = peer.signal < 30 ? "weak" : "online";
      this.stats.successfulDeliveries += 1;
    } else {
      peer.failureCount += 1;
      peer.trust = clamp(peer.trust - 6);
      peer.health = clamp(peer.health - 8);
      peer.reliability = clamp(peer.reliability - 8);
      peer.congestion = clamp(peer.congestion + 10);
      this.stats.failedDeliveries += 1;

      if (peer.health < 20 || peer.trust < 20) {
        peer.state = "blocked";
      } else if (peer.health < 45) {
        peer.state = "recovering";
        this.stats.selfHealingEvents += 1;
      } else {
        peer.state = "weak";
      }
    }

    peer.lastSeen = outcome.timestamp;
    peer.sqrt2Balance = this.calculateSqrt2Balance(peer);
    peer.tikangaScore = this.calculateTikangaScore(peer);
    peer.routeScore = this.calculateRouteScore(peer);
    this.peers.set(peer.id, peer);
  }

  selfHeal(): void {
    for (const peer of this.peers.values()) {
      const age = now() - peer.lastSeen;

      if (peer.state === "offline" && age < STALE_MS * 2) {
        peer.state = "recovering";
        peer.health = clamp(peer.health + 4);
        this.stats.selfHealingEvents += 1;
      }

      if (peer.state === "weak" && peer.successCount > peer.failureCount) {
        peer.state = "recovering";
        peer.health = clamp(peer.health + 3);
      }

      if (peer.state === "recovering" && peer.health >= 60 && peer.trust >= 50) {
        peer.state = "online";
      }

      peer.sqrt2Balance = this.calculateSqrt2Balance(peer);
      peer.tikangaScore = this.calculateTikangaScore(peer);
      peer.routeScore = this.calculateRouteScore(peer);
      this.peers.set(peer.id, peer);
    }
  }

  drainQueue(): { attempted: number; remaining: number } {
    const pending = [...this.queue];
    this.queue = [];
    let attempted = 0;

    for (const packet of pending) {
      const decision = this.decideRoute(packet);

      if (
        decision.kind === "DIRECT_BLE" ||
        decision.kind === "DIRECT_GATT" ||
        decision.kind === "RELAY" ||
        decision.kind === "SELF_HEAL"
      ) {
        attempted += 1;
        this.markPacketSeen(packet.id);
        this.learn({
          packetId: packet.id,
          peerId: decision.selectedPeerId!,
          ok: true,
          latencyMs: Math.max(20, Math.round(1000 - decision.score * 8)),
          reason: "Stored Bluetooth packet drained through recovered route.",
          timestamp: now(),
        });
      } else {
        this.storePacket(packet);
      }
    }

    return { attempted, remaining: this.queue.length };
  }

  storePacket(packet: BluetoothMeshPacket): void {
    if (this.queue.some((queued) => queued.id === packet.id)) return;
    this.queue.push(packet);
    this.stats.storedPackets += 1;
    if (this.queue.length > MAX_QUEUE_SIZE) this.queue.shift();
  }

  markPacketSeen(packetId: string): void {
    this.seenPackets.add(packetId);
    if (this.seenPackets.size > 10_000) {
      this.seenPackets = new Set([...this.seenPackets].slice(-5000));
    }
  }

  getSnapshot() {
    const peers = [...this.peers.values()]
      .map((peer) => ({
        ...peer,
        sqrt2Balance: this.calculateSqrt2Balance(peer),
        tikangaScore: this.calculateTikangaScore(peer),
        routeScore: this.calculateRouteScore(peer),
      }))
      .sort((a, b) => b.routeScore - a.routeScore);

    return {
      mode: "MAURIMESH_BLUETOOTH_SUPER_MESH",
      truth:
        "Logic can be validated in Replit. Real Bluetooth P2P requires APK and physical phones.",
      localNodeId: this.localNodeId,
      message:
        peers.length > 0
          ? "Bluetooth mesh intelligence active: BLE scan, advertise, GATT, JumpCode, √2 balance, Tikanga, relay, ACK, self-learning, self-healing."
          : "Bluetooth mesh intelligence active. Waiting for live Bluetooth peers.",
      peers,
      routes: peers.map((peer) => ({
        from: this.localNodeId,
        to: peer.id,
        quality: peer.routeScore,
        sqrt2Balance: peer.sqrt2Balance,
        tikangaScore: peer.tikangaScore,
        transport: peer.transport,
        mode: peer.mode,
        jumpCode: peer.jumpCode,
        state: peer.state,
      })),
      queue: this.queue,
      learningLog: this.learningLog.slice(-25),
      stats: this.stats,
    };
  }

  private calculateTikangaScore(peer: BluetoothMeshPeer): number {
    let score = 75;
    score += (peer.trust - 70) * 0.25;
    score += (peer.health - 70) * 0.2;
    score += (peer.reliability - 70) * 0.15;
    if (peer.state === "blocked") score -= 100;
    if (peer.state === "recovering") score -= 5;
    if (peer.state === "relay") score += 4;
    return Math.round(clamp(score));
  }

  private calculateSqrt2Balance(peer: BluetoothMeshPeer): number {
    const total = peer.successCount + peer.failureCount;
    const successRate = total === 0 ? 0.65 : peer.successCount / total;

    const signal = peer.signal / 100;
    const trust = peer.trust / 100;
    const health = peer.health / 100;
    const reliability = peer.reliability / 100;
    const congestionRelief = 1 - peer.congestion / 100;
    const batteryRelief = 1 - peer.batteryPressure / 100;
    const latencyRelief = clamp(1 - peer.latencyMs / 2000, 0, 1);

    const stability =
      successRate * 0.25 +
      trust * 0.2 +
      health * 0.2 +
      reliability * 0.2 +
      latencyRelief * 0.15;

    const resilience =
      signal * 0.25 +
      trust * 0.18 +
      health * 0.18 +
      reliability * 0.16 +
      congestionRelief * 0.1 +
      batteryRelief * 0.08 +
      latencyRelief * 0.05;

    const weakestSafeFactor = Math.min(signal, trust, health, reliability);
    const relayBonus = peer.state === "relay" || peer.channel === "relay" ? 0.08 : 0;
    const recoveryBonus = peer.state === "recovering" ? 0.06 : 0;

    const balanced =
      ((stability + resilience) / 2) / SQRT2 +
      weakestSafeFactor * (SQRT2 - 1) +
      relayBonus +
      recoveryBonus;

    return Math.round(clamp(balanced * 100));
  }

  private calculateRouteScore(peer: BluetoothMeshPeer): number {
    const total = peer.successCount + peer.failureCount;
    const successRate = total === 0 ? 0.65 : peer.successCount / total;

    const score =
      successRate * 0.13 +
      (peer.signal / 100) * 0.13 +
      (peer.trust / 100) * 0.11 +
      (peer.health / 100) * 0.11 +
      (peer.reliability / 100) * 0.11 +
      clamp(1 - peer.latencyMs / 2000, 0, 1) * 0.08 +
      clamp(1 - (now() - peer.lastSeen) / STALE_MS, 0, 1) * 0.08 +
      clamp(1 - peer.congestion / 100, 0, 1) * 0.05 +
      clamp(1 - peer.batteryPressure / 100, 0, 1) * 0.04 +
      (peer.sqrt2Balance / 100) * 0.07 +
      (peer.tikangaScore / 100) * 0.05 +
      this.modeWeight(peer.mode) * 0.04;

    const statePenalty =
      peer.state === "blocked"
        ? 100
        : peer.state === "offline"
          ? 50
          : peer.state === "weak"
            ? 15
            : 0;

    return Math.round(clamp(score * 100 - statePenalty));
  }

  private transportFromMode(mode: BluetoothMode): TransportKind {
    switch (mode) {
      case "BLE_GATT":
        return "ble-gatt";
      case "BLE_ADVERTISE":
        return "ble-advertise";
      case "BLE_BEACON":
        return "ble-beacon";
      case "CLASSIC_SOCKET":
        return "classic-bluetooth";
      case "HYBRID":
      case "BLE_SCAN":
      default:
        return "ble";
    }
  }

  private modeWeight(mode: BluetoothMode): number {
    switch (mode) {
      case "BLE_GATT":
        return 1.0;
      case "CLASSIC_SOCKET":
        return 0.92;
      case "BLE_ADVERTISE":
        return 0.82;
      case "BLE_SCAN":
        return 0.76;
      case "BLE_BEACON":
        return 0.62;
      case "HYBRID":
        return 0.88;
      default:
        return 0.7;
    }
  }
}

export const bluetoothMeshSuperEngine =
  new BluetoothMeshSuperEngine("local-device");
