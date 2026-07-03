import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { ButtonDecision } from "../maurimesh/system-brain/systemTypes";
import { mauriTheme } from "../theme/mauriTheme";

export function ButtonWiringPanel({ buttons }: { buttons: ButtonDecision[] }) {
  return (
    <View style={styles.card}>
      <Text style={styles.title}>Button Decision Router</Text>
      {buttons.map((button) => (
        <View key={`${button.screen}-${button.buttonTitle}`} style={styles.item}>
          <Text
            style={[
              styles.status,
              button.status === "CONNECTED" && styles.pass,
              button.status === "NEEDS_NATIVE_PROOF" && styles.warn,
              button.status === "MISSING_SCREEN" && styles.fail,
            ]}
          >
            {button.status}
          </Text>
          <Text style={styles.buttonTitle}>{button.buttonTitle}</Text>
          <Text style={styles.text}>{button.targetRoute}</Text>
          <Text style={styles.layer}>{button.decisionLayer}</Text>
          <Text style={styles.text}>{button.reason}</Text>
        </View>
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
    gap: mauriTheme.spacing.md,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 22,
    fontWeight: "900",
  },
  item: {
    borderTopWidth: 1,
    borderTopColor: "rgba(255,255,255,0.08)",
    paddingTop: 12,
    gap: 4,
  },
  status: {
    fontSize: 12,
    fontWeight: "900",
  },
  pass: {
    color: mauriTheme.colors.success,
  },
  warn: {
    color: mauriTheme.colors.warning,
  },
  fail: {
    color: mauriTheme.colors.danger,
  },
  buttonTitle: {
    color: mauriTheme.colors.white,
    fontSize: 17,
    fontWeight: "900",
  },
  layer: {
    color: mauriTheme.colors.greenstone,
    fontWeight: "900",
  },
  text: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 20,
  },
});
