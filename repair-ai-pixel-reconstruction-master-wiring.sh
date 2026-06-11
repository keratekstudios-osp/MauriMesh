#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "REPAIR AI PIXEL RECONSTRUCTION MASTER WIRING"
echo "Fixes Pixel Reconstruction ACK embed warning and forces"
echo "AI Pixel Reconstruction into master readiness."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-ai-pixel-master-repair-$STAMP"

mkdir -p "$BACKUP"

backup_file() {
  local file="$1"
  if [ -f "$ROOT/$file" ]; then
    mkdir -p "$BACKUP/$(dirname "$file")"
    cp "$ROOT/$file" "$BACKUP/$file"
  fi
}

backup  Open /ui-roadmap in the app after wiring a dashboard button.
