import { useEffect, useState } from "react";
import {
  ActivityIndicator,
  Keyboard,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TouchableWithoutFeedback,
  View,
} from "react-native";
import { useRouter } from "expo-router";
import * as Haptics from "expo-haptics";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { isSessionActive, setSessionActive } from "../lib/session";

export default function LoginScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const [checking, setChecking] = useState(true);
  const [signingIn, setSigningIn] = useState(false);

  useEffect(() => {
    let mounted = true;
    isSessionActive().then((active) => {
      if (!mounted) return;
      if (active) router.replace("/dashboard");
      else setChecking(false);
    });
    return () => { mounted = false; };
  }, []);

  async function handleSignIn() {
    if (signingIn) return;
    setSigningIn(true);
    await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    await setSessionActive();
    router.replace("/dashboard");
  }

  if (checking) {
    return (
      <View style={[styles.root, styles.center]}>
        <ActivityIndicator color="#39FF14" size="large" />
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      style={styles.root}
      behavior={Platform.OS === "ios" ? "padding" : "height"}
      keyboardVerticalOffset={0}
    >
      <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
        <ScrollView
          contentContainerStyle={[
            styles.scroll,
            {
              paddingTop: insets.top + 40,
              paddingBottom: insets.bottom + 32,
            },
          ]}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          <View style={styles.brandRow}>
            <View style={styles.brandOrb}>
              <Text style={styles.brandIcon}>◉</Text>
            </View>
          </View>

          <Text style={styles.title}>MAURIMESH</Text>
          <Text style={styles.subtitle}>Sovereign Mesh Protocol</Text>

          <View style={styles.card}>
            <View style={styles.cardHeader}>
              <View style={styles.statusDot} />
              <Text style={styles.statusLabel}>SECURE GATEWAY</Text>
            </View>

            <Text style={styles.cardTitle}>Sign In</Text>
            <Text style={styles.cardText}>
              Access the private mesh dashboard and activate trusted node authentication.
            </Text>

            <Pressable
              onPress={handleSignIn}
              disabled={signingIn}
              style={({ pressed }) => [
                styles.button,
                pressed && styles.buttonPressed,
                signingIn && styles.buttonDisabled,
              ]}
            >
              {signingIn
                ? <ActivityIndicator color="#050816" />
                : <Text style={styles.buttonText}>Enter Mesh</Text>
              }
            </Pressable>
          </View>

          <Text style={styles.footer}>MauriMesh Core v1.4.2-alpha</Text>
        </ScrollView>
      </TouchableWithoutFeedback>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: "#050816",
  },
  center: {
    alignItems: "center",
    justifyContent: "center",
  },
  scroll: {
    flexGrow: 1,
    paddingHorizontal: 28,
  },
  brandRow: {
    alignItems: "center",
    marginBottom: 32,
  },
  brandOrb: {
    width: 96,
    height: 96,
    borderRadius: 48,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "rgba(57,255,20,0.10)",
    borderWidth: 1,
    borderColor: "rgba(57,255,20,0.32)",
    shadowColor: "#39FF14",
    shadowOpacity: 0.35,
    shadowRadius: 28,
    elevation: 10,
  },
  brandIcon: {
    color: "#39FF14",
    fontSize: 46,
    fontWeight: "900",
  },
  title: {
    color: "#FFFFFF",
    fontSize: 40,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
    letterSpacing: 6,
    textAlign: "center",
  },
  subtitle: {
    marginTop: 8,
    color: "#39FF14",
    fontSize: 13,
    fontWeight: "800",
    fontFamily: "Inter_700Bold",
    letterSpacing: 5,
    textTransform: "uppercase",
    textAlign: "center",
  },
  card: {
    marginTop: 48,
    padding: 28,
    borderRadius: 32,
    backgroundColor: "#101827",
    borderWidth: 1,
    borderColor: "rgba(57,255,20,0.20)",
    shadowColor: "#39FF14",
    shadowOpacity: 0.12,
    shadowRadius: 20,
    elevation: 6,
  },
  cardHeader: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    marginBottom: 20,
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: "#39FF14",
    shadowColor: "#39FF14",
    shadowOpacity: 0.8,
    shadowRadius: 6,
  },
  statusLabel: {
    color: "#39FF14",
    fontSize: 11,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
    letterSpacing: 4,
  },
  cardTitle: {
    color: "#FFFFFF",
    fontSize: 32,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
  },
  cardText: {
    marginTop: 12,
    color: "#94A3B8",
    fontSize: 16,
    lineHeight: 26,
    fontWeight: "500",
    fontFamily: "Inter_500Medium",
  },
  button: {
    marginTop: 28,
    height: 60,
    borderRadius: 20,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#39FF14",
    shadowColor: "#39FF14",
    shadowOpacity: 0.40,
    shadowRadius: 20,
    elevation: 8,
  },
  buttonPressed: {
    opacity: 0.84,
    transform: [{ scale: 0.97 }],
  },
  buttonDisabled: {
    opacity: 0.55,
  },
  buttonText: {
    color: "#050816",
    fontSize: 18,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
    letterSpacing: 1,
  },
  footer: {
    marginTop: "auto",
    paddingTop: 32,
    textAlign: "center",
    color: "rgba(255,255,255,0.20)",
    fontSize: 13,
    fontWeight: "700",
    fontFamily: "Inter_700Bold",
  },
});
