#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-ai-pixel-reconstruction-report-$STAMP.md"
LATEST="$DOCS/maurimesh-ai-pixel-reconstruction-report-latest.md"

PASS=0
FAIL=0
WARN=0

line(){ echo "$1" | tee -a "$REPORT"; }
pass(){ PASS=$((PASS+1)); line "- [x] $1"; }
fail(){ FAIL=$((FAIL+1)); line "- [ ] MISSING: $1"; }
warn(){ WARN=$((WARN+1)); line "- [!] PARTIAL: $1"; }

has_file(){ [ -f "$ROOT/$1" ]; }
has_text(){ [ -f "$ROOT/$1" ] && grep -Fq "$2" "$ROOT/$1"; }

: > "$REPORT"

line "# MauriMesh AI Pixel Reconstruction Report"
line ""
line "Generated: $STAMP"
line ""

line "## Files"
for file in \
  "src/maurimesh/pixel-calling/AiPixelReconstructionTypes.ts" \
  "src/maurimesh/pixel-calling/AiPixelReconstructionEngine.ts" \
  "src/components/AiPixelReconstructionPanel.tsx" \
  "app/ai-pixel-reconstruction.tsx"
do
  if has_file "$file"; then pass "$file exists"; else fail "$file missing"; fi
done

line ""
line "## AI Pixel Reconstruction Capabilities"
for token in \
  "SOURCE_1080P_CAPTURED" \
  "FRAME_COMPRESSED" \
  "FRAME_CHUNKED" \
  "FRAME_RECEIVED" \
  "AI_RECONSTRUCTION_STARTED" \
  "AI_PIXELS_CORRECTED" \
  "AI_UPSCALE_TARGET_32K" \
  "RECONSTRUCTION_QUALITY_SCORED" \
  "RECONSTRUCTED_FRAME_HASHED" \
  "RECONSTRUCTED_PIXEL_ACK_SENT" \
  "RECONSTRUCTED_PIXEL_ACK_RECEIVED" \
  "RAW_32K_LIVE_FALSE" \
  "AI_32K_RECONSTRUCTION_TARGET" \
  "AI_PIXEL_RECONSTRUCTION_TARGETS" \
  "estimateTargetPixels" \
  "selectAiPixelModelMode" \
  "chooseAiPixelFallbackTarget" \
  "calculateCompressionRatioEstimate" \
  "calculateReconstructedPixelMultiplier" \
  "createAiReconstructionStages" \
  "decideAiPixelReconstruction" \
  "runAiPixelReconstructionDemo"
do
  if grep -R "$token" "$ROOT/src/maurimesh/pixel-calling" "$ROOT/src/components/AiPixelReconstructionPanel.tsx" >/dev/null 2>&1; then
    pass "Capability found: $token"
  else
    fail "Capability missing: $token"
  fi
done

line ""
line "## Route + Backup Wiring"
if has_text "app/dashboard.tsx" "/ai-pixel-reconstruction"; then pass "Dashboard has /ai-pixel-reconstruction"; else fail "Dashboard missing /ai-pixel-reconstruction"; fi
if has_text "src/lib/uiBackupRoutes.ts" "/ai-pixel-reconstruction"; then pass "Backup registry has /ai-pixel-reconstruction"; else fail "Backup registry missing /ai-pixel-reconstruction"; fi
if has_text "app/ai-pixel-reconstruction.tsx" "AiPixelReconstructionPanel"; then pass "Screen uses AiPixelReconstructionPanel"; else fail "Screen missing panel"; fi

line ""
line "## Embedded Wiring"
if has_text "app/pixel-calling.tsx" "AiPixelReconstructionPanel"; then pass "Pixel Calling embeds AiPixelReconstructionPanel"; else warn "Pixel Calling embed not confirmed"; fi
if has_text "app/pixel-calling-backup.tsx" "AiPixelReconstructionPanel"; then pass "Pixel Calling Backup embeds AiPixelReconstructionPanel"; else warn "Pixel Calling Backup embed not confirmed"; fi
if has_text "app/pixel-reconstruction-ack.tsx" "AiPixelReconstructionPanel"; then pass "Pixel Reconstruction ACK embeds AiPixelReconstructionPanel"; else warn "Pixel Reconstruction ACK embed not confirmed"; fi
if has_text "app/device-proof.tsx" "AiPixelReconstructionPanel"; then pass "Device Proof includes AiPixelReconstructionPanel"; else warn "Device Proof embed not confirmed"; fi
if has_text "app/proof-ledger.tsx" "AiPixelReconstructionPanel"; then pass "Proof Ledger includes AiPixelReconstructionPanel"; else warn "Proof Ledger embed not confirmed"; fi
if has_text "app/message-fallback.tsx" "AiPixelReconstructionPanel"; then pass "Message Fallback includes AiPixelReconstructionPanel"; else warn "Message Fallback embed not confirmed"; fi

line ""
line "## Truth Protection"
if has_text "src/maurimesh/pixel-calling/AiPixelReconstructionEngine.ts" "does not claim raw 32K live streaming"; then
  pass "Raw 32K live false truth boundary present"
else
  fail "Raw 32K live false truth boundary missing"
fi

if has_text "src/maurimesh/pixel-calling/AiPixelReconstructionEngine.ts" "1080p compressed source frames"; then
  pass "1080p compressed source truth boundary present"
else
  warn "1080p compressed source truth boundary not confirmed"
fi

if has_text "src/maurimesh/pixel-calling/AiPixelReconstructionEngine.ts" "strict reconstructed-pixel ACK proof"; then
  pass "Strict reconstructed-pixel ACK truth boundary present"
else
  warn "Strict reconstructed-pixel ACK truth boundary not confirmed"
fi

line ""
line "## TypeScript"
if npx tsc --noEmit >> "$REPORT" 2>&1; then
  pass "TypeScript passed"
else
  fail "TypeScript failed"
fi

TOTAL=$((PASS + FAIL + WARN))
if [ "$TOTAL" -gt 0 ]; then SCORE=$((PASS * 100 / TOTAL)); else SCORE=0; fi

if [ "$FAIL" -eq 0 ] && [ "$WARN" -eq 0 ]; then
  STATUS="COMPLETE"
elif [ "$FAIL" -eq 0 ]; then
  STATUS="COMPLETE_WITH_WARNINGS"
else
  STATUS="INCOMPLETE"
fi

line ""
line "## Summary"
line ""
line "- Total: $TOTAL"
line "- Complete: $PASS"
line "- Partial: $WARN"
line "- Missing/failed: $FAIL"
line "- Score: $SCORE%"
line "- Status: **$STATUS**"

cp "$REPORT" "$LATEST"

echo ""
echo "============================================================"
echo "AI PIXEL RECONSTRUCTION CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
