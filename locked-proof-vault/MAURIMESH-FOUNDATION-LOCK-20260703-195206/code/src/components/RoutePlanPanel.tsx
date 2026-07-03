import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

type Hop = {
  nodeId: string;
  transport: string;
  score: number;
  reason: string;
};

export function RoutePlanPanel({
  routePlan,
}: {
  routePlan?: {
    totalScore: number;
    transport: string;
    decisionReason: string;
    storeAndForward: boolean;
    governanceApproved: boolean;
    hops: Hop[];
  };
}) {
  return (
    <View style={styles.card}>
      <Text style={styles.title}>Adaptive Mesh Routing Intelligence</Text>
      {!routePlan ? (
        <Text style={styles.empty}>No route plan yet.</Text>
      ) : (
        <>
          <Text style={styles.summary}>
            {routePlan.decisionReason}
          </Text>
          <View style={styles.row}>
            <Text style={styles.k}>Transport</Text>
            <Text style={styles.v}>{routePlan.transport}</Text>
          </View>
          <View style={styles.row}>
            <Text style={styles.k}>Score</Text>
            <Text style={styles.v}>{Math.round(routePlan.totalScore * 100)}%</Text>
          </View>
          <View style={styles.row}>
            <Text style={styles.k}>Store + Forward</Text>
            <Text style={styles.v}>{routePlan.storeAndForward ? "YES" : "NO"}</Text>
          </View>
          <View style={styles.row}>
            <Text style={styles.k}>Governance</Text>
            <Text style={styles.v}>{routePlan.governanceApproved ? "APPROVED" : "REJECTED"}</Text>
          </View>

          {routePlan.hops.map((hop, index) => (
            <View key={`${hop.nodeId}-${index}`} style={styles.hop}>
              <Text style={styles.hopTitle}>Hop {index + 1}: {hop.nodeId}</Text>
              <Text style={styles.hopText}>{hop.transport} · {Math.round(hop.score * 100)}%</Text>
              <Text style={styles.hopText}>{hop.reason}</Text>
            </View>
          ))}
        </>
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
    gap: mauriTheme.spacing.sm,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 20,
    fontWeight: "900",
  },
  empty: {
    color: mauriTheme.colors.mutedWhite,
  },
  summary: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    borderBottomWidth: 1,
    borderBottomColor: "rgba(255,255,255,0.08)",
    paddingVertical: 8,
    gap: 12,
  },
  k: {
    color: mauriTheme.colors.mutedWhite,
    fontWeight: "700",
  },
  v: {
    color: mauriTheme.colors.white,
    fontWeight: "900",
    textAlign: "right",
    flex: 1,
  },
  hop: {
    marginTop: 8,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    borderRadius: mauriTheme.radius.lg,
    padding: mauriTheme.spacing.md,
    backgroundColor: "rgba(0,208,132,0.08)",
    gap: 4,
  },
  hopTitle: {
    color: mauriTheme.colors.greenstone,
    fontWeight: "900",
  },
  hopText: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 20,
  },
});
