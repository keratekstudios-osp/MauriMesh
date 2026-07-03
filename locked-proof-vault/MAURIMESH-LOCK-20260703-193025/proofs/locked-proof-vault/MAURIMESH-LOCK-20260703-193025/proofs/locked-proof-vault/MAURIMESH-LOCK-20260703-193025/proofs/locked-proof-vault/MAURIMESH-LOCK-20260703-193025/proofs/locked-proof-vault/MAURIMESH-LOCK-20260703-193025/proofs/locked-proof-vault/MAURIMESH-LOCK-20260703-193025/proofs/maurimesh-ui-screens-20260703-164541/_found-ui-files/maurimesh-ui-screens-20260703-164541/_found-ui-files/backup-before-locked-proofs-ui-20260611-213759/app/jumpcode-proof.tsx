import React from "react";
import { ScrollView, StyleSheet } from "react-native";
import { JumpCodeProofPanel } from "../src/components/JumpCodeProofPanel";
import { MaoriProtocolPanel } from "../src/components/MaoriProtocolPanel";

export default function JumpCodeProofScreen() {
  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <MaoriProtocolPanel screen="JumpCode Proof" />
      <JumpCodeProofPanel />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: "#020403",
  },
  content: {
    padding: 16,
    paddingBottom: 42,
  },
});
