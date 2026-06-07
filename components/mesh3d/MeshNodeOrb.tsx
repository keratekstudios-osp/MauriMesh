import { useEffect, useRef } from "react";
import { Animated, StyleSheet, View } from "react-native";
import { NodeStatus } from "@/lib/mesh-core/types";

export interface MeshNodeOrbProps {
  nodeId: string;
  displayName: string;
  status: NodeStatus;
  size?: number;
  active?: boolean;
}

function statusColor(status: NodeStatus): string {
  switch (status) {
    case NodeStatus.SELF:     return "#10b981";
    case NodeStatus.TRUSTED:  return "#21c45d";
    case NodeStatus.RELAY:    return "#f59e0b";
    case NodeStatus.UNKNOWN:  return "#6b7280";
    case NodeStatus.DEGRADED: return "#ef4444";
    default:                  return "#6b7280";
  }
}

function statusLabel(status: NodeStatus): string {
  return status;
}

export function MeshNodeOrb({ status, size = 48, active = false }: MeshNodeOrbProps) {
  const glowAnim = useRef(new Animated.Value(0)).current;
  const pulseAnim = useRef(new Animated.Value(1)).current;

  const color = statusColor(status);

  useEffect(() => {
    if (active) {
      Animated.loop(
        Animated.sequence([
          Animated.timing(glowAnim, { toValue: 1, duration: 900, useNativeDriver: true }),
          Animated.timing(glowAnim, { toValue: 0, duration: 900, useNativeDriver: true }),
        ])
      ).start();
      Animated.loop(
        Animated.sequence([
          Animated.timing(pulseAnim, { toValue: 1.12, duration: 700, useNativeDriver: true }),
          Animated.timing(pulseAnim, { toValue: 1.0, duration: 700, useNativeDriver: true }),
        ])
      ).start();
    } else {
      glowAnim.stopAnimation();
      pulseAnim.stopAnimation();
      glowAnim.setValue(0);
      pulseAnim.setValue(1);
    }
  }, [active, glowAnim, pulseAnim]);

  const glowOpacity = glowAnim.interpolate({ inputRange: [0, 1], outputRange: [0.2, 0.7] });

  return (
    <Animated.View style={[styles.wrapper, { transform: [{ scale: pulseAnim }] }]}>
      <Animated.View
        style={[
          styles.glowRing,
          {
            width: size + 16,
            height: size + 16,
            borderRadius: (size + 16) / 2,
            borderColor: color,
            opacity: glowOpacity,
          },
        ]}
      />
      <View
        style={[
          styles.orb,
          {
            width: size,
            height: size,
            borderRadius: size / 2,
            backgroundColor: color + "22",
            borderColor: color,
          },
        ]}
      >
        <View
          style={[
            styles.inner,
            {
              width: size * 0.55,
              height: size * 0.55,
              borderRadius: (size * 0.55) / 2,
              backgroundColor: color,
            },
          ]}
        />
      </View>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    alignItems: "center",
    justifyContent: "center",
  },
  glowRing: {
    position: "absolute",
    borderWidth: 2,
  },
  orb: {
    borderWidth: 1.5,
    alignItems: "center",
    justifyContent: "center",
  },
  inner: {
    opacity: 0.85,
  },
});

export { statusColor, statusLabel };
