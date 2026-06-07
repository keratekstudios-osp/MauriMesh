import { useRouter } from "expo-router";
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function SettingsScreen() {
  const router = useRouter();

  return (
    <AppShell>
      <Text style={styles.title}>Settings</Text>
      <Text style={styles.subtitle}>
        User controls, language shell, app state, and safe logout.
      </Text>

      <View style={styles.card}>
        <StatusPill label="LANGUAGE" tone="info" />
        <Text style={styles.cardTitle}>Preferred Language</Text>
        <Text style={styles.cardText}>
          English selected. Te reo Māori and additional languages can be wired into i18n next.
        </Text>
      </View>

      <View style={styles.card}>
        <StatusPill label="REPLIT MODE" tone="warning" />
        <Text style={styles.cardTitle}>Runtime Notice</Text>
        <Text style={styles.cardText}>
          Replit preview supports UI and API testing. Real BLE/offline proof requires APK on physical devices.
        </Text>
      </View>

      <MauriButton title="Log Out" variant="danger" onPress={() => router.replace("/login")} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, lineHeight: 22 },
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.sm
  },
  cardTitle: { color: mauriTheme.colors.white, fontSize: 18, fontWeight: "900" },
  cardText: { color: mauriTheme.colors.mutedWhite, lineHeight: 21 }
});
