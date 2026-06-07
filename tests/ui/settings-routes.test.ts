import { describe, it, expect } from "vitest";
import { SCREEN_REGISTRY } from "../../lib/lib/screen-registry";

const SETTINGS_ENTRIES = SCREEN_REGISTRY.filter((s) =>
  s.route.startsWith("/settings/"),
);
const SETTINGS_PATHS = SETTINGS_ENTRIES.map((s) => s.route);

describe("UI Smoke — Settings hub canonical route paths", () => {
  it("all settings sub-screen paths use the /settings/ prefix", () => {
    for (const path of SETTINGS_PATHS) {
      expect(
        path.startsWith("/settings/"),
        `${path} must use /settings/ prefix`,
      ).toBe(true);
    }
  });

  it("defines the core settings sections", () => {
    expect(SETTINGS_PATHS).toContain("/settings/appearance");
    expect(SETTINGS_PATHS).toContain("/settings/language");
    expect(SETTINGS_PATHS).toContain("/settings/notifications");
    expect(SETTINGS_PATHS).toContain("/settings/permissions");
    expect(SETTINGS_PATHS).toContain("/settings/offline-controls");
    expect(SETTINGS_PATHS).toContain("/settings/security");
    expect(SETTINGS_PATHS).toContain("/settings/privacy");
    expect(SETTINGS_PATHS).toContain("/settings/device-pairing");
    expect(SETTINGS_PATHS).toContain("/settings/export-import");
  });

  it("no settings path has a trailing slash", () => {
    for (const path of SETTINGS_PATHS) {
      expect(path.endsWith("/"), `${path} must not have trailing slash`).toBe(false);
    }
  });

  it("each settings entry has a non-empty name", () => {
    for (const entry of SETTINGS_ENTRIES) {
      expect(
        entry.name.length,
        `entry ${entry.route} must have a name`,
      ).toBeGreaterThan(0);
    }
  });

  it("all settings paths are unique", () => {
    const unique = new Set(SETTINGS_PATHS);
    expect(unique.size).toBe(SETTINGS_PATHS.length);
  });

  it("the settings hub route itself is registered", () => {
    expect(SCREEN_REGISTRY.some((s) => s.route === "/settings")).toBe(true);
  });
});
