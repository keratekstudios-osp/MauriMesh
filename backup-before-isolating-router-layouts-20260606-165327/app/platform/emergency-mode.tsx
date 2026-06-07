import { useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { radius } from "../../src/design-system/radius";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshButton } from "../../src/components/ui/MeshButton";

const LOG = [
  { ts: "14:00", event: "Emergency beacon received from MM-E5F2"      },
  { ts: "13:58", event: "Priority relay activated — all channels"      },
  { ts: "12:30", event: "Emergency mode deactivated after 4 h 32 m"   },
];

export default function EmergencyModeScreen() {
  const [active, setActive] = useState(false);

  return (
    <ScreenWithHeader title="Emergency Mode" subtitle="Mesh resilience and SOS protocols">
      <View style={[styles.sosBox, active && styles.sosBoxActive]}>
        <Text style={styles.sosIcon}>{active ? "🚨" : "⚠️"}</Text>
        <Text style={[styles.sosTitle, active && styles.sosTitleActive]}>
          {active ? "EMERGENCY MODE ACTIVE" : "Emergency Mode Standby"}
        </Text>
        <Text style={styles.sosDesc}>
          {active
            ? "SOS beacon broadcasting. Priority relay enabled for all nodes."
            : "Activating will broadcast a SOS beacon and enable priority relaying across all mesh nodes."}
        </Text>
        <MeshButton
          label={active ? "Deactivate" : "⚠ Activate Emergency Mode"}
          onPress={() => setActive((v) => !v)}
          variant={active ? "secondary" : "danger"}
          fullWidth
        />
      </View>

      <MeshCard title="Emergency Log">
        {LOG.map((l, i) => (
          <View key={i} style={[styles.logRow, i < LOG.length - 1 && styles.logBorder]}>
            <Text style={styles.logTs}>{l.ts}</Text>
            <Text style={styles.logEvent}>{l.event}</Text>
          </View>
        ))}
      </MeshCard>
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  sosBox:        { backgroundColor: DS.amberDim, borderWidth: 1, borderColor: DS.amberBorder, borderRadius: radius.xl, padding: spacing.lg, alignItems: "center", gap: spacing.sm },
  sosBoxActive:  { backgroundColor: DS.redDim, borderColor: DS.redBorder },
  sosIcon:       { fontSize: 36 },
  sosTitle:      { fontSize: typography.sizes.md, fontFamily: typography.fonts.bold, color: DS.warningAmber, textAlign: "center" },
  sosTitleActive:{ color: DS.dangerRed },
  sosDesc:       { fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular, color: DS.mutedText, textAlign: "center" },
  logRow:        { flexDirection: "row", gap: spacing.sm, paddingVertical: spacing.xs },
  logBorder:     { borderBottomWidth: 1, borderBottomColor: DS.divider },
  logTs:         { fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, color: DS.mutedText, width: 40 },
  logEvent:      { fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, color: DS.textPrimary, flex: 1 },
});
