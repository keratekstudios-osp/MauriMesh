#!/usr/bin/env tsx
/**
 * rollback.ts — MauriMesh agent safety rollback
 *
 * Usage:
 *   pnpm --filter @workspace/scripts run rollback              # interactive list + prompt
 *   pnpm --filter @workspace/scripts run rollback -- --list    # list only, no prompt
 *   pnpm --filter @workspace/scripts run rollback -- --sha <sha>      # prompted rollback
 *   pnpm --filter @workspace/scripts run rollback -- --sha <sha> --yes  # auto-confirmed
 *
 * Security notes:
 *   - All git calls use spawnSync/execFileSync with argument arrays (no shell interpolation).
 *   - SHA values are validated against /^[0-9a-f]{4,40}$/i before any git operation.
 *   - Even --sha mode requires explicit confirmation unless --yes is passed.
 */

import { execFileSync, spawnSync } from "node:child_process";
import * as readline from "node:readline";

// ---------------------------------------------------------------------------
// Helpers — no user input is ever interpolated into a shell string
// ---------------------------------------------------------------------------

function git(...args: string[]): string {
  const result = spawnSync("git", args, { encoding: "utf8" });
  return (result.stdout ?? "").trim();
}

/** Strict SHA validation — 4-40 lowercase hex chars only */
function isValidSha(sha: string): boolean {
  return /^[0-9a-f]{4,40}$/i.test(sha);
}

function bold(s: string)   { return `\x1b[1m${s}\x1b[0m`; }
function green(s: string)  { return `\x1b[32m${s}\x1b[0m`; }
function yellow(s: string) { return `\x1b[33m${s}\x1b[0m`; }
function red(s: string)    { return `\x1b[31m${s}\x1b[0m`; }
function cyan(s: string)   { return `\x1b[36m${s}\x1b[0m`; }
function dim(s: string)    { return `\x1b[2m${s}\x1b[0m`; }

// ---------------------------------------------------------------------------
// List checkpoint commits
// ---------------------------------------------------------------------------

interface CheckpointEntry { sha: string; message: string; date: string; }

function listCheckpoints(n = 25): CheckpointEntry[] {
  // Use argument array — grep pattern is passed as a single argument, no shell
  const raw = git(
    "log", `--format=%h|%ai|%s`, `-n`, String(n), "--grep=^checkpoint:"
  );
  if (!raw) return [];
  return raw.split("\n").map((line) => {
    const [sha = "", date = "", ...rest] = line.split("|");
    return { sha: sha.trim(), date: date.trim(), message: rest.join("|").trim() };
  }).filter((e) => e.sha);
}

function printCheckpoints(entries: CheckpointEntry[]): void {
  console.log(bold("\n── Checkpoint History ────────────────────────────────────────\n"));
  if (entries.length === 0) {
    console.log(yellow("  No checkpoint commits found.\n"));
    console.log(dim("  Create one with:"));
    console.log(dim("    pnpm --filter @workspace/scripts run checkpoint -- --label <label>\n"));
    return;
  }
  for (let i = 0; i < entries.length; i++) {
    const e = entries[i]!;
    const dateStr = e.date.substring(0, 19).replace("T", " ");
    console.log(
      `  ${dim(String(i + 1).padStart(2))}. ${cyan(e.sha)}  ${dim(dateStr)}  ${e.message}`
    );
  }
  console.log();
}

// ---------------------------------------------------------------------------
// Rollback to a validated SHA
// ---------------------------------------------------------------------------

function doRollback(sha: string): void {
  // Validate SHA before any git operation
  if (!isValidSha(sha)) {
    console.error(red(`  ✗ Invalid SHA format: "${sha}"`));
    console.error(red("    SHAs must be 4-40 hexadecimal characters.\n"));
    process.exit(1);
  }

  // Verify the commit exists using execFileSync with argument array
  const objType = spawnSync("git", ["cat-file", "-t", sha], { encoding: "utf8" });
  if (objType.status !== 0 || (objType.stdout ?? "").trim() !== "commit") {
    console.error(red(`  ✗ SHA "${sha}" is not a commit in this repository. Aborting.\n`));
    process.exit(1);
  }

  const branch  = git("rev-parse", "--abbrev-ref", "HEAD");
  const current = git("rev-parse", "--short", "HEAD");

  console.log(bold("\n── Rollback ──────────────────────────────────────────────────\n"));
  console.log(`  Current branch: ${cyan(branch || "(detached)")}`);
  console.log(`  Current SHA:    ${cyan(current)}`);
  console.log(`  Target SHA:     ${cyan(sha)}`);
  console.log();
  console.log(yellow("  ⚠ This will HARD-RESET the working tree to the chosen checkpoint."));
  console.log(yellow("    ALL uncommitted changes will be permanently discarded."));
  console.log(yellow("    Commits after the target remain reachable via `git reflog`.\n"));

  // Perform the reset using execFileSync with argument array — no shell
  try {
    execFileSync("git", ["reset", "--hard", sha], { stdio: "inherit" });
    const newSha = git("rev-parse", "--short", "HEAD");
    console.log();
    console.log(green(`  ✓ Rolled back to ${newSha}.`));
    console.log(green("  ✓ Working tree restored to checkpoint state.\n"));
  } catch {
    console.error(red("  ✗ git reset --hard failed."));
    console.error(red("  ✗ Run `git status` and `git reflog` to inspect and recover.\n"));
    process.exit(1);
  }

  console.log("──────────────────────────────────────────────────────────────\n");
}

// ---------------------------------------------------------------------------
// Prompt helpers
// ---------------------------------------------------------------------------

function prompt(question: string): Promise<string> {
  return new Promise((resolve) => {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    rl.question(question, (answer) => { rl.close(); resolve(answer.trim()); });
  });
}

/**
 * Confirm rollback to a SHA. Always shows target and asks the user to type
 * "YES" explicitly. Returns true if confirmed.
 */
async function confirmRollback(sha: string): Promise<boolean> {
  console.log(yellow(`\n  Target SHA: ${sha}`));
  console.log(yellow("  This will HARD-RESET and discard all uncommitted changes.\n"));
  const answer = await prompt(red("  Type YES to confirm rollback (anything else cancels): "));
  return answer === "YES";
}

async function interactivePrompt(entries: CheckpointEntry[]): Promise<void> {
  if (entries.length === 0) {
    console.log(red("  No checkpoints available to roll back to.\n"));
    process.exit(0);
  }

  const answer = await prompt(
    `  Enter number (1–${entries.length}) or full SHA (then press Enter): `
  );

  if (answer === "q" || answer === "Q" || answer === "") {
    console.log(yellow("\n  Rollback cancelled.\n"));
    process.exit(0);
  }

  const num = parseInt(answer, 10);
  let targetSha: string | undefined;

  if (!isNaN(num) && num >= 1 && num <= entries.length) {
    targetSha = entries[num - 1]!.sha;
  } else if (isValidSha(answer)) {
    targetSha = answer;
  } else {
    console.error(red(`\n  ✗ Invalid input: "${answer}". Enter a list number or a git SHA.\n`));
    process.exit(1);
  }

  const confirmed = await confirmRollback(targetSha);
  if (!confirmed) {
    console.log(yellow("\n  Rollback cancelled.\n"));
    process.exit(0);
  }

  doRollback(targetSha);
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

const args     = process.argv.slice(2);
const listOnly = args.includes("--list");
const autoYes  = args.includes("--yes");
const shaIdx   = args.indexOf("--sha");
const rawSha   = shaIdx !== -1 ? (args[shaIdx + 1] ?? "") : "";

const entries = listCheckpoints(25);
printCheckpoints(entries);

if (listOnly) process.exit(0);

(async () => {
  if (rawSha) {
    // --sha mode: validate first, then always confirm unless --yes was passed
    if (!isValidSha(rawSha)) {
      console.error(red(`  ✗ Invalid SHA format: "${rawSha}"`));
      console.error(red("    SHAs must be 4-40 hexadecimal characters.\n"));
      process.exit(1);
    }

    if (autoYes) {
      // Caller explicitly opted into auto-confirm — proceed directly
      console.log(yellow("  --yes flag detected: skipping interactive confirmation."));
      doRollback(rawSha);
    } else {
      // Require explicit "YES" even in direct --sha mode
      const confirmed = await confirmRollback(rawSha);
      if (!confirmed) {
        console.log(yellow("\n  Rollback cancelled.\n"));
        process.exit(0);
      }
      doRollback(rawSha);
    }
  } else {
    // Interactive mode
    await interactivePrompt(entries);
  }
})().catch((err: unknown) => {
  console.error(red(`\n  ✗ Unexpected error: ${String(err)}\n`));
  process.exit(1);
});
