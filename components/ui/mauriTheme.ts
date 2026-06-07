export const mauriColors = {
  bg:           "#050816",
  bgElevated:   "#0B1220",
  bgCard:       "#101827",
  accent:       "#39FF14",
  accentBright: "#39FF14",
  accentDim:    "rgba(57,255,20,0.10)",
  accentGlow:   "rgba(57,255,20,0.20)",
  meshBlue:     "#00BFFF",
  meshBlueDim:  "rgba(0,191,255,0.10)",
  border:       "rgba(57,255,20,0.18)",
  borderBright: "rgba(57,255,20,0.36)",
  white:        "#FFFFFF",
  silver:       "#94A3B8",
  muted:        "rgba(148,163,184,0.55)",
  faint:        "rgba(255,255,255,0.20)",
  destructive:  "#EF4444",
  amber:        "#FACC15",
  grey:         "#64748B",
  gradTop:      "#050816",
  gradMid:      "#080F20",
  gradBot:      "#050816",
} as const;

export const mauriRadius = {
  xs:   6,
  sm:   10,
  md:   14,
  lg:   18,
  xl:   24,
  full: 9999,
} as const;

export const mauriSpacing = {
  xxs: 4,
  xs:  8,
  sm:  12,
  md:  16,
  lg:  24,
  xl:  32,
  xxl: 48,
} as const;

export const mauriShadow = {
  glow: {
    shadowColor:   "#39FF14",
    shadowOffset:  { width: 0, height: 4 },
    shadowOpacity: 0.28,
    shadowRadius:  16,
    elevation:     8,
  },
  glowStrong: {
    shadowColor:   "#39FF14",
    shadowOffset:  { width: 0, height: 6 },
    shadowOpacity: 0.42,
    shadowRadius:  24,
    elevation:     12,
  },
  card: {
    shadowColor:   "#000",
    shadowOffset:  { width: 0, height: 2 },
    shadowOpacity: 0.35,
    shadowRadius:  8,
    elevation:     4,
  },
} as const;

export const mauriFonts = {
  regular:  "Inter_400Regular",
  medium:   "Inter_500Medium",
  semibold: "Inter_600SemiBold",
  bold:     "Inter_700Bold",
} as const;
