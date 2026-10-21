import { QR_GATEWAY_POLICY as policy } from "./config.ts";
import { readJsonResponse, scanUrl, UrlscanError } from "./urlscan.ts";

const SCHEMA_VERSION = policy.version;
const PROVIDER_ID = policy.provider;
const CONSENT_VERSION = policy.consentVersion;
const MAX_BODY_BYTES = 16 * 1024;
const MAX_URL_BYTES = 8 * 1024;
const MIN_CACHE_HMAC_SECRET_BYTES = 32;
const ALLOWED_THREATS = new Set(policy.categories);
const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET, POST, OPTIONS",
  "access-control-allow-headers":
    "apikey, authorization, content-type, x-client-info",
  "access-control-max-age": "86400",
};

class InvalidBodyEncodingError extends Error {}

type GatewayConfig = {
  schemaVersion: number;
  provider: string;
  threatTypes: string[];
  perMinuteLimit: number;
  perHourLimit: number;
  perDayLimit: number;
  perMonthLimit: number;
};

type GatewayRequest = {
  schemaVersion: number;
  requestId: string;
  inputRevision: number;
  url: string;
  consentVersion: string;
};

type ReputationResponse = {
  schemaVersion: number;
  requestId: string;
  inputRevision: number;
  provider: string;
  providerVerdict: "match" | "no_match";
  checkedCategories: string[];
  matchingCategories: string[];
  providerCheckedAt: string;
  reviewExpiresAt: string | null;
  servedFromCache: boolean;
  redirectResolution: "not_performed";
  coverageComplete: true;
  isFixture: false;
};

const json = (
  body: unknown,
  status = 200,
  extraHeaders: Record<string, string> = {},
) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      ...CORS_HEADERS,
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      ...extraHeaders,
    },
  });

const errorResponse = (
  requestId: string,
  code: string,
  status: number,
  retryAfterSeconds?: number,
) =>
  json(
    {
      schemaVersion: SCHEMA_VERSION,
      requestId,
      code,
      message: "No se pudo verificar la reputación del enlace.",
      ...(retryAfterSeconds === undefined ? {} : { retryAfterSeconds }),
    },
    status,
    retryAfterSeconds === undefined
      ? {}
      : { "retry-after": String(retryAfterSeconds) },
  );

function routeFor(requestUrl: string): string {
  const pathname = new URL(requestUrl).pathname;
  const functionPrefix = "/functions/v1/qr-reputation";
  return pathname.startsWith(functionPrefix)
    ? pathname.slice(functionPrefix.length) || "/"
    : pathname;
}

function randomRequestId(): string {
  return crypto.randomUUID().replaceAll("-", "");
}

async function readBodyWithinLimit(request: Request): Promise<string | null> {
  const declaredLength = Number(request.headers.get("content-length"));
  if (Number.isFinite(declaredLength) && declaredLength > MAX_BODY_BYTES) {
    return null;
  }
  if (!request.body) return "";

  const reader = request.body.getReader();
  const chunks: Uint8Array[] = [];
  let length = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    length += value.byteLength;
    if (length > MAX_BODY_BYTES) {
      await reader.cancel();
      return null;
    }
    chunks.push(value);
  }

  const bytes = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  try {
    return new TextDecoder("utf-8", { fatal: true }).decode(bytes);
  } catch {
    throw new InvalidBodyEncodingError("invalid_utf8");
  }
}

function validateRequest(value: unknown): GatewayRequest | null {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    return null;
  }
  const body = value as Record<string, unknown>;
  const allowedKeys = new Set([
    "schemaVersion",
    "requestId",
    "inputRevision",
    "url",
    "consentVersion",
  ]);
  if (Object.keys(body).some((key) => !allowedKeys.has(key))) return null;
  if (
    body.schemaVersion !== SCHEMA_VERSION ||
    typeof body.requestId !== "string" ||
    !/^[A-Za-z0-9_-]{8,80}$/.test(body.requestId) ||
    !Number.isSafeInteger(body.inputRevision) ||
    (body.inputRevision as number) < 0 ||
    typeof body.url !== "string" ||
    typeof body.consentVersion !== "string" ||
    body.consentVersion !== CONSENT_VERSION
  ) return null;
  if (new TextEncoder().encode(body.url).byteLength > MAX_URL_BYTES) {
    return null;
  }
  if (!isEligibleUrl(body.url)) return null;
  return body as GatewayRequest;
}

function isEligibleUrl(rawUrl: string): boolean {
  if (
    Array.from(rawUrl).some((character) => {
      const code = character.charCodeAt(0);
      return code < 32 || code === 127;
    }) || rawUrl.includes("#")
  ) {
    return false;
  }
  let parsed: URL;
  try {
    parsed = new URL(rawUrl);
  } catch {
    return false;
  }
  if (
    !["http:", "https:"].includes(parsed.protocol) ||
    parsed.username !== "" || parsed.password !== "" ||
    parsed.hostname === "" ||
    (parsed.port !== "" &&
      !((parsed.protocol === "https:" && parsed.port === "443") ||
        (parsed.protocol === "http:" && parsed.port === "80")))
  ) return false;

  const host = parsed.hostname.toLowerCase().replace(/^\[|\]$/g, "");
  if (
    host.includes(":") ||
    /^(?:\d+\.){3}\d+$/.test(host) ||
    /^(?:0x[0-9a-f]+|\d+)(?:\.(?:0x[0-9a-f]+|\d+))*$/i.test(host) ||
    !host.includes(".")
  ) return false;
  const blockedSuffixes = [
    "localhost",
    "local",
    "internal",
    "test",
    "invalid",
    "example",
    "arpa",
  ];
  return !blockedSuffixes.some((suffix) =>
    host === suffix || host.endsWith(`.${suffix}`)
  );
}

function requiredSecrets() {
  const cacheHmacSecret = Deno.env.get("QR_CACHE_HMAC_SECRET") ?? "";
  return {
    supabaseUrl: Deno.env.get("SUPABASE_URL")?.trim() ?? "",
    serviceRoleKey: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim() ?? "",
    urlscanApiKey: Deno.env.get("URLSCAN_API_KEY")?.trim() ?? "",
    cacheHmacSecret: new TextEncoder().encode(cacheHmacSecret).byteLength >=
        MIN_CACHE_HMAC_SECRET_BYTES
      ? cacheHmacSecret
      : "",
  };
}

async function supabaseRpc<T>(
  name: string,
  args: Record<string, unknown> = {},
): Promise<T> {
  const { supabaseUrl, serviceRoleKey } = requiredSecrets();
  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error("gateway_not_configured");
  }
  const controller = new AbortController();
  const timeoutMs = name === "qr_store_reputation_match" ? 300 : 1_000;
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(`${supabaseUrl}/rest/v1/rpc/${name}`, {
      method: "POST",
      redirect: "error",
      signal: controller.signal,
      headers: {
        apikey: serviceRoleKey,
        authorization: `Bearer ${serviceRoleKey}`,
        "content-type": "application/json",
        accept: "application/json",
      },
      body: JSON.stringify(args),
    });
    if (!response.ok) throw new Error("gateway_storage_unavailable");
    return await readJsonResponse(response, 16 * 1024) as T;
  } finally {
    clearTimeout(timeout);
  }
}

async function getConfig(): Promise<GatewayConfig> {
  const config = await supabaseRpc<GatewayConfig>("qr_gateway_get_config");
  if (
    config?.schemaVersion !== SCHEMA_VERSION ||
    config.provider !== PROVIDER_ID ||
    !Array.isArray(config.threatTypes) ||
    config.threatTypes.length !== 1 || config.threatTypes[0] !== policy.scope ||
    !Number.isSafeInteger(config.perMinuteLimit) ||
    !Number.isSafeInteger(config.perHourLimit) ||
    !Number.isSafeInteger(config.perDayLimit) ||
    !Number.isSafeInteger(config.perMonthLimit)
  ) {
    throw new Error("gateway_config_invalid");
  }
  return config;
}

async function makeCacheKey(
  url: string,
  threatTypes: string[],
  secret: string,
): Promise<string> {
  const normalizedUrl = new URL(url).href;
  const material = `${PROVIDER_ID}:v${SCHEMA_VERSION}:${
    [...threatTypes].sort().join(",")
  }:${normalizedUrl}`;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const digest = new Uint8Array(
    await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(material)),
  );
  return [...digest].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

function validMatchCategories(
  value: unknown,
  allowed: Set<string>,
): string[] | null {
  if (!Array.isArray(value)) return null;
  const categories = [...new Set(value)];
  if (
    categories.some((category) =>
      typeof category !== "string" || !allowed.has(category)
    )
  ) return null;
  return categories as string[];
}

function makeSuccess(
  request: GatewayRequest,
  verdict: "match" | "no_match",
  checkedAt: string,
  categories: string[],
  expiresAt: string | null,
  servedFromCache: boolean,
  checkedCategories: string[],
): ReputationResponse {
  return {
    schemaVersion: SCHEMA_VERSION,
    requestId: request.requestId,
    inputRevision: request.inputRevision,
    provider: PROVIDER_ID,
    providerVerdict: verdict,
    checkedCategories,
    matchingCategories: categories,
    providerCheckedAt: checkedAt,
    reviewExpiresAt: expiresAt,
    servedFromCache,
    redirectResolution: "not_performed",
    coverageComplete: true,
    isFixture: false,
  };
}

async function handleLookup(
  request: Request,
  requestId: string,
  scan: typeof scanUrl,
): Promise<Response> {
  let bodyText: string | null;
  try {
    bodyText = await readBodyWithinLimit(request);
  } catch (error) {
    if (error instanceof InvalidBodyEncodingError) {
      return errorResponse(requestId, "invalid_input", 400);
    }
    throw error;
  }
  if (bodyText === null) {
    return errorResponse(requestId, "payload_too_large", 413);
  }
  let rawBody: unknown;
  try {
    rawBody = JSON.parse(bodyText);
  } catch {
    return errorResponse(requestId, "invalid_input", 400);
  }
  const input = validateRequest(rawBody);
  if (!input) return errorResponse(requestId, "invalid_input", 400);
  requestId = input.requestId;

  const { urlscanApiKey, cacheHmacSecret } = requiredSecrets();
  if (!urlscanApiKey || !cacheHmacSecret) {
    return errorResponse(requestId, "not_configured", 503);
  }

  let config: GatewayConfig;
  try {
    config = await getConfig();
  } catch {
    return errorResponse(requestId, "provider_unavailable", 503);
  }

  const checkedCategories = [...config.threatTypes].sort();
  const cacheKey = await makeCacheKey(
    input.url,
    checkedCategories,
    cacheHmacSecret,
  );
  try {
    const cached = await supabaseRpc<
      {
        categories?: unknown;
        providerCheckedAt?: unknown;
        providerExpiresAt?: unknown;
      } | null
    >("qr_get_reputation_match", { p_cache_key: cacheKey });
    if (cached !== null) {
      const categories = validMatchCategories(
        cached.categories,
        ALLOWED_THREATS,
      );
      const checkedAt = typeof cached.providerCheckedAt === "string"
        ? Date.parse(cached.providerCheckedAt)
        : Number.NaN;
      const expiresAt = typeof cached.providerExpiresAt === "string"
        ? Date.parse(cached.providerExpiresAt)
        : Number.NaN;
      if (
        categories && categories.length > 0 &&
        Number.isFinite(checkedAt) && checkedAt <= Date.now() &&
        Number.isFinite(expiresAt) && expiresAt > Date.now() &&
        expiresAt <= checkedAt + policy.matchMaxAgeMs
      ) {
        return json(makeSuccess(
          input,
          "match",
          new Date(checkedAt).toISOString(),
          categories,
          new Date(expiresAt).toISOString(),
          true,
          checkedCategories,
        ));
      }
    }
  } catch {
    return errorResponse(requestId, "provider_unavailable", 503);
  }

  let quota: { allowed: boolean; code?: string; retryAfterSeconds?: number };
  try {
    quota = await supabaseRpc("qr_consume_reputation_quota");
  } catch {
    return errorResponse(requestId, "provider_unavailable", 503);
  }
  if (quota.allowed !== true) {
    const code = quota.code === "rate_limited"
      ? "rate_limited"
      : quota.code === "quota_exhausted"
      ? "quota_exhausted"
      : "provider_unavailable";
    const retry = Number.isSafeInteger(quota.retryAfterSeconds)
      ? Math.max(1, quota.retryAfterSeconds as number)
      : undefined;
    return errorResponse(
      requestId,
      code,
      code === "provider_unavailable" ? 503 : 429,
      retry,
    );
  }

  let analysis;
  try {
    analysis = await scan(input.url, urlscanApiKey, {}, request.signal);
  } catch (error) {
    return error instanceof UrlscanError
      ? errorResponse(
        requestId,
        error.code,
        error.status,
        error.retryAfterSeconds,
      )
      : errorResponse(requestId, "provider_unavailable", 503);
  }
  if (analysis.verdict === "match") {
    try {
      await supabaseRpc<boolean>("qr_store_reputation_match", {
        p_cache_key: cacheKey,
        p_categories: analysis.categories,
        p_provider_checked_at: analysis.checkedAt,
        p_provider_expires_at: analysis.expiresAt,
      });
    } catch {
      // A verified match still blocks opening if the cache write is unavailable.
    }
  }

  return json(makeSuccess(
    input,
    analysis.verdict,
    analysis.checkedAt,
    analysis.categories,
    analysis.expiresAt,
    false,
    checkedCategories,
  ));
}

export async function handleRequest(
  request: Request,
  scan: typeof scanUrl = scanUrl,
): Promise<Response> {
  const requestId = randomRequestId();
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  const route = routeFor(request.url);
  if (route === "/health" && request.method === "GET") {
    return json({ status: "ok", schemaVersion: SCHEMA_VERSION });
  }
  if (route === "/v1/capabilities" && request.method === "GET") {
    const secrets = requiredSecrets();
    return json({
      schemaVersion: SCHEMA_VERSION,
      provider: PROVIDER_ID,
      secretsConfigured: Boolean(
        secrets.supabaseUrl && secrets.serviceRoleKey &&
          secrets.urlscanApiKey && secrets.cacheHmacSecret,
      ),
    });
  }
  if (route !== "/v1/reputation/check") {
    return errorResponse(requestId, "invalid_input", 404);
  }
  if (request.method !== "POST") {
    return errorResponse(requestId, "invalid_input", 405);
  }
  const contentType = request.headers.get("content-type")?.split(";", 1)[0]
    .trim().toLowerCase();
  if (contentType !== "application/json") {
    return errorResponse(requestId, "invalid_input", 400);
  }

  try {
    return await handleLookup(request, requestId, scan);
  } catch {
    return errorResponse(requestId, "provider_unavailable", 503);
  }
}
