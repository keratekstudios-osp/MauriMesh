#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH EAS ACCOUNT SWITCH"
echo "Target: maurimesh-network / mauri-mesh"
echo "Project ID: 58787f88-6d39-402d-a0ec-91458f5f6246"
echo "============================================================"
echo ""

PROJECT_ID="58787f88-6d39-402d-a0ec-91458f5f6246"
OWNER="maurimesh-network"
SLUG="mauri-mesh"
ANDROID_PACKAGE="com.maurimesh.messenger"

echo "1. Checking required files..."
test -f package.json || { echo "ERROR: package.json not found. Run this at project root."; exit 1; }

echo ""
echo "2. Checking EXPO_TOKEN..."
if [ -z "${EXPO_TOKEN:-}" ]; then
  echo "ERROR: EXPO_TOKEN is not set."
  echo "Add the NEW maurimesh-network Expo token into Replit Secrets as EXPO_TOKEN."
  exit 1
fi

echo ""
echo "3. Installing/using latest EAS CLI..."
npx eas-cli@latest --version

echo ""
echo "4. Confirming authenticated Expo account..."
npx eas-cli@latest whoami || {
  echo "ERROR: EAS authentication failed. Your EXPO_TOKEN may be wrong."
  exit 1
}

echo ""
echo "5. Backing up current EAS/app config..."
BACKUP="backup-before-eas-switch-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
[ -f app.json ] && cp app.json "$BACKUP/app.json"
[ -f app.config.js ] && cp app.config.js "$BACKUP/app.config.js"
[ -d .eas ] && cp -R .eas "$BACKUP/.eas"
[ -f eas.json ] && cp eas.json "$BACKUP/eas.json"
echo "Backup saved to: $BACKUP"

echo ""
echo "6. Updating Expo config..."

node <<NODE
const fs = require("fs");

const PROJECT_ID = "$PROJECT_ID";
const OWNER = "$OWNER";
const SLUG = "$SLUG";
const ANDROID_PACKAGE = "$ANDROID_PACKAGE";

function updateObject(config) {
  const root = config.expo ? config.expo : config;

  root.owner = OWNER;
  root.slug = SLUG;

  root.extra = root.extra || {};
  root.extra.eas = root.extra.eas || {};
  root.extra.eas.projectId = PROJECT_ID;

  root.android = root.android || {};
  if (!root.android.package) {
    root.android.package = ANDROID_PACKAGE;
  }

  return config;
}

if (fs.existsSync("app.json")) {
  const raw = fs.readFileSync("app.json", "utf8");
  const json = JSON.parse(raw);
  const updated = updateObject(json);
  fs.writeFileSync("app.json", JSON.stringify(updated, null, 2) + "\\n");
  console.log("Updated app.json");
} else {
  console.log("No app.json found. If you use app.config.js, verify owner/slug/projectId manually.");
}
NODE

echo ""
echo "7. Re-linking local project to existing EAS project ID..."
rm -rf .eas
npx eas-cli@latest project:init --id "$PROJECT_ID" --force --non-interactive

echo ""
echo "8. Verifying EAS project info..."
npx eas-cli@latest project:info

echo ""
echo "9. Ensuring eas.json exists..."
if [ ! -f eas.json ]; then
  cat > eas.json <<'JSON'
{
  "cli": {
    "version": ">= 10.0.0",
    "appVersionSource": "local"
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
  echo "Created eas.json"
else
  echo "eas.json already exists. Preserved."
fi

echo ""
echo "10. Installing dependencies safely..."
if [ -f pnpm-lock.yaml ]; then
  corepack enable || true
  pnpm install --no-frozen-lockfile
elif [ -f yarn.lock ]; then
  yarn install
else
  npm install
fi

echo ""
echo "11. Final config check..."
node - <<'NODE'
const fs = require("fs");
if (fs.existsSync("app.json")) {
  const app = JSON.parse(fs.readFileSync("app.json", "utf8"));
  const root = app.expo || app;
  console.log("owner:", root.owner);
  console.log("slug:", root.slug);
  console.log("android.package:", root.android && root.android.package);
  console.log("extra.eas.projectId:", root.extra && root.extra.eas && root.extra.eas.projectId);
}
NODE

echo ""
echo "============================================================"
echo "READY."
echo "Now build APK with:"
echo "npx eas-cli@latest build -p android --profile preview-apk --clear-cache"
echo ""
echo "For Play Store AAB:"
echo "npx eas-cli@latest build -p android --profile production --clear-cache"
echo "============================================================"
