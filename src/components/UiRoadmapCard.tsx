import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { UiRemainderTask } from "../lib/uiRemainder";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

export function UiRoadmapCard({ task }: { task: UiRemainderTask }) {
  const tone =
    task.priority === "P0"
      ? "danger"
      : task.priority === "P1"
        ? "warning"
        : "info";

  return (
    <View style={styles.card}>
      <View style={styles.row}>
        <StatusPill label={task.priority} tone={tone} />
        <StatusPill
          label={task.status.toUpperCase()}
          tone={task.status === "ready" ? "success" : task.status === "requires-device-proof" ? "warning" : "info"}
        />
      </View>

      <Text style={styles.title}>{task.title}</Text>
      <Text style={styles.why}>{task.why}</Text>

      <Text style={styles.heading}>Build</Text>
      {task.build.map((item) => (
        <Text key={item} style={styles.item}>• {item}</Text>
      ))}

      <Text style={styles.heading}>Acceptance</Text>
      {task.acceptance.map((item) => (
        <Text key={item} style={styles.item}>✓ {item}</Text>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.sm,
  },
  row: {
    flexDirection: "row",
    gap: 8,
    flexWrap: "wrap",
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 20,
    fontWeight: "900",
  },
  why: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 14,
    lineHeight: 21,
  },
  heading: {
    color: mauriTheme.colors.greenstone,
    fontSize: 13,
    fontWeight: "900",
    marginTop: 6,
    letterSpacing: 0.8,
  },
  item: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 13,
    lineHeight: 19,
  },
});
