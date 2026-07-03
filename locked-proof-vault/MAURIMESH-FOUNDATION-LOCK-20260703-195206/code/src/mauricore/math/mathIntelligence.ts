export const SQRT2 = Math.SQRT2;
export const SQRT2_INVERSE = 1 / Math.SQRT2;
export const GOLDEN_RATIO = 1.618033988749895;

export function clamp01(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.max(0, Math.min(1, value));
}

export function sqrt2Growth(value: number): number {
  return value * SQRT2;
}

export function sqrt2Stabilise(value: number): number {
  return value * SQRT2_INVERSE;
}

export function fibonacci(n: number): number {
  if (n <= 0) return 0;
  if (n <= 2) return 1;
  let a = 1;
  let b = 1;
  for (let i = 3; i <= n; i++) {
    const next = a + b;
    a = b;
    b = next;
  }
  return b;
}

export function fibonacciBackoff(attempt: number, baseMs = 250): number {
  return fibonacci(Math.max(1, attempt)) * baseMs;
}

export function goldenGrowth(current: number, max = 1): number {
  const remaining = max - current;
  return clamp01(current + remaining / GOLDEN_RATIO);
}

export function entropy(values: number[]): number {
  const total = values.reduce((sum, v) => sum + Math.max(0, v), 0);
  if (total <= 0) return 0;

  let e = 0;
  for (const value of values) {
    const p = Math.max(0, value) / total;
    if (p > 0) e -= p * Math.log2(p);
  }

  const maxEntropy = Math.log2(values.length || 1);
  return maxEntropy === 0 ? 0 : clamp01(e / maxEntropy);
}

export function bayesianUpdate(prior: number, evidenceStrength: number, evidencePositive: boolean): number {
  const p = clamp01(prior);
  const e = clamp01(evidenceStrength);

  if (evidencePositive) {
    return clamp01(p + (1 - p) * e / SQRT2);
  }

  return clamp01(p * (1 - e / SQRT2));
}

export function fuzzyAnd(values: number[]): number {
  return clamp01(Math.min(...values));
}

export function fuzzyOr(values: number[]): number {
  return clamp01(Math.max(...values));
}

export function weightedAverage(items: Array<{ value: number; weight: number }>): number {
  const totalWeight = items.reduce((sum, item) => sum + Math.max(0, item.weight), 0);
  if (totalWeight <= 0) return 0;

  const total = items.reduce((sum, item) => {
    return sum + clamp01(item.value) * Math.max(0, item.weight);
  }, 0);

  return clamp01(total / totalWeight);
}
