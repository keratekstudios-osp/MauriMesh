// BLE Transport — scan + GATT TX/RX.
// Peers and bleReady are written directly to useMeshStore (no local useState).
// Payloads > 500 chars are fragmented; re-assembled before the callback fires.
// Stale peers (no scan ad for 30 s) are pruned every 15 s.
// Failed GATT connections use exponential backoff (1 s → 60 s cap).
//
// ── BLE ownership model ──────────────────────────────────────────────────────
// This JS layer is the PRIMARY BLE manager while the app is in the foreground.
// MeshForegroundService (Kotlin) is the BACKGROUND-only BLE manager: it keeps
// the scanner, GATT server, and advertiser alive when Android suspends JS.
// The two layers share data only through the plugin bridge callbacks
// (onMauriMeshBleMessageReceived / MeshCentralClient.kt → JS event).
// They do NOT both scan/connect at the same time in foreground — the service
// exits active GATT connections when JS signals it is foregrounded, preventing
// duplicate GATT manager contention on the Android radio stack.

import { useCallback, useEffect, useRef } from "react";
import { ingestBluetoothPeer, learnBluetoothMeshRoute, receiveBluetoothMeshPacket } from "../../../src/lib/bluetoothMeshClient";
import { AppState, PermissionsAndroid, Platform } from "react-native";
import {
  clearNoPeersDutyCycle,
  forceNoPeersDutyCycle,
  getScanDutyCycle,
  onScanDutyCycleChange,
  scanRestMs,
  scanWindowMs,
  startPowerManager,
} from "./power-manager";
import { useMeshStore } from "../store/meshStore";
import { addDiscoveredPeer } from "./nearbyPeerRegistry";

export const MESH_SERVICE_UUID = "7f9a0001-5b7b-4c1f-9c8f-4f0f7f9a0001";
export const MESH_CHAR_UUID = "7f9a0002-5b7b-4c1f-9c8f-4f0f7f9a0002";
/**
 * Service UUID advertised in the BLE service data slot by devices that want to
 * be discoverable as friend-invite candidates. The value is a base64-encoded
 * JSON object: { nodeId: string; publicKey: string; displayName?: string }.
 */
export const FRIEND_INVITE_SERVICE_UUID = "7f9a0003-5b7b-4c1f-9c8f-4f0f7f9a0001";

const FRAGMENT_SIZE = 500;
/** Expiry: prune peers not seen for 30 s. */
const STALE_PEER_MS = 30_000;
/** How often the stale-peer sweep runs. */
const HEARTBEAT_INTERVAL_MS = 15_000;
/** After this many ms without any peer, force LOW_POWER scan. */
const NO_PEERS_LOW_POWER_MS = 120_000;
/** Initial backoff for GATT reconnect. */
const RECONNECT_BACKOFF_INIT_MS = 1_000;
/** Maximum backoff cap. */
const RECONNECT_BACKOFF_MAX_MS = 60_000;

export interface BlePeer {
  deviceId: string;
  nodeId: string;
  rssi: number;
  lastSeen: number;
}

export interface BleMessage {
  packetId: string;
  fromNodeId: string;
  toNodeId: string;
  payload: string;
  createdAt: number;
  /**
   * BLE hardware device ID of the sending radio — injected on inbound messages
   * by the GATT subscription handler. Absent on locally-created outbound messages.
   */
  fromDeviceId?: string;
}

// ─────────────────────────────────────────────────────────────────────────────
// Lazy native-module guard
// ─────────────────────────────────────────────────────────────────────────────

// eslint-disable-next-line @typescript-eslint/no-explicit-any
let NativeBleManager: any = null;
try {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  NativeBleManager = require("react-native-ble-plx").BleManager;
} catch {
  // Not available in Expo Go or web — hook will stay inactive
}

// ─────────────────────────────────────────────────────────────────────────────
// Permissions
// ─────────────────────────────────────────────────────────────────────────────

async function requestBlePermissions(): Promise<boolean> {
  if (Platform.OS !== "android") return true;

  const sdkVersion =
    typeof Platform.Version === "number"
      ? Platform.Version
      : parseInt(Platform.Version, 10);

  if (sdkVersion >= 31) {
    const results = await PermissionsAndroid.requestMultiple([
      PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN,
      PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT,
      PermissionsAndroid.PERMISSIONS.BLUETOOTH_ADVERTISE,
    ]);
    return Object.values(results).every(
      (r) => r === PermissionsAndroid.RESULTS.GRANTED
    );
  }

  const granted = await PermissionsAndroid.request(
    PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION
  );
  return granted === PermissionsAndroid.RESULTS.GRANTED;
}

// ─────────────────────────────────────────────────────────────────────────────
// Base64 helpers (btoa/atob are global in RN 0.70+)
// ─────────────────────────────────────────────────────────────────────────────

function strToBase64(str: string): string {
  return btoa(unescape(encodeURIComponent(str)));
}

function base64ToStr(b64: string): string {
  return decodeURIComponent(escape(atob(b64)));
}

function fragmentB64(b64: string): string[] {
  const chunks: string[] = [];
  for (let i = 0; i < b64.length; i += FRAGMENT_SIZE) {
    chunks.push(b64.slice(i, i + FRAGMENT_SIZE));
  }
  return chunks;
}

// ─────────────────────────────────────────────────────────────────────────────
// Friend-invite beacon parser
// ─────────────────────────────────────────────────────────────────────────────

interface FriendBeaconPayload {
  nodeId: string;
  publicKey: string;
  displayName?: string;
}

/**
 * Decode a base64 string to a Uint8Array.
 * Works with the global atob available in React Native 0.70+.
 */
function base64ToBytes(b64: string): Uint8Array {
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) {
    bytes[i] = bin.charCodeAt(i);
  }
  return bytes;
}

/**
 * Primary path: parse the friend-invite JSON beacon from service data.
 *
 * react-native-ble-plx delivers device.serviceData as a dict where each value
 * is a base64 string of the raw service data bytes.  MeshAdvertiser (Kotlin)
 * puts raw UTF-8 JSON bytes in the FRIEND_INVITE_SERVICE_UUID slot, so
 * base64ToStr() decodes them back to the JSON string.
 *
 * Payload shape: { nodeId: string; publicKey: string; displayName?: string }
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function parseBeaconFromServiceData(device: any): FriendBeaconPayload | null {
  const raw: string | undefined =
    device.serviceData?.[FRIEND_INVITE_SERVICE_UUID];
  if (!raw) return null;
  try {
    const json = base64ToStr(raw);
    const parsed = JSON.parse(json) as Partial<FriendBeaconPayload>;
    if (
      typeof parsed.nodeId === "string" &&
      parsed.nodeId.length > 0 &&
      typeof parsed.publicKey === "string" &&
      parsed.publicKey.length > 0
    ) {
      return {
        nodeId: parsed.nodeId,
        publicKey: parsed.publicKey,
        displayName:
          typeof parsed.displayName === "string"
            ? parsed.displayName
            : undefined,
      };
    }
  } catch {
    // malformed — fall through
  }
  return null;
}

/**
 * Fallback path: parse the legacy compact beacon from manufacturer data.
 *
 * Used when the advertising device does not support LE extended advertising
 * (Android < 8 or hardware limitation) and falls back to a compact binary
 * record in manufacturer-specific data.
 *
 * react-native-ble-plx encodes device.manufacturerData as base64 of the full
 * manufacturer data bytes including the 2-byte little-endian company ID.
 *
 * Company ID: 0x4D4D ("MM") → bytes[0]=0x4D, bytes[1]=0x4D
 * Payload layout (after company ID):
 *   [0x01 version][nodeId_len:1][nodeId_utf8:≤16][pubKey_prefix:8]
 *
 * publicKey is stored as "fp:<base64>" to signal it is an 8-byte fingerprint,
 * not the full Ed25519 key.  The Add Friend flow can do a GATT read for the
 * full key when the user initiates a friend request.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function parseBeaconFromManufacturerData(device: any): FriendBeaconPayload | null {
  const raw: string | undefined = device.manufacturerData;
  if (!raw) return null;
  try {
    const bytes = base64ToBytes(raw);
    // Validate company ID (0x4D 0x4D = "MM", little-endian in BLE)
    if (bytes.length < 12 || bytes[0] !== 0x4D || bytes[1] !== 0x4D) return null;
    // Version check
    if (bytes[2] !== 0x01) return null;
    const nodeIdLen = Math.min(bytes[3], 16);
    if (bytes.length < 4 + nodeIdLen + 8) return null;
    // Decode nodeId (ASCII-safe; format is "mm-<base36>-<base36>")
    let nodeId = "";
    for (let i = 4; i < 4 + nodeIdLen; i++) {
      nodeId += String.fromCharCode(bytes[i]);
    }
    if (nodeId.length === 0) return null;
    // Encode the 8-byte public-key prefix as base64 fingerprint
    const prefixBytes = bytes.slice(4 + nodeIdLen, 4 + nodeIdLen + 8);
    const fingerprint = btoa(String.fromCharCode(...prefixBytes));
    return {
      nodeId,
      publicKey: `fp:${fingerprint}`,
      displayName: undefined,
    };
  } catch {
    // malformed — discard silently
  }
  return null;
}

/**
 * Attempt to parse a friend-invite beacon from a BLE scan result.
 *
 * Tries the primary service-data path first (full JSON payload, extended
 * advertising on Android 8+ hardware), then falls back to the compact
 * manufacturer-data path (legacy advertising with 8-byte key fingerprint).
 *
 * Returns null when neither path yields a valid payload.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function parseFriendBeacon(device: any): FriendBeaconPayload | null {
  return parseBeaconFromServiceData(device) ?? parseBeaconFromManufacturerData(device);
}

// ─────────────────────────────────────────────────────────────────────────────
// Fragment reassembly — accumulates base64 chunks per device
// ─────────────────────────────────────────────────────────────────────────────

function makeReassembler() {
  const buf = new Map<string, string>();

  return function tryReassemble(
    deviceId: string,
    chunk: string
  ): string | null {
    const accumulated = (buf.get(deviceId) ?? "") + chunk;
    try {
      JSON.parse(base64ToStr(accumulated));
      buf.delete(deviceId);
      return base64ToStr(accumulated);
    } catch {
      buf.set(deviceId, accumulated);
      return null;
    }
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Hook
// ─────────────────────────────────────────────────────────────────────────────

export function useBleTransport(onMessage: (msg: BleMessage) => void) {
  // ── Zustand store — peers/bleReady are written here directly ──────────────
  const setPeers = useMeshStore((s) => s.setPeers);
  const setTransportStatus = useMeshStore((s) => s.setTransportStatus);

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const managerRef = useRef<any>(null);
  const peersRef = useRef<Map<string, BlePeer>>(new Map());
  /**
   * Maps BLE hardware device IDs to their app-level mesh node IDs.
   * Populated by resolvePeerNodeId() once the first packet is received from a
   * peer — before that, the scan uses localName (if advertised) or deviceId as
   * a placeholder.
   */
  const nodeIdByDeviceId = useRef<Map<string, string>>(new Map());
  /** Connected device IDs (GATT subscription active). */
  const connectedRef = useRef<Set<string>>(new Set());
  /** Devices currently attempting connection OR in backoff cooldown. */
  const connectingRef = useRef<Set<string>>(new Set());
  /** Current exponential backoff delay per device (ms). */
  const reconnectBackoffRef = useRef<Map<string, number>>(new Map());
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const subscriptionsRef = useRef<any[]>([]);
  const reassemble = useRef(makeReassembler());
  const onMessageRef = useRef(onMessage);
  onMessageRef.current = onMessage;

  /** Timestamp of the most recent scan advertisement from any peer. */
  const lastPeerSeenAtRef = useRef<number>(Date.now());
  /**
   * True when the app is in the background/inactive state. While true, JS BLE
   * scanning is paused — MeshForegroundService (Kotlin) is the active owner.
   * Toggled by the AppState listener in the BLE manager lifecycle effect.
   */
  const isBackgroundedRef = useRef<boolean>(false);

  // ── Power manager ──────────────────────────────────────────────────────────

  useEffect(() => {
    const stop = startPowerManager();
    return stop;
  }, []);

  // ── BLE manager lifecycle ──────────────────────────────────────────────────

  useEffect(() => {
    if (Platform.OS === "web" || !NativeBleManager) return;

    const manager = new NativeBleManager();
    managerRef.current = manager;

    let pauseTimer: ReturnType<typeof setTimeout> | null = null;

    function startActiveScan() {
      const cycle = getScanDutyCycle();
      const restMs = scanRestMs(cycle);
      const windowMs = scanWindowMs(cycle);

      manager.startDeviceScan(
        [MESH_SERVICE_UUID, FRIEND_INVITE_SERVICE_UUID],
        { allowDuplicates: true },
        (error: unknown, device: unknown) => {
          if (error || !device) return;

          // eslint-disable-next-line @typescript-eslint/no-explicit-any
          const d = device as any;
          const now = Date.now();
          // Use the already-resolved mesh node ID if we have one; fall back
          // to the BLE local name (set by the peripheral to its myNodeId), then
          // the BLE device address as a placeholder until the first packet.
          const resolvedNodeId =
            nodeIdByDeviceId.current.get(d.id) ?? d.localName ?? d.id;
          const peer: BlePeer = {
            deviceId: d.id,
            nodeId: resolvedNodeId,
            rssi: d.rssi ?? -100,
            lastSeen: now,
          };

          // Track last-seen for no-peers duty-cycle logic
          lastPeerSeenAtRef.current = now;
          clearNoPeersDutyCycle();

          peersRef.current.set(d.id, peer);
          setPeers([...peersRef.current.values()]);

          // If this advertisement carries a friend-invite beacon, register the
          // peer in nearbyPeerRegistry so searchNearbyFriendNodes() surfaces it.
          const beacon = parseFriendBeacon(d);
          if (beacon) {
            console.log(
              `[MauriMesh] parseFriendBeacon: nodeId=${beacon.nodeId}` +
              ` displayName=${beacon.displayName ?? "(none)"} rssi=${d.rssi ?? "?"}`
            );
            addDiscoveredPeer({
              nodeId: beacon.nodeId,
              publicKey: beacon.publicKey,
              displayName: beacon.displayName,
              rssi: d.rssi ?? undefined,
              lastSeenAt: now,
            }).catch(() => {});
          }

          // Connect only if not already connected or in backoff cooldown
          if (
            !connectedRef.current.has(d.id) &&
            !connectingRef.current.has(d.id)
          ) {
            connectingRef.current.add(d.id);

            connectAndSubscribe(
              manager,
              d,
              reassemble.current,
              (msg) => onMessageRef.current(msg)
            ).then((subs) => {
              if (subs) {
                connectedRef.current.add(d.id);
                subscriptionsRef.current.push(...subs);
                reconnectBackoffRef.current.delete(d.id);
                connectingRef.current.delete(d.id);
              } else {
                // Failed: hold the "connecting" slot for the backoff duration,
                // then release it so the scanner triggers a fresh attempt.
                const backoff =
                  reconnectBackoffRef.current.get(d.id) ??
                  RECONNECT_BACKOFF_INIT_MS;
                const next = Math.min(backoff * 2, RECONNECT_BACKOFF_MAX_MS);
                reconnectBackoffRef.current.set(d.id, next);
                setTimeout(
                  () => connectingRef.current.delete(d.id),
                  backoff
                );
              }
            });
          }
        }
      );

      // Duty-cycle pause/resume
      if (restMs > 0 && windowMs > 0) {
        pauseTimer = setTimeout(() => {
          manager.stopDeviceScan();
          pauseTimer = setTimeout(() => startActiveScan(), restMs);
        }, windowMs);
      }
    }

    const stateSub = manager.onStateChange(async (state: string) => {
      if (state !== "PoweredOn") return;
      const hasPerms = await requestBlePermissions();
      if (!hasPerms) return;
      setTransportStatus({ bleReady: true });
      startActiveScan();
    }, true);

    // Re-apply duty cycle when power manager emits a change
    const offDutyCycle = onScanDutyCycleChange(() => {
      if (pauseTimer) clearTimeout(pauseTimer);
      manager.stopDeviceScan();
      if (!isBackgroundedRef.current) startActiveScan();
    });

    // ── AppState arbitration ─────────────────────────────────────────────────
    // JS BLE is PRIMARY in foreground; MeshForegroundService is PRIMARY in
    // background. We enforce this here so only one scanner/GATT owner is active
    // at a time, preventing duplicate manager contention on the Android radio.
    const appStateSub = AppState.addEventListener("change", (nextState) => {
      const goingBackground = nextState === "background" || nextState === "inactive";
      if (goingBackground && !isBackgroundedRef.current) {
        isBackgroundedRef.current = true;
        // Pause JS scan — Kotlin foreground service takes over from here.
        if (pauseTimer) { clearTimeout(pauseTimer); pauseTimer = null; }
        manager.stopDeviceScan();
      } else if (nextState === "active" && isBackgroundedRef.current) {
        isBackgroundedRef.current = false;
        // Reclaim scanning — Kotlin service yields when app is foregrounded.
        startActiveScan();
      }
    });

    return () => {
      stateSub.remove();
      offDutyCycle();
      appStateSub.remove();
      if (pauseTimer) clearTimeout(pauseTimer);
      subscriptionsRef.current.forEach((s) => s.remove());
      subscriptionsRef.current = [];
      manager.stopDeviceScan();
      manager.destroy();
      managerRef.current = null;
      setTransportStatus({ bleReady: false });
    };
  }, [setPeers, setTransportStatus]);

  // ── Stale peer expiry — runs every HEARTBEAT_INTERVAL_MS ─────────────────
  //
  // • Prune peers not seen for STALE_PEER_MS (30 s).
  // • If no peers at all for NO_PEERS_LOW_POWER_MS (120 s), force LOW_POWER.

  useEffect(() => {
    const timer = setInterval(() => {
      const now = Date.now();
      let changed = false;

      for (const [id] of peersRef.current) {
        const peer = peersRef.current.get(id)!;
        if (now - peer.lastSeen > STALE_PEER_MS) {
          peersRef.current.delete(id);
          connectedRef.current.delete(id);
          connectingRef.current.delete(id);
          changed = true;
        }
      }

      if (changed) setPeers([...peersRef.current.values()]);

      // No peers seen for 120 s → conserve battery with LOW_POWER scan
      if (
        peersRef.current.size === 0 &&
        now - lastPeerSeenAtRef.current > NO_PEERS_LOW_POWER_MS
      ) {
        forceNoPeersDutyCycle();
      }
    }, HEARTBEAT_INTERVAL_MS);

    return () => clearInterval(timer);
  }, [setPeers]);

  // ── sendTo (GATT write) ───────────────────────────────────────────────────

  const sendTo = useCallback(
    async (deviceId: string, msg: BleMessage): Promise<boolean> => {
      const manager = managerRef.current;
      if (!manager) return false;

      try {
        const json = JSON.stringify(msg);
        const b64 = strToBase64(json);
        const chunks = fragmentB64(b64);

        const device = await manager.connectToDevice(deviceId);
        await device.discoverAllServicesAndCharacteristics();

        for (const chunk of chunks) {
          await device.writeCharacteristicWithResponseForService(
            MESH_SERVICE_UUID,
            MESH_CHAR_UUID,
            chunk
          );
        }

        await device.cancelConnection();
        return true;
      } catch {
        connectedRef.current.delete(deviceId);
        return false;
      }
    },
    []
  );

  /**
   * Called by useMeshTransport when it parses a packet from a peer.
   * Updates the deviceId→nodeId map and refreshes the peer entry so that
   * directed heartbeat pings address the correct mesh node ID going forward.
   */
  const resolvePeerNodeId = useCallback(
    (deviceId: string, meshNodeId: string) => {
      if (nodeIdByDeviceId.current.get(deviceId) === meshNodeId) return;
      nodeIdByDeviceId.current.set(deviceId, meshNodeId);
      const existing = peersRef.current.get(deviceId);
      if (existing && existing.nodeId !== meshNodeId) {
        peersRef.current.set(deviceId, { ...existing, nodeId: meshNodeId });
        setPeers([...peersRef.current.values()]);
      }
    },
    [setPeers]
  );

  /**
   * Called by useMeshTransport when a PONG (or any heartbeat response) arrives
   * from a peer identified by its mesh node ID. Refreshes the BLE peer's lastSeen
   * timestamp so the scan-age stale sweep doesn't evict a peer that is still
   * actively responding to pings — even if it has temporarily stopped advertising.
   */
  const refreshPeerActivity = useCallback((meshNodeId: string) => {
    // Find the deviceId for this meshNodeId so we can update peersRef
    for (const [deviceId, nodeId] of nodeIdByDeviceId.current) {
      if (nodeId === meshNodeId) {
        const existing = peersRef.current.get(deviceId);
        if (existing) {
          peersRef.current.set(deviceId, { ...existing, lastSeen: Date.now() });
          // No need to call setPeers — UI only cares about peer identity and
          // rssi, not lastSeen. Avoids spurious FlashList re-renders.
        }
        return;
      }
    }
    // Fallback: try localName-based match (pre-resolve placeholder)
    for (const [deviceId, peer] of peersRef.current) {
      if (peer.nodeId === meshNodeId) {
        peersRef.current.set(deviceId, { ...peer, lastSeen: Date.now() });
        return;
      }
    }
  }, []);

  return { sendTo, resolvePeerNodeId, refreshPeerActivity };
}

// ─────────────────────────────────────────────────────────────────────────────
// Connect and subscribe to GATT notifications (inbound RX)
// ─────────────────────────────────────────────────────────────────────────────

async function connectAndSubscribe(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  manager: any,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  device: any,
  tryReassemble: (deviceId: string, chunk: string) => string | null,
  onMessage: (msg: BleMessage) => void
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
): Promise<any[] | null> {
  try {
    const connected = await manager.connectToDevice(device.id);

    try {
      ingestBluetoothPeer({
        id: device.id,
        name: device.name || device.localName || "BLE GATT Device",
        rssi: typeof device.rssi === "number" ? device.rssi : undefined,
        mode: "BLE_GATT",
      });
    } catch (meshError) {
      console.log("[MauriMeshBLE] Bluetooth Super Mesh GATT ingest failed:", meshError);
    }

    await connected.discoverAllServicesAndCharacteristics();

    const sub = connected.monitorCharacteristicForService(
      MESH_SERVICE_UUID,
      MESH_CHAR_UUID,
      (err: unknown, characteristic: unknown) => {
        if (err) return;
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const char = characteristic as any;
        if (!char?.value) return;

        const complete = tryReassemble(device.id, char.value);
        if (!complete) return;

        try {
          const parsed = JSON.parse(complete);
          // Inject the BLE hardware device ID so the caller can maintain
          // a deviceId → meshNodeId mapping (they're different namespaces).
          const msg: BleMessage = { ...parsed, fromDeviceId: device.id };
          onMessage(msg);
        } catch {
          // malformed packet — discard
        }
      }
    );

    return [sub];
  } catch {
    return null;
  }
}
