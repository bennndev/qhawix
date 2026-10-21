// Personal site notes for Escudo QR, stored in Atomic Memory.
//
// A note is something the person wrote about a destination they reviewed
// (for example "lo verifiqué en la app oficial de mi tienda"). It is shown
// back the next time the same exact host is reviewed. It never changes the
// reputation verdict, the opening policy or any safety decision.
//
// Identity comes only from the Supabase session (`/auth/v1/user`); the memory
// subject is derived from that user id on the server and never from the body.
// Atomic Memory credentials stay in Edge Function secrets.
//
// One note per host: each note carries `metadata.externalId`, a stable hash of
// the normalized host, and is read back with the documented exact lookup
// `GET /v1/memories/by-external-id/{externalId}` (scoped to user_id). No
// semantic search is involved, so a note never drops out of a result window
// as the person adds notes for other sites. Only the normalized hostname and
// the note text are sent; never a full URL or the raw scanned content.

import { redactSensitive } from "../_shared/domain/redact.ts";

export const SCHEMA_VERSION = 1;
export const SOURCE_SITE = "qhawix-qr-site-notes";
export const NOTE_KIND = "qr_site_note";
export const MAX_NOTE_CHARS = 280;
export const DAILY_LIMIT = 120;
const MAX_BODY_BYTES = 4 * 1024;
const MAX_PROVIDER_RESPONSE_BYTES = 256 * 1024;
const PROVIDER_TIMEOUT_MS = 3_500;
const AUTH_TIMEOUT_MS = 3_000;
const QUOTA_TIMEOUT_MS = 2_000;
/** Upper bound on duplicate rows cleared by one delete request. */
const MAX_DELETE_ROUNDS = 5;
const EXTERNAL_ID_PREFIX = "qhawix-site-note-v1-";
const DEFAULT_API_URL = "https://api.atomicstrata.ai";
const HOST_PATTERN =
  /^(?=.{1,253}$)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?$/;
const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const EMAIL_PATTERN = /[^\s@]+@[^\s@]+\.[^\s@]+/g;
// deno-lint-ignore no-control-regex
const CONTROL_PATTERN = /[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/;

const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-allow-headers":
    "apikey, authorization, content-type, x-client-info",
};

export type Env = (name: string) => string | undefined;

export type Deps = {
  env: Env;
  fetch: typeof fetch;
};

type NoteRequest =
  | { action: "get" | "delete"; host: string }
  | { action: "save"; host: string; note: string };

type StoredNote = { id: string; text: string; savedAt: string | null };

class ProviderError extends Error {
  constructor(readonly code: "provider_unavailable" | "provider_timeout") {
    super(code);
  }
}

const json = (body: Record<string, unknown>, status = 200) =>
  new Response(
    JSON.stringify({ schemaVersion: SCHEMA_VERSION, ...body }),
    {
      status,
      headers: {
        ...CORS_HEADERS,
        "content-type": "application/json; charset=utf-8",
        "cache-control": "no-store",
      },
    },
  );

const fail = (code: string, status: number) => json({ code }, status);

export function createHandler(deps: Deps) {
  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response("ok", { headers: CORS_HEADERS });
    }
    if (request.method !== "POST") return fail("method_not_allowed", 405);

    const bodyText = await readBounded(request);
    if (bodyText === null) return fail("payload_too_large", 413);
    let input: NoteRequest | null = null;
    try {
      input = validateRequest(JSON.parse(bodyText));
    } catch {
      input = null;
    }
    if (!input) return fail("invalid_input", 400);

    const userId = await authenticatedUserId(request, deps);
    if (!userId) return fail("unauthorized", 401);

    const memory = memoryConfig(deps.env);
    if (!memory) return fail("not_configured", 503);

    if (input.action !== "delete") {
      const quota = await consumeQuota(userId, deps);
      if (quota === "unavailable") return fail("provider_unavailable", 503);
      if (quota === "exceeded") return fail("rate_limited", 429);
    }

    const client = new MemoryClient(memory, subjectFor(userId), deps.fetch);
    const externalId = await externalIdFor(input.host);
    try {
      switch (input.action) {
        case "get": {
          const note = await client.find(externalId, input.host);
          return note
            ? json({ status: "found", note })
            : json({ status: "none" });
        }
        case "save": {
          // Write first so a failed write never loses the confirmed note.
          // Then remove the previous row by its own id, and confirm that the
          // exact lookup now resolves to the new row.
          const previous = await client.find(externalId, input.host);
          const saved = await client.save(externalId, input.host, input.note);
          if (!saved) return fail("save_unconfirmed", 502);
          if (previous && previous.id !== saved.id) {
            if (!await client.deleteById(previous.id)) {
              // Keep exactly one note: roll the new row back so the previous
              // note stays the only one for this host.
              return await client.deleteById(saved.id)
                ? fail("correction_not_applied", 502)
                : fail("provider_unavailable", 502);
            }
          }
          const current = await client.find(externalId, input.host);
          if (current?.id !== saved.id) return fail("save_unconfirmed", 502);
          return json({ status: "saved", note: current });
        }
        case "delete": {
          // Deleted only when every delete returned the documented
          // `success: true` and the exact lookup finally reports not found.
          let removed = 0;
          for (let round = 0; round < MAX_DELETE_ROUNDS; round++) {
            const note = await client.find(externalId, input.host);
            if (!note) return json({ status: "deleted", removed });
            if (!await client.deleteById(note.id)) {
              return fail("provider_unavailable", 502);
            }
            removed++;
          }
          return fail("provider_unavailable", 502);
        }
      }
    } catch (error) {
      const code = error instanceof ProviderError
        ? error.code
        : "provider_unavailable";
      return fail(code, code === "provider_timeout" ? 504 : 502);
    }
  };
}

/** Memory subject owned by one QHAWIX account; derived only on the server. */
export function subjectFor(userId: string): string {
  return `qhawix:user:${userId.toLowerCase()}`;
}

/** Hides codes, long numbers and e-mail addresses before anything is stored. */
/**
 * Stable caller-owned id for the one note per host (within one subject).
 * A hash keeps it under the provider's 256-character limit for any host.
 */
export async function externalIdFor(host: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(host),
  );
  const hex = Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
  return `${EXTERNAL_ID_PREFIX}${hex}`;
}

export function sanitizeNote(raw: string): string | null {
  const normalized = raw.normalize("NFC").replace(/\s+/g, " ").trim();
  if (normalized.length === 0 || normalized.length > MAX_NOTE_CHARS) {
    return null;
  }
  if (CONTROL_PATTERN.test(raw.replace(/[\n\r\t]/g, " "))) return null;
  return redactSensitive(normalized.replace(EMAIL_PATTERN, "[correo oculto]"));
}

export function noteContent(host: string, note: string): string {
  return `${notePrefix(host)}${note}`;
}

function notePrefix(host: string): string {
  return `Nota personal de QHAWIX sobre el sitio ${host}: `;
}

function validateRequest(value: unknown): NoteRequest | null {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    return null;
  }
  const body = value as Record<string, unknown>;
  const allowed = new Set(["schemaVersion", "action", "host", "note"]);
  if (Object.keys(body).some((key) => !allowed.has(key))) return null;
  if (body.schemaVersion !== SCHEMA_VERSION) return null;
  if (
    body.action !== "get" && body.action !== "save" && body.action !== "delete"
  ) {
    return null;
  }
  if (typeof body.host !== "string" || !HOST_PATTERN.test(body.host)) {
    return null;
  }
  if (body.action !== "save") {
    return body.note === undefined
      ? { action: body.action, host: body.host }
      : null;
  }
  if (typeof body.note !== "string") return null;
  const note = sanitizeNote(body.note);
  return note === null ? null : { action: "save", host: body.host, note };
}

async function readBounded(request: Request): Promise<string | null> {
  const declared = Number(request.headers.get("content-length"));
  if (Number.isFinite(declared) && declared > MAX_BODY_BYTES) return null;
  const bytes = await readStream(request.body, MAX_BODY_BYTES);
  if (bytes === null) return null;
  try {
    return new TextDecoder("utf-8", { fatal: true }).decode(bytes);
  } catch {
    return "";
  }
}

async function readStream(
  body: ReadableStream<Uint8Array> | null,
  maxBytes: number,
): Promise<Uint8Array | null> {
  if (!body) return new Uint8Array();
  const reader = body.getReader();
  const chunks: Uint8Array[] = [];
  let length = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    length += value.byteLength;
    if (length > maxBytes) {
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
  return bytes;
}

async function authenticatedUserId(
  request: Request,
  deps: Deps,
): Promise<string | null> {
  const authorization = request.headers.get("authorization");
  const supabaseUrl = deps.env("SUPABASE_URL")?.trim();
  const anonKey = deps.env("SUPABASE_ANON_KEY")?.trim();
  if (!authorization?.startsWith("Bearer ") || !supabaseUrl || !anonKey) {
    return null;
  }
  try {
    const response = await deps.fetch(`${supabaseUrl}/auth/v1/user`, {
      headers: { authorization, apikey: anonKey },
      redirect: "error",
      signal: AbortSignal.timeout(AUTH_TIMEOUT_MS),
    });
    if (!response.ok) return null;
    const user = await response.json();
    return typeof user?.id === "string" && UUID_PATTERN.test(user.id)
      ? user.id
      : null;
  } catch {
    return null;
  }
}

async function consumeQuota(
  userId: string,
  deps: Deps,
): Promise<"ok" | "exceeded" | "unavailable"> {
  const supabaseUrl = deps.env("SUPABASE_URL")?.trim();
  const serviceKey = deps.env("SUPABASE_SERVICE_ROLE_KEY")?.trim();
  if (!supabaseUrl || !serviceKey) return "unavailable";
  try {
    const response = await deps.fetch(
      `${supabaseUrl}/rest/v1/rpc/qr_site_note_consume_quota`,
      {
        method: "POST",
        redirect: "error",
        headers: {
          apikey: serviceKey,
          authorization: `Bearer ${serviceKey}`,
          "content-type": "application/json",
        },
        body: JSON.stringify({ p_user_id: userId, p_daily_limit: DAILY_LIMIT }),
        signal: AbortSignal.timeout(QUOTA_TIMEOUT_MS),
      },
    );
    if (!response.ok) return "unavailable";
    return await response.json() === true ? "ok" : "exceeded";
  } catch {
    return "unavailable";
  }
}

type MemoryConfig = { baseUrl: string; apiKey: string };

function memoryConfig(env: Env): MemoryConfig | null {
  const apiKey = env("ATOMICMEMORY_API_KEY")?.trim() ?? "";
  const rawUrl = env("ATOMICMEMORY_API_URL")?.trim() || DEFAULT_API_URL;
  if (!apiKey || apiKey.startsWith("replace-with-")) return null;
  let url: URL;
  try {
    url = new URL(rawUrl);
  } catch {
    return null;
  }
  const loopback = url.hostname === "127.0.0.1" || url.hostname === "localhost";
  if (url.protocol !== "https:" && !(url.protocol === "http:" && loopback)) {
    return null;
  }
  if (url.username || url.password || url.search || url.hash) return null;
  return { baseUrl: url.origin + url.pathname.replace(/\/+$/, ""), apiKey };
}

class MemoryClient {
  constructor(
    private readonly config: MemoryConfig,
    private readonly subject: string,
    private readonly fetcher: typeof fetch,
  ) {}

  /**
   * The note for this host, or null when the exact lookup returns 404. A row
   * that does not match what this function writes is treated as a provider
   * failure, never as "no note".
   */
  async find(externalId: string, host: string): Promise<StoredNote | null> {
    const memory = await this.call(
      "GET",
      `/v1/memories/by-external-id/${encodeURIComponent(externalId)}?user_id=${
        encodeURIComponent(this.subject)
      }`,
      undefined,
      { notFoundAsNull: true },
    );
    if (memory === null) return null;
    const prefix = notePrefix(host);
    const metadata = memory.metadata;
    if (
      typeof memory.id !== "string" ||
      !UUID_PATTERN.test(memory.id) ||
      (memory.user_id !== undefined && memory.user_id !== this.subject) ||
      typeof memory.content !== "string" ||
      !memory.content.startsWith(prefix) ||
      (memory.source_site !== undefined &&
        memory.source_site !== SOURCE_SITE) ||
      (memory.deleted_at !== undefined && memory.deleted_at !== null) ||
      !isRecord(metadata) ||
      metadata.externalId !== externalId ||
      metadata.qhawix_kind !== NOTE_KIND ||
      metadata.qhawix_host !== host
    ) {
      throw new ProviderError("provider_unavailable");
    }
    return {
      id: memory.id,
      text: memory.content.slice(prefix.length).slice(0, MAX_NOTE_CHARS * 2),
      savedAt: typeof memory.created_at === "string" ? memory.created_at : null,
    };
  }

  /** Verbatim write; returns null unless the provider confirms one stored id. */
  async save(
    externalId: string,
    host: string,
    note: string,
  ): Promise<StoredNote | null> {
    const body = await this.call("POST", "/v1/memories/ingest/quick", {
      user_id: this.subject,
      conversation: noteContent(host, note),
      source_site: SOURCE_SITE,
      skip_extraction: true,
      content_class: "redacted",
      metadata: {
        externalId,
        qhawix_kind: NOTE_KIND,
        qhawix_schema: SCHEMA_VERSION,
        qhawix_host: host,
      },
    });
    const stored = Array.isArray(body?.stored_memory_ids)
      ? body.stored_memory_ids
      : [];
    const updated = Array.isArray(body?.updated_memory_ids)
      ? body.updated_memory_ids
      : [];
    const ids = [
      ...new Set(
        [...stored, ...updated].filter((id): id is string =>
          typeof id === "string" && UUID_PATTERN.test(id)
        ),
      ),
    ];
    if (ids.length !== 1) return null;
    return { id: ids[0], text: note, savedAt: null };
  }

  /**
   * True only when the provider answers 200 with the documented
   * `{ "success": true }` body. A 404, an error or any other body is false.
   */
  async deleteById(id: string): Promise<boolean> {
    if (!UUID_PATTERN.test(id)) return false;
    try {
      const body = await this.call(
        "DELETE",
        `/v1/memories/${encodeURIComponent(id)}?user_id=${
          encodeURIComponent(this.subject)
        }`,
      );
      return body?.success === true;
    } catch {
      return false;
    }
  }

  private async call(
    method: "GET" | "POST" | "DELETE",
    path: string,
    payload?: unknown,
    options: { notFoundAsNull?: boolean } = {},
  ): Promise<ProviderBody> {
    let response: Response;
    try {
      response = await this.fetcher(`${this.config.baseUrl}${path}`, {
        method,
        redirect: "error",
        headers: {
          authorization: `Bearer ${this.config.apiKey}`,
          accept: "application/json",
          ...(payload === undefined
            ? {}
            : { "content-type": "application/json" }),
        },
        body: payload === undefined ? undefined : JSON.stringify(payload),
        signal: AbortSignal.timeout(PROVIDER_TIMEOUT_MS),
      });
    } catch (error) {
      const name = error instanceof Error ? error.name : undefined;
      throw new ProviderError(
        name === "TimeoutError" || name === "AbortError"
          ? "provider_timeout"
          : "provider_unavailable",
      );
    }
    const bytes = await readStream(response.body, MAX_PROVIDER_RESPONSE_BYTES)
      .catch(() => null);
    // Documented 404 of the exact lookup: the note does not exist.
    if (response.status === 404 && options.notFoundAsNull) return null;
    if (!response.ok || bytes === null) {
      throw new ProviderError("provider_unavailable");
    }
    try {
      const decoded: unknown = JSON.parse(
        new TextDecoder("utf-8", { fatal: true }).decode(bytes),
      );
      if (!isRecord(decoded)) {
        throw new Error("invalid_shape");
      }
      return decoded;
    } catch {
      throw new ProviderError("provider_unavailable");
    }
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

// Provider JSON is untrusted; every field is checked where it is read.
type ProviderBody = Record<string, unknown> | null;
