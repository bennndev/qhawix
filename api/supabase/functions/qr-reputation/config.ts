// Versioned gateway policy. Provider quotas are also enforced durably in Postgres.
export const QR_GATEWAY_POLICY = Object.freeze({
  version: 2,
  provider: "urlscan_v1",
  consentVersion: "qr-urlscan-private-consent-v2",
  scope: "URLSCAN_VERDICT",
  categories: ["URLSCAN_MALICIOUS", "URLSCAN_PHISHING"] as readonly string[],
  providerRequestTimeoutMs: 10_000,
  maxProviderResponseBytes: 4 * 1024 * 1024,
  initialPollDelayMs: 10_000,
  pollIntervalMs: 5_000,
  maxScanWaitMs: 45_000,
  negativeMaxAgeMs: 60_000,
  matchMaxAgeMs: 300_000,
});
