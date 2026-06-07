---
name: MauriMesh auth pattern
description: How auth/verify accepts tokens and how the mobile session lib stores/sends them.
---

## Rule
`POST /auth/verify` must accept token from BOTH:
1. `Authorization: Bearer <token>` header (what the mobile client sends)
2. `req.body.token` (backward-compat for direct API callers)

**Why:** Mobile sends the Bearer header via standard HTTP convention. Original code only read body.token, so verify always returned ok:false for mobile clients.

**How to apply:** Any new auth-checking middleware or route should check `req.headers.authorization?.split(' ')[1]` first, then fall back to `req.body.token`.

## Session storage (mobile)
- Token stored in AsyncStorage under `maurimesh.session.token`
- `lib/session.ts` → `getSessionToken()` retrieves it
- Session expires after 7 days; `isSessionActive()` checks expiry on each load
