import { ActivityIndicator, StyleSheet, Text, View } from "react-native";
import { StatusBar } from "expo-status-bar";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { DS } from "../src/design-system/colors";
import { typography } from "../src/design-system/typography";
import { radius } from "../src/design-system/radius";
import { spacing } from "../src/design-system/spacing";

export default function SplashScreen() {
  const insets = useSafeAreaInsets();

  return (
    <View
      style={[
        styles.root,
        { paddingTop: insets.top, paddingBottom: insets.bottom },
      ]}
    >
      <StatusBar style="light" />

      <View style={styles.center}>
        <View style={styles.orb}>
          <Text style={styles.orbIcon}>◉</Text>
        </View>
        <Text style={styles.title}>MAURIMESH</Text>
        <Text style={styles.tagline}>SOVEREIGN MESH PROTOCOL</Text>
        <ActivityIndicator
          color={DS.mauriGreen}
          style={styles.spinner}
        />
        <Text style={styles.status}>Initializing mesh engine…</Text>
      </View>

      <Text style={styles.footer}>MauriMesh Core v1.4.2-alpha</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex:            1,
    backgroundColor: DS.deepSpace,
    alignItems:      "center",
    justifyContent:  "space-between",
    paddingHorizontal: spacing.lg,
    paddingVertical:   spacing.xl,
  },
  center: {
    flex:           1,
    alignItems:     "center",
    justifyContent: "center",
    gap:            spacing.sm,
  },
  orb: {
    width:           96,
    height:          96,
    borderRadius:    radius.full,
    backgroundColor: DS.greenDim,
    borderWidth:     1,
    borderColor:     DS.greenBorder,
    alignItems:      "center",
    justifyContent:  "center",
    shadowColor:     DS.mauriGreen,
    shadowOpacity:   0.40,
    shadowRadius:    32,
    elevation:       12,
    marginBottom:    spacing.md,
  },
  orbIcon: {
    color:     DS.mauriGreen,
    fontSize:  46,
    fontFamily: typography.fonts.bold,
  },
  title: {
    color:         DS.textPrimary,
    fontSize:      typography.sizes["4xl"],
    fontFamily:    typography.fonts.bold,
    letterSpacing: typography.tracking.widest,
    textAlign:     "center",
  },
  tagline: {
    color:         DS.mauriGreen,
    fontSize:      typography.sizes.sm,
    fontFamily:    typography.fonts.bold,
    letterSpacing: typography.tracking.wider,
    textTransform: "uppercase",
    textAlign:     "center",
  },
  spinner: {
    marginTop: spacing.xl,
  },
  status: {
    color:      DS.textSecondary,
    fontSize:   typography.sizes.sm,
    fontFamily: typography.fonts.regular,
    textAlign:  "center",
    marginTop:  spacing.xs,
  },
  footer: {
    color:         DS.faintText,
    fontSize:      typography.sizes.sm,
    fontFamily:    typography.fonts.bold,
    textAlign:     "center",
    letterSpacing: typography.tracking.normal,
  },
});
