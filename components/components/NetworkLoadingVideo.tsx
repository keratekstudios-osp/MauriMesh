import { useEffect, useRef, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { useVideoPlayer, VideoView } from "expo-video";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  Easing,
  runOnJS,
} from "react-native-reanimated";

// Source is required at module load — metro bundler resolves the asset path.
// eslint-disable-next-line @typescript-eslint/no-require-imports
const VIDEO_SOURCE = require("@/assets/network-connect.mp4");

interface NetworkLoadingVideoProps {
  // True when BLE or bridge connection is established.
  connected: boolean;
}

export function NetworkLoadingVideo({ connected }: NetworkLoadingVideoProps) {
  // Only mount the overlay on the initial render if not yet connected.
  // Once dismissed it never comes back in the same session.
  const [visible, setVisible] = useState(!connected);
  const hasFaded = useRef(false);

  // Opacity shared value — drives the morph fade-out.
  const opacity = useSharedValue(!connected ? 1 : 0);

  // Animated style — must be called unconditionally (hook rule).
  const animStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
  }));

  // Video player — loop so it never freezes while the device connects.
  const player = useVideoPlayer(VIDEO_SOURCE, (p) => {
    p.loop = true;
    if (!connected) {
      p.play();
    }
  });

  // When connection is established, morph-fade the overlay out.
  useEffect(() => {
    if (connected && visible && !hasFaded.current) {
      hasFaded.current = true;

      opacity.value = withTiming(
        0,
        { duration: 700, easing: Easing.out(Easing.cubic) },
        (finished) => {
          if (finished) {
            runOnJS(setVisible)(false);
          }
        },
      );
    }
  }, [connected, visible, opacity]);

  // Once dismissed, render nothing — zero overhead.
  if (!visible) return null;

  return (
    <Animated.View
      style={[StyleSheet.absoluteFillObject, styles.root, animStyle]}
      pointerEvents="none"
    >
      {/* Full-bleed video — looped, no controls */}
      <VideoView
        player={player}
        style={StyleSheet.absoluteFillObject}
        contentFit="cover"
        nativeControls={false}
        allowsPictureInPicture={false}
      />

      {/* Subtle dark veil so underlying content edges don't bleed through */}
      <View style={styles.veil} />

      {/* Connecting label at the bottom */}
      <View style={styles.footer} pointerEvents="none">
        <View style={styles.pill}>
          <View style={styles.pillDot} />
          <Text style={styles.pillText}>CONNECTING TO MESH…</Text>
        </View>
      </View>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  root: {
    zIndex: 200,
    backgroundColor: "#050816",
  },
  veil: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(5,8,22,0.30)",
  },
  footer: {
    position: "absolute",
    bottom: 48,
    left: 0,
    right: 0,
    alignItems: "center",
  },
  pill: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 9999,
    backgroundColor: "rgba(5,8,22,0.70)",
    borderWidth: 1,
    borderColor: "rgba(57,255,20,0.28)",
  },
  pillDot: {
    width: 7,
    height: 7,
    borderRadius: 4,
    backgroundColor: "#39FF14",
    shadowColor: "#39FF14",
    shadowOpacity: 0.9,
    shadowRadius: 6,
    elevation: 3,
  },
  pillText: {
    color: "#39FF14",
    fontSize: 11,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
    letterSpacing: 3,
  },
});
