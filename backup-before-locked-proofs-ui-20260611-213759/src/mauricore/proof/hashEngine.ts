export function stableStringify(value: unknown): string {
  if (value === null || typeof value !== "object") return JSON.stringify(value);

  if (Array.isArray(value)) {
    return `[${value.map(stableStringify).join(",")}]`;
  }

  const obj = value as Record<string, unknown>;
  return `{${Object.keys(obj)
    .sort()
    .map((key) => `${JSON.stringify(key)}:${stableStringify(obj[key])}`)
    .join(",")}}`;
}

/**
 * Deterministic development hash.
 * For production security, replace with Rust/native SHA-256 or platform crypto.
 */
export function deterministicHash(value: unknown): string {
  const input = stableStringify(value);
  let hash = 2166136261;

  for (let i = 0; i < input.length; i++) {
    hash ^= input.charCodeAt(i);
    hash += (hash << 1) + (hash << 4) + (hash << 7) + (hash << 8) + (hash << 24);
  }

  return `fnv1a_${(hash >>> 0).toString(16).padStart(8, "0")}`;
}
