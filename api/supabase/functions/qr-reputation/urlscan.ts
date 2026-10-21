import { QR_GATEWAY_POLICY as policy } from "./config.ts";

const ORIGIN = "https://urlscan.io";
const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export class UrlscanError extends Error {
  constructor(
    public readonly code: string,
    public readonly status = 503,
    public readonly retryAfterSeconds?: number,
  ) {
    super(code);
    this.name = "UrlscanError";
  }
}

export type ScanVerdict = {
  verdict: "match" | "no_match";
  checkedAt: string;
  expiresAt: string | null;
  categories: string[];
};

type Runtime = {
  fetch: typeof fetch;
  now: () => number;
  sleep: (ms: number, signal?: AbortSignal) => Promise<void>;
};

function sleep(ms: number, signal?: AbortSignal): Promise<void> {
  return new Promise((resolve, reject) => {
    if (signal?.aborted) {
      reject(new UrlscanError("provider_timeout", 504));
      return;
    }
    const abort = () => {
      clearTimeout(timer);
      reject(new UrlscanError("provider_timeout", 504));
    };
    const timer = setTimeout(() => {
      signal?.removeEventListener("abort", abort);
      resolve();
    }, ms);
    signal?.addEventListener("abort", abort, { once: true });
  });
}

function object(value: unknown): Record<string, unknown> | null {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null;
}

export async function readJsonResponse(
  response: Response,
  maxBytes: number,
): Promise<unknown> {
  const reader = response.body?.getReader();
  if (!reader) throw new UrlscanError("invalid_provider_response");
  const chunks: Uint8Array[] = [];
  let length = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      length += value.byteLength;
      if (length > maxBytes) {
        await reader.cancel();
        throw new UrlscanError("invalid_provider_response");
      }
      chunks.push(value);
    }
    const bytes = new Uint8Array(length);
    let offset = 0;
    for (const chunk of chunks) {
      bytes.set(chunk, offset);
      offset += chunk.byteLength;
    }
    return JSON.parse(new TextDecoder("utf-8", { fatal: true }).decode(bytes));
  } finally {
    reader.releaseLock();
  }
}

function sameUrl(left: unknown, right: string): boolean {
  if (typeof left !== "string") return false;
  try {
    return new URL(left).href === new URL(right).href;
  } catch {
    return false;
  }
}

function isHttpUrl(value: unknown): boolean {
  if (typeof value !== "string") return false;
  try {
    const url = new URL(value);
    return ["http:", "https:"].includes(url.protocol) && url.hostname !== "" &&
      url.username === "" && url.password === "";
  } catch {
    return false;
  }
}

function parseResult(
  body: unknown,
  url: string,
  uuid: string,
  now: number,
): ScanVerdict {
  const root = object(body);
  const task = object(root?.task);
  const page = object(root?.page);
  const verdicts = object(root?.verdicts);
  const verdict = object(verdicts?.urlscan);
  const checkedAt = typeof task?.time === "string"
    ? Date.parse(task.time)
    : NaN;
  if (
    task?.uuid !== uuid || task?.visibility !== "private" ||
    !sameUrl(task?.url, url) ||
    !Number.isFinite(checkedAt) || checkedAt > now ||
    typeof verdict?.malicious !== "boolean" ||
    !Number.isInteger(verdict?.score) || (verdict!.score as number) < -100 ||
    (verdict!.score as number) > 100
  ) {
    throw new UrlscanError("invalid_provider_response");
  }
  const categories = verdict!.categories ?? [];
  if (
    !Array.isArray(categories) ||
    categories.some((value) => typeof value !== "string")
  ) {
    throw new UrlscanError("invalid_provider_response");
  }
  if (verdict!.malicious) {
    if (now - checkedAt >= policy.matchMaxAgeMs) {
      throw new UrlscanError("analysis_expired");
    }
    return {
      verdict: "match",
      checkedAt: new Date(checkedAt).toISOString(),
      // urlscan does not supply a reputation TTL. This is QHAWIX's local validity policy.
      expiresAt: new Date(checkedAt + policy.matchMaxAgeMs).toISOString(),
      categories: [
        categories.some((value) => value.toLowerCase() === "phishing")
          ? "URLSCAN_PHISHING"
          : "URLSCAN_MALICIOUS",
      ],
    };
  }
  if (
    (verdict!.score as number) > 0 || categories.length > 0 ||
    object(verdicts?.overall)?.malicious === true ||
    object(verdicts?.community)?.malicious === true
  ) {
    throw new UrlscanError("scan_inconclusive");
  }
  if (
    !page || !isHttpUrl(page.url) ||
    !/^2\d\d$/.test(String(page.status))
  ) {
    throw new UrlscanError("scan_incomplete");
  }
  if (now - checkedAt >= policy.negativeMaxAgeMs) {
    throw new UrlscanError("analysis_expired");
  }
  return {
    verdict: "no_match",
    checkedAt: new Date(checkedAt).toISOString(),
    expiresAt: null,
    categories: [],
  };
}

export async function scanUrl(
  url: string,
  apiKey: string,
  overrides: Partial<Runtime> = {},
  signal?: AbortSignal,
): Promise<ScanVerdict> {
  const runtime: Runtime = {
    fetch: globalThis.fetch,
    now: Date.now,
    sleep,
    ...overrides,
  };
  const deadline = runtime.now() + policy.maxScanWaitMs;
  async function call(path: string, body?: unknown): Promise<unknown | null> {
    if (signal?.aborted) throw new UrlscanError("provider_timeout", 504);
    const controller = new AbortController();
    const abort = () => controller.abort();
    signal?.addEventListener("abort", abort, { once: true });
    const timeout = setTimeout(
      abort,
      Math.min(
        policy.providerRequestTimeoutMs,
        Math.max(1, deadline - runtime.now()),
      ),
    );
    try {
      const response = await runtime.fetch(`${ORIGIN}${path}`, {
        method: body === undefined ? "GET" : "POST",
        redirect: "error",
        signal: controller.signal,
        headers: {
          "api-key": apiKey,
          accept: "application/json",
          "content-type": "application/json",
          "user-agent": "QHAWIX-QR-Shield/2",
        },
        ...(body === undefined ? {} : { body: JSON.stringify(body) }),
      });
      if (!response.ok) {
        await response.body?.cancel();
        if (response.status === 404 && body === undefined) return null;
        if (response.status === 410) throw new UrlscanError("scan_deleted");
        if (response.status === 429) {
          const retry = Number(
            response.headers.get("x-rate-limit-reset-after"),
          );
          throw new UrlscanError(
            "quota_exhausted",
            429,
            Number.isFinite(retry) && retry > 0
              ? Math.min(86_400, Math.ceil(retry))
              : 60,
          );
        }
        if (response.status === 401) {
          throw new UrlscanError("provider_auth_failed");
        }
        if (response.status === 403 && body !== undefined) {
          throw new UrlscanError("private_scan_unavailable");
        }
        throw new UrlscanError("provider_unavailable");
      }
      return await readJsonResponse(response, policy.maxProviderResponseBytes);
    } catch (error) {
      if (error instanceof UrlscanError) throw error;
      if (controller.signal.aborted) {
        throw new UrlscanError("provider_timeout", 504);
      }
      if (
        error instanceof SyntaxError ||
        error instanceof TypeError && error.message.includes("decode")
      ) {
        throw new UrlscanError("invalid_provider_response");
      }
      throw new UrlscanError("provider_unavailable");
    } finally {
      clearTimeout(timeout);
      signal?.removeEventListener("abort", abort);
    }
  }

  // Explicit private visibility; an unavailable private quota must never trigger a public retry.
  const submitted = object(
    await call("/api/v1/scan/", { url, visibility: "private" }),
  );
  if (submitted?.visibility !== "private") {
    throw new UrlscanError("private_scan_unavailable");
  }
  if (
    typeof submitted?.uuid !== "string" || !UUID_PATTERN.test(submitted.uuid)
  ) {
    throw new UrlscanError("invalid_provider_response");
  }
  const uuid = submitted.uuid;
  await runtime.sleep(policy.initialPollDelayMs, signal);
  while (runtime.now() < deadline) {
    // Never follow a result/api URL supplied in provider JSON.
    const body = await call(`/api/v1/result/${uuid}/`);
    if (body !== null) return parseResult(body, url, uuid, runtime.now());
    if (runtime.now() + policy.pollIntervalMs >= deadline) break;
    await runtime.sleep(policy.pollIntervalMs, signal);
  }
  throw new UrlscanError("provider_timeout", 504);
}
