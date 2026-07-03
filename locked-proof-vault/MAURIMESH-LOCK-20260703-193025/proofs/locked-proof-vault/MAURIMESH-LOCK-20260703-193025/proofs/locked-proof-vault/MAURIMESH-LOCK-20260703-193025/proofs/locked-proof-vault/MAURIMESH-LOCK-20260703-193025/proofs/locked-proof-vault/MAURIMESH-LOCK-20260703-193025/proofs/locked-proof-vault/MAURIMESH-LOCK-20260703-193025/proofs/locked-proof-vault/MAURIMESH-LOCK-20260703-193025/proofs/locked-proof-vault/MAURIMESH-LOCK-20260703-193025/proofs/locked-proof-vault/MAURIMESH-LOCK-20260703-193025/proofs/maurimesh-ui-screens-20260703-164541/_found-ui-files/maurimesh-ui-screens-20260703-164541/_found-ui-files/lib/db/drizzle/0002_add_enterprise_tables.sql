-- Migration: add enterprise persistence tables
-- Applied via: drizzle-kit push (development) / this file (production migrations)
-- Tables persist operator clearance records, legal-document acceptance, and
-- admin command history so admin actions survive across sessions.

CREATE TABLE IF NOT EXISTS "operators" (
  "id"               varchar(128) PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "node_id"          text NOT NULL,
  "name"             text DEFAULT 'Unknown Operator' NOT NULL,
  "clearance_level"  text DEFAULT 'standard' NOT NULL,
  "status"           text DEFAULT 'active' NOT NULL,
  "suspended_reason" text,
  "created_at"       timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at"       timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "operators_node_id_unique" UNIQUE ("node_id")
);

CREATE TABLE IF NOT EXISTS "accepted_docs" (
  "id"          varchar(128) PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "node_id"     text NOT NULL,
  "doc_type"    text NOT NULL,
  "doc_version" text DEFAULT '1.0' NOT NULL,
  "accepted_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_at"  timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "admin_commands" (
  "id"         varchar(128) PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "actor"      text DEFAULT 'unknown' NOT NULL,
  "command"    text NOT NULL,
  "args"       jsonb DEFAULT '{}'::jsonb NOT NULL,
  "result"     text DEFAULT 'ok' NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS "accepted_docs_node_id_idx"
  ON "accepted_docs" ("node_id");

CREATE INDEX IF NOT EXISTS "admin_commands_created_at_idx"
  ON "admin_commands" ("created_at" DESC);
