import React from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { TikangaDecisionCard } from "../src/components/TikangaDecisionCard";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function TikangaEngineScreen() {
  return (
    <AppShell>
      <Text style={styles.title}>Tikanga Engine</Text>
      <Text style={styles.subtitle}>
        Governance UI for cultural risk, review states, protected terms, and audit trail.
      </Text>
      <TikangaDecisionCard />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 34,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 22,
  },
});
