import React, { useEffect } from "react";
import { Stack } from "expo-router";
import { initRoutingConfig } from "../lib/lib/routingConfig";
import { markAppBoot } from "../src/maurimesh/runtime/runtimeLog";

markAppBoot("app/_layout.tsx");

export default function RootLayout() {
  useEffect(() => {
    // Apply the user's saved routing-sensitivity preset to the shared engine on
    // startup so the choice survives app restarts. Falls back to defaults.
    void initRoutingConfig();
  }, []);

  return (
    <Stack
      screenOptions={{
        headerShown: false,
        contentStyle: { backgroundColor: "#020617" },
      }}
    />
  );
}
