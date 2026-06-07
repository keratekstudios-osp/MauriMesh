import { LinearGradient } from "expo-linear-gradient";
import { Platform, StyleSheet, View, type ViewStyle } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { mauriColors } from "./mauriTheme";

interface MauriScreenProps {
  children: React.ReactNode;
  style?: ViewStyle;
  noSafeArea?: boolean;
}

export function MauriScreen({ children, style, noSafeArea = false }: MauriScreenProps) {
  const insets = useSafeAreaInsets();
  const topInset    = noSafeArea ? 0 : (Platform.OS === "web" ? 67 : insets.top);
  const bottomInset = noSafeArea ? 0 : (Platform.OS === "web" ? 34 : insets.bottom);

  return (
    <View style={[styles.root, { paddingTop: topInset, paddingBottom: bottomInset }, style]}>
      <LinearGradient
        colors={[mauriColors.gradTop, mauriColors.gradMid, mauriColors.gradBot]}
        style={StyleSheet.absoluteFillObject}
      />
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: mauriColors.bg,
  },
});
