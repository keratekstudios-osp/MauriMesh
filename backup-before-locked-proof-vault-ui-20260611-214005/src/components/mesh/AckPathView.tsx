import React from "react";
import { View, Text } from "react-native";

export type AckNode = {
  id: string;
  label?: string;
  status?: string;
};

export function AckPathView({ nodes = [] }: { nodes?: AckNode[] }) {
  return (
    <View>
      {nodes.map((n) => (
        <Text key={n.id}>{n.label || n.id} {n.status || ""}</Text>
      ))}
    </View>
  );
}

export default AckPathView;
