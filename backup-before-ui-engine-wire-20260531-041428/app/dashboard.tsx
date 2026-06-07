import { useRouter } from "expo-router";
import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { MeshSignalCard } from "../src/components/MeshSignalCard";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function DashboardScreen() {
  const router = useRouter();
  const [mesh, setMesh] = useState<MeshStatus | null>(null);

  useEffect(() => {
    getMeshStatus().then(setMesh);
  }, []);

  const mode = mesh?.mode || "UNAVAILABLE";

  return (
    <AppShell>
      <Text style={styles.title}>Dashboard</Text>
      <Text style={styles.subtitle}>
        Command centre for messenger, mesh visibility, friend discovery, and Pixel Calling shell.
      </Text>

      <MeshSignalCard title="Mesh Status" value={mesh?.message || "Checking mesh status..."} status={mode} />

      <View style={styles.grid}>
        <MauriButton title="Chat" onPress={() => router.push("/chat")} />
        <MauriButton title="Living Mesh" onPress={() => router.push("/living-mesh")} />
        <MauriButton title="Add Friend" onPress={() => router.push("/add-friend")} />
        <MauriButton title="Pixel Calling" onPress={() => router.push("/pixel-calling")} />
        <MauriButton title="Mesh Status" onPress={() => router.push("/mesh-status")} />
        <MauriButton title="Settings" onPress={() => router.push("/settings")} />
      </View>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 36, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, fontSize: 15, lineHeight: 22 },
  grid: { gap: mauriTheme.spacing.md }
});
