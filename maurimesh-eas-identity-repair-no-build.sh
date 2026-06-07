#!/usr/bin/env bash
set -e

echo "=================================================="
echo "MAURIMESH EAS IDENTITY REPAIR — NO BUILD"
echo "=================================================="

BACKUP="backup-before-eas-identity-repair-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

for f in app.json app.config.js app.config.ts eas.json package.json; do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP/$f"
    echo "Backed up: $f"
  fi
done

echo ""
echo "1. Repair app.json if present"

if [ -f app.json ]; then
node <<'NODE'
const fs = require("fs");
const path = "app.json";
const raw = fs.readFileSync(path, "utf8");
const json = JSON.parse(raw);

const expo = json.expo || json;

expo.name = expo.name || "MauriMesh";
expo.slug = expo.slug || "maurimesh";
expo.scheme = expo.scheme || "maurimesh";
expo.version = expo.version || "1.0.0";
expo.orientation = expo.orientation || "portrait";

expo.android = expo.android || {};
expo.android.package = "com.maurimesh.messenger";
expo.android.versionCode = expo.android.versionCode || 1;

expo.ios = expo.ios || {};
expo.ios.bundleIdentifier = "com.maurimesh.messenger";

expo.extra = expo.extra || {};
expo.extra.projectName = "MauriMesh Messenger";
expo.extra.truth = "Replit preview does not prove native BLE. APK/device validation required.";

const out = json.expo ? json : { expo };
fs.writeFileSync(path, JSON.stringify(out, null, 2));
NODE
else
cat > app.json <<'JSON'
{
  "expo": {
    "name": "MauriMesh",
    "slug": "maurimesh",
    "scheme": "maurimesh",
    "version": "1.0.0",
    "orientation": "portrait",
    "android": {
      "package": "com.maurimesh.messenger",
      "versionCode": 1
    },
    "ios": {
      "bundleIdentifier": "com.maurimesh.messenger"
    },
    "extra": {
      "projectName": "MauriMesh Messenger",
      "truth": "Replit preview does not prove native BLE. APK/device validation required."
    }
  }
}
JSON
fi

echo ""
echo "2. Repair eas.json"

cat > eas.json <<'JSON'
{
  "cli": {
    "version": ">= 12.0.0"
  },
  "build": {
    "preview-apk": {
      "android": {
        "buildType": "apk"
      },
      "distribution": "internal",
      "developmentClient": false
    },
    "preview": {
      "android": {
        "buildType": "apk"
      },
      "distribution": "internal",
      "developmentClient": false
    },
    "production": {
      "android": {
        "buildType": "app-bundle"
      }
    }
  }
}
JSON

echo ""
echo "3. Show final identity"
npx expo config --type public | grep -E "name:|slug:|scheme:|package:|bundleIdentifier:" || true

echo ""
echo "4. Run checks again — NO BUILD"
npx expo-doctor || true
npx tsc --noEmit || true

echo ""
echo "=================================================="
echo "IDENTITY REPAIR COMPLETE — NO EAS BUILD USED"
echo "Backup: $BACKUP"
echo "=================================================="
