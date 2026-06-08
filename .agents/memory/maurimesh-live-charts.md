---
name: MauriMesh live charts
description: How time-series charts are built on the RN analytics screens and why Recharts/SVG are not used
---

# MauriMesh live charts

The analytics screens (latency-monitoring, delivery-analytics, relay-analytics under `app/`) render
time-series charts built from **plain animated React Native Views** in
`src/maurimesh/live/meshCharts.tsx` (MultiLineChart via rotated segment Views, StackedAreaChart and
BarChart via Animated height columns).

**Why no Recharts / no SVG:** This is a React Native / Expo app. Recharts is a DOM/SVG-only library and
cannot render in RN. No charting or `react-native-svg` dependency is installed, so charts are composed
from primitives with the built-in `Animated` API (height/opacity, `useNativeDriver:false` for height).

**Data source constraint:** the live metrics spine (`useLiveMesh` → `MeshMetricSnapshot`) only ever emits
a **cumulative snapshot** (deliveryCount, relayCount, averageLatencyMs, …) with no history and no
per-node relay attribution. Time-series therefore comes from a client-side rolling-window hook
`src/maurimesh/live/useMeshHistory.ts` that samples each poll (keyed on `state.updatedAt`, which is fresh
every read) and derives buckets: `bucketPercentiles` (P50/P90/P99 of real latency readings per bucket),
`bucketDeltas` (per-interval change of a cumulative counter). Nothing is fabricated — respects the app's
truth-boundary design; charts show an empty note until >=2 samples exist.

**How to apply:** add new charts the same way (animated Views + a derivation over `useMeshHistory`), never
reach for Recharts/SVG. Relay "per node over time" is not possible — spine has no per-node relay data.
