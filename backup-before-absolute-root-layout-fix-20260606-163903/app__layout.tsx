import React from "react";
import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";

/**
 * MauriMesh safe root layout.
 *
 * Purpose:
 * - Keep APK boot stable.
 * - Avoid startup side effects that can crash release builds.
 * - Do not call SplashScreen, useFonts, router methods, or undefined runtime helpers here.
 *
 * BLE, routing, proof ledger, and MauriMesh engine screens remain preserved in their own routes.
 */
export default function RootLayout() {
  return (
    <>
      <Stack
        screenOptions={{
          headerShown: false,
          animation: "fade",
          contentStyle: {
            backgroundColor: "#020617",
          },
        }}
      />
      <StatusBar style="light" />
    </>
  );
}
