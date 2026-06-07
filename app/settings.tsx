import React, { useEffect, useState } from "react";
import {
  ActivityIndicator,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import {
  ROUTING_PRESETS,
  DEFAULT_ROUTING_PRESET,
  RoutingPreset,
} from "../lib/mauri-mesh-engine/src/index";
import {
  getStoredRoutingPreset,
  setRoutingPreset,
} from "../lib/lib/routingConfig";

const MARKER = "SAFE_SETTINGS_20260607_A";

const PRESET_ORDER: RoutingPreset[] = ["stable", "balanced", "aggressive"];

export default function SettingsScreen() {
  const [preset, setPreset] = useState<RoutingPreset>(DEFAULT_ROUTING_PRESET);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let alive = true;
    getStoredRoutingPreset()
      .then((stored) => {
        if (alive) setPreset(stored);
      })
      .finally(() => {
        if (alive) setLoading(false);
      });
    return () => {
      alive = false;
    };
  }, []);

  const choose = (next: RoutingPreset) => {
    setPreset(next);
    void setRoutingPreset(next);
  };

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Settings</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Routing Sensitivity</Text>
        <Text style={styles.cardText}>
          Controls how aggressively the mesh reroutes around flaky peers and busy
          relays. Saved on this device and applied on every restart.
        </Text>

        {loading ? (
          <ActivityIndicator color="#00D084" style={styles.loader} />
        ) : (
          <View style={styles.presetList}>
            {PRESET_ORDER.map((key) => {
              const meta = ROUTING_PRESETS[key];
              const selected = key === preset;
              return (
                <TouchableOpacity
                  key={key}
                  accessibilityRole="button"
                  accessibilityState={{ selected }}
                  onPress={() => choose(key)}
                  style={[styles.preset, selected && styles.presetSelected]}
                >
                  <View style={styles.presetHeader}>
                    <Text
                      style={[
                        styles.presetLabel,
                        selected && styles.presetLabelSelected,
                      ]}
                    >
                      {meta.label}
                    </Text>
                    {selected ? (
                      <Text style={styles.presetCheck}>ACTIVE</Text>
                    ) : null}
                  </View>
                  <Text style={styles.presetDesc}>{meta.description}</Text>
                </TouchableOpacity>
              );
            })}
          </View>
        )}
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Runtime Mode</Text>
        <Text style={styles.cardText}>
          Safe UI shell only. BLE/runtime engines still isolated until stable
          route proof.
        </Text>
      </View>
      <View style={styles.card}>
        <Text style={styles.cardTitle}>Package</Text>
        <Text style={styles.cardText}>com.maurimesh.messenger</Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020617" },
  content: { padding: 24, paddingTop: 72 },
  brand: { color: "#00D084", fontSize: 38, fontWeight: "900", marginBottom: 8 },
  title: { color: "#FFFFFF", fontSize: 28, fontWeight: "900", marginBottom: 8 },
  marker: { color: "#38BDF8", fontSize: 12, fontWeight: "800", marginBottom: 20 },
  card: { backgroundColor: "rgba(255,255,255,0.06)", borderColor: "rgba(0,208,132,0.28)", borderWidth: 1, borderRadius: 22, padding: 18, marginBottom: 16 },
  cardTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900", marginBottom: 10 },
  cardText: { color: "rgba(255,255,255,0.72)", fontSize: 14, lineHeight: 22 },
  loader: { marginTop: 16, alignSelf: "flex-start" },
  presetList: { marginTop: 14, gap: 10 },
  preset: {
    backgroundColor: "rgba(255,255,255,0.04)",
    borderColor: "rgba(255,255,255,0.12)",
    borderWidth: 1,
    borderRadius: 16,
    padding: 14,
  },
  presetSelected: {
    borderColor: "#00D084",
    backgroundColor: "rgba(0,208,132,0.12)",
  },
  presetHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 6,
  },
  presetLabel: { color: "rgba(255,255,255,0.86)", fontSize: 16, fontWeight: "800" },
  presetLabelSelected: { color: "#FFFFFF" },
  presetCheck: { color: "#00D084", fontSize: 11, fontWeight: "900", letterSpacing: 1 },
  presetDesc: { color: "rgba(255,255,255,0.62)", fontSize: 13, lineHeight: 19 },
});
