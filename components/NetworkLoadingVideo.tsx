import React from "react";
import { ActivityIndicator, Text, View } from "react-native";

export function NetworkLoadingVideo({ connected }: { connected?: boolean }) {
  return (
    <View style={{ padding: 16, alignItems: "center", justifyContent: "center" }}>
      <ActivityIndicator />
      <Text>{connected ? "Connected" : "Connecting to MauriMesh..."}</Text>
    </View>
  );
}

export default NetworkLoadingVideo;
