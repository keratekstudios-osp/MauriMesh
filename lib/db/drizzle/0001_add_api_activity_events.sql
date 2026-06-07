-- Migration: add api_activity_events table
-- Applied via: drizzle-kit push (development) / this file (production migrations)
-- Table stores mobile→API synced proof and simulation events.

CREATE TABLE IF NOT EXISTS "api_activity_events" (
  "id"          uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "user_id"     text NOT NULL,
  "scope"       text NOT NULL,
  "event_type"  text NOT NULL,
  "message"     text NOT NULL,
  "metadata"    jsonb,
  "created_at"  timestamp DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS "api_activity_events_user_id_idx"
  ON "api_activity_events" ("user_id");

CREATE INDEX IF NOT EXISTS "api_activity_events_scope_idx"
  ON "api_activity_events" ("scope");

CREATE INDEX IF NOT EXISTS "api_activity_events_created_at_idx"
  ON "api_activity_events" ("created_at" DESC);
