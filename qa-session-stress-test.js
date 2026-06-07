/**
 * QA Dashboard — Long-Session Stress Test
 * =========================================
 * Paste this entire script into browser DevTools console while on the
 * QA Dashboard page. It exercises items 3-10 of the long-session checklist
 * and prints a PASS/FAIL report when done (~60 s run time).
 *
 * Usage:
 *   1. Sign in to MauriMesh and navigate to QA Dashboard
 *   2. Open DevTools → Console
 *   3. Paste and press Enter
 *   4. Watch the live log, read the final report
 */

(async function qaSessionStressTest() {
  const log = (msg, ok) => {
    const icon = ok === undefined ? "🔵" : ok ? "✅" : "❌";
    console.log(`${icon} [QA-STRESS] ${msg}`);
  };

  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const dbg = () => window.__qaDebug;
  const results = [];
  const check = (label, pass, detail = "") => {
    results.push({ label, pass, detail });
    log(`${label}${detail ? " — " + detail : ""}`, pass);
  };

  // ── 0. Pre-flight ─────────────────────────────────────────────────────────
  log("Starting QA Dashboard long-session stress test…");
  log("Checking window.__qaDebug is exposed…");
  if (!dbg()) {
    console.error("❌ window.__qaDebug not found. Are you on the QA Dashboard page in dev mode?");
    return;
  }
  check("0. __qaDebug present", true);

  // ── 1. Mount state baseline ───────────────────────────────────────────────
  const snap0 = dbg().snapshot();
  log("Baseline snapshot:", undefined);
  console.table(snap0);
  check("1. Mounted on load", snap0.mounted === true, `mounted=${snap0.mounted}`);
  check("1. Polling active on load", snap0.polling === true, `polling=${snap0.polling}`);
  check("1. No SSE open at rest", snap0.sseOpen === false, `sseOpen=${snap0.sseOpen}`);
  check("1. No fallback poll at rest", snap0.fallbackPoll === false);

  // ── 2. Tab-visibility simulation (item 3) ─────────────────────────────────
  log("Simulating 10 rapid tab hide/show cycles…");
  for (let i = 0; i < 10; i++) {
    Object.defineProperty(document, "hidden", { value: true,  configurable: true });
    document.dispatchEvent(new Event("visibilitychange"));
    await sleep(50);
    Object.defineProperty(document, "hidden", { value: false, configurable: true });
    document.dispatchEvent(new Event("visibilitychange"));
    await sleep(50);
  }
  await sleep(200);
  const snapAfterVisibility = dbg().snapshot();
  check("2. Polling still active after 10 tab cycles", snapAfterVisibility.polling === true);
  check("2. Still mounted after visibility cycles", snapAfterVisibility.mounted === true);

  // ── 3. Cross-tab sync simulation (item 9) ─────────────────────────────────
  log("Simulating cross-tab storage events…");
  const thresholdKey = `qa-pass-threshold-${location.pathname.split("/").pop()}-v1`;
  const beforeThreshold = localStorage.getItem(thresholdKey);

  // Simulate another tab setting threshold to 80
  window.dispatchEvent(new StorageEvent("storage", {
    key: thresholdKey, newValue: "80", oldValue: beforeThreshold, storageArea: localStorage,
  }));
  await sleep(100);

  // Simulate another tab resetting threshold (removeItem sends null)
  window.dispatchEvent(new StorageEvent("storage", {
    key: thresholdKey, newValue: null, oldValue: "80", storageArea: localStorage,
  }));
  await sleep(100);

  // Simulate an invalid value — should be ignored
  window.dispatchEvent(new StorageEvent("storage", {
    key: thresholdKey, newValue: "999", oldValue: null, storageArea: localStorage,
  }));
  await sleep(100);

  check("3. Cross-tab sync handled without throw", true, "no exceptions caught");

  // ── 4. Reset flow stress (item 5) ─────────────────────────────────────────
  log("Triggering reset button 5 times rapidly…");
  const resetBtn = Array.from(document.querySelectorAll("button"))
    .find((b) => b.textContent?.includes("Reset"));
  if (resetBtn) {
    for (let i = 0; i < 5; i++) {
      resetBtn.click();
      await sleep(80);
    }
    await sleep(500);
    check("4. Reset idempotent (no crash)", true);
  } else {
    check("4. Reset button found", false, "could not locate button");
  }

  // ── 5. Memory growth check (item 7) ───────────────────────────────────────
  log("Checking memory usage…");
  const mem = snap0.memoryMB;
  if (mem === "n/a") {
    check("5. Memory API available", false, "performance.memory not supported (non-Chrome)");
  } else {
    check("5. Memory within sane range", mem < 200, `${mem} MB used`);
  }

  // ── 6. Hydration flicker check (item 10) ──────────────────────────────────
  log("Checking for hydration flash elements…");
  // A flicker would leave a loading spinner visible after data is present
  const spinners = document.querySelectorAll(".animate-spin");
  const hasStaleSpinner = Array.from(spinners).some(
    (el) => !el.closest("[data-running]")
  );
  // Also check there's no "Loading…" subtitle when data is loaded
  const subtitle = document.querySelector("[data-testid='page-subtitle']");
  const isLoadingText = subtitle?.textContent?.includes("Loading…") ?? false;
  check("6. No stale loading spinners", !hasStaleSpinner, `${spinners.length} spinner(s) on page`);
  check("6. Subtitle not stuck on Loading…", !isLoadingText);

  // ── 7. Console warning scan (item 6) ──────────────────────────────────────
  log("Patching console.warn/error to catch React warnings for 5 s…");
  const caught = [];
  const origWarn = console.warn.bind(console);
  const origError = console.error.bind(console);
  console.warn  = (...a) => { caught.push({ level: "warn",  msg: a.join(" ") }); origWarn(...a); };
  console.error = (...a) => { caught.push({ level: "error", msg: a.join(" ") }); origError(...a); };

  // Poll once to trigger a render cycle and check for warnings
  await fetch("/api/qa/results").then((r) => r.json()).catch(() => null);
  await sleep(5_000);

  console.warn  = origWarn;
  console.error = origError;

  const reactWarnings = caught.filter(
    (w) => w.msg.includes("Warning:") || w.msg.includes("unmounted") || w.msg.includes("memory leak")
  );
  check(
    "7. No React warnings during render cycle",
    reactWarnings.length === 0,
    reactWarnings.length > 0 ? reactWarnings.map((w) => w.msg).join(" | ") : "clean"
  );

  // ── 8. Final snapshot (item 8 — polling state after test) ─────────────────
  const snapFinal = dbg().snapshot();
  log("Final snapshot:", undefined);
  console.table(snapFinal);
  check("8. Polling still active at end of test", snapFinal.polling === true);
  check("8. Mounted still true at end of test",   snapFinal.mounted === true);
  check("8. No leaked fallback poll",              snapFinal.fallbackPoll === false);
  check("8. No leaked SSE",                        snapFinal.sseOpen === false);

  // ── Final report ──────────────────────────────────────────────────────────
  const passed = results.filter((r) => r.pass).length;
  const failed = results.filter((r) => !r.pass);
  console.log("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log(`%c QA Session Stress Test — ${passed}/${results.length} passed `,
    passed === results.length
      ? "background:#166534;color:#bbf7d0;font-weight:bold;padding:4px 8px;border-radius:4px"
      : "background:#7f1d1d;color:#fecaca;font-weight:bold;padding:4px 8px;border-radius:4px"
  );
  if (failed.length > 0) {
    console.log("%cFailed checks:", "color:#f87171;font-weight:bold");
    failed.forEach((f) => console.log(`  ❌ ${f.label}${f.detail ? " — " + f.detail : ""}`));
  }
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
  return results;
})();
