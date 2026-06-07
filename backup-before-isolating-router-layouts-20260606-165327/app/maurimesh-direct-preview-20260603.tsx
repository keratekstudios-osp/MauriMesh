import React from "react";
import { ScrollView, StyleSheet, Text, View, Pressable, Alert } from "react-native";

export default function MauriMeshDirectPreview() {
  return (
    <ScrollView style={styles.page} contentContainerStyle={styles.content}>
      <View style={styles.header}>
        <Text style={styles.menu}>☰</Text>
        <View style={styles.dot} />
        <Text style={styles.brand}>MauriMesh</Text>
      </View>

      <View style={styles.hero}>
        <Text style={styles.pill}>DIRECT STATIC PREVIEW · NO API WAIT</Text>
        <Text style={styles.title}>MauriMesh Messenger</Text>
        <Text style={styles.subtitle}>
          Replit preview route is now registered inside Expo Router. This page
          bypasses the old mesh API failure screen and runs labelled simulation only.
        </Text>
      </View>

      <View style={styles.grid}>
        <Card title="Web UI Layer" status="READY">
          Static preview is loading through a real Expo Router page.
        </Card>

        <Card title="BLE Runtime" status="PROTECTED">
          Native BLE, ACK, relay, and store-forward remain APK/device validation work.
        </Card>

        <Card title="Living Mesh" status="SIMULATION">
          Local preview nodes are shown without API calls.
        </Card>

        <Card title="System Brain" status="SERVER ONLY">
          Node fs/path file logic stays outside browser bundling.
        </Card>
      </View>

      <View style={styles.mesh}>
        <View style={[styles.node, styles.nodeA]}>
          <Text style={styles.nodeText}>A</Text>
          <Text style={styles.nodeSub}>96%</Text>
        </View>

        <View style={[styles.node, styles.nodeB]}>
          <Text style={styles.nodeText}>B</Text>
          <Text style={styles.nodeSub}>82%</Text>
        </View>

        <View style={[styles.node, styles.nodeC]}>
          <Text style={styles.nodeText}>C</Text>
          <Text style={styles.nodeSub}>74%</Text>
        </View>

        <View style={[styles.node, styles.nodeD]}>
          <Text style={styles.nodeText}>D</Text>
          <Text style={styles.nodeSub}>31%</Text>
        </View>
      </View>

      <View style={styles.actions}>
        <Button label="Demo Route" message="Demo route prepared in static simulation mode." />
        <Button label="Simulate ACK" message="ACK simulated. Real ACK requires APK/device proof." />
        <Button label="Store Forward" message="Store-forward shell active in preview." />
        <Button label="Tikanga Layer" message="Tikanga governance layer protected for runtime integration." />
      </View>

      <Text style={styles.truth}>
        Truth: this proves the Replit web/static UI route. Real BLE discovery,
        native ACK routing, offline delivery, background Bluetooth, and live mesh API
        still require APK/device testing.
      </Text>
    </ScrollView>
  );
}

function Card({
  title,
  status,
  children
}: {
  title: string;
  status: string;
  children: React.ReactNode;
}) {
  return (
    <View style={styles.card}>
      <Text style={styles.pillSmall}>{status}</Text>
      <Text style={styles.cardTitle}>{title}</Text>
      <Text style={styles.cardText}>{children}</Text>
    </View>
  );
}

function Button({ label, message }: { label: string; message: string }) {
  return (
    <Pressable style={styles.button} onPress={() => Alert.alert("MauriMesh", message)}>
      <Text style={styles.buttonText}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  page: {
    flex: 1,
    backgroundColor: "#020403"
  },
  content: {
    paddingBottom: 40
  },
  header: {
    height: 72,
    paddingHorizontal: 22,
    backgroundColor: "#050B16",
    borderBottomWidth: 1,
    borderBottomColor: "rgba(255,255,255,0.08)",
    flexDirection: "row",
    alignItems: "center",
    gap: 14
  },
  menu: {
    color: "rgba(255,255,255,0.72)",
    fontSize: 30
  },
  dot: {
    width: 14,
    height: 14,
    borderRadius: 999,
    backgroundColor: "#00D084"
  },
  brand: {
    color: "#FFFFFF",
    fontSize: 24,
    fontWeight: "900"
  },
  hero: {
    margin: 18,
    padding: 22,
    borderRadius: 24,
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.32)",
    backgroundColor: "rgba(2,12,8,0.88)"
  },
  pill: {
    alignSelf: "flex-start",
    color: "#00D084",
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.45)",
    borderRadius: 999,
    paddingVertical: 8,
    paddingHorizontal: 12,
    fontWeight: "900",
    fontSize: 12,
    letterSpacing: 0.8
  },
  pillSmall: {
    alignSelf: "flex-start",
    color: "#00D084",
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.35)",
    borderRadius: 999,
    paddingVertical: 6,
    paddingHorizontal: 10,
    fontWeight: "900",
    fontSize: 11
  },
  title: {
    color: "#FFFFFF",
    fontSize: 42,
    fontWeight: "900",
    marginTop: 20,
    lineHeight: 44
  },
  subtitle: {
    color: "rgba(255,255,255,0.72)",
    lineHeight: 23,
    marginTop: 12,
    fontSize: 15
  },
  grid: {
    paddingHorizontal: 18,
    gap: 14
  },
  card: {
    padding: 18,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.28)",
    backgroundColor: "rgba(255,255,255,0.05)"
  },
  cardTitle: {
    color: "#FFFFFF",
    fontSize: 20,
    fontWeight: "900",
    marginTop: 10,
    marginBottom: 8
  },
  cardText: {
    color: "rgba(255,255,255,0.72)",
    lineHeight: 21
  },
  mesh: {
    height: 320,
    margin: 18,
    borderRadius: 24,
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.32)",
    backgroundColor: "#020806",
    position: "relative",
    overflow: "hidden"
  },
  node: {
    position: "absolute",
    width: 72,
    height: 72,
    borderRadius: 999,
    borderWidth: 1,
    borderColor: "#00D084",
    backgroundColor: "rgba(0,208,132,0.16)",
    alignItems: "center",
    justifyContent: "center"
  },
  nodeA: { left: "16%", top: "25%" },
  nodeB: { left: "46%", top: "52%" },
  nodeC: { left: "76%", top: "25%" },
  nodeD: { left: "62%", top: "74%", opacity: 0.45 },
  nodeText: {
    color: "#FFFFFF",
    fontWeight: "900",
    fontSize: 20
  },
  nodeSub: {
    color: "rgba(255,255,255,0.72)",
    fontSize: 12,
    fontWeight: "800"
  },
  actions: {
    paddingHorizontal: 18,
    gap: 12
  },
  button: {
    minHeight: 54,
    borderRadius: 18,
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.32)",
    backgroundColor: "rgba(0,208,132,0.16)",
    alignItems: "center",
    justifyContent: "center"
  },
  buttonText: {
    color: "#FFFFFF",
    fontWeight: "900",
    fontSize: 15
  },
  truth: {
    color: "rgba(255,255,255,0.72)",
    borderLeftWidth: 3,
    borderLeftColor: "#F59E0B",
    paddingLeft: 12,
    margin: 18,
    lineHeight: 21
  }
});
