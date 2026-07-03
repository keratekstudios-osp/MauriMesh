# MauriMesh UI Remainder Blueprint

Generated: 20260610-063443

## Current Scan Score

- Passed checks: 28
- Missing checks: 15
- Partial checks: 1
- Completion score: 63%

## What This Script Created

- `src/lib/uiRemainder.ts`
- `src/components/UiRoadmapCard.tsx`
- `app/ui-roadmap.tsx`
- `docs/maurimesh-ui-remainder-blueprint-20260610-063443.md`
- `docs/maurimesh-ui-remainder-tasks-20260610-063443.json`

## Current Project Scan

```
SCREEN CHECKS
MISSING|Login screen|app/login.tsx
FOUND|Dashboard screen|app/dashboard.tsx
FOUND|Chat screen|app/chat.tsx
FOUND|Settings screen|app/settings.tsx
FOUND|Add Friend screen|app/add-friend.tsx
FOUND|Living Mesh screen|app/living-mesh.tsx
FOUND|Mesh Status screen|app/mesh-status.tsx
FOUND|Pixel Calling screen|app/pixel-calling.tsx
FOUND|MauriCore Governance screen|app/mauricore-governance.tsx
FOUND|MauriCore BLE Runtime screen|app/mauricore-ble-runtime.tsx
FOUND|Proof Ledger screen|app/proof-ledger.tsx
MISSING|Route Lab screen|app/route-lab.tsx
MISSING|Tikanga Engine screen|app/tikanga-engine.tsx
MISSING|Self-Healing screen|app/self-healing.tsx
MISSING|Operator Console screen|app/operator-console.tsx
MISSING|Device Proof screen|app/device-proof.tsx
MISSING|UI Roadmap screen|app/ui-roadmap.tsx

COMPONENT CHECKS
FOUND|AppShell|src/components/AppShell.tsx
FOUND|MauriButton|src/components/MauriButton.tsx
FOUND|StatusPill|src/components/StatusPill.tsx
FOUND|MeshSignalCard|src/components/MeshSignalCard.tsx
FOUND|LivingMeshCanvas|src/components/LivingMeshCanvas.tsx
FOUND|ChatBubble|src/components/ChatBubble.tsx
MISSING|UiRoadmapCard|src/components/UiRoadmapCard.tsx
MISSING|ProofLedgerPanel|src/components/ProofLedgerPanel.tsx
MISSING|RouteDecisionPanel|src/components/RouteDecisionPanel.tsx
MISSING|TikangaDecisionCard|src/components/TikangaDecisionCard.tsx
MISSING|SelfHealingPanel|src/components/SelfHealingPanel.tsx
MISSING|DeviceProofCard|src/components/DeviceProofCard.tsx
MISSING|MauriCoreStatusPanel|src/components/MauriCoreStatusPanel.tsx

LIBRARY CHECKS
FOUND|Mauri theme|src/theme/mauriTheme.ts
FOUND|API client|src/lib/api.ts
FOUND|Mesh client|src/lib/meshClient.ts
FOUND|Simulation data|src/lib/simulation.ts
MISSING|UI remainder data|src/lib/uiRemainder.ts

MARKER CHECKS
FOUND|Dashboard Chat route|app/dashboard.tsx contains /chat
FOUND|Dashboard Living Mesh route|app/dashboard.tsx contains /living-mesh
FOUND|Dashboard Mesh Status route|app/dashboard.tsx contains /mesh-status
FOUND|Dashboard Pixel Calling route|app/dashboard.tsx contains /pixel-calling
FOUND|Dashboard Add Friend route|app/dashboard.tsx contains /add-friend
FOUND|Dashboard Settings route|app/dashboard.tsx contains /settings
FOUND|Pixel Calling truth label|app/pixel-calling.tsx contains UI SHELL
PARTIAL|Living Mesh simulation label|app/living-mesh.tsx missing marker: SIMULATION
FOUND|Mesh simulation fallback|src/lib/meshClient.ts contains SIMULATION
```

## UI Screens Left To Create Or Finish

### P0 — Critical Before Final UI

1. **Proof Ledger Screen**
   - File: `app/proof-ledger.tsx`
   - Component: `src/components/ProofLedgerPanel.tsx`
   - Purpose: show packet ID, payload hash, route path, ACK status, timestamp, proof state.
   - Must label: simulation vs device proof.

2. **Route Lab Screen**
   - File: `app/route-lab.tsx`
   - Component: `src/components/RouteDecisionPanel.tsx`
   - Purpose: show BLE, relay, Wi-Fi, internet fallback, TTL, trust, latency, and selected route.

3. **Tikanga Engine Screen**
   - File: `app/tikanga-engine.tsx`
   - Component: `src/components/TikangaDecisionCard.tsx`
   - Purpose: show governance result: approved, warning, review, refused.

4. **Device Proof Screen**
   - File: `app/device-proof.tsx`
   - Component: `src/components/DeviceProofCard.tsx`
   - Purpose: show APK/phone proof checklist and pasted logcat proof later.

5. **Dashboard Final Wiring**
   - Add buttons for:
     - `/ui-roadmap`
     - `/proof-ledger`
     - `/route-lab`
     - `/tikanga-engine`
     - `/self-healing`
     - `/device-proof`
     - `/operator-console`

## P1 — Strong Product Layer

1. **Self-Healing Screen**
   - File: `app/self-healing.tsx`
   - Shows fault detection, repair queue, resilience score, homeostasis.

2. **Operator Console**
   - File: `app/operator-console.tsx`
   - Shows API URL, current mode, UI completion score, build readiness.

3. **MauriCore Status Panel**
   - File: `src/components/MauriCoreStatusPanel.tsx`
   - Reusable status card for governance, BLE runtime, routing, living memory.

## P2 — Reliability UI

1. Empty state component.
2. Error state component.
3. Loading state component.
4. Consistent fallback language.
5. No blank screens.

## P3 — Final Polish

1. Standardize page headers.
2. Standardize card layout.
3. Standardize greenstone/emerald color system.
4. Make all technical screens look like one product.
5. Test readability on Android screen.

## Final Truth

The UI can be completed in Replit.

Real BLE, real phone-to-phone delivery, native Bluetooth scanning, QR camera scanning, and real calling transport still require APK/device proof.
