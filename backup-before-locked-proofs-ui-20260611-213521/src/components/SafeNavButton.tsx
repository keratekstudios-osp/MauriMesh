import React from "react";
import { useRouter } from "expo-router";
import { Alert } from "react-native";
import { MauriButton } from "./MauriButton";
import { getUiRoute, UiRouteKey } from "../lib/uiBackupRoutes";

export function SafeNavButton({
  routeKey,
  variant = "primary",
}: {
  routeKey: UiRouteKey;
  variant?: "primary" | "secondary" | "danger";
}) {
  const router = useRouter();
  const target = getUiRoute(routeKey);

  function go() {
    try {
      router.push(target.route as never);
    } catch (error) {
      try {
        router.replace(target.fallbackRoute as never);
      } catch {
        Alert.alert(
          "Navigation fallback failed",
          `Could not open ${target.title}. Fallback route: ${target.fallbackRoute}`
        );
      }
    }
  }

  return <MauriButton title={target.title} variant={variant} onPress={go} />;
}
