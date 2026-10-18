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
  const key = Deno.env.get("TRUTHSCAN_API_KEY");
  if (!key) return json({ error: "provider_not_configured" }, 503);
  try {
    const input = await request.json();
    if (typeof input.pcm16Base64 !== "string" || input.pcm16Base64.length > 500_000 || input.sampleRate !== 16000) return json({ error: "invalid_audio_window" }, 400);
    const pcm = Uint8Array.from(atob(input.pcm16Base64), (char) => char.charCodeAt(0));
    // TruthScan's audio workflow requires a valid audio file (minimum 1 KB).
    if (pcm.length < 32_000 || pcm.length > 400_000) return json({ error: "invalid_audio_window" }, 400);
    if (!await consumeQuota(userId, "voice_check", 10)) return json({ error: "daily_limit_reached" }, 429);
    const wav = toWav(pcm);
    const filename = `echotrap-${crypto.randomUUID()}.wav`;
    const uploadTicketResponse = await fetch(`https://detect-audio.truthscan.com/get-presigned-url?file_name=${filename}`, {
      headers: { apikey: key, Accept: "application/json" }, signal: AbortSignal.timeout(8000),
    });
    if (!uploadTicketResponse.ok) return json({ error: "voice_check_unavailable" }, 502);
    const ticket = await uploadTicketResponse.json();
    const uploadUrl = new URL(ticket.presigned_url);
    if (uploadUrl.protocol !== "https:" || uploadUrl.hostname !== "audio-presigned-upload.ai-assets-cdn.com" || typeof ticket.file_path !== "string") {
      return json({ error: "invalid_provider_response" }, 502);
    }
    const upload = await fetch(uploadUrl, { method: "PUT", headers: { "Content-Type": "audio/wav", "x-amz-acl": "private" }, body: wav, signal: AbortSignal.timeout(15_000) });
    if (!upload.ok) return json({ error: "voice_check_unavailable" }, 502);
    const detectionResponse = await fetch("https://detect-audio.truthscan.com/detect", {
      method: "POST", headers: { "Content-Type": "application/json", Accept: "application/json" },
      body: JSON.stringify({ key, url: ticket.file_path, document_type: "Audio", analyzeUpToSeconds: 10 }),
      signal: AbortSignal.timeout(10_000),
    });
    if (!detectionResponse.ok) return json({ error: "voice_check_unavailable" }, 502);
    const detection = await detectionResponse.json();
    if (typeof detection.id !== "string") return json({ error: "invalid_provider_response" }, 502);
    for (let attempt = 0; attempt < 7; attempt++) {
      await new Promise((resolve) => setTimeout(resolve, 1200));
      const status = await fetch("https://detect-audio.truthscan.com/query", {
        method: "POST", headers: { "Content-Type": "application/json", Accept: "application/json" },
        body: JSON.stringify({ id: detection.id }), signal: AbortSignal.timeout(6000),
      });
      if (!status.ok) continue;
      const result = await status.json();
      if (result.status === "failed") return json({ error: "voice_check_unavailable" }, 502);
      if (result.status === "done") {
        const score = Number(result.result_details?.mean_ai_prob ?? result.result);
        if (!Number.isFinite(score) || score < 0 || score > 1) return json({ error: "invalid_provider_response" }, 502);
        return json({ score, provider: "truthscan", analyzedSeconds: Math.min(10, Number(result.result_details?.truncated_duration ?? 10)), stored: false });
      }
    }
    return json({ pending: true, provider: "truthscan" }, 202);
  } catch (_error) {
    return json({ error: "voice_check_unavailable" }, 502);
  }
});

function toWav(pcm: Uint8Array): ArrayBuffer {
  const data = new Uint8Array(44 + pcm.length); const view = new DataView(data.buffer);
  const text = (offset: number, value: string) => { for (let i = 0; i < value.length; i++) data[offset + i] = value.charCodeAt(i); };
  text(0, "RIFF"); view.setUint32(4, 36 + pcm.length, true); text(8, "WAVE"); text(12, "fmt ");
  view.setUint32(16, 16, true); view.setUint16(20, 1, true); view.setUint16(22, 1, true);
  view.setUint32(24, 16000, true); view.setUint32(28, 32000, true); view.setUint16(32, 2, true); view.setUint16(34, 16, true);
  text(36, "data"); view.setUint32(40, pcm.length, true); data.set(pcm, 44); return data.buffer as ArrayBuffer;
}
async function signedIn(request: Request): Promise<string | null> {
  const token = request.headers.get("Authorization"); const url = Deno.env.get("SUPABASE_URL"); const anon = Deno.env.get("SUPABASE_ANON_KEY");
  if (!token || !url || !anon) return null;
  const response = await fetch(`${url}/auth/v1/user`, { headers: { Authorization: token, apikey: anon }, signal: AbortSignal.timeout(5000) });
  if (!response.ok) return null;
  const user = await response.json(); return typeof user.id === "string" ? user.id : null;
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
