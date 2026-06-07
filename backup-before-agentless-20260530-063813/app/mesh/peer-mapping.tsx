import { StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshBadge } from "../../src/components/ui/MeshBadge";
import { PeerList } from "../../src/components/mesh/PeerList";
import { type Peer } from "../../src/components/mesh/PeerList";
import { EmptyScreen } from "../../src/components/system/EmptyScreen";

const PEERS: Peer[] = [
  { id: "MM-7A3F", name: "Kupe-Node-1",  status: "online",  rssi: -52, hops: 1, lastSeen: "just now"   },
  { id: "MM-2D9E", name: "Rangi-Node-2", status: "online",  rssi: -71, hops: 2, lastSeen: "30 s ago"   },
  { id: "MM-B1C4", name: "Tama-Relay-3", status: "syncing", rssi: -84, hops: 2, lastSeen: "1 min ago"  },
  { id: "MM-E5F2", name: "Hine-Node-4",  status: "offline",             hops: 3, lastSeen: "5 min ago" },
];

export default function PeerMappingScreen() {
  if (PEERS.length === 0) {
    return (
      <EmptyScreen
        icon="◌"
        title="No Peers Mapped"
        message="Start a BLE scan to discover nearby mesh nodes. They will appear here once connected."
      />
    );
  }

  return (
    <ScreenWithHeader title="Peer Mapping" subtitle="Connected mesh nodes">
      <MeshCard title="Mesh Summary">
        <View style={styles.stats}>
          <Stat label="Online"  value="2" accent={DS.mauriGreen}   />
          <Stat label="Syncing" value="1" accent={DS.warningAmber} />
          <Stat label="Offline" value="1" accent={DS.textSecondary}/>
          <Stat label="Max Hop" value="3" accent={DS.meshBlue}      />
        </View>
      </MeshCard>

      <View style={styles.listHeader}>
        <Text style={styles.listTitle}>All Peers</Text>
        <MeshBadge label={`${PEERS.length} nodes`} variant="blue" />
      </View>

      <PeerList peers={PEERS} />
    </ScreenWithHeader>
  );
}

function Stat({ label, value, accent }: { label: string; value: string; accent: string }) {
  return (
    <View style={styles.stat}>
      <Text style={[styles.statValue, { color: accent }]}>{value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  stats:      { flexDirection: "row", justifyContent: "space-around" },
  stat:       { alignItems: "center", gap: 2 },
  statValue:  { fontSize: typography.sizes.xl, fontFamily: typography.fonts.bold },
  statLabel:  { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular },
  listHeader: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  listTitle:  { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.bold, letterSpacing: typography.tracking.wide, textTransform: "uppercase" },
});
