import { useState } from "react";
import { StyleSheet, Switch, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshStatusPill } from "../../src/components/ui/MeshStatusPill";

const JOBS = [
  { id: "peer-list",   label: "Peer List Sync",    interval: "30 s",  lastRun: "Just now",  variant: "online"   as const },
  { id: "route-table", label: "Route Table Update", interval: "60 s",  lastRun: "1 min ago", variant: "online"   as const },
  { id: "key-refresh", label: "Key Refresh",        interval: "1 h",   lastRun: "42 min",    variant: "online"   as const },
  { id: "ota-check",   label: "OTA Check",          interval: "6 h",   lastRun: "3 h ago",   variant: "syncing"  as const },
  { id: "backup",      label: "Config Backup",      interval: "24 h",  lastRun: "Yesterday", variant: "offline"  as const },
];

const DEFAULTS: Record<string, boolean> = {
  "peer-list": true, "route-table": true, "key-refresh": true, "ota-check": true, backup: false,
};

export default function BackgroundSyncScreen() {
  const [enabled, setEnabled] = useState(DEFAULTS);

  function toggle(id: string) {
    setEnabled((prev) => ({ ...prev, [id]: !prev[id] }));
  }

  const active = Object.values(enabled).filter(Boolean).length;

  return (
    <ScreenWithHeader title="Background Sync" subtitle={`${active} jobs active`}>
      <MeshCard title="Sync Jobs">
        {JOBS.map((job, i) => (
          <View key={job.id} style={[styles.row, i < JOBS.length - 1 && styles.rowBorder]}>
            <MeshStatusPill label={enabled[job.id] ? job.variant : "offline"} variant={enabled[job.id] ? job.variant : "offline"} />
            <View style={styles.rowText}>
              <Text style={styles.label}>{job.label}</Text>
              <Text style={styles.meta}>every {job.interval} · last: {job.lastRun}</Text>
            </View>
            <Switch
              value={enabled[job.id]}
              onValueChange={() => toggle(job.id)}
              trackColor={{ false: DS.surface, true: DS.mauriGreen + "60" }}
              thumbColor={enabled[job.id] ? DS.mauriGreen : DS.textSecondary}
            />
          </View>
        ))}
      </MeshCard>
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  row:       { flexDirection: "row", alignItems: "center", paddingVertical: spacing.xs, gap: spacing.sm },
  rowBorder: { borderBottomWidth: 1, borderBottomColor: DS.divider },
  rowText:   { flex: 1 },
  label:     { fontSize: typography.sizes.base, fontFamily: typography.fonts.medium, color: DS.textPrimary, marginBottom: 2 },
  meta:      { fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, color: DS.mutedText },
});
