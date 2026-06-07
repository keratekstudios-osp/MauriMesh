import { StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { radius } from "../../src/design-system/radius";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshStatusPill } from "../../src/components/ui/MeshStatusPill";

type ConnStatus = "online" | "warning" | "offline";

const TRANSPORTS: {
  icon: string; name: string; detail: string; status: ConnStatus; latency?: string;
}[] = [
  { icon: "ᛒ", name: "BLE 5.0",      detail: "Short-range primary transport",    status: "warning", latency: "--"    },
  { icon: "⟡", name: "LoRa 915 MHz", detail: "Long-range fallback (no module)",   status: "offline"                  },
  { icon: "⌁", name: "Store-Forward", detail: "Queue active · 4 items pending",  status: "online",  latency: "N/A"   },
  { icon: "⊙", name: "Internet Bridge",detail: "Disabled in sovereign mode",      status: "offline"                  },
];

export default function ConnectivityScreen() {
  return (
    <ScreenWithHeader title="Connectivity" subtitle="Transport layer status">
      <MeshCard title="Transport Summary">
        <View style={styles.summary}>
          {([["Active", "1", DS.mauriGreen], ["Idle", "1", DS.warningAmber], ["Down", "2", DS.dangerRed]] as const).map(
            ([l, v, c]) => (
              <View key={l} style={styles.summStat}>
                <Text style={[styles.summVal, { color: c }]}>{v}</Text>
                <Text style={styles.summLabel}>{l}</Text>
              </View>
            )
          )}
        </View>
      </MeshCard>

      {TRANSPORTS.map((t) => (
        <View key={t.name} style={styles.card}>
          <View style={[styles.iconWrap, {
            backgroundColor: t.status === "online" ? DS.greenDim :
                             t.status === "warning" ? DS.amberDim : DS.redDim,
          }]}>
            <Text style={styles.icon}>{t.icon}</Text>
          </View>
          <View style={styles.meta}>
            <Text style={styles.name}>{t.name}</Text>
            <Text style={styles.detail}>{t.detail}</Text>
            {t.latency && (
              <Text style={styles.latency}>Latency: {t.latency}</Text>
            )}
          </View>
          <MeshStatusPill label={t.status === "online" ? "Active" : t.status === "warning" ? "Idle" : "Down"} variant={t.status} />
        </View>
      ))}
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  summary:    { flexDirection: "row", justifyContent: "space-around" },
  summStat:   { alignItems: "center", gap: 2 },
  summVal:    { fontSize: typography.sizes.xl, fontFamily: typography.fonts.bold },
  summLabel:  { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular },
  card: {
    flexDirection: "row", alignItems: "center", gap: spacing.sm,
    backgroundColor: DS.card, borderRadius: radius.lg, borderWidth: 1,
    borderColor: DS.divider, padding: spacing.md,
  },
  iconWrap:  { width: 44, height: 44, borderRadius: radius.sm, alignItems: "center", justifyContent: "center", flexShrink: 0 },
  icon:      { fontSize: 22 },
  meta:      { flex: 1, gap: 2 },
  name:      { color: DS.textPrimary,   fontSize: typography.sizes.base, fontFamily: typography.fonts.semibold },
  detail:    { color: DS.textSecondary, fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular  },
  latency:   { color: DS.mauriGreen,    fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular  },
});
