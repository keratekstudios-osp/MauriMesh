import React, { useEffect, useMemo, useState } from "react";
import {
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useRouter } from "expo-router";
import { AppShell } from "../src/components/AppShell";
import { MauriPageHeader } from "../src/components/MauriPageHeader";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";
import {
  clearRuntimeLogs,
  getRuntimeLogs,
  markScreenOpen,
  recordRuntimeLog,
  runtimeLogText,
  subscribeRuntimeLogs,
  MauriRuntimeLogEvent,
} from "../src/maurimesh/runtime/runtimeLog";

export default function RuntimeLogsScreen() {
  const router = useRouter();
  const [events, setEvents] = useState<MauriRuntimeLogEvent[]>(() => getRuntimeLogs());

  useEffect(() => {
    markScreenOpen("Runtime Logs", { route: "/runtime-logs" });
    return subscribeRuntimeLogs(setEvents);
  }, []);

  const report = useMemo(() => runtimeLogText(), [events]);

  const stats = useMemo(() => {
    const pass = events.filter((e) => e.level === "PASS").length;
    const fail = events.filter((e) => e.level === "FAIL").length;
    const proof = events.filter((e) => e.level === "PROOF").length;
    const nav = events.filter((e) => e.level === "NAV").length;
    return { total: events.length, pass, fail, proof, nav };
  }, [events]);

  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="MAURIMESH RUNTIME"
        title="App Logs"
        subtitle="Live in-app runtime events, screen opens, button presses, proof notes, and exportable report block."
        tone="success"
      />

      <View style={styles.card}>
        <Text style={styles.title}>Runtime Status</Text>
        <View style={styles.row}>
          <StatusPill label={`${stats.total} EVENTS`} tone="success" />
          <StatusPill label={`${stats.pass} PASS`} tone="success" />
          <StatusPill label={`${stats.fail} FAIL`} tone={stats.fail > 0 ? "danger" : "neutral"} />
        </View>
        <Text style={styles.text}>
          Open every proof and feature screen. This logger records app runtime movement so the APK can prove which screens were reached without crashing.
        </Text>
      </View>

      <View style={styles.actions}>
        <TouchableOpacity
          style={styles.button}
          onPress={() => {
            recordRuntimeLog("PROOF", "manual.runtime", "Manual runtime checkpoint recorded");
          }}
        >
          <Text style={styles.buttonText}>Add Runtime Checkpoint</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.button}
          onPress={() => {
            clearRuntimeLogs();
          }}
        >
          <Text style={styles.buttonText}>Clear Logs</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.button}
          onPress={() => {
            recordRuntimeLog("NAV", "runtime.logs", "Return to dashboard pressed");
            router.replace("/dashboard");
          }}
        >
          <Text style={styles.buttonText}>Back to Dashboard</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.card}>
        <Text style={styles.title}>Copyable Runtime Report</Text>
        <Text style={styles.text}>
          Long-press inside the box, select all, copy, then paste into ChatGPT or your proof archive.
        </Text>
        <TextInput
          value={report}
          multiline
          editable={false}
          selectTextOnFocus
          style={styles.logBox}
        />
      </View>

      <View style={styles.card}>
        <Text style={styles.title}>Latest Events</Text>
        <ScrollView style={styles.eventList} nestedScrollEnabled>
          {events.slice(0, 80).map((event) => (
            <View key={event.id} style={styles.event}>
              <Text style={styles.eventMeta}>
                {event.level} · {event.scope}
              </Text>
              <Text style={styles.eventMsg}>{event.message}</Text>
              <Text style={styles.eventTs}>{event.ts}</Text>
            </View>
          ))}
        </ScrollView>
      </View>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  card: {
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.25)",
    backgroundColor: "rgba(2,12,8,0.86)",
    borderRadius: 22,
    padding: 16,
    marginBottom: 14,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 18,
    fontWeight: "900",
    marginBottom: 8,
  },
  text: {
    color: "rgba(255,255,255,0.72)",
    fontSize: 13,
    lineHeight: 19,
  },
  row: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
    marginBottom: 10,
  },
  actions: {
    gap: 10,
    marginBottom: 14,
  },
  button: {
    backgroundColor: "#00D084",
    borderRadius: 18,
    paddingVertical: 13,
    paddingHorizontal: 14,
    alignItems: "center",
  },
  buttonText: {
    color: "#001F14",
    fontWeight: "900",
  },
  logBox: {
    minHeight: 260,
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.32)",
    borderRadius: 14,
    padding: 12,
    color: "#D8FFE9",
    backgroundColor: "rgba(0,0,0,0.45)",
    fontSize: 11,
    lineHeight: 16,
    marginTop: 12,
  },
  eventList: {
    maxHeight: 420,
  },
  event: {
    borderBottomWidth: 1,
    borderBottomColor: "rgba(255,255,255,0.08)",
    paddingVertical: 10,
  },
  eventMeta: {
    color: "#00D084",
    fontSize: 11,
    fontWeight: "900",
  },
  eventMsg: {
    color: mauriTheme.colors.white,
    fontSize: 13,
    fontWeight: "700",
    marginTop: 3,
  },
  eventTs: {
    color: "rgba(255,255,255,0.45)",
    fontSize: 10,
    marginTop: 3,
  },
});
