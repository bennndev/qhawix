// TEST/DEMO FIXTURE ONLY. Never imported by index.ts and never deployed as a
// feature. It imitates, in memory, the small parts of Supabase Auth, the
// quota RPC and the Atomic Memory HTTP API (ingest/quick,
// GET /v1/memories/by-external-id/{externalId}, DELETE /v1/memories/{id})
// that qr-site-notes uses. It is not Atomic Memory. It has no semantic search
// on purpose: the function must never depend on a ranked result window.
//
// When several rows share one externalId the documented contract does not say
// which one the lookup returns; this fixture returns the OLDEST, the harder
// case for corrections.

export type FixtureUser = { id: string; email: string; password: string };

type FixtureMemory = {
  id: string;
  user_id: string;
  content: string;
  source_site: string;
  metadata: Record<string, unknown>;
  created_at: string;
};

export type MemoryMode = "ok" | "down" | "timeout" | "no_ids";

export class FakeServices {
  readonly memories: FixtureMemory[] = [];
  readonly memoryRequests: { path: string; body: unknown }[] = [];
  readonly quotaCounts = new Map<string, number>();
  memoryMode: MemoryMode = "ok";
  failDeletes = false;
  upsert = false;
  foreignSubject = false;
  /** Answer DELETE with 200 but without the documented `success: true`. */
  unconfirmedDeletes = false;
  /** Memory ids whose DELETE fails with an outage. */
  readonly failDeleteIds = new Set<string>();
  private sequence = 0;
  private readonly users: FixtureUser[];
  private readonly tokens = new Map<string, string>();

  constructor(
    users: FixtureUser[],
    readonly memoryApiKey = "fixture-memory-key",
  ) {
    this.users = users;
  }

  /** Bearer token the fixture accepts for [user]. */
  tokenFor(user: FixtureUser): string {
    const cached = this.tokens.get(user.id);
    if (cached) return cached;
    const payload = btoa(JSON.stringify({
      sub: user.id,
      email: user.email,
      aud: "authenticated",
      role: "authenticated",
      exp: Math.floor(Date.now() / 1000) + 3600,
    })).replaceAll("=", "").replaceAll("+", "-").replaceAll("/", "_");
    const token = `eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.${payload}.fixture`;
    this.tokens.set(user.id, token);
    return token;
  }

  readonly fetch = async (
    input: string | URL | Request,
    init?: RequestInit,
  ): Promise<Response> => {
    const request = new Request(input, init);
    const url = new URL(request.url);
    const path = url.pathname;
    if (path === "/auth/v1/user") return this.authUser(request);
    if (path === "/auth/v1/token") return this.signIn(request);
    if (path === "/rest/v1/rpc/qr_site_note_consume_quota") {
      return this.consumeQuota(request);
    }
    if (path.startsWith("/v1/memories")) return await this.memory(request, url);
    return reply({ error: "not_found" }, 404);
  };

  private userFromToken(request: Request): FixtureUser | undefined {
    const header = request.headers.get("authorization") ?? "";
    return this.users.find((user) =>
      header === `Bearer ${this.tokenFor(user)}`
    );
  }

  private authUser(request: Request): Response {
    const user = this.userFromToken(request);
    if (!user) return reply({ msg: "invalid JWT" }, 401);
    return reply(this.userJson(user));
  }

  private async signIn(request: Request): Promise<Response> {
    const body = await request.json().catch(() => ({}));
    const user = this.users.find((candidate) =>
      candidate.email === body.email && candidate.password === body.password
    );
    if (!user) {
      return reply({
        error: "invalid_grant",
        error_description: "Invalid login credentials",
      }, 400);
    }
    const now = Math.floor(Date.now() / 1000);
    return reply({
      access_token: this.tokenFor(user),
      token_type: "bearer",
      expires_in: 3600,
      expires_at: now + 3600,
      refresh_token: `fixture-refresh-${user.id}`,
      user: this.userJson(user),
    });
  }

  private userJson(user: FixtureUser) {
    return {
      id: user.id,
      aud: "authenticated",
      role: "authenticated",
      email: user.email,
      app_metadata: { provider: "email" },
      user_metadata: {},
      created_at: "2026-10-20T00:00:00Z",
    };
  }

  private async consumeQuota(request: Request): Promise<Response> {
    const body = await request.json();
    const used = (this.quotaCounts.get(body.p_user_id) ?? 0) + 1;
    if (used > body.p_daily_limit) return reply(false);
    this.quotaCounts.set(body.p_user_id, used);
    return reply(true);
  }

  private async memory(request: Request, url: URL): Promise<Response> {
    if (
      request.headers.get("authorization") !== `Bearer ${this.memoryApiKey}`
    ) {
      return reply({ error: "unauthorized" }, 401);
    }
    const body = request.method === "POST" ? await request.json() : null;
    this.memoryRequests.push({ path: url.pathname + url.search, body });
    if (this.memoryMode === "down") {
      return reply({ error: "fixture outage" }, 503);
    }
    if (this.memoryMode === "timeout") {
      await new Promise((_, reject) =>
        request.signal.addEventListener(
          "abort",
          () =>
            reject(
              request.signal.reason ??
                new DOMException("timeout", "TimeoutError"),
            ),
        )
      );
    }
    const byExternalId = /^\/v1\/memories\/by-external-id\/([^/]+)$/.exec(
      url.pathname,
    );
    if (byExternalId && request.method === "GET") {
      const externalId = decodeURIComponent(byExternalId[1]);
      const userId = url.searchParams.get("user_id");
      const memory = this.memories.find((candidate) =>
        candidate.user_id === userId &&
        candidate.metadata.externalId === externalId
      );
      if (!memory) return reply({ error: "Memory not found" }, 404);
      const { user_id: _user, ...row } = memory;
      return reply({
        ...row,
        ...(this.foreignSubject ? { user_id: "another-user" } : {}),
        deleted_at: null,
        status: "active",
      });
    }
    if (url.pathname === "/v1/memories/ingest/quick") {
      if (this.memoryMode === "no_ids") {
        return reply({
          episode_id: "e",
          stored_memory_ids: [],
          updated_memory_ids: [],
        });
      }
      const previous = this.upsert
        ? this.memories.find((row) =>
          row.user_id === body.user_id &&
          row.metadata.externalId === body.metadata?.externalId
        )
        : undefined;
      if (previous) {
        previous.content = body.conversation;
        previous.metadata = body.metadata;
        return reply({
          episode_id: `fixture-${previous.id}`,
          facts_extracted: 0,
          memories_stored: 0,
          memories_updated: 1,
          memories_deleted: 0,
          memories_skipped: 0,
          stored_memory_ids: [],
          updated_memory_ids: [previous.id],
          links_created: 0,
          composites_created: 0,
        });
      }
      const id = crypto.randomUUID();
      this.memories.push({
        id,
        user_id: body.user_id,
        content: body.conversation,
        source_site: body.source_site,
        metadata: body.metadata ?? {},
        created_at: new Date(Date.UTC(2026, 9, 20, 12, 0, this.sequence++))
          .toISOString(),
      });
      return reply({
        episode_id: `fixture-${id}`,
        facts_extracted: 0,
        memories_stored: 1,
        memories_updated: 0,
        memories_deleted: 0,
        memories_skipped: 0,
        stored_memory_ids: [id],
        updated_memory_ids: [],
        links_created: 0,
        composites_created: 0,
      });
    }
    const match = /^\/v1\/memories\/([^/]+)$/.exec(url.pathname);
    if (match && request.method === "DELETE") {
      if (this.failDeletes) return reply({ error: "fixture outage" }, 503);
      if (this.unconfirmedDeletes) return reply({ success: false });
      if (this.failDeleteIds.has(decodeURIComponent(match[1]))) {
        return reply({ error: "fixture outage" }, 503);
      }
      const userId = url.searchParams.get("user_id");
      const index = this.memories.findIndex((memory) =>
        memory.id === decodeURIComponent(match[1]) && memory.user_id === userId
      );
      if (index < 0) return reply({ error: "Memory not found" }, 404);
      this.memories.splice(index, 1);
      return reply({ success: true });
    }
    return reply({ error: "not_found" }, 404);
  }
}

function reply(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}
