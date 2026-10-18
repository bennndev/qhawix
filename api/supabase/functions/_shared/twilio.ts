import { env } from "./env.ts";

/** Twilio firma: base64(HMAC-SHA1(authToken, url + params ordenados concatenados)). */
export async function validTwilioSignature(
  url: string,
  params: Record<string, string>,
  signature: string | null,
): Promise<boolean> {
  if (!signature) return false;
  const data = Object.keys(params)
    .sort()
    .reduce((acc, k) => acc + k + params[k], url);
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(env("TWILIO_AUTH_TOKEN")),
    { name: "HMAC", hash: "SHA-1" },
    false,
    ["sign"],
  );
  const mac = new Uint8Array(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(data)));
  let bin = "";
  for (const b of mac) bin += String.fromCharCode(b);
  const expected = btoa(bin);
  if (expected.length !== signature.length) return false;
  let diff = 0;
  for (let i = 0; i < expected.length; i++) diff |= expected.charCodeAt(i) ^ signature.charCodeAt(i);
  return diff === 0;
}

export async function readForm(req: Request): Promise<Record<string, string>> {
  const text = await req.text();
  const out: Record<string, string> = {};
  for (const [k, v] of new URLSearchParams(text)) out[k] = v;
  return out;
}

/** URL publica con la que Twilio calculo la firma (el proxy de Supabase reescribe req.url). */
export function publicUrl(fnName: string): string {
  const base = env("PUBLIC_FUNCTIONS_BASE_URL").replace(/\/$/, "");
  return base + "/" + fnName;
}

export function xml(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

export function twiml(body: string): Response {
  return new Response('<?xml version="1.0" encoding="UTF-8"?><Response>' + body + "</Response>", {
    headers: { "Content-Type": "text/xml; charset=utf-8" },
  });
}
