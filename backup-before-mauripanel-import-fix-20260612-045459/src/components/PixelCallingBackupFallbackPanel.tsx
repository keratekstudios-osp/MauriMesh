import React, { useMemo, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import {
  decidePixelCallingBackupFallback,
  PixelCallingBackupInput,
} from "../maurimesh/pixel-calling";
import { mauriTheme } from "../theme/mauriTheme";
import { MauriButton } from "./MauriButton";
import { StatusPill } from "./StatusPill";

type Scenario = "primaryFailed" | "noAudio" | "storeForward" | "primaryReady";

export function PixelCallingBackupFallbackPanel() {
  const [scenario, setScenario] = useState<Scenario>("primaryFailed");

  const input: PixelCallingBackupInput = useMemo(() => {
    const base: PixelCallingBackupInput = {
      callId: `MM-CALL-BACKUP-${scenario.toUpperCase()}`,
      primaryRuntimeReady: false,
      strictAckReceived: false,
      relayAckReceived: true,
      microphonePermission: true,
      speakerReady: true,
      bleControlAvailable: true,
      wifiAudioAvailable: false,
      internetGatewayAvailable: false,
      messageFallbackAvailable: true,
      storeForwardAvailable: true,
      hardwarePressure: "medium",
      userAccepted: true,
    };

    if (scenario === "noAudio") {
      return {
        ...base,
        microphonePermission: false,
        speakerReady: false,
      };
    }

    if (scenario === "storeForward") {
      return {
        ...base,
        bleControlAvailable: false,
        relayAckReceived: false,
        wifiAudioAvailable: false,
        internetGatewayAvailable: false,
      };
    }

    if (scenario === "primaryReady") {
      return {
        ...base,
        primaryRuntimeReady: true,
        strictAckReceived: true,
        wifiAudioAvailable: true,
        internetGatewayAvailable: true,
        hardwarePressure: "low",
      };
    }

    return base;
  }, [scenario]);

  const decision = decidePixelCallingBackupFallback(input);

  return (
    <View style={styles.wrap}>
      <MauriPanel glow>
        <StatusPill
          label={decision.proofLabel}
          tone={decision.selectedStage === "PRIMARY_CALL_RUNTIME" ? "success" : "warning"}
        />
        <Text style={styles.title}>Pixel Calling Backup Fallback</Text>
        <Text style={styles.detail}>{decision.finalTruth}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Selected Backup Stage</Text>
        <Text style={styles.big}>{decision.selectedStage}</Text>
        <Text style={styles.rowText}>Reason: {decision.reason}</Text>
        <Text style={styles.rowText}>
          Can claim live call: {decision.canClaimLiveCall ? "yes" : "no"}
        </Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Fallback-Backup Order</Text>
        {decision.fallbackBackupOrder.map((stage, index) => (
          <Text key={`${stage}-${index}`} style={styles.rowText}>
            {index + 1}. {stage}
          </Text>
        ))}
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Backup Capabilities</Text>
        <Text style={styles.rowText}>Primary runtime: {decision.canUsePrimaryCallRuntime ? "ready" : "fallback"}</Text>
        <Text style={styles.rowText}>Backup control: {decision.canUseBackupControl ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Push-to-talk: {decision.canUsePushToTalk ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Voice note: {decision.canUseVoiceNote ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Text fallback: {decision.canUseTextFallback ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Store-forward: {decision.canUseStoreForward ? "yes" : "no"}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Try-Out Scenarios</Text>
        <View style={styles.buttons}>
          <MauriButton title="Primary Failed" onPress={() => setScenario("primaryFailed")} />
          <MauriButton title="No Audio" onPress={() => setScenario("noAudio")} />
          <MauriButton title="Store Forward" onPress={() => setScenario("storeForward")} />
          <MauriButton title="Primary Ready" onPress={() => setScenario("primaryReady")} />
        </View>
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
