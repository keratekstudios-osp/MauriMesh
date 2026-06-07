import { Feather } from "@expo/vector-icons";
import { CameraView, useCameraPermissions } from "expo-camera";
import { useRouter } from "expo-router";
import { useState } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { useColors } from "../hooks/useColors";
import { parseFriendInvite } from "../lib/friends/friendQr";
import { addFriendFromInvite } from "../lib/friends/friendStore";

export default function ScanFriendScreen() {
  const router = useRouter();
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const [permission, requestPermission] = useCameraPermissions();
  const [locked, setLocked] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState("");

  if (!permission) {
    return (
      <View style={[styles.center, { backgroundColor: colors.background }]}>
        <Text style={[styles.infoText, { color: colors.mutedForeground }]}>
          Checking camera…
        </Text>
      </View>
    );
  }

  if (!permission.granted) {
    return (
      <View style={[styles.center, { backgroundColor: colors.background, paddingTop: insets.top }]}>
        <View style={[styles.permCard, { backgroundColor: colors.card, borderColor: colors.border }]}>
          <Feather name="camera" size={40} color={colors.primary} />
          <Text style={[styles.permTitle, { color: colors.foreground }]}>
            Camera Access Required
          </Text>
          <Text style={[styles.permBody, { color: colors.mutedForeground }]}>
            MauriMesh needs camera access to scan friend QR codes.
          </Text>
          <Pressable
            style={[styles.allowBtn, { backgroundColor: colors.primary }]}
            onPress={requestPermission}
          >
            <Text style={[styles.allowBtnText, { color: colors.primaryForeground }]}>
              Allow Camera
            </Text>
          </Pressable>
          <Pressable onPress={() => router.back()} style={styles.backLink}>
            <Text style={[styles.backLinkText, { color: colors.mutedForeground }]}>Go Back</Text>
          </Pressable>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.root}>
      <CameraView
        style={StyleSheet.absoluteFill}
        barcodeScannerSettings={{ barcodeTypes: ["qr"] }}
        onBarcodeScanned={
          locked
            ? undefined
            : async ({ data }) => {
                try {
                  setLocked(true);
                  setError("");
                  const invite = parseFriendInvite(data);
                  await addFriendFromInvite(invite, "qr");
                  setSuccess(true);
                  setTimeout(() => router.replace("/add-friend"), 900);
                } catch (e: unknown) {
                  setError(e instanceof Error ? e.message : "Invalid QR code");
                  setTimeout(() => {
                    setError("");
                    setLocked(false);
                  }, 2000);
                }
              }
        }
      />

      {/* Back button */}
      <View style={[styles.topBar, { paddingTop: insets.top + 8 }]}>
        <Pressable
          style={styles.backCircle}
          onPress={() => router.back()}
        >
          <Feather name="arrow-left" size={20} color="#ffffff" />
        </Pressable>
      </View>

      {/* Finder frame */}
      <View style={styles.frame}>
        <View style={styles.corner} />
        <View style={[styles.corner, styles.cornerTR]} />
        <View style={[styles.corner, styles.cornerBL]} />
        <View style={[styles.corner, styles.cornerBR]} />
      </View>

      {/* Bottom overlay */}
      <View style={[styles.overlay, { paddingBottom: insets.bottom + 24 }]}>
        {success ? (
          <View style={styles.successRow}>
            <Feather name="check-circle" size={22} color="#39FF14" />
            <Text style={styles.successText}>Friend added!</Text>
          </View>
        ) : error ? (
          <Text style={styles.errorText}>{error}</Text>
        ) : (
          <Text style={styles.hint}>Point at a MauriMesh friend QR code</Text>
        )}
      </View>
    </View>
  );
}

const FRAME = 220;

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#000000" },
  center: { flex: 1, alignItems: "center", justifyContent: "center", padding: 24 },
  infoText: { fontSize: 15 },
  permCard: {
    borderRadius: 24,
    borderWidth: 1,
    padding: 28,
    alignItems: "center",
    gap: 14,
    maxWidth: 340,
    width: "100%",
  },
  permTitle: {
    fontSize: 20,
    fontWeight: "700",
    fontFamily: "Inter_700Bold",
    textAlign: "center",
  },
  permBody: {
    fontSize: 14,
    fontFamily: "Inter_400Regular",
    textAlign: "center",
    lineHeight: 21,
  },
  allowBtn: {
    width: "100%",
    paddingVertical: 14,
    borderRadius: 14,
    alignItems: "center",
    marginTop: 4,
  },
  allowBtnText: {
    fontSize: 15,
    fontWeight: "700",
    fontFamily: "Inter_700Bold",
  },
  backLink: { paddingVertical: 8 },
  backLinkText: { fontSize: 14, fontFamily: "Inter_400Regular" },
  topBar: {
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    paddingHorizontal: 16,
  },
  backCircle: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: "rgba(0,0,0,0.55)",
    alignItems: "center",
    justifyContent: "center",
  },
  frame: {
    position: "absolute",
    width: FRAME,
    height: FRAME,
    top: "50%",
    left: "50%",
    marginTop: -(FRAME / 2),
    marginLeft: -(FRAME / 2),
  },
  corner: {
    position: "absolute",
    width: 28,
    height: 28,
    borderColor: "#39FF14",
    borderTopWidth: 3,
    borderLeftWidth: 3,
    borderRadius: 3,
    top: 0,
    left: 0,
  },
  cornerTR: { left: undefined, right: 0, borderLeftWidth: 0, borderRightWidth: 3 },
  cornerBL: { top: undefined, bottom: 0, borderTopWidth: 0, borderBottomWidth: 3 },
  cornerBR: {
    top: undefined,
    left: undefined,
    bottom: 0,
    right: 0,
    borderTopWidth: 0,
    borderLeftWidth: 0,
    borderBottomWidth: 3,
    borderRightWidth: 3,
  },
  overlay: {
    position: "absolute",
    bottom: 0,
    left: 0,
    right: 0,
    paddingTop: 20,
    paddingHorizontal: 24,
    backgroundColor: "rgba(0,0,0,0.7)",
    alignItems: "center",
  },
  hint: {
    color: "#94A3B8",
    fontSize: 16,
    fontFamily: "Inter_500Medium",
    textAlign: "center",
  },
  successRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
  },
  successText: {
    color: "#39FF14",
    fontSize: 18,
    fontWeight: "700",
    fontFamily: "Inter_700Bold",
  },
  errorText: {
    color: "#EF4444",
    fontSize: 15,
    fontFamily: "Inter_400Regular",
    textAlign: "center",
  },
});
