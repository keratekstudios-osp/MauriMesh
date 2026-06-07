import { useEffect, useRef } from "react";
import { Animated, StyleSheet, View } from "react-native";

export interface BeamPosition {
  x1: number;
  y1: number;
  x2: number;
  y2: number;
}

export interface MeshRouteBeamProps {
  from: { x: number; y: number };
  to: { x: number; y: number };
  active?: boolean;
  color?: string;
  containerWidth: number;
  containerHeight: number;
  /**
   * RouteScore [0, 1] — drives beam thickness and glow intensity.
   * 0 = faint thin line (weak / unknown route)
   * 1 = thick bright beam (proven reliable route)
   */
  routeScore?: number;
}

export function MeshRouteBeam({
  from,
  to,
  active = false,
  color = "#10b981",
  containerWidth,
  containerHeight,
  routeScore = 0.5,
}: MeshRouteBeamProps) {
  const opacityAnim = useRef(new Animated.Value(0.25)).current;

  // Clamp score to [0, 1]
  const score = Math.max(0, Math.min(1, routeScore));

  // Beam thickness: 1 px (score=0) → 4 px (score=1)
  const beamHeight = 1 + score * 3;

  // Base (idle) opacity scales with score; animated ceiling also scales
  const baseOpacity = 0.12 + score * 0.28;     // 0.12 → 0.40
  const peakOpacity = 0.40 + score * 0.55;      // 0.40 → 0.95

  useEffect(() => {
    if (active) {
      Animated.loop(
        Animated.sequence([
          Animated.timing(opacityAnim, { toValue: peakOpacity, duration: 600, useNativeDriver: true }),
          Animated.timing(opacityAnim, { toValue: baseOpacity, duration: 600, useNativeDriver: true }),
        ])
      ).start();
    } else {
      opacityAnim.stopAnimation();
      opacityAnim.setValue(baseOpacity);
    }
  }, [active, opacityAnim, baseOpacity, peakOpacity]);

  const dx = to.x * containerWidth - from.x * containerWidth;
  const dy = to.y * containerHeight - from.y * containerHeight;
  const length = Math.sqrt(dx * dx + dy * dy);
  const angle = Math.atan2(dy, dx) * (180 / Math.PI);

  const left = from.x * containerWidth;
  const top = from.y * containerHeight;

  return (
    <Animated.View
      style={[
        styles.beam,
        {
          width: length,
          height: beamHeight,
          left,
          top,
          transform: [{ rotate: `${angle}deg` }],
          backgroundColor: color,
          opacity: opacityAnim,
        },
      ]}
    />
  );
}

const styles = StyleSheet.create({
  beam: {
    position: "absolute",
    transformOrigin: "0 50%",
  },
});
