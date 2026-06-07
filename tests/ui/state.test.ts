import { describe, it, expect } from "vitest";

// ── UI state logic under test (pure functions, no DOM) ────────────────────────

// Chat message formatting
interface RawMessage {
  id: string;
  text: string;
  senderId: string;
  timestamp: number;
  status: "sending" | "sent" | "delivered" | "failed";
}

interface DisplayMessage extends RawMessage {
  timeLabel: string;
  isMine: boolean;
  showAvatar: boolean;
}

function formatTimeLabel(ts: number): string {
  const d = new Date(ts);
  const h = d.getUTCHours().toString().padStart(2, "0");
  const m = d.getUTCMinutes().toString().padStart(2, "0");
  return `${h}:${m}`;
}

function buildDisplayMessages(
  msgs: RawMessage[],
  myId: string,
): DisplayMessage[] {
  return msgs.map((msg, i) => {
    const prev = msgs[i - 1];
    const showAvatar = !prev || prev.senderId !== msg.senderId;
    return {
      ...msg,
      timeLabel: formatTimeLabel(msg.timestamp),
      isMine: msg.senderId === myId,
      showAvatar,
    };
  });
}

// Pagination logic
function paginate<T>(items: T[], page: number, pageSize: number): T[] {
  const start = page * pageSize;
  return items.slice(start, start + pageSize);
}

function totalPages(total: number, pageSize: number): number {
  if (pageSize <= 0) return 0;
  return Math.ceil(total / pageSize);
}

function clampPage(page: number, maxPage: number): number {
  return Math.max(0, Math.min(page, maxPage));
}

// Connection banner logic
type ConnectionState = "online" | "offline" | "reconnecting";

function getBannerVariant(state: ConnectionState): "success" | "warning" | "error" | null {
  switch (state) {
    case "online": return null;
    case "reconnecting": return "warning";
    case "offline": return "error";
  }
}

function getBannerMessage(state: ConnectionState, peers: number): string {
  if (state === "online") return `Connected · ${peers} peer${peers !== 1 ? "s" : ""}`;
  if (state === "reconnecting") return "Reconnecting to mesh…";
  return "Offline — messages queued locally";
}

// Search filtering
function filterMessages(msgs: RawMessage[], query: string): RawMessage[] {
  const q = query.toLowerCase().trim();
  if (!q) return msgs;
  return msgs.filter((m) => m.text.toLowerCase().includes(q));
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

const T = 1_700_000_000_000;

const RAW: RawMessage[] = [
  { id: "1", text: "Hello mesh",   senderId: "alice", timestamp: T,        status: "delivered" },
  { id: "2", text: "Hey Alice",    senderId: "bob",   timestamp: T + 1000, status: "delivered" },
  { id: "3", text: "BLE active?",  senderId: "alice", timestamp: T + 2000, status: "delivered" },
  { id: "4", text: "Yes, RSSI -72",senderId: "alice", timestamp: T + 3000, status: "delivered" },
];

// ── Tests ─────────────────────────────────────────────────────────────────────

describe("formatTimeLabel", () => {
  it("formats midnight as 00:00", () => {
    expect(formatTimeLabel(0)).toBe("00:00");
  });
  it("formats noon as 12:00", () => {
    expect(formatTimeLabel(12 * 3600 * 1000)).toBe("12:00");
  });
  it("pads single-digit hours and minutes", () => {
    const ts = (9 * 3600 + 5 * 60) * 1000;
    expect(formatTimeLabel(ts)).toBe("09:05");
  });
  it("formats 23:59 correctly", () => {
    const ts = (23 * 3600 + 59 * 60) * 1000;
    expect(formatTimeLabel(ts)).toBe("23:59");
  });
});

describe("buildDisplayMessages", () => {
  it("marks messages from myId as isMine=true", () => {
    const display = buildDisplayMessages(RAW, "alice");
    expect(display[0].isMine).toBe(true);
    expect(display[1].isMine).toBe(false);
  });
  it("first message always shows avatar", () => {
    const display = buildDisplayMessages(RAW, "alice");
    expect(display[0].showAvatar).toBe(true);
  });
  it("consecutive messages from same sender hide avatar", () => {
    const display = buildDisplayMessages(RAW, "alice");
    expect(display[3].showAvatar).toBe(false);
  });
  it("sender switch triggers avatar display", () => {
    const display = buildDisplayMessages(RAW, "alice");
    expect(display[1].showAvatar).toBe(true);
  });
  it("timeLabel is formatted correctly", () => {
    const msgs: RawMessage[] = [
      { id: "x", text: "hi", senderId: "a", timestamp: (14 * 3600 + 30 * 60) * 1000, status: "sent" },
    ];
    const display = buildDisplayMessages(msgs, "a");
    expect(display[0].timeLabel).toBe("14:30");
  });
  it("preserves all original fields", () => {
    const display = buildDisplayMessages(RAW, "alice");
    expect(display[0].id).toBe("1");
    expect(display[0].text).toBe("Hello mesh");
  });
  it("empty array returns empty", () => {
    expect(buildDisplayMessages([], "alice")).toHaveLength(0);
  });
  it("length matches input", () => {
    const display = buildDisplayMessages(RAW, "alice");
    expect(display).toHaveLength(RAW.length);
  });
});

describe("paginate", () => {
  const items = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  it("returns first page correctly", () => {
    expect(paginate(items, 0, 3)).toEqual([1, 2, 3]);
  });
  it("returns second page correctly", () => {
    expect(paginate(items, 1, 3)).toEqual([4, 5, 6]);
  });
  it("returns partial last page", () => {
    expect(paginate(items, 3, 3)).toEqual([10]);
  });
  it("returns empty array past last page", () => {
    expect(paginate(items, 99, 3)).toEqual([]);
  });
  it("page size equal to length returns all", () => {
    expect(paginate(items, 0, 10)).toEqual(items);
  });
});

describe("totalPages", () => {
  it("exact division", () => {
    expect(totalPages(9, 3)).toBe(3);
  });
  it("rounds up when not exact", () => {
    expect(totalPages(10, 3)).toBe(4);
  });
  it("returns 0 for 0 items", () => {
    expect(totalPages(0, 10)).toBe(0);
  });
  it("returns 0 for pageSize 0", () => {
    expect(totalPages(100, 0)).toBe(0);
  });
  it("single item is one page", () => {
    expect(totalPages(1, 10)).toBe(1);
  });
});

describe("clampPage", () => {
  it("clamps below 0 to 0", () => {
    expect(clampPage(-5, 10)).toBe(0);
  });
  it("clamps above maxPage to maxPage", () => {
    expect(clampPage(99, 5)).toBe(5);
  });
  it("returns value unchanged when in range", () => {
    expect(clampPage(3, 10)).toBe(3);
  });
  it("boundary: 0 is valid", () => {
    expect(clampPage(0, 5)).toBe(0);
  });
  it("boundary: maxPage is valid", () => {
    expect(clampPage(5, 5)).toBe(5);
  });
});

describe("getBannerVariant", () => {
  it("online returns null (no banner)", () => {
    expect(getBannerVariant("online")).toBeNull();
  });
  it("reconnecting returns warning", () => {
    expect(getBannerVariant("reconnecting")).toBe("warning");
  });
  it("offline returns error", () => {
    expect(getBannerVariant("offline")).toBe("error");
  });
});

describe("getBannerMessage", () => {
  it("online shows peer count", () => {
    expect(getBannerMessage("online", 5)).toBe("Connected · 5 peers");
  });
  it("online singular peer uses correct grammar", () => {
    expect(getBannerMessage("online", 1)).toBe("Connected · 1 peer");
  });
  it("reconnecting shows reconnecting message", () => {
    expect(getBannerMessage("reconnecting", 0)).toBe("Reconnecting to mesh…");
  });
  it("offline shows queue message", () => {
    expect(getBannerMessage("offline", 0)).toBe("Offline — messages queued locally");
  });
});

describe("filterMessages", () => {
  it("empty query returns all messages", () => {
    expect(filterMessages(RAW, "")).toHaveLength(RAW.length);
  });
  it("whitespace-only query returns all", () => {
    expect(filterMessages(RAW, "   ")).toHaveLength(RAW.length);
  });
  it("case-insensitive search", () => {
    expect(filterMessages(RAW, "BLE")).toHaveLength(1);
    expect(filterMessages(RAW, "ble")).toHaveLength(1);
  });
  it("partial match works", () => {
    expect(filterMessages(RAW, "mesh")).toHaveLength(1);
  });
  it("no match returns empty array", () => {
    expect(filterMessages(RAW, "xyzzy")).toHaveLength(0);
  });
  it("searches message text content case-insensitively", () => {
    // "Hey Alice" contains "alice" in the text — should return 1 match
    expect(filterMessages(RAW, "alice")).toHaveLength(1);
  });
});
