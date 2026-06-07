import { Text, View, StyleSheet } from "react-native";
import ScreenShell from "../components/ScreenShell";

const logLines: { time: string; level: string; msg: string }[] = [];

export default function DiagnosticLogsScreen() {
  return (
    <ScreenShell title="Diagnostics" subtitle="Export local mesh diagnostics">
      <View style={styles.card}>
        <View style={styles.cardHeader}>
          <Text style={styles.cardTitle}>Diagnostics Ready</Text>
          <View style={styles.readyPill}>
            <Text style={styles.readyText}>READY</Text>
          </View>
        </View>
        <Text style={styles.text}>
          Log export route connected. Tap Export to generate a diagnostic bundle.
        </Text>
      </View>

      <View style={styles.logBox}>
        <Text style={styles.logHeader}>RECENT EVENTS</Text>
        {logLines.length === 0 ? (
          <Text style={styles.logEmpty}>No events logged yet</Text>
        ) : (
          logLines.map((l, i) => (
            <View key={i} style={styles.logLine}>
              <Text style={styles.logTime}>{l.time}</Text>
              <Text style={[styles.logLevel, l.level === "WARN" && styles.logWarn]}>{l.level}</Text>
              <Text style={styles.logMsg}>{l.msg}</Text>
            </View>
          ))
        )}
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
  cardHeader: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 12,
  },
  cardTitle: { color: "#FFFFFF", fontSize: 20, fontWeight: "900", fontFamily: "Inter_700Bold" },
  readyPill: {
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 8,
    backgroundColor: "rgba(57,255,20,0.10)",
    borderWidth: 1,
    borderColor: "rgba(57,255,20,0.22)",
  },
  readyText: { color: "#39FF14", fontSize: 9, fontWeight: "900", fontFamily: "Inter_700Bold", letterSpacing: 2 },
  text: { color: "#94A3B8", fontSize: 14, fontFamily: "Inter_400Regular", lineHeight: 22 },
  logBox: {
    padding: 16,
    borderRadius: 18,
    backgroundColor: "#0B1220",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.07)",
  },
  logHeader: {
    color: "#94A3B8",
    fontSize: 9,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
    letterSpacing: 4,
    marginBottom: 12,
  },
  logLine: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    paddingVertical: 6,
    borderTopWidth: 1,
    borderColor: "rgba(255,255,255,0.05)",
  },
  logTime: { color: "#64748B", fontSize: 11, fontFamily: "Inter_400Regular", width: 68 },
  logLevel: { color: "#39FF14", fontSize: 11, fontWeight: "700", fontFamily: "Inter_700Bold", width: 36 },
  logWarn: { color: "#FACC15" },
  logMsg: { color: "#94A3B8", fontSize: 11, fontFamily: "Inter_400Regular", flex: 1 },
  logEmpty: { color: "#4A5568", fontSize: 13, fontFamily: "Inter_400Regular", textAlign: "center", paddingVertical: 16 },
});
