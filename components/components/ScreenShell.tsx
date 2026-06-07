import { ReactNode } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import * as Haptics from "expo-haptics";

export default function ScreenShell({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle?: string;
  children: ReactNode;
}) {
  const router = useRouter();
  const insets = useSafeAreaInsets();

  async function back() {
    await Haptics.selectionAsync();
    router.back();
  }

  return (
    <ScrollView
      style={styles.root}
      contentContainerStyle={{
        paddingTop: insets.top + 20,
        paddingBottom: insets.bottom + 48,
      }}
      showsVerticalScrollIndicator={false}
    >
      <View style={styles.header}>
        <Pressable
          onPress={back}
          style={({ pressed }) => [styles.back, pressed && styles.backPressed]}
        >
          <Text style={styles.backText}>‹</Text>
        </Pressable>

        <View style={{ flex: 1 }}>
          <Text style={styles.title}>{title}</Text>
          {!!subtitle && <Text style={styles.subtitle}>{subtitle}</Text>}
        </View>
      </View>

      <View style={styles.body}>{children}</View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: "#050816",
  },
  header: {
    paddingHorizontal: 24,
    flexDirection: "row",
    alignItems: "center",
    gap: 14,
    paddingBottom: 8,
    borderBottomWidth: 1,
    borderColor: "rgba(255,255,255,0.06)",
  },
  back: {
    width: 44,
    height: 44,
    borderRadius: 13,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#101827",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.08)",
  },
  backPressed: {
    opacity: 0.7,
    transform: [{ scale: 0.95 }],
  },
  backText: {
    color: "#39FF14",
    fontSize: 36,
    lineHeight: 38,
    fontWeight: "400",
  },
  title: {
    color: "#FFFFFF",
    fontSize: 26,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
  },
  subtitle: {
    marginTop: 3,
    color: "#94A3B8",
    fontSize: 13,
    fontWeight: "600",
    fontFamily: "Inter_600SemiBold",
  },
  body: {
    paddingHorizontal: 24,
    paddingTop: 28,
  },
});
