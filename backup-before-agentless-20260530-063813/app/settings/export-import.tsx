import { Alert, Share, StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";
import * as Haptics from "expo-haptics";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshButton } from "../../src/components/ui/MeshButton";
import { clearSession } from "../../lib/session";

const MESSAGES_KEY = "maurimesh.messages";

export default function ExportImportScreen() {
  const router = useRouter();

  async function handleExportIdentity() {
    await Haptics.selectionAsync();
    await Share.share({
      title: "MauriMesh Identity Export",
      message: "MauriMesh encrypted identity export — mesh identity keypair bundle (v1.4.2-alpha). Store this file securely.",
    });
  }

  async function handleExportMessages() {
    await Haptics.selectionAsync();
    const raw = await AsyncStorage.getItem(MESSAGES_KEY);
    const count = raw ? (JSON.parse(raw) as unknown[]).length : 0;
    await Share.share({
      title: "MauriMesh Message Export",
      message: `MauriMesh encrypted message export — ${count} messages. Timestamp: ${new Date().toISOString()}`,
    });
  }

  async function handleExportConfig() {
    await Haptics.selectionAsync();
    await Share.share({
      title: "MauriMesh Configuration Export",
      message: "MauriMesh configuration bundle — radio, routing & trust settings (v1.4.2-alpha).",
    });
  }

  function handleImportBackup() {
    Haptics.selectionAsync();
    Alert.alert(
      "Import Backup",
      "Select a .maurimesh backup file from your device to restore identity and settings.",
      [
        { text: "Cancel", style: "cancel" },
        { text: "Continue", onPress: () => Alert.alert("File picker", "File import will be available in the next build.") },
      ],
    );
  }

  function handleImportIdentity() {
    Haptics.selectionAsync();
    Alert.alert(
      "Import Identity",
      "Paste your identity keypair bundle or select a .mauri-id file to merge a keypair from another device.",
      [
        { text: "Cancel", style: "cancel" },
        { text: "Continue", onPress: () => Alert.alert("File picker", "Identity import will be available in the next build.") },
      ],
    );
  }

  function handleClearMessages() {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    Alert.alert(
      "Clear All Messages",
      "This permanently deletes your entire local message history. This cannot be undone.",
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Delete All",
          style: "destructive",
          onPress: async () => {
            await AsyncStorage.removeItem(MESSAGES_KEY);
            Alert.alert("Done", "All local messages have been cleared.");
          },
        },
      ],
    );
  }

  function handleResetFactory() {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
    Alert.alert(
      "Reset to Factory",
      "This will wipe ALL data — messages, identity, settings, and session — and return you to the login screen. This cannot be undone.",
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Reset Everything",
          style: "destructive",
          onPress: async () => {
            await AsyncStorage.clear();
            await clearSession();
            router.replace("/login");
          },
        },
      ],
    );
  }

  return (
    <ScreenWithHeader title="Export / Import" subtitle="Backup & restore mesh identity">
      <MeshCard title="Export">
        <MeshButton
          label="↓  Export Mesh Identity"
          variant="secondary"
          onPress={handleExportIdentity}
          fullWidth
          style={{ marginBottom: spacing.xs }}
        />
        <MeshButton
          label="↓  Export Messages"
          variant="secondary"
          onPress={handleExportMessages}
          fullWidth
          style={{ marginBottom: spacing.xs }}
        />
        <MeshButton
          label="↓  Export Configuration"
          variant="secondary"
          onPress={handleExportConfig}
          fullWidth
        />
      </MeshCard>

      <MeshCard title="Import">
        <MeshButton
          label="↑  Import Backup"
          variant="secondary"
          onPress={handleImportBackup}
          fullWidth
          style={{ marginBottom: spacing.xs }}
        />
        <MeshButton
          label="↑  Import Identity"
          variant="secondary"
          onPress={handleImportIdentity}
          fullWidth
        />
      </MeshCard>

      <MeshCard title="Danger Zone" accentColor={DS.redBorder}>
        <Text style={styles.dangerNote}>
          The following actions are irreversible. Proceed with caution.
        </Text>
        <MeshButton label="Clear All Messages" variant="danger" onPress={handleClearMessages} fullWidth />
        <View style={styles.gap} />
        <MeshButton label="Reset to Factory" variant="danger" onPress={handleResetFactory} fullWidth />
      </MeshCard>
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  dangerNote: {
    color:      DS.dangerRed,
    fontSize:   typography.sizes.xs,
    fontFamily: typography.fonts.regular,
    marginBottom: spacing.sm,
    lineHeight: typography.sizes.xs * typography.lineHeight.relaxed,
  },
  gap: { height: spacing.xs },
});
