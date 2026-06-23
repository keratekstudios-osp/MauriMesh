import React from "react";
import { View, Text } from "react-native";

export function EmptyScreen({ title, message }: { title?: string; message?: string }) {
  return (
    <View style={{ flex: 1, alignItems: "center", justifyContent: "center", padding: 24 }}>
      <Text style={{ fontSize: 22, fontWeight: "700" }}>{title || "Empty"}</Text>
      <Text>{message || "No data yet"}</Text>
    </View>
  );
}

export default EmptyScreen;
