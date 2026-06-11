#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH FINAL REPLIT AGENT TASK PUSH"
echo "Creates final task pack for Replit Agent"
echo "Safe bypass: fallback around broken installs/build blockers only"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
TASK_DIR="$ROOT/maurimesh-agent-final-push-$STAMP"
DOCS="$ROOT/docs"

mkdir -p "$TASK_DIR" "$DOCS"

cat > "$TASK_DIR/REPLIT_AGENT_FINAL_PUSH.md" <<'AGENT'
# MAURIMESH MESSENGER — FINAL REPLIT AGENT PUSH

## PRIME DIRECTIVE

Complete the remaining MauriMesh Messenger app tasks without destroying existing working code.

Respect existing engineering.

Do not delete:
- BLE runtime files
- Android native files
- routing engines
- ACK engines
- proof ledger files
- dashboard screens
- MauriCore files
- Tikanga/governance files
- self-learning/memory/healing files

Repair only what is broken.
Patch safely.
Back up before changing.
Verify after every change.

## TRUTH RULE

Do not claim Replit proves real BLE.

Replit can prove:
- UI wiring
- route wiring
- proof flow logic
- packetId discipline
- button lighting states
- local stage notifications
- build/typecheck readiness
- dashboard access

Physical APK phones prove:
- real BLE TX
- real BLE RX
- real ACK return
- real two-device proof
- logcat hardware evidence

Final BLE PASS requires same packetId across:

- TX_A06_TO_S10
- RX_S10_FROM_A06
- ACK_RELAY_S10_TO_A06
- ACK_BACK_TO_A06

## SAFE BYPASS RULE

Use MauriMesh safe bypass logic only for engineering blockers.

Allowed:
- If pnpm add fails, do not keep forcing it.
- If expo-notifications cannot install, use dependency-free Alert + in-app banner.
- If dashboard patch pattern fails, add route button manually.
- If Replit preview cannot access BLE, label it APK REQUIRED.
- If native module is missing in web preview, guard it behind Platform checks.
- If TypeScript fails from stale imports, remove or guard stale imports.
- If a screen crashes from missing dependency, replace with safe fallback.

Not allowed:
- Do not bypass Android Bluetooth permission requirements.
- Do not fake packet delivery.
- Do not fake BLE scan logs.
- Do not mark proof PASS without matching packetId evidence.
- Do not bypass login/security/authentication by hiding failures.
- Do not remove safety labels.
- Do not delete proof/truth warnings.

## CURRENT REQUIRED OUTCOME

Complete the final app layer so the APK can be rebuilt with:

1. Dashboard opens safely.
2. Dashboard includes Proof 2-Hop button.
3. `/proof-2-hop` route opens safely.
4. A06 role screen works.
5. S10 role screen works.
6. Buttons light by stage:
   - grey locked
   - amber ready
   - blue active/waiting
   - purple ACK
   - green complete
7. Stage-ready notification appears in-app.
8. Popup Alert tells operator what to press next.
9. No external notification dependency required.
10. No `expo-notifications` import unless package is already installed and typecheck passes.
11. Packet ID is visible and copyable manually.
12. Logs show event + packetId + role + timestamp.
13. Truth rule is visible on screen.
14. TypeScript passes.
15. Expo starts.
16. Existing BLE runtime remains untouched.
17. Final report is written.

## TASK 1 — INSPECT BEFORE CHANGE

Run:

```bash
pwd
ls
find app -maxdepth 2 -type f | sort
find src -maxdepth 3 -type f | sort | head -200
test -f package.json && cat package.json
