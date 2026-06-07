import { useState } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import * as Haptics from "expo-haptics";
import { useRouter } from "expo-router";
import { StatusBar } from "expo-status-bar";
import ScreenShell from "../components/ScreenShell";
import { safeNavigate } from "../lib/safeNavigate";
import { mauriTheme } from "../src/theme/mauriTheme";

const { colors } = mauriTheme;

export default function AddFriendScreen() {
  const router = useRouter();
  const [scanActive, setScanActive] = useState(false);

  async function handleScanQR() {
    await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    setScanActive(true);
    setTimeout(() => setScanActive(false), 2000);
    safeNavigate(router, "/scan-friend");
  }

  async function handleNearby() {
    await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    safeNavigate(router, "/invite");
  }

  async function handleMyQR() {
    await Haptics.selectionAsync();
    safeNavigate(router, "/my-qr");
  }

  return (
    <>
      <StatusBar style="light" />
      <ScreenShell title="Add Friend" subtitle="Scan QR or find nearby nodes">
        {/* QR visual shell */}
        <View style={styles.qrCard}>
          <View style={styles.qrFrame}>
            {/* QR corner marks */}
            <View style={[styles.qrCorner, styles.qrTL]} />
            <View style={[styles.qrCorner, styles.qrTR]} />
            <View style={[styles.qrCorner, styles.qrBL]} />
            <View style={[styles.qrCorner, styles.qrBR]} />
            {/* Centre icon */}
            <View style={styles.qrCenter}>
              <Text style={styles.qrIcon}>⌗</Text>
            </View>
          </View>

          <Text style={styles.qrLabel}>SCAN FRIEND'S QR CODE</Text>
          <Text style={styles.qrSub}>
            Point your camera at a friend's MauriMesh QR to add them to your trusted node list.
          </Text>

          {/* Device proof warning */}
          <View style={styles.proofPill}>
            <Text style={styles.proofIcon}>⚠</Text>
            <Text style={styles.proofText}>
              Camera scan requires physical device — not available in Replit preview.
            </Text>
          </View>
        </View>

        {/* Primary action — Scan QR */}
        <Pressable
          onPress={handleScanQR}
          disabled={scanActive}
          style={({ pressed }) => [
            styles.btn,
            styles.btnPrimary,
            pressed && styles.btnPressed,
            scanActive && styles.btnDisabled,
          ]}
        >
          <Text style={styles.btnIcon}>⌗</Text>
          <View style={{ flex: 1 }}>
            <Text style={styles.btnLabel}>Scan QR Code</Text>
            <Text style={styles.btnSub}>Add by scanning friend's code</Text>
          </View>
          <Text style={styles.btnArrow}>→</Text>
        </Pressable>

        {/* Secondary action — Nearby BLE */}
        <Pressable
          onPress={handleNearby}
          style={({ pressed }) => [
            styles.btn,
            styles.btnSecondary,
            pressed && styles.btnPressed,
          ]}
        >
          <Text style={styles.btnIcon}>◎</Text>
          <View style={{ flex: 1 }}>
            <Text style={[styles.btnLabel, { color: colors.blueWeb }]}>
              Search Nearby Mesh
            </Text>
            <Text style={styles.btnSub}>BLE discovery — within 30 m</Text>
          </View>
          <Text style={[styles.btnArrow, { color: colors.blueWeb }]}>→</Text>
        </Pressable>

        {/* Show my QR */}
        <Pressable
          onPress={handleMyQR}
          style={({ pressed }) => [
            styles.btn,
            styles.btnGhost,
            pressed && styles.btnPressed,
          ]}
        >
          <Text style={styles.btnIcon}>◈</Text>
          <View style={{ flex: 1 }}>
            <Text style={[styles.btnLabel, { color: colors.muted }]}>
              Show My QR Code
            </Text>
            <Text style={styles.btnSub}>Let others scan to add you</Text>
          </View>
          <Text style={[styles.btnArrow, { color: colors.muted }]}>→</Text>
        </Pressable>

        {/* Info card */}
        <View style={styles.infoCard}>
          <Text style={styles.infoTitle}>HOW MESH PAIRING WORKS</Text>
          {[
            ["◌", "BLE Range",     "Works within 30 m — no internet required."],
            ["⬡", "Trust First",   "All peers must be manually approved."],
            ["◉", "Encrypted",     "AES-256 end-to-end on every message."],
            ["∞", "Offline Ready", "Mesh routing works with no Wi-Fi or data."],
          ].map(([icon, title, desc]) => (
            <View key={title} style={styles.infoRow}>
              <Text style={styles.infoIcon}>{icon}</Text>
              <View style={{ flex: 1 }}>
                <Text style={styles.infoRowTitle}>{title}</Text>
                <Text style={styles.infoRowDesc}>{desc}</Text>
              </View>
            </View>
          ))}
        </View>
      </ScreenShell>
    </>
  );
}

const styles = StyleSheet.create({
  qrCard: {
    padding: 28,
    borderRadius: 28,
    backgroundColor: "#101827",
    borderWidth: 1,
    borderColor: colors.greenBorder,
    alignItems: "center",
    marginBottom: 16,
    gap: 14,
    shadowColor: colors.greenstone,
    shadowOpacity: 0.10,
    shadowRadius: 20,
    elevation: 6,
  },
  qrFrame: {
    width: 140,
    height: 140,
    alignItems: "center",
    justifyContent: "center",
    position: "relative",
  },
  qrCenter: {
    width: 64,
    height: 64,
    borderRadius: 16,
    backgroundColor: colors.greenDim,
    borderWidth: 1,
    borderColor: colors.greenBorder,
    alignItems: "center",
    justifyContent: "center",
  },
  qrIcon: {
    color: colors.greenstone,
    fontSize: 32,
    fontWeight: "900",
  },
  qrCorner: {
    position: "absolute",
    width: 22,
    height: 22,
    borderColor: colors.greenstone,
    borderWidth: 2.5,
  },
  qrTL: { top: 0,    left: 0,    borderRightWidth: 0, borderBottomWidth: 0, borderTopLeftRadius: 6     },
  qrTR: { top: 0,    right: 0,   borderLeftWidth: 0,  borderBottomWidth: 0, borderTopRightRadius: 6    },
  qrBL: { bottom: 0, left: 0,    borderRightWidth: 0, borderTopWidth: 0,    borderBottomLeftRadius: 6  },
  qrBR: { bottom: 0, right: 0,   borderLeftWidth: 0,  borderTopWidth: 0,    borderBottomRightRadius: 6 },
  qrLabel: {
    color: colors.white,
    fontSize: 14,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
    letterSpacing: 3,
    textAlign: "center",
  },
  qrSub: {
    color: colors.muted,
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    textAlign: "center",
    lineHeight: 20,
  },
  proofPill: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 8,
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 12,
    backgroundColor: colors.amberDim,
    borderWidth: 1,
    borderColor: colors.amberBorder,
    alignSelf: "stretch",
  },
  proofIcon: {
    color: colors.warning,
    fontSize: 13,
    flexShrink: 0,
    marginTop: 1,
  },
  proofText: {
    flex: 1,
    color: colors.warning,
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    lineHeight: 17,
  },
  btn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 14,
    padding: 20,
    borderRadius: 20,
    borderWidth: 1,
    marginBottom: 10,
  },
  btnPrimary: {
    backgroundColor: colors.greenDim,
    borderColor:     colors.greenBorder,
  },
  btnSecondary: {
    backgroundColor: colors.blueDim,
    borderColor:     colors.blueBorder,
  },
  btnGhost: {
    backgroundColor: "#101827",
    borderColor:     "rgba(255,255,255,0.07)",
  },
  btnPressed: {
    opacity: 0.80,
    transform: [{ scale: 0.978 }],
  },
  btnDisabled: {
    opacity: 0.50,
  },
  btnIcon: {
    color: colors.greenstone,
    fontSize: 26,
    width: 32,
    textAlign: "center",
  },
  btnLabel: {
    color: colors.white,
    fontSize: 16,
    fontWeight: "800",
    fontFamily: "Inter_700Bold",
  },
  btnSub: {
    color: colors.muted,
    fontSize: 12,
    fontFamily: "Inter_400Regular",
    marginTop: 2,
  },
  btnArrow: {
    color: colors.greenstone,
    fontSize: 20,
    fontWeight: "900",
  },
  infoCard: {
    padding: 20,
    borderRadius: 20,
    backgroundColor: "#101827",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.07)",
    marginTop: 6,
    gap: 14,
  },
  infoTitle: {
    color: "#94A3B8",
    fontSize: 10,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
    letterSpacing: 4,
    marginBottom: 4,
  },
  infoRow: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 14,
  },
  infoIcon: {
    color: colors.greenstone,
    fontSize: 20,
    width: 24,
    textAlign: "center",
    marginTop: 1,
  },
  infoRowTitle: {
    color: colors.white,
    fontSize: 14,
    fontWeight: "800",
    fontFamily: "Inter_700Bold",
  },
  infoRowDesc: {
    color: colors.muted,
    fontSize: 12,
    fontFamily: "Inter_400Regular",
    marginTop: 2,
    lineHeight: 18,
  },
});
