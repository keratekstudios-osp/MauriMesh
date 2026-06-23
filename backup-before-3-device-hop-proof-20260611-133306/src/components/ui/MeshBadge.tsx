import React from "react";
import { Text, View } from "react-native";

export function MeshBadge({ label, children }: { label?: string; children?: React.ReactNode }) {
  return (
    <View>
      <Text>{label || children || "MESH"}</Text>
    </View>
  );
}

export default MeshBadge;
