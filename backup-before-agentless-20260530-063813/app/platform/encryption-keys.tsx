import { StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { radius } from "../../src/design-system/radius";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshStatusPill } from "../../src/components/ui/MeshStatusPill";

const KEYS = [
  { label: "Node Identity Key",   algo: "Ed25519", fp: "7A3F:2E1B:9C4D:F5A8", variant: "online"   as const, expires: "No expiry"         },
  { label: "Session Encrypt Key", algo: "X25519",  fp: "B2C4:5D6E:F7G8:9H0I", variant: "syncing"  as const, expires: "Expires 2026-06-01" },
  { label: "Message Signing Key", algo: "Ed25519", fp: "J1K2:3L4M:5N6O:7P8Q", variant: "warning"  as const, expires: "Expires 2026-06-01 ⚠" },
];

const POLICY = [
  { label: "Algorithm",         value: "TweetNaCl v1.0.3"  },
  { label: "Session rotation",  value: "30 days"           },
  { label: "Key storage",       value: "Encrypted on-device" },
];

export default function EncryptionKeysScreen() {
  return (
    <ScreenWithHeader title="Encryption Keys" subtitle="TweetNaCl key lifecycle">
      <MeshCard title="Key Registry">
        {KEYS.map((k, i) => (
          <View key={k.label} style={[styles.keyRow, i < KEYS.length - 1 && styles.border]}>
            <View style={styles.keyHeader}>
              <Text style={styles.keyLabel}>{k.label}</Text>
              <MeshStatusPill label={k.algo} variant={k.variant} />
            </View>
            <Text style={styles.fp}>{k.fp}</Text>
            <Text style={styles.meta}>{k.expires}</Text>
          </View>
        ))}
      </MeshCard>

      <View style={styles.warnBox}>
        <Text style={styles.warnText}>
          ⚠ 1 key expires in &lt;30 days. Schedule rotation to avoid decryption failures.
        </Text>
      </View>

      <MeshCard title="Policy">
        {POLICY.map(({ label, value }) => (
          <View key={label} style={styles.policyRow}>
            <Text style={styles.policyLabel}>{label}</Text>
            <Text style={styles.policyValue}>{value}</Text>
          </View>
        ))}
      </MeshCard>
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  keyRow:      { paddingVertical: spacing.xs },
  border:      { borderBottomWidth: 1, borderBottomColor: DS.divider, marginBottom: spacing.xs },
  keyHeader:   { flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 4 },
  keyLabel:    { fontSize: typography.sizes.base, fontFamily: typography.fonts.medium, color: DS.textPrimary },
  fp:          { fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, color: DS.meshBlue, letterSpacing: 1 },
  meta:        { fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, color: DS.mutedText, marginTop: 2 },
  warnBox:     { backgroundColor: DS.amberDim, borderWidth: 1, borderColor: DS.amberBorder, borderRadius: radius.lg, padding: spacing.md },
  warnText:    { fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, color: DS.warningAmber },
  policyRow:   { flexDirection: "row", justifyContent: "space-between", paddingVertical: spacing.xs, borderBottomWidth: 1, borderBottomColor: DS.divider },
  policyLabel: { fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, color: DS.mutedText },
  policyValue: { fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, color: DS.textPrimary },
});
