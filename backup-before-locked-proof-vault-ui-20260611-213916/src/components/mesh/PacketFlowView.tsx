import React from "react";
import { View, Text } from "react-native";

export type Packet = {
  id: string;
  status?: string;
  hopCount?: number;
  label?: string;
};

export function PacketFlowView({ packets = [] }: { packets?: Packet[] }) {
  return (
    <View>
      {packets.map((p) => (
        <Text key={p.id}>{p.label || p.id} {p.status || ""}</Text>
      ))}
    </View>
  );
}

export default PacketFlowView;
