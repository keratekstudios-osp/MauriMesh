import { useState } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";
import { safeNavigate } from "../../lib/safeNavigate";
import { StatusBar } from "expo-status-bar";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import * as Haptics from "expo-haptics";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { radius } from "../../src/design-system/radius";
import { spacing } from "../../src/design-system/spacing";
import { MeshStatusPill } from "../../src/components/ui/MeshStatusPill";
import { MeshBadge } from "../../src/components/ui/MeshBadge";

export default function ActiveCallScreen() {
  const router    = useRouter();
  const insets    = useSafeAreaInsets();
  const [muted,   setMuted]   = useState(false);
  const [speaker, setSpeaker] = useState(false);
  const [hold,    setHold]    = useState(false);

  function end() {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
    router.back();
  }

  function toggle(fn: (v: boolean) => void, v: boolean) {
    Haptics.selectionAsync();
    fn(!v);
  }

  return (
    <View style={[styles.root, { paddingTop: insets.top + 16, paddingBottom: insets.bottom + 24 }]}>
      <StatusBar style="light" />

      <View style={styles.top}>
        <MeshStatusPill label="⬡  Mesh Encrypted Call" variant="online" />
        <MeshBadge label="1 hop · -52 dBm" variant="blue" />
      </View>

      <View style={styles.callerSection}>
        <View style={styles.callerOrb}>
          <Text style={styles.callerInitial}>K</Text>
        </View>
        <Text style={styles.callerName}>Kupe-Node-1</Text>
        <Text style={styles.timer}>0:04:32</Text>
        <Text style={styles.quality}>
          {hold ? "⏸  On Hold" : "▶  Adaptive Quality · 24 kbps"}
        </Text>
      </View>

      <View style={styles.controls}>
        <View style={styles.controlRow}>
          <CtrlBtn icon={muted   ? "🔇" : "🎙"} label={muted ? "Unmute" : "Mute"}
            active={muted}   accent={DS.warningAmber} onPress={() => toggle(setMuted,   muted)}   />
          <CtrlBtn icon={speaker ? "🔊" : "🔈"} label="Speaker"
            active={speaker} accent={DS.meshBlue}     onPress={() => toggle(setSpeaker, speaker)} />
          <CtrlBtn icon="⏸" label={hold ? "Resume" : "Hold"}
            active={hold}    accent={DS.warningAmber} onPress={() => toggle(setHold,    hold)}    />
          <CtrlBtn icon="▤" label="Analytics"
            active={false}   accent={DS.textSecondary} onPress={() => safeNavigate(router, "/calling/call-analytics")} />
        </View>

        <Pressable
          onPress={end}
          style={({ pressed }) => [styles.endBtn, pressed && styles.endBtnPressed]}
        >
          <Text style={styles.endIcon}>✕</Text>
        </Pressable>
        <Text style={styles.endLabel}>End Call</Text>
      </View>
    </View>
  );
}

function CtrlBtn({ icon, label, active, accent, onPress }: {
  icon: string; label: string; active: boolean; accent: string; onPress: () => void;
}) {
  return (
    <View style={styles.ctrlWrap}>
      <Pressable
        onPress={onPress}
        style={({ pressed }) => [
          styles.ctrlBtn,
          { backgroundColor: active ? `${accent}20` : DS.card, borderColor: active ? accent : DS.divider },
          pressed && styles.ctrlBtnPressed,
        ]}
      >
        <Text style={styles.ctrlIcon}>{icon}</Text>
      </Pressable>
      <Text style={styles.ctrlLabel}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  root:          { flex: 1, backgroundColor: DS.deepSpace, alignItems: "center", justifyContent: "space-between", paddingHorizontal: spacing.xl },
  top:           { flexDirection: "row", gap: spacing.xs, flexWrap: "wrap", justifyContent: "center" },
  callerSection: { alignItems: "center", gap: spacing.sm },
  callerOrb: {
    width: 100, height: 100, borderRadius: radius.full,
    backgroundColor: DS.greenDim, borderWidth: 2, borderColor: DS.greenBorderBright,
    alignItems: "center", justifyContent: "center",
    shadowColor: DS.mauriGreen, shadowOpacity: 0.35, shadowRadius: 28, elevation: 10,
  },
  callerInitial: { color: DS.mauriGreen, fontSize: 44, fontFamily: typography.fonts.bold },
  callerName:    { color: DS.textPrimary,   fontSize: typography.sizes["2xl"], fontFamily: typography.fonts.bold    },
  timer:         { color: DS.mauriGreen,    fontSize: typography.sizes["3xl"], fontFamily: typography.fonts.bold, letterSpacing: 2 },
  quality:       { color: DS.textSecondary, fontSize: typography.sizes.sm,     fontFamily: typography.fonts.regular },
  controls:      { width: "100%", alignItems: "center", gap: spacing.lg },
  controlRow:    { flexDirection: "row", justifyContent: "space-around", width: "100%" },
  ctrlWrap:      { alignItems: "center", gap: spacing.xs },
  ctrlBtn:       { width: 60, height: 60, borderRadius: radius.full, borderWidth: 1, alignItems: "center", justifyContent: "center" },
  ctrlBtnPressed:{ transform: [{ scale: 0.90 }] },
  ctrlIcon:      { fontSize: 24 },
  ctrlLabel:     { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular },
  endBtn: {
    width: 72, height: 72, borderRadius: radius.full, backgroundColor: DS.dangerRed,
    alignItems: "center", justifyContent: "center",
    shadowColor: DS.dangerRed, shadowOpacity: 0.50, shadowRadius: 24, elevation: 10,
  },
  endBtnPressed: { transform: [{ scale: 0.92 }] },
  endIcon:       { fontSize: 30, color: DS.deepSpace, fontFamily: typography.fonts.bold },
  endLabel:      { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular },
});
