/**
 * MauriMeshAccessCard — premium invite card for the Settings screen.
 *
 * Extracted from settings.tsx so it can be tested and reused independently.
 * All colours are card-local (emerald/jade palette) — independent of the
 * app theme so the card always feels dark and premium.
 */

import { Feather } from "@expo/vector-icons";
import Constants from "expo-constants";
import * as Haptics from "expo-haptics";
import { LinearGradient } from "expo-linear-gradient";
import {
  Alert,
  Linking,
  Platform,
  Pressable,
  Share,
  StyleSheet,
  Text,
  View,
} from "react-native";

// ── Install link ──────────────────────────────────────────────────────────────

const INSTALL_URL =
  Constants.expoConfig?.extra?.installUrl as string | undefined;

const SHARE_TITLE = "MauriMesh — Private Mesh Access";

const SHARE_MESSAGE = INSTALL_URL
  ? `You've been invited to test MauriMesh Messenger.\n\nMauriMesh is a private decentralized communication network built for resilient, offline-first connection.\n\nInstall here:\n${INSTALL_URL}`
  : "";

// ── Palette ───────────────────────────────────────────────────────────────────

const JADE = {
  grad0:    "#031a10" as const,
  grad1:    "#042d1a" as const,
  grad2:    "#064e3b" as const,
  accent:   "#10b981" as const,
  accentDim:"rgba(16,185,129,0.18)" as const,
  border:   "rgba(16,185,129,0.28)" as const,
  white:    "#ffffff" as const,
  silver:   "rgba(255,255,255,0.65)" as const,
  muted:    "rgba(255,255,255,0.38)" as const,
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
        title:   SHARE_TITLE,
        message: Platform.OS === "ios" ? SHARE_TITLE : SHARE_MESSAGE,
        url:     INSTALL_URL,
      },
      { dialogTitle: SHARE_TITLE, subject: SHARE_TITLE }
    );
  } catch {
    Alert.alert(
      "Share failed",
      "The invite link could not be shared."
    );
  }
}

async function handleOpenInstallLink() {
  if (!INSTALL_URL) {
    Alert.alert("Install link missing", "Update extra.installUrl in app.json.");
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

// ── Component ─────────────────────────────────────────────────────────────────

export function MauriMeshAccessCard() {
  const urlPreview = INSTALL_URL
    ? INSTALL_URL.replace(/^https?:\/\//, "").slice(0, 40) +
      (INSTALL_URL.length > 48 ? "…" : "")
    : "No install link configured";

  return (
    <View style={s.wrapper}>
      <View style={s.glowRing} />
      <LinearGradient
        colors={[JADE.grad0, JADE.grad1, JADE.grad2]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={s.gradient}
      >
        {/* Top row */}
        <View style={s.topRow}>
          <View style={s.iconCircle}>
            <Feather name="share-2" size={20} color={JADE.accent} />
          </View>
          <View style={s.badge}>
            <Feather name="shield" size={9} color={JADE.accent} />
            <Text style={s.badgeText}>Trusted Access</Text>
          </View>
        </View>

        <Text style={s.title}>MauriMesh Access</Text>
        <Text style={s.body}>
          Invite a trusted tester to install MauriMesh Messenger and join the
          private mesh network.
        </Text>

        {/* URL preview */}
        <View style={s.urlPill}>
          <Feather name="link" size={10} color={JADE.accent} />
          <Text style={s.urlText} numberOfLines={1}>{urlPreview}</Text>
        </View>

        <View style={s.divider} />

        {/* Primary CTA */}
        <Pressable
          style={({ pressed }) => [s.primaryBtn, pressed && s.primaryBtnPressed]}
          onPress={handleShareInvite}
        >
          <Feather name="send" size={15} color={JADE.white} />
          <Text style={s.primaryBtnText}>Share Invite</Text>
        </Pressable>

        {/* Secondary link */}
        <Pressable
          style={({ pressed }) => [s.secondaryBtn, pressed && s.secondaryBtnPressed]}
          onPress={handleOpenInstallLink}
        >
          <Feather name="external-link" size={13} color={JADE.silver} />
          <Text style={s.secondaryBtnText}>Open Install Page</Text>
        </Pressable>
      </LinearGradient>
    </View>
  );
}

const s = StyleSheet.create({
  wrapper: {
    marginHorizontal: 20,
    marginTop: 28,
    borderRadius: 24,
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
  primaryBtnPressed: { opacity: 0.82, transform: [{ scale: 0.97 }] },
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
  secondaryBtnPressed: { opacity: 0.55 },
  secondaryBtnText: {
    fontSize: 13,
    color: JADE.silver,
    fontFamily: "Inter_500Medium",
    fontWeight: "500" as const,
  },
});
