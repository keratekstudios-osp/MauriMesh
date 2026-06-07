import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: true,
    environment: "node",
    include: ["tests/**/*.test.ts"],
    reporters: ["default", "json"],
    outputFile: {
      json: "./qa-results/vitest-results.json",
    },
  },
});
