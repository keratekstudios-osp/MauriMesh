#!/usr/bin/env tsx
/**
 * checkpoint.ts — MauriMesh agent safety checkpoint
 *
 * Usage:
 *   pnpm --filter @workspace/scripts run checkpoint -- --label "pre-ui-polish"
 *   pnpm --filter @workspace/scripts run checkpoint -- --audit
 */

import { execFileSync, spawnSync } from "node:child_process";

// ---------------------------------------------------------------------------
// Helpers — all git calls use execFileSync/spawnSync with argument arrays.
// No user-supplied value is ever interpolated into a shell string.
// ---------------------------------------------------------------------------

function git(...args: string[]): string {
  const result = spawnSync("git", args, { encoding: "utf8" });
  return (result.stdout ?? "").trim();
}

function gitOrEmpty(...args: string[]): string {
  try { return git(...args); } catch { return ""; }
}

/** Sanitise a checkpoint label: keep only safe characters. */
function sanitiseLabel(raw: string): string {
  // Allow alphanumeric, hyphens, underscores, spaces, dots, slashes
  return raw.replace(/[^\w\s\-./]/g, "").trim().slice(0, 120);
}

function bold(s: string)   { return `\x1b[1m${s}\x1b[0m`; }
function green(s: string)  { return `\x1b[32m${s}\x1b[0m`; }
function yellow(s: string) { return `\x1b[33m${s}\x1b[0m`; }
function red(s: string)    { return `\x1b[31m${s}\x1b[0m`; }
function cyan(s: string)   { return `\x1b[36m${s}\x1b[0m`; }

// ---------------------------------------------------------------------------
// Risk-category patterns for --audit
// ---------------------------------------------------------------------------

interface RiskCategory { name: string; patterns: RegExp[]; }

const RISK_CATEGORIES: RiskCategory[] = [
  {
    name: "deps",
    patterns: [/package\.json$/, /pnpm-lock\.yaml$/, /pnpm-workspace\.yaml$/],
  },
  {
    name: "config",
    patterns: [
      /app\.json$/, /eas\.json$/, /metro\.config\.[jt]s$/,
      /babel\.config\.[jt]s$/, /vite\.config\.[jt]s$/, /tsconfig.*\.json$/,
    ],
  },
  {
    name: "ui",
    patterns: [
      /app\/.*\.tsx$/, /src\/pages\/.*\.tsx$/,
      /src\/components\/.*\.tsx$/, /artifacts\/.*\/src\/.*\.tsx$/,
    ],
  },
  {
    name: "routing",
    patterns: [
      // Matches App.tsx at any depth, including repo root (no leading slash required)
      /(^|\/)App\.tsx$/, /\/_layout\.tsx$/,
      /app\/\(tabs\)\//, /(^|\/)src\/App\.tsx$/,
      /artifacts\/.*\/src\/App\.tsx$/,
    ],
  },
];

function classifyFile(filePath: string): string[] {
  return RISK_CATEGORIES
    .filter((cat) => cat.patterns.some((re) => re.test(filePath)))
    .map((cat) => cat.name);
}

function runAudit(): boolean {
  console.log(bold("\n── Pre-change audit ──────────────────────────────────────────\n"));

  // Intentionally broad scope: staged + unstaged modified + untracked files.
  // This is safer than staged-only because it catches changes the agent may not
  // have staged yet and gives an accurate picture of the full blast radius.
  const trackedDiff = git("diff", "--name-only", "HEAD");
  const staged      = git("diff", "--name-only", "--cached");
  const untracked   = git("ls-files", "--others", "--exclude-standard");

  const allFiles = [
    ...trackedDiff.split("\n"),
    ...staged.split("\n"),
    ...untracked.split("\n"),
  ]
    .map((f) => f.trim())
    .filter(Boolean)
    .filter((f, i, arr) => arr.indexOf(f) === i);

  if (allFiles.length === 0) {
    console.log(green("  ✓ No uncommitted changes — working tree is clean."));
    console.log("──────────────────────────────────────────────────────────────\n");
    return true;
  }

  const touchedCategories = new Map<string, string[]>();
  for (const file of allFiles) {
    for (const cat of classifyFile(file)) {
      const list = touchedCategories.get(cat) ?? [];
      list.push(file);
      touchedCategories.set(cat, list);
    }
  }

  const catNames = [...touchedCategories.keys()];
  console.log(`  Files inspected:          ${bold(String(allFiles.length))}`);
  console.log(`  Risk categories touched:  ${bold(String(catNames.length))}\n`);

  for (const cat of catNames) {
    const files = touchedCategories.get(cat)!;
    console.log(`  ${cyan(`[${cat}]`)} — ${files.length} file(s):`);
    for (const f of files) console.log(`    • ${f}`);
    console.log();
  }

  let clean = true;
  if (catNames.length > 1) {
    clean = false;
    console.log(yellow("  ⚠ WARNING: Changes span multiple risk categories."));
    console.log(yellow(`    Categories: ${catNames.join(", ")}`));
    console.log(yellow("    Consider splitting into separate focused commits.\n"));
  } else if (catNames.length === 0) {
    console.log(green("  ✓ No high-risk files touched."));
  } else {
    console.log(green(`  ✓ Single risk category (${catNames[0]}) — no cross-category conflict.`));
  }

  console.log("──────────────────────────────────────────────────────────────\n");
  return clean;
}

// ---------------------------------------------------------------------------
// Build status capture
// ---------------------------------------------------------------------------

type BuildStatus = "pass" | "fail" | "unknown";

function captureBuildStatus(checkBuild: boolean): BuildStatus {
  if (!checkBuild) return "unknown";
  console.log("  Running typecheck (pnpm run typecheck)…");
  const result = spawnSync("pnpm", ["run", "typecheck"], {
    encoding: "utf8",
    timeout: 120_000,
    cwd: process.cwd(),
  });
  if (result.status === 0) {
    console.log(green("  ✓ typecheck passed."));
    return "pass";
  }
  console.log(red(`  ✗ typecheck failed (exit ${String(result.status ?? "?")}).`));
  console.log(red("    Checkpoint still created — resolve errors before next task."));
  return "fail";
}

// ---------------------------------------------------------------------------
// Checkpoint
// ---------------------------------------------------------------------------

function runCheckpoint(label: string, checkBuild: boolean): void {
  const safeLabel = sanitiseLabel(label);
  if (!safeLabel) {
    console.error(red("  ✗ Label is empty after sanitisation. Use alphanumeric characters.\n"));
    process.exit(1);
  }

  const branch     = gitOrEmpty("rev-parse", "--abbrev-ref", "HEAD");
  const sha        = gitOrEmpty("rev-parse", "--short", "HEAD");
  const ts         = new Date().toISOString();
  const buildStatus: BuildStatus = captureBuildStatus(checkBuild);

  console.log(bold("\n── MauriMesh Checkpoint ──────────────────────────────────────\n"));
  console.log(`  Branch:       ${cyan(branch || "(detached)")}`);
  console.log(`  Current SHA:  ${cyan(sha || "n/a")}`);
  console.log(`  Timestamp:    ${ts}`);
  // "unknown" is an accepted and documented build status — it means the agent
  // did not run a build check at checkpoint time. Run with --check-build to
  // capture a real pass/fail result. See AGENTS.md §6 for details.
  console.log(`  Build status: ${
    buildStatus === "pass"    ? green("pass") :
    buildStatus === "fail"    ? red("FAIL — fix before proceeding") :
    yellow("unknown (pass --check-build to capture; unknown is acceptable for pre-change checkpoints)")
  }`);
  console.log(`  Label:        ${bold(safeLabel)}\n`);

  const status = git("status", "--short");
  if (!status) {
    console.log(green("  Working tree is clean — nothing new to checkpoint.\n"));
    console.log("──────────────────────────────────────────────────────────────\n");
    return;
  }

  console.log("  Files being staged:");
  for (const line of status.split("\n")) console.log(`    ${line}`);
  console.log();

  // Stage using execFileSync with argument array — no shell interpolation
  execFileSync("git", ["add", "."]);

  // Commit with the safe label — single argument to -m, no shell involved
  const commitMsg = `checkpoint: ${safeLabel}`;
  const commitResult = spawnSync("git", ["commit", "-m", commitMsg, "--allow-empty"], {
    encoding: "utf8",
  });

  if (commitResult.status !== 0) {
    const out = (commitResult.stdout ?? "") + (commitResult.stderr ?? "");
    if (out.includes("nothing to commit")) {
      console.log(yellow("  Nothing new to commit — checkpoint already up-to-date."));
    } else {
      console.log(red(`  ✗ Commit failed: ${out}`));
      process.exit(1);
    }
  } else {
    const newSha = gitOrEmpty("rev-parse", "--short", "HEAD");
    console.log(green(`  ✓ Checkpoint committed: ${newSha}`));
    console.log(green(`  ✓ Message: "${commitMsg}"`));
    console.log(green(`  ✓ Build status at checkpoint: ${buildStatus}`));
  }

  console.log("\n──────────────────────────────────────────────────────────────\n");
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

const args       = process.argv.slice(2);
const auditOnly  = args.includes("--audit");
const checkBuild = args.includes("--check-build");
const labelIdx   = args.indexOf("--label");
const rawLabel   = labelIdx !== -1 ? (args[labelIdx + 1] ?? "") : "";

if (auditOnly) {
  runAudit();
  process.exit(0);
}

const auditClean = runAudit();
if (!auditClean) {
  console.log(yellow("  ⚠ Proceeding with checkpoint despite cross-category warning.\n"));
}

if (!rawLabel) {
  console.error(red("  ✗ --label is required (e.g. --label pre-ui-polish)"));
  console.error(red("  Usage: pnpm --filter @workspace/scripts run checkpoint -- --label <label>\n"));
  console.error(red("  Optional: --check-build  to run typecheck and capture build status\n"));
  process.exit(1);
}

runCheckpoint(rawLabel, checkBuild);
