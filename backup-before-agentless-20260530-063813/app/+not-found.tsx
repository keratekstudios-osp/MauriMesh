import { Link, Stack } from "expo-router";
import { StyleSheet, Text, View } from "react-native";

export default function NotFoundScreen() {
  return (
    <>
      <Stack.Screen options={{ title: "Not Found" }} />
      <View style={styles.container}>
        <Text style={styles.icon}>◎</Text>
        <Text style={styles.title}>Screen Not Found</Text>
        <Text style={styles.body}>
          This route doesn&apos;t exist in the mesh.
        </Text>
        <Link href="/dashboard" style={styles.link}>
          <Text style={styles.linkText}>Return to Dashboard</Text>
        </Link>
      </View>
    </>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    padding: 32,
    backgroundColor: "#050816",
  },
  icon: {
    color: "#39FF14",
    fontSize: 56,
    marginBottom: 20,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 24,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
    textAlign: "center",
    letterSpacing: 0.5,
    marginBottom: 12,
  },
  body: {
    color: "#94A3B8",
    fontSize: 15,
    fontWeight: "500",
    fontFamily: "Inter_500Medium",
    textAlign: "center",
    lineHeight: 24,
    marginBottom: 32,
  },
  link: {
    paddingHorizontal: 28,
    paddingVertical: 14,
    borderRadius: 16,
    backgroundColor: "rgba(57,255,20,0.08)",
    borderWidth: 1,
    borderColor: "rgba(57,255,20,0.28)",
  },
  linkText: {
    color: "#39FF14",
    fontSize: 15,
    fontWeight: "700",
    fontFamily: "Inter_700Bold",
    textAlign: "center",
    letterSpacing: 0.3,
  },
});
