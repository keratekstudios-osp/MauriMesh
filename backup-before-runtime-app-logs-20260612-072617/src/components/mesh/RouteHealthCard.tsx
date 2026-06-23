import React from "react";
import { View, Text } from "react-native";

export type RouteHealth = {
  nodeId?: string;
  name?: string;
  latencyMs?: number;
  packetLoss?: number;
  hops?: number;
  rssi?: number;
};

export function RouteHealthCard({ route }: { route?: RouteHealth }) {
  return (
    <View style={{ padding: 12 }}>
      <Text>{route?.name || route?.nodeId || "Route"}</Text>
      <Text>Latency: {route?.latencyMs ?? 0}ms</Text>
      <Text>Hops: {route?.hops ?? 0}</Text>
    </View>
  );
}

export default RouteHealthCard;
