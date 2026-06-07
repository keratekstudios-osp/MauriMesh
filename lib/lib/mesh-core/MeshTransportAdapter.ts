import type { MeshPacket } from "./types";

export type ReceiveCallback = (packet: MeshPacket) => void;

export interface IMeshTransport {
  readonly name: string;
  start(): Promise<void>;
  stop(): Promise<void>;
  send(packet: MeshPacket): Promise<boolean>;
  onReceive(callback: ReceiveCallback): () => void;
}
