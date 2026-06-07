import { useState } from "react";
import { StyleSheet, Switch, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";

interface NotifItem {
  key:    string;
  label:  string;
  sub:    string;
}

const NOTIF_GROUPS = [
  {
    title: "Messages",
    items: [
      { key: "msg_new",      label: "New Messages",        sub: "Alert when a message arrives"        },
      { key: "msg_deliver",  label: "Delivery Receipts",   sub: "Confirm when messages are delivered" },
    ] as NotifItem[],
  },
  {
    title: "Mesh Events",
    items: [
      { key: "relay_found",  label: "Relay Node Detected", sub: "New relay node in range"             },
      { key: "peer_joined",  label: "Peer Joined Mesh",    sub: "A trusted peer connects"             },
      { key: "peer_lost",    label: "Peer Lost Signal",    sub: "Peer drops out of range"             },
    ] as NotifItem[],
  },
  {
    title: "Security",
    items: [
      { key: "sec_alert",    label: "Security Alerts",     sub: "Untrusted node or intrusion"         },
      { key: "sec_sync",     label: "Trust Sync",          sub: "Trust engine synchronised"           },
    ] as NotifItem[],
  },
];

export default function NotificationsScreen() {
  const initialState = Object.fromEntries(
    NOTIF_GROUPS.flatMap((g) => g.items.map((i) => [i.key, true]))
  );
  const [state, setState] = useState<Record<string, boolean>>(initialState);

  function toggle(key: string) {
    setState((s) => ({ ...s, [key]: !s[key] }));
  }

  return (
    <ScreenWithHeader title="Notifications" subtitle="Message & relay alert preferences">
      {NOTIF_GROUPS.map((group) => (
        <MeshCard key={group.title} title={group.title}>
          {group.items.map((item) => (
            <View key={item.key} style={styles.row}>
              <View style={styles.text}>
                <Text style={styles.label}>{item.label}</Text>
                <Text style={styles.sub}>{item.sub}</Text>
              </View>
              <Switch
                value={state[item.key]}
                onValueChange={() => toggle(item.key)}
                trackColor={{ false: DS.surface, true: DS.greenDim }}
                thumbColor={state[item.key] ? DS.mauriGreen : DS.textSecondary}
              />
            </View>
          ))}
        </MeshCard>
      ))}
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  row:   { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingVertical: spacing.xs },
  text:  { flex: 1, gap: 2 },
  label: { color: DS.textPrimary,   fontSize: typography.sizes.base, fontFamily: typography.fonts.medium  },
  sub:   { color: DS.textSecondary, fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular },
});
