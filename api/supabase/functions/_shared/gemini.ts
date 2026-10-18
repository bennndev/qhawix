import { buildClassifierPrompt, parseLlmResult, type LlmResult } from "./domain/index.ts";
import { optionalEnv } from "./env.ts";

const SCHEMA = {
  type: "OBJECT",
  properties: {
    label: { type: "STRING", enum: ["benign", "suspicious", "scam"] },
    confidence: { type: "NUMBER" },
    reasons: { type: "ARRAY", items: { type: "STRING" } },
  },
  required: ["label", "confidence", "reasons"],
};

/** Clasifica con Gemini. Devuelve null ante cualquier fallo: el sistema sigue con reglas (degradar, no fallar). */
export async function classifyWithGemini(transcript: string, timeoutMs = 4000): Promise<LlmResult | null> {
  const key = optionalEnv("GEMINI_API_KEY");
  if (!key) return null;
  const model = optionalEnv("GEMINI_MODEL") ?? "gemini-2.5-flash-lite";
  const prompt = buildClassifierPrompt(transcript);
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetch(
      "https://generativelanguage.googleapis.com/v1beta/models/" + model + ":generateContent",
      {
        method: "POST",
        signal: ctrl.signal,
        headers: { "Content-Type": "application/json", "x-goog-api-key": key },
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: prompt.system }] },
          contents: [{ role: "user", parts: [{ text: prompt.user }] }],
          generationConfig: {
            temperature: 0,
            maxOutputTokens: 300,
            responseMimeType: "application/json",
            responseSchema: SCHEMA,
          },
        }),
      },
    );
    if (!res.ok) return null;
    const data = await res.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    return parseLlmResult(text);
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}
