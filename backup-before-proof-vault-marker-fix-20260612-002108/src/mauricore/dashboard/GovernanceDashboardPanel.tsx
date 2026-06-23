import React, { useMemo } from "react";
import { ScrollView, Text, View } from "react-native";
import { getGovernanceDashboardData } from "./governanceDashboard";

export function GovernanceDashboardPanel() {
  const data = useMemo(() => getGovernanceDashboardData(), []);

  return (
    <ScrollView style={{ flex: 1, backgroundColor: "#020403", padding: 16 }}>
      <Text style={{ color: "#fff", fontSize: 28, fontWeight: "900" }}>
        MauriCore Governance
      </Text>

      <Text style={{ color: "#00D084", marginTop: 8 }}>
        Proof chain: {data.core.proofChainOk ? "OK" : "BROKEN"}
      </Text>

      <Text style={{ color: "#fff", marginTop: 16, fontSize: 20, fontWeight: "800" }}>
        Build Readiness
      </Text>
      <Text style={{ color: data.build.canBuildApk ? "#00D084" : "#F59E0B" }}>
        APK Gate: {data.build.canBuildApk ? "READY" : "NOT READY"}
      </Text>

      <Text style={{ color: "#fff", marginTop: 16, fontSize: 20, fontWeight: "800" }}>
        Layers
      </Text>

      {data.layers.map((layer) => (
        <View
          key={layer.id}
          style={{
            borderWidth: 1,
            borderColor: "rgba(0,208,132,0.35)",
            borderRadius: 16,
            padding: 12,
            marginTop: 10,
          }}
        >
          <Text style={{ color: "#fff", fontWeight: "900" }}>{layer.name}</Text>
          <Text style={{ color: "#cbd5e1" }}>
            {layer.status} · confidence {Math.round(layer.confidence * 100)}%
          </Text>
        </View>
      ))}
    </ScrollView>
  );
}
