import { describe, it, expect } from "vitest";

// ── BLE utility functions under test ─────────────────────────────────────────

const MAURI_SERVICE_UUID = "0000f00d-dead-beef-cafe-000000000001";

interface BleDevice {
  uuid: string;
  name: string;
  rssi: number;
  serviceUuids: string[];
  manufacturerData: Record<number, number[]>;
}

function parseLocalName(bytes: number[]): string {
  return bytes.map((b) => String.fromCharCode(b)).join("");
}

function parseManufacturerData(raw: number[]): Record<number, number[]> {
  if (raw.length < 2) return {};
  const companyId = (raw[1] << 8) | raw[0];
  return { [companyId]: raw.slice(2) };
}

function filterByRssi(devices: BleDevice[], threshold: number): BleDevice[] {
  return devices.filter((d) => d.rssi >= threshold);
}

function matchesMauriService(device: BleDevice): boolean {
  return device.serviceUuids.some(
    (u) => u.toLowerCase() === MAURI_SERVICE_UUID.toLowerCase(),
  );
}

function deduplicateDevices(devices: BleDevice[]): BleDevice[] {
  const seen = new Map<string, BleDevice>();
  for (const d of devices) {
    const existing = seen.get(d.uuid);
    if (!existing || d.rssi > existing.rssi) seen.set(d.uuid, d);
  }
  return [...seen.values()];
}

function buildScanFilter(serviceUuid: string, rssiThreshold: number) {
  return {
    serviceUuids: [serviceUuid],
    rssiThreshold,
    scanMode: rssiThreshold < -80 ? "low-latency" : "balanced",
  };
}

function rankDevicesBySignal(devices: BleDevice[]): BleDevice[] {
  return [...devices].sort((a, b) => b.rssi - a.rssi);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe("parseLocalName", () => {
  it("decodes ASCII bytes to string", () => {
    expect(parseLocalName([77, 97, 117, 114, 105])).toBe("Mauri");
  });
  it("returns empty string for empty array", () => {
    expect(parseLocalName([])).toBe("");
  });
  it("decodes single character", () => {
    expect(parseLocalName([65])).toBe("A");
  });
  it("preserves special characters in range", () => {
    expect(parseLocalName([45, 49])).toBe("-1");
  });
});

describe("parseManufacturerData", () => {
  it("extracts company ID in little-endian order", () => {
    const result = parseManufacturerData([0x4c, 0x00, 0xde, 0xad]);
    expect(result[0x004c]).toEqual([0xde, 0xad]);
  });
  it("returns empty object for single byte input", () => {
    expect(parseManufacturerData([0x01])).toEqual({});
  });
  it("returns empty object for empty input", () => {
    expect(parseManufacturerData([])).toEqual({});
  });
  it("handles multi-byte payload", () => {
    const raw = [0x30, 0x00, 1, 2, 3, 4, 5];
    const result = parseManufacturerData(raw);
    expect(result[0x0030]).toEqual([1, 2, 3, 4, 5]);
  });
});

describe("filterByRssi", () => {
  const devices: BleDevice[] = [
    { uuid: "a", name: "A", rssi: -50, serviceUuids: [], manufacturerData: {} },
    { uuid: "b", name: "B", rssi: -75, serviceUuids: [], manufacturerData: {} },
    { uuid: "c", name: "C", rssi: -90, serviceUuids: [], manufacturerData: {} },
    { uuid: "d", name: "D", rssi: -60, serviceUuids: [], manufacturerData: {} },
  ];
  it("keeps devices at or above threshold", () => {
    expect(filterByRssi(devices, -75)).toHaveLength(3);
  });
  it("rejects all below threshold", () => {
    expect(filterByRssi(devices, -40)).toEqual([]);
  });
  it("returns all when threshold is very low", () => {
    expect(filterByRssi(devices, -100)).toHaveLength(4);
  });
  it("returns empty array for empty input", () => {
    expect(filterByRssi([], -70)).toEqual([]);
  });
  it("handles exact boundary match inclusive", () => {
    expect(filterByRssi(devices, -90)).toHaveLength(4);
  });
});

describe("matchesMauriService", () => {
  it("matches device with correct service UUID", () => {
    const d: BleDevice = { uuid: "x", name: "X", rssi: -60, serviceUuids: [MAURI_SERVICE_UUID], manufacturerData: {} };
    expect(matchesMauriService(d)).toBe(true);
  });
  it("case-insensitive UUID match", () => {
    const d: BleDevice = { uuid: "x", name: "X", rssi: -60, serviceUuids: [MAURI_SERVICE_UUID.toUpperCase()], manufacturerData: {} };
    expect(matchesMauriService(d)).toBe(true);
  });
  it("rejects device without service UUID", () => {
    const d: BleDevice = { uuid: "x", name: "X", rssi: -60, serviceUuids: [], manufacturerData: {} };
    expect(matchesMauriService(d)).toBe(false);
  });
  it("rejects device with wrong service UUID", () => {
    const d: BleDevice = { uuid: "x", name: "X", rssi: -60, serviceUuids: ["0000dead-0000-0000-0000-000000000000"], manufacturerData: {} };
    expect(matchesMauriService(d)).toBe(false);
  });
});

describe("deduplicateDevices", () => {
  it("keeps device with stronger signal when duplicated", () => {
    const devices: BleDevice[] = [
      { uuid: "a", name: "A", rssi: -70, serviceUuids: [], manufacturerData: {} },
      { uuid: "a", name: "A", rssi: -55, serviceUuids: [], manufacturerData: {} },
    ];
    const result = deduplicateDevices(devices);
    expect(result).toHaveLength(1);
    expect(result[0].rssi).toBe(-55);
  });
  it("keeps all devices when no duplicates", () => {
    const devices: BleDevice[] = [
      { uuid: "a", name: "A", rssi: -60, serviceUuids: [], manufacturerData: {} },
      { uuid: "b", name: "B", rssi: -70, serviceUuids: [], manufacturerData: {} },
    ];
    expect(deduplicateDevices(devices)).toHaveLength(2);
  });
  it("returns empty array for empty input", () => {
    expect(deduplicateDevices([])).toHaveLength(0);
  });
  it("handles single device", () => {
    const devices: BleDevice[] = [{ uuid: "a", name: "A", rssi: -60, serviceUuids: [], manufacturerData: {} }];
    expect(deduplicateDevices(devices)).toHaveLength(1);
  });
  it("collapses three duplicates into the strongest", () => {
    const devices: BleDevice[] = [
      { uuid: "z", name: "Z", rssi: -80, serviceUuids: [], manufacturerData: {} },
      { uuid: "z", name: "Z", rssi: -60, serviceUuids: [], manufacturerData: {} },
      { uuid: "z", name: "Z", rssi: -70, serviceUuids: [], manufacturerData: {} },
    ];
    const result = deduplicateDevices(devices);
    expect(result).toHaveLength(1);
    expect(result[0].rssi).toBe(-60);
  });
});

describe("buildScanFilter", () => {
  it("includes the given service UUID", () => {
    const f = buildScanFilter(MAURI_SERVICE_UUID, -70);
    expect(f.serviceUuids).toContain(MAURI_SERVICE_UUID);
  });
  it("sets low-latency mode for weak signal threshold", () => {
    const f = buildScanFilter(MAURI_SERVICE_UUID, -90);
    expect(f.scanMode).toBe("low-latency");
  });
  it("sets balanced mode for normal signal threshold", () => {
    const f = buildScanFilter(MAURI_SERVICE_UUID, -65);
    expect(f.scanMode).toBe("balanced");
  });
  it("preserves rssiThreshold exactly", () => {
    const f = buildScanFilter(MAURI_SERVICE_UUID, -75);
    expect(f.rssiThreshold).toBe(-75);
  });
});

describe("rankDevicesBySignal", () => {
  it("sorts descending by rssi (strongest first)", () => {
    const devices: BleDevice[] = [
      { uuid: "a", name: "A", rssi: -80, serviceUuids: [], manufacturerData: {} },
      { uuid: "b", name: "B", rssi: -50, serviceUuids: [], manufacturerData: {} },
      { uuid: "c", name: "C", rssi: -65, serviceUuids: [], manufacturerData: {} },
    ];
    const ranked = rankDevicesBySignal(devices);
    expect(ranked[0].rssi).toBe(-50);
    expect(ranked[1].rssi).toBe(-65);
    expect(ranked[2].rssi).toBe(-80);
  });
  it("returns empty array for empty input", () => {
    expect(rankDevicesBySignal([])).toEqual([]);
  });
  it("does not mutate the original array", () => {
    const devices: BleDevice[] = [
      { uuid: "a", name: "A", rssi: -80, serviceUuids: [], manufacturerData: {} },
      { uuid: "b", name: "B", rssi: -50, serviceUuids: [], manufacturerData: {} },
    ];
    rankDevicesBySignal(devices);
    expect(devices[0].rssi).toBe(-80);
  });
  it("handles single element", () => {
    const devices: BleDevice[] = [{ uuid: "a", name: "A", rssi: -60, serviceUuids: [], manufacturerData: {} }];
    expect(rankDevicesBySignal(devices)).toHaveLength(1);
  });
});
