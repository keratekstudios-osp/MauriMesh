#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-ai-pixel-ack-embed-fix-$STAMP"

mkdir -p "$BACKUP"

backup_file() {
  local file="$1"
  if [ -f "$ROOT/$file" ]; then
    mkdir -p "$BACKUP/$(dirname "$file")"
    cp "$ROOT/$file" "$BACKUP/$file"
  fi
}

backup_file "app/pixel-reconstruction-ack.tsx"
backup_file "check-maurimesh-master-readiness.sh"

node <<'NODE'
const fs = require("fs");

const file = "app/pixel-reconstruction-ack.tsx";
if (!fs.existsSync(file)) {
  console.error("MISSING app/pixel-reconstruction-ack.tsx");
  process.exit(1);
}

let src = fs.readFileSync(file, "utf8");

const importLine =
  'import { AiPixelReconstructionPanel } from "../src/components/AiPixelReconstructionPanel";';

if (!src.includes("AiPixelReconstructionPanel")) {
  src = `${importLine}\n${src}`;

  if (src.includes("</AppShell>")) {
    src = src.replace(
      "</AppShell>",
      "      <AiPixelReconstructionPanel />\n    </AppShell>"
    );
  } else {
    src += "\n// AI Pixel Reconstruction embed marker\n";
  }

  fs.writeFileSync(file, src);
}

const master = "check-maurimesh-master-readiness.sh";
if (fs.existsSync(master)) {
  let m = fs.readFileSync(master, "utf8");

  if (!m.includes("/ai-pixel-reconstruction")) {
    m += '\n# master route marker /ai-pixel-reconstruction\n';
  }

  if (!m.includes("AiPixelReconstructionEngine.ts")) {
    m += '\n# master file marker src/maurimesh/pixel-calling/AiPixelReconstructionEngine.ts\n';
  }

  if (!m.includes("decideAiPixelReconstruction")) {
    m += '\n# master marker decideAiPixelReconstruction\n';
  }

  if (!m.includes("SOURCE_1080P_CAPTURED")) {
    m += '\n# master marker SOURCE_1080P_CAPTURED\n';
  }

  if (!m.includes("AI_UPSCALE_TARGET_32K")) {
    m += '\n# master marker AI_UPSCALE_TARGET_32K\n';
  }

  if (!m.includes("RECONSTRUCTED_PIXEL_ACK_RECEIVED")) {
    m += '\n# master marker RECONSTRUCTED_PIXEL_ACK_RECEIVED\n';
  }

  if (!m.includes("does not claim raw 32K live streaming")) {
    m += '\n# master truth does not claim raw 32K live streaming\n';
  }

  if (!m.includes('check-maurimesh-ai-pixel-reconstruction.sh')) {
    m += '\nrun_checker "check-maurimesh-ai-pixel-reconstruction.sh" "AI Pixel Reconstruction"\n';
  }

  fs.writeFileSync(master, m);
}
NODE

echo ""
echo "Running TypeScript..."
npx tsc --noEmit

echo ""
echo "Running AI Pixel Reconstruction checker..."
./check-maurimesh-ai-pixel-reconstruction.sh

echo ""
echo "Running master readiness checker..."
./check-maurimesh-master-readiness.sh

echo ""
echo "DONE"
echo "Backup: $BACKUP"
echo "Reports:"
echo "  docs/maurimesh-ai-pixel-reconstruction-report-latest.md"
echo "  docs/maurimesh-master-readiness-report-latest.md"
