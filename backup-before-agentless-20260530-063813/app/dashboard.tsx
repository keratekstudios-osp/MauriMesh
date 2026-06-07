import { Pressable, ScrollView, Text, View, StyleSheet } from "react-native";
import { useRouter } from "expo-router";
import * as Haptics from "expo-haptics";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { safeNavigate } from "../lib/safeNavigate";

const CORE_CARDS = [
  {
    title: "Mesh Chat",
    subtitle: "Broadcast messages over BLE relay",
    route: "/chat",
    status: "Live",
    statusVariant: "live" as const,
    icon: "◌",
    accent: "#39FF14",
  },
  {
    title: "Living Mesh Core",
    subtitle: "3D visualiser · offline engine",
    route: "/living-mesh",
    status: "Offline",
    statusVariant: "offline" as const,
    icon: "▣",
    accent: "#00BFFF",
  },
  {
    title: "Configuration",
    subtitle: "Radio, routing & security",
    route: "/configuration",
    status: "",
    statusVariant: "none" as const,
    icon: "⚙",
    accent: "#94A3B8",
  },
];

const EXTENDED_CARDS = [
  {
    title: "Mesh Network",
    subtitle: "BLE discovery, peer mapping & routing",
    route: "/mesh",
    status: "BLE Init",
    statusVariant: "offline" as const,
    icon: "ᛒ",
    accent: "#39FF14",
  },
  {
    title: "Network Diagnostics",
    subtitle: "Latency, packets & delivery analytics",
    route: "/network",
    status: "",
    statusVariant: "none" as const,
    icon: "◈",
    accent: "#00BFFF",
  },
  {
    title: "Trust & Governance",
    subtitle: "Tikanga engine, trust scores & rules",
    route: "/trust",
    status: "",
    statusVariant: "none" as const,
    icon: "⬡",
    accent: "#39FF14",
  },
  {
    title: "Mesh Status",
    subtitle: "Node registry, routes & API health",
    route: "/mesh-status",
    status: "Live",
    statusVariant: "live" as const,
    icon: "◈",
    accent: "#39FF14",
  },
  {
    title: "Pixel Calling",
    subtitle: "Mesh-native encrypted voice calls",
    route: "/calling",
    status: "Ready",
    statusVariant: "live" as const,
    icon: "✆",
    accent: "#00BFFF",
  },
  {
    title: "Settings",
    subtitle: "Appearance, security & mesh controls",
    route: "/settings",
    status: "",
    statusVariant: "none" as const,
    icon: "◑",
    accent: "#94A3B8",
  },
];

export default function DashboardScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();

  async function go(route: string) {
    await Haptics.selectionAsync();
    safeNavigate(router, route);
  }

  return (
    <ScrollView
      style={styles.root}
      contentContainerStyle={{
        paddingTop: insets.top + 28,
        paddingBottom: insets.bottom + 48,
      }}
      showsVerticalScrollIndicator={false}
    >
      <View style={styles.header}>
        <View style={styles.logoWrap}>
          <View style={styles.logo}>
            <Text style={styles.logoText}>◉</Text>
          </View>
        </View>

        <View style={{ flex: 1 }}>
          <Text style={styles.title}>MAURIMESH</Text>
          <Text style={styles.subtitle}>SOVEREIGN MESH PROTOCOL</Text>
        </View>

        <View style={styles.pill}>
          <View style={styles.pillDot} />
          <Text style={styles.pillText}>OFFLINE MESH</Text>
        </View>
      </View>

      <View style={styles.rule} />

      <Text style={styles.section}>CORE SYSTEMS</Text>

      {CORE_CARDS.map((card) => (
        <CardRow key={card.title} card={card} onPress={() => go(card.route)} />
      ))}

      <View style={styles.rule} />

      <Text style={styles.section}>EXTENDED SYSTEMS</Text>

      {EXTENDED_CARDS.map((card) => (
        <CardRow key={card.title} card={card} onPress={() => go(card.route)} />
      ))}

      <Text style={styles.footer}>MauriMesh Core v1.4.2-alpha · Built for resilience</Text>
    </ScrollView>
  );
}

interface CardData {
  title: string; subtitle: string; route: string;
  status: string; statusVariant: "live" | "offline" | "none"; icon: string; accent: string;
}

function CardRow({ card, onPress }: { card: CardData; onPress: () => void }) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [styles.card, pressed && styles.cardPressed]}
    >
      <View style={[styles.cardIcon, { borderColor: `${card.accent}30` }]}>
        <Text style={[styles.cardIconText, { color: card.accent }]}>{card.icon}</Text>
      </View>

      {!!card.status && (
        <View style={[
          styles.status,
          card.statusVariant === "offline" && styles.statusOffline,
        ]}>
          <View style={[
            styles.statusDot,
            { backgroundColor: card.statusVariant === "offline" ? "#FACC15" : "#39FF14" },
          ]} />
          <Text style={[
            styles.statusText,
            card.statusVariant === "offline" && styles.statusTextOffline,
          ]}>
            {card.status}
          </Text>
        </View>
      )}

      <View style={styles.cardInner}>
        <Text style={styles.cardTitle}>{card.title}</Text>
        <Text style={styles.cardSubtitle}>{card.subtitle}</Text>
      </View>

      <Text style={[styles.arrow, { color: card.accent }]}>→</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: "#050816",
    paddingHorizontal: 24,
  },
  header: {
    flexDirection: "row",
    alignItems: "center",
    gap: 16,
  },
  logoWrap: {
    shadowColor: "#39FF14",
    shadowOpacity: 0.30,
    shadowRadius: 20,
    elevation: 8,
  },
  logo: {
    width: 72,
    height: 72,
    borderRadius: 36,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "rgba(57,255,20,0.10)",
    borderWidth: 1,
    borderColor: "rgba(57,255,20,0.28)",
  },
  logoText: {
    color: "#39FF14",
    fontSize: 34,
    fontWeight: "900",
  },
  title: {
    color: "#FFFFFF",
    fontSize: 26,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
    letterSpacing: 5,
  },
  subtitle: {
    marginTop: 4,
    color: "#39FF14",
    fontSize: 11,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
    letterSpacing: 3,
  },
  pill: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: "rgba(57,255,20,0.08)",
    borderWidth: 1,
    borderColor: "rgba(57,255,20,0.18)",
  },
  pillDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: "#39FF14",
  },
  pillText: {
    color: "#39FF14",
    fontSize: 10,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
    letterSpacing: 1,
  },
  rule: {
    height: 1,
    backgroundColor: "rgba(255,255,255,0.08)",
    marginTop: 28,
    marginBottom: 24,
  },
  section: {
    color: "#94A3B8",
    fontSize: 11,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
    letterSpacing: 6,
    marginBottom: 16,
  },
  card: {
    minHeight: 156,
    borderRadius: 28,
    padding: 24,
    marginBottom: 16,
    backgroundColor: "#101827",
    borderWidth: 1,
    borderColor: "rgba(57,255,20,0.14)",
    shadowColor: "#000",
    shadowOpacity: 0.30,
    shadowRadius: 12,
    elevation: 4,
  },
  cardPressed: {
    opacity: 0.88,
    transform: [{ scale: 0.984 }],
  },
  cardIcon: {
    width: 64,
    height: 64,
    borderRadius: 18,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#0B1220",
    borderWidth: 1,
  },
  cardIconText: {
    fontSize: 32,
    fontWeight: "900",
  },
  status: {
    position: "absolute",
    right: 24,
    top: 24,
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderRadius: 18,
    backgroundColor: "rgba(57,255,20,0.08)",
    borderWidth: 1,
    borderColor: "rgba(57,255,20,0.20)",
  },
  statusOffline: {
    backgroundColor: "rgba(250,204,21,0.08)",
    borderColor: "rgba(250,204,21,0.22)",
  },
  statusDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  statusText: {
    color: "#39FF14",
    fontSize: 11,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
  },
  statusTextOffline: {
    color: "#FACC15",
  },
  cardInner: {
    marginTop: 22,
  },
  cardTitle: {
    color: "#FFFFFF",
    fontSize: 24,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
  },
  cardSubtitle: {
    marginTop: 8,
    color: "#94A3B8",
    fontSize: 15,
    fontWeight: "500",
    fontFamily: "Inter_500Medium",
  },
  arrow: {
    position: "absolute",
    right: 24,
    bottom: 22,
    fontSize: 26,
    fontWeight: "900",
  },
  footer: {
    textAlign: "center",
    color: "rgba(255,255,255,0.18)",
    fontSize: 13,
    fontWeight: "700",
    fontFamily: "Inter_700Bold",
    marginTop: 24,
  },
});
