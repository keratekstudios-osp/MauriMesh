export function nowMs(): number {
  return Date.now();
}

export function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

export function safeId(prefix: string): string {
  const rand = Math.random().toString(36).slice(2, 10);
  return `${prefix}-${Date.now()}-${rand}`;
}

export function routeKey(nodes: string[]): string {
  return nodes.join(">");
}

export function weightedScore(parts: Array<[number, number]>): number {
  const totalWeight = parts.reduce((sum, [, weight]) => sum + weight, 0);
  if (totalWeight <= 0) return 0;
  return parts.reduce((sum, [value, weight]) => sum + value * weight, 0) / totalWeight;
}
