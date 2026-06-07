#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "===================================================="
echo "MauriMesh HQ Replit Agent System — Stage 2 Setup"
echo "Strict Reverse-Path ACK Routing"
echo "===================================================="
echo ""

ROOT="$(pwd)"
KIT="$ROOT/maurimesh-final-integration-kit"

mkdir -p \
  "$KIT/docs" \
  "$KIT/src/stage2-strict-ack" \
  "$KIT/tests" \
  "$KIT/agent-tasks" \
  "$KIT/architecture" \
  "$KIT/ui" \
  "$KIT/telemetry"

# ------------------------------------------------------------
# AGENTS.md — Replit Agent Operating Law
# ------------------------------------------------------------

cat > "$ROOT/AGENTS.md" <<'AGENTS'
# MauriMesh Replit Agent Operating Law

## Prime Directive

You are working inside the MauriMesh project.

Do not rebuild from scratch.
Do not erase working systems.
Do not replace architecture blindly.
Protect the existing application.
Verify before changing.
Improve without destruction.

Your job is to complete integrations with production-grade structure, logic, UI intention, telemetry, and tests.

## Required Process For Every Integration

Every integration must include:

1. Architecture discovery
2. Existing code verification
3. Data contracts
4. Component wiring
5. State wiring
6. UI intention wiring
7. Telemetry events
8. Error handling
9. Recovery path
10. Automated tests
11. Manual acceptance tests
12. Final completion report

No integration is complete until the real app is wired and tests pass.

## Engineering Morals

Understand first.
Protect the foundation.
Verify before change.
Use logic before action.
Push to perfect.
Respect original engineering.
Speak facts.
Build for excellence.

## Build Quality Standard

All code must be:

- typed
- readable
- modular
- testable
- fault-aware
- telemetry-aware
- compatible with existing architecture
- safe for production progression

Avoid shortcuts.
Avoid fake success.
Avoid hidden failure.
Avoid mock-only completion.

## UI Quality Standard

Every visible screen or operator state must feel:

- premium
- expensive
- calm
- clean
- enterprise-grade
- trustworthy
- intentional

MauriMesh visual direction:

- greenstone / emerald
- black
- white
- deep night blue
- strong contrast
- minimal clutter
- operator-grade clarity

Every UI action must have:

- purpose
- state source
- loading state
- empty state
- error state
- disabled reason
- telemetry event if important

## Māori Protocol Design Layer

MauriMesh must respect tikanga-aligned design principles:

### Whakapapa
Every packet, route, device, node, ACK, and decision must preserve lineage.

### Manaakitanga
Protect users, devices, privacy, and message integrity.

### Kaitiakitanga
Protect the mesh from flooding, waste, spam, loops, and unsafe behaviour.

### Rangatiratanga
Preserve user control, local sovereignty, and device autonomy.

### Kotahitanga
Strengthen coordination between devices and people.

### Tapu / Noa
Separate protected internal state from safe public state.

## Self-Healing Requirement

Every major runtime system should support detection and safe response.

When a fault is detected:

1. classify the fault
2. preserve working systems
3. attempt only safe repair
4. refuse unsafe automatic repair
5. log the decision
6. expose truth through telemetry
7. never fake recovery

## Truth Rule

Never present fake data as live.

Telemetry states must distinguish:

- live
- stale
- simulation
- unavailable

## Completion Rule

A task is only complete when:

- files are created or updated
- wiring is connected to the real app
- tests exist
- tests pass
- build is not broken
- UI state is wired if visible
- telemetry reports truth
- acceptance checklist is complete
- remaining risks are reported

AGENTS

# ------------------------------------------------------------
# Main Stage 2 Agent Task
# ------------------------------------------------------------

cat > "$KIT/agent-tasks/STAGE_2_STRICT_REVERSE_PATH_ACK_HQ_TASK.md" <<'TASK'
# MauriMesh Stage 2 HQ Task
## Strict Reverse-Path ACK Routing

## Mission

Complete Stage 2 only.

Build deterministic ACK routing so acknowledgement packets return through the exact recorded reverse path.

Example:

Data route:

A -> B -> C

ACK route must be:

C -> B -> A

The ACK must never choose another route through RouteScore.

## Non-Negotiable Rules

Do not rebuild from scratch.
Do not delete working code.
Do not rewrite the full app.
Do not replace the routing engine.
Do not fake completion.
Do not mark Stage 2 complete until real wiring and tests are done.

## Phase 1 — Discover Existing Architecture

Inspect and report files responsible for:

1. BLE scan
2. BLE advertise
3. BLE send
4. BLE receive
5. packet parsing
6. message routing
7. RouteScore
8. ACK creation
9. ACK handling
10. store-forward queue
11. dedupe
12. TTL/hop logic
13. telemetry/logging
14. UI/operator state

Do not edit code during discovery.

## Phase 2 — Verify Existing Contracts

Before changing anything, identify the current packet shape.

Confirm whether these fields exist:

- id
- type
- from
- to
- createdAt
- ttlMs
- hopCount
- maxHops
- path
- reversePath
- reversePathIndex
- payload

If fields are missing, add compatibility adapters instead of breaking existing packets.

## Phase 3 — Implement Strict ACK Contract

ACK packets must support:

```ts
type MeshPacketType = "data" | "ack" | "control" | "health";

interface MeshPacket {
  id: string;
  type: MeshPacketType;
  from: string;
  to: string;
  createdAt: number;
  ttlMs: number;
  hopCount: number;
  maxHops: number;
  path: string[];
  reversePath?: string[];
  reversePathIndex?: number;
  payload: unknown;
}EOF
