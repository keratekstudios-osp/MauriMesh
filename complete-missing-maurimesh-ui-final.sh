#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "COMPLETE MISSING MAURIMESH UI FINAL"
echo "Creates missing UI screens/components + dashboard wiring"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-complete-missing-ui-$STAMP"

APP="$ROOT/app"
SRC="$ROOT/src"
COMP="$SRC/components"
LIB="$SRC/lib"
THEME="$SRC/theme"
DOCS="$ROOT/docs"

mkdir -p "$BACKUP" "$APP" "$COMP" "$LIB" "$THEME" "$DOCS"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from Replit project root."
  exit 1
fi

echo "Backup folder:"
echo "$BACKUP"

backup_file() {
  local file="$1"
  if [ -f "$ROOT/$file" ]; then
    mkdir -p "$BACKUP/$(dirname "$file")"
    cp "$ROOT/$file" "$BACKUP/$file"
  fi
}

backup_file "app/dashboard.tsx"
backup_file "app/login.tsx"
backup_file "app/route-lab.tsx"
backup_file "app/tikanga-engine.tsx"
backup_file "app/self-healing.tsx"
backup_file "app/device-proof.tsx"
backup_file "app/operator-console.tsx"
backup_file "app/mauricore-governance.tsx"
backup_file "app/mauricore-ble-runtime.tsx"

# ------------------------------------------------------------
# Ensure theme exists
# ------------------------------------------------------------
if [ ! -f "$THEME/mauriTheme.ts" ]; then
cat > "$THEME/mauriTheme.ts" <<'TS'
export const mauriTheme = {
  colors: {
    black: "#020403",
    deepBlack: "#000000",
    navy: "#020617",
    greenstone: "#00D084",
    emerald: "#10B981",
    jade: "#22C55E",
    blueWeb: "#38BDF8",
    white: "#FFFFFF",
    mutedWhite: "rgba(255,255,255,0.72)",
    softWhite: "rgba(255,255,255,0.12)",
    danger: "#EF4444",
    warning: "#F59E0B",
    success: "#22C55E",
    panel: "rgba(2,12,8,0.84)",
    panelSoft: "rgba(255,255,255,0.06)",
    panelBorder: "rgba(34,197,94,0.28)",
  },
  radius: {
    sm: 10,
    md: 16,
    lg: 24,
    xl: 32,
  },
  spacing: {
    xs: 6,
    sm: 10,
    md: 16,
    lg: 24,
    xl: 36,
  },
};
TS
fi

# ------------------------------------------------------------
# Ensure core components exist
# ------------------------------------------------------------
if [ ! -f "$COMP/AppShell.tsx" ]; then
cat > "$COMP/AppShell.tsx" <<'TSX'
import React from "react";
import { SafeAreaView, ScrollView, StyleSheet, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

export function AppShell({
  children,
  scroll = true,
}: {
  children: React.ReactNode;
  scroll?: boolean;
}) {
  const content = <View style={styles.content}>{children}</View>;

  return (
    <SafeAreaView style={styles.safe}>
      {scroll ? <ScrollView>{content}</ScrollView> : content}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: mauriTheme.colors.black,
  },
  content: {
    flex: 1,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.md,
  },
});
TSX
fi

if [ ! -f "$COMP/MauriButton.tsx" ]; then
cat > "$COMP/MauriButton.tsx" <<'TSX'
import React from "react";
import { Pressable, StyleSheet, Text } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

export function MauriButton({
  title,
  onPress,
  variant = "primary",
}: {
  title: string;
  onPress: () => void;
  variant?: "primary" | "secondary" | "danger";
}) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.base,
        variant === "primary" && styles.primary,
        variant === "secondary" && styles.secondary,
        variant === "danger" && styles.danger,
        pressed && { opacity: 0.76, transform: [{ scale: 0.98 }] },
      ]}
    >
      <Text style={styles.text}>{title}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    minHeight: 52,
    borderRadius: mauriTheme.radius.lg,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: mauriTheme.spacing.lg,
    borderWidth: 1,
  },
  primary: {
    backgroundColor: mauriTheme.colors.greenstone,
    borderColor: mauriTheme.colors.greenstone,
  },
  secondary: {
    backgroundColor: mauriTheme.colors.panel,
    borderColor: mauriTheme.colors.panelBorder,
  },
  danger: {
    backgroundColor: "rgba(239,68,68,0.16)",
    borderColor: "rgba(239,68,68,0.5)",
  },
  text: {
    color: mauriTheme.colors.white,
    fontSize: 16,
    fontWeight: "800",
  },
});
TSX
fi

if [ ! -f "$COMP/StatusPill.tsx" ]; then
cat > "$COMP/StatusPill.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

export function StatusPill({
  label,
  tone = "success",
}: {
  label: string;
  tone?: "success" | "warning" | "danger" | "info";
}) {
  const color =
    tone === "success"
      ? mauriTheme.colors.success
      : tone === "warning"
        ? mauriTheme.colors.warning
        : tone === "danger"
          ? mauriTheme.colors.danger
          : mauriTheme.colors.blueWeb;

  return (
    <View style={[styles.pill, { borderColor: color }]}>
      <Text style={[styles.text, { color }]}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  pill: {
    alignSelf: "flex-start",
    borderWidth: 1,
    borderRadius: 999,
    paddingVertical: 6,
    paddingHorizontal: 12,
    backgroundColor: "rgba(255,255,255,0.05)",
  },
  text: {
    fontWeight: "800",
    fontSize: 12,
    letterSpacing: 0.6,
  },
});
TSX
fi

if [ ! -f "$COMP/MeshSignalCard.tsx" ]; then
cat > "$COMP/MeshSignalCard.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

export function MeshSignalCard({
  title,
  value,
  status,
}: {
  title: string;
  value: string;
  status: "LIVE" | "SIMULATION" | "UNAVAILABLE";
}) {
  return (
    <View style={styles.card}>
      <StatusPill
        label={status}
        tone={
          status === "LIVE"
            ? "success"
            : status === "SIMULATION"
              ? "warning"
              : "danger"
        }
      />
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.value}>{value}</Text>
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
    fontSize: 18,
    fontWeight: "900",
  },
  value: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 14,
    lineHeight: 20,
  },
});
TSX
fi

# ------------------------------------------------------------
# Final missing components
# ------------------------------------------------------------
cat > "$COMP/ProofLedgerPanel.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

export function ProofLedgerPanel() {
  const rows = [
    ["Packet ID", "MM-PROOF-UI-001"],
    ["Payload Hash", "sha256: simulation-placeholder"],
    ["Route", "Device A → Relay B → Device C"],
    ["ACK State", "SIMULATION ACK"],
    ["Truth", "UI proof ledger only until APK/device logcat proof is added"],
  ];

  return (
    <View style={styles.card}>
      <StatusPill label="SIMULATION / DEVICE PROOF READY" tone="warning" />
      <Text style={styles.title}>Proof Ledger</Text>
      <Text style={styles.subtitle}>
        Packet proof view for hashes, route path, ACK state, timestamps, and future native logcat evidence.
      </Text>

      {rows.map(([label, value]) => (
        <View key={label} style={styles.row}>
          <Text style={styles.label}>{label}</Text>
          <Text style={styles.value}>{value}</Text>
        </View>
      ))}
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
    fontSize: 24,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  row: {
    borderTopWidth: 1,
    borderTopColor: mauriTheme.colors.panelBorder,
    paddingTop: 10,
    gap: 4,
  },
  label: {
    color: mauriTheme.colors.greenstone,
    fontWeight: "900",
    fontSize: 12,
    letterSpacing: 0.6,
  },
  value: {
    color: mauriTheme.colors.white,
    fontSize: 14,
    lineHeight: 20,
  },
});
TSX

cat > "$COMP/RouteDecisionPanel.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

const routes = [
  { name: "BLE Direct", score: 68, reason: "Low energy, short range, best when peer is nearby." },
  { name: "BLE Relay → Wi-Fi", score: 91, reason: "Best hybrid path. Relay discovers stronger Wi-Fi completion path." },
  { name: "Internet Fallback", score: 74, reason: "Use only when mesh path cannot complete delivery." },
];

export function RouteDecisionPanel() {
  return (
    <View style={styles.card}>
      <StatusPill label="ROUTE LAB / SIMULATION" tone="info" />
      <Text style={styles.title}>Route Lab</Text>
      <Text style={styles.subtitle}>
        Visual decision layer for BLE, relay, Wi-Fi, internet fallback, trust score, TTL, and path selection.
      </Text>

      {routes.map((route) => (
        <View key={route.name} style={styles.route}>
          <View style={styles.routeTop}>
            <Text style={styles.routeName}>{route.name}</Text>
            <Text style={styles.score}>{route.score}%</Text>
          </View>
          <Text style={styles.reason}>{route.reason}</Text>
        </View>
      ))}

      <View style={styles.selected}>
        <Text style={styles.selectedTitle}>Selected Route</Text>
        <Text style={styles.selectedText}>
          BLE Relay → Wi-Fi selected because it balances delivery confidence, energy, and path resilience.
        </Text>
      </View>
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
    fontSize: 24,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  route: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    borderRadius: mauriTheme.radius.lg,
    padding: mauriTheme.spacing.md,
    gap: 6,
  },
  routeTop: {
    flexDirection: "row",
    justifyContent: "space-between",
    gap: 12,
  },
  routeName: {
    color: mauriTheme.colors.white,
    fontWeight: "900",
    fontSize: 15,
  },
  score: {
    color: mauriTheme.colors.greenstone,
    fontWeight: "900",
  },
  reason: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 20,
  },
  selected: {
    backgroundColor: "rgba(0,208,132,0.12)",
    borderRadius: mauriTheme.radius.lg,
    padding: mauriTheme.spacing.md,
    borderWidth: 1,
    borderColor: mauriTheme.colors.greenstone,
  },
  selectedTitle: {
    color: mauriTheme.colors.greenstone,
    fontWeight: "900",
    marginBottom: 4,
  },
  selectedText: {
    color: mauriTheme.colors.white,
    lineHeight: 20,
  },
});
TSX

cat > "$COMP/TikangaDecisionCard.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

export function TikangaDecisionCard() {
  return (
    <View style={styles.card}>
      <StatusPill label="TIKANGA GOVERNANCE / UI" tone="success" />
      <Text style={styles.title}>Tikanga Engine</Text>
      <Text style={styles.subtitle}>
        Governance view for mana, tapu/noa, cultural risk, review state, and audit trail.
      </Text>

      <View style={styles.grid}>
        <Text style={styles.label}>Decision</Text>
        <Text style={styles.value}>APPROVED_WITH_WARNING</Text>

        <Text style={styles.label}>Cultural Risk</Text>
        <Text style={styles.value}>MEDIUM</Text>

        <Text style={styles.label}>Protocol</Text>
        <Text style={styles.value}>Respect mana, protect tapu content, require review for protected terms.</Text>

        <Text style={styles.label}>Audit Note</Text>
        <Text style={styles.value}>
          UI governance shell complete. Live policy execution must connect to the real Tikanga runtime later.
        </Text>
      </View>
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
    fontSize: 24,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  grid: {
    gap: 8,
  },
  label: {
    color: mauriTheme.colors.greenstone,
    fontWeight: "900",
    fontSize: 12,
    letterSpacing: 0.7,
  },
  value: {
    color: mauriTheme.colors.white,
    fontSize: 14,
    lineHeight: 20,
    marginBottom: 8,
  },
});
TSX

cat > "$COMP/SelfHealingPanel.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

export function SelfHealingPanel() {
  const repairs = [
    "Detect stale route memory",
    "Lower trust on failed relay",
    "Recalculate hybrid path",
    "Preserve store-and-forward queue",
  ];

  return (
    <View style={styles.card}>
      <StatusPill label="SELF-HEALING / HOMEOSTASIS" tone="warning" />
      <Text style={styles.title}>Self-Healing</Text>
      <Text style={styles.subtitle}>
        Health screen for faults, repair actions, resilience score, and living mesh homeostasis.
      </Text>

      <View style={styles.scoreBox}>
        <Text style={styles.score}>86%</Text>
        <Text style={styles.scoreLabel}>Resilience Score</Text>
      </View>

      {repairs.map((item) => (
        <Text key={item} style={styles.item}>✓ {item}</Text>
      ))}
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
    fontSize: 24,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  scoreBox: {
    borderRadius: mauriTheme.radius.xl,
    borderWidth: 1,
    borderColor: mauriTheme.colors.greenstone,
    backgroundColor: "rgba(0,208,132,0.12)",
    padding: mauriTheme.spacing.lg,
    alignItems: "center",
  },
  score: {
    color: mauriTheme.colors.greenstone,
    fontSize: 42,
    fontWeight: "900",
  },
  scoreLabel: {
    color: mauriTheme.colors.white,
    fontWeight: "800",
  },
  item: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
});
TSX

cat > "$COMP/DeviceProofCard.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

export function DeviceProofCard() {
  const checks = [
    "Install APK on Phone A and Phone B",
    "Grant Bluetooth, Nearby Devices, Location, and notification permissions",
    "Run BLE receiver on Phone B",
    "Send packet from Phone A",
    "Capture logcat proof for TX, RX, relay, ACK, and packet ID",
  ];

  return (
    <View style={styles.card}>
      <StatusPill label="APK / DEVICE PROOF REQUIRED" tone="danger" />
      <Text style={styles.title}>Device Proof</Text>
      <Text style={styles.subtitle}>
        This page does not fake BLE. It shows the exact APK/phone proof checklist needed for real native validation.
      </Text>

      {checks.map((check) => (
        <Text key={check} style={styles.item}>□ {check}</Text>
      ))}

      <View style={styles.truth}>
        <Text style={styles.truthTitle}>Truth</Text>
        <Text style={styles.truthText}>
          Replit proves UI and TypeScript only. Real BLE proof requires physical Android devices and logcat evidence.
        </Text>
      </View>
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
    fontSize: 24,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  item: {
    color: mauriTheme.colors.white,
    lineHeight: 22,
  },
  truth: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.danger,
    borderRadius: mauriTheme.radius.lg,
    padding: mauriTheme.spacing.md,
    backgroundColor: "rgba(239,68,68,0.10)",
  },
  truthTitle: {
    color: mauriTheme.colors.danger,
    fontWeight: "900",
    marginBottom: 4,
  },
  truthText: {
    color: mauriTheme.colors.white,
    lineHeight: 20,
  },
});
TSX

cat > "$COMP/MauriCoreStatusPanel.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

export function MauriCoreStatusPanel() {
  const rows = [
    ["Living Memory", "UI READY"],
    ["Governance", "UI READY"],
    ["BLE Runtime", "REQUIRES APK"],
    ["Routing", "SIMULATION READY"],
    ["Self-Healing", "UI READY"],
  ];

  return (
    <View style={styles.card}>
      <StatusPill label="MAURICORE STATUS" tone="info" />
      <Text style={styles.title}>MauriCore</Text>
      {rows.map(([label, value]) => (
        <View key={label} style={styles.row}>
          <Text style={styles.label}>{label}</Text>
          <Text style={styles.value}>{value}</Text>
        </View>
      ))}
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
    fontSize: 22,
    fontWeight: "900",
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    borderTopWidth: 1,
    borderTopColor: mauriTheme.colors.panelBorder,
    paddingTop: 8,
    gap: 12,
  },
  label: {
    color: mauriTheme.colors.mutedWhite,
    fontWeight: "700",
  },
  value: {
    color: mauriTheme.colors.greenstone,
    fontWeight: "900",
  },
});
TSX

# ------------------------------------------------------------
# Login screen
# ------------------------------------------------------------
cat > "$APP/login.tsx" <<'TSX'
import { useRouter } from "expo-router";
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function LoginScreen() {
  const router = useRouter();

  return (
    <AppShell scroll={false}>
      <View style={styles.hero}>
        <StatusPill label="MAURIMESH MESSENGER" tone="success" />
        <Text style={styles.title}>MauriMesh</Text>
        <Text style={styles.tagline}>Messenger</Text>
        <Text style={styles.subtitle}>
          Secure mesh communication prepared for offline routing, relay logic,
          living governance, and future native device proof.
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Enter Network</Text>
        <Text style={styles.cardText}>
          Replit preview supports UI, navigation, API fallback, and simulation.
          Real BLE proof requires APK on physical phones.
        </Text>
        <MauriButton title="Open Dashboard" onPress={() => router.replace("/dashboard")} />
      </View>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  hero: {
    flex: 1,
    justifyContent: "center",
    gap: mauriTheme.spacing.md,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 54,
    lineHeight: 58,
    fontWeight: "900",
    letterSpacing: -1.5,
  },
  tagline: {
    color: mauriTheme.colors.greenstone,
    fontSize: 28,
    fontWeight: "900",
    letterSpacing: 2,
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 16,
    lineHeight: 24,
  },
  card: {
    borderRadius: mauriTheme.radius.xl,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.md,
  },
  cardTitle: {
    color: mauriTheme.colors.white,
    fontSize: 22,
    fontWeight: "900",
  },
  cardText: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
});
TSX

# ------------------------------------------------------------
# Missing screens
# ------------------------------------------------------------
cat > "$APP/proof-ledger.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { ProofLedgerPanel } from "../src/components/ProofLedgerPanel";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function ProofLedgerScreen() {
  return (
    <AppShell>
      <Text style={styles.title}>Proof Ledger</Text>
      <Text style={styles.subtitle}>
        SIMULATION ledger view. DEVICE PROOF can be added after APK/logcat validation.
      </Text>
      <ProofLedgerPanel />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 34,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 22,
  },
});
TSX

cat > "$APP/route-lab.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { RouteDecisionPanel } from "../src/components/RouteDecisionPanel";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function RouteLabScreen() {
  return (
    <AppShell>
      <Text style={styles.title}>Route Lab</Text>
      <Text style={styles.subtitle}>
        SIMULATION route design for BLE, relay, Wi-Fi, internet fallback, trust, TTL, and path selection.
      </Text>
      <RouteDecisionPanel />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 34,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 22,
  },
});
TSX

cat > "$APP/tikanga-engine.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { TikangaDecisionCard } from "../src/components/TikangaDecisionCard";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function TikangaEngineScreen() {
  return (
    <AppShell>
      <Text style={styles.title}>Tikanga Engine</Text>
      <Text style={styles.subtitle}>
        Governance UI for cultural risk, review states, protected terms, and audit trail.
      </Text>
      <TikangaDecisionCard />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 34,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 22,
  },
});
TSX

cat > "$APP/self-healing.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { SelfHealingPanel } from "../src/components/SelfHealingPanel";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function SelfHealingScreen() {
  return (
    <AppShell>
      <Text style={styles.title}>Self-Healing</Text>
      <Text style={styles.subtitle}>
        Living system UI for repair queues, resilience, route recovery, and homeostasis.
      </Text>
      <SelfHealingPanel />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 34,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 22,
  },
});
TSX

cat > "$APP/device-proof.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { DeviceProofCard } from "../src/components/DeviceProofCard";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function DeviceProofScreen() {
  return (
    <AppShell>
      <Text style={styles.title}>Device Proof</Text>
      <Text style={styles.subtitle}>
        APK/device checklist for real BLE, native Bluetooth, QR camera, logcat, packet delivery, and ACK proof.
      </Text>
      <DeviceProofCard />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 34,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 22,
  },
});
TSX

cat > "$APP/operator-console.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriCoreStatusPanel } from "../src/components/MauriCoreStatusPanel";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function OperatorConsoleScreen() {
  return (
    <AppShell>
      <StatusPill label="OPERATOR CONSOLE" tone="info" />
      <Text style={styles.title}>Operator Console</Text>
      <Text style={styles.subtitle}>
        Current UI control page for mode, readiness, completion, warnings, and final proof requirements.
      </Text>

      <MauriCoreStatusPanel />

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Build Readiness</Text>
        <Text style={styles.row}>UI screens: READY AFTER CHECK</Text>
        <Text style={styles.row}>TypeScript: RUNNING IN SCRIPT</Text>
        <Text style={styles.row}>Replit proof: UI ONLY</Text>
        <Text style={styles.row}>APK proof: REQUIRED FOR BLE</Text>
      </View>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 34,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 22,
  },
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: 8,
  },
  cardTitle: {
    color: mauriTheme.colors.greenstone,
    fontSize: 18,
    fontWeight: "900",
  },
  row: {
    color: mauriTheme.colors.white,
    fontWeight: "800",
  },
});
TSX

# ------------------------------------------------------------
# Fix MauriCore screens with valid default exports
# ------------------------------------------------------------
cat > "$APP/mauricore-governance.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { TikangaDecisionCard } from "../src/components/TikangaDecisionCard";
import { MauriCoreStatusPanel } from "../src/components/MauriCoreStatusPanel";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function MauriCoreGovernanceScreen() {
  return (
    <AppShell>
      <Text style={styles.title}>MauriCore Governance</Text>
      <Text style={styles.subtitle}>
        Governance dashboard for MauriCore, Tikanga decision state, audit visibility, and safe UI proof.
      </Text>
      <MauriCoreStatusPanel />
      <TikangaDecisionCard />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 34,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 22,
  },
});
TSX

cat > "$APP/mauricore-ble-runtime.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriCoreStatusPanel } from "../src/components/MauriCoreStatusPanel";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function MauriCoreBleRuntimeScreen() {
  return (
    <AppShell>
      <StatusPill label="BLE RUNTIME / APK REQUIRED" tone="danger" />
      <Text style={styles.title}>MauriCore BLE Runtime</Text>
      <Text style={styles.subtitle}>
        UI readiness screen for Android BLE runtime. Real BLE scanning, advertising, GATT, relay, and ACK require APK/device proof.
      </Text>

      <MauriCoreStatusPanel />

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Runtime Checklist</Text>
        <Text style={styles.item}>□ Bluetooth permissions granted</Text>
        <Text style={styles.item}>□ Nearby Devices permission granted</Text>
        <Text style={styles.item}>□ Phone B receiver advertising</Text>
        <Text style={styles.item}>□ Phone A sender discovers receiver</Text>
        <Text style={styles.item}>□ ACK proof captured in logcat</Text>
      </View>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 34,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 22,
  },
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: 8,
  },
  cardTitle: {
    color: mauriTheme.colors.greenstone,
    fontSize: 18,
    fontWeight: "900",
  },
  item: {
    color: mauriTheme.colors.white,
    lineHeight: 21,
  },
});
TSX

# ------------------------------------------------------------
# Patch truth labels in existing screens where possible
# ------------------------------------------------------------
node <<'NODE'
const fs = require("fs");

function patchIfExists(file, marker, insertion) {
  if (!fs.existsSync(file)) return;
  let src = fs.readFileSync(file, "utf8");
  if (src.includes(marker)) return;

  if (src.includes("</AppShell>")) {
    src = src.replace("</AppShell>", `${insertion}\n    </AppShell>`);
    fs.writeFileSync(file, src);
  }
}

patchIfExists(
  "app/living-mesh.tsx",
  "SIMULATION fallback",
  `      <Text style={{ color: "rgba(255,255,255,0.72)", lineHeight: 20 }}>
        SIMULATION fallback shown in Replit unless live Mesh API/device proof is connected.
      </Text>`
);

patchIfExists(
  "app/add-friend.tsx",
  "Camera QR",
  `      <Text style={{ color: "rgba(255,255,255,0.72)", lineHeight: 20 }}>
        Camera QR scanning and nearby BLE discovery require APK/device validation.
      </Text>`
);

patchIfExists(
  "app/proof-ledger.tsx",
  "DEVICE PROOF",
  `      <Text style={{ color: "rgba(255,255,255,0.72)", lineHeight: 20 }}>
        SIMULATION ledger only until DEVICE PROOF is captured from APK/logcat.
      </Text>`
);
NODE

# ------------------------------------------------------------
# Replace dashboard with complete route hub
# ------------------------------------------------------------
cat > "$APP/dashboard.tsx" <<'TSX'
import { useRouter } from "expo-router";
import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { MeshSignalCard } from "../src/components/MeshSignalCard";
import { MauriCoreStatusPanel } from "../src/components/MauriCoreStatusPanel";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function DashboardScreen() {
  const router = useRouter();
  const [mesh, setMesh] = useState<MeshStatus | null>(null);

  useEffect(() => {
    getMeshStatus()
      .then(setMesh)
      .catch(() => {
        setMesh({
          mode: "SIMULATION",
          message: "Mesh status unavailable. Showing safe dashboard fallback.",
          nodes: [],
          routes: [],
        });
      });
  }, []);

  const mode = mesh?.mode || "UNAVAILABLE";

  return (
    <AppShell>
      <Text style={styles.title}>Dashboard</Text>
      <Text style={styles.subtitle}>
        MauriMesh command centre for messenger UI, mesh visibility, proof ledger,
        routing, governance, self-healing, device proof, and final completion.
      </Text>

      <MeshSignalCard
        title="Mesh Status"
        value={mesh?.message || "Checking mesh status..."}
        status={mode}
      />

      <MauriCoreStatusPanel />

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Core Messenger</Text>
        <MauriButton title="Chat" onPress={() => router.push("/chat")} />
        <MauriButton title="Living Mesh" onPress={() => router.push("/living-mesh")} />
        <MauriButton title="Mesh Status" onPress={() => router.push("/mesh-status")} />
        <MauriButton title="Add Friend" onPress={() => router.push("/add-friend")} />
        <MauriButton title="Pixel Calling" onPress={() => router.push("/pixel-calling")} />
        <MauriButton title="Settings" onPress={() => router.push("/settings")} />
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Final UI Layers</Text>
        <MauriButton title="UI Roadmap" onPress={() => router.push("/ui-roadmap")} />
        <MauriButton title="Proof Ledger" onPress={() => router.push("/proof-ledger")} />
        <MauriButton title="Route Lab" onPress={() => router.push("/route-lab")} />
        <MauriButton title="Tikanga Engine" onPress={() => router.push("/tikanga-engine")} />
        <MauriButton title="Self-Healing" onPress={() => router.push("/self-healing")} />
        <MauriButton title="Device Proof" onPress={() => router.push("/device-proof")} />
        <MauriButton title="Operator Console" onPress={() => router.push("/operator-console")} />
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>MauriCore</Text>
        <MauriButton title="MauriCore Governance" onPress={() => router.push("/mauricore-governance")} />
        <MauriButton title="MauriCore BLE Runtime" onPress={() => router.push("/mauricore-ble-runtime")} />
      </View>

      <View style={styles.notice}>
        <Text style={styles.noticeTitle}>Final Truth</Text>
        <Text style={styles.noticeText}>
          Replit proves UI, routing shells, API fallback, TypeScript, and simulation views.
          Real BLE, QR camera, native Bluetooth scanning, phone-to-phone ACK, and real calling transport still require APK/device proof.
        </Text>
      </View>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 36,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 15,
    lineHeight: 22,
  },
  section: {
    gap: mauriTheme.spacing.md,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
  },
  sectionTitle: {
    color: mauriTheme.colors.greenstone,
    fontSize: 18,
    fontWeight: "900",
  },
  notice: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.sm,
  },
  noticeTitle: {
    color: mauriTheme.colors.greenstone,
    fontSize: 16,
    fontWeight: "900",
  },
  noticeText: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 13,
    lineHeight: 20,
  },
});
TSX

# ------------------------------------------------------------
# Ensure index redirects to login
# ------------------------------------------------------------
cat > "$APP/index.tsx" <<'TSX'
import { Redirect } from "expo-router";
import React from "react";

export default function Index() {
  return <Redirect href="/login" />;
}
TSX

# ------------------------------------------------------------
# Optional report
# ------------------------------------------------------------
cat > "$DOCS/maurimesh-ui-final-completion-fix-$STAMP.md" <<MD
# MauriMesh UI Final Completion Fix

Generated: $STAMP

## Created / Repaired

- app/login.tsx
- app/dashboard.tsx
- app/proof-ledger.tsx
- app/route-lab.tsx
- app/tikanga-engine.tsx
- app/self-healing.tsx
- app/device-proof.tsx
- app/operator-console.tsx
- app/mauricore-governance.tsx
- app/mauricore-ble-runtime.tsx
- src/components/ProofLedgerPanel.tsx
- src/components/RouteDecisionPanel.tsx
- src/components/TikangaDecisionCard.tsx
- src/components/SelfHealingPanel.tsx
- src/components/DeviceProofCard.tsx
- src/components/MauriCoreStatusPanel.tsx

## Dashboard Routes Added

- /chat
- /living-mesh
- /mesh-status
- /add-friend
- /pixel-calling
- /settings
- /ui-roadmap
- /proof-ledger
- /route-lab
- /tikanga-engine
- /self-healing
- /device-proof
- /operator-console
- /mauricore-governance
- /mauricore-ble-runtime

## Truth

Replit completes UI and simulation proof only.
Real BLE, native scanning, QR camera, ACK, and real calling require APK/device proof.
MD

echo ""
echo "Running TypeScript..."
if command -v npx >/dev/null 2>&1; then
  npx tsc --noEmit
else
  echo "WARN: npx not found. Skipping TypeScript."
fi

echo ""
echo "============================================================"
echo "DONE: MISSING UI FINAL LAYER CREATED"
echo "============================================================"
echo "Backup saved:"
echo "$BACKUP"
echo ""
echo "Now rerun your checklist:"
echo "  ./check-ui-available-complete.sh"
echo ""
echo "Then open:"
echo "  Login -> Open Dashboard"
echo "============================================================"
