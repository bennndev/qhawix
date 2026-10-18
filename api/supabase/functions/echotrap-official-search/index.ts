const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const officialDomains = [
  "bcp.com.pe", "viabcp.com", "interbank.pe", "bbva.pe", "scotiabank.com.pe", "bn.com.pe",
  "sbs.gob.pe", "gob.pe", "indecopi.gob.pe", "pj.gob.pe", "mpfn.gob.pe", "osiptel.gob.pe",
];
const institutions: Record<string, string> = {
  BCP: "Banco de Crédito del Perú BCP",
  Interbank: "Interbank Perú",
  BBVA: "BBVA Perú",
  Scotiabank: "Scotiabank Perú",
  "Banco de la Nación": "Banco de la Nación del Perú",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const userId = await signedIn(request);
  if (!userId) return json({ error: "unauthorized" }, 401);
  const key = Deno.env.get("EXA_API_KEY");
  if (!key) return json({ error: "provider_not_configured" }, 503);
  try {
    const body = await request.json();
    const institution = institutions[String(body.institution ?? "")];
    if (!institution) return json({ error: "unsupported_institution" }, 400);
    if (!await consumeQuota(userId, "official_search", 40)) return json({ error: "daily_limit_reached" }, 429);
    const response = await fetch("https://api.exa.ai/search", {
      method: "POST", headers: { "x-api-key": key, "Content-Type": "application/json" },
      body: JSON.stringify({
        query: `Perú ${institution} alertas oficiales sobre suplantación, fraude, llamadas falsas, denuncias o casos judiciales publicados por la entidad`,
        type: "auto", numResults: 8, includeDomains: officialDomains,
        contents: { highlights: { maxCharacters: 700 } },
      }),
      signal: AbortSignal.timeout(15_000),
    });
    if (!response.ok) return json({ error: "search_unavailable" }, 502);
    const data = await response.json();
    const results = (Array.isArray(data.results) ? data.results : []).flatMap((item: Record<string, unknown>) => {
      if (typeof item.url !== "string" || typeof item.title !== "string") return [];
      let sourceUrl: URL;
      try { sourceUrl = new URL(item.url); } catch { return []; }
      if (sourceUrl.protocol !== "https:" || !isOfficialDomain(sourceUrl.hostname)) return [];
      const host = sourceUrl.hostname.toLowerCase();
      const excerpt = Array.isArray(item.highlights) ? item.highlights.filter((part) => typeof part === "string").join(" ").slice(0, 900) : "";
      return [{
        title: item.title.slice(0, 180), url: sourceUrl.href, publishedAt: typeof item.publishedDate === "string" ? item.publishedDate : null,
        excerpt, sourceType: isCourtOrAuthority(host) ? "autoridad_o_justicia" : "entidad_oficial",
      }];
    }).slice(0, 5);
    const apifyToken = Deno.env.get("APIFY_API_TOKEN");
    const enriched = await Promise.all(results.slice(0, 3).map(async (source: Record<string, unknown>) => {
      if (!apifyToken || typeof source.url !== "string") return source;
      try {
        const scraped = await fetch("https://web-fetch.apify.actor/", {
          method: "POST",
          headers: { Authorization: `Bearer ${apifyToken}`, "Content-Type": "application/json" },
          body: JSON.stringify({ url: source.url, formats: ["markdown"] }),
          signal: AbortSignal.timeout(10_000),
        });
        if (!scraped.ok) return source;
        const page = await scraped.json();
        const loadedUrl = typeof page.fetch?.loadedUrl === "string" ? page.fetch.loadedUrl : source.url;
        let canonicalSourceUrl: URL;
        try { canonicalSourceUrl = new URL(loadedUrl); } catch { return source; }
        if (canonicalSourceUrl.protocol !== "https:" || !isOfficialDomain(canonicalSourceUrl.hostname)) return source;
        const markdown = typeof page.markdown === "string" ? page.markdown : "";
        const excerpt = extractRelevantExcerpt(markdown);
        return {
          ...source,
          title: typeof page.metadata?.title === "string" ? page.metadata.title.slice(0, 180) : source.title,
          url: canonicalSourceUrl.href,
          excerpt: excerpt || source.excerpt,
        };
      } catch (_error) {
        return source;
      }
    }));
    return json({ sources: enriched.concat(results.slice(3)), verifiedIdentity: false, message: "Los resultados muestran publicaciones de fuentes oficiales. No confirman quién llama ni prueban que esa persona haya cometido un delito." });
  } catch (_error) {
    return json({ error: "search_unavailable" }, 502);
  }
});
function extractRelevantExcerpt(markdown: string): string {
  const text = markdown
    .replace(/\[([^\]]+)\]\((?:https?:\/\/[^)]+)\)/g, "$1")
    .replace(/[>#*_`~]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  if (!text) return "";
  const match = /\b(estaf\w*|fraud\w*|suplant\w*|vishing|llamad\w*|clave\w*|c[oó]dig\w*|extorsi\w*|alerta\w*)\b/i.exec(text);
  const start = Math.max(0, (match?.index ?? 0) - 160);
  return text.slice(start, start + 900);
}
function isOfficialDomain(host: string) { const normalized = host.toLowerCase(); return officialDomains.some((domain) => normalized === domain || normalized.endsWith(`.${domain}`)); }
function isCourtOrAuthority(host: string) { return ["sbs.gob.pe", "gob.pe", "indecopi.gob.pe", "pj.gob.pe", "mpfn.gob.pe", "osiptel.gob.pe"].some((domain) => host === domain || host.endsWith(`.${domain}`)); }
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
