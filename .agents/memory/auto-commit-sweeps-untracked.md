---
name: Auto-commit sweeps untracked files from other tasks
description: Why an unrelated task's commit can contain another task's install-script output, and how to handle it
---

# Auto-commit sweeps untracked files into the current task's commit

The end-of-task auto-commit stages the ENTIRE working tree, not just the files
you edited. In MauriMesh, several queued tasks ship `install-task-NNN-*.sh`
scripts that generate `.ts`/`.kt` files into the tree. If those scripts have
been run (leaving untracked output) before an unrelated task finishes, that
output gets swept into the unrelated task's commit.

**Consequence:** code review reviews the full git diff, so it will flag issues
in leaked files you never authored (e.g. an auth bypass from task #223's
`RuntimeTruthEngine.ts` / `runtime-verify.ts` surfaced inside task #62's review).

**How to apply:**
- Before finishing, run `git show --stat HEAD` (or check `git status`) to see what
  actually landed in your commit. Don't assume it's only your edits.
- If a reviewer flags leaked code that now sits on `main`, fix the minimal
  security-blocking issue (main must be safe) but do NOT implement the other
  task's full feature. Note the leak + which task owns it in the commit message.
- Do NOT delete/revert `android/`, `rust/`, or other guardrailed native files to
  un-pollute — that violates the BLE no-touch guardrail. Leave them; only harden
  plain TS/security issues.
- Beware regeneration: the owning task's install script still holds the flawed
  version and will overwrite your fix when it runs. A regression test under
  `tests/` survives regeneration and will catch the flaw if it returns.

**Proof-scope invariant (truth boundary):** promotion to `real_native` /
`proofCapable=true` must require a validated native attestation
(`hasRealNativeMinimum`) on EVERY path. An absent attestation must never promote.
