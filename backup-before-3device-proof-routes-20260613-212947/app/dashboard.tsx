import { useRouter } from "expo-router";
import React, { useMemo, useState } from "react";
import {
  Alert,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";

type RouteItem = {
  title: string;
  route: string;
  note: string;
  protected?: boolean;
};

const routes: RouteItem[] = [
  {
    title: "Store-Forward Proof",
    route: "/store-forward-proof",
    note: "A06 → S10 store → A16 return → ACK back.",
    protected: true,
  },
  {
    title: "3-Device Proof",
    route: "/3-device-proof",
    note: "A06 sender → S10 relay → A16 receiver.",
    protected: true,
  },
  {
    title: "2-Hop Proof",
    route: "/proof-2-hop",
    note: "Sender → relay → ACK return.",
    protected: true,
  },
  {
    title: "Raw Proof Vault",
    route: "/locked-proof-vault",
    note: "Proof archive and locked milestone records.",
  },
  {
    title: "Mesh Status",
    route: "/mesh-status",
    note: "Safe status screen.",
  },
  {
    title: "Settings",
    route: "/settings",
    note: "App settings.",
  },
];

function proofLog(message: string) {
  const line = `${new Date().toISOString()} | MAURIMESH_DASHBOARD_SAFE | ${message}`;

  try {
    console.log(line);
    console.warn(line);
  } catch (_) {}
}

function SafeButton({
  title,
  note,
  onPress,
  protectedRoute,
}: {
  title: string;
  note: string;
  onPress: () => void;
  protectedRoute?: boolean;
}) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.button,
        protectedRoute && styles.protectedButton,
        pressed && styles.pressed,
      ]}
    >
      <Text style={styles.buttonTitle}>{title}</Text>
      <Text style={styles.buttonNote}>{note}</Text>
    </Pressable>
  );
}

export default function DashboardScreen() {
  const router = useRouter();
  const [lastAction, setLastAction] = useState("Dashboard loaded safely.");

  const deviceLabel = useMemo(() => {
    return `${Platform.OS.toUpperCase()} dashboard safe mode`;
  }, []);

  function go(route: string, title: string) {
    try {
      const line = `NAVIGATE | title=${title} | route=${route}`;
      proofLog(line);
      setLastAction(line);
      router.push(route as never);
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      const line = `NAVIGATION_ERROR | title=${title} | route=${route} | error=${msg}`;
      proofLog(line);
      setLastAction(line);
      Alert.alert("MauriMesh navigation protected", msg);
    }
  }

  return (
    <View style={styles.safe}>
      <ScrollView contentContainerStyle={styles.content}>
        <View style={styles.headerCard}>
          <Text style={styles.kicker}>MAURIMESH MESSENGER</Text>
          <Text style={styles.title}>Safe Dashboard</Text>
          <Text style={styles.subtitle}>
            A06 crash fallback is active. This dashboard uses only stable
            React Native primitives and keeps proof routes accessible.
          </Text>

          <View style={styles.statusRow}>
            <Text style={styles.statusPill}>SAFE MODE</Text>
            <Text style={styles.statusPill}>A06 READY</Text>
          </View>
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>Runtime Status</Text>
          <Text style={styles.cardText}>{deviceLabel}</Text>
          <Text style={styles.cardText}>Last action: {lastAction}</Text>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Proof Routes</Text>

          {routes.map((item) => (
            <SafeButton
              key={item.route}
              title={item.title}
              note={item.note}
              protectedRoute={item.protected}
              onPress={() => go(item.route, item.title)}
            />
          ))}
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>Crash Fix Boundary</Text>
          <Text style={styles.cardText}>
            This does not delete BLE, routing, ACK, proof vault, or store-forward
            logic. It only replaces the dashboard entry screen with a stable
            shell so A06 can open the app safely.
          </Text>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: "#020403",
  },
  content: {
    padding: 18,
    paddingBottom: 42,
  },
  headerCard: {
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.35)",
    backgroundColor: "rgba(2,12,8,0.92)",
    borderRadius: 26,
    padding: 20,
    marginBottom: 14,
  },
  kicker: {
    color: "#00D084",
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 1.4,
    marginBottom: 8,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 36,
    fontWeight: "900",
    marginBottom: 8,
  },
  subtitle: {
    color: "rgba(255,255,255,0.74)",
    fontSize: 15,
    lineHeight: 22,
  },
  statusRow: {
    flexDirection: "row",
    flexWrap: "wrap",
    marginTop: 14,
  },
  statusPill: {
    color: "#00D084",
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.55)",
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6,
    marginRight: 8,
    marginBottom: 8,
    fontSize: 11,
    fontWeight: "900",
  },
  card: {
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.12)",
    backgroundColor: "rgba(255,255,255,0.055)",
    borderRadius: 22,
    padding: 16,
    marginBottom: 14,
  },
  cardTitle: {
    color: "#FFFFFF",
    fontSize: 18,
    fontWeight: "900",
    marginBottom: 8,
  },
  cardText: {
    color: "rgba(255,255,255,0.72)",
    fontSize: 14,
    lineHeight: 20,
  },
  section: {
    marginBottom: 14,
  },
  sectionTitle: {
    color: "#FFFFFF",
    fontSize: 22,
    fontWeight: "900",
    marginBottom: 10,
  },
  button: {
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.28)",
    backgroundColor: "rgba(2,12,8,0.9)",
    borderRadius: 20,
    padding: 16,
    marginBottom: 10,
  },
  protectedButton: {
    borderColor: "rgba(0,208,132,0.72)",
    backgroundColor: "rgba(0,208,132,0.12)",
  },
  pressed: {
    opacity: 0.75,
    transform: [{ scale: 0.985 }],
  },
  buttonTitle: {
    color: "#FFFFFF",
    fontSize: 17,
    fontWeight: "900",
    marginBottom: 4,
  },
  buttonNote: {
    color: "rgba(255,255,255,0.68)",
    fontSize: 13,
    lineHeight: 18,
  },
});
