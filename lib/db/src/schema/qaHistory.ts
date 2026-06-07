import { sql } from "drizzle-orm";
import { pgTable, serial, text, integer, timestamp, uniqueIndex, check } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";

export const qaHistory = pgTable(
  "qa_history",
  {
    id: serial("id").primaryKey(),
    suiteName: text("suite_name").notNull(),
    passed: integer("passed").notNull(),
    tests: integer("tests").notNull(),
    status: text("status").notNull(),
    ts: timestamp("ts", { withTimezone: true }).notNull().default(sql`now()`),
  },
  (table) => [
    uniqueIndex("qa_history_ts_suite_name_uniq").on(table.ts, table.suiteName),
    check("qa_history_status_check", sql`${table.status} IN ('pass', 'fail')`),
  ],
);

export const insertQaHistorySchema = createInsertSchema(qaHistory).omit({ id: true });
export type InsertQaHistory = z.infer<typeof insertQaHistorySchema>;
export type QaHistory = typeof qaHistory.$inferSelect;
