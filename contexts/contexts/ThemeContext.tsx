import AsyncStorage from "@react-native-async-storage/async-storage";
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
} from "react";
import { useColorScheme } from "react-native";

export type ThemeMode = "dark" | "light";

interface ThemeContextValue {
  theme: ThemeMode;
  setTheme: (t: ThemeMode) => void;
}

const STORAGE_KEY = "@maurimesh/theme";

const ThemeContext = createContext<ThemeContextValue>({
  theme: "dark",
  setTheme: () => {},
});

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const systemScheme = useColorScheme();
  const [theme, setThemeState] = useState<ThemeMode>(
    systemScheme === "light" ? "light" : "dark"
  );

  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY).then((stored) => {
      if (stored === "dark" || stored === "light") {
        setThemeState(stored);
      }
    });
  }, []);

  const setTheme = useCallback((t: ThemeMode) => {
    setThemeState(t);
    AsyncStorage.setItem(STORAGE_KEY, t);
  }, []);

  return (
    <ThemeContext.Provider value={{ theme, setTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme(): ThemeContextValue {
  return useContext(ThemeContext);
}
