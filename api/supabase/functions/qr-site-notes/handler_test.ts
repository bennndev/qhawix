import {
  createHandler,
  DAILY_LIMIT,
  externalIdFor,
  sanitizeNote,
  subjectFor,
} from "./handler.ts";
import { FakeServices, type FixtureUser } from "./test_fixtures.ts";

const ana: FixtureUser = {
  id: "11111111-1111-4111-8111-111111111111",
  email: "ana@fixture.test",
  password: "fixture-password",
};
const beto: FixtureUser = {
  id: "22222222-2222-4222-8222-222222222222",
  email: "beto@fixture.test",
  password: "fixture-password",
};

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

function setup(env: Record<string, string | undefined> = {}) {
  const services = new FakeServices([ana, beto]);
  const values: Record<string, string | undefined> = {
    SUPABASE_URL: "https://fixture.supabase.test",
    SUPABASE_ANON_KEY: "fixture-anon",
    SUPABASE_SERVICE_ROLE_KEY: "fixture-service-role",
    ATOMICMEMORY_API_URL: "https://memory.fixture.test",
    ATOMICMEMORY_API_KEY: services.memoryApiKey,
    ...env,
  };
  const handler = createHandler({
    env: (name) => values[name],
    fetch: services.fetch,
  });
  const call = async (
    user: FixtureUser | null,
    body: Record<string, unknown>,
  ) => {
    const response = await handler(
      new Request("https://fixture.supabase.test/functions/v1/qr-site-notes", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          ...(user
            ? { authorization: `Bearer ${services.tokenFor(user)}` }
            : {}),
        },
        body: JSON.stringify({ schemaVersion: 1, ...body }),
      }),
    );
    return { status: response.status, body: await response.json() };
  };
  return { services, call };
}

Deno.test("saves a note and recalls it for the same exact host", async () => {
  const { services, call } = setup();
  const saved = await call(ana, {
    action: "save",
    host: "pagos.mitienda.pe",
    note: "Lo verifiqué en la app oficial de la tienda.",
  });
  assert(
    saved.status === 200 && saved.body.status === "saved",
    JSON.stringify(saved),
  );
  assert(
    saved.body.note.text === "Lo verifiqué en la app oficial de la tienda.",
    "text",
  );

  const ingest = services.memoryRequests.find((r) =>
    r.path === "/v1/memories/ingest/quick"
  );
  const payload = ingest?.body as Record<string, unknown>;
  assert(
    payload.user_id === subjectFor(ana.id),
    "subject comes from the session",
  );
  assert(payload.skip_extraction === true, "verbatim write");
  assert(payload.content_class === "redacted", "content class");
  const metadata = payload.metadata as Record<string, unknown>;
  assert(
    metadata.externalId === await externalIdFor("pagos.mitienda.pe"),
    "stable per-host external id",
  );
  assert(
    !JSON.stringify(services.memoryRequests).includes("://pagos"),
    "only the hostname leaves, never a URL",
  );
  assert(
    !("session_id" in payload) && !("workspace_id" in payload),
    "user-only scope",
  );

  const found = await call(ana, { action: "get", host: "pagos.mitienda.pe" });
  assert(found.body.status === "found", JSON.stringify(found));
  assert(
    found.body.note.text === "Lo verifiqué en la app oficial de la tienda.",
    "recall",
  );

  const other = await call(ana, {
    action: "get",
    host: "pagos.mitienda.pe.evil.com",
  });
  assert(
    other.body.status === "none",
    "a look-alike host never receives the note",
  );
});

Deno.test("never exposes one account's note to another account", async () => {
  const { call } = setup();
  await call(ana, { action: "save", host: "bcp.com.pe", note: "Mi banco." });
  const forBeto = await call(beto, { action: "get", host: "bcp.com.pe" });
  assert(
    forBeto.status === 200 && forBeto.body.status === "none",
    JSON.stringify(forBeto),
  );
  const betoDelete = await call(beto, { action: "delete", host: "bcp.com.pe" });
  assert(betoDelete.body.removed === 0, "cannot delete someone else's note");
  const forAna = await call(ana, { action: "get", host: "bcp.com.pe" });
  assert(forAna.body.status === "found", "owner still has the note");
});

Deno.test("ignores an identity supplied in the body", async () => {
  const { call } = setup();
  const response = await call(ana, {
    action: "get",
    host: "bcp.com.pe",
    user_id: beto.id,
  });
  assert(
    response.status === 400 && response.body.code === "invalid_input",
    "extra keys rejected",
  );
});

Deno.test("correcting replaces the previous note and delete removes it", async () => {
  const { services, call } = setup();
  await call(ana, {
    action: "save",
    host: "mitienda.pe",
    note: "Primera versión.",
  });
  const corrected = await call(ana, {
    action: "save",
    host: "mitienda.pe",
    note: "Versión corregida.",
  });
  assert(
    corrected.body.status === "saved" &&
      corrected.body.note.text === "Versión corregida.",
    JSON.stringify(corrected),
  );
  assert(services.memories.length === 1, "only the corrected note remains");
  assert(
    services.memories[0].id === corrected.body.note.id,
    "the exact lookup resolves to the corrected row",
  );
  const found = await call(ana, { action: "get", host: "mitienda.pe" });
  assert(found.body.note.text === "Versión corregida.", "latest text");

  const deleted = await call(ana, { action: "delete", host: "mitienda.pe" });
  assert(
    deleted.body.status === "deleted" && deleted.body.removed === 1,
    JSON.stringify(deleted),
  );
  const after = await call(ana, { action: "get", host: "mitienda.pe" });
  assert(after.body.status === "none", "nothing left after delete");
});

Deno.test("a correction that cannot replace the old row is rolled back", async () => {
  const { services, call } = setup();
  const first = await call(ana, {
    action: "save",
    host: "mitienda.pe",
    note: "Primera.",
  });
  services.failDeleteIds.add(first.body.note.id);
  const corrected = await call(ana, {
    action: "save",
    host: "mitienda.pe",
    note: "Segunda.",
  });
  assert(
    corrected.status === 502 &&
      corrected.body.code === "correction_not_applied",
    JSON.stringify(corrected),
  );
  assert(services.memories.length === 1, "still exactly one note");
  const found = await call(ana, { action: "get", host: "mitienda.pe" });
  assert(found.body.note.text === "Primera.", "the confirmed note is kept");

  services.failDeletes = true;
  const deleted = await call(ana, { action: "delete", host: "mitienda.pe" });
  assert(
    deleted.status === 502,
    "delete is not reported as done when it failed",
  );
});

Deno.test("recall stays exact after notes for 25 other sites", async () => {
  const { services, call } = setup();
  await call(ana, { action: "save", host: "primera.pe", note: "La primera." });
  for (let index = 0; index < 25; index++) {
    const saved = await call(ana, {
      action: "save",
      host: `sitio${index}.example.org`,
      note: `Nota ${index}.`,
    });
    assert(saved.body.status === "saved", JSON.stringify(saved));
  }
  const found = await call(ana, { action: "get", host: "primera.pe" });
  assert(
    found.body.status === "found" && found.body.note.text === "La primera.",
    JSON.stringify(found),
  );
  const last = await call(ana, { action: "get", host: "sitio24.example.org" });
  assert(last.body.note.text === "Nota 24.", JSON.stringify(last));
  assert(
    services.memoryRequests.every((r) => !r.path.includes("/search")),
    "no ranked search is used",
  );
});

Deno.test("a row that does not match the host is a failure, not a note", async () => {
  const { services, call } = setup();
  await call(ana, { action: "save", host: "mitienda.pe", note: "Mía." });
  services.memories[0].metadata.qhawix_host = "otra.pe";
  const found = await call(ana, { action: "get", host: "mitienda.pe" });
  assert(
    found.status === 502 && found.body.code === "provider_unavailable",
    JSON.stringify(found),
  );
});

Deno.test("a delete is confirmed only by the documented success body", async () => {
  const { services, call } = setup();
  await call(ana, { action: "save", host: "mitienda.pe", note: "Primera." });
  services.unconfirmedDeletes = true;
  const deleted = await call(ana, { action: "delete", host: "mitienda.pe" });
  assert(deleted.status === 502, JSON.stringify(deleted));
  services.unconfirmedDeletes = false;
  const retried = await call(ana, { action: "delete", host: "mitienda.pe" });
  assert(
    retried.body.status === "deleted" && retried.body.removed === 1,
    JSON.stringify(retried),
  );
});

Deno.test("disabled when Atomic Memory is not configured", async () => {
  const { services, call } = setup({ ATOMICMEMORY_API_KEY: undefined });
  const response = await call(ana, { action: "get", host: "bcp.com.pe" });
  assert(
    response.status === 503 && response.body.code === "not_configured",
    JSON.stringify(response),
  );
  assert(services.memoryRequests.length === 0, "no provider call");
});

Deno.test("rejects a non-loopback plain-HTTP provider URL", async () => {
  const { call } = setup({
    ATOMICMEMORY_API_URL: "http://memory.fixture.test",
  });
  const response = await call(ana, { action: "get", host: "bcp.com.pe" });
  assert(response.body.code === "not_configured", JSON.stringify(response));
});

Deno.test("requires a valid Supabase session", async () => {
  const { services, call } = setup();
  const response = await call(null, { action: "get", host: "bcp.com.pe" });
  assert(response.status === 401, JSON.stringify(response));
  assert(services.memoryRequests.length === 0, "no provider call");
});

Deno.test("provider outage is reported as not saved", async () => {
  const { services, call } = setup();
  services.memoryMode = "down";
  const response = await call(ana, {
    action: "save",
    host: "bcp.com.pe",
    note: "Mi banco.",
  });
  assert(
    response.status === 502 && response.body.code === "provider_unavailable",
    JSON.stringify(response),
  );
  assert(services.memories.length === 0, "nothing stored");
});

Deno.test("an ingest without a stored id is never reported as saved", async () => {
  const { services, call } = setup();
  services.memoryMode = "no_ids";
  const response = await call(ana, {
    action: "save",
    host: "bcp.com.pe",
    note: "Mi banco.",
  });
  assert(
    response.status === 502 && response.body.code === "save_unconfirmed",
    JSON.stringify(response),
  );
});

Deno.test("provider timeout is bounded", async () => {
  const { services, call } = setup();
  services.memoryMode = "timeout";
  const started = Date.now();
  const response = await call(ana, { action: "get", host: "bcp.com.pe" });
  assert(
    response.status === 504 && response.body.code === "provider_timeout",
    JSON.stringify(response),
  );
  assert(Date.now() - started < 6_000, "returns within the timeout budget");
});

Deno.test("applies the durable daily quota", async () => {
  const { services, call } = setup();
  services.quotaCounts.set(ana.id, DAILY_LIMIT);
  const response = await call(ana, { action: "get", host: "bcp.com.pe" });
  assert(
    response.status === 429 && response.body.code === "rate_limited",
    JSON.stringify(response),
  );
});

Deno.test("validates host and note", async () => {
  const { call } = setup();
  for (
    const host of [
      "192.168.0.1",
      "localhost",
      "BCP.com.pe",
      "a..b",
      "x".repeat(300),
    ]
  ) {
    const response = await call(ana, { action: "get", host });
    assert(response.status === 400, `host ${host}`);
  }
  const tooLong = await call(ana, {
    action: "save",
    host: "bcp.com.pe",
    note: "a".repeat(281),
  });
  assert(tooLong.status === 400, "note length");
  const empty = await call(ana, {
    action: "save",
    host: "bcp.com.pe",
    note: "   ",
  });
  assert(empty.status === 400, "empty note");
});

Deno.test("redacts codes, long numbers and e-mails before storing", () => {
  const note = sanitizeNote(
    "Código 123456, cuenta 1234 5678 9012 3456, escribe a ana@correo.pe",
  );
  assert(
    note ===
      "Código [codigo oculto], cuenta [numero oculto], escribe a [correo oculto]",
    String(note),
  );
  assert(
    sanitizeNote("Pagué 1500 soles") === "Pagué 1500 soles",
    "amounts are kept",
  );
});

Deno.test("correcting accepts the documented updated_memory_ids acknowledgement", async () => {
  const { services, call } = setup();
  services.upsert = true;
  const first = await call(ana, {
    action: "save",
    host: "tienda.pe",
    note: "Primera nota.",
  });
  const correction = await call(ana, {
    action: "save",
    host: "tienda.pe",
    note: "Nota corregida.",
  });
  assert(
    correction.status === 200 && correction.body.status === "saved",
    JSON.stringify(correction),
  );
  assert(
    correction.body.note.id === first.body.note.id,
    "updates the same note",
  );
  assert(
    correction.body.note.text === "Nota corregida.",
    "returns the correction",
  );
  assert(services.memories.length === 1, "does not duplicate an upserted note");
});

Deno.test("rejects an explicitly foreign subject returned by the provider", async () => {
  const { services, call } = setup();
  await call(ana, { action: "save", host: "tienda.pe", note: "Mi nota." });
  services.foreignSubject = true;
  const read = await call(ana, { action: "get", host: "tienda.pe" });
  assert(
    read.status === 502 && read.body.note === undefined,
    JSON.stringify(read),
  );
  const deletion = await call(ana, { action: "delete", host: "tienda.pe" });
  assert(
    deletion.status === 502 && services.memories.length === 1,
    "does not delete a foreign row",
  );
});
