import React from "react";
import { SafeAreaView, ScrollView, StyleSheet, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

export function AppShell({
  children,
  scroll = true,
}: {
  children: React.ReactNode;
  scroll?: boolean;
}) {
  const content = (
    <View style={styles.content}>
      <View style={styles.glowA} />
      <View style={styles.glowB} />
      {children}
    </View>
  );

  return (
    <SafeAreaView style={styles.safe}>
      {scroll ? (
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          {content}
        </ScrollView>
      ) : (
        content
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: mauriTheme.colors.black,
  },
  scrollContent: {
    flexGrow: 1,
  },
  content: {
    flex: 1,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.md,
    backgroundColor: mauriTheme.colors.black,
    overflow: "hidden",
  },
  glowA: {
    position: "absolute",
    width: 280,
    height: 280,
    borderRadius: 140,
    top: -90,
    right: -110,
    backgroundColor: "rgba(0,208,132,0.18)",
  },
  glowB: {
    position: "absolute",
    width: 260,
    height: 260,
    borderRadius: 130,
    bottom: -120,
    left: -110,
    backgroundColor: "rgba(56,189,248,0.10)",
  },
});
