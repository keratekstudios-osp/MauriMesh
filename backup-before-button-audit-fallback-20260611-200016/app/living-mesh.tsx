import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { LivingMeshCanvas } from "../src/components/LivingMeshCanvas";
import { StatusPill } from "../src/components/StatusPill";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function LivingMeshScreen() {
  const [mesh, setMesh] = useState<MeshStatus | null>(null);

  useEffect(() => {
    getMeshStatus()
      .then(setMesh)
      .catch(() => {
        setMesh({
          mode: "SIMULATION",
          message: "Mesh API unavailable. Showing SIMULATION fallback.",
          nodes: [],
          routes: [],
        });
      });
  }, []);

  return (
    <AppShell>
      <StatusPill
        label={mesh?.mode || "SIMULATION"}
        tone={mesh?.mode === "LIVE" ? "success" : "warning"}
      />

      <Text style={styles.title}>Living Mesh</Text>

      <Text style={styles.subtitle}>
        {mesh?.message ||
          "Checking Mesh API. Replit fallback displays SIMULATION only."}
      </Text>

      <View style={styles.truthBox}>
        <Text style={styles.truthTitle}>SIMULATION fallback</Text>
        <Text style={styles.truthText}>
          Living Mesh is a Replit UI/simulation view until live Mesh API or APK/device proof is connected.
        </Text>
      </View>

      <LivingMeshCanvas nodes={mesh?.nodes || []} routes={mesh?.routes || []} />
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
  truthBox: {
    borderWidth: 1,
    borderColor: "rgba(245,158,11,0.45)",
    backgroundColor: "rgba(245,158,11,0.10)",
    borderRadius: mauriTheme.radius.lg,
    padding: mauriTheme.spacing.md,
    gap: 6,
  },
  truthTitle: {
    color: mauriTheme.colors.warning,
    fontWeight: "900",
  },
  truthText: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 20,
  },
});
