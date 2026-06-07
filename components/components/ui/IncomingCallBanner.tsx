import { Feather } from "@expo/vector-icons";
import { useEffect, useRef } from "react";
import { Animated, Pressable, StyleSheet, Text, View } from "react-native";

import { useColors } from "@/hooks/useColors";
import type { IncomingCall } from "@/lib/store/meshStore";

interface Props {
  call: IncomingCall;
  onAccept: () => void;
  onDecline: () => void;
}

export function IncomingCallBanner({ call, onAccept, onDecline }: Props) {
  const colors = useColors();
  const slideAnim = useRef(new Animated.Value(-120)).current;
  const pulseAnim = useRef(new Animated.Value(1)).current;

  useEffect(() => {
    Animated.spring(slideAnim, {
      toValue: 0,
      tension: 65,
      friction: 10,
      useNativeDriver: true,
    }).start();

    const pulse = Animated.loop(
      Animated.sequence([
        Animated.timing(pulseAnim, {
          toValue: 1.15,
          duration: 600,
          useNativeDriver: true,
        }),
        Animated.timing(pulseAnim, {
          toValue: 1,
          duration: 600,
          useNativeDriver: true,
        }),
      ])
    );
    pulse.start();
    return () => pulse.stop();
  }, [slideAnim, pulseAnim]);

  const dismiss = (cb: () => void) => {
    Animated.timing(slideAnim, {
      toValue: -120,
      duration: 220,
      useNativeDriver: true,
    }).start(cb);
  };

  const styles = makeStyles(colors);

  return (
    <Animated.View
      style={[styles.container, { transform: [{ translateY: slideAnim }] }]}
    >
      <View style={styles.inner}>
        {/* Icon + caller info */}
        <View style={styles.left}>
          <Animated.View
            style={[styles.iconRing, { transform: [{ scale: pulseAnim }] }]}
          >
            <Feather
              name={call.mode === "video" ? "video" : "phone"}
              size={22}
              color={colors.primary}
            />
          </Animated.View>
          <View>
            <Text style={styles.label}>
              Incoming {call.mode === "video" ? "Video" : "Audio"} Call
            </Text>
            <Text style={styles.caller} numberOfLines={1}>
              {call.from}
            </Text>
          </View>
        </View>

        {/* Action buttons */}
        <View style={styles.actions}>
          <Pressable
            style={({ pressed }) => [
              styles.btn,
              styles.btnDecline,
              pressed && styles.btnPressed,
            ]}
            onPress={() => dismiss(onDecline)}
            accessibilityLabel="Decline call"
          >
            <Feather name="phone-off" size={18} color="#fff" />
          </Pressable>
          <Pressable
            style={({ pressed }) => [
              styles.btn,
              styles.btnAccept,
              pressed && styles.btnPressed,
            ]}
            onPress={() => dismiss(onAccept)}
            accessibilityLabel="Accept call"
          >
            <Feather name="phone" size={18} color="#fff" />
          </Pressable>
        </View>
      </View>
    </Animated.View>
  );
}

function makeStyles(colors: ReturnType<typeof useColors>) {
  return StyleSheet.create({
    container: {
      position: "absolute",
      top: 0,
      left: 0,
      right: 0,
      zIndex: 100,
      paddingHorizontal: 12,
      paddingTop: 12,
      paddingBottom: 8,
    },
    inner: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      backgroundColor: colors.card,
      borderRadius: 18,
      paddingVertical: 12,
      paddingHorizontal: 16,
      borderWidth: 1,
      borderColor: colors.primary + "40",
      shadowColor: colors.primary,
      shadowOffset: { width: 0, height: 4 },
      shadowOpacity: 0.25,
      shadowRadius: 12,
      elevation: 8,
      gap: 12,
    },
    left: {
      flexDirection: "row",
      alignItems: "center",
      gap: 12,
      flex: 1,
    },
    iconRing: {
      width: 48,
      height: 48,
      borderRadius: 24,
      backgroundColor: colors.primary + "1a",
      borderWidth: 2,
      borderColor: colors.primary + "50",
      alignItems: "center",
      justifyContent: "center",
    },
    label: {
      fontSize: 11,
      color: colors.mutedForeground,
      fontFamily: "Inter_400Regular",
      letterSpacing: 0.3,
    },
    caller: {
      fontSize: 15,
      fontWeight: "600" as const,
      color: colors.foreground,
      fontFamily: "Inter_600SemiBold",
      letterSpacing: -0.2,
    },
    actions: {
      flexDirection: "row",
      gap: 10,
    },
    btn: {
      width: 44,
      height: 44,
      borderRadius: 22,
      alignItems: "center",
      justifyContent: "center",
    },
    btnDecline: {
      backgroundColor: "#ef4444",
    },
    btnAccept: {
      backgroundColor: "#22c55e",
    },
    btnPressed: {
      opacity: 0.75,
      transform: [{ scale: 0.92 }],
    },
  });
}
