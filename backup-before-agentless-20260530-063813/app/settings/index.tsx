import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";
import { safeNavigate } from "../../lib/safeNavigate";
import { StatusBar } from "expo-status-bar";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { radius } from "../../src/design-system/radius";
import { spacing } from "../../src/design-system/spacing";
import { MeshHeader } from "../../src/components/ui/MeshHeader";
import { useBackendConfig, type BackendStatus } from "../../contexts/BackendConfigContext";

// ── Status badge pill shown on the Connect Backend row ───────────────────────

function BackendStatusBadge({ status }: { status: BackendStatus }) {
  const color = status === "connected" ? "#10b981"
    : status === "checking"  ? "#FACC15"
    : status === "error"     ? "#EF4444"
    : "#64748B";
  const label = status === "connected" ? "Live"
    : status === "checking"  ? "…"
    : status === "error"     ? "Error"
    : "Offline";
  return (
    <View style={[badge.wrap, { borderColor: color + "55", backgroundColor: color + "18" }]}>
      <View style={[badge.dot, { backgroundColor: color }]} />
      <Text style={[badge.text, { color }]}>{label}</Text>
    </View>
  );
}

const badge = StyleSheet.create({
  wrap: { flexDirection: "row", alignItems: "center", gap: 5, paddingHorizontal: 8, paddingVertical: 4, borderRadius: 8, borderWidth: 1 },
  dot:  { width: 6, height: 6, borderRadius: 3 },
  text: { fontSize: 11, fontFamily: "Inter_600SemiBold", letterSpacing: 0.3 },
});

// ── Nav definition ───────────────────────────────────────────────────────────

interface NavItem {
  icon: string;
  title: string;
  sub: string;
  route: string;
  showBackendBadge?: boolean;
}

const SETTINGS_NAV: { section: string; items: NavItem[] }[] = [
  { section: "BACKEND", items: [
    { icon: "⇄", title: "Connect Backend",  sub: "Point APK at your live server",  route: "/settings/backend-connect", showBackendBadge: true },
  ]},
  { section: "MY ACCOUNT", items: [
    { icon: "◉", title: "Profile",          sub: "Display name, avatar & identity", route: "/profile"   },
    { icon: "⊛", title: "Contacts",         sub: "Trusted peers & mesh contacts",   route: "/contacts"  },
  ]},
  { section: "PERSONALISATION", items: [
    { icon: "◑", title: "Appearance",       sub: "Theme, font size, animations",    route: "/settings/appearance"       },
    { icon: "⟡", title: "Language",         sub: "Display language",                route: "/settings/language"         },
  ]},
  { section: "ALERTS & ACCESS", items: [
    { icon: "◈", title: "Notifications",    sub: "Message & relay alerts",          route: "/settings/notifications"    },
    { icon: "⊙", title: "Permissions",      sub: "BLE, Location, Camera",           route: "/settings/permissions"      },
  ]},
  { section: "MESH BEHAVIOUR", items: [
    { icon: "⌁", title: "Offline Controls", sub: "Store-forward & queue",           route: "/settings/offline-controls" },
    { icon: "⬡", title: "Device Pairing",   sub: "Trusted & paired devices",        route: "/settings/device-pairing"   },
  ]},
  { section: "SECURITY & PRIVACY", items: [
    { icon: "⊗", title: "Security",         sub: "Biometric, PIN, app lock",        route: "/settings/security"         },
    { icon: "◌", title: "Privacy",          sub: "Analytics & data sharing",        route: "/settings/privacy"          },
  ]},
  { section: "DATA", items: [
    { icon: "▤", title: "Export / Import",  sub: "Backup & restore identity",       route: "/settings/export-import"    },
  ]},
  { section: "PLATFORM FEATURES", items: [
    { icon: "♿", title: "Accessibility",      sub: "Display scaling & motor aids",      route: "/platform/accessibility"     },
    { icon: "◎", title: "AI Assistant",       sub: "On-device mesh AI features",        route: "/platform/ai-assistant"      },
    { icon: "⟳", title: "Background Sync",    sub: "Silent relay & background jobs",    route: "/platform/background-sync"   },
    { icon: "⌨", title: "Developer Mode",     sub: "Debug overlays & verbose logs",     route: "/platform/developer-mode"    },
    { icon: "⚠", title: "Emergency Mode",     sub: "Broadcast & SOS protocols",         route: "/platform/emergency-mode"    },
    { icon: "⚿", title: "Encryption Keys",    sub: "Key rotation & cert management",    route: "/platform/encryption-keys"   },
    { icon: "⇪", title: "Export Backup",      sub: "Full node backup archive",          route: "/platform/export-backup"     },
    { icon: "⤒", title: "OTA Updates",        sub: "Over-the-air firmware delivery",    route: "/platform/ota-updates"       },
    { icon: "◐", title: "Push Notifications", sub: "Cloud push bridge configuration",  route: "/platform/push-notifications" },
    { icon: "▤", title: "Storage Management", sub: "Cache quotas & database pruning",   route: "/platform/storage-management"},
  ]},
];

// ── Screen ───────────────────────────────────────────────────────────────────

export default function SettingsIndexScreen() {
  const router  = useRouter();
  const insets  = useSafeAreaInsets();
  const { status: backendStatus } = useBackendConfig();

  return (
    <View style={styles.root}>
      <StatusBar style="light" />
      <MeshHeader title="Settings" subtitle="Customise your mesh experience" />
      <ScrollView
        style={styles.scroll}
        contentContainerStyle={[styles.content, { paddingBottom: insets.bottom + 24 }]}
        showsVerticalScrollIndicator={false}
      >
        {SETTINGS_NAV.map((group) => (
          <View key={group.section}>
            <Text style={styles.sectionLabel}>{group.section}</Text>
            {group.items.map((item) => (
              <Pressable
                key={item.route}
                onPress={() => safeNavigate(router, item.route)}
                style={({ pressed }) => [styles.row, pressed && styles.rowPressed]}
              >
                <View style={styles.iconWrap}>
                  <Text style={styles.icon}>{item.icon}</Text>
                </View>
                <View style={styles.text}>
                  <Text style={styles.rowTitle}>{item.title}</Text>
                  <Text style={styles.rowSub}>{
                    item.showBackendBadge && backendStatus === "connected"
                      ? "Live backend connected"
                      : item.sub
                  }</Text>
                </View>
                {item.showBackendBadge ? (
                  <BackendStatusBadge status={backendStatus} />
                ) : (
                  <Text style={styles.arrow}>›</Text>
                )}
              </Pressable>
            ))}
          </View>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root:         { flex: 1, backgroundColor: DS.deepSpace },
  scroll:       { flex: 1 },
  content:      { padding: spacing.lg, gap: spacing.xs },
  sectionLabel: { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.bold, letterSpacing: typography.tracking.wide, marginTop: spacing.md, marginBottom: spacing.xs },
  row: {
    flexDirection: "row", alignItems: "center", gap: spacing.sm,
    backgroundColor: DS.card, borderRadius: radius.lg, borderWidth: 1,
    borderColor: DS.divider, padding: spacing.md,
  },
  rowPressed: { opacity: 0.80, transform: [{ scale: 0.985 }] },
  iconWrap:   { width: 40, height: 40, borderRadius: radius.sm, backgroundColor: DS.greenDim, alignItems: "center", justifyContent: "center", flexShrink: 0 },
  icon:       { fontSize: 20, color: DS.mauriGreen },
  text:       { flex: 1, gap: 2 },
  rowTitle:   { color: DS.textPrimary,   fontSize: typography.sizes.base, fontFamily: typography.fonts.semibold },
  rowSub:     { color: DS.textSecondary, fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular  },
  arrow:      { color: DS.textSecondary, fontSize: 26, fontFamily: typography.fonts.regular, flexShrink: 0 },
});
