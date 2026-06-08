import {
  sqliteTable,
  text as sqliteText,
  integer as sqliteInteger,
} from "drizzle-orm/sqlite-core";
import { sql } from "drizzle-orm";
import { pgTable, text, integer, timestamp, varchar, real, boolean, jsonb } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";

export const meshPeers = pgTable("mesh_peers", {
  id: varchar("id", { length: 128 }).primaryKey(),
  label: text("label").notNull().default("Unknown"),
  transport: text("transport").notNull().default("ble"),
  status: text("status").notNull().default("online"),
  signal: integer("signal").notNull().default(50),
  trust: integer("trust").notNull().default(50),
  rssi: integer("rssi"),
  latencyMs: integer("latency_ms"),
  jumpCode: text("jump_code"),
  lastSeen: timestamp("last_seen", { withTimezone: true }).notNull().default(sql`now()`),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().default(sql`now()`),
});

export const insertMeshPeerSchema = createInsertSchema(meshPeers).omit({ createdAt: true });
export type InsertMeshPeer = z.infer<typeof insertMeshPeerSchema>;
export type MeshPeer = typeof meshPeers.$inferSelect;

export const meshEvents = pgTable("mesh_events", {
  id: varchar("id", { length: 128 }).primaryKey().default(sql`gen_random_uuid()`),
  type: text("type").notNull(),
  fromNode: text("from_node").notNull(),
  toNode: text("to_node").notNull(),
  jumpCode: text("jump_code"),
  decision: text("decision"),
  transport: text("transport"),
  delivered: integer("delivered").notNull().default(0),
  latencyMs: real("latency_ms"),
  payloadHash: text("payload_hash"),
  integrityStatus: text("integrity_status").notNull().default("not_checked"),
  ts: timestamp("ts", { withTimezone: true }).notNull().default(sql`now()`),
});

export const insertMeshEventSchema = createInsertSchema(meshEvents).omit({ id: true });
export type InsertMeshEvent = z.infer<typeof insertMeshEventSchema>;
export type MeshEvent = typeof meshEvents.$inferSelect;

export const meshUsers = pgTable("mesh_users", {
  username:     text("username").primaryKey(),
  passwordHash: text("password_hash").notNull(),
  nodeId:       text("node_id").notNull().unique(),
  createdAt:    timestamp("created_at", { withTimezone: true }).notNull().default(sql`now()`),
});

export type MeshUser = typeof meshUsers.$inferSelect;

export const meshSessions = pgTable("mesh_sessions", {
  token: varchar("token", { length: 128 }).primaryKey(),
  nodeId: text("node_id").notNull(),
  username: text("username").notNull(),
  role: varchar("role", { length: 32 }).notNull().default("user"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().default(sql`now()`),
  expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
});

export type MeshSession = typeof meshSessions.$inferSelect;

// ── Trust Records ─────────────────────────────────────────────────────────────

export const trustRecords = pgTable("trust_records", {
  peerId:          varchar("peer_id", { length: 128 }).primaryKey(),
  peerLabel:       text("peer_label").notNull().default("Unknown"),
  role:            text("role").notNull().default("peer"),
  trustScore:      real("trust_score").notNull().default(0.5),
  reputationScore: real("reputation_score").notNull().default(0.5),
  deliveryCount:   integer("delivery_count").notNull().default(0),
  ackCount:        integer("ack_count").notNull().default(0),
  failureCount:    integer("failure_count").notNull().default(0),
  timeoutCount:    integer("timeout_count").notNull().default(0),
  warningCount:    integer("warning_count").notNull().default(0),
  firstSeen:       timestamp("first_seen",  { withTimezone: true }).notNull().default(sql`now()`),
  lastSeen:        timestamp("last_seen",   { withTimezone: true }).notNull().default(sql`now()`),
  updatedAt:       timestamp("updated_at",  { withTimezone: true }).notNull().default(sql`now()`),
});

export const insertTrustRecordSchema = createInsertSchema(trustRecords).omit({ firstSeen: true });
export type InsertTrustRecord = z.infer<typeof insertTrustRecordSchema>;
export type TrustRecord = typeof trustRecords.$inferSelect;

// ── Store-Forward Queue ───────────────────────────────────────────────────────

export const storeForwardQueue = pgTable("store_forward_queue", {
  id:        varchar("id", { length: 128 }).primaryKey().default(sql`gen_random_uuid()`),
  toPeerId:  text("to_peer_id").notNull(),
  body:      text("body").notNull(),
  status:    text("status").notNull().default("queued"),
  attempts:  integer("attempts").notNull().default(0),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().default(sql`now()`),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().default(sql`now()`),
});

export const insertStoreForwardSchema = createInsertSchema(storeForwardQueue).omit({ id: true, createdAt: true });
export type InsertStoreForward = z.infer<typeof insertStoreForwardSchema>;
export type StoreForwardMessage = typeof storeForwardQueue.$inferSelect;

// ── Proof Ledger ──────────────────────────────────────────────────────────────

export const proofLedger = pgTable("proof_ledger", {
  id:             varchar("id", { length: 128 }).primaryKey().default(sql`gen_random_uuid()`),
  eventType:      text("event_type").notNull(),
  runtimeMode:    text("runtime_mode").notNull().default("api_simulation"),
  deviceId:       text("device_id"),
  peerId:         text("peer_id"),
  packetId:       text("packet_id"),
  routeId:        text("route_id"),
  ackId:          text("ack_id"),
  source:         text("source").notNull().default("api"),
  verified:       boolean("verified").notNull().default(false),
  rawLogExcerpt:  text("raw_log_excerpt"),
  ts:             timestamp("ts", { withTimezone: true }).notNull().default(sql`now()`),
});

export type ProofEntry = typeof proofLedger.$inferSelect;

// ── Runtime Errors ────────────────────────────────────────────────────────────

export const runtimeErrors = pgTable("runtime_errors", {
  id:             varchar("id", { length: 128 }).primaryKey().default(sql`gen_random_uuid()`),
  subsystem:      text("subsystem").notNull(),
  severity:       text("severity").notNull().default("error"),
  message:        text("message").notNull(),
  stack:          text("stack"),
  runtimeMode:    text("runtime_mode"),
  recoveryAction: text("recovery_action"),
  resolved:       boolean("resolved").notNull().default(false),
  ts:             timestamp("ts", { withTimezone: true }).notNull().default(sql`now()`),
});

export type RuntimeError = typeof runtimeErrors.$inferSelect;

// ── API Activity Events ────────────────────────────────────────────────────────
// Records activity synced from mobile clients (proof events, simulation events).
// scope must be "simulation" for any event not originating from physical BLE proof.

export const apiActivityEvents = pgTable("api_activity_events", {
  id:        varchar("id", { length: 128 }).primaryKey().default(sql`gen_random_uuid()`),
  scope:     varchar("scope", { length: 64 }).notNull(),
  eventType: varchar("event_type", { length: 128 }).notNull(),
  message:   text("message").notNull(),
  metadata:  jsonb("metadata").notNull().default(sql`'{}'::jsonb`),
  userId:    text("user_id").notNull().default("unknown"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().default(sql`now()`),
});

export const insertApiActivityEventSchema = createInsertSchema(apiActivityEvents).omit({ id: true, createdAt: true });
export type InsertApiActivityEvent = z.infer<typeof insertApiActivityEventSchema>;
export type ApiActivityEvent = typeof apiActivityEvents.$inferSelect;


export const routeSafetyBlacklist = sqliteTable("route_safety_blacklist", {
  id: sqliteText("id").primaryKey(),
  routeKey: sqliteText("route_key").notNull(),
  reason: sqliteText("reason").notNull(),
  failureCount: sqliteInteger("failure_count").notNull().default(1),
  blacklistedAt: sqliteInteger("blacklisted_at", { mode: "timestamp" }).notNull(),
  expiresAt: sqliteInteger("expires_at", { mode: "timestamp" }).notNull(),
  source: sqliteText("source").notNull().default("ROUTE_SAFETY_PERSISTENCE_SERVER_20260608_A"),
});
