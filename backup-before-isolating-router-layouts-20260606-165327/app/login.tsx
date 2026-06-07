import { useRouter } from "expo-router";
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function LoginScreen() {
  const router = useRouter();

  return (
    <AppShell scroll={false}>
      <View style={styles.hero}>
        <StatusPill label="MAURIMESH MESSENGER" tone="success" />
        <Text style={styles.title}>MauriMesh</Text>
        <Text style={styles.tagline}>Messenger</Text>
        <Text style={styles.subtitle}>
          Secure mesh communication prepared for offline routing, relay logic, and future native device proof.
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Enter Network</Text>
        <Text style={styles.cardText}>
          Replit preview supports UI, navigation, API fallback, and simulation. Real BLE proof requires APK on physical phones.
        </Text>
        <MauriButton title="Open Dashboard" onPress={() => router.replace("/dashboard")} />
      </View>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  hero: { flex: 1, justifyContent: "center", gap: mauriTheme.spacing.md },
  title: { color: mauriTheme.colors.white, fontSize: 54, lineHeight: 58, fontWeight: "900", letterSpacing: -1.5 },
  tagline: { color: mauriTheme.colors.greenstone, fontSize: 28, fontWeight: "900", letterSpacing: 2 },
  subtitle: { color: mauriTheme.colors.mutedWhite, fontSize: 16, lineHeight: 24 },
  card: { borderRadius: mauriTheme.radius.xl, borderWidth: 1, borderColor: mauriTheme.colors.panelBorder, backgroundColor: mauriTheme.colors.panel, padding: mauriTheme.spacing.lg, gap: mauriTheme.spacing.md },
  cardTitle: { color: mauriTheme.colors.white, fontSize: 22, fontWeight: "900" },
  cardText: { color: mauriTheme.colors.mutedWhite, lineHeight: 21 }
});
