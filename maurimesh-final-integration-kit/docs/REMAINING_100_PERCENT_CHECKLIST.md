# MauriMesh Remaining 100% Completion Checklist

## Stage 1 — Crash And APK Integrity
Duration: 1 to 3 days

Tasks:
- Confirm correct APK/build is installed.
- Remove old APK from test phones.
- Verify package name.
- Capture crash logs.
- Fix native crash.
- Confirm app opens on Samsung A06 and Samsung S10.

Acceptance:
- No crash within 60 seconds.
- Correct APK installs.
- Logs prove current build is running.

## Stage 2 — Strict Reverse-Path ACK Routing
Duration: 1 to 2 days

Tasks:
- Enforce ACK return through recorded reversePath only.
- Prevent RouteScore from rerouting ACK packets.
- Queue ACK if exact next peer is missing.
- Drain ACK only when exact peer returns.

Acceptance:
- A -> B -> C message works.
- ACK returns C -> B -> A only.
- No infinite rebroadcast.

## Stage 3 — Identity And Secure Packet Envelope
Duration: 2 to 5 days

Tasks:
- Create stable device identity.
- Encrypt packet payload.
- Sign packet metadata.
- Reject malformed packets.
- Reject replayed packets.

Acceptance:
- No plaintext user payload.
- Invalid packets are rejected.
- Trusted packets are accepted.

## Stage 4 — Self-Healing Engineer Layer
Duration: 2 to 4 days

Tasks:
- Detect BLE scan failure.
- Detect advertise failure.
- Detect ACK timeout.
- Detect queue blockage.
- Detect route decay.
- Attempt safe repair only.

Acceptance:
- Faults are classified.
- Safe repairs are attempted.
- Unsafe repairs are refused.

## Stage 5 — Telemetry Truth Layer
Duration: 1 to 3 days

Tasks:
- Track live status.
- Track stale status.
- Track simulation separately.
- Track queue pressure.
- Track ACK health.

Acceptance:
- No fake data appears as live.
- Stale data is labelled stale.
- Simulation is labelled simulation.

## Stage 6 — UI Intention Wiring
Duration: 2 to 5 days

Tasks:
- Define every screen intention.
- Wire every button.
- Add premium mesh health states.
- Add secure identity state.
- Add self-healing status panel.

Acceptance:
- No dead buttons.
- No fake metrics.
- Every UI action has a real intention.

## Stage 7 — Multi-Device Field Test
Duration: 2 to 7 days

Tasks:
- Test Phone A to Phone B.
- Test A -> B -> C.
- Test airplane mode.
- Test Wi-Fi off.
- Test mobile data off.
- Test app restart queue recovery.

Acceptance:
- Offline message works.
- Relay works.
- ACK works.
- Queue survives restart.
- No crash.

## Stage 8 — Production Build And Public Release
Duration: 3 to 14+ days

Tasks:
- Android release build.
- Signing.
- Privacy policy.
- Terms of service.
- Closed testing.
- Public release approval.

Acceptance:
- Production APK/AAB builds.
- App installs cleanly.
- Release path is approved.

Estimated remaining time:
Fast path: 14 to 21 days.
Careful production path: 21 to 45 days.
Public approval path: 30 to 60 days.
