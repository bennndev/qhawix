import webpush from "npm:web-push@3.6.7";
import type { SupabaseClient } from "npm:@supabase/supabase-js@2.45.4";
import { optionalEnv } from "./env.ts";
import { isAllowedPushEndpoint } from "./domain/index.ts";

export interface PushPayload {
  title: string;
  body: string;
  tier: "amber" | "red";
  callId: string;
}

/** Envia Web Push a los dispositivos del usuario. Nunca lanza: un push caido no debe romper la llamada. */
export async function sendPush(db: SupabaseClient, userId: string, payload: PushPayload): Promise<number> {
  const pub = optionalEnv("NEXT_PUBLIC_VAPID_PUBLIC_KEY");
  const priv = optionalEnv("VAPID_PRIVATE_KEY");
  if (!pub || !priv) return 0;
  webpush.setVapidDetails(optionalEnv("VAPID_SUBJECT") ?? "mailto:equipo@example.com", pub, priv);
  const { data: devices } = await db.from("devices").select("id, endpoint, p256dh, auth").eq("user_id", userId);
  let sent = 0;
  for (const d of devices ?? []) {
    // Anti-SSRF: el endpoint lo controla el navegador del usuario
    if (!isAllowedPushEndpoint(d.endpoint)) {
      await db.from("devices").delete().eq("id", d.id);
      continue;
    }
    try {
      await webpush.sendNotification(
        { endpoint: d.endpoint, keys: { p256dh: d.p256dh, auth: d.auth } },
        JSON.stringify(payload),
        { urgency: "high", TTL: 60 },
      );
      sent++;
    } catch (err) {
      const code = (err as { statusCode?: number }).statusCode;
      if (code === 404 || code === 410) await db.from("devices").delete().eq("id", d.id);
    }
  }
  return sent;
}
