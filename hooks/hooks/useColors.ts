import { useTheme } from "@/contexts/ThemeContext";
import colors, { type Palette } from "@/constants/colors";

export type Colors = Palette & { radius: number };

export function useColors(): Colors {
  const { theme } = useTheme();
  const palette: Palette = theme === "dark" ? colors.dark : colors.light;
  return { ...palette, radius: colors.radius };
}
