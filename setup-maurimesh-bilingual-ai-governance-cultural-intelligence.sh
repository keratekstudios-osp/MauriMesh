#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MauriMesh Bilingual AI Governance + Cultural Intelligence"
echo "HQ Replit Agent Integration System"
echo "============================================================"
echo ""

ROOT="$(pwd)"
KIT="$ROOT/maurimesh-final-integration-kit"

mkdir -p \
  "$KIT/agent-tasks" \
  "$KIT/docs" \
  "$KIT/architecture" \
  "$KIT/src/governance" \
  "$KIT/src/language" \
  "$KIT/src/cultural-intelligence" \
  "$KIT/src/telemetry" \
  "$KIT/src/ui-intentions" \
  "$KIT/tests"

# -------------------------------------------------------------------
# AGENTS.md enhancement
# -------------------------------------------------------------------

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

Every integration must include:

1. architecture discovery
2. existing code verification
3. data contracts
4. component wiring
5. state wiring
6. UI intention wiring
7. telemetry events
8. error handling
9. recovery path
10. automated tests
11. manual acceptance tests
12. final completion report

## Engineering Morals

Understand first.
Protect the foundation.
Verify before change.
Use logic before action.
Push to perfect.
Respect original engineering.
Speak facts.
Build for excellence.

## Design Quality

Every UI must feel:

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

## Māori Cultural Protocol Layer

MauriMesh must respect tikanga-aligned design principles.

This system must not claim cultural authority.
It must support cultural respect, safety, provenance, and review.

Core values:

- Whakapapa: preserve lineage and origin.
- Manaakitanga: protect people and relationships.
- Kaitiakitanga: guard the network, data, and community.
- Rangatiratanga: preserve user agency and local control.
- Kotahitanga: strengthen unity and coordination.
- Tapu / Noa: separate protected states from safe public states.
- Pono: truthfulness.
- Tika: correctness and right action.
- Aroha: care in interaction.

## Bilingual Language Rule

MauriMesh must support English and te reo Māori labels with graceful fallback.

Rules:

1. never fake translation confidence
2. preserve macrons
3. allow review by fluent speakers
4. label uncertain language as review_required
5. avoid using sacred/culturally sensitive words casually
6. do not auto-translate cultural protocol terms without explanation

## AI Governance Rule

AI decisions must be:

- explainable
- auditable
- reversible where possible
- risk-scored
- culturally aware
- privacy-preserving
- truthful about uncertainty

High-risk decisions require human review.

## Self-Healing Rule

When a system fault appears:

1. classify it
2. preserve working systems
3. attempt only safe repair
4. refuse unsafe automatic repair
5. log the decision
6. expose truth through telemetry
7. never fake recovery

## Completion Rule

A task is only complete when:

- code exists
- wiring exists
- tests exist
- tests pass
- app still builds
- UI state is wired if visible
- telemetry reports truth
- cultural risk is reviewed
- remaining risks are reported

AGENTS

# -------------------------------------------------------------------
# Architecture document
# -------------------------------------------------------------------

cat > "$KIT/architecture/BILINGUAL_AI_GOVERNANCE_CULTURAL_INTELLIGENCE_ARCHITECTURE.md" <<'ARCH'
# MauriMesh Bilingual AI Governance + Cultural Intelligence Architecture

## Purpose

This integration gives MauriMesh a structured bilingual language layer, AI governance layer, and cultural intelligence layer.

It is designed to help the system make safer, clearer, more respectful decisions while preserving the foundation of a living, self-learning intelligent communication mesh network.

## Core Principle

The system must not pretend to be a cultural authority.

It must provide:

- structured guidance
- risk scoring
- bilingual support
- cultural review flags
- audit trails
- explainable decisions
- safe defaults

## Main Components

### 1. BilingualLanguageEngine

Handles:

- English labels
- te reo Māori labels
- fallback language
- missing translation detection
- macron preservation
- review flags

### 2. CulturalIntelligenceEngine

Handles:

- tikanga-aligned decision checks
- cultural sensitivity scoring
- context awareness
- review-required outcomes
- protected term detection
- respect rules

### 3. AiGovernanceEngine

Handles:

- AI action approval
- risk classification
- explainability
- human review routing
- audit trails
- decision confidence

### 4. GovernanceTelemetry

Handles:

- truth-state events
- cultural review events
- AI decision events
- bilingual fallback events
- human review required events

### 5. UI Intention Registry

Ensures every governance UI element has:

- intention
- state source
- action
- empty state
- error state
- premium design requirement

## Decision Pipeline

Input request enters:

```text
User / System Event
        ↓
BilingualLanguageEngine
        ↓
CulturalIntelligenceEngine
        ↓
AiGovernanceEngine
        ↓
Telemetry + Audit Trail
        ↓
Approved Action / Safe Refusal / Human Review
