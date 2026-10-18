const SCHEMA_VERSION = 1;
const PROVIDER_ID = 'google_web_risk_lookup';
const CONSENT_VERSION = 'qr-reputation-consent-v1';
const MAX_BODY_BYTES = 16 * 1024;
const MAX_URL_BYTES = 8 * 1024;
const MAX_PROVIDER_RESPONSE_BYTES = 64 * 1024;
const PROVIDER_TIMEOUT_MS = 4_500;
const MIN_CACHE_HMAC_SECRET_BYTES = 32;
const GOOGLE_LOOKUP_ENDPOINT = 'https://webrisk.googleapis.com/v1/uris:search';
const ALLOWED_THREATS = new Set([
  'MALWARE',
  'SOCIAL_ENGINEERING',
  'UNWANTED_SOFTWARE',
]);
const CORS_HEADERS = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, OPTIONS',
  'access-control-allow-headers': 'apikey, authorization, content-type, x-client-info',
  'access-control-max-age': '86400',
};

class InvalidBodyEncodingError extends Error {}

type GatewayConfig = {
  schemaVersion: number;
  provider: string;
  threatTypes: string[];
  perMinuteLimit: number;
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
  providerVerdict: 'match' | 'no_match';
  checkedCategories: string[];
  matchingCategories: string[];
  providerCheckedAt: string;
  providerExpiresAt: string | null;
  servedFromCache: boolean;
  redirectResolution: 'not_performed';
  coverageComplete: true;
  isFixture: false;
};

const json = (body: unknown, status = 200, extraHeaders: Record<string, string> = {}) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      ...CORS_HEADERS,
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
      ...extraHeaders,
    },
  });

const errorResponse = (
  requestId: string,
  code: string,
  status: number,
  retryAfterSeconds?: number,
) => json({
  schemaVersion: SCHEMA_VERSION,
  requestId,
  code,
  message: 'No se pudo verificar la reputación del enlace.',
  ...(retryAfterSeconds === undefined ? {} : { retryAfterSeconds }),
}, status, retryAfterSeconds === undefined ? {} : { 'retry-after': String(retryAfterSeconds) });

function routeFor(requestUrl: string): string {
  const pathname = new URL(requestUrl).pathname;
  const functionPrefix = '/functions/v1/qr-reputation';
  return pathname.startsWith(functionPrefix)
    ? pathname.slice(functionPrefix.length) || '/'
    : pathname;
}

function randomRequestId(): string {
  return crypto.randomUUID().replaceAll('-', '');
}

async function readBodyWithinLimit(request: Request): Promise<string | null> {
  const declaredLength = Number(request.headers.get('content-length'));
  if (Number.isFinite(declaredLength) && declaredLength > MAX_BODY_BYTES) return null;
  if (!request.body) return '';

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
    return new TextDecoder('utf-8', { fatal: true }).decode(bytes);
  } catch {
    throw new InvalidBodyEncodingError('invalid_utf8');
  }
}

function validateRequest(value: unknown): GatewayRequest | null {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) return null;
  const body = value as Record<string, unknown>;
  const allowedKeys = new Set([
    'schemaVersion', 'requestId', 'inputRevision', 'url', 'consentVersion',
  ]);
  if (Object.keys(body).some((key) => !allowedKeys.has(key))) return null;
  if (body.schemaVersion !== SCHEMA_VERSION ||
      typeof body.requestId !== 'string' ||
      !/^[A-Za-z0-9_-]{8,80}$/.test(body.requestId) ||
      !Number.isSafeInteger(body.inputRevision) ||
      (body.inputRevision as number) < 0 ||
      typeof body.url !== 'string' ||
      typeof body.consentVersion !== 'string' ||
      body.consentVersion !== CONSENT_VERSION) return null;
  if (new TextEncoder().encode(body.url).byteLength > MAX_URL_BYTES) return null;
  if (!isEligibleUrl(body.url)) return null;
  return body as GatewayRequest;
}

function isEligibleUrl(rawUrl: string): boolean {
  if (/[\u0000-\u001f\u007f]/.test(rawUrl) || rawUrl.includes('#')) return false;
  let parsed: URL;
  try {
    parsed = new URL(rawUrl);
  } catch {
    return false;
  }
  if (!['http:', 'https:'].includes(parsed.protocol) ||
      parsed.username !== '' || parsed.password !== '' ||
      parsed.hostname === '' ||
      (parsed.port !== '' &&
        !((parsed.protocol === 'https:' && parsed.port === '443') ||
          (parsed.protocol === 'http:' && parsed.port === '80')))) return false;

  const host = parsed.hostname.toLowerCase().replace(/^\[|\]$/g, '');
  if (host.includes(':') ||
      /^(?:\d+\.){3}\d+$/.test(host) ||
      /^(?:0x[0-9a-f]+|\d+)(?:\.(?:0x[0-9a-f]+|\d+))*$/i.test(host) ||
      !host.includes('.')) return false;
  const blockedSuffixes = [
    'localhost', 'local', 'internal', 'test', 'invalid', 'example', 'arpa',
  ];
  return !blockedSuffixes.some((suffix) => host === suffix || host.endsWith(`.${suffix}`));
}

async function readJsonResponse(response: Response, maxBytes: number): Promise<unknown> {
  const reader = response.body?.getReader();
  if (!reader) throw new Error('empty_response');
  const chunks: Uint8Array[] = [];
  let length = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    length += value.byteLength;
    if (length > maxBytes) {
      await reader.cancel();
      throw new Error('response_too_large');
    }
    chunks.push(value);
  }
  const bytes = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
}

function requiredSecrets() {
  const cacheHmacSecret = Deno.env.get('QR_CACHE_HMAC_SECRET') ?? '';
  return {
    supabaseUrl: Deno.env.get('SUPABASE_URL')?.trim() ?? '',
    serviceRoleKey: Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')?.trim() ?? '',
    webRiskApiKey: Deno.env.get('WEBRISK_API_KEY')?.trim() ?? '',
    cacheHmacSecret: new TextEncoder().encode(cacheHmacSecret).byteLength >= MIN_CACHE_HMAC_SECRET_BYTES
      ? cacheHmacSecret
      : '',
  };
}

async function supabaseRpc<T>(
  name: string,
  args: Record<string, unknown> = {},
): Promise<T> {
  const { supabaseUrl, serviceRoleKey } = requiredSecrets();
  if (!supabaseUrl || !serviceRoleKey) throw new Error('gateway_not_configured');
  const controller = new AbortController();
  const timeoutMs = name === 'qr_store_reputation_match' ? 300 : 1_000;
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(`${supabaseUrl}/rest/v1/rpc/${name}`, {
      method: 'POST',
      redirect: 'error',
      signal: controller.signal,
      headers: {
        apikey: serviceRoleKey,
        authorization: `Bearer ${serviceRoleKey}`,
        'content-type': 'application/json',
        accept: 'application/json',
      },
      body: JSON.stringify(args),
    });
    if (!response.ok) throw new Error('gateway_storage_unavailable');
    return await readJsonResponse(response, 16 * 1024) as T;
  } finally {
    clearTimeout(timeout);
  }
}

async function getConfig(): Promise<GatewayConfig> {
  const config = await supabaseRpc<GatewayConfig>('qr_gateway_get_config');
  if (config?.schemaVersion !== SCHEMA_VERSION ||
      config.provider !== PROVIDER_ID ||
      !Array.isArray(config.threatTypes) ||
      config.threatTypes.length === 0 ||
      config.threatTypes.some((type) => !ALLOWED_THREATS.has(type)) ||
      !Number.isSafeInteger(config.perMinuteLimit) ||
      !Number.isSafeInteger(config.perDayLimit) ||
      !Number.isSafeInteger(config.perMonthLimit)) {
    throw new Error('gateway_config_invalid');
  }
  return config;
}

async function makeCacheKey(url: string, threatTypes: string[], secret: string): Promise<string> {
  const normalizedUrl = new URL(url).href;
  const material = `web-risk-lookup:v1:${[...threatTypes].sort().join(',')}:${normalizedUrl}`;
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const digest = new Uint8Array(await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(material)));
  return [...digest].map((byte) => byte.toString(16).padStart(2, '0')).join('');
}

function validMatchCategories(value: unknown, allowed: Set<string>): string[] | null {
  if (!Array.isArray(value)) return null;
  const categories = [...new Set(value)];
  if (categories.some((category) => typeof category !== 'string' || !allowed.has(category))) return null;
  return categories as string[];
}

function makeSuccess(
  request: GatewayRequest,
  verdict: 'match' | 'no_match',
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
    providerExpiresAt: expiresAt,
    servedFromCache,
    redirectResolution: 'not_performed',
    coverageComplete: true,
    isFixture: false,
  };
}

async function handleLookup(request: Request, requestId: string): Promise<Response> {
  let bodyText: string | null;
  try {
    bodyText = await readBodyWithinLimit(request);
  } catch (error) {
    if (error instanceof InvalidBodyEncodingError) {
      return errorResponse(requestId, 'invalid_input', 400);
    }
    throw error;
  }
  if (bodyText === null) return errorResponse(requestId, 'payload_too_large', 413);
  let rawBody: unknown;
  try {
    rawBody = JSON.parse(bodyText);
  } catch {
    return errorResponse(requestId, 'invalid_input', 400);
  }
  const input = validateRequest(rawBody);
  if (!input) return errorResponse(requestId, 'invalid_input', 400);
  requestId = input.requestId;

  const { webRiskApiKey, cacheHmacSecret } = requiredSecrets();
  if (!webRiskApiKey || !cacheHmacSecret) {
    return errorResponse(requestId, 'not_configured', 503);
  }

  let config: GatewayConfig;
  try {
    config = await getConfig();
  } catch {
    return errorResponse(requestId, 'provider_unavailable', 503);
  }

  const checkedCategories = [...config.threatTypes].sort();
  const cacheKey = await makeCacheKey(input.url, checkedCategories, cacheHmacSecret);
  try {
    const cached = await supabaseRpc<{
      categories?: unknown;
      providerCheckedAt?: unknown;
      providerExpiresAt?: unknown;
    } | null>('qr_get_reputation_match', { p_cache_key: cacheKey });
    if (cached !== null) {
      const categories = validMatchCategories(cached.categories, ALLOWED_THREATS);
      const checkedAt = typeof cached.providerCheckedAt === 'string'
        ? Date.parse(cached.providerCheckedAt)
        : Number.NaN;
      const expiresAt = typeof cached.providerExpiresAt === 'string'
        ? Date.parse(cached.providerExpiresAt)
        : Number.NaN;
      if (categories && categories.length > 0 &&
          Number.isFinite(checkedAt) && Number.isFinite(expiresAt) && expiresAt > Date.now()) {
        return json(makeSuccess(
          input,
          'match',
          new Date(checkedAt).toISOString(),
          categories,
          new Date(expiresAt).toISOString(),
          true,
          checkedCategories,
        ));
      }
    }
  } catch {
    return errorResponse(requestId, 'provider_unavailable', 503);
  }

  let quota: { allowed: boolean; code?: string; retryAfterSeconds?: number };
  try {
    quota = await supabaseRpc('qr_consume_reputation_quota');
  } catch {
    return errorResponse(requestId, 'provider_unavailable', 503);
  }
  if (quota.allowed !== true) {
    const code = quota.code === 'rate_limited' ? 'rate_limited' :
      quota.code === 'quota_exhausted' ? 'quota_exhausted' : 'provider_unavailable';
    const retry = Number.isSafeInteger(quota.retryAfterSeconds)
      ? Math.max(1, quota.retryAfterSeconds as number)
      : undefined;
    return errorResponse(requestId, code, code === 'provider_unavailable' ? 503 : 429, retry);
  }

  const googleUrl = new URL(GOOGLE_LOOKUP_ENDPOINT);
  googleUrl.searchParams.set('uri', input.url);
  for (const threatType of checkedCategories) googleUrl.searchParams.append('threatTypes', threatType);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), PROVIDER_TIMEOUT_MS);
  let providerResponse: Response;
  let providerBody: unknown;
  try {
    providerResponse = await fetch(googleUrl, {
      method: 'GET',
      redirect: 'error',
      signal: controller.signal,
      headers: {
        accept: 'application/json',
        'x-goog-api-key': webRiskApiKey,
      },
    });
    if (!providerResponse.ok) {
      await providerResponse.body?.cancel();
      if (providerResponse.status === 429) {
        return errorResponse(requestId, 'quota_exhausted', 429, 60);
      }
      return errorResponse(requestId, 'provider_unavailable', 503);
    }
    try {
      providerBody = await readJsonResponse(providerResponse, MAX_PROVIDER_RESPONSE_BYTES);
    } catch {
      if (controller.signal.aborted) {
        return errorResponse(requestId, 'provider_timeout', 504);
      }
      return errorResponse(requestId, 'invalid_provider_response', 503);
    }
  } catch {
    return errorResponse(requestId, controller.signal.aborted ? 'provider_timeout' : 'provider_unavailable',
      controller.signal.aborted ? 504 : 503);
  } finally {
    clearTimeout(timeout);
  }
  if (typeof providerBody !== 'object' || providerBody === null || Array.isArray(providerBody)) {
    return errorResponse(requestId, 'invalid_provider_response', 503);
  }

  const threat = (providerBody as Record<string, unknown>).threat;
  if (threat !== undefined &&
      (typeof threat !== 'object' || threat === null || Array.isArray(threat))) {
    return errorResponse(requestId, 'invalid_provider_response', 503);
  }
  const threatObject = (threat ?? {}) as Record<string, unknown>;
  const threatTypes = threatObject.threatTypes ?? [];
  if (!Array.isArray(threatTypes)) return errorResponse(requestId, 'invalid_provider_response', 503);
  const categories = validMatchCategories(threatTypes, ALLOWED_THREATS);
  if (!categories || categories.some((category) => !checkedCategories.includes(category))) {
    return errorResponse(requestId, 'invalid_provider_response', 503);
  }
  const providerCheckedAt = new Date().toISOString();
  if (categories.length === 0) {
    return json(makeSuccess(
      input,
      'no_match',
      providerCheckedAt,
      [],
      null,
      false,
      checkedCategories,
    ));
  }

  const expireTime = threatObject.expireTime;
  if (typeof expireTime !== 'string') {
    return errorResponse(requestId, 'invalid_provider_response', 503);
  }
  const expiresAt = Date.parse(expireTime);
  if (!Number.isFinite(expiresAt) || expiresAt <= Date.now()) {
    return errorResponse(requestId, 'invalid_provider_response', 503);
  }
  const matchingCategories = [...categories].sort();
  const providerExpiresAt = new Date(expiresAt).toISOString();
  try {
    await supabaseRpc<boolean>('qr_store_reputation_match', {
      p_cache_key: cacheKey,
      p_categories: matchingCategories,
      p_provider_checked_at: providerCheckedAt,
      p_provider_expires_at: providerExpiresAt,
    });
  } catch {
    // A verified match still blocks opening if the cache write is unavailable.
  }

  return json(makeSuccess(
    input,
    'match',
    providerCheckedAt,
    matchingCategories,
    providerExpiresAt,
    false,
    checkedCategories,
  ));
}

Deno.serve(async (request: Request) => {
  const requestId = randomRequestId();
  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS_HEADERS });

  const route = routeFor(request.url);
  if (route === '/health' && request.method === 'GET') {
    return json({ status: 'ok', schemaVersion: SCHEMA_VERSION });
  }
  if (route === '/v1/capabilities' && request.method === 'GET') {
    const secrets = requiredSecrets();
    return json({
      schemaVersion: SCHEMA_VERSION,
      provider: PROVIDER_ID,
      secretsConfigured: Boolean(
        secrets.supabaseUrl && secrets.serviceRoleKey &&
        secrets.webRiskApiKey && secrets.cacheHmacSecret
      ),
    });
  }
  if (route !== '/v1/reputation/check') {
    return errorResponse(requestId, 'invalid_input', 404);
  }
  if (request.method !== 'POST') return errorResponse(requestId, 'invalid_input', 405);
  const contentType = request.headers.get('content-type')?.split(';', 1)[0].trim().toLowerCase();
  if (contentType !== 'application/json') {
    return errorResponse(requestId, 'invalid_input', 400);
  }

  try {
    return await handleLookup(request, requestId);
  } catch {
    return errorResponse(requestId, 'provider_unavailable', 503);
  }
});
