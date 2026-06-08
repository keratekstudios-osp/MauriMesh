---
name: Auto-commit sweeps untracked files into the current commit
description: Why an unrelated change's commit can contain another effort's generated files, and how to handle it
---

# Auto-commit stages the whole working tree

The end-of-task auto-commit stages the ENTIRE working tree, not just the files
you edited. When other efforts ship generator/install scripts that write
`.ts`/`.kt` files into the tree, any already-run output sits untracked. If it is
present when an unrelated change finishes, that output gets folded into the
unrelated commit.

**Consequence:** code review reviews the full git diff, so it flags issues in
generated files you never authored (e.g. an auth bypass in a runtime-attestation
engine surfacing inside an unrelated screen-wiring review).

**How to apply:**
- Before finishing, run `git show --stat HEAD` (or check `git status`) to see what
  actually landed. Don't assume the commit holds only your edits.
- If a reviewer flags leaked code now sitting on `main`, fix the minimal
  security-blocking issue so `main` is safe, but do NOT implement the other
  effort's full feature. Note the leak in the commit message.
- Do NOT delete/revert guardrailed native trees (`android/`, `rust/`,
  routing/packet engines) to un-pollute — that violates the BLE no-touch
  guardrail. Leave them; only harden plain TS/security issues.
- Beware regeneration: the owning generator script still holds the flawed
  version and will overwrite your fix when it runs. A regression test under
  `tests/` survives regeneration and catches the flaw if it returns.

**Proof-scope invariant (truth boundary):** promotion to `real_native` /
`proofCapable=true` must require a validated native attestation
(`hasRealNativeMinimum`) on EVERY path; an absent attestation must never promote.
The deeper open risk: an unauthenticated HTTP attestation endpoint still trusts
self-asserted fields — true trust needs a signed/authenticated attestation
source, which belongs to the attestation feature, not to unrelated screen wiring.
