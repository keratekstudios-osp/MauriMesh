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
  RoutingEngineConfig,
} from "../lib/mauri-mesh-engine/src/index";
import {
  getStoredRoutingSelection,
  setRoutingPreset,
  setCustomRoutingConfig,
  resolveSelectionValues,
  ROUTING_DIMENSIONS,
  RoutingDimension,
  RoutingMode,
} from "../lib/lib/routingConfig";

const MARKER = "SAFE_SETTINGS_20260607_A";

const PRESET_ORDER: RoutingPreset[] = ["stable", "balanced", "aggressive"];

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function formatDimension(dim: RoutingDimension, value: number): string {
  const scaled = value / dim.scale;
  const text =
    dim.scale === 1 ? String(scaled) : String(Number(scaled.toFixed(2)));
  return dim.unit ? `${text}${dim.unit}` : text;
}

function toCustomConfig(
  values: RoutingEngineConfig
): Partial<RoutingEngineConfig> {
  const out: Partial<RoutingEngineConfig> = {};
  for (const dim of ROUTING_DIMENSIONS) {
    out[dim.key] = values[dim.key];
  }
  return out;
}

export default function SettingsScreen() {
  const [mode, setMode] = useState<RoutingMode>(DEFAULT_ROUTING_PRESET);
  const [customValues, setCustomValues] = useState<RoutingEngineConfig>(() =>
    resolveSelectionValues({ mode: DEFAULT_ROUTING_PRESET }),
  );
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let alive = true;
    getStoredRoutingSelection()
      .then((selection) => {
        if (!alive) return;
        setMode(selection.mode);
        setCustomValues(resolveSelectionValues(selection));
      })
      .finally(() => {
        if (alive) setLoading(false);
      });
    return () => {
      alive = false;
    };
  }, []);

  const choosePreset = (next: RoutingPreset) => {
    setMode(next);
    // Seed the custom editor from the chosen preset so switching into Advanced
    // starts from the user's current sensitivity rather than a cold default.
    setCustomValues(resolveSelectionValues({ mode: next }));
    void setRoutingPreset(next);
  };

  const enterCustom = () => {
    setMode("custom");
    void setCustomRoutingConfig(toCustomConfig(customValues));
  };

  const adjust = (dim: RoutingDimension, delta: number) => {
    setCustomValues((prev) => {
      const nextValue = clamp(prev[dim.key] + delta, dim.min, dim.max);
      const next = { ...prev, [dim.key]: nextValue };
      void setCustomRoutingConfig(toCustomConfig(next));
      return next;
    });
  };

  const resetCustom = () => {
    const defaults = resolveSelectionValues({ mode: "balanced" });
    setCustomValues(defaults);
    void setCustomRoutingConfig(toCustomConfig(defaults));
  };

  const customActive = mode === "custom";

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
          <>
            <View style={styles.presetList}>
              {PRESET_ORDER.map((key) => {
                const meta = ROUTING_PRESETS[key];
                const selected = key === mode;
                return (
                  <TouchableOpacity
                    key={key}
                    accessibilityRole="button"
                    accessibilityState={{ selected }}
                    onPress={() => choosePreset(key)}
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

              <TouchableOpacity
                accessibilityRole="button"
                accessibilityState={{ selected: customActive }}
                onPress={enterCustom}
                style={[styles.preset, customActive && styles.presetSelected]}
              >
                <View style={styles.presetHeader}>
                  <Text
                    style={[
                      styles.presetLabel,
                      customActive && styles.presetLabelSelected,
                    ]}
                  >
                    Advanced (Custom)
                  </Text>
                  {customActive ? (
                    <Text style={styles.presetCheck}>ACTIVE</Text>
                  ) : null}
                </View>
                <Text style={styles.presetDesc}>
                  Tune each routing dimension by hand — for dense or unusual
                  meshes. Starts from your current preset.
                </Text>
              </TouchableOpacity>
            </View>

            {customActive ? (
              <View style={styles.customPanel}>
                {ROUTING_DIMENSIONS.map((dim) => {
                  const value = customValues[dim.key];
                  const atMin = value <= dim.min;
                  const atMax = value >= dim.max;
                  return (
                    <View key={dim.key} style={styles.dimRow}>
                      <View style={styles.dimHeader}>
                        <Text style={styles.dimLabel}>{dim.label}</Text>
                        <Text style={styles.dimValue}>
                          {formatDimension(dim, value)}
                        </Text>
                      </View>
                      <Text style={styles.dimHelp}>{dim.help}</Text>
                      <View style={styles.stepper}>
                        <TouchableOpacity
                          accessibilityRole="button"
                          accessibilityLabel={`Decrease ${dim.label}`}
                          disabled={atMin}
                          onPress={() => adjust(dim, -dim.step)}
                          style={[
                            styles.stepBtn,
                            atMin && styles.stepBtnDisabled,
                          ]}
                        >
                          <Text style={styles.stepBtnText}>−</Text>
                        </TouchableOpacity>
                        <Text style={styles.stepReadout}>
                          {formatDimension(dim, value)}
                        </Text>
                        <TouchableOpacity
                          accessibilityRole="button"
                          accessibilityLabel={`Increase ${dim.label}`}
                          disabled={atMax}
                          onPress={() => adjust(dim, dim.step)}
                          style={[
                            styles.stepBtn,
                            atMax && styles.stepBtnDisabled,
                          ]}
                        >
                          <Text style={styles.stepBtnText}>+</Text>
                        </TouchableOpacity>
                      </View>
                    </View>
                  );
                })}

                <TouchableOpacity
                  accessibilityRole="button"
                  onPress={resetCustom}
                  style={styles.resetBtn}
                >
                  <Text style={styles.resetBtnText}>Reset to defaults</Text>
                </TouchableOpacity>
              </View>
            ) : null}
          </>
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
  customPanel: { marginTop: 16, gap: 16 },
  dimRow: {
    backgroundColor: "rgba(255,255,255,0.04)",
    borderColor: "rgba(255,255,255,0.10)",
    borderWidth: 1,
    borderRadius: 14,
    padding: 14,
  },
  dimHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 6,
  },
  dimLabel: { color: "#FFFFFF", fontSize: 15, fontWeight: "800", flexShrink: 1 },
  dimValue: { color: "#00D084", fontSize: 15, fontWeight: "900", marginLeft: 12 },
  dimHelp: { color: "rgba(255,255,255,0.58)", fontSize: 12, lineHeight: 18, marginBottom: 12 },
  stepper: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  stepBtn: {
    width: 52,
    height: 44,
    borderRadius: 12,
    backgroundColor: "rgba(0,208,132,0.16)",
    borderColor: "rgba(0,208,132,0.5)",
    borderWidth: 1,
    alignItems: "center",
    justifyContent: "center",
  },
  stepBtnDisabled: {
    opacity: 0.35,
  },
  stepBtnText: { color: "#FFFFFF", fontSize: 22, fontWeight: "900", lineHeight: 24 },
  stepReadout: { color: "#FFFFFF", fontSize: 16, fontWeight: "800" },
  resetBtn: {
    alignSelf: "flex-start",
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderRadius: 12,
    borderColor: "rgba(255,255,255,0.18)",
    borderWidth: 1,
  },
  resetBtnText: { color: "rgba(255,255,255,0.8)", fontSize: 13, fontWeight: "800" },
});
