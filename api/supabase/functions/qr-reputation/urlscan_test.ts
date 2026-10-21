import { scanUrl, UrlscanError } from "./urlscan.ts";

const UUID = "12345678-1234-4234-8234-123456789abc";
const TARGET = "https://example.com/";
const START = Date.parse("2026-10-18T12:00:00Z");

function assert(value: unknown, message = "Assertion failed"): asserts value {
  if (!value) throw new Error(message);
}

function result(overrides: Record<string, unknown> = {}) {
  return {
    task: {
      uuid: UUID,
      url: TARGET,
      time: new Date(START).toISOString(),
      visibility: "private",
    },
    page: { url: TARGET, status: "200" },
    verdicts: { urlscan: { malicious: false, score: 0, categories: [] } },
    ...overrides,
  };
}

function harness(responses: Response[]) {
  let now = START;
  const calls: { url: string; init?: RequestInit }[] = [];
  return {
    calls,
    runtime: {
      now: () => now,
      sleep: (ms: number, _signal?: AbortSignal) => {
        now += ms;
        return Promise.resolve();
      },
      fetch: ((input: string | URL | Request, init?: RequestInit) => {
        calls.push({ url: String(input), init });
        const response = responses.shift();
        if (!response) throw new Error("Unexpected provider request");
        return Promise.resolve(response);
      }) as typeof fetch,
    },
  };
}

function submission() {
  // Returned URLs are untrusted: the client must construct its own fixed-host result URL.
  return Response.json({
    uuid: UUID,
    visibility: "private",
    api: "https://attacker.invalid/",
  });
}

async function expectError(action: () => Promise<unknown>, code: string) {
  try {
    await action();
  } catch (error) {
    assert(
      error instanceof UrlscanError && error.code === code,
      `Expected ${code}`,
    );
    return;
  }
  throw new Error(`Expected ${code}, received a successful result`);
}

Deno.test("private scan waits for a completed exact-URL verdict without visiting the destination", async () => {
  const h = harness([
    submission(),
    new Response(null, { status: 404 }),
    Response.json(result()),
  ]);
  const verdict = await scanUrl(TARGET, "test-key", h.runtime);
  assert(verdict.verdict === "no_match");
  assert(verdict.categories.length === 0 && verdict.expiresAt === null);
  assert(verdict.checkedAt === new Date(START).toISOString());
  assert(h.calls.length === 3);
  assert(
    h.calls.every((call) => new URL(call.url).origin === "https://urlscan.io"),
  );
  assert(h.calls[1].url === `https://urlscan.io/api/v1/result/${UUID}/`);
  assert(
    h.calls.every((call) =>
      new Headers(call.init?.headers).get("api-key") === "test-key"
    ),
  );
  assert(h.calls.every((call) => call.init?.redirect === "error"));
  const body = JSON.parse(String(h.calls[0].init?.body));
  assert(body.url === TARGET && body.visibility === "private");
  assert(!("overrideSafety" in body));
});

Deno.test("malicious verdict is a match with bounded local validity and a normalized category", async () => {
  const h = harness([
    submission(),
    Response.json(result({
      verdicts: {
        urlscan: { malicious: true, score: 100, categories: ["phishing"] },
      },
    })),
  ]);
  const verdict = await scanUrl(TARGET, "test-key", h.runtime);
  assert(verdict.verdict === "match");
  assert(verdict.categories.join(",") === "URLSCAN_PHISHING");
  assert(verdict.expiresAt === new Date(START + 300_000).toISOString());
});

Deno.test("missing verdict never becomes a clean result", async () => {
  const h = harness([submission(), Response.json(result({ verdicts: {} }))]);
  await expectError(
    () => scanUrl(TARGET, "test-key", h.runtime),
    "invalid_provider_response",
  );
});

Deno.test("a URL mismatch cannot grant clearance to the requested URL", async () => {
  const h = harness([
    submission(),
    Response.json(result({
      task: {
        uuid: UUID,
        url: "https://other.example.org/",
        time: new Date(START).toISOString(),
        visibility: "private",
      },
    })),
  ]);
  await expectError(
    () => scanUrl(TARGET, "test-key", h.runtime),
    "invalid_provider_response",
  );
});

Deno.test("inaccessible page is unverifiable even with a non-malicious verdict", async () => {
  const h = harness([
    submission(),
    Response.json(result({ page: { url: TARGET, status: "403" } })),
  ]);
  await expectError(
    () => scanUrl(TARGET, "test-key", h.runtime),
    "scan_incomplete",
  );
});

Deno.test("positive score without a malicious verdict is inconclusive", async () => {
  const h = harness([
    submission(),
    Response.json(result({
      verdicts: { urlscan: { malicious: false, score: 30, categories: [] } },
    })),
  ]);
  await expectError(
    () => scanUrl(TARGET, "test-key", h.runtime),
    "scan_inconclusive",
  );
});

Deno.test("rate limits stop the scan without retries or a clean result", async () => {
  const h = harness([
    new Response(null, {
      status: 429,
      headers: { "x-rate-limit-reset-after": "120" },
    }),
  ]);
  await expectError(
    () => scanUrl(TARGET, "test-key", h.runtime),
    "quota_exhausted",
  );
  assert(h.calls.length === 1);
});

Deno.test("denied private scan never falls back to public or unlisted submission", async () => {
  const h = harness([new Response(null, { status: 403 })]);
  await expectError(
    () => scanUrl(TARGET, "test-key", h.runtime),
    "private_scan_unavailable",
  );
  assert(h.calls.length === 1);
});

Deno.test("queued scan times out without treating 404 as no-match", async () => {
  const h = harness([
    submission(),
    ...Array.from({ length: 10 }, () => new Response(null, { status: 404 })),
  ]);
  await expectError(
    () => scanUrl(TARGET, "test-key", h.runtime),
    "provider_timeout",
  );
  assert(h.calls.length <= 9);
});

Deno.test("deleted scan is unverifiable", async () => {
  const h = harness([submission(), new Response(null, { status: 410 })]);
  await expectError(
    () => scanUrl(TARGET, "test-key", h.runtime),
    "scan_deleted",
  );
});

Deno.test("unexpected visibility is rejected", async () => {
  const h = harness([Response.json({ uuid: UUID, visibility: "public" })]);
  await expectError(
    () => scanUrl(TARGET, "test-key", h.runtime),
    "private_scan_unavailable",
  );
});

Deno.test("an expired analysis is never refreshed by the retrieval time", async () => {
  const h = harness([
    submission(),
    Response.json(result({
      task: {
        uuid: UUID,
        url: TARGET,
        time: new Date(START - 120_000).toISOString(),
        visibility: "private",
      },
    })),
  ]);
  await expectError(
    () => scanUrl(TARGET, "test-key", h.runtime),
    "analysis_expired",
  );
});
