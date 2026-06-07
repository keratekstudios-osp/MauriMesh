import { useState } from "react";
import { Alert, StyleSheet, Text, View } from "react-native";
import * as Haptics from "expo-haptics";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshBadge } from "../../src/components/ui/MeshBadge";
import { MeshButton } from "../../src/components/ui/MeshButton";
import { QueueVisualizer, type QueueItem } from "../../src/components/mesh/QueueVisualizer";

const INITIAL_QUEUE: QueueItem[] = [
  { id: "q1", label: "MSG-001 → Kupe",      status: "acked",   hopCount: 2 },
  { id: "q2", label: "MSG-002 → Broadcast", status: "sending", hopCount: 1 },
  { id: "q3", label: "MSG-003 → Rangi",     status: "queued",  hopCount: 0 },
  { id: "q4", label: "MSG-004 → Tama",      status: "queued",  hopCount: 0 },
  { id: "q5", label: "MSG-005 → Hine",      status: "failed",  hopCount: 1 },
];

export default function StoreForwardQueueScreen() {
  const [queue, setQueue] = useState(INITIAL_QUEUE);

  const pending = queue.filter((q) => q.status === "queued" || q.status === "sending").length;
  const failed  = queue.filter((q) => q.status === "failed").length;

  function handleFlushPending() {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    if (pending === 0) {
      Alert.alert("Nothing to Flush", "There are no pending messages in the queue.");
      return;
    }
    Alert.alert(
      "Flush Pending",
      `Re-attempt delivery of ${pending} pending message${pending !== 1 ? "s" : ""} now?`,
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Flush",
          onPress: () => {
            setQueue((prev) =>
              prev.map((q) =>
                q.status === "queued" || q.status === "sending"
                  ? { ...q, status: "sending" as const }
                  : q,
              ),
            );
            setTimeout(() => {
              Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
              setQueue((prev) =>
                prev.map((q) =>
                  q.status === "sending" ? { ...q, status: "acked" as const, hopCount: (q.hopCount ?? 0) + 1 } : q,
                ),
              );
            }, 1500);
          },
        },
      ],
    );
  }

  function handleClearFailed() {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    if (failed === 0) {
      Alert.alert("Nothing to Clear", "There are no failed messages in the queue.");
      return;
    }
    Alert.alert(
      "Clear Failed",
      `Permanently remove ${failed} failed message${failed !== 1 ? "s" : ""} from the queue?`,
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Clear",
          style: "destructive",
          onPress: () => {
            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
            setQueue((prev) => prev.filter((q) => q.status !== "failed"));
          },
        },
      ],
    );
  }

  return (
    <ScreenWithHeader title="Store-Forward Queue" subtitle="Offline message relay">
      <MeshCard title="Queue Summary">
        <View style={styles.statsRow}>
          <QStat label="Total"   value={String(queue.length)} accent={DS.textPrimary}   />
          <QStat label="Pending" value={String(pending)}      accent={DS.warningAmber}  />
          <QStat label="Failed"  value={String(failed)}       accent={DS.dangerRed}     />
        </View>
      </MeshCard>

      <View style={styles.listHeader}>
        <Text style={styles.listTitle}>Message Queue</Text>
        <MeshBadge label={`${pending} pending`} variant="amber" />
      </View>

      <MeshCard>
        <QueueVisualizer items={queue} />
      </MeshCard>

      <View style={styles.actions}>
        <MeshButton label="Flush Pending" variant="secondary" onPress={handleFlushPending} />
        <MeshButton label="Clear Failed"  variant="danger"    onPress={handleClearFailed}  />
      </View>
    </ScreenWithHeader>
  );
}

function QStat({ label, value, accent }: { label: string; value: string; accent: string }) {
  return (
    <View style={styles.stat}>
      <Text style={[styles.statVal, { color: accent }]}>{value}</Text>
      <Text style={styles.statLbl}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  statsRow:   { flexDirection: "row", justifyContent: "space-around" },
  stat:       { alignItems: "center", gap: 2 },
  statVal:    { fontSize: typography.sizes.xl,   fontFamily: typography.fonts.bold    },
  statLbl:    { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular },
  listHeader: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  listTitle:  { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.bold, letterSpacing: typography.tracking.wide, textTransform: "uppercase" },
  actions:    { flexDirection: "row", gap: spacing.sm },
});
