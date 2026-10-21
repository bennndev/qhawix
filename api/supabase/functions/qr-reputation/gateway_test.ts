import { handleRequest } from "./gateway.ts";
import { UrlscanError } from "./urlscan.ts";

function assert(value: unknown, message = "Assertion failed"): asserts value {
  if (!value) throw new Error(message);
}

function request(overrides = {}) {
  return new Request(
    "https://gateway.example.org/functions/v1/qr-reputation/v1/reputation/check",
    {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        schemaVersion: 2,
        requestId: "test-request-123",
        inputRevision: 4,
        url: "https://example.com/",
        consentVersion: "qr-urlscan-private-consent-v2",
        ...overrides,
      }),
    },
  );
}

async function withBackend(action: () => Promise<void>, quotaAllowed = true) {
  const keys = [
    "URLSCAN_API_KEY",
    "QR_CACHE_HMAC_SECRET",
    "SUPABASE_URL",
    "SUPABASE_SERVICE_ROLE_KEY",
  ];
  const old = keys.map((key) => Deno.env.get(key));
  [
    "test-provider-key",
    "a".repeat(32),
    "https://backend.example.org",
    "test-service-key",
  ]
    .forEach((value, index) => Deno.env.set(keys[index], value));
  const previousFetch = globalThis.fetch;
  globalThis.fetch = ((input: string | URL | Request) => {
    const path = new URL(String(input)).pathname;
    if (path.endsWith("/qr_gateway_get_config")) {
      return Promise.resolve(Response.json({
        schemaVersion: 2,
        provider: "urlscan_v1",
        threatTypes: ["URLSCAN_VERDICT"],
        perMinuteLimit: 5,
        perHourLimit: 50,
        perDayLimit: 50,
        perMonthLimit: 1500,
      }));
    }
    if (path.endsWith("/qr_get_reputation_match")) {
      return Promise.resolve(Response.json(null));
    }
    if (path.endsWith("/qr_consume_reputation_quota")) {
      return Promise.resolve(Response.json({
        allowed: quotaAllowed,
        code: "quota_exhausted",
        retryAfterSeconds: 60,
      }));
    }
    if (path.endsWith("/qr_store_reputation_match")) {
      return Promise.resolve(Response.json(true));
    }
    throw new Error("Unexpected external request");
  }) as typeof fetch;
  try {
    await action();
  } finally {
    globalThis.fetch = previousFetch;
    keys.forEach((key, index) =>
      old[index] === undefined
        ? Deno.env.delete(key)
        : Deno.env.set(key, old[index]!)
    );
  }
}

Deno.test("gateway filters a completed scan into contract v2 without leaking credentials or scan metadata", async () => {
  await withBackend(async () => {
    const response = await handleRequest(request(), (_url, key) => {
      assert(key === "test-provider-key");
      return Promise.resolve({
        verdict: "no_match",
        checkedAt: new Date().toISOString(),
        expiresAt: null,
        categories: [],
      });
    });
    assert(response.status === 200);
    const body = await response.json();
    assert(body.schemaVersion === 2 && body.provider === "urlscan_v1");
    assert(body.inputRevision === 4 && body.requestId === "test-request-123");
    assert(body.checkedCategories.join(",") === "URLSCAN_VERDICT");
    assert(body.coverageComplete === true && body.isFixture === false);
    assert(
      body.reviewExpiresAt === null &&
        body.redirectResolution === "not_performed",
    );
    assert(!JSON.stringify(body).includes("test-provider-key"));
    assert(!("uuid" in body) && !("url" in body));
  });
});

Deno.test("durable exhausted quota prevents a scan request", async () => {
  await withBackend(async () => {
    let called = false;
    const response = await handleRequest(request(), () => {
      called = true;
      throw new Error("No scan allowed");
    });
    assert(response.status === 429 && !called);
    assert((await response.json()).code === "quota_exhausted");
  }, false);
});

Deno.test("provider error remains unverifiable at the gateway", async () => {
  await withBackend(async () => {
    const response = await handleRequest(request(), () => {
      throw new UrlscanError("private_scan_unavailable");
    });
    assert(response.status === 503);
    const body = await response.json();
    assert(
      body.code === "private_scan_unavailable" && !("providerVerdict" in body),
    );
  });
});

Deno.test("old consent and unsafe destinations are rejected before contacting the provider", async () => {
  for (
    const override of [
      { consentVersion: "qr-reputation-consent-v1" },
      { url: "http://127.0.0.1/admin" },
      { url: "https://user:password@example.com/" },
      { url: "https://example.com/#secret" },
    ]
  ) {
    const response = await handleRequest(request(override), () => {
      throw new Error("Must not scan");
    });
    assert(response.status === 400);
  }
});
