import React from "react";
import { View, Text } from "react-native";

export function ScreenWithHeader({ title, children }: { title?: string; children?: React.ReactNode }) {
  return (
    <View style={{ flex: 1, padding: 16 }}>
      {title ? <Text style={{ fontSize: 24, fontWeight: "700" }}>{title}</Text> : null}
      {children}
    </View>
  );
}

export default ScreenWithHeader;
