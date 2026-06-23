import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

export type SynthPanelMessage = {
  agent: string;
  tone: string;
  text: string;
};

export function SynthPanel({ messages }: { messages: SynthPanelMessage[] }) {
  return (
    <View style={styles.card}>
      <Text style={styles.title}>Cleo + Chanelle Synth AI</Text>
      {messages.length === 0 ? (
        <Text style={styles.empty}>No synth explanation yet. Run a demo or send a message.</Text>
      ) : (
        messages.map((msg, index) => (
          <View key={`${msg.agent}-${index}`} style={styles.message}>
            <Text style={styles.agent}>{msg.agent} · {msg.tone}</Text>
            <Text style={styles.text}>{msg.text}</Text>
          </View>
        ))
      )}
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
    fontSize: 20,
    fontWeight: "900",
  },
  empty: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  message: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    borderRadius: mauriTheme.radius.lg,
    padding: mauriTheme.spacing.md,
    backgroundColor: "rgba(255,255,255,0.04)",
    gap: 6,
  },
  agent: {
    color: mauriTheme.colors.greenstone,
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 0.6,
  },
  text: {
    color: mauriTheme.colors.white,
    lineHeight: 21,
  },
});
