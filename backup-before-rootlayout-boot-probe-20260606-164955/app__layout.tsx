import React from "react";
import { Slot } from "expo-router";

/**
 * Absolute minimal MauriMesh root layout.
 *
 * No Stack.
 * No StatusBar.
 * No SplashScreen.
 * No fonts.
 * No effects.
 * No router calls.
 * No runtime engine startup.
 *
 * This isolates the APK crash so the app can boot first.
 */
export default function RootLayout() {
  return <Slot />;
}
