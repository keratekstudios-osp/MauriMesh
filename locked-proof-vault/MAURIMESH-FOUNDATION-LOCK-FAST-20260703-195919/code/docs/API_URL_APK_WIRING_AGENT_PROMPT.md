# Replit Agent Task: Verify APK API URL Wiring

The backend API URL has been set to:

```text
https://mauri-mesh-messenger.replit.app/api
```

## Required verification

1. Search the app for all API base URL usage.
2. Ensure mobile app uses:
   - `process.env.EXPO_PUBLIC_API_BASE_URL`
   - fallback: `https://mauri-mesh-messenger.replit.app/api`

3. Ensure web/dashboard uses:
   - `process.env.VITE_API_BASE_URL`
   - fallback: `https://mauri-mesh-messenger.replit.app/api`

4. Remove all bad API base URLs:
   - `replit-objstore-...`
   - `127.0.0.1:4300`
   - `localhost:4300`
   - `localhost:3000` in mobile build code

5. Ensure dashboard calls:
   - `https://mauri-mesh-messenger.replit.app/api/activity`

6. Ensure login/auth calls:
   - `https://mauri-mesh-messenger.replit.app/api/auth/login`

7. Ensure readiness calls:
   - `https://mauri-mesh-messenger.replit.app/api/readiness`

8. Rebuild APK after env changes. Expo public variables are embedded at build time.

## Test commands

```bash
bash scripts/test-maurimesh-api-url.sh
grep -R "replit-objstore\|127.0.0.1:4300\|localhost:4300\|localhost:3000" -n . \
  --exclude-dir=node_modules \
  --exclude-dir=.git \
  --exclude-dir=android/.gradle \
  --exclude-dir=ios/Pods
```

## Completion rule

Do not mark complete unless the installed APK points to:

```text
https://mauri-mesh-messenger.replit.app/api
```

and not to localhost, 127.0.0.1, or Replit object storage.
