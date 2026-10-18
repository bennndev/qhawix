import type { Label, RuleResult, Signal, Tier } from "./types.ts";

/** Umbrales [P]: sin calibrar con datos reales. */
export const THRESHOLDS = { amber: 30, red: 60 } as const;
/** Suma de pesos de reglas para etiquetar. [P] */
export const LABEL_SUM = { scam: 3, suspicious: 2 } as const;
const POINTS_PER_WEIGHT = 20;

const LABEL_ORDER: Label[] = ["benign", "suspicious", "scam"];
const TIER_ORDER: Tier[] = ["green", "amber", "red"];

export function maxLabel(a: Label, b: Label): Label {
  return LABEL_ORDER.indexOf(a) >= LABEL_ORDER.indexOf(b) ? a : b;
}

export function maxTier(a: Tier, b: Tier): Tier {
  return TIER_ORDER.indexOf(a) >= TIER_ORDER.indexOf(b) ? a : b;
}

export function tierFromScore(score: number): Tier {
  if (score >= THRESHOLDS.red) return "red";
  if (score >= THRESHOLDS.amber) return "amber";
  return "green";
}

export function labelFromSum(sum: number): Label {
  if (sum >= LABEL_SUM.scam) return "scam";
  if (sum >= LABEL_SUM.suspicious) return "suspicious";
  return "benign";
}

export function toRuleResult(signals: Signal[]): RuleResult {
  const sum = signals.reduce((acc, s) => acc + s.weight, 0);
  return { sum, label: labelFromSum(sum), signals };
}

/** Puntaje base desde reglas, con pisos por etiqueta. */
export function scoreFromRules(r: RuleResult): number {
  const raw = Math.min(100, r.sum * POINTS_PER_WEIGHT);
  if (r.label === "scam") return Math.max(raw, THRESHOLDS.red);
  if (r.label === "suspicious") return Math.max(raw, THRESHOLDS.amber);
  return Math.min(raw, THRESHOLDS.amber - 5);
}
