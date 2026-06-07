# MauriMesh UI Engine Wiring Report

## Wired into Replit UI

- Dashboard now links to Invention Engine.
- Chat now sends messages through MauriMesh invention engine.
- Living Mesh now uses engine node/route snapshot.
- Mesh Status now shows Mauri AI, route memory, trust memory, ledger, and synth status.
- New `/invention-engine` screen controls:
  - Run demo message
  - ACK last route
  - Fail last route
  - Reset demo
  - View route plan
  - View Cleo + Chanelle Synth AI explanation
  - View delivery ledger
  - View living mesh visual proof

## API endpoints

- GET `/api/health`
- GET `/api/mesh/status`
- GET `/api/invention/status`
- POST `/api/invention/demo`
- POST `/api/invention/send`
- POST `/api/invention/ack`
- POST `/api/invention/fail`

## Truth boundary

This proves Replit-safe logic-engine wiring and UI visibility.

It does not prove:
- native BLE
- Wi-Fi Direct
- background Android service
- real APK packet transport
- physical phone-to-phone delivery
- live emergency routing on devices

Those require Android APK + physical phones.
