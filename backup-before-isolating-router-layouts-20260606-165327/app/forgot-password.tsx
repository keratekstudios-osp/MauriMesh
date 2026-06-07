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
import { MeshCard } from "../src/components/ui/MeshCard";

export default function ForgotPasswordScreen() {
  const router   = useRouter();
  const insets   = useSafeAreaInsets();
  const [seed, setSeed]       = useState("");
  const [loading, setLoading] = useState(false);
  const [sent, setSent]       = useState(false);

  function handleRecover() {
    if (loading || !seed.trim()) return;
    setLoading(true);
    setTimeout(() => { setLoading(false); setSent(true); }, 1000);
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

          <Text style={styles.title}>Recover Access</Text>
          <Text style={styles.subtitle}>
            Enter your 12-word seed phrase to restore your mesh identity.
          </Text>

          {sent ? (
            <MeshCard accentColor={DS.greenBorder} glow style={styles.successCard}>
              <Text style={styles.successIcon}>✓</Text>
              <Text style={styles.successTitle}>Identity Verified</Text>
              <Text style={styles.successText}>
                Your seed phrase matched. You can now set a new passphrase.
              </Text>
              <MeshButton
                label="Set New Passphrase"
                onPress={() => router.replace("/login")}
                fullWidth
                style={{ marginTop: spacing.md }}
              />
            </MeshCard>
          ) : (
            <View style={styles.form}>
              <MeshInput
                label="Seed Phrase"
                value={seed}
                onChangeText={setSeed}
                placeholder="word1 word2 word3 … word12"
                multiline
                numberOfLines={4}
                autoCapitalize="none"
                autoCorrect={false}
                hint="12 words, space-separated"
                containerStyle={styles.seedInput}
              />

              <MeshCard
                accentColor={DS.amberBorder}
                style={styles.warningCard}
              >
                <Text style={styles.warningText}>
                  ⚠  Never share your seed phrase with anyone. MauriMesh
                  support will never ask for it.
                </Text>
              </MeshCard>

              <MeshButton
                label="Recover Identity"
                onPress={handleRecover}
                loading={loading}
                disabled={!seed.trim()}
                fullWidth
              />
            </View>
          )}
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
  title: {
    color:        DS.textPrimary,
    fontSize:     typography.sizes["2xl"],
    fontFamily:   typography.fonts.bold,
    marginBottom: spacing.xs,
  },
  subtitle: {
    color:        DS.textSecondary,
    fontSize:     typography.sizes.base,
    fontFamily:   typography.fonts.regular,
    marginBottom: spacing.xl,
    lineHeight:   typography.sizes.base * typography.lineHeight.relaxed,
  },
  form:      { gap: spacing.md },
  seedInput: {},
  warningCard: { borderColor: DS.amberBorder },
  warningText: {
    color:      DS.warningAmber,
    fontSize:   typography.sizes.sm,
    fontFamily: typography.fonts.regular,
    lineHeight: typography.sizes.sm * typography.lineHeight.relaxed,
  },
  successCard: { alignItems: "center", gap: spacing.xs },
  successIcon: {
    fontSize:  40,
    color:     DS.mauriGreen,
    textAlign: "center",
  },
  successTitle: {
    color:      DS.textPrimary,
    fontSize:   typography.sizes.xl,
    fontFamily: typography.fonts.bold,
    textAlign:  "center",
  },
  successText: {
    color:      DS.textSecondary,
    fontSize:   typography.sizes.sm,
    fontFamily: typography.fonts.regular,
    textAlign:  "center",
    lineHeight: typography.sizes.sm * typography.lineHeight.relaxed,
  },
});
