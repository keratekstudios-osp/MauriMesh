import { Pressable, StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import * as Haptics from "expo-haptics";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { radius } from "../../src/design-system/radius";
import { spacing } from "../../src/design-system/spacing";
import { MeshStatusPill } from "../../src/components/ui/MeshStatusPill";

export default function IncomingCallScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();

  function handleAccept() {
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    router.replace("/calling/active-call");
  }

  function handleDecline() {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
    router.back();
  }

  return (
    <View style={[styles.root, { paddingTop: insets.top, paddingBottom: insets.bottom + 24 }]}>
      <StatusBar style="light" />

      <View style={styles.callTypePill}>
        <MeshStatusPill label="◌  Incoming Pixel Call" variant="online" />
      </View>

      <View style={styles.callerSection}>
        <View style={styles.callerOrb}>
          <Text style={styles.callerInitial}>K</Text>
          <View style={styles.orbPulse} />
        </View>
        <Text style={styles.callerName}>Kupe-Node-1</Text>
        <Text style={styles.callerSub}>Peer · 1 hop · 52 dBm signal</Text>
        <Text style={styles.callLabel}>Pixel Voice Call — Mesh Encrypted</Text>
      </View>

      <View style={styles.controls}>
        <View style={styles.controlRow}>
          <Pressable
            onPress={handleDecline}
            style={({ pressed }) => [
              styles.ctrlBtn,
              styles.declineBtn,
              pressed && styles.ctrlBtnPressed,
            ]}
          >
            <Text style={styles.ctrlBtnIcon}>✕</Text>
          </Pressable>

          <Pressable
            onPress={handleAccept}
            style={({ pressed }) => [
              styles.ctrlBtn,
              styles.acceptBtn,
              pressed && styles.ctrlBtnPressed,
            ]}
          >
            <Text style={styles.ctrlBtnIcon}>✆</Text>
          </Pressable>
        </View>

        <View style={styles.labelRow}>
          <Text style={styles.ctrlLabel}>Decline</Text>
          <Text style={styles.ctrlLabel}>Accept</Text>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1, backgroundColor: DS.deepSpace,
    alignItems: "center", justifyContent: "space-between",
    paddingHorizontal: spacing.xl,
  },
  callTypePill:  { marginTop: spacing.lg },
  callerSection: { alignItems: "center", gap: spacing.md },
  callerOrb: {
    width:           120,
    height:          120,
    borderRadius:    radius.full,
    backgroundColor: DS.greenDim,
    borderWidth:     3,
    borderColor:     DS.greenBorderBright,
    alignItems:      "center",
    justifyContent:  "center",
    shadowColor:     DS.mauriGreen,
    shadowOpacity:   0.45,
    shadowRadius:    40,
    elevation:       16,
  },
  orbPulse: {
    position: "absolute", width: 140, height: 140,
    borderRadius: radius.full, borderWidth: 2,
    borderColor: DS.greenBorder, opacity: 0.40,
  },
  callerInitial: { color: DS.mauriGreen, fontSize: 52, fontFamily: typography.fonts.bold },
  callerName:    { color: DS.textPrimary,  fontSize: typography.sizes["3xl"], fontFamily: typography.fonts.bold    },
  callerSub:     { color: DS.textSecondary, fontSize: typography.sizes.sm,  fontFamily: typography.fonts.regular  },
  callLabel:     { color: DS.mauriGreen, fontSize: typography.sizes.xs, fontFamily: typography.fonts.semibold, letterSpacing: typography.tracking.wide },
  controls:      { width: "100%", gap: spacing.sm },
  controlRow:    { flexDirection: "row", justifyContent: "space-around", alignItems: "center" },
  ctrlBtn: {
    width: 80, height: 80, borderRadius: radius.full,
    alignItems: "center", justifyContent: "center",
  },
  ctrlBtnPressed: { transform: [{ scale: 0.92 }], opacity: 0.80 },
  declineBtn:    { backgroundColor: DS.dangerRed,   shadowColor: DS.dangerRed,  shadowOpacity: 0.40, shadowRadius: 20, elevation: 8 },
  acceptBtn:     { backgroundColor: DS.mauriGreen,  shadowColor: DS.mauriGreen, shadowOpacity: 0.50, shadowRadius: 24, elevation: 10 },
  ctrlBtnIcon:   { fontSize: 32, color: DS.deepSpace, fontFamily: typography.fonts.bold },
  labelRow:      { flexDirection: "row", justifyContent: "space-around" },
  ctrlLabel:     { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, textAlign: "center", width: 80 },
});
