import type { SupabaseClient } from "npm:@supabase/supabase-js@2.45.4";
import {
  analyzeSegments,
  combine,
  labeledTranscript,
  maxTier,
  redactSensitive,
  shouldCallLlm,
  type Segment,
  type Speaker,
  type Tier,
  type Verdict,
} from "./domain/index.ts";
import { classifyWithGemini } from "./gemini.ts";
import { sendPush } from "./push.ts";

export interface CallRow {
  id: string;
  user_id: string;
}

export interface IncomingSegment {
  speaker: Speaker;
  text: string;
  seq?: number;
}

const lastLlmAt = new Map<string, number>();
const RANK: Record<Tier, number> = { green: 0, amber: 1, red: 2 };

function rowToVerdict(r: Record<string, unknown>): Verdict {
  return {
    tier: r.tier as Tier,
    score: r.score as number,
    label: r.label as Verdict["label"],
    confidence: r.confidence as number,
    signals: (r.signals as Verdict["signals"]) ?? [],
    reasons: (r.reasons as string[]) ?? [],
    advice: (r.advice as string) ?? "",
    degraded: (r.degraded as string[]) ?? [],
    engine: r.engine as Verdict["engine"],
    at: new Date(r.at as string).getTime(),
  };
}

/** Guarda el segmento, recalcula el veredicto de la llamada y avisa si subio de nivel. */
export async function ingestSegment(db: SupabaseClient, call: CallRow, seg: IncomingSegment): Promise<Verdict | null> {
  // Privacidad: codigos, PIN y numeros largos se ocultan ANTES de guardar o enviar al LLM
  const text = redactSensitive(seg.text.trim().slice(0, 1000));
  if (!text) return null;

  const { data: prof } = await db.from("profiles").select("consent_transcript").eq("id", call.user_id).single();
  const keepMs = prof?.consent_transcript ? 24 * 3600_000 : 15 * 60_000;
  await db.from("transcript_segments").insert({
    call_id: call.id,
    speaker: seg.speaker,
    text,
    final: true,
    seq: seg.seq ?? null,
    expires_at: new Date(Date.now() + keepMs).toISOString(),
  });

  const since = new Date(Date.now() - 180_000).toISOString();
  const { data: rows } = await db
    .from("transcript_segments")
    .select("speaker, text, final, seq, at")
    .eq("call_id", call.id)
    .gte("at", since)
    .order("at", { ascending: true });
  const segments: Segment[] = (rows ?? []).map((r) => ({
    speaker: r.speaker as Speaker,
    text: r.text as string,
    final: r.final as boolean,
    seq: (r.seq as number | null) ?? undefined,
    at: new Date(r.at as string).getTime(),
  }));

  const { data: prevRow } = await db
    .from("verdicts")
    .select("*")
    .eq("call_id", call.id)
    .order("at", { ascending: false })
    .limit(1)
    .maybeSingle();
  const prev = prevRow ? rowToVerdict(prevRow) : null;
  return await judge(db, call, segments, prev);
}

/**
 * Analiza la pista de voz de una llamada Qhawix sin guardar la transcripción ni
 * una fila de veredicto. El cliente aporta solo el contexto reciente en memoria;
 * Supabase conserva las alertas elevadas, que son necesarias para notificar.
 */
export async function analyzeLiveSegment(
  db: SupabaseClient,
  call: CallRow,
  seg: IncomingSegment,
  recentTranscript: string,
): Promise<Verdict | null> {
  const current = redactSensitive(seg.text.trim().slice(0, 1000));
  if (!current) return null;
  const history = redactSensitive(recentTranscript.slice(-6000));
  const transcript = [history, current].filter(Boolean).join("\n").slice(-7000);
  const now = Date.now();
  const segments: Segment[] = [{
    speaker: seg.speaker,
    text: transcript,
    final: true,
    seq: seg.seq,
    at: now,
  }];
  const rules = analyzeSegments(segments, { now });

  // Las alertas son la única memoria persistente del nivel de riesgo durante
  // una llamada; no se escriben texto ni filas de veredicto para esta fuente.
  const { data: previousAlert } = await db
    .from("alerts")
    .select("tier")
    .eq("call_id", call.id)
    .eq("user_id", call.user_id)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  const previousTier: Tier | null = previousAlert?.tier === "amber" || previousAlert?.tier === "red"
    ? previousAlert.tier
    : null;
  const prev: Verdict | null = previousTier
    ? {
      tier: previousTier,
      score: previousTier === "red" ? 60 : 30,
      label: previousTier === "red" ? "scam" : "suspicious",
      confidence: 0.5,
      signals: [],
      reasons: [],
      advice: "",
      degraded: [],
      engine: "rules",
      at: now - 1,
    }
    : null;
  const gate = shouldCallLlm({
    rules,
    prev,
    now,
    lastLlmAt: lastLlmAt.get(call.id),
    minGapMs: 8_000,
    textChanged: true,
  });
  let llm = null;
  if (gate) {
    lastLlmAt.set(call.id, now);
    llm = await classifyWithGemini(labeledTranscript(segments, { now }));
  }
  const verdict = combine({ rules, llm, llmAttempted: gate, prev, now });

  const previousRank: Tier = previousTier ?? "green";
  if (verdict.tier !== "green" && RANK[verdict.tier] > RANK[previousRank]) {
    const title = verdict.tier === "red" ? "Posible estafa o extorsión" : "Llamada sospechosa";
    try {
      await db.from("alerts").insert({
        call_id: call.id,
        user_id: call.user_id,
        tier: verdict.tier,
        title,
        body: verdict.advice,
      });
      await sendPush(db, call.user_id, { title, body: verdict.advice, tier: verdict.tier, callId: call.id });
    } catch {
      // El resultado de riesgo se devuelve aunque las notificaciones fallen.
    }
  }
  return verdict;
}

async function judge(db: SupabaseClient, call: CallRow, segments: Segment[], prev: Verdict | null): Promise<Verdict> {
  const now = Date.now();
  const rules = analyzeSegments(segments, { now });
  const gate = shouldCallLlm({ rules, prev, now, lastLlmAt: lastLlmAt.get(call.id), textChanged: true });
  let llm = null;
  if (gate) {
    lastLlmAt.set(call.id, now);
    llm = await classifyWithGemini(labeledTranscript(segments, { now }));
  }
  const verdict = combine({ rules, llm, llmAttempted: gate, prev, now });

  const changed =
    !prev || prev.tier !== verdict.tier || prev.score !== verdict.score || prev.signals.length !== verdict.signals.length;
  if (changed) {
    await db.from("verdicts").insert({
      call_id: call.id,
      tier: verdict.tier,
      score: verdict.score,
      label: verdict.label,
      confidence: verdict.confidence,
      signals: verdict.signals,
      reasons: verdict.reasons,
      advice: verdict.advice,
      degraded: verdict.degraded,
      engine: verdict.engine,
    });
  }

  const prevTier: Tier = prev?.tier ?? "green";
  if (verdict.tier !== "green" && RANK[verdict.tier] > RANK[prevTier] && maxTier(prevTier, verdict.tier) === verdict.tier) {
    const title = verdict.tier === "red" ? "Posible estafa o extorsion" : "Llamada sospechosa";
    const body = verdict.advice;
    await db.from("alerts").insert({ call_id: call.id, user_id: call.user_id, tier: verdict.tier, title, body });
    await sendPush(db, call.user_id, { title, body, tier: verdict.tier, callId: call.id });
  }
  return verdict;
}
