import React from "react";
import { StyleSheet, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

export function MauriDivider() {
  return <View style={styles.divider} />;
}

const styles = StyleSheet.create({
  divider: {
    height: 1,
    backgroundColor: mauriTheme.colors.panelBorder,
    marginVertical: mauriTheme.spacing.xs,
  },
});
