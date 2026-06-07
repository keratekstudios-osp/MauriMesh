import { useState } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { radius } from "../../src/design-system/radius";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";

interface Cat { id: string; label: string; used: number; total: number; purgeable: boolean; color: string; }

const INIT_CATS: Cat[] = [
  { id: "messages", label: "Message Store",   used: 128, total: 512,  purgeable: false, color: DS.mauriGreen },
  { id: "keys",     label: "Key Material",    used: 4,   total: 50,   purgeable: false, color: DS.meshBlue   },
  { id: "cache",    label: "Route Cache",     used: 47,  total: 100,  purgeable: true,  color: DS.warningAmber },
  { id: "media",    label: "Media Files",     used: 342, total: 1000, purgeable: true,  color: DS.mauriGreen },
  { id: "logs",     label: "Diagnostic Logs", used: 64,  total: 200,  purgeable: true,  color: DS.warningAmber },
];

const TOTAL = 2048;

export default function StorageManagementScreen() {
  const [cats, setCats] = useState<Cat[]>(INIT_CATS);
  const used = cats.reduce((s, c) => s + c.used, 0);
  const pct  = Math.round((used / TOTAL) * 100);

  function purge(id: string) {
    setCats((prev) => prev.map((c) => (c.id === id ? { ...c, used: 0 } : c)));
  }

  return (
    <ScreenWithHeader title="Storage" subtitle={`${used} MB / ${TOTAL} MB (${pct}%)`}>
      <MeshCard title="Usage Overview">
        <View style={styles.barTrack}>
          {cats.filter((c) => c.used > 0).map((c) => (
            <View
              key={c.id}
              style={[styles.barSegment, {
                width: `${Math.max(2, (c.used / TOTAL) * 100)}%` as `${number}%`,
                backgroundColor: c.color + "80",
              }]}
            />
          ))}
        </View>
        <Text style={styles.barLabel}>{TOTAL - used} MB free</Text>
      </MeshCard>

      <MeshCard title="Categories">
        {cats.map((cat, i) => (
          <View key={cat.id} style={[styles.row, i < cats.length - 1 && styles.rowBorder]}>
            <View style={styles.rowLeft}>
              <Text style={styles.catLabel}>{cat.label}</Text>
              <Text style={styles.catMeta}>{cat.used} / {cat.total} MB</Text>
              <View style={styles.progTrack}>
                <View style={[styles.progFill, {
                  width: `${Math.min(100, (cat.used / cat.total) * 100)}%` as `${number}%`,
                  backgroundColor: cat.color + "90",
                }]} />
              </View>
            </View>
            {cat.purgeable && cat.used > 0 && (
              <Pressable onPress={() => purge(cat.id)} style={styles.clearBtn}>
                <Text style={styles.clearText}>Clear</Text>
              </Pressable>
            )}
          </View>
        ))}
      </MeshCard>
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  barTrack:  { flexDirection: "row", height: 8, borderRadius: 4, overflow: "hidden", backgroundColor: DS.surface, marginBottom: spacing.xs },
  barSegment:{ height: "100%" },
  barLabel:  { fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, color: DS.mutedText, textAlign: "right" },
  row:       { paddingVertical: spacing.xs, flexDirection: "row", alignItems: "center", gap: spacing.sm },
  rowBorder: { borderBottomWidth: 1, borderBottomColor: DS.divider },
  rowLeft:   { flex: 1 },
  catLabel:  { fontSize: typography.sizes.base, fontFamily: typography.fonts.medium, color: DS.textPrimary },
  catMeta:   { fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, color: DS.mutedText, marginBottom: 4 },
  progTrack: { height: 4, backgroundColor: DS.surface, borderRadius: 2, overflow: "hidden" },
  progFill:  { height: "100%", borderRadius: 2 },
  clearBtn:  { paddingHorizontal: spacing.xs, paddingVertical: 4, backgroundColor: DS.redDim, borderRadius: radius.sm },
  clearText: { fontSize: typography.sizes.xs, fontFamily: typography.fonts.medium, color: DS.dangerRed },
});
