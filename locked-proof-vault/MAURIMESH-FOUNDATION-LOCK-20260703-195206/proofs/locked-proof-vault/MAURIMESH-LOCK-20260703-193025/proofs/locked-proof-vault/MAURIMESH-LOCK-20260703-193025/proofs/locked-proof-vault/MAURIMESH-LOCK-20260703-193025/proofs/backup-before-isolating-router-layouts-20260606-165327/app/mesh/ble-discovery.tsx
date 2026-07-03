import { useEffect, useRef, useState } from "react";
import { ActivityIndicator, NativeModules, StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshButton } from "../../src/components/ui/MeshButton";
import { MeshStatusPill } from "../../src/components/ui/MeshStatusPill";
import { NodeCard } from "../../src/components/mesh/NodeCard";
import { type NodeStatus } from "../../src/components/mesh/NodeCard";
import { EmptyScreen } from "../../src/components/system/EmptyScreen";
import {
  startMauriMeshBleScan,
  stopMauriMeshBleScan,
  onMauriMeshBlePeerSeen,
  onMauriMeshBleStatus,
} from "../../lib/mesh/nativeMauriMeshBle";
import { simulatedNodes, SIMULATION_NOTICE } from "../../src/lib/simulation";

// ── Runtime detection ────────────────────────────────────────────────────────

const IS_NATIVE = NativeModules.MauriMeshBle != null;

// ── Types ────────────────────────────────────────────────────────────────────

interface DiscoveredNode {
  nodeId: string;
  name: string;
  rssi: number;
  status: NodeStatus;
}

// ── Simulation fallback data ─────────────────────────────────────────────────

const SIM_NODES: DiscoveredNode[] = simulatedNodes.map((n) => ({
  nodeId: n.id,
  name: n.label,
  rssi: Math.round(-100 + n.signal * 0.7),
  status: (n.status === "offline"
    ? "offline"
    : n.status === "relay"
    ? "syncing"
    : "online") as NodeStatus,
}));

// ── Screen ───────────────────────────────────────────────────────────────────

export default function BleDiscoveryScreen() {
  const [scanning, setScanning] = useState(false);
  const [discovered, setDiscovered] = useState<DiscoveredNode[]>([]);
  const [scanHistory, setScanHistory] = useState<string[]>([]);
  const [statusNote, setStatusNote] = useState<string | null>(null);
  const unsubPeerRef = useRef<(() => void) | null>(null);
  const unsubStatusRef = useRef<(() => void) | null>(null);

  // Subscribe to native events while mounted
  useEffect(() => {
    if (!IS_NATIVE) return;

    // Peer-seen: native emits a raw JSON string (see MeshCentralClient.kt).
    // Payload: { address, rssi, txPower, connectable, isMauriMeshNode, beaconPayload? }
    // beaconPayload is base64-encoded JSON: { nodeId, publicKey, displayName? }
    const unsubPeer = onMauriMeshBlePeerSeen((raw: string) => {
      try {
        const peer = JSON.parse(raw) as {
          address: string;
          rssi: number;
          txPower: number | null;
          connectable: boolean;
          isMauriMeshNode: boolean;
          beaconPayload?: string;
        };

        // Decode identity beacon if present — gives us displayName and nodeId
        let displayName: string | undefined;
        let nodeId: string | undefined;
        if (peer.beaconPayload) {
          try {
            const beacon = JSON.parse(atob(peer.beaconPayload)) as {
              nodeId?: string;
              displayName?: string;
            };
            nodeId = beacon.nodeId;
            displayName = beacon.displayName;
          } catch {
            // beacon unreadable — fall through to MAC-based label
          }
        }

        const resolvedId = nodeId ?? peer.address;
        const resolvedName = displayName ?? `Node ${peer.address.slice(-5)}`;

        setDiscovered((prev) => {
          if (prev.some((n) => n.nodeId === resolvedId)) return prev;
          return [
            ...prev,
            {
              nodeId: resolvedId,
              name: resolvedName,
              rssi: peer.rssi,
              status: (peer.connectable ? "online" : "syncing") as NodeStatus,
            },
          ];
        });
      } catch {
        // ignore malformed event
      }
    });
    unsubPeerRef.current = unsubPeer;

    // Status events: scan_started, scan_stopped, scan_permission_denied, …
    const unsubStatus = onMauriMeshBleStatus((s: string) => {
      if (s === "scan_stopped") setScanning(false);
      if (s === "scan_permission_denied") {
        setStatusNote("Bluetooth permission denied — grant it in Settings → MauriMesh");
        setScanning(false);
      }
      if (s === "bluetooth_disabled") {
        setStatusNote("Bluetooth is off — enable it and try again");
        setScanning(false);
      }
    });
    unsubStatusRef.current = unsubStatus;

    return () => {
      unsubPeer();
      unsubStatus();
      unsubPeerRef.current = null;
      unsubStatusRef.current = null;
    };
  }, []);

  async function handleToggleScan() {
    if (scanning) {
      await stopMauriMeshBleScan();
      const ts = new Date().toLocaleTimeString([], {
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",
      });
      setScanHistory((h) => [
        `${ts} — ${discovered.length} node${discovered.length === 1 ? "" : "s"} found`,
        ...h.slice(0, 9),
      ]);
      setScanning(false);
    } else {
      setDiscovered([]);
      setStatusNote(null);
      const ok = await startMauriMeshBleScan(10_000); // 10-second scan window
      if (ok) {
        setScanning(true);
      } else {
        setStatusNote("Failed to start scan — check Bluetooth and permissions");
      }
    }
  }

  // In simulation mode show static nodes; in native mode show live discovered list
  const displayNodes = IS_NATIVE ? discovered : SIM_NODES;

  if (!scanning && displayNodes.length === 0 && IS_NATIVE) {
    return (
      <EmptyScreen
        icon="ᛒ"
        title="No Devices Found"
        message="No BLE mesh nodes were discovered nearby. Try moving closer to a peer or starting a new scan."
        actionLabel="⟳  Scan Again"
        onAction={handleToggleScan}
      />
    );
  }

  return (
    <ScreenWithHeader title="BLE Discovery" subtitle="Bluetooth Low Energy scanning">

      {/* Simulation notice */}
      {!IS_NATIVE && (
        <View style={styles.simBanner}>
          <Text style={styles.simText}>{SIMULATION_NOTICE}</Text>
        </View>
      )}

      {/* Status error note */}
      {statusNote && (
        <View style={styles.errorBanner}>
          <Text style={styles.errorText}>{statusNote}</Text>
        </View>
      )}

      <MeshCard title="Scan Status">
        <View style={styles.statusRow}>
          <MeshStatusPill
            label={scanning ? "Scanning…" : "Idle"}
            variant={scanning ? "syncing" : "offline"}
          />
          {scanning && <ActivityIndicator color={DS.mauriGreen} size="small" />}
        </View>
        <Text style={styles.meta}>
          Range: ~30 m · Channel: BLE 5.0 · Advertising interval: 250 ms
          {IS_NATIVE ? " · LIVE" : " · SIMULATION"}
        </Text>
        <MeshButton
          label={scanning ? "Stop Scan" : "Start BLE Scan"}
          onPress={handleToggleScan}
          variant={scanning ? "secondary" : "primary"}
          fullWidth
        />
      </MeshCard>

      <MeshCard title={`Discovered Nodes (${displayNodes.length})`}>
        {displayNodes.map((d) => (
          <NodeCard
            key={d.nodeId}
            nodeId={d.nodeId}
            name={d.name}
            rssi={d.rssi}
            status={d.status}
            role="peer"
          />
        ))}
      </MeshCard>

      <MeshCard title="Scan History">
        {scanHistory.length === 0 ? (
          <Text style={styles.historyRow}>◌  No scans yet this session</Text>
        ) : (
          scanHistory.map((e) => (
            <Text key={e} style={styles.historyRow}>◌  {e}</Text>
          ))
        )}
      </MeshCard>

    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  statusRow:   { flexDirection: "row", alignItems: "center", gap: spacing.sm, marginBottom: spacing.xs },
  meta:        { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, marginBottom: spacing.sm },
  historyRow:  { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular, paddingVertical: 4 },
  simBanner:   { backgroundColor: "#7c3aed22", borderColor: "#7c3aed55", borderWidth: 1, borderRadius: 10, padding: spacing.sm, marginBottom: spacing.sm },
  simText:     { color: "#a78bfa", fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, lineHeight: 16 },
  errorBanner: { backgroundColor: "#ef444422", borderColor: "#ef444455", borderWidth: 1, borderRadius: 10, padding: spacing.sm, marginBottom: spacing.sm },
  errorText:   { color: "#f87171", fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular },
});
