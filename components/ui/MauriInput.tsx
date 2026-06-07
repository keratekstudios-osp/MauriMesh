import { forwardRef, useState } from "react";
import {
  StyleSheet,
  Text,
  TextInput,
  View,
  type TextInputProps,
  type ViewStyle,
} from "react-native";
import { Feather } from "@expo/vector-icons";
import { mauriColors, mauriFonts, mauriRadius } from "./mauriTheme";

interface MauriInputProps extends TextInputProps {
  label?: string;
  icon?: React.ComponentProps<typeof Feather>["name"];
  containerStyle?: ViewStyle;
  error?: string;
}

export const MauriInput = forwardRef<TextInput, MauriInputProps>(
  ({ label, icon, containerStyle, error, style, onFocus, onBlur, ...rest }, ref) => {
    const [focused, setFocused] = useState(false);

    return (
      <View style={[styles.wrapper, containerStyle]}>
        {label ? <Text style={styles.label}>{label}</Text> : null}
        <View
          style={[
            styles.inputRow,
            focused && styles.inputRowFocused,
            error ? styles.inputRowError : null,
          ]}
        >
          {icon ? (
            <Feather
              name={icon}
              size={16}
              color={focused ? mauriColors.accent : mauriColors.muted}
              style={styles.icon}
            />
          ) : null}
          <TextInput
            ref={ref}
            style={[styles.input, style]}
            placeholderTextColor={mauriColors.muted}
            onFocus={(e) => { setFocused(true); onFocus?.(e); }}
            onBlur={(e)  => { setFocused(false); onBlur?.(e); }}
            {...rest}
          />
        </View>
        {error ? <Text style={styles.error}>{error}</Text> : null}
      </View>
    );
  }
);

MauriInput.displayName = "MauriInput";

const styles = StyleSheet.create({
  wrapper: {
    gap: 6,
  },
  label: {
    fontSize: 10,
    fontWeight: "700",
    fontFamily: mauriFonts.bold,
    color: mauriColors.accent,
    letterSpacing: 2,
    textTransform: "uppercase",
  },
  inputRow: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: mauriColors.bgCard,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.08)",
    borderRadius: mauriRadius.sm,
    paddingHorizontal: 14,
    height: 52,
  },
  inputRowFocused: {
    borderColor: mauriColors.border,
    shadowColor: mauriColors.accent,
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.30,
    shadowRadius: 10,
    elevation: 4,
  },
  inputRowError: {
    borderColor: mauriColors.destructive,
  },
  icon: {
    marginRight: 10,
  },
  input: {
    flex: 1,
    fontSize: 14,
    color: mauriColors.white,
    fontFamily: mauriFonts.regular,
  },
  error: {
    fontSize: 11,
    color: mauriColors.destructive,
    fontFamily: mauriFonts.regular,
  },
});
