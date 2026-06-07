import { Feather } from "@expo/vector-icons";
import Constants from "expo-constants";
import { LinearGradient } from "expo-linear-gradient";
import * as Haptics from "expo-haptics";
import { useState } from "react";
import {
  Alert,
  Linking,
  Platform,
  Pressable,
  ScrollView,
  Share,
  StyleSheet,
  Switch,
  Text,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { useRouter } from "expo-router";
import { useColors, type Colors } from "../../hooks/useColors";
import { useTheme, type ThemeMode } from "../../contexts/ThemeContext";
import { useBackendConfig, type BackendStatus } from "../../contexts/BackendConfigContext";
import { safeNavigate } from "../../lib/safeNavigate";
import { clearSession } from "../../lib/session";

// ── Install link config ───────────────────────────────────────────────────────

const INSTALL_URL =
  Constants.expoConfig?.extra?.installUrl as string | undefined;

const SHARE_TITLE = "MauriMesh — Private Mesh Access";

const SHARE_MESSAGE = INSTALL_URL
  ? `You've been invited to test MauriMesh Messenger.\n\nMauriMesh is a private decentralized communication network built for resilient, offline-first connection.\n\nInstall here:\n${INSTALL_URL}`
  : "";

// ── Premium emerald palette (card-local, not from theme) ─────────────────────

const JADE = {
  grad0: "#031a10" as const,
  grad1: "#042d1a" as const,
  grad2: "#064e3b" as const,
  accent: "#10b981" as const,
  accentDim: "rgba(16,185,129,0.18)" as const,
  border: "rgba(16,185,129,0.28)" as const,
  glow: "rgba(16,185,129,0.12)" as const,
  white: "#ffffff" as const,
  silver: "rgba(255,255,255,0.65)" as const,
  muted: "rgba(255,255,255,0.38)" as const,
};

// ── Actions ───────────────────────────────────────────────────────────────────

async function handleShareInvite() {
  if (!INSTALL_URL) {
    Alert.alert(
      "Install link missing",
      "Update extra.installUrl in app.json to enable sharing."
    );
    return;
  }

  await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);

  try {
    await Share.share(
      {
        title: SHARE_TITLE,
        message: Platform.OS === "ios" ? SHARE_TITLE : SHARE_MESSAGE,
        url: INSTALL_URL,
      },
      {
        dialogTitle: SHARE_TITLE,
        subject: SHARE_TITLE,
      }
    );
  } catch {
    Alert.alert(
      "Share failed",
      "The invite link could not be shared. You can still copy it from Settings."
    );
  }
}

async function handleOpenInstallLink() {
  if (!INSTALL_URL) {
    Alert.alert(
      "Install link missing",
      "Update extra.installUrl in app.json."
    );
    return;
  }

  await Haptics.selectionAsync();

  const supported = await Linking.canOpenURL(INSTALL_URL);
  if (!supported) {
    Alert.alert("Invalid link", "The install link cannot be opened.");
    return;
  }

  await Linking.openURL(INSTALL_URL);
}

// ── InviteCard ────────────────────────────────────────────────────────────────

function InviteCard() {
  const urlPreview = INSTALL_URL
    ? INSTALL_URL.replace(/^https?:\/\//, "").slice(0, 40) +
      (INSTALL_URL.length > 48 ? "…" : "")
    : "No install link configured";

  return (
    <View style={card.wrapper}>
      {/* Outer glow ring */}
      <View style={card.glowRing} />

      <LinearGradient
        colors={[JADE.grad0, JADE.grad1, JADE.grad2]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={card.gradient}
      >
        {/* Top row: icon + badge */}
        <View style={card.topRow}>
          <View style={card.iconCircle}>
            <Feather name="share-2" size={20} color={JADE.accent} />
          </View>
          <View style={card.badge}>
            <Feather name="shield" size={9} color={JADE.accent} />
            <Text style={card.badgeText}>Trusted Access</Text>
          </View>
        </View>

        {/* Heading */}
        <Text style={card.title}>MauriMesh Access</Text>

        {/* Body */}
        <Text style={card.body}>
          Invite a trusted tester to install MauriMesh Messenger and join the
          private mesh network.
        </Text>

        {/* URL preview pill */}
        <View style={card.urlPill}>
          <Feather name="link" size={10} color={JADE.accent} />
          <Text style={card.urlText} numberOfLines={1}>
            {urlPreview}
          </Text>
        </View>

        {/* Divider */}
        <View style={card.divider} />

        {/* Primary CTA */}
        <Pressable
          style={({ pressed }) => [
            card.primaryBtn,
            pressed && card.primaryBtnPressed,
          ]}
          onPress={handleShareInvite}
        >
          <Feather name="send" size={15} color={JADE.white} />
          <Text style={card.primaryBtnText}>Share Invite</Text>
        </Pressable>

        {/* Secondary link */}
        <Pressable
          style={({ pressed }) => [
            card.secondaryBtn,
            pressed && card.secondaryBtnPressed,
          ]}
          onPress={handleOpenInstallLink}
        >
          <Feather name="external-link" size={13} color={JADE.silver} />
          <Text style={card.secondaryBtnText}>Open Install Page</Text>
        </Pressable>
      </LinearGradient>
    </View>
  );
}

const card = StyleSheet.create({
  wrapper: {
    marginHorizontal: 20,
    marginTop: 28,
    borderRadius: 24,
    // Outer shadow / glow
    shadowColor: JADE.accent,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.35,
    shadowRadius: 24,
    elevation: 12,
  },
  glowRing: {
    position: "absolute",
    inset: -1,
    borderRadius: 25,
    borderWidth: 1,
    borderColor: JADE.border,
  },
  gradient: {
    borderRadius: 24,
    padding: 22,
    overflow: "hidden",
    borderWidth: 1,
    borderColor: JADE.border,
  },
  topRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 16,
  },
  iconCircle: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: JADE.accentDim,
    borderWidth: 1,
    borderColor: JADE.border,
    alignItems: "center",
    justifyContent: "center",
  },
  badge: {
    flexDirection: "row",
    alignItems: "center",
    gap: 5,
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 20,
    backgroundColor: JADE.accentDim,
    borderWidth: 1,
    borderColor: JADE.border,
  },
  badgeText: {
    fontSize: 11,
    fontWeight: "600" as const,
    color: JADE.accent,
    fontFamily: "Inter_600SemiBold",
    letterSpacing: 0.3,
  },
  title: {
    fontSize: 22,
    fontWeight: "700" as const,
    color: JADE.white,
    fontFamily: "Inter_700Bold",
    letterSpacing: -0.5,
    marginBottom: 8,
  },
  body: {
    fontSize: 14,
    lineHeight: 21,
    color: JADE.silver,
    fontFamily: "Inter_400Regular",
    marginBottom: 16,
  },
  urlPill: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderRadius: 10,
    backgroundColor: "rgba(0,0,0,0.35)",
    borderWidth: 1,
    borderColor: "rgba(16,185,129,0.15)",
    marginBottom: 20,
  },
  urlText: {
    flex: 1,
    fontSize: 11,
    color: JADE.muted,
    fontFamily: "Inter_400Regular",
    letterSpacing: 0.1,
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: JADE.border,
    marginBottom: 16,
  },
  primaryBtn: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
    backgroundColor: JADE.accent,
    borderRadius: 14,
    paddingVertical: 14,
    marginBottom: 12,
    shadowColor: JADE.accent,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.45,
    shadowRadius: 12,
    elevation: 6,
  },
  primaryBtnPressed: {
    opacity: 0.82,
    transform: [{ scale: 0.97 }],
  },
  primaryBtnText: {
    fontSize: 15,
    fontWeight: "700" as const,
    color: JADE.white,
    fontFamily: "Inter_700Bold",
    letterSpacing: 0.2,
  },
  secondaryBtn: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 6,
    paddingVertical: 8,
    borderRadius: 10,
  },
  secondaryBtnPressed: {
    opacity: 0.55,
  },
  secondaryBtnText: {
    fontSize: 13,
    color: JADE.silver,
    fontFamily: "Inter_500Medium",
    fontWeight: "500" as const,
  },
});

// ── ThemeToggle ───────────────────────────────────────────────────────────────

function ThemeToggle() {
  const colors = useColors();
  const { theme, setTheme } = useTheme();
  const styles = makeThemeToggleStyles(colors);

  const options: { value: ThemeMode; icon: React.ComponentProps<typeof Feather>["name"]; label: string }[] = [
    { value: "dark",  icon: "moon",  label: "Dark"  },
    { value: "light", icon: "sun",   label: "Light" },
  ];

  const handlePress = (t: ThemeMode) => {
    Haptics.selectionAsync();
    setTheme(t);
  };

  return (
    <View style={styles.wrapper}>
      {options.map((opt) => {
        const active = theme === opt.value;
        return (
          <Pressable
            key={opt.value}
            style={({ pressed }) => [
              styles.option,
              active && styles.optionActive,
              pressed && !active && styles.optionPressed,
            ]}
            onPress={() => handlePress(opt.value)}
          >
            <Feather
              name={opt.icon}
              size={16}
              color={active ? colors.primary : colors.mutedForeground}
            />
            <Text style={[styles.optionText, active && styles.optionTextActive]}>
              {opt.label}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

function makeThemeToggleStyles(colors: Colors) {
  return StyleSheet.create({
    wrapper: {
      flexDirection: "row",
      marginHorizontal: 20,
      marginTop: 28,
      borderRadius: 14,
      backgroundColor: colors.secondary,
      borderWidth: 1,
      borderColor: colors.border,
      padding: 4,
      gap: 4,
    },
    option: {
      flex: 1,
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      gap: 7,
      paddingVertical: 12,
      borderRadius: 10,
    },
    optionActive: {
      backgroundColor: colors.card,
      borderWidth: 1,
      borderColor: colors.primary + "50",
      shadowColor: colors.primary,
      shadowOffset: { width: 0, height: 2 },
      shadowOpacity: 0.18,
      shadowRadius: 6,
      elevation: 3,
    },
    optionPressed: {
      opacity: 0.6,
    },
    optionText: {
      fontSize: 14,
      fontWeight: "500" as const,
      color: colors.mutedForeground,
      fontFamily: "Inter_500Medium",
    },
    optionTextActive: {
      color: colors.primary,
      fontWeight: "700" as const,
      fontFamily: "Inter_700Bold",
    },
  });
}

// ── SettingRow ────────────────────────────────────────────────────────────────

interface SettingRowProps {
  icon: React.ComponentProps<typeof Feather>["name"];
  title: string;
  description?: string;
  toggle?: boolean;
  defaultOn?: boolean;
  onPress?: () => void;
}

function SettingRow({
  icon,
  title,
  description,
  toggle,
  defaultOn = false,
  onPress,
}: SettingRowProps) {
  const colors = useColors();
  const [enabled, setEnabled] = useState(defaultOn);
  const styles = makeRowStyles(colors);

  const handleToggle = (val: boolean) => {
    Haptics.selectionAsync();
    setEnabled(val);
  };

  return (
    <Pressable
      style={({ pressed }) => [
        styles.row,
        pressed && !toggle && styles.rowPressed,
      ]}
      onPress={onPress}
      disabled={toggle}
    >
      <View style={styles.rowLeft}>
        <View style={styles.iconBox}>
          <Feather name={icon} size={18} color={colors.foreground} />
        </View>
        <View style={styles.textBlock}>
          <Text style={styles.rowTitle}>{title}</Text>
          {description ? (
            <Text style={styles.rowDesc}>{description}</Text>
          ) : null}
        </View>
      </View>
      <View style={styles.rowRight}>
        {toggle ? (
          <Switch
            value={enabled}
            onValueChange={handleToggle}
            trackColor={{
              false: colors.border,
              true: colors.primary + "80",
            }}
            thumbColor={enabled ? colors.primary : colors.mutedForeground}
            ios_backgroundColor={colors.border}
          />
        ) : (
          <Feather
            name="chevron-right"
            size={16}
            color={colors.mutedForeground}
          />
        )}
      </View>
    </Pressable>
  );
}

// ── Section ───────────────────────────────────────────────────────────────────

interface SectionProps {
  title: string;
  children: React.ReactNode;
}

function Section({ title, children }: SectionProps) {
  const colors = useColors();
  const styles = makeSectionStyles(colors);
  return (
    <View style={styles.section}>
      <Text style={styles.sectionTitle}>{title}</Text>
      <View style={styles.sectionCard}>{children}</View>
    </View>
  );
}

// ── Screen ────────────────────────────────────────────────────────────────────

// ── BackendStatusBadge (inline, tab-settings only) ───────────────────────────

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
    <View style={[
      bstyles.wrap,
      { borderColor: color + "55", backgroundColor: color + "18" },
    ]}>
      <View style={[bstyles.dot, { backgroundColor: color }]} />
      <Text style={[bstyles.text, { color }]}>{label}</Text>
    </View>
  );
}

const bstyles = StyleSheet.create({
  wrap: { flexDirection: "row", alignItems: "center", gap: 5, paddingHorizontal: 8, paddingVertical: 4, borderRadius: 8, borderWidth: 1 },
  dot:  { width: 6, height: 6, borderRadius: 3 },
  text: { fontSize: 11, fontWeight: "600" as const, fontFamily: "Inter_600SemiBold", letterSpacing: 0.3 },
});

const bsectionStyles = StyleSheet.create({
  row:       { flexDirection: "row", alignItems: "center", gap: 12, borderWidth: 1, borderRadius: 14, padding: 14 },
  rowPressed:{ opacity: 0.75, transform: [{ scale: 0.985 }] },
  iconBox:   { width: 38, height: 38, borderRadius: 10, borderWidth: 1, alignItems: "center", justifyContent: "center", flexShrink: 0 },
  textBlock: { flex: 1 },
  rowTitle:  { fontSize: 15, fontWeight: "600" as const, fontFamily: "Inter_600SemiBold" },
  rowDesc:   { fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 2 },
});

export default function SettingsScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const topInset = Platform.OS === "web" ? 67 : insets.top;
  const bottomInset = Platform.OS === "web" ? 34 : insets.bottom;
  const styles = makeStyles(colors, topInset, bottomInset);
  const router = useRouter();
  const { status: backendStatus, url: backendUrl } = useBackendConfig();

  const handleLogout = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium).catch(() => {});
    clearSession().finally(() => router.replace("/login"));
  };

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.content}
      showsVerticalScrollIndicator={false}
    >
      <View style={styles.header}>
        <View style={styles.headerTitleRow}>
          <Feather name="settings" size={22} color={colors.primary} />
          <Text style={styles.headerTitle}>Configuration</Text>
        </View>
        <Text style={styles.headerSubtitle}>System parameters</Text>
      </View>

      {/* Appearance — theme switcher */}
      <Text style={styles.appearanceLabel}>APPEARANCE</Text>
      <ThemeToggle />

      {/* Backend connection */}
      <Section title="Backend">
        <Pressable
          style={({ pressed }) => [
            bsectionStyles.row,
            { backgroundColor: colors.card, borderColor: colors.border },
            pressed && bsectionStyles.rowPressed,
          ]}
          onPress={() => safeNavigate(router, "/settings/backend-connect")}
        >
          <View style={[bsectionStyles.iconBox, { backgroundColor: colors.primary + "18", borderColor: colors.primary + "40" }]}>
            <Feather name="server" size={18} color={colors.primary} />
          </View>
          <View style={bsectionStyles.textBlock}>
            <Text style={[bsectionStyles.rowTitle, { color: colors.foreground }]}>Connect Backend</Text>
            <Text style={[bsectionStyles.rowDesc, { color: colors.mutedForeground }]} numberOfLines={1}>
              {backendStatus === "connected" && backendUrl
                ? backendUrl
                : "Fully offline — tap to configure"}
            </Text>
          </View>
          <BackendStatusBadge status={backendStatus} />
        </Pressable>
      </Section>

      <Section title="Radio Hardware">
        <SettingRow
          icon="bluetooth"
          title="BLE Transceiver"
          description="Primary short-range transport"
          toggle
          defaultOn
        />
        <SettingRow
          icon="zap"
          title="High Tx Power"
          description="Increases range, drains battery"
          toggle
        />
      </Section>

      <Section title="Routing & Security">
        <SettingRow
          icon="cpu"
          title="Hybrid Routing"
          description="Auto-failover to LoRa"
          toggle
          defaultOn
        />
        <SettingRow
          icon="shield"
          title="Strict Mode"
          description="Drop unverified packets"
          toggle
          defaultOn
        />
      </Section>

      <Section title="Friends">
        <SettingRow
          icon="user-plus"
          title="Add Friend"
          description="Scan QR or find nearby MauriMesh nodes"
          onPress={() => safeNavigate(router, "/add-friend")}
        />
        <SettingRow
          icon="maximize"
          title="My QR Code"
          description="Share your mesh identity"
          onPress={() => safeNavigate(router, "/my-qr")}
        />
      </Section>

      <Section title="System">
        <SettingRow
          icon="database"
          title="Local Storage"
          description="Manage message retention and on-device data"
          onPress={() => safeNavigate(router, "/local-storage")}
        />
        <SettingRow
          icon="activity"
          title="Export Diagnostic Logs"
          description="View system events and share a report"
          onPress={() => safeNavigate(router, "/diagnostic-logs")}
        />
        <SettingRow
          icon="cpu"
          title="Living Mesh Core"
          description="3D mesh visualiser · offline engine"
          onPress={() => safeNavigate(router, "/living-mesh")}
        />
      </Section>

      <Section title="Device Testing">
        <SettingRow
          icon="cpu"
          title="Device Proof Suite"
          description="BLE readiness check and 6-test proof suite"
          onPress={() => safeNavigate(router, "/device-proof")}
        />
      </Section>

      {/* Native Proof Checklist */}
      <View style={styles.checklistSection}>
        <Text style={styles.checklistTitle}>NATIVE PROOF CHECKLIST</Text>
        {[
          "APK required — Expo Go cannot run native BLE",
          "Physical Android phones required (min 2)",
          "Same app build installed on both phones",
          "Wi-Fi & mobile data turned off during test",
          "BLE scan / send / receive logs must be captured",
        ].map((item, i) => (
          <View key={i} style={styles.checklistRow}>
            <View style={[styles.checklistDot, { backgroundColor: colors.primary + "33", borderColor: colors.primary + "66" }]}>
              <Text style={[styles.checklistDotText, { color: colors.primary }]}>{i + 1}</Text>
            </View>
            <Text style={[styles.checklistText, { color: colors.mutedForeground }]}>{item}</Text>
          </View>
        ))}
        <Pressable
          style={({ pressed }) => [
            styles.proofBtn,
            { backgroundColor: colors.primary + "1a", borderColor: colors.primary + "44", opacity: pressed ? 0.75 : 1 },
          ]}
          onPress={() => safeNavigate(router, "/device-proof")}
        >
          <Feather name="arrow-right-circle" size={16} color={colors.primary} />
          <Text style={[styles.proofBtnText, { color: colors.primary }]}>Open Device Proof Suite</Text>
        </Pressable>
      </View>

      {/* Premium invite card — replaces the two plain share rows */}
      <InviteCard />

      {/* Log Out */}
      <Pressable
        style={({ pressed }) => [
          styles.logoutBtn,
          pressed && styles.logoutBtnPressed,
        ]}
        onPress={handleLogout}
      >
        <Feather name="log-out" size={17} color={colors.destructive} />
        <Text style={styles.logoutBtnText}>Log Out</Text>
      </Pressable>

      <View style={styles.footer}>
        <Text style={styles.footerVersion}>MauriMesh Core v1.4.2-alpha</Text>
        <Text style={styles.footerTagline}>Built for resilience</Text>
      </View>
    </ScrollView>
  );
}

// ── Styles ────────────────────────────────────────────────────────────────────

function makeStyles(colors: Colors, topInset: number, bottomInset: number) {
  return StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: colors.background,
    },
    content: {
      paddingBottom: bottomInset + 80,
    },
    appearanceLabel: {
      fontSize: 11,
      fontWeight: "700" as const,
      color: colors.mutedForeground,
      letterSpacing: 2,
      textTransform: "uppercase",
      paddingHorizontal: 24,
      paddingTop: 28,
      fontFamily: "Inter_700Bold",
    },
    header: {
      paddingTop: topInset + 16,
      paddingHorizontal: 24,
      paddingBottom: 24,
      borderBottomWidth: StyleSheet.hairlineWidth,
      borderBottomColor: colors.border,
      backgroundColor: colors.background + "e6",
    },
    headerTitleRow: {
      flexDirection: "row",
      alignItems: "center",
      gap: 10,
    },
    headerTitle: {
      fontSize: 24,
      fontWeight: "700" as const,
      color: colors.foreground,
      fontFamily: "Inter_700Bold",
      letterSpacing: -0.5,
    },
    headerSubtitle: {
      fontSize: 13,
      color: colors.mutedForeground,
      fontFamily: "Inter_400Regular",
      marginTop: 4,
    },
    checklistSection: {
      marginHorizontal: 20,
      marginTop: 24,
      gap: 10,
    },
    checklistTitle: {
      fontSize: 11,
      fontWeight: "700" as const,
      color: colors.mutedForeground,
      letterSpacing: 1.8,
      textTransform: "uppercase" as const,
      fontFamily: "Inter_700Bold",
      marginBottom: 4,
    },
    checklistRow: {
      flexDirection: "row" as const,
      alignItems: "flex-start" as const,
      gap: 12,
    },
    checklistDot: {
      width: 22,
      height: 22,
      borderRadius: 11,
      borderWidth: 1,
      alignItems: "center" as const,
      justifyContent: "center" as const,
      marginTop: 1,
    },
    checklistDotText: {
      fontSize: 10,
      fontWeight: "700" as const,
      fontFamily: "Inter_700Bold",
    },
    checklistText: {
      flex: 1,
      fontSize: 13,
      lineHeight: 19,
      fontFamily: "Inter_400Regular",
    },
    proofBtn: {
      flexDirection: "row" as const,
      alignItems: "center" as const,
      justifyContent: "center" as const,
      gap: 8,
      marginTop: 8,
      paddingVertical: 13,
      borderRadius: 12,
      borderWidth: 1,
    },
    proofBtnText: {
      fontSize: 14,
      fontWeight: "600" as const,
      fontFamily: "Inter_600SemiBold",
    },
    logoutBtn: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      gap: 10,
      marginHorizontal: 20,
      marginTop: 28,
      paddingVertical: 15,
      borderRadius: 14,
      borderWidth: 1,
      borderColor: colors.destructive + "59",
      backgroundColor: colors.destructive + "14",
    },
    logoutBtnPressed: {
      opacity: 0.7,
      transform: [{ scale: 0.97 }],
    },
    logoutBtnText: {
      fontSize: 15,
      fontWeight: "600" as const,
      color: colors.destructive,
      fontFamily: "Inter_600SemiBold",
      letterSpacing: 0.2,
    },
    footer: {
      alignItems: "center",
      paddingTop: 32,
      paddingVertical: 24,
      gap: 4,
    },
    footerVersion: {
      fontSize: 12,
      color: colors.mutedForeground,
      fontFamily: "Inter_400Regular",
      opacity: 0.6,
    },
    footerTagline: {
      fontSize: 10,
      color: colors.mutedForeground,
      fontFamily: "Inter_400Regular",
      opacity: 0.4,
    },
  });
}

function makeRowStyles(colors: Colors) {
  return StyleSheet.create({
    row: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      paddingVertical: 13,
      paddingHorizontal: 16,
      borderBottomWidth: StyleSheet.hairlineWidth,
      borderBottomColor: colors.border,
    },
    rowPressed: {
      backgroundColor: colors.secondary,
    },
    rowLeft: {
      flexDirection: "row",
      alignItems: "center",
      flex: 1,
      gap: 14,
    },
    iconBox: {
      width: 36,
      height: 36,
      borderRadius: 10,
      backgroundColor: colors.secondary,
      alignItems: "center",
      justifyContent: "center",
    },
    textBlock: {
      flex: 1,
    },
    rowTitle: {
      fontSize: 14,
      fontWeight: "500" as const,
      color: colors.foreground,
      fontFamily: "Inter_500Medium",
    },
    rowDesc: {
      fontSize: 12,
      color: colors.mutedForeground,
      fontFamily: "Inter_400Regular",
      marginTop: 2,
    },
    rowRight: {
      marginLeft: 12,
    },
  });
}

function makeSectionStyles(colors: Colors) {
  return StyleSheet.create({
    section: {
      marginTop: 28,
      gap: 8,
    },
    sectionTitle: {
      fontSize: 11,
      fontWeight: "700" as const,
      color: colors.mutedForeground,
      letterSpacing: 2,
      textTransform: "uppercase",
      paddingHorizontal: 24,
      fontFamily: "Inter_700Bold",
    },
    sectionCard: {
      borderTopWidth: StyleSheet.hairlineWidth,
      borderColor: colors.border,
      backgroundColor: colors.card,
      overflow: "hidden",
    },
  });
}
