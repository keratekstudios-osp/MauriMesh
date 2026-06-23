import React from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { TikangaDecisionCard } from "../src/components/TikangaDecisionCard";
import { MauriCoreStatusPanel } from "../src/components/MauriCoreStatusPanel";
import { mauriTheme } from "../src/theme/mauriTheme";
import { MaoriProtocolPanel } from "../src/components/MaoriProtocolPanel";

export default function MauriCoreGovernanceScreen() {
  return (
    <AppShell>
      <Text style={styles.title}>MauriCore Governance</Text>
      <Text style={styles.subtitle}>
        Governance dashboard for MauriCore, Tikanga decision state, audit visibility, and safe UI proof.
      </Text>
      <MauriCoreStatusPanel />
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

// Māori Protocol restored for MauriCore Governance
