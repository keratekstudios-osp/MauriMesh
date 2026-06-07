import { useState } from "react";
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TouchableWithoutFeedback,
  Keyboard,
  View,
} from "react-native";
import { useRouter } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { DS } from "../src/design-system/colors";
import { typography } from "../src/design-system/typography";
import { radius } from "../src/design-system/radius";
import { spacing } from "../src/design-system/spacing";
import { MeshInput } from "../src/components/ui/MeshInput";
import { MeshButton } from "../src/components/ui/MeshButton";
import { MeshStatusPill } from "../src/components/ui/MeshStatusPill";
import { safeNavigate } from "../lib/safeNavigate";

export default function BiometricUnlockScreen() {
  const router  = useRouter();
  const insets  = useSafeAreaInsets();
  const [showPin, setShowPin]   = useState(false);
  const [pin, setPin]           = useState("");
  const [loading, setLoading]   = useState(false);
  const [bioError, setBioError] = useState(false);

  function handleBiometric() {
    setLoading(true);
    setBioError(false);
    setTimeout(() => {
      setLoading(false);
      // Show error pill first so the user sees biometric failed
      setBioError(true);
      // Then auto-transition to PIN fallback after a brief pause
      setTimeout(() => setShowPin(true), 1500);
    }, 1200);
  }

  function handlePin() {
    if (!pin || pin.length < 4) return;
    setLoading(true);
    setTimeout(() => { setLoading(false); router.replace("/dashboard"); }, 800);
  }

  return (
    <KeyboardAvoidingView
      style={styles.root}
      behavior={Platform.OS === "ios" ? "padding" : "height"}
    >
      <StatusBar style="light" />
      <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
        <ScrollView
          contentContainerStyle={[
            styles.scroll,
            { paddingTop: insets.top + 32, paddingBottom: insets.bottom + 32 },
          ]}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          <View style={styles.center}>
            <Pressable
              onPress={handleBiometric}
              style={({ pressed }) => [
                styles.bioOrb,
                pressed && styles.bioOrbPressed,
                loading && styles.bioOrbScanning,
              ]}
              disabled={loading || showPin}
            >
              <Text style={styles.bioIcon}>
                {Platform.OS === "ios" ? "⊙" : "◉"}
              </Text>
            </Pressable>

            <Text style={styles.title}>Biometric Unlock</Text>
            <Text style={styles.subtitle}>
              {showPin
                ? "Biometric unavailable — enter your PIN"
                : "Tap the orb to authenticate with Face ID or Fingerprint"}
            </Text>

            {bioError && !showPin ? (
              <MeshStatusPill
                label="Biometric failed"
                variant="error"
                style={styles.pill}
              />
            ) : null}
          </View>

          {showPin ? (
            <View style={styles.pinForm}>
              <MeshInput
                label="PIN"
                value={pin}
                onChangeText={setPin}
                placeholder="••••"
                keyboardType="numeric"
                secureTextEntry
                maxLength={8}
              />
              <MeshButton
                label="Unlock"
                onPress={handlePin}
                loading={loading}
                disabled={pin.length < 4}
                fullWidth
              />
            </View>
          ) : (
            <View style={styles.actions}>
              <MeshButton
                label={loading ? "Scanning…" : "Use Biometrics"}
                onPress={handleBiometric}
                loading={loading}
                fullWidth
              />
              <MeshButton
                label="Use PIN instead"
                onPress={() => setShowPin(true)}
                variant="ghost"
                fullWidth
              />
            </View>
          )}

          <Pressable onPress={() => safeNavigate(router, "/session-recovery")}>
            <Text style={styles.lostAccess}>Lost access? Recover session →</Text>
          </Pressable>
        </ScrollView>
      </TouchableWithoutFeedback>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  root:   { flex: 1, backgroundColor: DS.deepSpace },
  scroll: { flexGrow: 1, paddingHorizontal: spacing.lg },
  center: { alignItems: "center", marginBottom: spacing.xl, gap: spacing.sm },
  bioOrb: {
    width:           120,
    height:          120,
    borderRadius:    radius.full,
    backgroundColor: DS.greenDim,
    borderWidth:     2,
    borderColor:     DS.greenBorderBright,
    alignItems:      "center",
    justifyContent:  "center",
    shadowColor:     DS.mauriGreen,
    shadowOpacity:   0.50,
    shadowRadius:    36,
    elevation:       14,
    marginBottom:    spacing.lg,
  },
  bioOrbPressed:  { transform: [{ scale: 0.94 }], opacity: 0.80 },
  bioOrbScanning: { borderColor: DS.meshBlue, shadowColor: DS.meshBlue },
  bioIcon: {
    fontSize:  58,
    color:     DS.mauriGreen,
    lineHeight: 64,
  },
  title: {
    color:      DS.textPrimary,
    fontSize:   typography.sizes["2xl"],
    fontFamily: typography.fonts.bold,
    textAlign:  "center",
  },
  subtitle: {
    color:      DS.textSecondary,
    fontSize:   typography.sizes.base,
    fontFamily: typography.fonts.regular,
    textAlign:  "center",
    lineHeight: typography.sizes.base * typography.lineHeight.relaxed,
    maxWidth:   260,
  },
  pill:    { marginTop: spacing.xs },
  pinForm: { gap: spacing.md },
  actions: { gap: spacing.sm },
  lostAccess: {
    color:      DS.mauriGreen,
    fontSize:   typography.sizes.sm,
    fontFamily: typography.fonts.semibold,
    textAlign:  "center",
    marginTop:  spacing.xl,
  },
});
