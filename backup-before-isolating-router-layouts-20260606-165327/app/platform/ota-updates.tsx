import { useState } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { radius } from "../../src/design-system/radius";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshStatusPill } from "../../src/components/ui/MeshStatusPill";

interface Release { version: string; type: string; size: string; notes: string; critical: boolean; status: "available" | "installed"; }

const RELEASES: Release[] = [
  { version: "v1.4.3",       type: "App",      size: "4.2 MB", notes: "ACK timing + UI fixes",                critical: false, status: "available" },
  { version: "v1.4.2-sec1",  type: "Security", size: "1.1 MB", notes: "CVE patch: key exchange side-channel", critical: true,  status: "available" },
  { version: "BLE-fw-3.2.1", type: "Firmware", size: "512 KB", notes: "BLE 5.2 advertising improvements",     critical: false, status: "installed" },
];

export default function OtaUpdatesScreen() {
  const [releases, setReleases] = useState<Release[]>(RELEASES);

  function install(version: string) {
    setReleases((prev) => prev.map((r) => (r.version === version ? { ...r, status: "installed" as const } : r)));
  }

  const available = releases.filter((r) => r.status === "available").length;

  return (
    <ScreenWithHeader title="OTA Updates" subtitle={`${available} update${available !== 1 ? "s" : ""} available`}>
      <MeshCard title="Releases">
        {releases.map((rel, i) => (
          <View key={rel.version} style={[styles.row, i < releases.length - 1 && styles.rowBorder]}>
            <View style={styles.rowLeft}>
              <View style={styles.headerRow}>
                <Text style={styles.version}>{rel.version}</Text>
                <MeshStatusPill
                  label={rel.status === "installed" ? "Installed" : rel.critical ? "Critical" : rel.type}
                  variant={rel.status === "installed" ? "online" : rel.critical ? "error" : "syncing"}
                />
              </View>
              <Text style={styles.notes}>{rel.notes}</Text>
              <Text style={styles.meta}>{rel.size} · {rel.type}</Text>
            </View>
            {rel.status === "available" && (
              <Pressable onPress={() => install(rel.version)} style={styles.installBtn}>
                <Text style={styles.installText}>Install</Text>
              </Pressable>
            )}
          </View>
        ))}
      </MeshCard>
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  row:        { paddingVertical: spacing.xs, flexDirection: "row", gap: spacing.sm, alignItems: "center" },
  rowBorder:  { borderBottomWidth: 1, borderBottomColor: DS.divider },
  rowLeft:    { flex: 1 },
  headerRow:  { flexDirection: "row", alignItems: "center", gap: spacing.sm, marginBottom: 4 },
  version:    { fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular, color: DS.textPrimary },
  notes:      { fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, color: DS.textPrimary },
  meta:       { fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, color: DS.mutedText, marginTop: 2 },
  installBtn: { backgroundColor: DS.greenDim, borderWidth: 1, borderColor: DS.greenBorder, borderRadius: radius.sm, paddingHorizontal: spacing.xs, paddingVertical: 4 },
  installText:{ fontSize: typography.sizes.xs, fontFamily: typography.fonts.medium, color: DS.mauriGreen },
});
