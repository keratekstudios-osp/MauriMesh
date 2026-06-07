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

export default function SignUpScreen() {
  const router  = useRouter();
  const insets  = useSafeAreaInsets();
  const [displayName, setDisplayName]     = useState("");
  const [passphrase, setPassphrase]       = useState("");
  const [confirmPass, setConfirmPass]     = useState("");
  const [inviteCode, setInviteCode]       = useState("");
  const [loading, setLoading]             = useState(false);

  function handleCreate() {
    if (loading) return;
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      router.replace("/login");
    }, 1200);
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
          <Pressable
            onPress={() => router.back()}
            style={styles.backBtn}
          >
            <Text style={styles.backText}>‹  Back</Text>
          </Pressable>

          <Text style={styles.title}>Create Account</Text>
          <Text style={styles.subtitle}>Join the sovereign mesh network</Text>

          <View style={styles.form}>
            <MeshInput
              label="Display Name"
              value={displayName}
              onChangeText={setDisplayName}
              placeholder="e.g. Kupe-Node-1"
              autoCapitalize="words"
              autoCorrect={false}
            />
            <MeshInput
              label="Passphrase"
              value={passphrase}
              onChangeText={setPassphrase}
              placeholder="Strong passphrase"
              secureTextEntry
              autoCapitalize="none"
            />
            <MeshInput
              label="Confirm Passphrase"
              value={confirmPass}
              onChangeText={setConfirmPass}
              placeholder="Re-enter passphrase"
              secureTextEntry
              autoCapitalize="none"
              error={
                confirmPass.length > 0 && confirmPass !== passphrase
                  ? "Passphrases do not match"
                  : undefined
              }
            />
            <MeshInput
              label="Invite Code (optional)"
              value={inviteCode}
              onChangeText={setInviteCode}
              placeholder="MM-XXXX-XXXX"
              autoCapitalize="characters"
              autoCorrect={false}
              hint="Provided by your mesh administrator"
            />
          </View>

          <MeshButton
            label="Create Mesh Identity"
            onPress={handleCreate}
            loading={loading}
            fullWidth
            style={styles.cta}
          />

          <Text style={styles.legal}>
            By creating an account you agree to sovereign mesh usage terms.
            All communications are end-to-end encrypted.
          </Text>
        </ScrollView>
      </TouchableWithoutFeedback>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  root:   { flex: 1, backgroundColor: DS.deepSpace },
  scroll: { flexGrow: 1, paddingHorizontal: spacing.lg },
  backBtn: { alignSelf: "flex-start", marginBottom: spacing.xl },
  backText: {
    color:     DS.mauriGreen,
    fontSize:  typography.sizes.base,
    fontFamily: typography.fonts.semibold,
  },
  title: {
    color:      DS.textPrimary,
    fontSize:   typography.sizes["2xl"],
    fontFamily: typography.fonts.bold,
    marginBottom: spacing.xs,
  },
  subtitle: {
    color:        DS.textSecondary,
    fontSize:     typography.sizes.base,
    fontFamily:   typography.fonts.regular,
    marginBottom: spacing.xl,
  },
  form: { gap: spacing.md },
  cta: { marginTop: spacing.xl },
  legal: {
    color:      DS.mutedText,
    fontSize:   typography.sizes.xs,
    fontFamily: typography.fonts.regular,
    textAlign:  "center",
    lineHeight: typography.sizes.xs * typography.lineHeight.relaxed,
    marginTop:  spacing.md,
  },
});
