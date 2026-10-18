import { adminClient, CORS, json, optionalEnv, userClient } from "../_shared/env.ts";

const MAX_AUDIO_BYTES = 1_000_000;
const SAMPLE_SECONDS = 10;

function timeoutSignal(ms: number): AbortSignal {
  return AbortSignal.timeout(ms);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const authorization = req.headers.get("Authorization");
  if (!authorization) return json({ error: "unauthorized" }, 401);
  const { data: authData, error: authError } = await userClient(authorization).auth.getUser();
  if (authError || !authData.user) return json({ error: "unauthorized" }, 401);

  const body = await req.json().catch(() => ({}));
  const callId = typeof body.call_id === "string" ? body.call_id : "";
  const base64 = typeof body.audio === "string" ? body.audio : "";
  if (!/^[0-9a-f-]{36}$/i.test(callId) || !base64) return json({ error: "invalid_request" }, 400);
  const bytes = Uint8Array.from(atob(base64), (char) => char.charCodeAt(0));
  if (bytes.length < 1_000 || bytes.length > MAX_AUDIO_BYTES) return json({ error: "invalid_audio_size" }, 413);

  const client = userClient(authorization);
  const { data: call, error: callError } = await client
    .from("qhawix_calls")
    .select("id, status")
    .eq("id", callId)
    .eq("callee_id", authData.user.id)
    .eq("status", "active")
    .maybeSingle();
  if (callError || !call) return json({ error: "active_call_not_found" }, 403);

  // Marcar antes de llamar al proveedor evita reintentos que gasten créditos.
  const { data: reserved, error: reserveError } = await adminClient()
    .from("qhawix_calls")
    .update({ voice_origin_attempted_at: new Date().toISOString() })
    .eq("id", callId)
    .eq("callee_id", authData.user.id)
    .eq("status", "active")
    .is("voice_origin_attempted_at", null)
    .select("id")
    .maybeSingle();
  if (reserveError) return json({ error: "voice_origin_reservation_failed" }, 500);
  if (!reserved) return json({ error: "voice_origin_already_requested" }, 409);

  const apiKey = optionalEnv("TRUTHSCAN_API_KEY");
  if (!apiKey) {
    return json({ available: false, degraded: "voice_origin_not_configured" });
  }

  try {
    const presign = await fetch(
      "https://detect-audio.truthscan.com/get-presigned-url?file_name=qhawix-call-sample.wav",
      { headers: { apikey: apiKey }, signal: timeoutSignal(8_000) },
    );
    if (!presign.ok) throw new Error("presign_failed");
    const upload = await presign.json();
    if (upload?.status !== "success" || typeof upload.presigned_url !== "string" || typeof upload.file_path !== "string") {
      throw new Error("presign_invalid_response");
    }

    const uploadResponse = await fetch(upload.presigned_url, {
      method: "PUT",
      headers: { "Content-Type": "audio/wav", "x-amz-acl": "private" },
      body: bytes,
      signal: timeoutSignal(12_000),
    });
    if (!uploadResponse.ok) throw new Error("audio_upload_failed");

    const detectionResponse = await fetch("https://detect-audio.truthscan.com/detect", {
      method: "POST",
      headers: { "Content-Type": "application/json", accept: "application/json" },
      body: JSON.stringify({
        key: apiKey,
        url: upload.file_path,
        document_type: "Audio",
        analyzeUpToSeconds: SAMPLE_SECONDS,
      }),
      signal: timeoutSignal(12_000),
    });
    if (!detectionResponse.ok) throw new Error("detection_submit_failed");
    const detection = await detectionResponse.json();
    if (typeof detection?.id !== "string") throw new Error("detection_invalid_response");

    const deadline = Date.now() + 12_000;
    let result: Record<string, unknown> = { status: detection.status ?? "pending" };
    while (Date.now() < deadline) {
      await new Promise((resolve) => setTimeout(resolve, 1_000));
      const response = await fetch("https://detect-audio.truthscan.com/query", {
        method: "POST",
        headers: { "Content-Type": "application/json", accept: "application/json" },
        body: JSON.stringify({ id: detection.id }),
        signal: timeoutSignal(8_000),
      });
      if (!response.ok) throw new Error("detection_query_failed");
      result = await response.json();
      if (result.status === "done" || result.status === "failed") break;
    }

    const score = typeof result.result === "number" && Number.isFinite(result.result)
      ? Math.max(0, Math.min(1, result.result))
      : null;
    return json({
      available: true,
      status: result.status,
      provider: "TruthScan",
      score,
      analyzed_seconds: result.result_details && typeof result.result_details === "object"
        ? (result.result_details as Record<string, unknown>).truncated_duration ?? null
        : null,
      note: "El puntaje estima señales de audio sintético; no identifica a la persona ni prueba una estafa.",
    });
  } catch {
    return json({ available: false, degraded: "voice_origin_check_unavailable" }, 200);
  }
});
