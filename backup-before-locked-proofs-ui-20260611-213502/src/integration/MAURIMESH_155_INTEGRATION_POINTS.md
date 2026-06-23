# MauriMesh 155+ Runtime Integration Points

This file converts the Replit Agent integration prompt into direct developer instructions that can be followed from shell or by editing files manually.

## Do not delete

- Existing BLE files
- Existing routing files
- Existing ACK files
- Existing store-forward files
- Existing UI files
- Existing native Android/iOS files

## Main bridge

Use:

```ts
import { getMauriRuntimeIntegrationBridge } from "../integration/mauriRuntimeIntegrationBridge";

const bridge = getMauriRuntimeIntegrationBridge();

