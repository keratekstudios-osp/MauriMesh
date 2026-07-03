import React from "react";
import { SafeAreaView, ScrollView, StyleSheet, Text, View } from "react-native";

export default function LockedProofVaultScreen() {
  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView contentContainerStyle={styles.wrap}>
        <Text style={styles.kicker}>MAURIMESH</Text>
        <Text style={styles.title}>Locked Proof Vault</Text>
        <Text style={styles.subtitle}>
          Safe runtime proof vault route. This screen avoids undefined helpers,
          native BLE calls, heavy vault imports, and unguarded proof functions.
        </Text>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>Crash Guard</Text>
          <Text style={styles.body}>
            Previous /locked-proof-vault crash was a JavaScript runtime fault:
            TypeError: undefined is not a function. This fallback prevents that
            route from crashing the APK while preserving the proof foundation.
          </Text>
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>Proof Truth</Text>
          <Text style={styles.body}>
            No BLE/GATT packet-bound PASS is claimed here. Real proof still
            requires physical-device logs, packetId matching, relay evidence,
            and ACK return confirmation.
          </Text>
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>3-Device Target</Text>
          <Text style={styles.body}>
            A06-1 TX → S10 Relay → A06-2 RX → ACK back through S10 → A06-1.
            PASS requires the same packetId across the required path.
          </Text>
        </View>

        <Text style={styles.footer}>
          Final truth: safe route patch only. No native BLE/GATT proof claimed.
        </Text>
      </ScrollView>
    </SafeAreaView>
  );
}

const colors = {
  black: "#020403",
  panel: "rgba(2,12,8,0.92)",
  border: "rgba(34,197,94,0.32)",
  greenstone: "#00D084",
  white: "#FFFFFF",
  muted: "rgba(255,255,255,0.72)",
  warning: "#F59E0B",
};

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.black },
  wrap: { padding: 22, gap: 16 },
  kicker: {
    color: colors.greenstone,
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 2,
  },
  title: {
    color: colors.white,
    fontSize: 34,
    fontWeight: "900",
  },
  subtitle: {
    color: colors.muted,
    fontSize: 15,
    lineHeight: 22,
  },
  card: {
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.panel,
    borderRadius: 22,
    padding: 18,
    gap: 8,
  },
  cardTitle: {
    color: colors.white,
    fontSize: 18,
    fontWeight: "900",
  },
  body: {
    color: colors.muted,
    fontSize: 14,
    lineHeight: 21,
  },
  footer: {
    color: colors.warning,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
  },
});
