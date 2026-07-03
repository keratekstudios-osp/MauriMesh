# MauriMesh 3-Device Hop Proof

Status:
PENDING DEVICE PROOF

Devices:
- PHONE_A: Samsung Galaxy A06 / Sender / Packet origin
- PHONE_B: Samsung S10 / Relay / Middle hop
- PHONE_C: Samsung Galaxy A16 / Receiver / ACK source

Current connection plan:
- PHONE_A connected to same Wi-Fi as Mac
- PHONE_B connected to same Wi-Fi as Mac
- PHONE_C connected by USB Debugging

Forward path:
A06 TX -> S10 RX -> S10 RELAY -> A16 RX

ACK return path:
A16 ACK -> S10 ACK RELAY -> A06 ACK RECEIVED

PASS rule:
The same packetId must appear across every stage:
1. A06 packet generated
2. A06 TX to S10
3. S10 RX from A06
4. S10 relay to A16
5. A16 RX from S10
6. A16 ACK to S10
7. S10 ACK relay to A06
8. A06 ACK received

Truth:
This is only valid as real proof after APK/device logs and screenshots confirm the same packetId across the full path.
