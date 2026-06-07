import React, { useEffect, useState } from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { LivingMeshCanvas } from "../src/components/LivingMeshCanvas";
import { StatusPill } from "../src/components/StatusPill";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function LivingMeshScreen() {
  const [mesh, setMesh] = useState<MeshStatus | null>(null);

  useEffect(() => {
    getMeshStatus().then(setMesh);
  }, []);

  return (
    <AppShell>
      <StatusPill label={mesh?.mode || "CHECKING"} tone={mesh?.mode === "LIVE" ? "success" : "warning"} />
      <Text style={styles.title}>Living Mesh</Text>
      <Text style={styles.subtitle}>
        {mesh?.message || "Checking Mesh API. Replit fallback displays simulation only."}
      </Text>
      <LivingMeshCanvas nodes={mesh?.nodes || []} routes={mesh?.routes || []} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, lineHeight: 22 }
});
