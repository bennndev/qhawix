import { adminClient, CORS, json, optionalEnv, userClient } from "../_shared/env.ts";

type CallAction = "start" | "accept" | "reject" | "end" | "token" | "expire";

async function expireRingingCalls(
  db: ReturnType<typeof adminClient>,
  calleeId?: string,
): Promise<number> {
  const configuredSeconds = Number(optionalEnv("QHAWIX_CALL_RING_TIMEOUT_SECONDS"));
  const timeoutSeconds = Number.isInteger(configuredSeconds) && configuredSeconds >= 15 && configuredSeconds <= 120
    ? configuredSeconds
    : 45;
  const cutoff = new Date(Date.now() - timeoutSeconds * 1000).toISOString();
  let update = db.from("qhawix_calls")
    .update({ status: "missed", ended_at: new Date().toISOString() })
    .eq("status", "ringing")
    .lt("created_at", cutoff);
  if (calleeId) update = update.eq("callee_id", calleeId);
  const { data, error } = await update.select("analysis_call_id");
  if (error) throw new Error("stale_call_expiry_failed");
  const analysisIds = (data ?? []).map((row) => row.analysis_call_id);
  if (analysisIds.length > 0) {
    const { error: callError } = await db.from("calls")
      .update({ status: "ended", ended_at: new Date().toISOString() })
      .in("id", analysisIds);
    if (callError) throw new Error("stale_analysis_expiry_failed");
  }
  return analysisIds.length;
}

function base64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "");
}

async function makeRoomToken(apiKey: string, secret: string, identity: string, room: string): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(new TextEncoder().encode(JSON.stringify({ alg: "HS256", typ: "JWT" })));
  const claims = base64Url(new TextEncoder().encode(JSON.stringify({
    iss: apiKey,
    sub: identity,
    nbf: now,
    exp: now + 600,
    video: { roomJoin: true, room, canPublish: true, canSubscribe: true },
  })));
  const unsigned = `${header}.${claims}`;
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const signature = new Uint8Array(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(unsigned)));
  return `${unsigned}.${base64Url(signature)}`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const authorization = req.headers.get("Authorization");
  if (!authorization) return json({ error: "unauthorized" }, 401);
  const { data: authData, error: authError } = await userClient(authorization).auth.getUser();
  if (authError || !authData.user) return json({ error: "unauthorized" }, 401);
  const userId = authData.user.id;
  const body = await req.json().catch(() => ({}));
  const action = body.action as CallAction;
  const db = adminClient();

  if (action === "expire") {
    try {
      const expired = await expireRingingCalls(db, userId);
      return json({ expired });
    } catch {
      return json({ error: "call_expiry_failed" }, 500);
    }
  }

  if (action === "start") {
    const phone = typeof body.phone === "string" ? body.phone.trim() : "";
    if (!/^\+[1-9][0-9]{7,14}$/.test(phone)) return json({ error: "invalid_phone" }, 400);
    try {
      await expireRingingCalls(db);
    } catch {
      return json({ error: "call_expiry_failed" }, 500);
    }
    const { data, error } = await db.rpc("start_qhawix_call", { p_caller_id: userId, p_phone: phone });
    if (error) {
      if (error.message.includes("user_not_found")) return json({ error: "user_not_found" }, 404);
      if (error.message.includes("cannot_call_self")) return json({ error: "cannot_call_self" }, 400);
      if (error.message.includes("user_busy")) return json({ error: "already_in_call" }, 409);
      if (error.message.includes("invalid_phone")) return json({ error: "invalid_phone" }, 400);
      return json({ error: "invite_create_failed" }, 500);
    }
    return json(data);
  }

  const callId = typeof body.call_id === "string" ? body.call_id : "";
  if (!callId) return json({ error: "invalid_call_id" }, 400);
  const { data: call } = await db.from("qhawix_calls").select("*").eq("id", callId).maybeSingle();
  if (!call || (call.caller_id !== userId && call.callee_id !== userId)) return json({ error: "call_not_found" }, 404);

  if (action === "accept") {
    if (call.callee_id !== userId || call.status !== "ringing") return json({ error: "call_not_ringing" }, 409);
    const { data: updated, error } = await db.from("qhawix_calls")
      .update({ status: "active", answered_at: new Date().toISOString() })
      .eq("id", callId).eq("status", "ringing").select("id").maybeSingle();
    if (error) return json({ error: "call_update_failed" }, 500);
    if (!updated) return json({ error: "call_not_ringing" }, 409);
    return json({ call_id: callId, status: "active" });
  }
  if (action === "reject" || action === "end") {
    if (action === "reject" && call.callee_id !== userId) return json({ error: "not_callee" }, 403);
    const status = action === "reject" ? "rejected" : "ended";
    const { error } = await db.from("qhawix_calls").update({ status, ended_at: new Date().toISOString() }).eq("id", callId);
    await db.from("calls").update({ status: "ended", ended_at: new Date().toISOString() }).eq("id", call.analysis_call_id);
    if (error) return json({ error: "call_update_failed" }, 500);
    return json({ call_id: callId, status });
  }
  if (action === "token") {
    if (call.status !== "active") return json({ error: "call_not_active" }, 409);
    const apiKey = optionalEnv("LIVEKIT_API_KEY");
    const apiSecret = optionalEnv("LIVEKIT_API_SECRET");
    const url = optionalEnv("LIVEKIT_URL");
    if (!apiKey || !apiSecret || !url) return json({ error: "voice_service_not_configured" }, 503);
    const token = await makeRoomToken(apiKey, apiSecret, userId, call.room_name);
    return json({ url, token, call_id: callId, analysis_call_id: call.analysis_call_id });
  }
  return json({ error: "unknown_action" }, 400);
});
