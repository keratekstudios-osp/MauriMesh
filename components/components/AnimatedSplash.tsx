import { useEffect, useRef } from "react";
import { Animated, Dimensions, StyleSheet, Text, View } from "react-native";

const { width: W, height: H } = Dimensions.get("screen");

const PARTICLE_COUNT = 14;

const PARTICLES = Array.from({ length: PARTICLE_COUNT }, (_, i) => ({
  x:
    (W * (i + 0.5)) / PARTICLE_COUNT +
    (i % 3 === 0 ? -24 : i % 3 === 1 ? 18 : -6),
  y:
    30 +
    ((H - 60) * i) / PARTICLE_COUNT +
    (i % 2 === 0 ? -12 : 14),
  size:       2 + (i % 3),
  driftAmt:   16 + (i % 5) * 7,
  driftMs:    1900 + (i % 6) * 280,
  color:      i % 3 === 0 ? "#00BFFF" : "#39FF14",
  finalAlpha: 0.22 + (i % 4) * 0.13,
  delayMs:    i * 75,
}));

interface Props {
  onComplete: () => void;
}

export function AnimatedSplash({ onComplete }: Props) {
  const particleOpacities = useRef(
    PARTICLES.map(() => new Animated.Value(0))
  ).current;
  const particleDrifts = useRef(
    PARTICLES.map(() => new Animated.Value(0))
  ).current;

  const orbScale    = useRef(new Animated.Value(0)).current;
  const orbOpacity  = useRef(new Animated.Value(0)).current;
  const pulseScale  = useRef(new Animated.Value(1)).current;
  const pulseOpacity = useRef(new Animated.Value(0)).current;
  const pulse2Scale  = useRef(new Animated.Value(1.4)).current;
  const pulse2Opacity = useRef(new Animated.Value(0)).current;

  const titleOpacity    = useRef(new Animated.Value(0)).current;
  const titleY          = useRef(new Animated.Value(16)).current;
  const subtitleOpacity = useRef(new Animated.Value(0)).current;

  const scanY       = useRef(new Animated.Value(-4)).current;
  const scanOpacity = useRef(new Animated.Value(0)).current;
  const exitOpacity = useRef(new Animated.Value(1)).current;

  const pulseLoopRef  = useRef<Animated.CompositeAnimation | null>(null);
  const pulse2LoopRef = useRef<Animated.CompositeAnimation | null>(null);
  const driftLoopRefs = useRef<Animated.CompositeAnimation[]>([]);

  useEffect(() => {
    // ── Particle fade-in ──────────────────────────────────────────────────────
    PARTICLES.forEach((p, i) => {
      Animated.sequence([
        Animated.delay(p.delayMs),
        Animated.timing(particleOpacities[i], {
          toValue:         p.finalAlpha,
          duration:        380,
          useNativeDriver: true,
        }),
      ]).start();
    });

    // ── Particle drift loops ───────────────────────────────────────────────────
    PARTICLES.forEach((p, i) => {
      const loop = Animated.loop(
        Animated.sequence([
          Animated.timing(particleDrifts[i], {
            toValue:         -p.driftAmt,
            duration:        p.driftMs,
            useNativeDriver: true,
          }),
          Animated.timing(particleDrifts[i], {
            toValue:         0,
            duration:        p.driftMs,
            useNativeDriver: true,
          }),
        ])
      );
      driftLoopRefs.current[i] = loop;
      setTimeout(() => loop.start(), p.delayMs + 180);
    });

    // ── Pulse rings ────────────────────────────────────────────────────────────
    const pulseStart = setTimeout(() => {
      pulseLoopRef.current = Animated.loop(
        Animated.parallel([
          Animated.sequence([
            Animated.timing(pulseScale, { toValue: 2.0, duration: 1300, useNativeDriver: true }),
            Animated.timing(pulseScale, { toValue: 1, duration: 1300, useNativeDriver: true }),
          ]),
          Animated.sequence([
            Animated.timing(pulseOpacity, { toValue: 0, duration: 1300, useNativeDriver: true }),
            Animated.timing(pulseOpacity, { toValue: 0.55, duration: 1300, useNativeDriver: true }),
          ]),
        ])
      );
      pulseLoopRef.current.start();
    }, 650);

    const pulse2Start = setTimeout(() => {
      pulse2LoopRef.current = Animated.loop(
        Animated.parallel([
          Animated.sequence([
            Animated.timing(pulse2Scale, { toValue: 2.5, duration: 1600, useNativeDriver: true }),
            Animated.timing(pulse2Scale, { toValue: 1.4, duration: 1600, useNativeDriver: true }),
          ]),
          Animated.sequence([
            Animated.timing(pulse2Opacity, { toValue: 0, duration: 1600, useNativeDriver: true }),
            Animated.timing(pulse2Opacity, { toValue: 0.30, duration: 1600, useNativeDriver: true }),
          ]),
        ])
      );
      pulse2LoopRef.current.start();
    }, 900);

    // ── Main timeline (no infinite loops — has a known end) ───────────────────
    const main = Animated.parallel([
      // Init pulse opacity
      Animated.sequence([
        Animated.delay(650),
        Animated.timing(pulseOpacity, { toValue: 0.55, duration: 80, useNativeDriver: true }),
      ]),
      Animated.sequence([
        Animated.delay(900),
        Animated.timing(pulse2Opacity, { toValue: 0.30, duration: 80, useNativeDriver: true }),
      ]),
      // Orb springs in at 320ms
      Animated.sequence([
        Animated.delay(320),
        Animated.parallel([
          Animated.spring(orbScale, {
            toValue:  1,
            tension:  48,
            friction: 8,
            useNativeDriver: true,
          }),
          Animated.timing(orbOpacity, {
            toValue:         1,
            duration:        400,
            useNativeDriver: true,
          }),
        ]),
      ]),
      // Title fades up at 920ms
      Animated.sequence([
        Animated.delay(920),
        Animated.parallel([
          Animated.timing(titleOpacity, {
            toValue:         1,
            duration:        460,
            useNativeDriver: true,
          }),
          Animated.timing(titleY, {
            toValue:         0,
            duration:        460,
            useNativeDriver: true,
          }),
        ]),
      ]),
      // Subtitle at 1220ms
      Animated.sequence([
        Animated.delay(1220),
        Animated.timing(subtitleOpacity, {
          toValue:         1,
          duration:        360,
          useNativeDriver: true,
        }),
      ]),
      // Scan line sweeps at 1550ms
      Animated.sequence([
        Animated.delay(1550),
        Animated.timing(scanOpacity, {
          toValue:         0.9,
          duration:        80,
          useNativeDriver: true,
        }),
        Animated.timing(scanY, {
          toValue:         H + 4,
          duration:        1100,
          useNativeDriver: true,
        }),
        Animated.timing(scanOpacity, {
          toValue:         0,
          duration:        120,
          useNativeDriver: true,
        }),
      ]),
      // Exit fade at 3100ms → done at ~3480ms
      Animated.sequence([
        Animated.delay(3100),
        Animated.timing(exitOpacity, {
          toValue:         0,
          duration:        380,
          useNativeDriver: true,
        }),
      ]),
    ]);

    main.start(() => {
      pulseLoopRef.current?.stop();
      pulse2LoopRef.current?.stop();
      driftLoopRefs.current.forEach((l) => l.stop());
      clearTimeout(pulseStart);
      clearTimeout(pulse2Start);
      // Always call onComplete — even if animation was interrupted — so the
      // app never stays stuck on the splash screen.
      onComplete();
    });

    return () => {
      main.stop();
      pulseLoopRef.current?.stop();
      pulse2LoopRef.current?.stop();
      driftLoopRefs.current.forEach((l) => l.stop());
      clearTimeout(pulseStart);
      clearTimeout(pulse2Start);
    };
  }, []);

  return (
    <Animated.View style={[styles.root, { opacity: exitOpacity }]}>
      {/* Particle field */}
      {PARTICLES.map((p, i) => (
        <Animated.View
          key={i}
          style={[
            styles.particle,
            {
              left:            p.x,
              top:             p.y,
              width:           p.size,
              height:          p.size,
              borderRadius:    p.size,
              backgroundColor: p.color,
              opacity:         particleOpacities[i],
              transform:       [{ translateY: particleDrifts[i] }],
            },
          ]}
        />
      ))}

      {/* Orb + pulse rings */}
      <View style={styles.orbWrap}>
        {/* Outer cyan pulse ring */}
        <Animated.View
          style={[
            styles.pulseRing,
            styles.pulseRing2,
            {
              opacity:   pulse2Opacity,
              transform: [{ scale: pulse2Scale }],
            },
          ]}
        />
        {/* Inner green pulse ring */}
        <Animated.View
          style={[
            styles.pulseRing,
            {
              opacity:   pulseOpacity,
              transform: [{ scale: pulseScale }],
            },
          ]}
        />
        {/* Orb */}
        <Animated.View
          style={[
            styles.orb,
            {
              opacity:   orbOpacity,
              transform: [{ scale: orbScale }],
            },
          ]}
        >
          <Text style={styles.orbSymbol}>◉</Text>
        </Animated.View>
      </View>

      {/* Title */}
      <Animated.View
        style={[
          styles.titleWrap,
          { opacity: titleOpacity, transform: [{ translateY: titleY }] },
        ]}
      >
        <Text style={styles.title}>MAURIMESH</Text>
      </Animated.View>

      {/* Subtitle */}
      <Animated.Text style={[styles.subtitle, { opacity: subtitleOpacity }]}>
        SOVEREIGN MESH PROTOCOL
      </Animated.Text>

      {/* Scan line */}
      <Animated.View
        style={[
          styles.scanLine,
          {
            opacity:   scanOpacity,
            transform: [{ translateY: scanY }],
          },
        ]}
      />
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  root: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "#050816",
    zIndex:          9999,
    alignItems:      "center",
    justifyContent:  "center",
  },
  particle: {
    position: "absolute",
  },
  orbWrap: {
    width:          140,
    height:         140,
    alignItems:     "center",
    justifyContent: "center",
  },
  pulseRing: {
    position:        "absolute",
    width:           96,
    height:          96,
    borderRadius:    48,
    borderWidth:     1.5,
    borderColor:     "#39FF14",
  },
  pulseRing2: {
    width:        96,
    height:       96,
    borderRadius: 48,
    borderColor:  "#00BFFF",
    borderWidth:  1,
  },
  orb: {
    width:           84,
    height:          84,
    borderRadius:    42,
    alignItems:      "center",
    justifyContent:  "center",
    backgroundColor: "rgba(57,255,20,0.07)",
    borderWidth:     1.5,
    borderColor:     "rgba(57,255,20,0.40)",
    shadowColor:     "#39FF14",
    shadowOffset:    { width: 0, height: 0 },
    shadowOpacity:   0.55,
    shadowRadius:    22,
    elevation:       10,
  },
  orbSymbol: {
    fontSize:   40,
    color:      "#39FF14",
    lineHeight: 46,
  },
  titleWrap: {
    marginTop:  30,
    alignItems: "center",
  },
  title: {
    fontSize:      32,
    fontWeight:    "900",
    fontFamily:    "Inter_700Bold",
    color:         "#FFFFFF",
    letterSpacing: 9,
  },
  subtitle: {
    marginTop:     10,
    fontSize:      10,
    fontWeight:    "700",
    fontFamily:    "Inter_700Bold",
    color:         "#39FF14",
    letterSpacing: 3.5,
  },
  scanLine: {
    position:        "absolute",
    top:             0,
    left:            0,
    right:           0,
    height:          2,
    backgroundColor: "#39FF14",
    shadowColor:     "#39FF14",
    shadowOffset:    { width: 0, height: 0 },
    shadowOpacity:   1,
    shadowRadius:    10,
    elevation:       6,
  },
});
