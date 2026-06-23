import { useRouter } from "expo-router";
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";
import { MauriPanel } from "../src/components/MauriPanel";

export default function LoginScreen() {
  const router = useRouter();

  return (
    <AppShell scroll={false}>
      <View style={styles.hero}>
        <StatusPill label="MAURIMESH MESSENGER" tone="success" />
        <Text style={styles.title}>MauriMesh</Text>
        <Text style={styles.tagline}>Messenger</Text>
        <Text style={styles.subtitle}>
          Secure mesh communication prepared for offline routing, relay logic,
          living governance, and future native device proof.
        </Text>
      </View>

      <MauriPanel glow>
        <Text style={styles.cardTitle}>Enter Network</Text>
        <Text style={styles.cardText}>
          UI, navigation, API fallback, backup route wiring, and simulation views are ready.
          Real BLE proof still requires APK on physical phones.
        </Text>
        <MauriButton title="Open Dashboard" onPress={() => router.replace("/dashboard")} />
      </MauriPanel>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  hero: {
    flex: 1,
    justifyContent: "center",
    gap: mauriTheme.spacing.md,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: mauriTheme.typography.hero,
    lineHeight: 58,
    fontWeight: "900",
    letterSpacing: -1.7,
  },
  tagline: {
    color: mauriTheme.colors.greenstone,
    fontSize: 29,
    fontWeight: "900",
    letterSpacing: 2,
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 16,
    lineHeight: 24,
  },
  cardTitle: {
    color: mauriTheme.colors.white,
    fontSize: 23,
    fontWeight: "900",
  },
  cardText: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
});
