import { useState } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { radius } from "../../src/design-system/radius";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshStatusPill } from "../../src/components/ui/MeshStatusPill";

type QualityLevel = "ultra" | "high" | "balanced" | "low" | "emergency";

const LEVELS: { key: QualityLevel; label: string; bitrate: string; latency: string; desc: string }[] = [
  { key: "ultra",     label: "Ultra",     bitrate: "64 kbps", latency: "< 40 ms",  desc: "Best quality — requires strong BLE signal"   },
  { key: "high",      label: "High",      bitrate: "32 kbps", latency: "< 80 ms",  desc: "Clear voice — suitable for 1–2 hop paths"    },
  { key: "balanced",  label: "Balanced",  bitrate: "16 kbps", latency: "< 150 ms", desc: "Good quality — stable on 2–3 hops"           },
  { key: "low",       label: "Low",       bitrate: "8 kbps",  latency: "< 300 ms", desc: "Conserves bandwidth — works on weak signal"  },
  { key: "emergency", label: "Emergency", bitrate: "4 kbps",  latency: "< 600 ms", desc: "Minimum viable — extreme relay conditions"   },
];

export default function AdaptiveQualityScreen() {
  const [mode, setMode]   = useState<"auto" | "manual">("auto");
  const [level, setLevel] = useState<QualityLevel>("balanced");
  const current           = LEVELS.find((l) => l.key === (mode === "auto" ? "balanced" : level))!;

  return (
    <ScreenWithHeader title="Adaptive Quality" subtitle="Pixel Calling quality settings">
      <MeshCard title="Quality Mode">
        <View style={styles.modeRow}>
          {(["auto", "manual"] as const).map((m) => (
            <Pressable
              key={m}
              onPress={() => setMode(m)}
              style={[styles.modeBtn, mode === m && styles.modeBtnActive]}
            >
              <Text style={[styles.modeBtnText, mode === m && styles.modeBtnTextActive]}>
                {m === "auto" ? "⟳  Auto" : "⊙  Manual"}
              </Text>
            </Pressable>
          ))}
        </View>
      </MeshCard>

      <MeshCard title="Current Profile">
        <View style={styles.profileRow}>
          <View style={styles.profileMeta}>
            <Text style={styles.profileLabel}>{current.label}</Text>
            <Text style={styles.profileDesc}>{current.desc}</Text>
          </View>
          <MeshStatusPill label={mode === "auto" ? "Auto" : "Manual"} variant={mode === "auto" ? "syncing" : "online"} />
        </View>
        {[
          ["Bitrate",  current.bitrate],
          ["Latency",  current.latency],
          ["Codec",    "Opus"],
          ["Channels", "Mono"],
        ].map(([label, value]) => (
          <View key={label as string} style={styles.row}>
            <Text style={styles.rowLabel}>{label}</Text>
            <Text style={styles.rowValue}>{value}</Text>
          </View>
        ))}
      </MeshCard>

      {mode === "manual" && (
        <MeshCard title="Select Level">
          {LEVELS.map((l) => (
            <Pressable
              key={l.key}
              onPress={() => setLevel(l.key)}
              style={[styles.levelRow, level === l.key && styles.levelRowActive]}
            >
              <View style={styles.levelMeta}>
                <Text style={[styles.levelName, level === l.key && styles.levelNameActive]}>{l.label}</Text>
                <Text style={styles.levelBitrate}>{l.bitrate} · {l.latency}</Text>
              </View>
              {level === l.key && <Text style={styles.check}>✓</Text>}
            </Pressable>
          ))}
        </MeshCard>
      )}
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  modeRow:          { flexDirection: "row", gap: spacing.xs },
  modeBtn:          { flex: 1, paddingVertical: spacing.sm, borderRadius: radius.md, backgroundColor: DS.surface, borderWidth: 1, borderColor: DS.divider, alignItems: "center" },
  modeBtnActive:    { backgroundColor: DS.greenDim, borderColor: DS.greenBorder },
  modeBtnText:      { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.medium },
  modeBtnTextActive:{ color: DS.mauriGreen,    fontFamily: typography.fonts.bold },
  profileRow:       { flexDirection: "row", alignItems: "center", justifyContent: "space-between", marginBottom: spacing.sm },
  profileMeta:      { flex: 1, gap: 2 },
  profileLabel:     { color: DS.textPrimary,   fontSize: typography.sizes.lg, fontFamily: typography.fonts.bold    },
  profileDesc:      { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular },
  row:              { flexDirection: "row", justifyContent: "space-between", paddingVertical: 6 },
  rowLabel:         { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular  },
  rowValue:         { color: DS.textPrimary,   fontSize: typography.sizes.sm, fontFamily: typography.fonts.semibold },
  levelRow:         { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingVertical: spacing.sm, borderBottomWidth: 1, borderBottomColor: DS.divider },
  levelRowActive:   { borderBottomColor: DS.greenBorder },
  levelMeta:        { gap: 2 },
  levelName:        { color: DS.textPrimary,   fontSize: typography.sizes.base, fontFamily: typography.fonts.medium   },
  levelNameActive:  { color: DS.mauriGreen,                                     fontFamily: typography.fonts.semibold },
  levelBitrate:     { color: DS.textSecondary, fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular  },
  check:            { color: DS.mauriGreen, fontSize: typography.sizes.lg, fontFamily: typography.fonts.bold },
});
