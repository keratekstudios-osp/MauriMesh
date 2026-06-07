import { useEffect, useRef } from "react";
import { Animated, StyleSheet } from "react-native";

export interface MeshSignalPulseProps {
  from: { x: number; y: number };
  to: { x: number; y: number };
  sendPulse: boolean;
  color?: string;
  containerWidth: number;
  containerHeight: number;
  onComplete?: () => void;
}

export function MeshSignalPulse({
  from,
  to,
  sendPulse,
  color = "#21c45d",
  containerWidth,
  containerHeight,
  onComplete,
}: MeshSignalPulseProps) {
  const progress = useRef(new Animated.Value(0)).current;
  const opacity = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (!sendPulse) return;

    progress.setValue(0);
    opacity.setValue(1);

    Animated.sequence([
      Animated.timing(progress, {
        toValue: 1,
        duration: 800,
        useNativeDriver: false,
      }),
      Animated.timing(opacity, {
        toValue: 0,
        duration: 200,
        useNativeDriver: false,
      }),
    ]).start(() => {
      onComplete?.();
    });
  }, [sendPulse, progress, opacity, onComplete]);

  const left = progress.interpolate({
    inputRange: [0, 1],
    outputRange: [
      from.x * containerWidth,
      to.x * containerWidth,
    ],
  });

  const top = progress.interpolate({
    inputRange: [0, 1],
    outputRange: [
      from.y * containerHeight,
      to.y * containerHeight,
    ],
  });

  return (
    <Animated.View
      style={[
        styles.dot,
        {
          left,
          top,
          backgroundColor: color,
          opacity,
        },
      ]}
    />
  );
}

const styles = StyleSheet.create({
  dot: {
    position: "absolute",
    width: 10,
    height: 10,
    borderRadius: 5,
    marginLeft: -5,
    marginTop: -5,
    shadowColor: "#21c45d",
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.9,
    shadowRadius: 6,
    elevation: 6,
  },
});
