import React, { useMemo, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import {
  decideBackupHybridWifiBleRoute,
  HybridLinkState,
  HybridMeshDecision,
  HybridMeshPacket,
} from "../maurimesh/hybrid-wifi-ble-mesh";
import { mauriTheme } from "../theme/mauriTheme";
import { MauriButton } from "./MauriButton";
import { StatusPill } from "./StatusPill";

import { MauriPanel } from "./MauriPanel";
function toneForTransport(
  transport: string
): "success" | "warning" | "danger" | "info" {
  if (transport === "BLE_DIRECT") return "success";
  if (transport === "BLE_RELAY") return "info";
  if (transport === "STORE_FORWARD") return "warning";
  if (transport === "OFFLINE_HOLD") return "danger";
  return "success";
}

export function HybridWifiBleMeshPanel() {
  const [scenario, setScenario] = useState<"normal" | "pressure" | "offline">("normal");

  const packet: HybridMeshPacket = {
    packetId: `MM-HYBRID-${scenario.toUpperCase()}`,
    from: "PHONE-A",
    to: "PHONE-B",
    createdAt: Date.now(),
    payloadSizeBytes: scenario === "pressure" ? 196000 : 4096,
    urgency: scenario === "offline" ? "normal" : "high",
    requiresAck: true,
  };

  const link: HybridLinkState = useMemo(() => {
    if (scenario === "offline") {
      return {
        bleDirectAvailable: false,
        bleRelayAvailable: false,
        wifiLocalAvailable: false,
        wifiDirectAvailable: false,
        internetGatewayAvailable: false,
        peerTrustScore: 62,
        routePressure: "high",
        batteryPressure: "medium",
        thermalPressure: "medium",
        payloadUrgency: "normal",
        payloadSizeBytes: packet.payloadSizeBytes,
        timestamp: Date.now(),
      };
    }

    if (scenario === "pressure") {
      return {
        bleDirectAvailable: true,
        bleRelayAvailable: true,
        wifiLocalAvailable: true,
        wifiDirectAvailable: true,
        internetGatewayAvailable: true,
        peerTrustScore: 86,
        routePressure: "high",
        batteryPressure: "high",
        thermalPressure: "high",
        payloadUrgency: "high",
        payloadSizeBytes: packet.payloadSizeBytes,
        timestamp: Date.now(),
      };
    }

    return {
      bleDirectAvailable: true,
      bleRelayAvailable: true,
      wifiLocalAvailable: true,
      wifiDirectAvailable: false,
      internetGatewayAvailable: true,
      peerTrustScore: 91,
      routePressure: "low",
      batteryPressure: "low",
      thermalPressure: "low",
      payloadUrgency: "high",
      payloadSizeBytes: packet.payloadSizeBytes,
      timestamp: Date.now(),
    };
  }, [scenario]);

  const decision: HybridMeshDecision = decideBackupHybridWifiBleRoute(packet, link);

  return (
    <View style={styles.wrap}>
      <MauriPanel glow>
        <StatusPill
          label={decision.selectedTransport}
          tone={toneForTransport(decision.selectedTransport)}
        />
        <Text style={styles.score}>{decision.confidence}%</Text>
        <Text style={styles.title}>Hybrid Wi-Fi + BLE Mesh</Text>
        <Text style={styles.detail}>{decision.reason}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Fallback Order</Text>
        {decision.fallbackOrder.map((item, index) => (
          <Text key={`${item}-${index}`} style={styles.rowText}>
            {index + 1}. {item}
          </Text>
        ))}
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Runtime Decision</Text>
        <Text style={styles.rowText}>Store-forward: {decision.shouldStoreForward ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Use gateway: {decision.shouldUseGateway ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Use relay: {decision.shouldUseRelay ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Offline hold: {decision.shouldHoldOffline ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Max hops: {decision.maxHops}</Text>
        <Text style={styles.rowText}>TTL: {decision.ttlMs} ms</Text>
        <Text style={styles.rowText}>Retry limit: {decision.retryLimit}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Proof Events</Text>
        {decision.proofEvents.slice(0, 7).map((event) => (
          <Text key={event.id} style={styles.bullet}>
            • {event.stage} · {event.transport} · {event.status}
          </Text>
        ))}
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Scenario</Text>
        <Text style={styles.detail}>
          Switch scenarios to test route failover: normal mesh, high hardware/network pressure, or full offline hold.
        </Text>
        <View style={styles.buttons}>
          <MauriButton title="Normal" onPress={() => setScenario("normal")} />
          <MauriButton title="Pressure" onPress={() => setScenario("pressure")} />
          <MauriButton title="Offline" onPress={() => setScenario("offline")} />
        </View>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Final Truth</Text>
        <Text style={styles.detail}>{decision.finalTruth}</Text>
      </MauriPanel>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    gap: mauriTheme.spacing.md,
  },
  score: {
    color: mauriTheme.colors.greenstone,
    fontSize: 54,
    fontWeight: "900",
    letterSpacing: -1.3,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 24,
    fontWeight: "900",
  },
  sectionTitle: {
    color: mauriTheme.colors.greenstone,
    fontSize: 18,
    fontWeight: "900",
  },
  detail: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  rowText: {
    color: mauriTheme.colors.white,
    lineHeight: 22,
  },
  bullet: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 22,
  },
  buttons: {
    gap: mauriTheme.spacing.sm,
    marginTop: mauriTheme.spacing.md,
  },
});
