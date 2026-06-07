import { Text, View, StyleSheet } from "react-native";
import ScreenShell from "../components/ScreenShell";

export default function LocalStorageScreen() {
  return (
    <ScreenShell title="Local Storage" subtitle="Manage message retention">
      <View style={styles.card}>
        <Text style={styles.title}>Storage Manager</Text>
        <Text style={styles.text}>
          Retention controls and cache inspection connected. Message store is encrypted at rest.
        </Text>
      </View>

      <View style={styles.statsGrid}>
        <View style={styles.statCard}>
          <Text style={styles.statValue}>--</Text>
          <Text style={styles.statLabel}>Messages</Text>
        </View>
        <View style={styles.statCard}>
          <Text style={styles.statValue}>--</Text>
          <Text style={styles.statLabel}>Queue</Text>
        </View>
        <View style={styles.statCard}>
          <Text style={styles.statValue}>--</Text>
          <Text style={styles.statLabel}>Free Space</Text>
        </View>
        <View style={styles.statCard}>
          <Text style={[styles.statValue, { color: "#39FF14" }]}>AES</Text>
          <Text style={styles.statLabel}>Encryption</Text>
        </View>
      </View>
    </ScreenShell>
  );
}

const styles = StyleSheet.create({
  card: {
    padding: 24,
    borderRadius: 22,
    backgroundColor: "#101827",
    borderWidth: 1,
    borderColor: "rgba(57,255,20,0.16)",
    marginBottom: 16,
  },
  title: { color: "#FFFFFF", fontSize: 20, fontWeight: "900", fontFamily: "Inter_700Bold", marginBottom: 10 },
  text: { color: "#94A3B8", fontSize: 14, fontFamily: "Inter_400Regular", lineHeight: 22 },
  statsGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 10,
  },
  statCard: {
    width: "48%",
    padding: 18,
    borderRadius: 18,
    backgroundColor: "#0B1220",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.07)",
    alignItems: "center",
  },
  statValue: {
    color: "#FFFFFF",
    fontSize: 22,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
  },
  statLabel: {
    color: "#94A3B8",
    fontSize: 11,
    fontWeight: "700",
    fontFamily: "Inter_700Bold",
    marginTop: 4,
    letterSpacing: 1,
  },
});
