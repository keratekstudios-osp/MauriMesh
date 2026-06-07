import React from "react";
import { SafeAreaView, ScrollView, StyleSheet, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

export function AppShell({
  children,
  scroll = true
}: {
  children: React.ReactNode;
  scroll?: boolean;
}) {
  const content = <View style={styles.content}>{children}</View>;

  return (
    <SafeAreaView style={styles.safe}>
      {scroll ? <ScrollView>{content}</ScrollView> : content}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: mauriTheme.colors.black
  },
  content: {
    flex: 1,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.md
  }
});
