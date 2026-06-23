import React from "react";
import { View, Text } from "react-native";

export type NodeStatus = "online" | "offline" | "relay" | "unknown";

export type MeshNode = {
  id: string;
  name?: string;
  status?: NodeStatus;
  rssi?: number;
};

export function NodeCard({ node }: { node?: MeshNode }) {
  return (
    <View style={{ padding: 12 }}>
      <Text>{node?.name || node?.id || "Node"}</Text>
      <Text>{node?.status || "unknown"}</Text>
    </View>
  );
}

export default NodeCard;
