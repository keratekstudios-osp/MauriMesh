---
name: MauriMesh integrity badge contract
description: Chat badge states, label wording, and server-side logging rules for SHA-256 receive rejections.
---

## Badge states (chat.tsx IntegrityBadge)

| integrityStatus | Label shown |
|---|---|
| passed | SHA-256 OK · not encryption |
| failed | SHA-256 FAIL · not encryption |
| not_checked | SHA-256 PENDING · not encryption |

All three states always show the "· not encryption" suffix — this was a code-review requirement to prevent users from mistaking integrity hashing for E2E encryption.

## Server logging rule (ai-mesh.ts /mesh/receive)

Both rejection branches MUST log to runtimeErrors AND meshEvents:

- `pipeline.missingHash` → REJECTED_MISSING_HASH, integrityStatus: "failed"
- `!pipeline.ok` → REJECTED_INTEGRITY_FAIL, integrityStatus: "failed"

The `missingHash` branch previously returned 400 without logging (bug). Both branches now write best-effort DB records.

**Why:** Runtime-errors screen and delivery-analytics screen both pull from DB. Silent rejections created invisible blind spots.

**How to apply:** Any new receive-rejection path must write to both runtimeErrors and meshEvents before returning an error response.
