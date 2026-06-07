import { Text, View, StyleSheet } from "react-native";
import ScreenShell from "../components/ScreenShell";

export default function MyQrScreen() {
  return (
    <ScreenShell title="My QR Code" subtitle="Share your mesh identity">
      <View style={styles.container}>
        <Text style={styles.label}>MESH IDENTITY</Text>

        <View style={styles.qrWrap}>
          <View style={styles.qr}>
            <Text style={styles.qrText}>QR</Text>
          </View>
          <View style={[styles.corner, styles.tl]} />
          <View style={[styles.corner, styles.tr]} />
          <View style={[styles.corner, styles.bl]} />
          <View style={[styles.corner, styles.br]} />
        </View>

        <Text style={styles.hint}>
          Show this to a trusted peer to add you to their mesh.
        </Text>

        <View style={styles.pill}>
          <View style={styles.pillDot} />
          <Text style={styles.pillText}>ENCRYPTED IDENTITY</Text>
        </View>
      </View>
    </ScreenShell>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: "center",
    padding: 28,
    backgroundColor: "#101827",
    borderRadius: 28,
    borderWidth: 1,
    borderColor: "rgba(57,255,20,0.16)",
  },
  label: {
    color: "#39FF14",
    fontSize: 10,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
    letterSpacing: 5,
    marginBottom: 24,
  },
  qrWrap: {
    position: "relative",
    padding: 8,
  },
  qr: {
    width: 240,
    height: 240,
    borderRadius: 16,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#FFFFFF",
  },
  qrText: { color: "#050816", fontSize: 48, fontWeight: "900" },
  corner: {
    position: "absolute",
    width: 24,
    height: 24,
    borderColor: "#39FF14",
    borderWidth: 3,
  },
  tl: { top: 0, left: 0, borderRightWidth: 0, borderBottomWidth: 0, borderRadius: 4 },
  tr: { top: 0, right: 0, borderLeftWidth: 0, borderBottomWidth: 0, borderRadius: 4 },
  bl: { bottom: 0, left: 0, borderRightWidth: 0, borderTopWidth: 0, borderRadius: 4 },
  br: { bottom: 0, right: 0, borderLeftWidth: 0, borderTopWidth: 0, borderRadius: 4 },
  hint: {
    color: "#94A3B8",
    fontSize: 14,
    fontFamily: "Inter_400Regular",
    textAlign: "center",
    marginTop: 20,
    lineHeight: 22,
  },
  pill: {
    flexDirection: "row",
    alignItems: "center",
    gap: 7,
    marginTop: 20,
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 12,
    backgroundColor: "rgba(57,255,20,0.08)",
    borderWidth: 1,
    borderColor: "rgba(57,255,20,0.20)",
  },
  pillDot: { width: 6, height: 6, borderRadius: 3, backgroundColor: "#39FF14" },
  pillText: {
    color: "#39FF14",
    fontSize: 10,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
    letterSpacing: 3,
  },
});
