import { useRouter } from "expo-router";
import React from "react";
import {
  Alert,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

type RouteButton = {
  title: string;
  route: string;
  note: string;
};

const ROUTES: RouteButton[] = [
  {
    title: "2-Hop Proof",
    route: "/ble-2-hop-proof",
    note: "A06 -> S10 -> ACK back to A06",
  },
  {
    title: "3-Device Relay Proof",
    route: "/3-device-proof",
    note: "A06 -> S10 -> A16 -> ACK return",
  },
  {
    title: "BLE 3-Device Proof",
    route: "/ble-3-device-proof",
    note: "BLE-labelled 3-device proof workflow",
  },
  {
    title: "Store-Forward Proof",
    route: "/store-forward-proof",
    note: "S10 stores while A16 is offline, forwards on return",
  },
  {
    title: "Raw Proof Vault",
    route: "/locked-proof-vault",
    note: "Inspect stored AsyncStorage proof/vault keys",
  },
  {
    title: "Proof Vault Health",
    route: "/proof-vault-health",
    note: "Count proof entries, bytes, packet IDs, checksum",
  },
  {
    title: "Learner Core",
    route: "/learner-core",
    note: "Classify evidence and recovery decisions",
  },
];

function SafeRouteButton({ title, route, note }: RouteButton) {
  const router = useRouter();

  function openRoute() {
    try {
      console.log(`MAURIMESH_SAFE_DASHBOARD_OPEN | route=${route}`);
      router.push(route as never);
    } catch (err) {
      const message = err instanceof Error ? err.message : "Unknown route error";
      console.log(`MAURIMESH_SAFE_DASHBOARD_ROUTE_ERROR | route=${route} | error=${message}`);
      Alert.alert("Route open failed", `${title}\n${route}\n\n${message}`);
    }
  }

  return (
    <TouchableOpacity style={styles.button} onPress={openRoute}>
      <Text style={styles.buttonTitle}>{title}</Text>
      <Text style={styles.buttonRoute}>{route}</Text>
      <Text style={styles.buttonNote}>{note}</Text>
    </TouchableOpacity>
  );
}

export default function SafeDashboardScreen() {
  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <View style={styles.header}>
        <Text style={styles.kicker}>MauriMesh Messenger</Text>
        <Text style={styles.title}>Safe Dashboard</Text>
        <Text style={styles.subtitle}>
          Dependency-light recovery dashboard. This screen avoids custom panels,
          heavy cards, native modules, animations, and experimental imports.
        </Text>
      </View>

      <View style={styles.truthBox}>
        <Text style={styles.truthTitle}>Truth State</Text>
        <Text style={styles.truthLine}>APK route entry: safe dashboard active</Text>
        <Text style={styles.truthLine}>Proof-screen workflow: allowed</Text>
        <Text style={styles.truthLine}>Native BLE/GATT packet-bound PASS: not claimed</Text>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Proof + Recovery Routes</Text>
        {ROUTES.map((item) => (
          <SafeRouteButton
            key={item.route}
            title={item.title}
            route={item.route}
            note={item.note}
          />
        ))}
      </View>

      <View style={styles.footer}>
        <Text style={styles.footerText}>
          If a route crashes, the dashboard itself should still reopen. Use logcat
          to identify the failed route, not the whole app.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: "#020403",
  },
  content: {
    padding: 18,
    paddingBottom: 36,
    gap: 16,
  },
  header: {
    padding: 18,
    borderRadius: 24,
    backgroundColor: "rgba(0,208,132,0.09)",
    borderColor: "rgba(0,208,132,0.32)",
    borderWidth: 1,
    gap: 8,
  },
  kicker: {
    color: "#00D084",
    fontSize: 13,
    fontWeight: "900",
    letterSpacing: 1.2,
    textTransform: "uppercase",
  },
  title: {
    color: "#FFFFFF",
    fontSize: 34,
    fontWeight: "900",
  },
  subtitle: {
    color: "rgba(255,255,255,0.76)",
    lineHeight: 22,
    fontSize: 15,
  },
  truthBox: {
    padding: 16,
    borderRadius: 20,
    backgroundColor: "rgba(255,255,255,0.055)",
    borderColor: "rgba(255,255,255,0.12)",
    borderWidth: 1,
    gap: 5,
  },
  truthTitle: {
    color: "#F59E0B",
    fontWeight: "900",
    fontSize: 17,
  },
  truthLine: {
    color: "#FFFFFF",
    lineHeight: 21,
    fontWeight: "700",
  },
  section: {
    gap: 12,
  },
  sectionTitle: {
    color: "#FFFFFF",
    fontSize: 21,
    fontWeight: "900",
  },
  button: {
    padding: 16,
    borderRadius: 20,
    backgroundColor: "rgba(3,20,12,0.92)",
    borderColor: "rgba(0,208,132,0.28)",
    borderWidth: 1,
    gap: 5,
  },
  buttonTitle: {
    color: "#FFFFFF",
    fontSize: 18,
    fontWeight: "900",
  },
  buttonRoute: {
    color: "#38BDF8",
    fontSize: 13,
    fontWeight: "800",
  },
  buttonNote: {
    color: "rgba(255,255,255,0.68)",
    lineHeight: 19,
  },
  footer: {
    padding: 14,
    borderRadius: 18,
    backgroundColor: "rgba(245,158,11,0.10)",
    borderColor: "rgba(245,158,11,0.22)",
    borderWidth: 1,
  },
  footerText: {
    color: "#FDE68A",
    lineHeight: 20,
    fontWeight: "700",
  },
});
