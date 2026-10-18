import type { RuleResult, Segment, Verdict } from "./types.ts";
import { applyRules } from "./rules.ts";
import { toRuleResult } from "./risk.ts";
import { speakerText, type WindowOptions } from "./window.ts";

/** Reglas sobre la ventana: texto del llamante y del usuario por separado. */
export function analyzeSegments(segments: Segment[], opts: WindowOptions = {}): RuleResult {
  const caller = speakerText(segments, "caller", opts);
  const user = speakerText(segments, "user", opts);
  return toRuleResult([...applyRules(caller, "caller"), ...applyRules(user, "user")]);
}

export interface LlmGate {
  rules: RuleResult;
  prev?: Verdict | null;
  now: number;
  lastLlmAt?: number;
  minGapMs?: number;
  textChanged: boolean;
}

/** Cuando conviene gastar una llamada al LLM. Las reglas ya en "scam" no la necesitan. */
export function shouldCallLlm(g: LlmGate): boolean {
  if (!g.textChanged) return false;
  if (g.rules.label === "scam") return false;
  const gap = g.minGapMs ?? 2500;
  if (g.lastLlmAt !== undefined && g.now - g.lastLlmAt < gap) return false;
  return true;
}
