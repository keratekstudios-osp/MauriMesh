import React from "react";
import { View, Text } from "react-native";

export function ComingSoonScreen({ screenName }: { screenName?: string }) {
  return (
    <View style={{ flex: 1, alignItems: "center", justifyContent: "center", padding: 24 }}>
      <Text style={{ fontSize: 24, fontWeight: "700" }}>
        {screenName || "Screen"}
      </Text>
      <Text>Coming soon</Text>
    </View>
  );
}

export default ComingSoonScreen;
