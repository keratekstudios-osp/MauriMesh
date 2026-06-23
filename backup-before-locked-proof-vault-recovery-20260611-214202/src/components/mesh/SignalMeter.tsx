import React from "react";
import { View, Text } from "react-native";

export function rssiToBars(rssi?: number) {
  const v = typeof rssi === "number" ? rssi : 0;
  if (v >= 75) return 5;
  if (v >= 60) return 4;
  if (v >= 45) return 3;
  if (v >= 30) return 2;
  return 1;
}

export function SignalMeter({ rssi, value }: { rssi?: number; value?: number }) {
  const bars = rssiToBars(value ?? rssi);
  return (
    <View>
      <Text>Signal {bars}/5</Text>
    </View>
  );
}

export default SignalMeter;
