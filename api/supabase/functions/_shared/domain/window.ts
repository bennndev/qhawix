import type { Segment, Speaker } from "./types.ts";
import { normalize, sanitize } from "./normalize.ts";

export interface WindowOptions {
  maxChars?: number;
  maxAgeMs?: number;
  now?: number;
}

/**
 * Ventana movil: solo segmentos finales, ordenados, recientes y recortados.
 * Los parciales (interim) se ignoran para no duplicar texto.
 */
export function recentSegments(segments: Segment[], opts: WindowOptions = {}): Segment[] {
  const { maxAgeMs = 180_000, now = Date.now() } = opts;
  return segments
    .filter((s) => s.final && s.text.trim().length > 0 && now - s.at <= maxAgeMs)
    .sort((a, b) => a.at - b.at || (a.seq ?? 0) - (b.seq ?? 0));
}

/** Texto normalizado de un hablante (para reglas). */
export function speakerText(segments: Segment[], speaker: Speaker, opts: WindowOptions = {}): string {
  const { maxChars = 3000 } = opts;
  const joined = recentSegments(segments, opts)
    .filter((s) => s.speaker === speaker)
    .map((s) => s.text)
    .join(" ");
  const norm = normalize(sanitize(joined, maxChars * 2));
  return norm.length > maxChars ? norm.slice(norm.length - maxChars) : norm;
}

/** Transcripcion etiquetada para el LLM (dato no confiable). */
export function labeledTranscript(segments: Segment[], opts: WindowOptions = {}): string {
  const { maxChars = 3000 } = opts;
  const lines = recentSegments(segments, opts).map((s) => {
    const who = s.speaker === "caller" ? "LLAMANTE" : "USUARIO";
    return who + ": " + sanitize(s.text.replace(/\s+/g, " "), 400);
  });
  const text = lines.join("\n");
  return text.length > maxChars ? text.slice(text.length - maxChars) : text;
}
