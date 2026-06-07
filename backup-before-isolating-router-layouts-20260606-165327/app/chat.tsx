import React, { useState } from "react";
import { StyleSheet, Text, TextInput, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { ChatBubble } from "../src/components/ChatBubble";
import { DeliveryLedgerPanel } from "../src/components/DeliveryLedgerPanel";
import { MauriButton } from "../src/components/MauriButton";
import { RoutePlanPanel } from "../src/components/RoutePlanPanel";
import { SynthPanel } from "../src/components/SynthPanel";
import { sendMessageThroughInventionEngine } from "../src/lib/inventionEngineClient";
import { mauriTheme } from "../src/theme/mauriTheme";

type Snapshot = Awaited<ReturnType<typeof sendMessageThroughInventionEngine>>;

export default function ChatScreen() {
  const [message, setMessage] = useState("");
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null);

  async function send() {
    const clean = message.trim();
    if (!clean) return;
    const result = await sendMessageThroughInventionEngine(clean);
    setSnapshot(result);
    setMessage("");
  }

  const packet = snapshot?.lastResult?.packet;

  return (
    <AppShell>
      <Text style={styles.title}>Chat</Text>
      <Text style={styles.subtitle}>
        Message input is now wired through Mauri AI, Tikanga governance,
        hybrid routing, store-and-forward, trust memory, and Cleo + Chanelle Synth AI.
      </Text>

      <View style={styles.thread}>
        <ChatBubble text="MauriMesh route prepared." status="ENGINE READY" />
        {packet ? (
          <ChatBubble
            mine
            text={packet.body}
            status={`${packet.culturalState} · ${snapshot?.lastResult?.routePlan.transport}`}
          />
        ) : (
          <ChatBubble
            mine
            text="Type a message below to run it through the invention engine."
            status="waiting"
          />
        )}
      </View>

      <View style={styles.inputWrap}>
        <TextInput
          placeholder="Type message..."
          placeholderTextColor="rgba(255,255,255,0.45)"
          style={styles.input}
          value={message}
          onChangeText={setMessage}
          multiline
        />
        <MauriButton title="Send Through MauriMesh Engine" onPress={send} />
      </View>

      <RoutePlanPanel routePlan={snapshot?.lastResult?.routePlan} />
      <SynthPanel messages={snapshot?.lastResult?.synth || []} />
      <DeliveryLedgerPanel ledger={snapshot?.lastResult?.ledger || []} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 34,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 22,
  },
  thread: {
    minHeight: 220,
    gap: 8,
  },
  inputWrap: {
    gap: mauriTheme.spacing.sm,
  },
  input: {
    minHeight: 90,
    borderRadius: mauriTheme.radius.lg,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    color: mauriTheme.colors.white,
    paddingHorizontal: mauriTheme.spacing.md,
    paddingVertical: mauriTheme.spacing.md,
    backgroundColor: mauriTheme.colors.panel,
  },
});
