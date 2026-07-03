import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

type LedgerEvent = {
  packetId: string;
  status: string;
  atMs: number;
  nodeId?: string;
  reason?: string;
};

export function DeliveryLedgerPanel({ ledger }: { ledger: LedgerEvent[] }) {
  return (
    <View style={styles.card}>
      <Text style={styles.title}>Delivery Proof + ACK Ledger</Text>
      {ledger.length === 0 ? (
        <Text style={styles.empty}>No delivery events yet.</Text>
      ) : (
        ledger.slice(-8).reverse().map((event, index) => (
          <View key={`${event.packetId}-${event.status}-${index}`} style={styles.event}>
            <Text style={styles.status}>{event.status}</Text>
            <Text style={styles.text}>{event.reason || "Ledger event recorded."}</Text>
            <Text style={styles.meta}>
              {event.nodeId ? `${event.nodeId} · ` : ""}
              {new Date(event.atMs).toLocaleTimeString()}
            </Text>
          </View>
        ))
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.md,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 20,
    fontWeight: "900",
  },
  empty: {
    color: mauriTheme.colors.mutedWhite,
  },
  event: {
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.08)",
    borderRadius: mauriTheme.radius.lg,
    padding: mauriTheme.spacing.md,
    gap: 4,
  },
  status: {
    color: mauriTheme.colors.greenstone,
    fontWeight: "900",
  },
  text: {
    color: mauriTheme.colors.white,
    lineHeight: 20,
  },
  meta: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 12,
  },
});
