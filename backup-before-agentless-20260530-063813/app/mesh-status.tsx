import { useEffect, useState } from "react";
import { ActivityIndicator, ScrollView, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import ScreenShell from "../components/ScreenShell";
import { getMeshStatus, type MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";
import { useBleReadiness } from "../hooks/useBleReadiness";
import { BleReadinessCard } from "../src/components/mesh/BleReadinessCard";
import { BleScanProof } from "../src/components/mesh/BleScanProof";

const { colors } = mauriTheme;

function StatusColor(mode: MeshStatus["mode"]) {
  if (mode === "LIVE")        return colors.greenstone;
  if (mode === "SIMULATION")  return colors.warning;
  return colors.danger;
}

export default function MeshStatusScreen() {
  const [status, setStatus] = useState<MeshStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const bleReadiness = useBleReadiness();

  useEffect(() => {
    let alive = true;
    async function load() {
      const result = await getMeshStatus();
      if (alive) {
        setStatus(result);
        setLoading(false);
      }
    }
    load();
    const interval = setInterval(load, 8000);
    return () => {
      alive = false;
      clearInterval(interval);
    };
  }, []);

  return (
    <>
      <StatusBar style="light" />
      <ScreenShell title="Mesh Status" subtitle="Network health & topology">
        {loading ? (
          <View style={styles.center}>
            <ActivityIndicator color={colors.greenstone} size="large" />
            <Text style={styles.loadingText}>Querying mesh…</Text>
          </View>
        ) : (
          <>
            {/* BLE readiness — permissions + hardware state */}
            <BleReadinessCard readiness={bleReadiness} />

            {/* BLE scan proof — start/stop scan, nearby devices */}
            <BleScanProof />

            {status && <>
            {/* Mode banner */}
            <View style={[
              styles.modeBanner,
              {
                backgroundColor: `${StatusColor(status.mode)}14`,
                borderColor:     `${StatusColor(status.mode)}36`,
              },
            ]}>
              <View style={[styles.modeDot, { backgroundColor: StatusColor(status.mode) }]} />
              <Text style={[styles.modeLabel, { color: StatusColor(status.mode) }]}>
                {status.mode}
              </Text>
              <Text style={styles.modeMessage} numberOfLines={2}>
                {status.message}
              </Text>
            </View>

            {/* Stats row */}
            <View style={styles.statsRow}>
              <StatCard label="Nodes"  value={status.nodeCount}  accent={colors.greenstone} />
              <StatCard label="Routes" value={status.routeCount} accent={colors.blueWeb}    />
              <StatCard
                label="Quality"
                value={status.mode === "LIVE" ? "LIVE" : "SIM"}
                accent={StatusColor(status.mode)}
              />
            </View>

            {/* Node list */}
            <View style={styles.card}>
              <Text style={styles.cardTitle}>NODE REGISTRY</Text>
              {status.nodes.map((node) => {
                const nc =
                  node.status === "online"  ? colors.greenstone :
                  node.status === "relay"   ? colors.blueWeb :
                  colors.warning;
                return (
                  <View key={node.id} style={styles.nodeRow}>
                    <View style={[styles.nodeDot, { backgroundColor: nc }]} />
                    <Text style={styles.nodeId}>{node.label}</Text>
                    <Text style={[styles.nodeStat, { color: nc }]}>{node.status.toUpperCase()}</Text>
                    <Text style={styles.nodeSignal}>{node.signal}%</Text>
                  </View>
                );
              })}
            </View>

            {/* Route list */}
            <View style={styles.card}>
              <Text style={styles.cardTitle}>ROUTE TABLE</Text>
              {status.routes.map((route) => {
                const qc = route.quality >= 80 ? colors.greenstone : route.quality >= 50 ? colors.blueWeb : colors.warning;
                return (
                  <View key={`${route.from}-${route.to}`} style={styles.routeRow}>
                    <Text style={styles.routeNode}>{route.from}</Text>
                    <Text style={styles.routeArrow}>→</Text>
                    <Text style={styles.routeNode}>{route.to}</Text>
                    <View style={styles.qualBar}>
                      <View style={[styles.qualFill, { width: `${route.quality}%` as unknown as number, backgroundColor: qc }]} />
                    </View>
                    <Text style={[styles.qualLabel, { color: qc }]}>{route.quality}%</Text>
                  </View>
                );
              })}
            </View>
            </>}
          </>
        )}
      </ScreenShell>
    </>
  );
}

function StatCard({ label, value, accent }: { label: string; value: number | string; accent: string }) {
  return (
    <View style={[styles.statCard, { borderColor: `${accent}28` }]}>
      <Text style={[styles.statValue, { color: accent }]}>{value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  center: {
    alignItems: "center",
    paddingTop: 60,
    gap: 16,
  },
  loadingText: {
    color: "#94A3B8",
    fontSize: 14,
    fontFamily: "Inter_400Regular",
  },
  modeBanner: {
    borderRadius: 20,
    borderWidth: 1,
    padding: 18,
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 12,
    flexWrap: "wrap",
    marginBottom: 16,
  },
  modeDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    marginTop: 3,
    flexShrink: 0,
  },
  modeLabel: {
    fontSize: 13,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
    letterSpacing: 3,
    flexShrink: 0,
  },
  modeMessage: {
    flex: 1,
    color: "#94A3B8",
    fontSize: 12,
    fontFamily: "Inter_400Regular",
    lineHeight: 18,
  },
  statsRow: {
    flexDirection: "row",
    gap: 10,
    marginBottom: 16,
  },
  statCard: {
    flex: 1,
    alignItems: "center",
    paddingVertical: 18,
    borderRadius: 18,
    backgroundColor: "#0B1220",
    borderWidth: 1,
    gap: 4,
  },
  statValue: {
    fontSize: 26,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
  },
  statLabel: {
    color: "#94A3B8",
    fontSize: 10,
    fontWeight: "700",
    fontFamily: "Inter_700Bold",
    letterSpacing: 2,
  },
  card: {
    borderRadius: 20,
    backgroundColor: "#101827",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.07)",
    padding: 18,
    gap: 10,
    marginBottom: 16,
  },
  cardTitle: {
    color: "#94A3B8",
    fontSize: 10,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
    letterSpacing: 4,
    marginBottom: 6,
  },
  nodeRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    paddingVertical: 4,
  },
  nodeDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    flexShrink: 0,
  },
  nodeId: {
    flex: 1,
    color: "#FFFFFF",
    fontSize: 14,
    fontWeight: "600",
    fontFamily: "Inter_600SemiBold",
  },
  nodeStat: {
    fontSize: 10,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
    letterSpacing: 1,
    width: 68,
    textAlign: "right",
  },
  nodeSignal: {
    color: "#94A3B8",
    fontSize: 12,
    fontFamily: "Inter_400Regular",
    width: 36,
    textAlign: "right",
  },
  routeRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    paddingVertical: 4,
  },
  routeNode: {
    color: "#FFFFFF",
    fontSize: 13,
    fontWeight: "800",
    fontFamily: "Inter_700Bold",
    width: 20,
  },
  routeArrow: {
    color: "#94A3B8",
    fontSize: 13,
  },
  qualBar: {
    flex: 1,
    height: 5,
    borderRadius: 3,
    backgroundColor: "rgba(255,255,255,0.07)",
    overflow: "hidden",
  },
  qualFill: {
    height: "100%",
    borderRadius: 3,
  },
  qualLabel: {
    fontSize: 12,
    fontWeight: "700",
    fontFamily: "Inter_700Bold",
    width: 34,
    textAlign: "right",
  },
});
