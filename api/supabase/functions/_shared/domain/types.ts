export type Tier = "green" | "amber" | "red";
export type Label = "benign" | "suspicious" | "scam";
/** caller = quien llama (potencial estafador). user = quien recibe (protegido). */
export type Speaker = "caller" | "user";

export interface Segment {
  speaker: Speaker;
  text: string;
  /** epoch ms */
  at: number;
  final: boolean;
  seq?: number;
}

export interface Signal {
  id: string;
  weight: number;
  reason: string;
  advice: string;
  /** fragmento normalizado que activo la regla (truncado) */
  evidence: string;
}

export interface RuleResult {
  sum: number;
  label: Label;
  signals: Signal[];
}

export interface LlmResult {
  label: Label;
  /** 0..1 */
  confidence: number;
  reasons: string[];
}

export type Engine = "rules" | "rules+llm";

export interface Verdict {
  tier: Tier;
  /** 0..100. Parametros sin calibrar [P] */
  score: number;
  label: Label;
  confidence: number;
  signals: Signal[];
  reasons: string[];
  advice: string;
  /** proveedores que fallaron o no se usaron, p. ej. ["llm"] */
  degraded: string[];
  engine: Engine;
  at: number;
}
