import { useRouter } from "expo-router";
import React from "react";
import { ScrollView, StyleSheet, Text, TouchableOpacity, View } from "react-native";

export default function NextProofExamScreen() {
  const router = useRouter();

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.kicker}>MAURIMESH NEXT TEST</Text>
      <Text style={styles.title}>Store-Forward Delay Proof</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Goal</Text>
        <Text style={styles.body}>
          Prove S10 can hold a packet while A16 is unavailable, then forward it when A16 returns.
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Path</Text>
        <Text style={styles.path}>
          A06 TX → S10 STORE → A16 OFFLINE → A16 RETURNS → S10 FORWARD → A16 RX → ACK BACK
        </Text>
      </View>

      <View style={styles.truthCard}>
        <Text style={styles.truthTitle}>PASS Rule</Text>
        <Text style={styles.body}>
          PASS only when the same packetId appears across store, hold, rediscovery, forward, receiver RX, ACK, relay ACK, and final A06 ACK logs/screenshots.
        </Text>
      </View>

      <TouchableOpacity style={styles.button} onPress={() => router.push("/store-forward-proof")}>
        <Text style={styles.buttonText}>Open Store-Forward Proof</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 18, paddingBottom: 48, gap: 14 },
  kicker: { color: "#38BDF8", fontWeight: "900", letterSpacing: 2, fontSize: 12 },
  title: { color: "white", fontSize: 30, fontWeight: "900" },
  card: {
    borderWidth: 1,
    borderColor: "rgba(56,189,248,0.35)",
    backgroundColor: "rgba(2,12,20,0.88)",
    borderRadius: 22,
    padding: 16,
    gap: 8,
  },
  truthCard: {
    borderWidth: 1,
    borderColor: "rgba(245,158,11,0.6)",
    backgroundColor: "rgba(245,158,11,0.12)",
    borderRadius: 22,
    padding: 16,
    gap: 8,
  },
  cardTitle: { color: "white", fontSize: 18, fontWeight: "900" },
  truthTitle: { color: "#F59E0B", fontSize: 18, fontWeight: "900" },
  body: { color: "rgba(255,255,255,0.8)", lineHeight: 21 },
  path: { color: "#38BDF8", fontWeight: "900", lineHeight: 22 },
  button: {
    minHeight: 56,
    borderRadius: 18,
    backgroundColor: "#38BDF8",
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 18,
  },
  buttonText: { color: "white", fontWeight: "900", fontSize: 15 },
});
