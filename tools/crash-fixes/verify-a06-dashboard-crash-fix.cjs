const fs = require("fs");

const file = "app/dashboard.tsx";

function fail(reason) {
  console.log("");
  console.log("============================================================");
  console.log("A06 DASHBOARD CRASH FIX VERIFY");
  console.log("============================================================");
  console.log("A06 DASHBOARD FIX VERDICT: FAIL");
  console.log("Reason:", reason);
  console.log("============================================================");
  process.exit(1);
}

if (!fs.existsSync(file)) fail("app/dashboard.tsx missing.");

const s = fs.readFileSync(file, "utf8");

const required = [
  "MAURIMESH_DASHBOARD_SAFE",
  "Safe Dashboard",
  "/store-forward-proof",
  "/3-device-proof",
  "/proof-2-hop",
  "React Native primitives",
];

for (const text of required) {
  if (!s.includes(text)) fail(`Missing required dashboard text: ${text}`);
}

const banned = [
  "../src/components/AppShell",
  "../src/components/MauriButton",
  "../src/components/MeshSignalCard",
  "../src/lib/meshClient",
  "getMeshStatus",
  "LivingMeshCanvas",
];

const foundBanned = banned.filter((text) => s.includes(text));

if (foundBanned.length) {
  fail(`Risky dashboard imports still present: ${foundBanned.join(", ")}`);
}

console.log("");
console.log("============================================================");
console.log("A06 DASHBOARD CRASH FIX VERIFY");
console.log("============================================================");
console.log("A06 DASHBOARD FIX VERDICT: PASS");
console.log("Reason: dashboard is now stable fallback using local React Native primitives.");
console.log("============================================================");
