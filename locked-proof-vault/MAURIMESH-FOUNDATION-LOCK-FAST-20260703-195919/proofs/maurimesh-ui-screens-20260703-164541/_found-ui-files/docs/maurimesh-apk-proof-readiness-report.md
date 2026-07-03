# MauriMesh APK Proof Readiness Report

Generated: 20260611-045924

## Status

Overall readiness: PASS

## Checked

- Dashboard route to /proof-2-hop
- 2-hop proof screen exists
- A06 sender role exists
- S10 relay / ACK role exists
- Lit button stage colours exist
- NEXT STAGE READY banner exists
- Alert popup operator notification exists
- No expo-notifications dependency
- Required packet proof event names exist
- TypeScript result: PASS

## Required Proof Events

Final hardware PASS requires same packetId across:

1. PACKET_ID_GENERATED
2. TX_A06_TO_S10
3. RX_S10_FROM_A06
4. ACK_RELAY_S10_TO_A06
5. ACK_BACK_TO_A06

## Truth Rule

This Replit check proves UI, routing, stage logic, and TypeScript readiness.

It does not prove real BLE.

Real BLE proof requires APK installed on physical A06 and S10 devices with matching packetId logs.

## Next Build Command

Use EAS preview APK build:

```bash
npx eas-cli build --platform android --profile preview-apk --clear-cache
```

