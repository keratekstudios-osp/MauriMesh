import { useState } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { radius } from "../../src/design-system/radius";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";

const LANGUAGES = [
  { code: "en",    label: "English",         native: "English"    },
  { code: "mi",    label: "Te Reo Māori",    native: "Te Reo"     },
  { code: "es",    label: "Spanish",         native: "Español"    },
  { code: "fr",    label: "French",          native: "Français"   },
  { code: "de",    label: "German",          native: "Deutsch"    },
  { code: "zh",    label: "Chinese (Simplified)", native: "中文"   },
  { code: "ar",    label: "Arabic",          native: "العربية"    },
];

export default function LanguageScreen() {
  const [selected, setSelected] = useState("en");

  return (
    <ScreenWithHeader title="Language" subtitle="Display & interface language">
      <MeshCard title="Select Language">
        {LANGUAGES.map((lang) => {
          const active = selected === lang.code;
          return (
            <Pressable
              key={lang.code}
              onPress={() => setSelected(lang.code)}
              style={({ pressed }) => [
                styles.row,
                active && styles.rowActive,
                pressed && styles.rowPressed,
              ]}
            >
              <View style={styles.rowLeft}>
                <Text style={[styles.label, active && styles.labelActive]}>{lang.label}</Text>
                <Text style={styles.native}>{lang.native}</Text>
              </View>
              {active && <Text style={styles.check}>✓</Text>}
            </Pressable>
          );
        })}
      </MeshCard>
      <Text style={styles.note}>
        Language changes apply to the UI only. Message content is never altered.
      </Text>
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row", alignItems: "center", justifyContent: "space-between",
    paddingVertical: spacing.sm, borderBottomWidth: 1, borderBottomColor: DS.divider,
  },
  rowActive:  { borderBottomColor: DS.greenBorder },
  rowPressed: { opacity: 0.80 },
  rowLeft:    { gap: 2 },
  label:      { color: DS.textPrimary,   fontSize: typography.sizes.base, fontFamily: typography.fonts.medium   },
  labelActive:{ color: DS.mauriGreen,                                     fontFamily: typography.fonts.semibold },
  native:     { color: DS.textSecondary, fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular  },
  check:      { color: DS.mauriGreen,    fontSize: typography.sizes.lg,   fontFamily: typography.fonts.bold     },
  note:       { color: DS.mutedText, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, textAlign: "center", lineHeight: typography.sizes.xs * typography.lineHeight.relaxed },
});
