const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const userId = await signedIn(request);
  if (!userId) return json({ error: "unauthorized" }, 401);
  const key = Deno.env.get("DEEPGRAM_API_KEY");
  if (!key) return json({ error: "provider_not_configured" }, 503);
  try {
    const input = await request.json();
    if (typeof input.pcm16Base64 !== "string" || input.pcm16Base64.length > 400_000) return json({ error: "invalid_audio_window" }, 400);
    const pcm = Uint8Array.from(atob(input.pcm16Base64), (char) => char.charCodeAt(0));
    if (pcm.length < 8_000 || pcm.length > 320_000) return json({ error: "invalid_audio_window" }, 400);
    if (!await consumeQuota(userId, "transcribe", 120)) return json({ error: "daily_limit_reached" }, 429);
    const wav = toWav(pcm, 16000, 1, 16);
    const response = await fetch("https://api.deepgram.com/v1/listen?model=nova-3&language=es&smart_format=true&utterances=false", {
      method: "POST",
      headers: { Authorization: `Token ${key}`, "Content-Type": "audio/wav" },
      body: wav,
      signal: AbortSignal.timeout(15_000),
    });
    if (!response.ok) return json({ error: "transcription_unavailable" }, 502);
    const result = await response.json();
    const transcript = result?.results?.channels?.[0]?.alternatives?.[0]?.transcript;
    if (typeof transcript !== "string") return json({ error: "invalid_provider_response" }, 502);
    return json({ transcript: transcript.slice(0, 3000), provider: "deepgram", stored: false });
  } catch (_error) {
    return json({ error: "transcription_unavailable" }, 502);
  }
});

function toWav(pcm: Uint8Array, sampleRate: number, channels: number, bits: number): ArrayBuffer {
  const bytesPerSample = bits / 8;
  const data = new Uint8Array(44 + pcm.length);
  const view = new DataView(data.buffer);
  const text = (offset: number, value: string) => { for (let i = 0; i < value.length; i++) data[offset + i] = value.charCodeAt(i); };
  text(0, "RIFF"); view.setUint32(4, 36 + pcm.length, true); text(8, "WAVE"); text(12, "fmt ");
  view.setUint32(16, 16, true); view.setUint16(20, 1, true); view.setUint16(22, channels, true);
  view.setUint32(24, sampleRate, true); view.setUint32(28, sampleRate * channels * bytesPerSample, true);
  view.setUint16(32, channels * bytesPerSample, true); view.setUint16(34, bits, true); text(36, "data");
  view.setUint32(40, pcm.length, true); data.set(pcm, 44); return data.buffer as ArrayBuffer;
}

async function signedIn(request: Request): Promise<string | null> {
  const token = request.headers.get("Authorization");
  const url = Deno.env.get("SUPABASE_URL"); const anon = Deno.env.get("SUPABASE_ANON_KEY");
  if (!token || !url || !anon) return null;
  const response = await fetch(`${url}/auth/v1/user`, { headers: { Authorization: token, apikey: anon }, signal: AbortSignal.timeout(5000) });
  if (!response.ok) return null;
  const user = await response.json();
  return typeof user.id === "string" ? user.id : null;
}
async function consumeQuota(userId: string, operation: string, dailyLimit: number): Promise<boolean> {
  const url = Deno.env.get("SUPABASE_URL"); const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceKey) throw new Error("quota_service_unavailable");
  const response = await fetch(`${url}/rest/v1/rpc/echotrap_consume_quota`, {
    method: "POST", headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({ p_user_id: userId, p_operation: operation, p_daily_limit: dailyLimit }), signal: AbortSignal.timeout(5000),
  });
  return response.ok && await response.json() === true;
}
function json(body: unknown, status = 200) { return new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, "Content-Type": "application/json", "Cache-Control": "no-store" } }); }
