import React from "react";
import { View, Text } from "react-native";

export function MeshHeader({ title, subtitle }: { title?: string; subtitle?: string }) {
  return (
    <View style={{ paddingVertical: 12 }}>
      <Text style={{ fontSize: 26, fontWeight: "700" }}>{title || "MauriMesh"}</Text>
      {subtitle ? <Text>{subtitle}</Text> : null}
    </View>
  );
}

export default MeshHeader;
