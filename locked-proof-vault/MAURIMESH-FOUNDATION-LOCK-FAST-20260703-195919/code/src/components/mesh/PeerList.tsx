import React from "react";
import { View, Text } from "react-native";

export type Peer = {
  id: string;
  name?: string;
  rssi?: number;
  status?: string;
};

export function PeerList({ peers = [] }: { peers?: Peer[] }) {
  return (
    <View>
      {peers.map((p) => (
        <Text key={p.id}>{p.name || p.id} {p.status || ""}</Text>
      ))}
    </View>
  );
}

export default PeerList;
