import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function PixelCallingScreen() {
  return (
    <AppShell>
      <StatusPill label="UI SHELL ONLY" tone="warning" />
      <Text style={styles.title}>Pixel Calling</Text>
      <Text style={styles.subtitle}>
        Interface prepared. Real media transport requires native WebRTC/device proof outside Replit.
      </Text>

      <View style={styles.videoBox}>
        <Text style={styles.videoText}>Pixel Stream Preview</Text>
        <Text style={styles.videoSub}>SIMULATION / UI ONLY</Text>
      </View>

      <MauriButton title="Start Call" onPress={() => {}} />
      <MauriButton title="End Call" variant="danger" onPress={() => {}} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, lineHeight: 22 },
  videoBox: {
    height: 380,
    borderRadius: mauriTheme.radius.xl,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: "#030B09",
    alignItems: "center",
    justifyContent: "center",
    gap: 8
  },
  videoText: { color: mauriTheme.colors.white, fontSize: 22, fontWeight: "900" },
  videoSub: { color: mauriTheme.colors.warning, fontSize: 12, fontWeight: "800", letterSpacing: 1 }
});
