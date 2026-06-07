import { useState } from "react";
import { StyleSheet, Switch, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { radius } from "../../src/design-system/radius";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";

const CHANNELS = [
  { id: "mesh-alert",  label: "Mesh Alerts",      desc: "Node join/leave, route changes"    },
  { id: "message",     label: "New Messages",      desc: "Incoming peer-to-peer messages"    },
  { id: "ack-fail",    label: "ACK Failures",      desc: "Unacknowledged message timeouts"   },
  { id: "emergency",   label: "Emergency Beacons", desc: "Priority broadcast signals"        },
  { id: "ota",         label: "OTA Updates",       desc: "Firmware and app update notices"   },
];

const DEFAULTS: Record<string, boolean> = {
  "mesh-alert": true, message: true, "ack-fail": true, emergency: true, ota: false,
};

export default function PushNotificationsScreen() {
  const [channels, setChannels] = useState(DEFAULTS);

  function toggle(id: string) {
    setChannels((prev) => ({ ...prev, [id]: !prev[id] }));
  }

  return (
    <ScreenWithHeader title="Push Notifications" subtitle="Notification channel settings">
      <MeshCard title="Channels">
        {CHANNELS.map((ch, i) => (
          <View key={ch.id} style={[styles.row, i < CHANNELS.length - 1 && styles.rowBorder]}>
            <View style={styles.rowText}>
              <Text style={styles.label}>{ch.label}</Text>
              <Text style={styles.desc}>{ch.desc}</Text>
            </View>
            <Switch
              value={channels[ch.id]}
              onValueChange={() => toggle(ch.id)}
              trackColor={{ false: DS.card, true: DS.mauriGreen + "60" }}
              thumbColor={channels[ch.id] ? DS.mauriGreen : DS.textSecondary}
            />
          </View>
        ))}
      </MeshCard>

      <View style={styles.infoBox}>
        <Text style={styles.infoText}>
          ℹ Push notifications are relayed via the mesh — no internet required for in-network alerts.
        </Text>
      </View>
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  row:       { flexDirection: "row", alignItems: "center", paddingVertical: spacing.xs, gap: spacing.sm },
  rowBorder: { borderBottomWidth: 1, borderBottomColor: DS.divider },
  rowText:   { flex: 1 },
  label:     { fontSize: typography.sizes.base, fontFamily: typography.fonts.medium, color: DS.textPrimary, marginBottom: 2 },
  desc:      { fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular, color: DS.mutedText },
  infoBox:   { backgroundColor: DS.blueDim, borderWidth: 1, borderColor: DS.blueBorder, borderRadius: radius.lg, padding: spacing.md },
  infoText:  { fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, color: DS.meshBlue },
});
