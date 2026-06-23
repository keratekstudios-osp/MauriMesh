import React from "react";
import { SafeAreaView, View } from "react-native";

export default function ScreenShell({ children }: any) {
  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: "#000" }}>
      <View style={{ flex: 1 }}>
        {children}
      </View>
    </SafeAreaView>
  );
}
