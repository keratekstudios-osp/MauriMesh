import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

export function MeshSignalCard({
  title,
  value,
  status,
}: {
  title: string;
  value: string;
  status: "LIVE" | "SIMULATION" | "UNAVAILABLE";
}) {
  return (
    <View style={styles.card}>
      <View style={styles.orb} />
      <StatusPill
        label={status}
        tone={
          status === "LIVE"
            ? "success"
            : status === "SIMULATION"
              ? "warning"
              : "danger"
        }
      />
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.value}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorderStrong,
    backgroundColor: mauriTheme.colors.panelStrong,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.sm,
    overflow: "hidden",
    ...mauriTheme.shadow.card,
  },
  orb: {
    position: "absolute",
    width: 130,
    height: 130,
    borderRadius: 65,
    right: -46,
    top: -42,
    backgroundColor: "rgba(0,208,132,0.16)",
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 20,
    fontWeight: "900",
  },
  value: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 14,
    lineHeight: 21,
  },
});
