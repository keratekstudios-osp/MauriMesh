import { Tabs } from "expo-router";
import { Icon, Label, NativeTabs } from "expo-router/unstable-native-tabs";
import { SymbolView } from "expo-symbols";
import { Feather } from "@expo/vector-icons";
import React from "react";
import { Platform, StyleSheet, View, useColorScheme } from "react-native";

import { useColors } from "../../hooks/useColors";

function NativeTabLayout() {
  return (
    <NativeTabs>
      <NativeTabs.Trigger name="index">
        <Icon sf={{ default: "message.circle", selected: "message.circle.fill" }} />
        <Label>Messages</Label>
      </NativeTabs.Trigger>
      <NativeTabs.Trigger name="settings">
        <Icon sf={{ default: "gear", selected: "gear.badge" }} />
        <Label>Settings</Label>
      </NativeTabs.Trigger>
    </NativeTabs>
  );
}

function ClassicTabLayout() {
  const colors = useColors();
  const colorScheme = useColorScheme();
  const isDark = colorScheme === "dark";
  const isIOS = Platform.OS === "ios";
  const isWeb = Platform.OS === "web";

  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: colors.primary,
        tabBarInactiveTintColor: colors.mutedForeground,
        headerShown: false,
        tabBarHideOnKeyboard: true,
        tabBarLabelStyle: {
          fontSize: 11,
          fontFamily: "Inter_600SemiBold",
          fontWeight: "600",
          letterSpacing: 0.2,
          marginBottom: 2,
        },
        tabBarItemStyle: {
          paddingTop: 4,
        },
        tabBarStyle: {
          position: "absolute",
          backgroundColor: isIOS ? "transparent" : colors.card,
          borderTopWidth: StyleSheet.hairlineWidth,
          borderTopColor: colors.border,
          elevation: 0,
          height: isWeb ? 64 : 56,
        },
        tabBarBackground: () =>
          isIOS ? (
            <View
              intensity={100}
              tint={isDark ? "dark" : "light"}
              style={StyleSheet.absoluteFill}
            />
          ) : isWeb ? (
            <View
              style={[
                StyleSheet.absoluteFill,
                {
                  backgroundColor: colors.card,
                  borderTopWidth: StyleSheet.hairlineWidth,
                  borderTopColor: colors.border,
                },
              ]}
            />
          ) : null,
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: "Messages",
          tabBarIcon: ({ color, focused }) =>
            isIOS ? (
              <SymbolView
                name="message.circle"
                tintColor={color}
                size={24}
              />
            ) : (
              <Feather
                name="message-circle"
                size={22}
                color={color}
                style={focused ? { opacity: 1 } : { opacity: 0.7 }}
              />
            ),
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: "Settings",
          tabBarIcon: ({ color, focused }) =>
            isIOS ? (
              <SymbolView name="gear" tintColor={color} size={24} />
            ) : (
              <Feather
                name="settings"
                size={22}
                color={color}
                style={focused ? { opacity: 1 } : { opacity: 0.7 }}
              />
            ),
        }}
      />
    </Tabs>
  );
}

export default function TabLayout() {
  if (false) {
    return <NativeTabLayout />;
  }
  return <ClassicTabLayout />;
}
