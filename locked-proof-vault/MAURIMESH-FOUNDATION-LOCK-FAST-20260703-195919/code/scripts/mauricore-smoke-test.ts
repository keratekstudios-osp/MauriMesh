import { runMauriCoreSmokeTest } from "../src/mauricore/testing/smoke";

const result = runMauriCoreSmokeTest();

console.log(JSON.stringify(result, null, 2));

if (!result.ok) {
  process.exit(1);
}
