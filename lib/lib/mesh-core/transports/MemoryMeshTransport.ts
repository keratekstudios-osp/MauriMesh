import type { MeshPacket } from "../types";
import type { IMeshTransport, ReceiveCallback } from "../MeshTransportAdapter";

const LOOPBACK_DELAY_MS = 20;

export class MemoryMeshTransport implements IMeshTransport {
  readonly name = "MemoryMeshTransport";

  private listeners = new Set<ReceiveCallback>();
  private running = false;
  private deliveryLog: string[] = [];

  async start(): Promise<void> {
    this.running = true;
    this.log("Transport started");
  }

  async stop(): Promise<void> {
    this.running = false;
    this.listeners.clear();
    this.log("Transport stopped");
  }

  async send(packet: MeshPacket): Promise<boolean> {
    if (!this.running) {
      this.log(`SEND FAILED (not running): ${packet.id}`);
      return false;
    }

    this.log(`SEND → ${packet.toNodeId} [${packet.type}] id=${packet.id}`);

    setTimeout(() => {
      if (!this.running) return;
      this.log(`DELIVER → ${packet.toNodeId} [${packet.type}] id=${packet.id}`);
      const copy = { ...packet };
      for (const cb of this.listeners) {
        try {
          cb(copy);
        } catch (err) {
          this.log(`RECEIVE ERROR: ${String(err)}`);
        }
      }
    }, LOOPBACK_DELAY_MS);

    return true;
  }

  onReceive(callback: ReceiveCallback): () => void {
    this.listeners.add(callback);
    return () => this.listeners.delete(callback);
  }

  getDeliveryLog(): readonly string[] {
    return this.deliveryLog;
  }

  clearLog(): void {
    this.deliveryLog = [];
  }

  private log(msg: string): void {
    const entry = `[${new Date().toISOString()}] ${msg}`;
    this.deliveryLog.push(entry);
    if (this.deliveryLog.length > 500) {
      this.deliveryLog.splice(0, 100);
    }
  }
}
