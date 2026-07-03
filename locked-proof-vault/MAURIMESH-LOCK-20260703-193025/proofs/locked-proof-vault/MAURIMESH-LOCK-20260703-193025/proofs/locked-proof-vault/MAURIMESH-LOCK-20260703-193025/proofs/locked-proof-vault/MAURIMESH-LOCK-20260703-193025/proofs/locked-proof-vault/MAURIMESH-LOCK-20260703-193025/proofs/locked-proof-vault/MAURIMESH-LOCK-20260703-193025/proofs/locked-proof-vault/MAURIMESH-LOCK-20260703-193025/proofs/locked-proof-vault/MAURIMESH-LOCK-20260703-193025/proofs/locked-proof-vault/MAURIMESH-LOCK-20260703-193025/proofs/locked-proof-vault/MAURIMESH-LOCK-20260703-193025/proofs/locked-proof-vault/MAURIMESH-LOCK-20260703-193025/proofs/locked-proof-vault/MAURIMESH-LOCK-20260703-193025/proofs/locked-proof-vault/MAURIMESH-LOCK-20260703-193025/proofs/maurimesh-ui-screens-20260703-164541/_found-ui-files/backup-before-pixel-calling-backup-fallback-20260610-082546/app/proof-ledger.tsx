import { PixelCallingRuntimePanel } from "../src/components/PixelCallingRuntimePanel";
import { MessageFallbackPanel } from "../src/components/MessageFallbackPanel";
import React from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { ProofLedgerPanel } from "../src/components/ProofLedgerPanel";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function ProofLedgerScreen() {
  return (
    <AppShell>
      <Text style={styles.title}>Proof Ledger</Text>
      <Text style={styles.subtitle}>
        SIMULATION ledger view. DEVICE PROOF can be added after APK/logcat validation.
      </Text>
      <ProofLedgerPanel />
          <MessageFallbackPanel />
          <PixelCallingRuntimePanel />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 34,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 22,
  },
});
