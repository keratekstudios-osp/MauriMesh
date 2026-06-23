import React from "react";
import { View, Text } from "react-native";

export function RouteBeam({ label }: { label?: string }) {
  return (
    <View>
      <Text>{label || "Route Beam"}</Text>
    </View>
  );
}

export default RouteBeam;
