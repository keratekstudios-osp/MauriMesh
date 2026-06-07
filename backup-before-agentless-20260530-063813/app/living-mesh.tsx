import { useEffect, useState } from "react";
import { ActivityIndicator, StyleSheet, Text, View } from "react-native";
import { StatusBar } from "expo-status-bar";
import ScreenShell from "../components/ScreenShell";
import { LivingMeshCanvas } from "../src/components/LivingMeshCanvas";
import { getMeshStatus, type MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

const { colors } = mauriTheme;

export default function LivingMeshScreen() {
  const [status, setStatus] = useState<MeshStatus | null>(null);
  const [loading, setLoading] = useState(true);

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
    const interval = setInterval(load, 6000);
    return () => {
      alive = false;
      clearInterval(interval);
    };
  }, []);

  return (
    <>
      <StatusBar style="light" />
      <ScreenShell title="Living Mesh" subtitle="Topology visualiser · offline engine">
        {loading ? (
          <View style={styles.center}>
            <ActivityIndicator color={colors.greenstone} size="large" />
            <Text style={styles.loadingText}>Scanning mesh topology…</Text>
          </View>
        ) : status ? (
          <>
            {/* Stats row */}
            <View style={styles.statsRow}>
              <View style={styles.statChip}>
                <Text style={[styles.statValue, { color: colors.greenstone }]}>
                  {status.nodeCount}
                </Text>
                <Text style={styles.statLabel}>Active Nodes</Text>
              </View>
              <View style={styles.statChip}>
                <Text style={[styles.statValue, { color: colors.blueWeb }]}>
                  {status.routeCount}
                </Text>
                <Text style={styles.statLabel}>Routes</Text>
              </View>
              <View style={styles.statChip}>
                <Text style={[styles.statValue, {
                  color: status.mode === "LIVE"
                    ? colors.greenstone
                    : status.mode === "SIMULATION"
                    ? colors.warning
                    : colors.danger,
                }]}>
                  {status.mode === "LIVE" ? "LIVE" : status.mode === "SIMULATION" ? "SIM" : "N/A"}
                </Text>
                <Text style={styles.statLabel}>API</Text>
              </View>
            </View>

            {/* Living mesh canvas with nodes + routes */}
            <LivingMeshCanvas
              nodes={status.nodes}
              routes={status.routes}
              mode={status.mode}
            />

            {/* Simulation disclaimer */}
            {status.mode !== "LIVE" && (
              <View style={styles.disclaimerCard}>
                <Text style={styles.disclaimerIcon}>⚠</Text>
                <Text style={styles.disclaimerText}>
                  {status.message}
                </Text>
              </View>
            )}

            {/* Bridge status */}
            <View style={styles.infoCard}>
              <View style={styles.infoRow}>
                <Text style={styles.infoIcon}>▣</Text>
                <View style={{ flex: 1 }}>
                  <Text style={styles.infoTitle}>Mesh Bridge</Text>
                  <Text style={styles.infoSub}>
                    {status.mode === "LIVE"
                      ? "Store-and-forward queue active"
                      : "Store-and-forward queue inactive · BLE required"}
                  </Text>
                </View>
                <View style={[
                  styles.statusPill,
                  {
                    backgroundColor: status.mode === "LIVE" ? colors.greenDim  : colors.amberDim,
                    borderColor:     status.mode === "LIVE" ? colors.greenBorder : colors.amberBorder,
                  },
                ]}>
                  <Text style={[
                    styles.statusPillText,
                    { color: status.mode === "LIVE" ? colors.greenstone : colors.warning },
                  ]}>
                    {status.mode === "LIVE" ? "ACTIVE" : "OFFLINE"}
                  </Text>
                </View>
              </View>
            </View>
          </>
        ) : null}
      </ScreenShell>
    </>
  );
}

const styles = StyleSheet.create({
  center: {
    alignItems: "center",
    paddingTop: 80,
    gap: 16,
  },
  loadingText: {
    color: "#94A3B8",
    fontSize: 14,
    fontFamily: "Inter_400Regular",
  },
  statsRow: {
    flexDirection: "row",
    gap: 10,
    marginBottom: 16,
  },
  statChip: {
    flex: 1,
    padding: 16,
    borderRadius: 18,
    backgroundColor: "#0B1220",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.07)",
    alignItems: "center",
    gap: 4,
  },
  statValue: {
    fontSize: 22,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
  },
  statLabel: {
    color: "#94A3B8",
    fontSize: 10,
    fontWeight: "700",
    fontFamily: "Inter_700Bold",
    letterSpacing: 1,
  },
  disclaimerCard: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 10,
    padding: 16,
    borderRadius: 16,
    backgroundColor: colors.amberDim,
    borderWidth: 1,
    borderColor: colors.amberBorder,
    marginTop: 14,
  },
  disclaimerIcon: {
    color: colors.warning,
    fontSize: 16,
    flexShrink: 0,
    marginTop: 1,
  },
  disclaimerText: {
    flex: 1,
    color: colors.warning,
    fontSize: 12,
    fontFamily: "Inter_400Regular",
    lineHeight: 18,
  },
  infoCard: {
    padding: 20,
    borderRadius: 20,
    backgroundColor: "#101827",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.07)",
    marginTop: 14,
  },
  infoRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 14,
  },
  infoIcon: {
    color: "#00BFFF",
    fontSize: 28,
  },
  infoTitle: {
    color: "#FFFFFF",
    fontSize: 16,
    fontWeight: "800",
    fontFamily: "Inter_700Bold",
  },
  infoSub: {
    color: "#94A3B8",
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    marginTop: 3,
    lineHeight: 18,
  },
  statusPill: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 10,
    borderWidth: 1,
    flexShrink: 0,
  },
  statusPillText: {
    fontSize: 9,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
    letterSpacing: 2,
  },
});
