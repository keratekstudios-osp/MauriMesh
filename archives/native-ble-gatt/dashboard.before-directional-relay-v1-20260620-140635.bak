import { useRouter } from "expo-router";
import React from "react";
import {
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";

type RouteItem = {
  title: string;
  route: string;
  subtitle: string;
  tone?: "green" | "blue" | "amber" | "red";
};

const routes: RouteItem[] = [
  {
    title: "Unified Spine Exam",
    route: "/maurimesh-spine-exam",
    subtitle: "Routing + resilience + governance + proof + exam spine.",
    tone: "green",
  },
  {
    title: "2-Hop Proof",
    route: "/proof-2-hop",
    subtitle: "A06 → S10 → ACK back to A06 proof workflow.",
    tone: "blue",
  },
  {
    title: "3-Device Relay Proof",
    route: "/3-device-proof",
    subtitle: "A06 → S10 → A16 → ACK back through relay.",
    tone: "blue",
  },
  {
    title: "BLE 3-Device Proof",
    route: "/ble-3-device-proof",
    subtitle: "BLE-labelled 3-device proof route if present.",
    tone: "blue",
  },
  {
    title: "Store-Forward Proof",
    route: "/store-forward-proof",
    subtitle: "Delayed delivery, hold, forward, ACK proof workflow.",
    tone: "green",
  },
  {
    title: "Native BLE/GATT Proof",
    route: "/native-ble-gatt-proof",
    subtitle: "Native callback capture gate. Packet-bound PASS remains pending.",
    tone: "amber",
  },
  {
    title: "Locked Proof Vault Guard",
    route: "/locked-proof-vault",
    subtitle: "Crash-safe vault guard. Does not claim native BLE/GATT PASS.",
    tone: "amber",
  },
  {
    title: "Proof Vault Health / Storage Reader",
    route: "/proof-vault-health",
    subtitle: "Reads vault entries, proof counts, bytes, checksums, packet IDs.",
    tone: "green",
  },
  {
    title: "Learner Core",
    route: "/learner-core",
    subtitle: "Evidence classifier, scoring, recovery, and trust state.",
    tone: "green",
  },
];

export default function DashboardScreen() {
  const router = useRouter();

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.kicker}>MAURIMESH SAFE RUNTIME</Text>
      <Text style={styles.title}>Safe Dashboard</Text>

      <View style={styles.truthBox}>
        <Text style={styles.truthTitle}>Truth State</Text>
        <Text style={styles.truthLine}>Safe Dashboard: ACTIVE</Text>
        <Text style={styles.truthLine}>Route entry: dependency-light</Text>
        <Text style={styles.truthLine}>Proof-screen workflow: ALLOWED</Text>
        <Text style={styles.truthLine}>
          Native BLE/GATT packet-bound PASS: NOT CLAIMED
        </Text>
        <Text style={styles.truthLine}>Vault guard: /locked-proof-vault</Text>
        <Text style={styles.truthLine}>
          Storage reader: /proof-vault-health
        </Text>
      </View>

      <Text style={styles.section}>Proof + Recovery Routes</Text>

      {routes.map((item) => (
        <RouteCard
          key={item.route}
          item={item}
          onPress={() => router.push(item.route as never)}
        />
      ))}

      <View style={styles.warningBox}>
        <Text style={styles.warningTitle}>Native BLE/GATT Truth Lock</Text>
        <Text style={styles.warningText}>
          This dashboard only opens routes. It does not claim native BLE/GATT
          packet-bound PASS. Final PASS requires the same packetId inside native
          BLE/GATT transport logs from physical devices.
        </Text>
      </View>

      <Text style={styles.footer}>
        If a route crashes, repair that route only. Do not destroy existing
        proof logic, vault evidence, ACK logic, or store-forward logic.
      </Text>
    </ScrollView>
  );
}

function RouteCard({
  item,
  onPress,
}: {
  item: RouteItem;
  onPress: () => void;
}) {
  const toneStyle =
    item.tone === "blue"
      ? styles.blue
      : item.tone === "amber"
        ? styles.amber
        : item.tone === "red"
          ? styles.red
          : styles.green;

  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.card,
        toneStyle,
        pressed && { opacity: 0.75, transform: [{ scale: 0.985 }] },
      ]}
    >
      <Text style={styles.cardTitle}>{item.title}</Text>
      <Text style={styles.route}>{item.route}</Text>
      <Text style={styles.cardSubtitle}>{item.subtitle}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: "#020403",
  },
  content: {
    padding: 20,
    paddingBottom: 56,
    gap: 14,
  },
  kicker: {
    color: "#00D084",
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 2,
    marginTop: 8,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 38,
    lineHeight: 42,
    fontWeight: "900",
  },
  section: {
    color: "#FFFFFF",
    fontSize: 22,
    fontWeight: "900",
    marginTop: 8,
  },
  truthBox: {
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.35)",
    backgroundColor: "rgba(0,32,20,0.72)",
    borderRadius: 22,
    padding: 16,
    gap: 6,
  },
  truthTitle: {
    color: "#00D084",
    fontSize: 18,
    fontWeight: "900",
    marginBottom: 4,
  },
  truthLine: {
    color: "rgba(255,255,255,0.84)",
    fontSize: 14,
    lineHeight: 20,
    fontWeight: "700",
  },
  card: {
    borderWidth: 1,
    borderRadius: 20,
    padding: 16,
    gap: 6,
    backgroundColor: "rgba(255,255,255,0.055)",
  },
  green: {
    borderColor: "rgba(0,208,132,0.42)",
  },
  blue: {
    borderColor: "rgba(56,189,248,0.42)",
  },
  amber: {
    borderColor: "rgba(245,158,11,0.48)",
  },
  red: {
    borderColor: "rgba(239,68,68,0.5)",
  },
  cardTitle: {
    color: "#FFFFFF",
    fontSize: 18,
    fontWeight: "900",
  },
  route: {
    color: "#00D084",
    fontSize: 12,
    fontWeight: "900",
  },
  cardSubtitle: {
    color: "rgba(255,255,255,0.72)",
    fontSize: 14,
    lineHeight: 20,
  },
  warningBox: {
    borderWidth: 1,
    borderColor: "rgba(245,158,11,0.5)",
    backgroundColor: "rgba(245,158,11,0.08)",
    borderRadius: 20,
    padding: 16,
    gap: 8,
    marginTop: 8,
  },
  warningTitle: {
    color: "#F59E0B",
    fontSize: 17,
    fontWeight: "900",
  },
  warningText: {
    color: "rgba(255,255,255,0.78)",
    lineHeight: 21,
    fontWeight: "700",
  },
  footer: {
    color: "rgba(255,255,255,0.62)",
    lineHeight: 21,
    fontWeight: "700",
    marginTop: 8,
  },
});
