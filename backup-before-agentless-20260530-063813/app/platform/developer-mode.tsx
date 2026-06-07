import { useState } from "react";
import { StyleSheet, Switch, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { radius } from "../../src/design-system/radius";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";

const TOGGLES = [
  { id: "verbose-ble",  label: "Verbose BLE logging",  desc: "Log all advertising packets"            },
  { id: "mesh-debug",   label: "Mesh debug overlay",   desc: "Show route scores in UI"                },
  { id: "perf-trace",   label: "Performance tracing",  desc: "Trace render times and hook calls"      },
  { id: "crash-report", label: "Crash reporting",      desc: "Send anonymised crash logs to dev team" },
];

const LOG_LINES = [
  { text: "[14:32:01] BLE: adv-packet MM-7A3F rssi=-52",  hi: "green" as const },
  { text: "[14:32:02] MESH: route-update MM-7A3F hops=2", hi: "green" as const },
  { text: "[14:32:05] ACK: ack-recv 0xAF3B latency=12ms", hi: "green" as const },
  { text: "[14:32:10] WARN: queue-depth=12 threshold=10", hi: "warn"  as const },
  { text: "[14:32:15] ACK: retry 0xAF3C attempt=1",       hi: "muted" as const },
];

const HI_COLOR = { green: DS.mauriGreen, warn: DS.warningAmber, muted: DS.mutedText };

export default function DeveloperModeScreen() {
  const [toggles, setToggles] = useState<Record<string, boolean>>({
    "verbose-ble": true, "mesh-debug": false, "perf-trace": false, "crash-report": true,
  });

  function toggle(id: string) {
    setToggles((prev) => ({ ...prev, [id]: !prev[id] }));
  }

  return (
    <ScreenWithHeader title="Developer Mode" subtitle="Advanced diagnostics">
      <MeshCard title="Debug Toggles">
        {TOGGLES.map((t, i) => (
          <View key={t.id} style={[styles.row, i < TOGGLES.length - 1 && styles.rowBorder]}>
            <View style={styles.rowText}>
              <Text style={styles.label}>{t.label}</Text>
              <Text style={styles.desc}>{t.desc}</Text>
            </View>
            <Switch
              value={toggles[t.id]}
              onValueChange={() => toggle(t.id)}
              trackColor={{ false: DS.surface, true: DS.mauriGreen + "60" }}
              thumbColor={toggles[t.id] ? DS.mauriGreen : DS.textSecondary}
            />
          </View>
        ))}
      </MeshCard>

      <MeshCard title="Live Console">
        <View style={styles.console}>
          {LOG_LINES.map((line, i) => (
            <Text key={i} style={[styles.consoleLine, { color: HI_COLOR[line.hi] }]}>
              {line.text}
            </Text>
          ))}
        </View>
      </MeshCard>
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  row:         { flexDirection: "row", alignItems: "center", paddingVertical: spacing.xs, gap: spacing.sm },
  rowBorder:   { borderBottomWidth: 1, borderBottomColor: DS.divider },
  rowText:     { flex: 1 },
  label:       { fontSize: typography.sizes.base, fontFamily: typography.fonts.medium, color: DS.textPrimary, marginBottom: 2 },
  desc:        { fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular, color: DS.mutedText },
  console:     { backgroundColor: DS.deepSpace, borderRadius: radius.sm, padding: spacing.sm, gap: 4 },
  consoleLine: { fontSize: 10, fontFamily: typography.fonts.regular, lineHeight: 16 },
});
