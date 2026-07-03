import { RecoveryPlan } from "./types";

export function planRecoveryFromLog(text: string): RecoveryPlan {
  if (/Host is down|offline|unauthorized|no devices\/emulators/i.test(text)) {
    return {
      issue: "ADB device unavailable",
      cause: "Phone is offline, unauthorized, or Wi-Fi ADB dropped.",
      nextAction: "Reconnect by USB, accept debugging, run adb tcpip 5555, then reconnect Wi-Fi ADB.",
      shellHint: "adb devices -l && adb -s <USB_SERIAL> tcpip 5555 && adb connect <PHONE_IP>:5555",
      confidence: 0.92,
    };
  }

  if (/JAVA_HOME is not set|java: command not installed/i.test(text)) {
    return {
      issue: "Java missing",
      cause: "Replit shell has no selected Java runtime.",
      nextAction: "Use Nix Java 17.",
      shellHint: "nix-shell -p zulu17 --run 'java -version'",
      confidence: 0.95,
    };
  }

  if (/SDK location not found|ANDROID_HOME|sdk.dir/i.test(text)) {
    return {
      issue: "Android SDK missing locally",
      cause: "Replit lacks Android SDK path.",
      nextAction: "Use EAS remote Android build for native compile validation.",
      shellHint: "npx eas-cli build -p android --profile preview --clear-cache",
      confidence: 0.9,
    };
  }

  if (/Unexpected keyword 'import'|SyntaxError/i.test(text)) {
    return {
      issue: "TypeScript/Metro syntax error",
      cause: "A generated import or code block was inserted in an invalid location.",
      nextAction: "Repair import placement and rerun expo export.",
      shellHint: "npx expo export --platform android --clear",
      confidence: 0.88,
    };
  }

  return {
    issue: "No known recovery match",
    cause: "The learner has not seen this failure pattern enough.",
    nextAction: "Capture the exact error section and add it to learner memory.",
    confidence: 0.35,
  };
}
