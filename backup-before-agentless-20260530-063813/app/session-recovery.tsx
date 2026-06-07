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
import { safeNavigate } from "../lib/safeNavigate";
import { StatusBar } from "expo-status-bar";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { DS } from "../src/design-system/colors";
import { typography } from "../src/design-system/typography";
import { radius } from "../src/design-system/radius";
import { spacing } from "../src/design-system/spacing";
import { MeshInput } from "../src/components/ui/MeshInput";
import { MeshButton } from "../src/components/ui/MeshButton";

export default function SessionRecoveryScreen() {
  const router   = useRouter();
  const insets   = useSafeAreaInsets();
  const [code, setCode]       = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError]     = useState<string | undefined>();

  function handleRestore() {
    if (loading || !code.trim()) return;
    setError(undefined);
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      if (code.trim().length < 8) {
        setError("Invalid recovery code. Please check and try again.");
      } else {
        router.replace("/dashboard");
      }
    }, 900);
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
            { paddingTop: insets.top + 24, paddingBottom: insets.bottom + 32 },
          ]}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          <Pressable onPress={() => router.back()} style={styles.backBtn}>
            <Text style={styles.backText}>‹  Back</Text>
          </Pressable>

          <View style={styles.iconWrap}>
            <Text style={styles.icon}>⟳</Text>
          </View>
          <Text style={styles.title}>Session Recovery</Text>
          <Text style={styles.subtitle}>
            Enter the recovery code provided when you set up your mesh identity.
          </Text>

          <View style={styles.form}>
            <MeshInput
              label="Recovery Code"
              value={code}
              onChangeText={(t) => { setCode(t); setError(undefined); }}
              placeholder="MM-RECOVERY-XXXXXXXX"
              autoCapitalize="characters"
              autoCorrect={false}
              error={error}
            />

            <MeshButton
              label="Restore Session"
              onPress={handleRestore}
              loading={loading}
              disabled={!code.trim()}
              fullWidth
            />

            <MeshButton
              label="Use Seed Phrase Instead"
              onPress={() => safeNavigate(router, "/forgot-password")}
              variant="ghost"
              fullWidth
            />
          </View>

          <Text style={styles.help}>
            Recovery codes are generated during initial mesh identity setup.
            Contact your mesh administrator if you have lost access.
          </Text>
        </ScrollView>
      </TouchableWithoutFeedback>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  root:    { flex: 1, backgroundColor: DS.deepSpace },
  scroll:  { flexGrow: 1, paddingHorizontal: spacing.lg },
  backBtn: { alignSelf: "flex-start", marginBottom: spacing.xl },
  backText: {
    color:     DS.mauriGreen,
    fontSize:  typography.sizes.base,
    fontFamily: typography.fonts.semibold,
  },
  iconWrap: { alignItems: "center", marginBottom: spacing.md },
  icon: {
    fontSize:  60,
    color:     DS.meshBlue,
    textAlign: "center",
  },
  title: {
    color:        DS.textPrimary,
    fontSize:     typography.sizes["2xl"],
    fontFamily:   typography.fonts.bold,
    textAlign:    "center",
    marginBottom: spacing.xs,
  },
  subtitle: {
    color:        DS.textSecondary,
    fontSize:     typography.sizes.base,
    fontFamily:   typography.fonts.regular,
    textAlign:    "center",
    lineHeight:   typography.sizes.base * typography.lineHeight.relaxed,
    marginBottom: spacing.xl,
  },
  form: { gap: spacing.md },
  help: {
    color:      DS.mutedText,
    fontSize:   typography.sizes.xs,
    fontFamily: typography.fonts.regular,
    textAlign:  "center",
    lineHeight: typography.sizes.xs * typography.lineHeight.relaxed,
    marginTop:  spacing.lg,
  },
});
