import React from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";

const MARKER = "SAFE_HOME_DASHBOARD_20260607_A";

export default function IndexScreen() {
  const router = useRouter();

  return (
    <View style={styles.screen}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Messenger Boot Complete</Text>
      <Text style={styles.marker}>{MARKER}</Text>
      <Text style={styles.text}>
        Native APK shell, package identity, and safe Expo Router navigation are working.
      </Text>

      <Pressable style={styles.button} onPress={() => router.push("/dashboard")}>
        <Text style={styles.buttonText}>Open Dashboard</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: "#020617",
    alignItems: "center",
    justifyContent: "center",
    padding: 24,
  },
  brand: {
    color: "#00D084",
    fontSize: 42,
    fontWeight: "900",
    marginBottom: 12,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 22,
    fontWeight: "800",
    textAlign: "center",
    marginBottom: 12,
  },
  marker: {
    color: "#38BDF8",
    fontSize: 12,
    fontWeight: "800",
    marginBottom: 18,
  },
  text: {
    color: "rgba(255,255,255,0.72)",
    fontSize: 14,
    lineHeight: 21,
    textAlign: "center",
    marginBottom: 24,
  },
  button: {
    backgroundColor: "#00D084",
    borderRadius: 18,
    paddingVertical: 16,
    paddingHorizontal: 26,
  },
  buttonText: {
    color: "#020617",
    fontSize: 16,
    fontWeight: "900",
  },
});
