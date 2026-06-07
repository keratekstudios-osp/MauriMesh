import { useState } from "react";
import { Alert, StyleSheet, Switch, Text, View } from "react-native";
import * as Haptics from "expo-haptics";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { radius } from "../../src/design-system/radius";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshButton } from "../../src/components/ui/MeshButton";

type RetentionPeriod = "1h" | "24h" | "7d" | "forever";

export default function OfflineControlsScreen() {
  const [storeForward, setStoreForward] = useState(true);
  const [relayMode, setRelayMode]       = useState(true);
  const [compression, setCompression]   = useState(false);
  const [retention, setRetention]       = useState<RetentionPeriod>("24h");
  const [queueCount, setQueueCount]     = useState(4);
  const [flushing, setFlushing]         = useState(false);

  function handleFlushQueue() {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    Alert.alert(
      "Flush Queue",
      `Retry delivery of all ${queueCount} queued messages now?`,
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Flush Now",
          onPress: () => {
            setFlushing(true);
            setTimeout(() => {
              setQueueCount(0);
              setFlushing(false);
              Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
              Alert.alert("Queue Flushed", "All pending messages have been re-queued for delivery.");
            }, 1200);
          },
        },
      ],
    );
  }

  return (
    <ScreenWithHeader title="Offline Controls" subtitle="Store-forward & queue management">
      <MeshCard title="Store-Forward">
        <Toggle label="Enable Store-Forward"   sub="Queue messages for offline peers"          value={storeForward} onChange={setStoreForward} />
        <Toggle label="Relay Mode"             sub="Forward messages on behalf of peers"       value={relayMode}    onChange={setRelayMode}    />
        <Toggle label="Payload Compression"    sub="Reduce packet size (experimental)"         value={compression}  onChange={setCompression}  />
      </MeshCard>

      <MeshCard title="Queue Status">
        {[
          ["Queued items",   String(queueCount)],
          ["Max queue size", "512"             ],
          ["Queue usage",    queueCount === 0 ? "0%" : `${((queueCount / 512) * 100).toFixed(1)}%`],
        ].map(([label, value]) => (
          <View key={label as string} style={styles.row}>
            <Text style={styles.rowLabel}>{label}</Text>
            <Text style={styles.rowValue}>{value}</Text>
          </View>
        ))}
        <MeshButton
          label={flushing ? "Flushing…" : "Flush Queue Now"}
          variant="secondary"
          onPress={handleFlushQueue}
          fullWidth
          style={{ marginTop: spacing.sm }}
        />
      </MeshCard>

      <MeshCard title="Message Retention">
        <Text style={styles.hint}>Auto-expire queued messages after:</Text>
        <View style={styles.options}>
          {(["1h", "24h", "7d", "forever"] as RetentionPeriod[]).map((r) => (
            <View
              key={r}
              style={[styles.option, retention === r && styles.optionActive]}
            >
              <Text
                onPress={() => { Haptics.selectionAsync(); setRetention(r); }}
                style={[styles.optionText, retention === r && styles.optionTextActive]}
              >
                {r === "forever" ? "∞" : r}
              </Text>
            </View>
          ))}
        </View>
      </MeshCard>
    </ScreenWithHeader>
  );
}

function Toggle({ label, sub, value, onChange }: { label: string; sub: string; value: boolean; onChange: (v: boolean) => void }) {
  return (
    <View style={styles.toggle}>
      <View style={styles.toggleText}>
        <Text style={styles.toggleLabel}>{label}</Text>
        <Text style={styles.toggleSub}>{sub}</Text>
      </View>
      <Switch
        value={value}
        onValueChange={(v) => { Haptics.selectionAsync(); onChange(v); }}
        trackColor={{ false: DS.surface, true: DS.greenDim }}
        thumbColor={value ? DS.mauriGreen : DS.textSecondary}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  row:              { flexDirection: "row", justifyContent: "space-between", paddingVertical: 6 },
  rowLabel:         { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular  },
  rowValue:         { color: DS.textPrimary,   fontSize: typography.sizes.sm, fontFamily: typography.fonts.semibold },
  toggle:           { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingVertical: spacing.xs },
  toggleText:       { flex: 1, gap: 2 },
  toggleLabel:      { color: DS.textPrimary,   fontSize: typography.sizes.base, fontFamily: typography.fonts.medium  },
  toggleSub:        { color: DS.textSecondary, fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular },
  hint:             { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, marginBottom: spacing.sm },
  options:          { flexDirection: "row", gap: spacing.xs },
  option:           { flex: 1, paddingVertical: spacing.sm, borderRadius: radius.md, backgroundColor: DS.surface, borderWidth: 1, borderColor: DS.divider, alignItems: "center" },
  optionActive:     { backgroundColor: DS.greenDim, borderColor: DS.greenBorder },
  optionText:       { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.medium   },
  optionTextActive: { color: DS.mauriGreen,    fontFamily: typography.fonts.bold },
});
