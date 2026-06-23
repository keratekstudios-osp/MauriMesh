import React, { useEffect, useRef, useState } from "react";
import { Animated, Easing, StyleSheet, Text, View } from "react-native";

// Lightweight, dependency-free charts built from React Native primitives.
// Recharts is a DOM/SVG library and cannot render inside React Native, so the
// time-series visualisations here are composed from animated Views.

type LineSeriesSpec = { label: string; color: string; values: number[] };

function usePulse(signature: string): Animated.Value {
  const v = useRef(new Animated.Value(1)).current;
  useEffect(() => {
    v.setValue(0.55);
    Animated.timing(v, {
      toValue: 1,
      duration: 420,
      easing: Easing.out(Easing.quad),
      useNativeDriver: true,
    }).start();
  }, [signature, v]);
  return v;
}

// A single column whose height animates smoothly whenever its value changes.
function AnimatedBar({
  heightPx,
  color,
  radius = 3,
}: {
  heightPx: number;
  color: string;
  radius?: number;
}) {
  const h = useRef(new Animated.Value(heightPx)).current;
  useEffect(() => {
    Animated.timing(h, {
      toValue: heightPx,
      duration: 450,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: false,
    }).start();
  }, [heightPx, h]);
  return (
    <Animated.View
      style={{
        height: h,
        width: "100%",
        backgroundColor: color,
        borderTopLeftRadius: radius,
        borderTopRightRadius: radius,
      }}
    />
  );
}

function GridLines({ height }: { height: number }) {
  return (
    <>
      {[0, 0.25, 0.5, 0.75, 1].map((f) => (
        <View
          key={f}
          style={[
            styles.gridLine,
            { top: height - f * height },
          ]}
        />
      ))}
    </>
  );
}

function Legend({ items }: { items: { label: string; color: string }[] }) {
  return (
    <View style={styles.legend}>
      {items.map((it) => (
        <View key={it.label} style={styles.legendItem}>
          <View style={[styles.legendDot, { backgroundColor: it.color }]} />
          <Text style={styles.legendText}>{it.label}</Text>
        </View>
      ))}
    </View>
  );
}

function ScaleLabels({ max, unit }: { max: number; unit?: string }) {
  const suffix = unit ? ` ${unit}` : "";
  return (
    <View style={styles.scaleRow}>
      <Text style={styles.axis}>
        peak {max}
        {suffix}
      </Text>
      <Text style={styles.axis}>
        0{suffix}
      </Text>
    </View>
  );
}

function LineSeries({
  values,
  color,
  width,
  height,
  min,
  max,
}: {
  values: number[];
  color: string;
  width: number;
  height: number;
  min: number;
  max: number;
}) {
  if (width <= 0 || values.length < 2) return null;
  const span = max - min || 1;
  const pts = values.map((v, i) => ({
    x: (i / (values.length - 1)) * width,
    y: height - ((v - min) / span) * height,
  }));

  const nodes: React.ReactNode[] = [];
  for (let i = 1; i < pts.length; i++) {
    const a = pts[i - 1];
    const b = pts[i];
    const dx = b.x - a.x;
    const dy = b.y - a.y;
    const len = Math.hypot(dx, dy);
    const angle = Math.atan2(dy, dx);
    nodes.push(
      <View
        key={`s${i}`}
        style={{
          position: "absolute",
          left: a.x + dx / 2 - len / 2,
          top: a.y + dy / 2 - 1,
          width: len,
          height: 2,
          backgroundColor: color,
          borderRadius: 1,
          transform: [{ rotate: `${angle}rad` }],
        }}
      />,
    );
  }
  pts.forEach((p, i) => {
    nodes.push(
      <View
        key={`d${i}`}
        style={{
          position: "absolute",
          left: p.x - 2.5,
          top: p.y - 2.5,
          width: 5,
          height: 5,
          borderRadius: 2.5,
          backgroundColor: color,
        }}
      />,
    );
  });
  return <>{nodes}</>;
}

export function MultiLineChart({
  series,
  height = 150,
  unit,
}: {
  series: LineSeriesSpec[];
  height?: number;
  unit?: string;
}) {
  const [w, setW] = useState(0);
  const all = series.flatMap((s) => s.values);
  const max = Math.max(1, ...all);
  const min = 0;
  const signature = `${series.map((s) => s.values.length).join("-")}:${all
    .slice(-series.length)
    .join(",")}`;
  const pulse = usePulse(signature);

  return (
    <View>
      <View
        style={[styles.plot, { height }]}
        onLayout={(e) => setW(e.nativeEvent.layout.width)}
      >
        <GridLines height={height} />
        <Animated.View style={[StyleSheet.absoluteFill, { opacity: pulse }]}>
          {series.map((s) => (
            <LineSeries
              key={s.label}
              values={s.values}
              color={s.color}
              width={w}
              height={height}
              min={min}
              max={max}
            />
          ))}
        </Animated.View>
      </View>
      <ScaleLabels max={max} unit={unit} />
      <Legend items={series.map((s) => ({ label: s.label, color: s.color }))} />
    </View>
  );
}

export function StackedAreaChart({
  lower,
  upper,
  lowerColor,
  upperColor,
  lowerLabel,
  upperLabel,
  height = 150,
}: {
  lower: number[];
  upper: number[];
  lowerColor: string;
  upperColor: string;
  lowerLabel: string;
  upperLabel: string;
  height?: number;
}) {
  const totals = lower.map((l, i) => l + (upper[i] || 0));
  const max = Math.max(1, ...totals);
  return (
    <View>
      <View style={[styles.plot, { height }]}>
        <GridLines height={height} />
        <View style={styles.columns}>
          {lower.map((l, i) => {
            const u = upper[i] || 0;
            return (
              <View key={i} style={styles.column}>
                <AnimatedBar
                  heightPx={(u / max) * height}
                  color={upperColor}
                  radius={2}
                />
                <AnimatedBar
                  heightPx={(l / max) * height}
                  color={lowerColor}
                  radius={0}
                />
              </View>
            );
          })}
        </View>
      </View>
      <ScaleLabels max={max} />
      <Legend
        items={[
          { label: lowerLabel, color: lowerColor },
          { label: upperLabel, color: upperColor },
        ]}
      />
    </View>
  );
}

export function BarChart({
  values,
  color,
  label,
  height = 150,
  unit,
}: {
  values: number[];
  color: string;
  label: string;
  height?: number;
  unit?: string;
}) {
  const max = Math.max(1, ...values);
  return (
    <View>
      <View style={[styles.plot, { height }]}>
        <GridLines height={height} />
        <View style={styles.columns}>
          {values.map((v, i) => (
            <View key={i} style={styles.column}>
              <AnimatedBar heightPx={(v / max) * height} color={color} radius={3} />
            </View>
          ))}
        </View>
      </View>
      <ScaleLabels max={max} unit={unit} />
      <Legend items={[{ label, color }]} />
    </View>
  );
}

const styles = StyleSheet.create({
  plot: {
    position: "relative",
    marginTop: 4,
    overflow: "hidden",
  },
  gridLine: {
    position: "absolute",
    left: 0,
    right: 0,
    height: 1,
    backgroundColor: "rgba(255,255,255,0.06)",
  },
  columns: {
    ...StyleSheet.absoluteFillObject,
    flexDirection: "row",
    alignItems: "flex-end",
    gap: 2,
  },
  column: {
    flex: 1,
    justifyContent: "flex-end",
  },
  scaleRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginTop: 6,
  },
  axis: {
    color: "rgba(255,255,255,0.45)",
    fontSize: 11,
    fontWeight: "700",
  },
  legend: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 14,
    marginTop: 10,
  },
  legendItem: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
  },
  legendDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
  },
  legendText: {
    color: "rgba(255,255,255,0.7)",
    fontSize: 13,
    fontWeight: "700",
  },
});
