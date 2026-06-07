import { useCallback, useEffect, useRef } from "react";
import {
  StoreForwardQueue,
  packetPriority,
  type MeshPacket,
} from "./maurimesh-intelligent-contract";
import { router, handleIncomingPacket, flushQueue as flushRelayQueue } from "./mesh-service";
import { useBleTransport, type BleMessage, type BlePeer } from "./useBleTransport";
import { mauriMeshBridge } from "../maurimesh-client";
import {
  startMauriMeshBlePeripheral,
  updateMauriMeshBleIdentityBeacon,
  onMauriMeshBleMessageReceived,
  onMauriMeshBleStatus,
} from "./nativeMauriMeshBle";
import { useMeshStore } from "../store/meshStore";
import type { ChatMessage } from "../store/meshStore";
import { startMeshReceiveLoop } from "./meshReceiveLoop";
import { saveMeshMessage, updateMeshMessageStatus } from "./meshMessageStore";
import {
  enqueueForDelivery,
  removeFromDeliveryQueue,
  loadDeliveryQueue,
} from "./deliveryQueue";
import {
  loadAllMetrics,
  recordSuccess,
  recordFailure,
  computeRouteScore,
  type RouteMetrics,
} from "./routeMetrics";
import { MeshDuplicateGuard } from "./MeshDuplicateGuard";
import {
  FragmentCollector,
  fragmentPacket,
  isFragmentEnvelope,
} from "./MeshFragmenter";
import type { FragmentEnvelope } from "./MeshFragmenter";
import {
  loadOrCreateCryptoIdentity,
  getCachedIdentity,
  signPacketBody,
  verifyPacketSignature,
  ReplayCache,
  KeyBindingStore,
} from "./MeshCryptoIdentity";
import type { NodeCryptoIdentity } from "./MeshCryptoIdentity";
import { loadVerifiedIdentities, recordVerifiedIdentity } from "./verifiedIdentityStore";
import { meshOfflineEngine } from "../mesh-core/MeshOfflineEngine";
import { PacketType } from "../mesh-core/types";
import { createPacket } from "../mesh-core/MeshPacket";
import type { IMeshTransport, ReceiveCallback } from "../mesh-core/MeshTransportAdapter";
import type { MeshPacket as CoreMeshPacket } from "../mesh-core/types";
import { getNodeDisplayName } from "./deviceIdentity";

// Heartbeat: directed ROUTE_BEACON ping sent to each peer every 15 s.
// Peers that have not responded (no PONG) for 30 s are evicted from the
// router registry and from the store's peer list.
const HEARTBEAT_INTERVAL_MS = 15_000;
const BEACON_STALE_MS = 30_000;

function makePacketId(): string {
  return `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
}

function simpleChecksum(str: string): string {
  let h = 0;
  for (let i = 0; i < str.length; i++) h = ((h << 5) - h + str.charCodeAt(i)) | 0;
  return (h >>> 0).toString(16);
}

function formatTime(ms: number): string {
  return new Date(ms).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
}

/**
 * Fail-closed outbound authenticity gate. ROUTE_BEACON is the sole type allowed
 * to travel unsigned (pure routing liveness); every other type MUST carry a
 * signature. A non-beacon packet missing a signature — e.g. one created during
 * the startup window before the crypto identity has loaded — is refused rather
 * than leaked unsigned (the receiver would drop it anyway). This is invoked at
 * every BLE egress point (trySendViaBle and the direct strict-ACK sends).
 */
function isOutboundAllowed(packet: MeshPacket): boolean {
  if (packet.type !== "ROUTE_BEACON" && (!packet.signature || !packet.fromPublicKey)) {
    console.log(
      `[MauriMesh][UnsignedSendBlocked] refusing to emit unsigned ${packet.type}` +
      ` packetId=${packet.packetId} — identity not ready`
    );
    return false;
  }
  return true;
}

/**
 * Outcome of verifyAndDispatch. Only "verified" carries a trusted nodeId that
 * callers may use to commit a deviceId→nodeId mapping; "beacon" (unsigned
 * ROUTE_BEACON liveness) and "dropped" must NOT update identity state.
 */
type VerifyDispatchResult =
  | { status: "verified"; nodeId: string }
  | { status: "beacon" }
  | { status: "pending" }
  | { status: "dropped" };

/** Max signed inbound packets buffered during the binding-hydration window. */
const MAX_PENDING_INBOUND = 100;

function makeBleMsg(packet: MeshPacket): BleMessage {
  return {
    packetId: packet.packetId,
    fromNodeId: packet.fromNodeId,
    toNodeId: packet.toNodeId,
    payload: JSON.stringify(packet),
    createdAt: packet.createdAt,
  };
}

/**
 * Send a single MeshPacket to one BLE device, fragmenting automatically when
 * the serialized size exceeds FRAGMENT_CHUNK_MAX characters.
 *
 * ACK packets are ALWAYS sent intact — fragmenting an ACK would break the
 * strict reverse-path guarantee because the reassembler on the next hop would
 * need all fragments before it could route the ACK onward.
 *
 * Fragment ordering within one send: sequential, abort on first failure so the
 * collector on the other side never sees a partial set that just hangs in RAM.
 *
 * Returns true only when every BLE write succeeded.
 */
async function sendOneBlePacket(
  sendTo: (deviceId: string, msg: BleMessage) => Promise<boolean>,
  deviceId: string,
  packet: MeshPacket
): Promise<boolean> {
  if (packet.type === "ACK") {
    return sendTo(deviceId, makeBleMsg(packet));
  }
  const fragments = fragmentPacket(packet);
  if (!fragments) {
    return sendTo(deviceId, makeBleMsg(packet));
  }
  console.log(
    `[MauriMesh][Fragment] splitting packetId=${packet.packetId}` +
    ` into ${fragments.length} chunks (${JSON.stringify(packet).length} chars)`
  );
  for (const frag of fragments) {
    const bleMsg: BleMessage = {
      packetId: packet.packetId,
      fromNodeId: packet.fromNodeId,
      toNodeId: packet.toNodeId,
      payload: JSON.stringify(frag),
      createdAt: packet.createdAt,
    };
    const sent = await sendTo(deviceId, bleMsg);
    if (!sent) {
      console.log(
        `[MauriMesh][Fragment] send failed at idx=${frag.fragmentIndex}` +
        `/${frag.fragmentCount - 1} packetId=${packet.packetId}`
      );
      return false;
    }
  }
  console.log(
    `[MauriMesh][Fragment] all ${fragments.length} chunks sent` +
    ` packetId=${packet.packetId}`
  );
  return true;
}

// Module-level relay dedup guard.
// Prevents this device from forwarding the same transit packet twice when BLE
// delivers duplicates (common in dense scan environments). Separate from
// router.deliveredPackets, which guards local delivery.
const relayDupGuard = new MeshDuplicateGuard(10 * 60 * 1_000);

// Module-level fragment collector.
// Accumulates incoming fragment envelopes and reassembles them into full
// MeshPackets. Reassembly happens BEFORE any routing logic — fragments are
// never relayed individually. One instance per device (one hook per node).
const fragmentCollector = new FragmentCollector();

// Send packet over BLE.
//   1. BROADCAST → all peers.
//   2. Direct peer → straight write.
//   3. No direct peer → send original to best eligible carrier (not in routePath).
//      Carrier selection uses router.selectBestRoute with routePath exclusion;
//      RSSI is the deterministic fallback.
/**
 * Attempt to deliver `packet` over BLE.
 *
 * Returns the nodeId of the peer that successfully received the packet, or
 * `false` when every attempt failed. The return is truthy/falsy so existing
 * `if (sent)` call sites continue to work without change.
 *
 * @param peerScorer  Optional RouteScore function (nodeId, rssi) → [0,1].
 *   When provided, carrier selection uses score-ranked ordering instead of
 *   the RSSI / router heuristic. Real delivery outcomes feed back into the
 *   scorer via `onSendResult`.
 * @param onSendResult  Called for every peer attempt with (peerId, success).
 *   Use to accumulate RouteMetrics without coupling this function to the store.
 */
async function trySendViaBle(
  packet: MeshPacket,
  blePeers: BlePeer[],
  sendTo: (deviceId: string, msg: BleMessage) => Promise<boolean>,
  peerScorer?: (nodeId: string, rssi: number) => number,
  onSendResult?: (peerId: string, success: boolean) => void
): Promise<string | false> {
  if (blePeers.length === 0) return false;

  // Fail-closed outbound authenticity policy enforced for every send path.
  if (!isOutboundAllowed(packet)) return false;

  if (packet.toNodeId === "BROADCAST") {
    let firstSuccessId: string | null = null;
    for (const peer of blePeers) {
      const sent = await sendOneBlePacket(sendTo, peer.deviceId, packet);
      if (sent) {
        router.recordRouteSuccess(peer.nodeId);
        onSendResult?.(peer.nodeId, true);
        if (!firstSuccessId) firstSuccessId = peer.nodeId;
      } else {
        router.recordRouteFailure(peer.nodeId);
        onSendResult?.(peer.nodeId, false);
      }
    }
    return firstSuccessId ?? false;
  }

  const directPeer = blePeers.find((p) => p.nodeId === packet.toNodeId);
  if (directPeer) {
    const sent = await sendOneBlePacket(sendTo, directPeer.deviceId, packet);
    if (sent) {
      router.recordRouteSuccess(directPeer.nodeId);
      onSendResult?.(directPeer.nodeId, true);
      return directPeer.nodeId;
    }
    router.recordRouteFailure(directPeer.nodeId);
    onSendResult?.(directPeer.nodeId, false);
  }

  if (packet.ttl <= 1) return false;

  const eligibleCarriers = blePeers.filter(
    (p) => !packet.routePath.includes(p.nodeId)
  );
  if (eligibleCarriers.length === 0) return false;

  // Carrier selection: RouteScore-ranked when scorer available, otherwise
  // fall back to router.selectBestRoute + RSSI.
  let carrier: BlePeer;
  if (peerScorer && eligibleCarriers.length > 1) {
    carrier = eligibleCarriers.reduce((best, p) =>
      peerScorer(p.nodeId, p.rssi) >= peerScorer(best.nodeId, best.rssi) ? p : best,
      eligibleCarriers[0]
    );
    console.log(
      `[MauriMesh][RouteDecision] carrier=${carrier.nodeId}` +
      ` score=${peerScorer(carrier.nodeId, carrier.rssi).toFixed(3)}`
    );
  } else {
    const route = router.selectBestRoute(packet.toNodeId, "BLE", packet.routePath);
    carrier =
      (route ? eligibleCarriers.find((p) => p.nodeId === route.nodeId) : null) ??
      eligibleCarriers.reduce((best, p) => (p.rssi > best.rssi ? p : best), eligibleCarriers[0]);
  }

  const sent = await sendOneBlePacket(sendTo, carrier.deviceId, packet);
  if (sent) {
    router.recordRouteSuccess(carrier.nodeId);
    onSendResult?.(carrier.nodeId, true);
    return carrier.nodeId;
  }
  router.recordRouteFailure(carrier.nodeId);
  onSendResult?.(carrier.nodeId, false);
  return false;
}

// ── BLE transport adapter for MeshOfflineEngine ─────────────────────────────
//
// Bridges mesh-core's IMeshTransport interface to the existing BLE send path.
// Invoked exclusively by the engine's 5 s retry timer via dispatchPacket().
//
// Packet identity and sender node:
//   All core packets are built by the caller via createPacket(myNodeId, ...)
//   before being handed to enqueuePacket(). This ensures fromNodeId is always
//   the real mesh node ID — not the random UUID produced by getOrCreateIdentity().
//
// Trust score updates:
//   • router.recordRouteSuccess/Failure — inside trySendViaBle (existing
//     router scoring, same as the direct-send path).
//   • MeshTrustEngine.recordDeliverySuccess/Failure — inside dispatchPacket()
//     which wraps every call to transport.send(), consistent with mesh-service.
//
// queueSize sync:
//   The adapter does NOT call setTransportStatus here because removal from the
//   MeshStoreForwardQueue happens AFTER this callback returns. The engine's
//   onCycleComplete hook (passed to start()) fires post-removal and performs
//   the authoritative queueSize update.

type OnRetrySuccess = (corePktId: string) => void;

class BleMeshTransportAdapter implements IMeshTransport {
  readonly name = "BLE";

  private receiveCallbacks = new Set<ReceiveCallback>();

  constructor(
    private getBlePeers: () => BlePeer[],
    private getSendTo: () => (deviceId: string, msg: BleMessage) => Promise<boolean>,
    private onRetrySuccess: OnRetrySuccess,
  ) {}

  async start(): Promise<void> {}
  async stop(): Promise<void> {}

  async send(corePkt: CoreMeshPacket): Promise<boolean> {
    const peers = this.getBlePeers();
    if (peers.length === 0) return false;

    // Reconstruct a contract MeshPacket from the core packet so that the BLE
    // receiver can parse it with its existing JSON.parse(bleMsg.payload) path.
    // corePkt.fromNodeId is already set to myNodeId by the caller.
    const contractPkt: MeshPacket = {
      packetId: corePkt.id,
      type: "CHAT_MESSAGE",
      fromNodeId: corePkt.fromNodeId,
      toNodeId: corePkt.toNodeId,
      routePath: corePkt.routePath,
      lane: "BLE",
      ttl: corePkt.ttl,
      createdAt: corePkt.createdAt,
      priority: packetPriority("CHAT_MESSAGE", corePkt.toNodeId),
      payload: corePkt.payload,
      checksum: "",
    };

    // Sign the retried packet so it satisfies the receiver's mandatory-signature
    // policy. The hook signs first-attempt packets via signOutboundPacket(); this
    // adapter runs outside the hook, so it reads the cached identity directly.
    const identity = getCachedIdentity();
    if (identity) {
      contractPkt.fromPublicKey = identity.publicKey;
      contractPkt.signature = signPacketBody(contractPkt, identity.privateKey);
    }

    const sent = await trySendViaBle(contractPkt, peers, this.getSendTo());
    if (sent) {
      this.onRetrySuccess(corePkt.id);
    }
    return !!sent;
  }

  onReceive(callback: ReceiveCallback): () => void {
    this.receiveCallbacks.add(callback);
    return () => this.receiveCallbacks.delete(callback);
  }
}

export function useMeshTransport(myNodeId: string) {
  // queue.current: fallback for READ_ACK and CALL_INVITE packets which have no
  // direct PacketType equivalent in mesh-core and are not handed to the engine.
  const queue = useRef(new StoreForwardQueue());

  // Maps core packet ID → original UI message ID (the contract packetId used
  // for store/SQLite updates). Populated BEFORE enqueuePacket() so there is
  // no window in which the retry timer could fire onRetrySuccess without a map
  // entry. Using enqueuePacket() (no immediate dispatch) guarantees the mapping
  // is always present when onRetrySuccess is first called by the 5 s timer.
  const engineToOriginalId = useRef(new Map<string, string>());

  const {
    addMessage,
    setTransportStatus,
    updateMessageStatus,
    removePeer,
    setIncomingCall,
    setRouteScore,
  } = useMeshStore();

  const blePeers = useMeshStore((s) => s.peers);
  const bleReady = useMeshStore((s) => s.transportStatus.bleReady);

  const blePeersRef = useRef<BlePeer[]>(blePeers);
  const sendToRef = useRef<(deviceId: string, msg: BleMessage) => Promise<boolean>>(
    async () => false
  );
  // Per-peer: timestamp of last received ROUTE_BEACON (PONG). Used for stale
  // detection — peers silent for >= BEACON_STALE_MS are evicted.
  const peerLastBeaconMs = useRef<Map<string, number>>(new Map());
  const prevPeersRef = useRef<BlePeer[]>([]);
  /** Persisted RouteMetrics per peer — hydrated from AsyncStorage on mount. */
  const metricsRef = useRef<Map<string, RouteMetrics>>(new Map());
  /** Tracks { peerId, sentAt } for each in-flight message id to compute ACK latency. */
  const sentAtRef = useRef<Map<string, { peerId: string; sentAt: number }>>(new Map());
  /**
   * Strict-ACK packets waiting for a specific peer to become a direct BLE contact.
   * Keyed by the required next-hop nodeId. Drained in the blePeers useEffect
   * when that exact peer appears — no rerouting to any other peer.
   */
  const strictAckQueueRef = useRef<Map<string, MeshPacket[]>>(new Map());
  /**
   * Cryptographic identity for this node — Ed25519 keypair + nodeId.
   * Loaded asynchronously on mount; null until the async load resolves.
   * Used to sign outbound CHAT and ACK packets.
   */
  const identityRef = useRef<NodeCryptoIdentity | null>(null);
  /**
   * Replay protection cache — tracks (fromNodeId, packetId) pairs for signed
   * inbound packets. Prevents the same packet from being delivered twice even
   * if it arrives via different relay paths (distinct from relayDupGuard which
   * guards relay forwarding; this guards local dispatch).
   */
  const replayCacheRef = useRef(new ReplayCache());
  /**
   * Trust-On-First-Use binding of peer nodeId → Ed25519 publicKey. Hydrated
   * from the persisted nearby-peer registry on mount and updated as new peers
   * are verified. Used to reject signed packets that reuse a known nodeId with
   * a different key (signed impersonation).
   */
  const keyBindingRef = useRef(new KeyBindingStore());

  /**
   * Trust bindings are hydrated asynchronously from durable storage on mount.
   * Until that completes, signed inbound packets are buffered rather than
   * verified, so an attacker cannot win a "first-seen" race against a not-yet
   * loaded binding (which `seed()` could never later correct). Set true once
   * hydration resolves (or fails); the buffer is then drained.
   */
  const bindingsReadyRef = useRef(false);
  /** Signed inbound packets buffered during the binding-hydration window. */
  const pendingInboundRef = useRef<MeshPacket[]>([]);

  /** Update a peer's RouteScore in the Zustand store after a metrics change. */
  function refreshScore(peerId: string): void {
    const peer = blePeersRef.current.find((p) => p.nodeId === peerId);
    const score = computeRouteScore(metricsRef.current.get(peerId), peer?.rssi ?? -80);
    setRouteScore(peerId, score);
    console.log(
      `[MauriMesh][RouteScore] refreshed peerId=${peerId} score=${score.toFixed(3)}`
    );
  }

  /** Callback passed to trySendViaBle — records outcome + refreshes score. */
  function onSendResult(peerId: string, success: boolean): void {
    const fn = success ? recordSuccess : recordFailure;
    fn(metricsRef.current, peerId, 0)
      .then(() => refreshScore(peerId))
      .catch(() => {});
  }

  /**
   * Attach fromPublicKey and signature to `packet` using the loaded identity.
   * No-op when identity has not yet loaded (packet is sent unsigned).
   * Mutates the packet in-place and returns it for fluent chaining.
   */
  function signOutboundPacket(packet: MeshPacket): MeshPacket {
    const identity = identityRef.current;
    if (!identity) {
      // Identity not loaded yet. Leave the packet unsigned; trySendViaBle is the
      // single outbound choke point and refuses to emit unsigned non-beacon
      // packets, so an unsigned packet can never reach the radio.
      console.log(
        `[MauriMesh][SignDeferred] identity not ready, ${packet.type}` +
        ` packetId=${packet.packetId} left unsigned (will be blocked at send)`
      );
      return packet;
    }
    packet.fromPublicKey = identity.publicKey;
    packet.signature = signPacketBody(packet, identity.privateKey);
    return packet;
  }

  /**
   * Verify the authenticity of an inbound packet, bind its key to the claimed
   * node identity, check the replay cache, then dispatch to routing logic.
   *
   * Security policy (enforced for every BLE-sourced packet):
   *  - ROUTE_BEACON is the ONLY type allowed unsigned — it is pure routing
   *    liveness (registers an UNKNOWN-trust node, triggers a PONG) and performs
   *    no message display, delivery-state change, or call UI.
   *  - Every other type (CHAT_MESSAGE, ACK, READ_ACK, CALL_INVITE, …) MUST be
   *    signed. Unsigned ones are dropped — authenticity is mandatory, not
   *    best-effort.
   *  - Signed packets:
   *      invalid signature                → [IdentityDrop], drop.
   *      key conflicts with bound identity → [IdentityBindingDrop], drop
   *        (a valid signature over an attacker-chosen key does NOT prove the key
   *         belongs to `fromNodeId`; the TOFU binding catches the swap).
   *      replay (fromNodeId+packetId seen) → [ReplayDrop], drop.
   *      valid + bound + fresh             → [Identity] verified, route.
   */
  function verifyAndDispatch(packet: MeshPacket): VerifyDispatchResult {
    let verifiedNodeId: string | null = null;
    if (packet.fromPublicKey && packet.signature) {
      // Trust bindings not hydrated yet: buffer (bounded) instead of verifying,
      // so a key-binding decision is never made against an empty store. Drained
      // in mount order once hydration completes. ROUTE_BEACON and unsigned
      // packets fall through to the normal logic below (they never touch
      // bindings), so liveness is unaffected during the window.
      if (!bindingsReadyRef.current) {
        if (pendingInboundRef.current.length < MAX_PENDING_INBOUND) {
          pendingInboundRef.current.push(packet);
        } else {
          console.log(
            `[MauriMesh][PendingDrop] inbound buffer full, dropping signed` +
            ` ${packet.type} packetId=${packet.packetId} during hydration`
          );
        }
        return { status: "pending" };
      }
      if (!verifyPacketSignature(packet)) {
        console.log(
          `[MauriMesh][IdentityDrop] invalid signature packetId=${packet.packetId}` +
          ` from nodeId=${packet.fromNodeId}`
        );
        return { status: "dropped" };
      }
      // Bind the signing key to the claimed nodeId (Trust-On-First-Use). A valid
      // signature only proves the sender holds the private key for the key they
      // supplied — not that the key belongs to fromNodeId. Reject any later
      // packet that reuses a known nodeId with a different key (impersonation).
      const binding = keyBindingRef.current.reconcile(
        packet.fromNodeId,
        packet.fromPublicKey
      );
      if (binding === "conflict") {
        console.log(
          `[MauriMesh][IdentityBindingDrop] nodeId=${packet.fromNodeId} presented a` +
          ` key that does not match its established identity packetId=${packet.packetId}`
        );
        return { status: "dropped" };
      }
      if (binding === "first-seen") {
        // Persist to the verified-identity store (signature already checked
        // above) so the binding survives restarts. First-write-wins there
        // prevents a later conflicting key from clobbering this identity.
        recordVerifiedIdentity(packet.fromNodeId, packet.fromPublicKey).catch(() => {});
      }
      if (replayCacheRef.current.hasSeen(packet.fromNodeId, packet.packetId)) {
        console.log(
          `[MauriMesh][ReplayDrop] duplicate packetId=${packet.packetId}` +
          ` from nodeId=${packet.fromNodeId}`
        );
        return { status: "dropped" };
      }
      replayCacheRef.current.markSeen(packet.fromNodeId, packet.packetId);
      console.log(
        `[MauriMesh][Identity] verified packetId=${packet.packetId}` +
        ` from nodeId=${packet.fromNodeId} (binding=${binding})`
      );
      verifiedNodeId = packet.fromNodeId;
    } else if (packet.type === "ROUTE_BEACON") {
      // Infrastructure liveness only — allowed unsigned.
    } else {
      console.log(
        `[MauriMesh][UnsignedDrop] rejecting unsigned ${packet.type}` +
        ` packetId=${packet.packetId} from nodeId=${packet.fromNodeId}`
      );
      return { status: "dropped" };
    }
    routeInboundPacket(packet);
    // Only an authenticated (signed + verified + key-bound) packet yields a
    // trusted nodeId. ROUTE_BEACON is accepted for routing liveness but its
    // fromNodeId is unauthenticated, so it is NOT a basis for committing a
    // deviceId→nodeId mapping.
    return verifiedNodeId
      ? { status: "verified", nodeId: verifiedNodeId }
      : { status: "beacon" };
  }

  /**
   * Send a strict reverse-path ACK one hop along its recorded reversePath.
   *
   * The outgoing copy has reversePathIndex incremented to tell the receiving
   * relay node where IT sits in the path. If the required next-hop peer is not
   * a current direct BLE contact the ACK is queued in strictAckQueueRef keyed
   * by that peer's nodeId — it is drained when that peer is discovered via BLE.
   *
   * No RouteScore carrier selection. No fallback rerouting. Ever.
   */
  function sendStrictAck(ack: MeshPacket): void {
    if (!ack.reversePath || ack.reversePathIndex === undefined) {
      // Legacy ACK without reversePath — best-effort (should not happen in new code).
      const peers = blePeersRef.current;
      if (peers.length > 0) trySendViaBle(ack, peers, sendToRef.current).catch(() => {});
      return;
    }
    const nextIdx = ack.reversePathIndex + 1;
    const nextHopId = ack.reversePath[nextIdx];
    if (!nextHopId) {
      // Already at the final recipient — nothing to forward.
      return;
    }
    // Stamp the outgoing packet so the receiving relay knows its position.
    const outgoing: MeshPacket = { ...ack, reversePathIndex: nextIdx };
    const nextHopPeer = blePeersRef.current.find((p) => p.nodeId === nextHopId);
    if (nextHopPeer && isOutboundAllowed(outgoing)) {
      sendToRef.current(nextHopPeer.deviceId, makeBleMsg(outgoing)).catch(() => {});
      console.log(
        `[MauriMesh][ACKRouteStrict] ${myNodeId}→${nextHopId}` +
        ` idx=${nextIdx}/${ack.reversePath.length - 1}` +
        ` path=[${ack.reversePath.join("→")}] packetId=${ack.packetId}`
      );
    } else {
      // Required peer not directly reachable — queue strictly for that peer only.
      const waiting = strictAckQueueRef.current.get(nextHopId) ?? [];
      strictAckQueueRef.current.set(nextHopId, [...waiting, outgoing]);
      console.log(
        `[MauriMesh][ACKRouteStrict] queued for ${nextHopId}` +
        ` (not a direct peer) packetId=${ack.packetId}`
      );
    }
  }

  useEffect(() => { blePeersRef.current = blePeers; }, [blePeers]);

  // Load (or create) the cryptographic identity for this node on mount.
  // Identity is persisted in AsyncStorage; subsequent app launches reuse it.
  // Once loaded, restart the BLE advertiser with the full identity beacon so
  // nearby devices can discover this node via the friend-invite pipeline.
  useEffect(() => {
    // Seed the nodeId→publicKey trust bindings from identities established by
    // PREVIOUSLY VERIFIED packets only (never from unauthenticated BLE
    // advertisements) so an attacker cannot rebind a known identity after a
    // restart.
    const markBindingsReadyAndDrain = () => {
      bindingsReadyRef.current = true;
      // Drain packets buffered during hydration, in arrival order, now that the
      // trust store is seeded. These come from native/JS BLE callbacks without
      // device context, so deviceId→nodeId resolution is skipped for them (a
      // negligible, short-window effect); authenticity is fully enforced.
      const pending = pendingInboundRef.current;
      pendingInboundRef.current = [];
      for (const p of pending) verifyAndDispatch(p);
    };
    loadVerifiedIdentities()
      .then((ids) => {
        for (const id of ids) keyBindingRef.current.seed(id.nodeId, id.publicKey);
        markBindingsReadyAndDrain();
      })
      .catch(() => {
        // Even on load failure, open the gate so we don't buffer forever — this
        // degrades to TOFU from an empty store, the original first-use behavior.
        markBindingsReadyAndDrain();
      });

    loadOrCreateCryptoIdentity(myNodeId).then((id) => {
      identityRef.current = id;
      console.log(
        `[MauriMesh][Identity] loaded identity nodeId=${id.nodeId}` +
        ` pubKey=${id.publicKey.slice(0, 8)}…`
      );
      // Broadcast identity over BLE — fire and forget; the advertiser is
      // already running (startPeripheral was called separately for GATT),
      // this call replaces the generic advertisement with one that carries
      // the full nodeId + publicKey so friend discovery works.
      getNodeDisplayName().then((displayName) => {
        updateMauriMeshBleIdentityBeacon(id.nodeId, id.publicKey, displayName)
          .then((ok) => {
            console.log(
              `[MauriMesh][Identity] identity beacon ${ok ? "started" : "unavailable"}`
            );
          })
          .catch(() => {});
      }).catch(() => {});
    }).catch(() => {
      console.log("[MauriMesh][Identity] failed to load identity — packets will be unsigned");
    });
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const { sendTo, resolvePeerNodeId, refreshPeerActivity } = useBleTransport(handleBleMessageStable);
  useEffect(() => { sendToRef.current = sendTo; }, [sendTo]);

  // Combined queue depth: engine CHAT queue + fallback ACK/INVITE queue.
  function combinedQueueSize(): number {
    return meshOfflineEngine.getQueue().length + queue.current.size();
  }

  /**
   * Forward a transit packet (toNodeId ≠ this node) one hop toward its destination.
   *
   * Design:
   * - Uses relayDupGuard (separate from router.deliveredPackets) to drop duplicate
   *   BLE deliveries without preventing local receipt of the same packetId.
   * - Uses router.prepareRelayPacket to append myNodeId to routePath + decrement TTL.
   *   Returns null when TTL ≤ 1 or this node is already in the path (loop guard).
   * - Registers all routePath nodes in the router so ACK relay hops know how to reach
   *   non-adjacent nodes they have never had a direct BLE connection with.
   * - Uses trySendViaBle with RouteScore scorer directly, bypassing selectBestRoute
   *   (which requires the destination in router.nodes — a constraint that fails for
   *   intermediate nodes that have never seen the final destination).
   */
  async function forwardPacket(incoming: MeshPacket): Promise<void> {
    // ── Strict reverse-path ACK routing ──────────────────────────────────────
    // ACK packets with a recorded reversePath must follow it exactly.
    // No carrier selection, no rerouting. Handled entirely here; returns early.
    if (
      incoming.type === "ACK" &&
      incoming.reversePath &&
      incoming.reversePathIndex !== undefined
    ) {
      if (relayDupGuard.hasSeen(incoming.packetId)) {
        console.log(`[MauriMesh][ACKHop] DROP dup relay packetId=${incoming.packetId}`);
        return;
      }
      relayDupGuard.markSeen(incoming.packetId);

      const nextIdx = incoming.reversePathIndex + 1;
      const nextHopId = incoming.reversePath[nextIdx];
      if (!nextHopId) {
        console.log(
          `[MauriMesh][ACKHop] reversePath exhausted packetId=${incoming.packetId}`
        );
        return;
      }

      // Build relay copy: increment index + append myNodeId to routePath.
      const strictRelay: MeshPacket = {
        ...incoming,
        routePath: [...incoming.routePath, myNodeId],
        reversePathIndex: nextIdx,   // tells the next node where it sits in the path
        ttl: incoming.ttl - 1,
      };

      const nextHopPeer = blePeersRef.current.find((p) => p.nodeId === nextHopId);
      if (nextHopPeer && isOutboundAllowed(strictRelay)) {
        sendToRef.current(nextHopPeer.deviceId, makeBleMsg(strictRelay)).catch(() => {});
        console.log(
          `[MauriMesh][ACKHop] ${myNodeId}→${nextHopId}` +
          ` idx=${nextIdx}/${incoming.reversePath.length - 1}` +
          ` path=[${incoming.reversePath.join("→")}] packetId=${incoming.packetId}`
        );
      } else {
        // Strict: do NOT reroute — queue only for this specific peer.
        const waiting = strictAckQueueRef.current.get(nextHopId) ?? [];
        strictAckQueueRef.current.set(nextHopId, [...waiting, strictRelay]);
        console.log(
          `[MauriMesh][ACKRouteStrict] relay queued for ${nextHopId}` +
          ` packetId=${incoming.packetId} (not a direct peer)`
        );
      }
      return; // Strict ACK handled — never fall through to generic relay.
    }

    // ── Generic relay (non-ACK / legacy ACK without reversePath) ─────────────
    if (relayDupGuard.hasSeen(incoming.packetId)) {
      console.log(
        `[MauriMesh][Relay] DROP dup packetId=${incoming.packetId} type=${incoming.type}`
      );
      return;
    }

    // Build relay copy: append myNodeId to routePath, decrement TTL.
    const relay = router.prepareRelayPacket(incoming, myNodeId);
    if (!relay) {
      console.log(
        `[MauriMesh][Relay] DROP ttl/loop packetId=${incoming.packetId}` +
        ` ttl=${incoming.ttl} path=[${incoming.routePath.join("→")}]`
      );
      return;
    }

    // Hard maxHops guard (belt-and-suspenders alongside TTL).
    const hopCount = relay.routePath.length;
    const maxHops = incoming.maxHops ?? 6;
    if (hopCount > maxHops) {
      console.log(
        `[MauriMesh][Relay] DROP maxHops=${maxHops} packetId=${incoming.packetId} hop=${hopCount}`
      );
      return;
    }

    // Register every node seen in the incoming routePath as a known mesh node
    // (using phantom RSSI −85 for non-adjacent entries). This lets relay nodes
    // route ACKs back through non-adjacent hops using router.selectBestRoute.
    for (const nodeId of incoming.routePath) {
      router.registerNode({
        nodeId,
        lastSeen: Date.now(),
        rssi: -85,
        trustState: "UNKNOWN",
        supportedLanes: ["BLE"],
      });
    }

    relayDupGuard.markSeen(incoming.packetId);

    const peers = blePeersRef.current;
    const scorer = (nodeId: string, rssi: number): number =>
      computeRouteScore(metricsRef.current.get(nodeId), rssi);

    console.log(
      `[MauriMesh][Relay] forwarding packetId=${incoming.packetId} type=${incoming.type}` +
      ` hop=${hopCount}/${maxHops} path=[${relay.routePath.join("→")}]`
    );

    const sentPeer = await trySendViaBle(relay, peers, sendToRef.current, scorer, onSendResult);
    if (sentPeer) {
      router.markDelivered(incoming.packetId);
      router.recordRouteSuccess(sentPeer);
      console.log(
        `[MauriMesh][Forward] packetId=${incoming.packetId} type=${incoming.type}` +
        ` hop=${hopCount}/${maxHops} via=${sentPeer} path=[${relay.routePath.join("→")}]`
      );
    } else {
      // No carrier available — queue the relay copy for retry on peer arrival.
      queue.current.enqueue(relay);
      console.log(
        `[MauriMesh][Relay] queued packetId=${incoming.packetId}` +
        ` (no carrier, ${peers.length} peer(s) visible)`
      );
    }
  }

  function routeInboundPacket(packet: MeshPacket) {
    if (!router.shouldAcceptPacket(packet)) return;

    // Transit relay: this packet is passing THROUGH us to reach its destination.
    // Use forwardPacket() which bypasses selectBestRoute and works even when the
    // final destination is not in this node's router registry.
    if (packet.toNodeId !== myNodeId && packet.toNodeId !== "BROADCAST") {
      forwardPacket(packet).catch(() => {});
      return;
    }

    router.markDelivered(packet.packetId);

    if (packet.type === "ROUTE_BEACON") {
      router.registerNode({
        nodeId: packet.fromNodeId,
        lastSeen: Date.now(),
        rssi: 0,
        trustState: "UNKNOWN",
        supportedLanes: ["BLE"],
      });

      // Parse kind from payload — defaults to "PING" for backward compat.
      let beaconKind: "PING" | "PONG" = "PING";
      try {
        const parsed = JSON.parse(packet.payload) as { nodeId?: string; kind?: string };
        if (parsed.kind === "PONG") beaconKind = "PONG";
      } catch { /* ignore malformed payload */ }

      // Record PONG arrival (or initial PING) for stale-peer sweep.
      peerLastBeaconMs.current.set(packet.fromNodeId, Date.now());
      // Also refresh the BLE scan-age timestamp so useBleTransport's own
      // scan-age sweep doesn't evict a peer that's still responding to pings.
      // This unifies both liveness signals into a single "peer is alive" decision.
      refreshPeerActivity(packet.fromNodeId);

      // Only send a PONG when we receive a directed PING — never echo a PONG.
      // This prevents an unbounded echo loop where each side thinks the other's
      // PONG is a fresh PING and keeps replying indefinitely.
      if (beaconKind === "PING" && packet.toNodeId === myNodeId) {
        const pong: MeshPacket = {
          packetId: makePacketId(),
          type: "ROUTE_BEACON",
          fromNodeId: myNodeId,
          toNodeId: packet.fromNodeId,
          routePath: [myNodeId],
          lane: "BLE",
          ttl: 1,
          createdAt: Date.now(),
          priority: packetPriority("ROUTE_BEACON"),
          payload: JSON.stringify({ nodeId: myNodeId, kind: "PONG" }),
          checksum: "",
        };
        const targetPeer = blePeersRef.current.find(
          (p) => p.nodeId === packet.fromNodeId
        );
        if (targetPeer)
          sendToRef.current(targetPeer.deviceId, makeBleMsg(pong)).catch(() => {});
      }
      return;
    }

    if (packet.type === "CALL_INVITE") {
      // Raise the incoming call banner and add a chat bubble so the user
      // sees an incoming call notice. Real call UI is layered on top via
      // the store's incomingCall state (rendered by IncomingCallBanner).
      try {
        const { callId, mode } = JSON.parse(packet.payload) as {
          callId?: string;
          mode?: string;
        };
        setIncomingCall({
          callId: callId ?? packet.packetId,
          mode: mode ?? "audio",
          from: packet.fromNodeId,
        });
        addMessage({
          id: packet.packetId,
          text: `📞 Incoming ${mode ?? "audio"} call from ${packet.fromNodeId}${callId ? ` (${callId})` : ""}`,
          sender: "other",
          senderId: packet.fromNodeId,
          timestamp: formatTime(packet.createdAt),
          timeMs: packet.createdAt,
          status: "delivered",
          transport: "ble",
          read: false,
        } satisfies ChatMessage);
      } catch {
        // malformed payload — show generic notice + banner
        setIncomingCall({
          callId: packet.packetId,
          mode: "audio",
          from: packet.fromNodeId,
        });
        addMessage({
          id: packet.packetId,
          text: `📞 Incoming call from ${packet.fromNodeId}`,
          sender: "other",
          senderId: packet.fromNodeId,
          timestamp: formatTime(packet.createdAt),
          timeMs: packet.createdAt,
          status: "delivered",
          transport: "ble",
          read: false,
        } satisfies ChatMessage);
      }
      return;
    }

    if (packet.type === "CHAT_MESSAGE") {
      addMessage({
        id: packet.packetId,
        text: packet.payload,
        sender: "other",
        senderId: packet.fromNodeId,
        timestamp: formatTime(packet.createdAt),
        timeMs: packet.createdAt,
        status: "delivered",
        transport: "ble",
        read: false,
      } satisfies ChatMessage);
      saveMeshMessage({
        id: packet.packetId,
        chatId: packet.fromNodeId,
        from: packet.fromNodeId,
        to: myNodeId,
        text: packet.payload,
        priority: "NORMAL",
        hopCount: packet.routePath.length,
        timestamp: packet.createdAt,
        via: "maurimesh",
      }).catch(() => {});

      // Strict reverse-path ACK.
      //
      // Build reversePath by appending myNodeId to the incoming routePath and
      // reversing it. If routePath = [A, B], the message traveled A→B→us(C),
      // so reversePath = [C, B, A]: index 0=C (us), 1=B, 2=A (origin).
      //
      // sendStrictAck sends to reversePath[1] stamped with reversePathIndex=1
      // so B knows to forward to reversePath[2]=A. No RouteScore, no fallback.
      const reversePath = [...packet.routePath, myNodeId].reverse();
      const ackTtl = Math.min(reversePath.length + 1, 8);
      const ack: MeshPacket = {
        packetId: makePacketId(),
        type: "ACK",
        fromNodeId: myNodeId,
        toNodeId: packet.fromNodeId,
        routePath: [myNodeId],
        lane: "BLE",
        ttl: ackTtl,
        hopCount: 0,
        maxHops: reversePath.length - 1,
        reversePath,
        reversePathIndex: 0,
        createdAt: Date.now(),
        priority: packetPriority("ACK"),
        payload: packet.packetId,
        checksum: "",
      };
      signOutboundPacket(ack);
      console.log(
        `[MauriMesh][ACKRouteStrict] generated ACK path=[${reversePath.join("→")}]` +
        ` for packetId=${packet.packetId}`
      );
      sendStrictAck(ack);
    }

    if (packet.type === "ACK") {
      // Translate engine core packet ID → original UI message ID when the ACK
      // was generated by a peer that received a retried CHAT packet. The adapter
      // sets contractPkt.packetId = corePkt.id, so the peer ACKs using that ID.
      // If no mapping exists the payload IS the original contract packetId.
      const ackTargetId =
        engineToOriginalId.current.get(packet.payload) ?? packet.payload;
      // Mapping is no longer needed after ACK — clean up to avoid leaks.
      engineToOriginalId.current.delete(packet.payload);
      console.log(
        `[MauriMesh][ACK] ack_confirmed packetId=${ackTargetId}` +
        ` hops=${packet.routePath.length}`
      );
      console.log(
        `[MauriMesh][Hop] full path confirmed: [${packet.routePath.join("→")}]→${myNodeId}`
      );
      updateMessageStatus(ackTargetId, "ack_confirmed");
      updateMeshMessageStatus(ackTargetId, "ack_confirmed").catch(() => {});
      removeFromDeliveryQueue(ackTargetId).catch(() => {});
      // Compute full RTT latency from original send to ACK receipt and update
      // the peer's RouteMetrics with the real round-trip measurement.
      // Look up by both the engine ID (for retried packets) and the target ID.
      const tracked =
        sentAtRef.current.get(packet.payload) ??
        sentAtRef.current.get(ackTargetId);
      if (tracked) {
        const latency = Date.now() - tracked.sentAt;
        console.log(
          `[MauriMesh][RouteScore] ACK latency=${latency}ms peerId=${tracked.peerId}`
        );
        recordSuccess(metricsRef.current, tracked.peerId, latency)
          .then(() => refreshScore(tracked.peerId))
          .catch(() => {});
        sentAtRef.current.delete(packet.payload);
        sentAtRef.current.delete(ackTargetId);
      }
    }
    if (packet.type === "READ_ACK") updateMessageStatus(packet.payload, "read");
  }

  function handleBleMessageStable(bleMsg: BleMessage) {
    let parsed: unknown;
    try { parsed = JSON.parse(bleMsg.payload); }
    catch { return; }

    // ── Fragment path ─────────────────────────────────────────────────────────
    // Fragments MUST be fully reassembled before any routing logic runs.
    // Individual fragments are never relayed, ACKed, or delivered to the app.
    if (isFragmentEnvelope(parsed)) {
      const env = parsed as FragmentEnvelope;
      // Individual fragments carry an UNVERIFIED fromNodeId — never commit a
      // deviceId→nodeId mapping from them. Resolution happens only AFTER the
      // packet is fully reassembled and cryptographically authenticated below.
      const reassembled = fragmentCollector.addFragment(env);
      if (!reassembled) {
        console.log(
          `[MauriMesh][Reassembly] fragment ${env.fragmentIndex + 1}/${env.fragmentCount}` +
          ` packetId=${env.packetId}`
        );
        return; // incomplete — wait for remaining fragments
      }
      console.log(
        `[MauriMesh][Reassembly] complete packetId=${reassembled.packetId}` +
        ` from ${env.fragmentCount} fragment(s)`
      );
      const result = verifyAndDispatch(reassembled);
      if (result.status === "verified" && bleMsg.fromDeviceId) {
        resolvePeerNodeId(bleMsg.fromDeviceId, result.nodeId);
      }
      return;
    }

    // ── Full-packet path (below FRAGMENT_CHUNK_MAX, no fragmentation) ─────────
    const packet = parsed as MeshPacket;
    // Verify FIRST. The deviceId→nodeId mapping is committed only after the
    // packet is authenticated (signed + signature-valid + key-bound), so a
    // spoofed/unsigned/dropped packet can never poison peer identity state.
    // Directed pings then use the correct app-level node ID rather than a BLE
    // hardware-address placeholder. fromDeviceId is absent on locally
    // synthesised packets (e.g. bridge replay).
    const result = verifyAndDispatch(packet);
    if (result.status === "verified" && bleMsg.fromDeviceId) {
      resolvePeerNodeId(bleMsg.fromDeviceId, result.nodeId);
    }
  }

  // Sync shared router registry on peer arrivals/departures
  useEffect(() => {
    const prev = prevPeersRef.current;
    const current = blePeers;
    const currentIds = new Set(current.map((p) => p.nodeId));

    for (const peer of prev) {
      if (!currentIds.has(peer.nodeId)) {
        router.removeNode(peer.nodeId);
        peerLastBeaconMs.current.delete(peer.nodeId);
      }
    }
    prevPeersRef.current = current;

    for (const peer of current) {
      router.registerNode({
        nodeId: peer.nodeId,
        lastSeen: peer.lastSeen,
        rssi: peer.rssi,
        trustState: "UNKNOWN",
        supportedLanes: ["BLE"],
      });
      // Do NOT initialize peerLastBeaconMs here. The 30s PONG-based eviction
      // timer only starts after a confirmed PONG arrives (set in the
      // ROUTE_BEACON handler). Until then, scan-age eviction in useBleTransport
      // acts as the sole liveness authority — preventing false eviction of peers
      // whose node IDs are still placeholder BLE addresses.

      // Drain any strict-ACK packets that were queued waiting for this exact peer.
      const pendingAcks = strictAckQueueRef.current.get(peer.nodeId);
      if (pendingAcks && pendingAcks.length > 0) {
        strictAckQueueRef.current.delete(peer.nodeId);
        for (const pendingAck of pendingAcks) {
          // Re-sign if it was queued unsigned during the identity-load window,
          // mirroring the fallback-queue drain, so a startup-window ACK is not
          // permanently blocked by the fail-closed egress gate.
          if (!pendingAck.signature) signOutboundPacket(pendingAck);
          if (!isOutboundAllowed(pendingAck)) continue;
          sendToRef.current(peer.deviceId, makeBleMsg(pendingAck)).catch(() => {});
          console.log(
            `[MauriMesh][ACKRouteStrict] drained queued ACK →${peer.nodeId}` +
            ` packetId=${pendingAck.packetId}`
          );
        }
      }
    }
  }, [blePeers]);

  // Send directed ROUTE_BEACON (ping) to each peer every 15 s
  useEffect(() => {
    if (!bleReady) return;
    const interval = setInterval(async () => {
      for (const peer of blePeersRef.current) {
        const ping: MeshPacket = {
          packetId: makePacketId(),
          type: "ROUTE_BEACON",
          fromNodeId: myNodeId,
          toNodeId: peer.nodeId,
          routePath: [myNodeId],
          lane: "BLE",
          ttl: 1,
          createdAt: Date.now(),
          priority: packetPriority("ROUTE_BEACON"),
          payload: JSON.stringify({ nodeId: myNodeId, kind: "PING" }),
          checksum: "",
        };
        await sendToRef.current(peer.deviceId, makeBleMsg(ping));
      }
    }, HEARTBEAT_INTERVAL_MS);
    return () => clearInterval(interval);
  }, [bleReady, myNodeId]);

  // Evict peers that have not responded to pings for >= BEACON_STALE_MS.
  // Removes from router registry AND from the store's peer list.
  useEffect(() => {
    const interval = setInterval(() => {
      const now = Date.now();
      for (const [nodeId, lastSeen] of peerLastBeaconMs.current) {
        if (now - lastSeen >= BEACON_STALE_MS) {
          router.removeNode(nodeId);
          peerLastBeaconMs.current.delete(nodeId);
          removePeer(nodeId);
        }
      }
    }, HEARTBEAT_INTERVAL_MS);
    return () => clearInterval(interval);
  }, [removePeer]);

  // Wire MeshOfflineEngine to the BLE send path.
  //
  // On mount:
  //   1. Create a BleMeshTransportAdapter that always reads blePeersRef /
  //      sendToRef so it works with the latest live values without stale
  //      closure risk.
  //   2. Attach it to the singleton meshOfflineEngine and start the engine,
  //      passing an onCycleComplete callback.
  //
  // onCycleComplete fires at the END of each 5 s retry interval, AFTER
  // MeshStoreForwardQueue has called remove() for every successfully delivered
  // packet. This guarantees queueSize reflects the post-removal count.
  //
  // onRetrySuccess fires when the transport adapter confirms a successful
  // retry send. It updates the UI message bubble, SQLite, and delivery queue
  // using the original UI message ID looked up from engineToOriginalId.
  //
  // The mapping is populated BEFORE enqueuePacket() in every call site, so
  // there is no window in which onRetrySuccess could fire without a map entry.
  // (enqueuePacket() does not dispatch immediately — only the 5 s timer does.)
  useEffect(() => {
    const adapter = new BleMeshTransportAdapter(
      () => blePeersRef.current,
      () => sendToRef.current,
      (corePktId: string) => {
        const originalId = engineToOriginalId.current.get(corePktId) ?? corePktId;
        router.markDelivered(originalId);
        console.log(
          `[MauriMesh][Engine] retry succeeded corePktId=${corePktId} originalId=${originalId}`
        );
        useMeshStore.getState().updateMessageStatus(originalId, "sent");
        updateMeshMessageStatus(originalId, "sent").catch(() => {});
        removeFromDeliveryQueue(originalId).catch(() => {});
        // Do NOT delete from engineToOriginalId here. The mapping must remain
        // so the ACK handler can translate the incoming ACK payload (corePktId)
        // back to originalId for the ack_confirmed status transition. The ACK
        // handler deletes the mapping entry once it has resolved the ID.
        //
        // queueSize is updated by onCycleComplete after queue.remove() runs
      },
    );

    meshOfflineEngine.attach(adapter);
    meshOfflineEngine.start(() => {
      // Post-removal: queueSize now reflects the true outstanding count
      setTransportStatus({
        queueSize: meshOfflineEngine.getQueue().length + queue.current.size(),
      });
    }).catch(() => {});

    return () => {
      meshOfflineEngine.stop().catch(() => {});
    };
  // setTransportStatus is stable (Zustand action); run once on mount only.
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // On mount: re-hydrate the persistent delivery queue into the engine's
  // MeshStoreForwardQueue so the 5 s retry timer retries them when BLE opens.
  //
  // createPacket(myNodeId, ...) ensures fromNodeId is the real mesh node ID —
  // not the random UUID produced by getOrCreateIdentity() inside sendPacket().
  //
  // The engineToOriginalId mapping is populated BEFORE enqueuePacket() so
  // onRetrySuccess can always resolve the original UI message ID.
  useEffect(() => {
    loadDeliveryQueue()
      .then((entries) => {
        let count = 0;
        for (const entry of entries) {
          const corePkt = createPacket(myNodeId, {
            type: PacketType.CHAT,
            toNodeId: entry.toNode,
            payload: entry.text,
            ttl: 7,
          });
          // Register mapping before enqueue — no race possible since
          // enqueuePacket() never dispatches immediately.
          engineToOriginalId.current.set(corePkt.id, entry.packetId);
          const accepted = meshOfflineEngine.enqueuePacket(corePkt);
          if (accepted) {
            count++;
            console.log(
              `[MauriMesh][Queue] hydrated id=${entry.id} corePktId=${corePkt.id} retryCount=${entry.retryCount}`
            );
          } else {
            // Queue full or packet expired — remove stale map entry so the
            // engine ID is never dangled without a pending queue slot.
            engineToOriginalId.current.delete(corePkt.id);
            console.warn(
              `[MauriMesh][Queue] hydration rejected (queue full/expired) id=${entry.id} corePktId=${corePkt.id}`
            );
          }
        }
        if (count > 0)
          setTransportStatus({
            queueSize: meshOfflineEngine.getQueue().length + queue.current.size(),
          });
      })
      .catch(() => {});
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // On mount: hydrate persisted RouteMetrics so routing decisions benefit from
  // historical delivery outcomes across restarts.
  useEffect(() => {
    loadAllMetrics().then((map) => {
      metricsRef.current = map;
      for (const [peerId, metrics] of map) {
        const peer = blePeersRef.current.find((p) => p.nodeId === peerId);
        const score = computeRouteScore(metrics, peer?.rssi ?? -80);
        setRouteScore(peerId, score);
        console.log(
          `[MauriMesh][RouteScore] hydrated peerId=${peerId} score=${score.toFixed(3)}`
        );
      }
    }).catch(() => {});
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Native GATT peripheral (Android)
  useEffect(() => {
    let mounted = true;
    startMauriMeshBlePeripheral().then((ok) => {
      if (mounted)
        console.log("[MauriMesh]", ok ? "peripheral started" : "peripheral unavailable");
    });
    const offMessage = onMauriMeshBleMessageReceived((json) => {
      let packet: MeshPacket;
      try { packet = JSON.parse(json) as MeshPacket; }
      catch { return; }
      // Native GATT peripheral writes are attacker-controllable BLE input, so
      // they go through the same authenticity gate as the JS BLE receive path.
      verifyAndDispatch(packet);
    });
    const offStatus = onMauriMeshBleStatus((s) => console.log("[MauriMesh BLE]", s));
    return () => { mounted = false; offMessage(); offStatus(); };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [myNodeId]);

  // HTTP bridge poll — uses the typed startMeshReceiveLoop (1 s cadence).
  // CALL_INVITE payloads are routed to onCallInvite; all other text (including
  // READ_ACK envelopes) arrives in onTextMessage for secondary dispatch.
  useEffect(() => {
    const stop = startMeshReceiveLoop({
      myNodeId,

      onTextMessage: (msg) => {
        // READ_ACK envelope: { __readAck: "<originalPacketId>" }
        // These arrive as JSON text since startMeshReceiveLoop only intercepts
        // CALL_INVITE under the JSON branch — handle them here before adding
        // a chat bubble.
        if (msg.payload.startsWith("{")) {
          try {
            const parsed = JSON.parse(msg.payload) as Record<string, unknown>;
            if (typeof parsed.__readAck === "string") {
              if (router.shouldAcceptPacket({
                packetId: msg.id, type: "READ_ACK",
                fromNodeId: msg.senderId, toNodeId: myNodeId,
                routePath: [], lane: "INTERNET", ttl: 1,
                createdAt: msg.timestamp,
                priority: packetPriority("READ_ACK"), payload: parsed.__readAck, checksum: "",
              })) {
                router.markDelivered(msg.id);
                updateMessageStatus(parsed.__readAck, "read");
              }
              return;
            }
          } catch { /* not a valid READ_ACK — fall through to chat bubble */ }
        }

        // Plain CHAT_MESSAGE
        const syntheticPacket: MeshPacket = {
          packetId: msg.id,
          type: "CHAT_MESSAGE",
          fromNodeId: msg.senderId,
          toNodeId: myNodeId,
          routePath: [],
          lane: "INTERNET",
          ttl: 1,
          createdAt: msg.timestamp,
          priority: packetPriority("CHAT_MESSAGE", myNodeId),
          payload: msg.payload,
          checksum: "",
        };
        if (router.shouldAcceptPacket(syntheticPacket)) {
          router.markDelivered(msg.id);
          addMessage({
            id: msg.id,
            text: msg.payload,
            sender: "other",
            senderId: msg.senderId,
            timestamp: formatTime(msg.timestamp),
            timeMs: msg.timestamp,
            status: "delivered",
            transport: "bridge",
            read: false,
          } satisfies ChatMessage);
          saveMeshMessage({
            id: msg.id,
            chatId: msg.senderId,
            from: msg.senderId,
            to: msg.recipientId,
            text: msg.payload,
            priority: msg.priority,
            hopCount: msg.hopCount,
            timestamp: msg.timestamp,
            via: "maurimesh",
          }).catch(() => {});
        }
      },

      onCallInvite: (invite, raw) => {
        if (router.shouldAcceptPacket({
          packetId: raw.id, type: "CALL_INVITE",
          fromNodeId: raw.senderId, toNodeId: myNodeId,
          routePath: [], lane: "INTERNET", ttl: 1,
          createdAt: raw.timestamp,
          priority: packetPriority("CALL_INVITE"), payload: raw.payload, checksum: "",
        })) {
          router.markDelivered(raw.id);
          setIncomingCall({
            callId: (invite.callId as string) ?? raw.id,
            mode: (invite.mode as string) ?? "audio",
            from: raw.senderId,
          });
          addMessage({
            id: raw.id,
            text: `📞 Incoming ${invite.mode ?? "audio"} call from ${raw.senderId}`,
            sender: "other",
            senderId: raw.senderId,
            timestamp: formatTime(raw.timestamp),
            timeMs: raw.timestamp,
            status: "delivered",
            transport: "bridge",
            read: false,
          } satisfies ChatMessage);
        }
      },

      onBridgeStatus: (online) => setTransportStatus({ bridgeOnline: online }),
    });
    return stop;
  }, [myNodeId, setTransportStatus, addMessage, updateMessageStatus, setIncomingCall]);

  // Drain fallback queue when BLE peers become available.
  //
  // Two queues are drained on each trigger:
  //   1. queue.current  — READ_ACK / CALL_INVITE packets that use the legacy
  //      fallback queue (no mesh-core PacketType equivalent).
  //   2. mesh-service flushRelayQueue — transit packets that failed or had no
  //      route when they first arrived; fresh relay attempt via best next-hop.
  //
  // CHAT packets are retried exclusively by MeshStoreForwardQueue's 5 s timer
  // registered inside meshOfflineEngine.start(). No additional trigger needed.
  useEffect(() => {
    if (!bleReady || blePeers.length === 0) return;
    let active = true;
    async function drain() {
      // --- Fallback queue (READ_ACK / CALL_INVITE) ---
      let packet = queue.current.dequeue();
      while (packet && active) {
        // A packet may have been enqueued unsigned during the identity-load
        // startup window. Re-sign at dequeue now that identity is (likely)
        // available, otherwise trySendViaBle's fail-closed gate would block it
        // forever. ROUTE_BEACON is never queued here.
        if (!packet.signature) signOutboundPacket(packet);
        const scorer = (nodeId: string, rssi: number): number =>
          computeRouteScore(metricsRef.current.get(nodeId), rssi);
        const drainPeer = await trySendViaBle(packet, blePeers, sendTo, scorer, onSendResult);
        if (!drainPeer) { queue.current.enqueue(packet); break; }
        router.markDelivered(packet.packetId);
        // Track sentAt for latency measurement (READ_ACK/CALL_INVITE in this
        // queue won't produce an ACK reply, but the entry is harmless and
        // consistent with the direct-send path).
        sentAtRef.current.set(packet.packetId, { peerId: drainPeer, sentAt: Date.now() });
        console.log(`[MauriMesh][Delivery] fallback-queue drain sent packetId=${packet.packetId} via=${drainPeer}`);
        packet = queue.current.dequeue();
      }
      setTransportStatus({
        queueSize: meshOfflineEngine.getQueue().length + queue.current.size(),
      });

      // --- Transit relay packets (enqueued by handleIncomingPacket on failure/no-route) ---
      if (active) {
        flushRelayQueue((p) => {
          trySendViaBle(p, blePeers, sendTo).then((sent) => {
            if (sent) router.markDelivered(p.packetId);
          }).catch(() => {});
        });
      }
    }
    drain();
    return () => { active = false; };
  }, [bleReady, blePeers, sendTo, myNodeId, setTransportStatus]);

  const sendMessage = useCallback(
    async (
      text: string,
      toNode: string = "BROADCAST",
      packetId?: string
    ): Promise<"delivered" | "bridge" | "queued"> => {
      const id = packetId ?? makePacketId();
      const packet: MeshPacket = {
        packetId: id,
        type: "CHAT_MESSAGE",
        fromNodeId: myNodeId,
        toNodeId: toNode,
        routePath: [myNodeId],
        lane: "BLE",
        ttl: 7,
        hopCount: 0,
        maxHops: 6,
        createdAt: Date.now(),
        priority: packetPriority("CHAT_MESSAGE", toNode),
        payload: text,
        checksum: simpleChecksum(text),
      };
      // Sign after all stable fields are set. fromPublicKey is set inside
      // signOutboundPacket before computing the signature so it is covered.
      signOutboundPacket(packet);

      useMeshStore.getState().updateMessageStatus(id, "sending");
      updateMeshMessageStatus(id, "sending").catch(() => {});
      console.log(`[MauriMesh][Delivery] attempting send id=${id}`);

      if (bleReady && blePeers.length > 0) {
        // Build a RouteScore-based scorer from current in-memory metrics so
        // carrier selection prefers historically reliable peers.
        const scorer = (nodeId: string, rssi: number): number =>
          computeRouteScore(metricsRef.current.get(nodeId), rssi);

        const sentPeer = await trySendViaBle(packet, blePeers, sendTo, scorer, onSendResult);
        if (sentPeer) {
          router.markDelivered(id);
          // Record send timestamp for RTT latency when ACK arrives.
          sentAtRef.current.set(id, { peerId: sentPeer, sentAt: Date.now() });
          console.log(`[MauriMesh][Delivery] BLE sent id=${id} via peerId=${sentPeer}`);
          useMeshStore.getState().updateMessageStatus(id, "sent");
          updateMeshMessageStatus(id, "sent").catch(() => {});
          removeFromDeliveryQueue(id).catch(() => {});
          return "delivered";
        }
        // BLE send failed — hand off to MeshOfflineEngine's store-forward
        // queue. The 5 s retry timer will reattempt via BleMeshTransportAdapter.
        // MeshTrustEngine scores are updated inside dispatchPacket() on each
        // retry; router scores are updated inside trySendViaBle.
        console.log(`[MauriMesh][Engine] BLE failed, enqueuing via meshOfflineEngine id=${id}`);
      }

      const { bridgeOnline } = useMeshStore.getState().transportStatus;
      if (bridgeOnline) {
        try {
          await mauriMeshBridge.sendMessengerText({ fromNode: myNodeId, toNode, text });
          router.markDelivered(id);
          console.log(`[MauriMesh][Delivery] bridge sent id=${id}`);
          useMeshStore.getState().updateMessageStatus(id, "sent");
          updateMeshMessageStatus(id, "sent").catch(() => {});
          removeFromDeliveryQueue(id).catch(() => {});
          return "bridge";
        } catch {
          setTransportStatus({ bridgeOnline: false });
        }
      }

      // No successful delivery path — hand off to MeshOfflineEngine.
      // Build a core packet with myNodeId so fromNodeId is correct on retry.
      // Mapping is stored BEFORE enqueuePacket() — no race with onRetrySuccess.
      const corePkt = createPacket(myNodeId, {
        type: PacketType.CHAT,
        toNodeId: toNode,
        payload: text,
        ttl: packet.ttl,
      });
      engineToOriginalId.current.set(corePkt.id, id);
      const enqueued = meshOfflineEngine.enqueuePacket(corePkt);
      if (!enqueued) {
        // Queue full or packet already expired — remove the stale mapping to
        // avoid a dangled entry with no corresponding queue slot.
        engineToOriginalId.current.delete(corePkt.id);
        console.warn(
          `[MauriMesh][Engine] enqueue rejected (queue full/expired) id=${id} corePktId=${corePkt.id}`
        );
      } else {
        console.log(
          `[MauriMesh][Queue] message id=${id} corePktId=${corePkt.id} enqueued for retry`
        );
      }
      setTransportStatus({
        queueSize: meshOfflineEngine.getQueue().length + queue.current.size(),
      });
      enqueueForDelivery({ id, packetId: id, text, toNode, fromNode: myNodeId }).catch(() => {});
      return "queued";
    },
    [bleReady, blePeers, sendTo, myNodeId, setTransportStatus]
  );

  const sendReadAck = useCallback(
    async (packetId: string, toNodeId: string): Promise<void> => {
      const ackPacket: MeshPacket = {
        packetId: makePacketId(),
        type: "READ_ACK",
        fromNodeId: myNodeId,
        toNodeId,
        routePath: [myNodeId],
        lane: "BLE",
        ttl: 4,
        createdAt: Date.now(),
        priority: packetPriority("READ_ACK"),
        payload: packetId,
        checksum: "",
      };
      // READ_ACK changes delivery state at the receiver, so it must be signed to
      // satisfy the mandatory-signature receive policy.
      signOutboundPacket(ackPacket);

      if (bleReady && blePeers.length > 0) {
        const sent = await trySendViaBle(ackPacket, blePeers, sendTo);
        if (sent) return;
      }

      // Fallback to bridge so read receipts survive transient BLE loss.
      const { bridgeOnline } = useMeshStore.getState().transportStatus;
      if (bridgeOnline) {
        try {
          await mauriMeshBridge.sendMessengerText({
            fromNode: myNodeId,
            toNode: toNodeId,
            text: JSON.stringify({ __readAck: packetId }),
          });
          return;
        } catch {
          setTransportStatus({ bridgeOnline: false });
        }
      }

      // READ_ACK has no mesh-core PacketType equivalent — use the legacy
      // fallback queue that is drained when BLE peers become available.
      queue.current.enqueue(ackPacket);
      setTransportStatus({
        queueSize: meshOfflineEngine.getQueue().length + queue.current.size(),
      });
    },
    [bleReady, blePeers, sendTo, myNodeId, setTransportStatus]
  );

  /**
   * Send a CALL_INVITE packet — uses the dedicated priority tier (7) so it
   * pre-empts queued chat traffic and gets routed via the fastest available path.
   */
  const sendCallInvite = useCallback(
    async (callId: string, mode: "audio" | "video", toNode: string): Promise<void> => {
      // Include type field so the bridge inbound parser (which checks
      // parsed.type === "CALL_INVITE") can identify and route this correctly
      // without adding a raw JSON bubble to the chat.
      const payload = JSON.stringify({ type: "CALL_INVITE", callId, mode, from: myNodeId });
      const packet: MeshPacket = {
        packetId: callId,
        type: "CALL_INVITE",
        fromNodeId: myNodeId,
        toNodeId: toNode,
        routePath: [myNodeId],
        lane: "BLE",
        ttl: 7,
        createdAt: Date.now(),
        priority: packetPriority("CALL_INVITE"),
        payload,
        checksum: simpleChecksum(payload),
      };
      // CALL_INVITE raises incoming-call UI at the receiver, so it must be signed
      // to satisfy the mandatory-signature receive policy.
      signOutboundPacket(packet);

      if (bleReady && blePeers.length > 0) {
        const sent = await trySendViaBle(packet, blePeers, sendTo);
        if (sent) { router.markDelivered(callId); return; }
      }

      const { bridgeOnline } = useMeshStore.getState().transportStatus;
      if (bridgeOnline) {
        try {
          await mauriMeshBridge.sendMessengerText({
            fromNode: myNodeId,
            toNode,
            text: payload,
          });
          router.markDelivered(callId);
          return;
        } catch {
          setTransportStatus({ bridgeOnline: false });
        }
      }

      // CALL_INVITE has no mesh-core PacketType equivalent — use the legacy
      // fallback queue that is drained when BLE peers become available.
      queue.current.enqueue(packet);
      setTransportStatus({
        queueSize: meshOfflineEngine.getQueue().length + queue.current.size(),
      });
    },
    [bleReady, blePeers, sendTo, myNodeId, setTransportStatus]
  );

  return { sendMessage, sendReadAck, sendCallInvite };
}
