import { sql } from "drizzle-orm";
import { pgTable, text, integer, timestamp, varchar, jsonb } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";

// ── Operators ─────────────────────────────────────────────────────────────────
// Operator clearance records. Admin actions (suspend / reinstate) update status
// here so they persist across sessions instead of living in in-file mock arrays.

export const operators = pgTable("operators", {
  id:             varchar("id", { length: 128 }).primaryKey().default(sql`gen_random_uuid()`),
  nodeId:         text("node_id").notNull().unique(),
  name:           text("name").notNull().default("Unknown Operator"),
  clearanceLevel: text("clearance_level").notNull().default("standard"),
  status:         text("status").notNull().default("active"),
  suspendedReason: text("suspended_reason"),
  createdAt:      timestamp("created_at", { withTimezone: true }).notNull().default(sql`now()`),
  updatedAt:      timestamp("updated_at", { withTimezone: true }).notNull().default(sql`now()`),
});

export const insertOperatorSchema = createInsertSchema(operators).omit({
  id: true,
  createdAt: true,
  updatedAt: true,
});
export type InsertOperator = z.infer<typeof insertOperatorSchema>;
export type Operator = typeof operators.$inferSelect;

// ── Accepted Docs ─────────────────────────────────────────────────────────────
// Tracks acceptance of legal documents (NDAs, terms) by operators / nodes.

export const acceptedDocs = pgTable("accepted_docs", {
  id:         varchar("id", { length: 128 }).primaryKey().default(sql`gen_random_uuid()`),
  nodeId:     text("node_id").notNull(),
  docType:    text("doc_type").notNull(),
  docVersion: text("doc_version").notNull().default("1.0"),
  acceptedAt: timestamp("accepted_at", { withTimezone: true }).notNull().default(sql`now()`),
  createdAt:  timestamp("created_at", { withTimezone: true }).notNull().default(sql`now()`),
});

export const insertAcceptedDocSchema = createInsertSchema(acceptedDocs).omit({
  id: true,
  acceptedAt: true,
  createdAt: true,
});
export type InsertAcceptedDoc = z.infer<typeof insertAcceptedDocSchema>;
export type AcceptedDoc = typeof acceptedDocs.$inferSelect;

// ── Admin Commands ────────────────────────────────────────────────────────────
// Server-side history of admin console commands (suspend operator, flush queue,
// accept NDA, etc.) so the command log survives restarts.

export const adminCommands = pgTable("admin_commands", {
  id:        varchar("id", { length: 128 }).primaryKey().default(sql`gen_random_uuid()`),
  actor:     text("actor").notNull().default("unknown"),
  command:   text("command").notNull(),
  args:      jsonb("args").notNull().default(sql`'{}'::jsonb`),
  result:    text("result").notNull().default("ok"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().default(sql`now()`),
});

export const insertAdminCommandSchema = createInsertSchema(adminCommands).omit({
  id: true,
  createdAt: true,
});
export type InsertAdminCommand = z.infer<typeof insertAdminCommandSchema>;
export type AdminCommand = typeof adminCommands.$inferSelect;
