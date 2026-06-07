import React, { useState } from "react";
import { StyleSheet, Text, TextInput, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { ChatBubble } from "../src/components/ChatBubble";
import { MauriButton } from "../src/components/MauriButton";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function ChatScreen() {
  const [message, setMessage] = useState("");

  return (
    <AppShell>
      <Text style={styles.title}>Chat</Text>
      <Text style={styles.subtitle}>
        Messenger interface wired for Replit preview. Native BLE send/receive proof remains APK/device work.
      </Text>

      <View style={styles.thread}>
        <ChatBubble text="MauriMesh route prepared." status="SIMULATION" />
        <ChatBubble mine text="ACK, TTL, dedupe, relay, and store-forward remain protected architecture." status="local shell" />
      </View>

      <View style={styles.inputWrap}>
        <TextInput
          placeholder="Type message..."
          placeholderTextColor="rgba(255,255,255,0.45)"
          style={styles.input}
          value={message}
          onChangeText={setMessage}
        />
        <MauriButton title="Send" onPress={() => setMessage("")} />
      </View>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, lineHeight: 22 },
  thread: { minHeight: 360, gap: 8 },
  inputWrap: { gap: mauriTheme.spacing.sm },
  input: {
    minHeight: 52,
    borderRadius: mauriTheme.radius.lg,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    color: mauriTheme.colors.white,
    paddingHorizontal: mauriTheme.spacing.md,
    backgroundColor: mauriTheme.colors.panel
  }
});
