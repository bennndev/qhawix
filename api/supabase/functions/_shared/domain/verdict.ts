import type { Label, LlmResult, RuleResult, Signal, Tier, Verdict } from "./types.ts";
import { maxLabel, maxTier, scoreFromRules, THRESHOLDS, tierFromScore } from "./risk.ts";

export interface CombineInput {
  rules: RuleResult;
  llm?: LlmResult | null;
  /** true si se intento llamar al LLM (si no hay llm y se intento, queda degradado) */
  llmAttempted?: boolean;
  prev?: Verdict | null;
  now?: number;
}

/** Un LLM que dice scam con baja confianza solo cuenta como sospechoso. [P] */
const LLM_SCAM_CONFIDENCE = 0.8;

function effectiveLlmLabel(llm: LlmResult | null | undefined): Label {
  if (!llm) return "benign";
  if (llm.label === "scam" && llm.confidence < LLM_SCAM_CONFIDENCE) return "suspicious";
  return llm.label;
}

function llmScore(label: Label): number {
  if (label === "scam") return THRESHOLDS.red;
  if (label === "suspicious") return THRESHOLDS.amber + 5;
  return 0;
}

function adviceFor(tier: Tier, signals: Signal[]): string {
  const top = [...signals].sort((a, b) => b.weight - a.weight)[0];
  if (tier === "red") {
    return top ? top.advice : "Corta la llamada. No des datos ni dinero y avisa a un familiar.";
  }
  if (tier === "amber") {
    return top ? top.advice : "Desconfia. No des codigos ni dinero y verifica por otro canal.";
  }
  return "Sin senales fuertes por ahora. Si te piden dinero, codigos o instalar algo, corta.";
}

function mergeSignals(prev: Signal[], next: Signal[]): Signal[] {
  const byId = new Map<string, Signal>();
  for (const s of [...prev, ...next]) byId.set(s.id, s);
  return [...byId.values()];
}

/**
 * Regla central: el LLM solo puede SUBIR. Dentro de una llamada el nivel solo sube.
 */
export function combine(input: CombineInput): Verdict {
  const now = input.now ?? Date.now();
  const llmLabel = effectiveLlmLabel(input.llm);
  const degraded: string[] = [];
  if (input.llmAttempted && !input.llm) degraded.push("llm");

  let label = maxLabel(input.rules.label, llmLabel);
  let score = Math.max(scoreFromRules(input.rules), llmScore(llmLabel));
  let signals = input.rules.signals;
  let confidence = Math.min(0.95, 0.5 + input.rules.sum * 0.1);
  if (input.llm) confidence = Math.max(confidence, input.llm.confidence);

  if (input.prev) {
    label = maxLabel(input.prev.label, label);
    score = Math.max(input.prev.score, score);
    signals = mergeSignals(input.prev.signals, signals);
    confidence = Math.max(input.prev.confidence, confidence);
  }
  const tier = input.prev ? maxTier(input.prev.tier, tierFromScore(score)) : tierFromScore(score);

  const reasons = [...signals]
    .sort((a, b) => b.weight - a.weight)
    .map((s) => s.reason);
  for (const r of input.llm?.reasons ?? []) if (!reasons.includes(r)) reasons.push(r);

  return {
    tier,
    score,
    label,
    confidence,
    signals,
    reasons: reasons.slice(0, 6),
    advice: adviceFor(tier, signals),
    degraded,
    engine: input.llm ? "rules+llm" : "rules",
    at: now,
  };
}
