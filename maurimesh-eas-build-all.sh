#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "=================================================="
echo "MAURIMESH EAS BUILD ALL-IN-ONE"
echo "Replit APK cloud build preparation + launch"
echo "=================================================="
echo ""

ROOT="$(pwd)"
echo "Project root: $ROOT"

echo ""
echo "1. Confirm package.json exists"
if [ ! -f package.json ]; then
  echo "ERROR: package.json not found."
  echo "Run this from the MauriMesh project root."
  exit 1
fi

echo ""
echo "2. Show project package"
node -e "const p=require('./package.json'); console.log('name:', p.name || 'no-name'); console.log('version:', p.version || 'no-version');"

echo ""
echo "3. Check Git state"
git status --short || true

echo ""
echo "4. Optional Git pull if this is a git repo"
if [ -d .git ]; then
  echo "Git repo detected."
  echo "Trying git pull..."
  git pull --ff-only || echo "WARNING: git pull skipped or failed. Continuing with current Replit files."
else
  echo "No .git folder found. Continuing with current Replit files."
fi

echo ""
echo "5. Check required Replit visual design files"
REQUIRED_FILES=(
  "app/login.tsx"
  "app/dashboard.tsx"
  "app/chat.tsx"
  "app/settings.tsx"
  "app/add-friend.tsx"
  "app/living-mesh.tsx"
  "app/mesh-status.tsx"
  "app/pixel-calling.tsx"
  "src/theme/mauriTheme.ts"
  "src/components/AppShell.tsx"
  "src/components/MauriButton.tsx"
  "src/components/LivingMeshCanvas.tsx"
)

MISSING=0
for f in "${REQUIRED_FILES[@]}"; do
  if [ -f "$f" ]; then
    echo "FOUND: $f"
  else
    echo "MISSING: $f"
    MISSING=1
  fi
done

if [ "$MISSING" -eq 1 ]; then
  echo ""
  echo "WARNING: Some Replit visual design files are missing."
  echo "EAS can still build, but the APK may NOT contain the full Replit visual design."
  echo ""
  echo "Continuing in 8 seconds. Press Ctrl+C now if you want to stop."
  sleep 8
fi

echo ""
echo "6. Check Android native folder"
if [ -d android ]; then
  echo "FOUND: android folder"
else
  echo "android folder missing."
  echo "Running expo prebuild to generate native Android folder."
  npx expo prebuild --platform android --no-install
fi

echo ""
echo "7. Install dependencies"
if [ -f pnpm-lock.yaml ]; then
  echo "Using pnpm"
  corepack enable || true
  corepack prepare pnpm@latest --activate || true
  pnpm install --no-frozen-lockfile
elif [ -f yarn.lock ]; then
  echo "Using yarn"
  yarn install
else
  echo "Using npm"
  npm install
fi

echo ""
echo "8. Install required build tools"
npm install -D eas-cli typescript || true

echo ""
echo "9. Confirm Expo config"
npx expo config --type public || true

echo ""
echo "10. Create or repair eas.json"
cat > eas.json <<'JSON'
{
  "cli": {
    "version": ">= 10.0.0"
  },
  "build": {
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

echo "eas.json ready:"
cat eas.json

echo ""
echo "11. TypeScript check"
npx tsc --noEmit || {
  echo ""
  echo "WARNING: TypeScript check failed."
  echo "EAS build may fail unless these errors are fixed."
  echo "Continuing in 8 seconds. Press Ctrl+C now if you want to stop."
  sleep 8
}

echo ""
echo "12. Expo doctor check"
npx expo-doctor || {
  echo ""
  echo "WARNING: expo-doctor found issues."
  echo "Some warnings may be safe. Fatal dependency issues should be fixed."
  echo "Continuing in 8 seconds. Press Ctrl+C now if you want to stop."
  sleep 8
}

echo ""
echo "13. Confirm EAS login"
npx eas whoami || {
  echo ""
  echo "You are not logged into Expo/EAS."
  echo "Login now:"
  npx eas login
}

echo ""
echo "14. Start EAS Android APK build"
echo "This will upload the CURRENT REPLIT project to EAS."
echo "Mac-only files are NOT included unless already pushed/pulled into Replit."
echo ""

npx eas build -p android --profile preview --non-interactive || {
  echo ""
  echo "Non-interactive build failed. Retrying interactive build..."
  npx eas build -p android --profile preview
}

echo ""
echo "=================================================="
echo "MAURIMESH EAS BUILD COMMAND COMPLETE"
echo "When EAS finishes, copy the APK download link."
echo "Install on phone and confirm the Replit visual design opens."
echo "=================================================="
