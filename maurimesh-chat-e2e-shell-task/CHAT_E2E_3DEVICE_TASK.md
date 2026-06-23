# MAURIMESH CHAT E2E 3-DEVICE DELIVERY PROOF v1

GOAL:
Move from proof-screen packet validation into real Chat screen delivery.

PASS CHAIN:
A06 sender -> S10 relay -> A16 receiver -> ACK back through S10 -> A06 delivered

REQUIRED EVENTS:
CHAT_CREATED
CHAT_TX_A06
CHAT_RX_S10
CHAT_RELAY_S10_TO_A16
CHAT_RX_A16
CHAT_UI_DISPLAYED_A16
CHAT_ACK_A16
CHAT_ACK_RELAY_S10_TO_A06
CHAT_DELIVERED_A06

PASS RULE:
Same messageId must appear in every event.

DO NOT:
- delete BLE/GATT/router/ACK/store-forward code
- fake BLE success
- replace proven proof logic
- claim PASS unless full chain exists

IMPLEMENTATION TARGET:
Connect app/chat.tsx to the existing proven relay/proof engine.

REPORT PATH:
docs/chat-e2e/MAURIMESH_CHAT_E2E_3DEVICE_DELIVERY_PROOF_V1.md
