import { useState } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { radius } from "../../src/design-system/radius";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshButton } from "../../src/components/ui/MeshButton";

const BACKUPS = [
  { id: "bk-001", label: "Full config + key store",   size: "1.4 MB", ts: "14:00 today"   },
  { id: "bk-002", label: "Message archive (30 days)", size: "8.2 MB", ts: "09:00 yesterday"},
  { id: "bk-003", label: "Mesh topology snapshot",    size: "0.3 MB", ts: "2 days ago"     },
];

const FORMATS = ["MauriMesh Bundle (.mmb)", "JSON (.json)", "Encrypted ZIP (.zip)"];

export default function ExportBackupScreen() {
  const [format, setFormat]     = useState(FORMATS[0]);
  const [exporting, setExporting] = useState(false);
  const [done, setDone]           = useState(false);

  function doExport() {
    setExporting(true);
    setDone(false);
    setTimeout(() => { setExporting(false); setDone(true); }, 1800);
  }

  return (
    <ScreenWithHeader title="Export / Backup" subtitle="Config, messages, topology">
      <MeshCard title="Export">
        <Text style={styles.label}>Format</Text>
        {FORMATS.map((f) => (
          <Pressable
            key={f}
            onPress={() => setFormat(f)}
            style={[styles.fmtBtn, f === format && styles.fmtBtnActive]}
          >
            <Text style={[styles.fmtText, f === format && styles.fmtTextActive]}>{f}</Text>
          </Pressable>
        ))}
        <MeshButton
          label={exporting ? "Packaging…" : "Export Now"}
          onPress={doExport}
          variant="primary"
          fullWidth
        />
        {done && (
          <Text style={styles.doneText}>✓ Export saved to device Downloads</Text>
        )}
      </MeshCard>

      <MeshCard title="Import / Restore">
        <Text style={styles.bodyText}>
          Restore a previous MauriMesh bundle (.mmb) or JSON export. Existing messages are not overwritten.
        </Text>
        <MeshButton label="Choose File (drag & drop)" onPress={() => {}} variant="secondary" fullWidth />
        <Text style={styles.hint}>Supported: .mmb, .json, .zip — max 50 MB</Text>
      </MeshCard>

      <MeshCard title="Backup History">
        {BACKUPS.map((bk, i) => (
          <View key={bk.id} style={[styles.bkRow, i < BACKUPS.length - 1 && styles.bkBorder]}>
            <View style={styles.bkLeft}>
              <Text style={styles.bkLabel}>{bk.label}</Text>
              <Text style={styles.bkMeta}>{bk.ts} · {bk.size}</Text>
            </View>
            <View style={styles.dlBtn}>
              <Text style={styles.dlText}>↓</Text>
            </View>
          </View>
        ))}
      </MeshCard>
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  label:       { fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, color: DS.mutedText, marginBottom: spacing.xs },
  fmtBtn:      { borderWidth: 1, borderColor: DS.divider, borderRadius: radius.sm, paddingHorizontal: spacing.sm, paddingVertical: 6, marginBottom: 4 },
  fmtBtnActive:{ borderColor: DS.greenBorder, backgroundColor: DS.greenDim },
  fmtText:     { fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, color: DS.mutedText },
  fmtTextActive:{ color: DS.mauriGreen },
  doneText:    { fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, color: DS.mauriGreen, marginTop: spacing.xs },
  bodyText:    { fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular, color: DS.textSecondary, marginBottom: spacing.sm },
  hint:        { fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, color: DS.mutedText, marginTop: spacing.xs },
  bkRow:       { flexDirection: "row", alignItems: "center", paddingVertical: spacing.xs, gap: spacing.sm },
  bkBorder:    { borderBottomWidth: 1, borderBottomColor: DS.divider },
  bkLeft:      { flex: 1 },
  bkLabel:     { fontSize: typography.sizes.sm, fontFamily: typography.fonts.medium, color: DS.textPrimary },
  bkMeta:      { fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, color: DS.mutedText, marginTop: 2 },
  dlBtn:       { width: 28, height: 28, borderRadius: radius.sm, backgroundColor: DS.greenDim, alignItems: "center", justifyContent: "center" },
  dlText:      { fontSize: 14, color: DS.mauriGreen },
});
