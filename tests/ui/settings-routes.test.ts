import { describe, it, expect } from "vitest";
import {
  SETTINGS_ROUTE_ENTRIES,
  SETTINGS_CANONICAL_PATHS,
  SETTINGS_BARE_PATHS,
} from "../../artifacts/maurimesh/src/pages/settings/routeConfig";

describe("UI Smoke — Settings hub canonical route paths", () => {
  it("all canonical settings paths use the /settings/ prefix", () => {
    for (const path of SETTINGS_CANONICAL_PATHS) {
      expect(
        path.startsWith("/settings/"),
        `${path} must use /settings/ prefix`,
      ).toBe(true);
    }
  });

  it("defines all 9 required settings sections", () => {
    expect(SETTINGS_CANONICAL_PATHS).toContain("/settings/appearance");
    expect(SETTINGS_CANONICAL_PATHS).toContain("/settings/language");
    expect(SETTINGS_CANONICAL_PATHS).toContain("/settings/notifications");
    expect(SETTINGS_CANONICAL_PATHS).toContain("/settings/permissions");
    expect(SETTINGS_CANONICAL_PATHS).toContain("/settings/offline");
    expect(SETTINGS_CANONICAL_PATHS).toContain("/settings/security");
    expect(SETTINGS_CANONICAL_PATHS).toContain("/settings/privacy");
    expect(SETTINGS_CANONICAL_PATHS).toContain("/settings/device-pairing");
    expect(SETTINGS_CANONICAL_PATHS).toContain("/settings/export-import");
    expect(SETTINGS_CANONICAL_PATHS).toHaveLength(9);
  });

  it("no canonical settings path has a trailing slash", () => {
    for (const path of SETTINGS_CANONICAL_PATHS) {
      expect(path.endsWith("/"), `${path} must not have trailing slash`).toBe(false);
    }
  });

  it("each settings entry has a non-empty label", () => {
    for (const entry of SETTINGS_ROUTE_ENTRIES) {
      expect(entry.label.length, `entry ${entry.canonicalPath} must have a label`).toBeGreaterThan(0);
    }
  });
});

describe("UI Smoke — Settings bare-path aliases", () => {
  it("bare paths exist for all 9 settings sections", () => {
    expect(SETTINGS_BARE_PATHS).toHaveLength(9);
  });

  it("bare /appearance alias maps to /settings/appearance", () => {
    const entry = SETTINGS_ROUTE_ENTRIES.find((e) => e.barePath === "/appearance");
    expect(entry).toBeDefined();
    expect(entry!.canonicalPath).toBe("/settings/appearance");
  });

  it("bare /offline-controls alias maps to /settings/offline", () => {
    const entry = SETTINGS_ROUTE_ENTRIES.find((e) => e.barePath === "/offline-controls");
    expect(entry).toBeDefined();
    expect(entry!.canonicalPath).toBe("/settings/offline");
  });

  it("bare /device-pairing alias maps to /settings/device-pairing", () => {
    const entry = SETTINGS_ROUTE_ENTRIES.find((e) => e.barePath === "/device-pairing");
    expect(entry).toBeDefined();
    expect(entry!.canonicalPath).toBe("/settings/device-pairing");
  });

  it("bare /security alias maps to /settings/security", () => {
    const entry = SETTINGS_ROUTE_ENTRIES.find((e) => e.barePath === "/security");
    expect(entry).toBeDefined();
    expect(entry!.canonicalPath).toBe("/settings/security");
  });

  it("bare /privacy alias maps to /settings/privacy", () => {
    const entry = SETTINGS_ROUTE_ENTRIES.find((e) => e.barePath === "/privacy");
    expect(entry).toBeDefined();
    expect(entry!.canonicalPath).toBe("/settings/privacy");
  });

  it("no bare path uses the /settings/ prefix (they are aliases, not canonical)", () => {
    for (const barePath of SETTINGS_BARE_PATHS) {
      expect(
        barePath.startsWith("/settings/"),
        `bare path ${barePath} should not use /settings/ prefix`,
      ).toBe(false);
    }
  });

  it("each entry has distinct canonical and bare paths", () => {
    for (const { canonicalPath, barePath } of SETTINGS_ROUTE_ENTRIES) {
      expect(canonicalPath).not.toBe(barePath);
    }
  });

  it("all canonical paths are unique", () => {
    const unique = new Set(SETTINGS_CANONICAL_PATHS);
    expect(unique.size).toBe(SETTINGS_CANONICAL_PATHS.length);
  });

  it("all bare paths are unique", () => {
    const unique = new Set(SETTINGS_BARE_PATHS);
    expect(unique.size).toBe(SETTINGS_BARE_PATHS.length);
  });
});
