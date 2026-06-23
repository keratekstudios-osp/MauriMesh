/**
 * MauriMesh Runtime Integration Bridge
 *
 * Purpose:
 * Connect existing MauriMesh systems to the 155+ operating runtime
 * without deleting or replacing existing BLE, routing, ACK, store-forward, or UI files.
 *
 * Truth:
 * - Replit can validate logic only.
 * - Physical BLE proof requires APK + physical phones + ADB/logcat.
 */

import { Mauri155OperatingRuntime } from "../operating/mauri155OperatingRuntime";

export type MauriIntegrationEvent =
  | {
      type: "route_success";
      peerId: string;
      packetId: string;
    }
  | {
      type: "route_failure";
      peerId: string;
      packetId: string;
    }
  | {
      type: "ack_received";
      peerId: string;
      packetId: string;
    }
  | {
      type: "tikanga_warning";
      reason: string;
    }
  | {
      type: "physical_ble_required";
      reason: string;
    }
  | {
      type: "runtime_started";
    };

export class MauriRuntimeIntegrationBridge {
  private runtime: Mauri155OperatingRuntime;
  private started = false;

  constructor(runtime?: Mauri155OperatingRuntime) {
    this.runtime = runtime ?? new Mauri155OperatingRuntime();
  }

  start() {
    if (!this.started) {
      this.started = true;
      return this.runtime.start();
    }
    return this.runtime.snapshot();
  }

  feed(event: MauriIntegrationEvent) {
    if (!this.started) {
      this.start();
    }

    switch (event.type) {
      case "runtime_started":
        return this.runtime.start();

      case "route_success":
        this.runtime.teachRouteSuccess(event.peerId, event.packetId);
        return this.runtime.snapshot();

      case "route_failure":
        this.runtime.teachRouteFailure(event.peerId, event.packetId);
        return this.runtime.snapshot();

      case "ack_received":
        this.runtime.teachAckReceived(event.peerId, event.packetId);
        return this.runtime.snapshot();

      case "tikanga_warning":
        this.runtime.teachTikangaWarning(event.reason);
        return this.runtime.snapshot();

      case "physical_ble_required":
        this.runtime.teachPhysicalBleRequired(event.reason);
        return this.runtime.snapshot();

      default:
        return this.runtime.snapshot();
    }
  }

  snapshot() {
    if (!this.started) {
      this.start();
    }
    return this.runtime.snapshot();
  }
}

let singleton: MauriRuntimeIntegrationBridge | null = null;

export function getMauriRuntimeIntegrationBridge() {
  if (!singleton) {
    singleton = new MauriRuntimeIntegrationBridge();
    singleton.start();
  }
  return singleton;
}
