import React, { useMemo, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import {
  decideMessageAckFallback,
  FallbackMessagePacket,
  MessageFallbackTransport,
} from "../maurimesh/message-fallback";
import { mauriTheme } from "../theme/mauriTheme";
import { MauriButton } from "./MauriButton";
import { StatusPill } from "./StatusPill";

type Scenario = "relayAck" | "strictAck" | "offlineHold";

export function MessageFallbackPanel() {
  const [scenario, setScenario] = useState<Scenario>("relayAck");

  const packet: FallbackMessagePacket = useMemo(
    () => ({
      packetId: `MM-MSG-${scenario.toUpperCase()}`,
      from: "PHONE-A",
      to: "PHONE-B",
      bodyPreview: "Kia ora — fallback proof packet",
      payloadSizeBytes: scenario === "offlineHold" ? 512 : 2048,
      createdAt: Date.now(),
      urgency: scenario === "offlineHold" ? "emergency" : "high",
      requiresAck: true,
      preferredTransport: "BLE_DIRECT",
    }),
    [scenario]
  );

  const failedTransport: MessageFallbackTransport =
    scenario === "offlineHold" ? "OFFLINE_HOLD" : "BLE_DIRECT";

  const decision = decideMessageAckFallback(
    packet,
    failedTransport,
    scenario === "offlineHold"
      ? "No BLE, relay, Wi-Fi, or gateway path exists. Offline hold required."
      : "BLE direct failed or peer moved out of range.",
    {
      packetId: packet.packetId,
      strictAckReceived: scenario === "strictAck",
      relayAckReceived: scenario === "relayAck",
      routeObserved: scenario !== "offlineHold",
      elapsedMs: scenario === "offlineHold" ? 180_000 : 14_000,
      requiresAck: true,
    }
  );

  const delivered = decision.ackDecision.canClaimDelivered;

  return (
    <View style={styles.wrap}>
      <MauriPanel glow>
        <StatusPill
          label={delivered ? "DELIVERED" : "PENDING PROOF"}
          tone={delivered ? "success" : "warning"}
        />
        <Text style={styles.title}>Message Queue + ACK Fallback</Text>
        <Text style={styles.detail}>{decision.ackDecision.reason}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Selected State</Text>
        <Text style={styles.big}>{decision.selectedState}</Text>
        <Text style={styles.detail}>Proof label: {decision.ackDecision.proofLabel}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Queue Record</Text>
        <Text style={styles.rowText}>Attempt: {decision.queueRecord.attemptCount}</Text>
        <Text style={styles.rowText}>Last transport: {decision.queueRecord.lastTransportTried}</Text>
        <Text style={styles.rowText}>Proof hash: {decision.queueRecord.proofHashStatus}</Text>
        <Text style={styles.rowText}>Queue TTL: {decision.queueRecord.queueTtlMs} ms</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Retry Plan</Text>
        {decision.retryPlan.map((transport, index) => (
          <Text key={`${transport}-${index}`} style={styles.rowText}>
            {index + 1}. {transport}
          </Text>
        ))}
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Actions</Text>
        <Text style={styles.rowText}>Queue packet: {decision.shouldQueue ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Retry later: {decision.shouldRetryLater ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>
          Operator escalation: {decision.shouldEscalateToOperator ? "yes" : "no"}
        </Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Scenario</Text>
        <View style={styles.buttons}>
          <MauriButton title="Relay ACK" onPress={() => setScenario("relayAck")} />
          <MauriButton title="Strict ACK" onPress={() => setScenario("strictAck")} />
          <MauriButton title="Offline Hold" onPress={() => setScenario("offlineHold")} />
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
  title: {
    color: mauriTheme.colors.white,
    fontSize: 24,
    fontWeight: "900",
    marginTop: mauriTheme.spacing.sm,
  },
  sectionTitle: {
    color: mauriTheme.colors.greenstone,
    fontSize: 18,
    fontWeight: "900",
  },
  big: {
    color: mauriTheme.colors.white,
    fontSize: 24,
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
  buttons: {
    gap: mauriTheme.spacing.sm,
    marginTop: mauriTheme.spacing.md,
  },
});
