import React, { useMemo, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import {
  decidePixelCallingRuntime,
  PixelCallInput,
} from "../maurimesh/pixel-calling";
import { mauriTheme } from "../theme/mauriTheme";
import { MauriButton } from "./MauriButton";
import { StatusPill } from "./StatusPill";

import { MauriPanel } from "./MauriPanel";
type Scenario = "ringing" | "fallback" | "strictReady";

export function PixelCallingRuntimePanel() {
  const [scenario, setScenario] = useState<Scenario>("fallback");

  const input: PixelCallInput = useMemo(
    () => ({
      callId: `MM-CALL-${scenario.toUpperCase()}`,
      from: "PHONE-A",
      to: "PHONE-B",
      microphonePermission: true,
      speakerReady: true,
      bleControlAvailable: true,
      wifiLocalAvailable: scenario !== "ringing",
      wifiDirectReady: false,
      internetGatewayAvailable: true,
      strictAckReceived: scenario === "strictReady",
      relayAckReceived: scenario === "fallback",
      hardwarePressure: "low",
      batteryPercent: 77,
      userAccepted: scenario !== "ringing",
      timestamp: Date.now(),
    }),
    [scenario]
  );

  const decision = decidePixelCallingRuntime(input);

  return (
    <View style={styles.wrap}>
      <MauriPanel glow>
        <StatusPill
          label={decision.uiTruthLabel}
          tone={decision.canClaimConnected ? "success" : "warning"}
        />
        <Text style={styles.title}>Pixel Calling Runtime</Text>
        <Text style={styles.detail}>{decision.reason}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Call State</Text>
        <Text style={styles.big}>{decision.state}</Text>
        <Text style={styles.rowText}>Transport: {decision.selectedTransport}</Text>
        <Text style={styles.rowText}>
          Can attempt live call: {decision.canAttemptLiveCall ? "yes" : "no"}
        </Text>
        <Text style={styles.rowText}>
          Can claim connected: {decision.canClaimConnected ? "yes" : "no"}
        </Text>
        <Text style={styles.rowText}>
          Fallback active: {decision.shouldFallback ? "yes" : "no"}
        </Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Fallback Order</Text>
        {decision.fallbackOrder.map((transport, index) => (
          <Text key={`${transport}-${index}`} style={styles.rowText}>
            {index + 1}. {transport}
          </Text>
        ))}
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Proof Events</Text>
        {decision.proofEvents.map((event) => (
          <Text key={event.id} style={styles.bullet}>
            • {event.stage} · {event.state} · {event.transport}
          </Text>
        ))}
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Try-Out Controls</Text>
        <View style={styles.buttons}>
          <MauriButton title="Ringing" onPress={() => setScenario("ringing")} />
          <MauriButton title="Fallback" onPress={() => setScenario("fallback")} />
          <MauriButton title="Strict Ready" onPress={() => setScenario("strictReady")} />
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
  bullet: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 22,
  },
  buttons: {
    gap: mauriTheme.spacing.sm,
    marginTop: mauriTheme.spacing.md,
  },
});
