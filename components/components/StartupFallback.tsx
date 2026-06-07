import { ActivityIndicator, StyleSheet, Text, View } from "react-native";

export function StartupFallback() {
  return (
    <View style={styles.root}>
      <Text style={styles.title}>MauriMesh</Text>

      <Text style={styles.subtitle}>
        Loading secure mesh interface...
      </Text>

      <ActivityIndicator
        style={styles.spinner}
        color="#7CFFB2"
        size="large"
      />

      <Text style={styles.note}>
        Waiting for mesh services.{"\n"}Offline mode will continue automatically.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: "#050814",
    alignItems: "center",
    justifyContent: "center",
    padding: 24,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 30,
    fontWeight: "900",
  },
  subtitle: {
    color: "#7CFFB2",
    marginTop: 12,
    fontSize: 15,
    textAlign: "center",
  },
  spinner: {
    marginTop: 24,
  },
  note: {
    color: "#8A94A6",
    marginTop: 18,
    fontSize: 13,
    textAlign: "center",
    lineHeight: 20,
  },
});
