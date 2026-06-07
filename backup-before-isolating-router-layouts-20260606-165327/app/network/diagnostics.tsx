import { StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshStatusPill } from "../../src/components/ui/MeshStatusPill";

const SYSTEM_ROWS = [
  { label: "Platform",       value: "React Native / Expo"  },
  { label: "OS",             value: "iOS 17.4"             },
  { label: "Architecture",   value: "arm64"                },
  { label: "App Version",    value: "1.4.2-alpha"          },
  { label: "Build",          value: "expo-49"              },
];

const BLE_ROWS = [
  { label: "BLE State",      value: "Powered On",    ok: true  },
  { label: "Advertising",    value: "Inactive",      ok: false },
  { label: "Scanning",       value: "Inactive",      ok: false },
  { label: "Connected Peers",value: "0",             ok: false },
  { label: "MTU",            value: "512 bytes",     ok: true  },
];

const MEM_ROWS = [
  { label: "JS Heap Used",   value: "18.4 MB" },
  { label: "JS Heap Limit",  value: "256 MB"  },
  { label: "Native Memory",  value: "62.1 MB" },
];

export default function DiagnosticsScreen() {
  return (
    <ScreenWithHeader title="Diagnostics" subtitle="System health & BLE state">
      <MeshCard title="System Info">
        {SYSTEM_ROWS.map(({ label, value }) => (
          <Row key={label} label={label} value={value} />
        ))}
      </MeshCard>

      <MeshCard title="BLE Stack">
        {BLE_ROWS.map(({ label, value, ok }) => (
          <View key={label} style={styles.row}>
            <Text style={styles.rowLabel}>{label}</Text>
            <View style={styles.rowRight}>
              <Text style={[styles.rowValue, { color: ok ? DS.mauriGreen : DS.warningAmber }]}>
                {value}
              </Text>
              <MeshStatusPill
                label={ok ? "OK" : "Idle"}
                variant={ok ? "online" : "warning"}
              />
            </View>
          </View>
        ))}
      </MeshCard>

      <MeshCard title="Memory">
        {MEM_ROWS.map(({ label, value }) => (
          <Row key={label} label={label} value={value} />
        ))}
      </MeshCard>
    </ScreenWithHeader>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.row}>
      <Text style={styles.rowLabel}>{label}</Text>
      <Text style={styles.rowValue}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  row:      { flexDirection: "row", justifyContent: "space-between", alignItems: "center", paddingVertical: 6 },
  rowRight: { flexDirection: "row", alignItems: "center", gap: spacing.xs },
  rowLabel: { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular },
  rowValue: { color: DS.textPrimary,   fontSize: typography.sizes.sm, fontFamily: typography.fonts.semibold },
});
