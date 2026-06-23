import React from "react";
import { View, Text } from "react-native";

export type QueueItem = {
  id: string;
  label?: string;
  status?: string;
  hopCount?: number;
};

export function QueueVisualizer({ items = [] }: { items?: QueueItem[] }) {
  return (
    <View>
      {items.map((item) => (
        <Text key={item.id}>{item.label || item.id} {item.status || ""}</Text>
      ))}
    </View>
  );
}

export default QueueVisualizer;
