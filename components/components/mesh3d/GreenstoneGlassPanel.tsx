import type { ViewStyle } from "react-native";
import type { ReactNode } from "react";

import { MauriGlassCard } from "@/components/ui/MauriGlassCard";

interface GreenstoneGlassPanelProps {
  children: ReactNode;
  style?: ViewStyle;
  noPadding?: boolean;
}

export function GreenstoneGlassPanel({
  children,
  style,
  noPadding = false,
}: GreenstoneGlassPanelProps) {
  return (
    <MauriGlassCard intense noPadding={noPadding} style={style}>
      {children}
    </MauriGlassCard>
  );
}
