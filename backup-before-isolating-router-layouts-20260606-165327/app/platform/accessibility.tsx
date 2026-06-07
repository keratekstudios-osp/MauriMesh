import { useState } from "react";
import { StyleSheet, Switch, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { radius } from "../../src/design-system/radius";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";

const OPTIONS = [
  { id: "high-contrast",  label: "High Contrast Mode",  desc: "Increase contrast for readability"         },
  { id: "reduced-motion", label: "Reduce Motion",        desc: "Disable animations and transitions"        },
  { id: "large-text",     label: "Large Text",           desc: "Increase global font size"                 },
  { id: "haptic",         label: "Haptic Feedback",      desc: "Vibration on key interactions"             },
  { id: "audio-alerts",   label: "Audio Alerts",         desc: "Sound cue on important mesh events"        },
  { id: "screen-reader",  label: "Screen Reader Hints",  desc: "Enhanced accessible labels"                },
];

const DEFAULTS: Record<string, boolean> = {
  "high-contrast": false, "reduced-motion": false, "large-text": false,
  haptic: true, "audio-alerts": false, "screen-reader": false,
};

export default function AccessibilityScreen() {
  const [opts, setOpts] = useState(DEFAULTS);

  function toggle(id: string) {
    setOpts((prev) => ({ ...prev, [id]: !prev[id] }));
  }

  return (
    <ScreenWithHeader title="Accessibility" subtitle="Display and input assistance">
      <MeshCard title="Accessibility Options">
        {OPTIONS.map((opt, i) => (
          <View key={opt.id} style={[styles.row, i < OPTIONS.length - 1 && styles.rowBorder]}>
            <View style={styles.rowText}>
              <Text style={styles.label}>{opt.label}</Text>
              <Text style={styles.desc}>{opt.desc}</Text>
            </View>
            <Switch
              value={opts[opt.id]}
              onValueChange={() => toggle(opt.id)}
              trackColor={{ false: DS.surface, true: DS.mauriGreen + "60" }}
              thumbColor={opts[opt.id] ? DS.mauriGreen : DS.textSecondary}
            />
          </View>
        ))}
      </MeshCard>

      <View style={styles.infoBox}>
        <Text style={styles.infoText}>
          ℹ MauriMesh targets WCAG 2.1 AA compliance. Minimum touch target: 44 × 44 pt.
        </Text>
      </View>
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  row:       { flexDirection: "row", alignItems: "center", paddingVertical: spacing.xs, gap: spacing.sm },
  rowBorder: { borderBottomWidth: 1, borderBottomColor: DS.divider },
  rowText:   { flex: 1 },
  label:     { fontSize: typography.sizes.base, fontFamily: typography.fonts.medium, color: DS.textPrimary, marginBottom: 2 },
  desc:      { fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular, color: DS.mutedText },
  infoBox:   { backgroundColor: DS.blueDim, borderWidth: 1, borderColor: DS.blueBorder, borderRadius: radius.lg, padding: spacing.md },
  infoText:  { fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, color: DS.meshBlue },
});
