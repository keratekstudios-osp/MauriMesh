---
name: MauriMesh API auto-detect
description: How the mobile app locates the API server without hardcoding URLs.
---

## Rule
`getEffectiveApiBase()` in `src/lib/api.ts` resolves the base URL in priority order:
1. `_runtimeBase` — set by BackendConfigContext when user saves a URL in Settings → Connect Backend
2. `EXPO_PUBLIC_MESH_API_URL` — explicit env var (for custom builds)
3. `EXPO_PUBLIC_DOMAIN` → auto-constructs `https://${EXPO_PUBLIC_DOMAIN}/api` (Replit dev)

**Why:** In Replit web preview, no URL is saved in AsyncStorage on first load. EXPO_PUBLIC_DOMAIN is injected by the mobile workflow dev command, so the API is reachable without manual setup.

**How to apply:** If the API path prefix ever changes from `/api`, update the auto-detect line in `src/lib/api.ts` getEffectiveApiBase().

## BackendConfigContext
- Loads stored URL from AsyncStorage on mount, calls setRuntimeApiBase()
- User can override via Settings → Connect Backend screen
- Pings /api/healthz to confirm connectivity; stores latencyMs + version
