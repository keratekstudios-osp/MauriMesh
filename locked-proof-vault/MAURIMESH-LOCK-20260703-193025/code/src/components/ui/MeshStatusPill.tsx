import React from "react";
import { Text } from "react-native";

export function MeshStatusPill({ label }: { label?: string }) {
  return <Text>{label || "ONLINE"}</Text>;
}

export default MeshStatusPill;
