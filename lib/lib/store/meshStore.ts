import { create } from "zustand";
import type { BlePeer } from "../mesh/useBleTransport";

export interface ChatMessage {
  id: string;
  text: string;
  sender: "me" | "other";
  senderId?: string;
  timestamp: string;
  timeMs: number;
  status: "queued" | "sending" | "sent" | "delivered" | "ack_confirmed" | "failed" | "read";
  transport?: "ble" | "bridge";
  read: boolean;
}

export interface TransportStatus {
  bleReady: boolean;
  bridgeOnline: boolean;
  queueSize: number;
}

export interface IncomingCall {
  callId: string;
  mode: string;
  from: string;
}

interface MeshState {
  messages: ChatMessage[];
  peers: BlePeer[];
  transportStatus: TransportStatus;
  incomingCall: IncomingCall | null;
  /** RouteScore [0,1] per peer nodeId — updated by useMeshTransport after each send/ACK. */
  routeScores: Record<string, number>;
  addMessage: (msg: ChatMessage) => void;
  hydrateMessages: (msgs: ChatMessage[]) => void;
  updateMessageStatus: (id: string, status: ChatMessage["status"]) => void;
  markMessageRead: (id: string) => void;
  setPeers: (peers: BlePeer[]) => void;
  removePeer: (nodeId: string) => void;
  setTransportStatus: (partial: Partial<TransportStatus>) => void;
  setIncomingCall: (call: IncomingCall | null) => void;
  setRouteScore: (peerId: string, score: number) => void;
}

export const useMeshStore = create<MeshState>((set) => ({
  messages: [],
  peers: [],
  transportStatus: { bleReady: false, bridgeOnline: false, queueSize: 0 },
  incomingCall: null,
  routeScores: {},

  addMessage: (msg) =>
    set((state) => {
      if (state.messages.some((m) => m.id === msg.id)) return state;
      const next = [msg, ...state.messages].sort((a, b) => b.timeMs - a.timeMs);
      return { messages: next };
    }),

  hydrateMessages: (msgs) =>
    set((state) => {
      const existingIds = new Set(state.messages.map((m) => m.id));
      const fresh = msgs.filter((m) => !existingIds.has(m.id));
      if (fresh.length === 0) return state;
      const all = [...state.messages, ...fresh].sort(
        (a, b) => b.timeMs - a.timeMs
      );
      return { messages: all };
    }),

  updateMessageStatus: (id, status) =>
    set((state) => ({
      messages: state.messages.map((m) => (m.id === id ? { ...m, status } : m)),
    })),

  markMessageRead: (id) =>
    set((state) => ({
      messages: state.messages.map((m) =>
        m.id === id ? { ...m, read: true, status: "read" as const } : m
      ),
    })),

  setPeers: (peers) => set({ peers }),

  removePeer: (nodeId) =>
    set((state) => ({ peers: state.peers.filter((p) => p.nodeId !== nodeId) })),

  setTransportStatus: (partial) =>
    set((state) => ({
      transportStatus: { ...state.transportStatus, ...partial },
    })),

  setIncomingCall: (call) => set({ incomingCall: call }),

  setRouteScore: (peerId, score) =>
    set((state) => ({
      routeScores: { ...state.routeScores, [peerId]: score },
    })),
}));
