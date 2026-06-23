import React from "react";
import { View } from "react-native";

export function MeshCard({ children }: { children?: React.ReactNode }) {
  return <View style={{ padding: 16, borderRadius: 16 }}>{children}</View>;
}

export default MeshCard;
