import { CORS, json, optionalEnv, userClient } from "../_shared/env.ts";

type Organization = { key: string; name: string; domains: string[] };

const ORGANIZATIONS: Organization[] = [
  { key: "bcp", name: "BCP", domains: ["viabcp.com", "bcp.com.pe"] },
  { key: "interbank", name: "Interbank", domains: ["interbank.pe"] },
  { key: "bbva", name: "BBVA Perú", domains: ["bbva.pe"] },
  { key: "scotiabank", name: "Scotiabank Perú", domains: ["scotiabank.com.pe"] },
  { key: "banbif", name: "BanBif", domains: ["banbif.com.pe"] },
  { key: "mibanco", name: "Mibanco", domains: ["mibanco.com.pe"] },
  { key: "banco de la nacion", name: "Banco de la Nación", domains: ["bn.com.pe"] },
  { key: "yape", name: "Yape", domains: ["yape.com.pe"] },
];

const PUBLIC_DOMAINS = [
  "sbs.gob.pe",
  "gob.pe",
  "indecopi.gob.pe",
  "pj.gob.pe",
  "mpfn.gob.pe",
  "osiptel.gob.pe",
  "datosabiertos.gob.pe",
];

function findOrganization(transcript: string): Organization | null {
  const normalized = transcript.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
  for (const organization of ORGANIZATIONS) {
    const escaped = organization.key.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    if (new RegExp(`\\b${escaped}\\b`, "i").test(normalized)) return organization;
  }
  return null;
}

function isApprovedSource(uri: string, organization: Organization | null): boolean {
  let hostname = "";
  try {
    hostname = new URL(uri).hostname.toLowerCase().replace(/^www\./, "");
  } catch {
    return false;
  }
  const allowed = [...PUBLIC_DOMAINS, ...(organization?.domains ?? [])];
  return allowed.some((domain) => hostname === domain || hostname.endsWith(`.${domain}`));
}

const lastLookupByUser = new Map<string, number>();

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const authorization = req.headers.get("Authorization");
  if (!authorization) return json({ error: "unauthorized" }, 401);
  const { data: authData, error: authError } = await userClient(authorization).auth.getUser();
  if (authError || !authData.user) return json({ error: "unauthorized" }, 401);

  const body = await req.json().catch(() => ({}));
  const callId = typeof body.qhawix_call_id === "string" ? body.qhawix_call_id : "";
  const transcript = typeof body.transcript === "string" ? body.transcript.slice(0, 1200) : "";
  if (!/^[0-9a-f-]{36}$/i.test(callId) || !transcript.trim()) {
    return json({ error: "invalid_request" }, 400);
  }

  // Solo la persona que recibe una llamada activa puede consultar información.
  // El teléfono y la transcripción completa no se envían al buscador ni se guardan.
  const client = userClient(authorization);
  const { data: call, error: callError } = await client
    .from("qhawix_calls")
    .select("id, status")
    .eq("id", callId)
    .eq("callee_id", authData.user.id)
    .eq("status", "active")
    .maybeSingle();
  if (callError || !call) return json({ error: "active_call_not_found" }, 403);

  const now = Date.now();
  const previous = lastLookupByUser.get(authData.user.id) ?? 0;
  if (now - previous < 15_000) return json({ error: "lookup_rate_limited" }, 429);
  lastLookupByUser.set(authData.user.id, now);

  const organization = findOrganization(transcript);
  const apiKey = optionalEnv("EXA_API_KEY");
  if (!apiKey) {
    return json({
      organization: organization?.name ?? null,
      summary: "La búsqueda de fuentes públicas no está configurada. Confirma siempre por el canal oficial de la entidad.",
      sources: [],
      degraded: ["web_search_not_configured"],
    });
  }

  const allowedDomains = [...PUBLIC_DOMAINS, ...(organization?.domains ?? [])];
  const entity = organization?.name ?? "entidad financiera mencionada";
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 8_000);
  try {
    const response = await fetch("https://api.exa.ai/search", {
      method: "POST",
      signal: controller.signal,
      headers: { "Content-Type": "application/json", "x-api-key": apiKey },
      body: JSON.stringify({
        query: `${entity} Perú alertas oficiales suplantación fraude telefónico canales de atención sanciones resoluciones`,
        type: "auto",
        numResults: 6,
        includeDomains: allowedDomains,
        contents: { highlights: true },
      }),
    });
    if (!response.ok) throw new Error("search_failed");

    const data = await response.json();
    const results = Array.isArray(data?.results) ? data.results : [];
    const seen = new Set<string>();
    const sources = results
      .filter((result: { title?: string; url?: string }) =>
        result?.title && result.url && isApprovedSource(result.url, organization),
      )
      .filter((result: { url?: string }) => {
        if (seen.has(result.url!)) return false;
        seen.add(result.url!);
        return true;
      })
      .slice(0, 4)
      .map((result: { title?: string; url?: string; highlights?: string[] }) => ({
        title: result.title,
        url: result.url,
        excerpt: Array.isArray(result.highlights) ? result.highlights[0] : undefined,
      }));

    return json({
      organization: organization?.name ?? null,
      summary: sources.length > 0
        ? `Se encontraron ${sources.length} resultados en dominios oficiales. Revisa la fecha y el contenido; un resultado sobre la entidad no identifica a quien llama.`
        : "No se encontró una fuente oficial verificable para esta afirmación. Esto no demuestra que la llamada sea legítima; contacta a la entidad desde su app o sitio oficial.",
      sources,
      searched_at: new Date().toISOString(),
      degraded: sources.length > 0 ? [] : ["no_official_source"],
    });
  } catch {
    return json({
      organization: organization?.name ?? null,
      summary: "La búsqueda no está disponible en este momento. No compartas claves ni códigos; verifica por la app o el canal oficial de la entidad.",
      sources: [],
      degraded: ["web_search_unavailable"],
    });
  } finally {
    clearTimeout(timer);
  }
});
