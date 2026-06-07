import { useState } from "react";
import { Pressable, StyleSheet, Switch, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { radius } from "../../src/design-system/radius";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";

type Theme = "dark" | "light" | "auto";
type FontSize = "sm" | "md" | "lg";

export default function AppearanceScreen() {
  const [theme, setTheme]         = useState<Theme>("dark");
  const [fontSize, setFontSize]   = useState<FontSize>("md");
  const [animations, setAnimations] = useState(true);
  const [scanOverlay, setScanOverlay] = useState(true);
  const [reducedMotion, setReducedMotion] = useState(false);

  return (
    <ScreenWithHeader title="Appearance" subtitle="Theme, font size & animations">
      <MeshCard title="Theme">
        <View style={styles.segment}>
          {(["dark", "light", "auto"] as Theme[]).map((t) => (
            <Pressable
              key={t}
              onPress={() => setTheme(t)}
              style={[styles.segBtn, theme === t && styles.segBtnActive]}
            >
              <Text style={[styles.segText, theme === t && styles.segTextActive]}>
                {t === "dark" ? "☾ Dark" : t === "light" ? "☼ Light" : "⟳ Auto"}
              </Text>
            </Pressable>
          ))}
        </View>
      </MeshCard>

      <MeshCard title="Font Size">
        <View style={styles.segment}>
          {(["sm", "md", "lg"] as FontSize[]).map((f) => (
            <Pressable
              key={f}
              onPress={() => setFontSize(f)}
              style={[styles.segBtn, fontSize === f && styles.segBtnActive]}
            >
              <Text style={[styles.segText, fontSize === f && styles.segTextActive]}>
                {f === "sm" ? "A" : f === "md" ? "A+" : "A++"}
              </Text>
            </Pressable>
          ))}
        </View>
      </MeshCard>

      <MeshCard title="Motion & Effects">
        <ToggleRow label="Animations" sub="UI transitions & micro-interactions" value={animations} onChange={setAnimations} />
        <ToggleRow label="Scan Overlay" sub="BLE scan animation on discovery" value={scanOverlay} onChange={setScanOverlay} />
        <ToggleRow label="Reduced Motion" sub="Minimal motion for accessibility" value={reducedMotion} onChange={setReducedMotion} />
      </MeshCard>
    </ScreenWithHeader>
  );
}

function ToggleRow({ label, sub, value, onChange }: {
  label: string; sub: string; value: boolean; onChange: (v: boolean) => void;
}) {
  return (
    <View style={styles.toggleRow}>
      <View style={styles.toggleText}>
        <Text style={styles.toggleLabel}>{label}</Text>
        <Text style={styles.toggleSub}>{sub}</Text>
      </View>
      <Switch
        value={value}
        onValueChange={onChange}
        trackColor={{ false: DS.surface, true: DS.greenDim }}
        thumbColor={value ? DS.mauriGreen : DS.textSecondary}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  segment: {
    flexDirection: "row", backgroundColor: DS.surface, borderRadius: radius.md,
    padding: 4, gap: 4,
  },
  segBtn:       { flex: 1, paddingVertical: 10, borderRadius: radius.sm, alignItems: "center" },
  segBtnActive: { backgroundColor: DS.card, borderWidth: 1, borderColor: DS.greenBorder },
  segText:      { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.medium },
  segTextActive:{ color: DS.mauriGreen,   fontFamily: typography.fonts.bold },
  toggleRow:    { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingVertical: spacing.xs },
  toggleText:   { flex: 1, gap: 2 },
  toggleLabel:  { color: DS.textPrimary,   fontSize: typography.sizes.base, fontFamily: typography.fonts.medium  },
  toggleSub:    { color: DS.textSecondary, fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular },
});
