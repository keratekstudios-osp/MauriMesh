import React from "react";
import { Pressable, Text, PressableProps } from "react-native";

export function MeshButton({ children, ...props }: PressableProps & { children?: React.ReactNode }) {
  return (
    <Pressable {...props}>
      <Text>{children}</Text>
    </Pressable>
  );
}

export default MeshButton;
