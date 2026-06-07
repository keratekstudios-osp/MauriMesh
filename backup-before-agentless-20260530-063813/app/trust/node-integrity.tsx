import { StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { radius } from "../../src/design-system/radius";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshStatusPill } from "../../src/components/ui/MeshStatusPill";
import { MeshBadge } from "../../src/components/ui/MeshBadge";

export default function NodeIntegrityScreen() {
  return (
    <ScreenWithHeader title="Node Integrity" subtitle="Node verification & signing">
      <MeshCard title="This Node" glow>
        <View style={styles.nodeHeader}>
          <View style={styles.nodeOrb}>
            <Text style={styles.nodeOrbIcon}>◉</Text>
          </View>
          <View style={styles.nodeMeta}>
            <Text style={styles.nodeName}>My-Node-1</Text>
            <Text style={styles.nodeId}>MM-SELF-001</Text>
            <View style={styles.nodeStatus}>
              <MeshStatusPill label="Verified" variant="online" />
              <MeshStatusPill label="Signing Active" variant="syncing" />
            </View>
          </View>
        </View>
        {[
          ["Public Key",   "ed25519:4Yz3...A8kP"],
          ["Key age",      "14 days"            ],
          ["Signed msgs",  "142"                ],
          ["Signature",    "secp256k1-SHA256"   ],
        ].map(([label, value]) => (
          <View key={label as string} style={styles.row}>
            <Text style={styles.rowLabel}>{label}</Text>
            <Text style={styles.rowValue}>{value}</Text>
          </View>
        ))}
      </MeshCard>

      <MeshCard title="Integrity Checks">
        {[
          { check: "Key Pair Valid",        pass: true  },
          { check: "Signature Verified",    pass: true  },
          { check: "Message Hashes Match",  pass: true  },
          { check: "Replay Protection",     pass: true  },
          { check: "Clock Drift < 60s",     pass: true  },
          { check: "Peer Cert Pinned",      pass: false },
        ].map(({ check, pass }) => (
          <View key={check} style={styles.checkRow}>
            <Text style={[styles.checkIcon, { color: pass ? DS.mauriGreen : DS.warningAmber }]}>
              {pass ? "✓" : "⚠"}
            </Text>
            <Text style={styles.checkLabel}>{check}</Text>
            <MeshStatusPill label={pass ? "Pass" : "Warn"} variant={pass ? "online" : "warning"} />
          </View>
        ))}
      </MeshCard>

      <MeshCard title="Peer Certificates">
        {[
          { name: "Kupe-Node-1",  verified: true  },
          { name: "Rangi-Node-2", verified: true  },
          { name: "Tama-Relay-3", verified: false },
        ].map(({ name, verified }) => (
          <View key={name} style={styles.certRow}>
            <Text style={styles.certName}>{name}</Text>
            <MeshBadge label={verified ? "Cert Pinned" : "Self-Signed"} variant={verified ? "green" : "amber"} />
          </View>
        ))}
      </MeshCard>
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  nodeHeader:    { flexDirection: "row", alignItems: "center", gap: spacing.md, marginBottom: spacing.md },
  nodeOrb:       { width: 56, height: 56, borderRadius: radius.full, backgroundColor: DS.greenDim, borderWidth: 2, borderColor: DS.greenBorderBright, alignItems: "center", justifyContent: "center", flexShrink: 0 },
  nodeOrbIcon:   { fontSize: 28, color: DS.mauriGreen },
  nodeMeta:      { flex: 1, gap: 4 },
  nodeName:      { color: DS.textPrimary,   fontSize: typography.sizes.lg,   fontFamily: typography.fonts.bold    },
  nodeId:        { color: DS.mutedText,     fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular  },
  nodeStatus:    { flexDirection: "row", gap: spacing.xs, flexWrap: "wrap" },
  row:           { flexDirection: "row", justifyContent: "space-between", paddingVertical: 6 },
  rowLabel:      { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular  },
  rowValue:      { color: DS.mauriGreen,    fontSize: typography.sizes.xs, fontFamily: typography.fonts.semibold },
  checkRow:      { flexDirection: "row", alignItems: "center", gap: spacing.sm, paddingVertical: 6 },
  checkIcon:     { fontSize: 16, fontFamily: typography.fonts.bold, width: 20, flexShrink: 0 },
  checkLabel:    { color: DS.textPrimary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular, flex: 1 },
  certRow:       { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingVertical: 6 },
  certName:      { color: DS.textPrimary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.medium },
});
