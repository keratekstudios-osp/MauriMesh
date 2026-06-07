import { StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { radius } from "../../src/design-system/radius";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshStatusPill } from "../../src/components/ui/MeshStatusPill";

const RELAY_NODES = [
  { name: "Tama-Relay-3", forwarded: 42, dropped: 1, uptime: "18 h", quality: 97 },
  { name: "Rangi-Node-2", forwarded: 18, dropped: 3, uptime: "6 h",  quality: 81 },
];

export default function RelayAnalyticsScreen() {
  return (
    <ScreenWithHeader title="Relay Analytics" subtitle="Relay usage & throughput">
      <MeshCard title="Network Totals">
        <View style={styles.statsRow}>
          {[
            { label: "Relays",     value: "2",   color: DS.mauriGreen  },
            { label: "Forwarded",  value: "60",  color: DS.meshBlue    },
            { label: "Dropped",    value: "4",   color: DS.dangerRed   },
            { label: "Avg Uptime", value: "12h", color: DS.textPrimary },
          ].map(({ label, value, color }) => (
            <View key={label} style={styles.stat}>
              <Text style={[styles.statVal, { color }]}>{value}</Text>
              <Text style={styles.statLbl}>{label}</Text>
            </View>
          ))}
        </View>
      </MeshCard>

      <Text style={styles.sectionLabel}>ACTIVE RELAYS</Text>

      {RELAY_NODES.map((relay) => (
        <MeshCard key={relay.name} accentColor={DS.blueBorder}>
          <View style={styles.relayHeader}>
            <View style={styles.relayOrb}>
              <Text style={styles.relayOrbIcon}>↔</Text>
            </View>
            <View style={styles.relayMeta}>
              <Text style={styles.relayName}>{relay.name}</Text>
              <MeshStatusPill label="Active Relay" variant="online" />
            </View>
          </View>
          <View style={styles.relayStats}>
            {[
              { label: "Forwarded",   value: String(relay.forwarded), color: DS.mauriGreen  },
              { label: "Dropped",     value: String(relay.dropped),   color: DS.dangerRed   },
              { label: "Uptime",      value: relay.uptime,            color: DS.textPrimary },
              { label: "Quality",     value: `${relay.quality}%`,     color: relay.quality > 90 ? DS.mauriGreen : DS.warningAmber },
            ].map(({ label, value, color }) => (
              <View key={label} style={styles.relayStat}>
                <Text style={[styles.relayStatVal, { color }]}>{value}</Text>
                <Text style={styles.relayStatLbl}>{label}</Text>
              </View>
            ))}
          </View>
        </MeshCard>
      ))}
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  statsRow:      { flexDirection: "row", justifyContent: "space-around" },
  stat:          { alignItems: "center", gap: 2 },
  statVal:       { fontSize: typography.sizes.xl, fontFamily: typography.fonts.bold },
  statLbl:       { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular },
  sectionLabel:  { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.bold, letterSpacing: typography.tracking.wide },
  relayHeader:   { flexDirection: "row", alignItems: "center", gap: spacing.sm, marginBottom: spacing.sm },
  relayOrb:      { width: 40, height: 40, borderRadius: radius.full, backgroundColor: DS.blueDim, alignItems: "center", justifyContent: "center" },
  relayOrbIcon:  { fontSize: 20, color: DS.meshBlue },
  relayMeta:     { flex: 1, gap: 4 },
  relayName:     { color: DS.textPrimary, fontSize: typography.sizes.base, fontFamily: typography.fonts.semibold },
  relayStats:    { flexDirection: "row", justifyContent: "space-around", marginTop: spacing.sm },
  relayStat:     { alignItems: "center", gap: 2 },
  relayStatVal:  { fontSize: typography.sizes.md, fontFamily: typography.fonts.bold },
  relayStatLbl:  { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular },
});
