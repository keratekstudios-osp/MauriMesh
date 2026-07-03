import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

export function ChatBubble({
  text,
  mine,
  status
}: {
  text: string;
  mine?: boolean;
  status?: string;
}) {
  return (
    <View style={[styles.wrap, mine ? styles.mine : styles.theirs]}>
      <Text style={styles.text}>{text}</Text>
      {status ? <Text style={styles.status}>{status}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    maxWidth: "84%",
    padding: mauriTheme.spacing.md,
    borderRadius: mauriTheme.radius.lg,
    borderWidth: 1,
    marginVertical: 4
  },
  mine: {
    alignSelf: "flex-end",
    backgroundColor: "rgba(0,208,132,0.18)",
    borderColor: mauriTheme.colors.greenstone
  },
  theirs: {
    alignSelf: "flex-start",
    backgroundColor: mauriTheme.colors.panel,
    borderColor: mauriTheme.colors.panelBorder
  },
  text: {
    color: mauriTheme.colors.white,
    fontSize: 15,
    lineHeight: 21
  },
  status: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 11,
    marginTop: 6
  }
});
