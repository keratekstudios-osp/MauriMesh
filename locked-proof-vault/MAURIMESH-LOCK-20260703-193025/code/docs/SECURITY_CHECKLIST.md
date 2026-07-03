# Security & Privacy Checklist — MauriMesh

Review this checklist before every commit, PR, or public push.

---

## Secrets & Credentials

- [ ] No `.env` files committed (only `.env.example` is safe)
- [ ] No `.env.local` committed
- [ ] No API keys or tokens hardcoded in source files
- [ ] No `DATABASE_URL` or connection strings in source
- [ ] No `EXPO_TOKEN` or `EAS_TOKEN` in source
- [ ] No private keys (`.pem`, `.key`, `.p12`) committed
- [ ] No Android keystores committed (`.jks`, `.keystore`)
- [ ] No Apple certificates or provisioning profiles committed
- [ ] No OAuth client secrets in source
- [ ] No JWT signing secrets in source

---

## Security Claims

- [ ] Encryption status in UI is accurate — never show "AES-256-GCM active" unless crypto is fully implemented in send/receive paths
- [ ] Diagnostics screen shows `status: simulation` for encryption in Replit / Expo Go
- [ ] Native BLE module reports `nativeAvailable: false` when `NativeModules.MauriMeshBle` is not present
- [ ] No hardcoded "pass" or "active" for features that are not implemented
- [ ] No fake production security claims in README, UI, or docs

---

## Data & Privacy

- [ ] No user PII hardcoded in source (usernames, emails, phone numbers)
- [ ] No test user credentials committed
- [ ] Session tokens are stored in AsyncStorage — not logged to console in production builds
- [ ] Mesh peer data does not include personally identifying info beyond node labels

---

## Dependencies

- [ ] No packages added from untrusted/unverified sources
- [ ] Core packages not downgraded: `expo`, `react`, `react-native`, `expo-router`
- [ ] `pnpm audit` run before release (or `pnpm --filter @workspace/api-server exec npm audit`)

---

## Repository

- [ ] `.gitignore` includes: `.env`, `.env.local`, `*.keystore`, `*.jks`, `*.pem`, `*.key`, `android/app/google-services.json`, `ios/GoogleService-Info.plist`
- [ ] No binary secrets in git history (use `git log --all --full-history -- '*.env'` to verify)
- [ ] Branch protection enabled on `main` (require PR review)

---

## APK / Build

- [ ] Release keystore stored in secure secrets manager (not in repo)
- [ ] EAS secrets configured via Replit secrets or EAS Secrets UI — not in files
- [ ] Debug APKs not distributed to end users
- [ ] `adb backup` disabled in AndroidManifest for production builds

---

## API Server

- [ ] Auth tokens expire (7-day TTL enforced in `mesh_sessions` table)
- [ ] Expired tokens rejected by `/auth/verify`
- [ ] No admin endpoints exposed without auth middleware
- [ ] CORS restricted to known origins in production (not `*`)
- [ ] Rate limiting considered for `/auth/login`
