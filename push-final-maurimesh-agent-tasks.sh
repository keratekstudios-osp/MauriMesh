#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH FINAL REPLIT AGENT TASK PUSH"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
TASK_DIR="$ROOT/maurimesh-agent-final-push-$STAMP"
DOCS="$ROOT/docs"

mkdir -p "$TASK_DIR" "$DOCS"

cat > "$TASK_DIR/REPLIT_AGENT_FINAL_PUSH.md" <<'AGENT'
# MAURIMESH MESSENGER — FINAL REPLIT AGENT PUSH

Complete the remaining MauriMesh Messenger tasks without deleting working code.

## Protect

Do not delete:
- BLE runtime files
- Android native files
- routing engines
- ACK engines
- proof ledger files
- dashboard screens
- MauriCore files
- Tikanga/governance files
- self-learning/healing/memory files

Patch only what is missing or broken.

## Truth rule

Do not claim Replit proves real BLE.

Replit can prove:
- UI wiring
- proof flow logic
- button lighting
- route wiring
- packetId discipline
- TypeScript readiness

APK + physical phones prove:
- real BLE TX
- real BLE RX
- real ACK return
- real two-device proof

Final BLE PASS requires the same packetId across:

- TX_A06_TO_S10
- RX_S10_FROM_A06
- ACK_RELAY_S10_TO_A06
- ACK_BACK_TO_A06

## Safe bypass logic

Allowed:
- If pnpm add fails, stop retrying.
- If expo-notifications fails, remove it and use Alert + in-app banner.
- If Replit preview cannot access BLE, label APK REQUIRED.
- If native modules crash web preview, guard them.
- If dashboard patch fails, manually add the button.

Not allowed:
- Do not fake BLE.
- Do not fake packet delivery.
- Do not fake ACK.
- Do not mark PASS without packetId evidence.
- Do not bypass Android Bluetooth permissions.
- Do not remove truth warnings.

## Required final state

1. Dashboard opens safely.
2. Dashboard has Proof 2-Hop button.
3. /proof-2-hop opens safely.
4. A06 role works.
5. S10 role works.
6. Buttons light by stage:
   - grey locked
   - amber ready
   - blue waiting
   - purple ACK
   - green complete
7. In-app NEXT STAGE READY banner works.
8. Alert popup tells operator what to press next.
9. No expo-notifications dependency unless already installed and passing TypeScript.
10. Packet ID is visible.
11. Logs show event, packetId, role, and timestamp.
12. Truth rule is visible.
13. TypeScript passes.
14. Final report is written.

## Inspect first

Run:

```bash
pwd
ls
find app -maxdepth 2 -type f | sort
find src -maxdepth 3 -type f | sort | head -200
test -f package.json && cat package.json
