# AGENTS.md

Operating manual for AI agents and contributors. Read [`README.md`](README.md) first: it defines the product, the modules and the feasibility tags used here.

**Authority order:** (1) the user's latest instructions; (2) this file and `README.md`; (3) [`docs/QHAWIX-ESPECIFICACION-MAESTRA.md`](docs/QHAWIX-ESPECIFICACION-MAESTRA.md) (the "master spec", Spanish) and the original sources in `docs/`, which remain **evidence**. The master spec's MVP scope (no audio, no accounts, a simulated transfer) is **superseded**: do not use it to remove features. Its rules for rule IDs (`R-01`..`R-18`), test IDs (`T-NN`), the four trust dimensions and the security analysis still apply unless this file says otherwise.

## Project Overview

QHAWIX is an Android security suite that (a) protects a person from digital and AI voice scams and (b) **hides or restricts their digital wallets** when context indicates physical danger, so an aggressor forcing them to open the phone finds nothing to steal. It is built as independent **modules** that work alone and reinforce each other.

Current status: design complete, **implementation not started** (only skeletons in `ui/` and `api/`).

## Product Principles (non-negotiable)

| Principle | Meaning for implementation |
| --- | --- |
| **Nothing is simulated** | Every feature must act on the real world. No fake transfers, fake balances, fake "sent" notices, decoy accounts or fake success screens. Fixtures exist only in tests and in clearly labeled developer builds, never as a user-facing feature. |
| **Honest limits** | If Android or a third party blocks an action, implement the documented alternative and show the limit in the UI. Never claim a capability the platform does not grant. |
| **Feasibility tags** | Every feature is `[Real]`, `[Requisito]`, `[Spike]` or `[Futuro]` (see `README.md`). Do not build a `[Spike]` feature before its spike (S-NN) has a recorded result. |
| **Data minimization** | Message text, audio and location are processed **on device** by default. Anything that leaves the device needs specific consent and a declared purpose. The server stores only: account, trusted contacts and alert events. It never stores audio, message text or the location baseline. |
| **Redact before persisting** | Redact OTP/PIN/CVV, passwords, card/account/document numbers and contacts before storing; quotes and spans are computed on redacted text. |
| **No secrets in the client** | No provider key, service-role key, keystore or password in the APK, repo, landing or public URL. The Supabase anon key is public by design and is **not authentication**. |
| **Nothing opens by itself** | QR/links/intents never execute automatically. External browser only after an explicit tap, re-validating the exact URL first; HTTP/HTTPS only. |
| **Unverifiable is not safe** | A failed or missing reputation or detection check is `unverifiable` with a reason, never "no match" and never "safe". |
| **Suspicion, not certainty** | Show scores and wording such as "suspicious"; never promise to detect all scams, verify identity, or block all fraud. No unmeasured accuracy claims. |
| **Human stays in control** | Models never authorize, hold or release anything alone. Decisions come from deterministic rules plus the person. |
| **Four independent trust dimensions** | `numberProvenance`, `institutionConfirmation`, `requestRisk`, `behavioralDeviation` are never collapsed into one "safe call" indicator (master spec §12.2). |
| **Safe by default under duress** | Hiding wallets is concealment, not deception. Restoring them requires the person's verification (biometric or PIN) and, if configured, a trusted contact's approval. |
| **Config, not constants** | Thresholds, cooldowns, TTLs, quotas and geofence parameters live in versioned configuration, not inside widgets. |

## Modules

Each module is a vertical slice under `ui/lib/features/<folder>/` (layers below). A module never imports another module's `data/` or `view/`; cross-module needs go through `domain/` interfaces or `core/`.

| Module | Folder | Responsibility | Key platform mechanism |
| --- | --- | --- | --- |
| Sentinel | `sentinel` | Analyze text, email, SMS, receipts | Local rules; share intent; OCR `[Spike]` |
| QR Shield | `qr_shield` | Capture, classify, check QR/URL | `mobile_scanner`; gateway reputation |
| EchoTrap | `echotrap` | Voice-clone detector, honeypot, call screening | Foreground service (microphone type); call-screening role; telephony provider |
| Refuge | `refuge` | Context engine and wallet concealment | Geofencing; device/profile administration; own-icon alias |
| Guardian Pay | `guardian_pay` | Real checkpoint before paying or opening a wallet | Reuses Refuge gate; trusted-contact approval |
| Trust Circle | `trust_circle` | Contacts, alerts, SOS, remote Refuge | Supabase Auth/Realtime; push |
| Logbook | `logbook` | Timeline, evidence, incident report | Local store with explicit retention |
| AURA | `aura` | Help, education, assistant | Static content; LLM via gateway |
| Privacy/Settings | `privacy` | Consents, permissions, data deletion | Per-module just-in-time consent |
| Platform | `api/`, landing | Auth, DB, gateway, distribution | Supabase; Lovable; GitHub Releases |

### Module rules

**Sentinel**
- Pure-Dart `Redactor` and `SignalExtractor`; rule IDs `R-01`..`R-18` and lexical IDs are versioned. Detect an *instruction or request*, not isolated words like "code" or "bank".
- Risk derivation order: no evidence → `not_assessed`; strong reliable signal or R-03/R-09 → `high`; other reliable signal → `caution`; insufficient (R-12) → `abstain`; sufficient with none → `none_detected`. These four states stay distinct; evidence with no signals is never called "legitimate".
- LLM output is untrusted data: validate it, and it can at most add a warning (R-14).

**QR Shield**
- Three results: known match, no-match with complete coverage, `unverifiable`. Block internal opening of a known threat. The gateway never fetches the destination (no SSRF) and `redirectResolution` stays `not_performed` until a sandboxed resolver is approved.
- Payload limit 8 KiB; escape control characters; hide sensitive query parameters by default.

**EchoTrap**
- Call audio is **not accessible** to third-party apps. Detection works only from the **microphone with the call on speakerphone**, in a foreground service declared with the microphone type, started by an explicit user action and visible while active. No always-on background listening.
- Pipeline: local voice-activity detection, windows of about 3-5 s, classifier (gateway API or on-device model) returning a score and verdict (human / doubtful / cloned / inconclusive). Batch windows to control cost. Never store audio; send windows only with consent.
- Detector accuracy degrades on speaker, compressed or phone-line audio. Treat vendor accuracy figures as self-reported marketing until measured by spike S-05; calibrate the threshold and show the score.
- Honeypot = the person forwards a suspicious call to a number served by a voice agent through a telephony provider (spike S-06). QHAWIX does not answer calls itself. Clone voices only with the owner's explicit consent, and only for testing.
- Call screening uses the call-screening role to block, reject or silence unknown numbers; it sees the number and verification status, never the audio.

**Refuge**
- Context engine inputs: time, location relative to a **locally learned** baseline, geofences, route deviation, manual panic trigger, remote trigger from a trusted contact (authenticated). Background location requires the "allow all the time" permission and is processed every few minutes, with a limit of 100 geofences per app: use zones, not continuous tracking. Never upload the baseline.
- Concealment is a port (`WalletConcealment`) with interchangeable implementations by tier:
  - **A, disguise and gate:** change QHAWIX's own icon/name via activity alias; cover a wallet app with a QHAWIX gate screen (usage-stats and overlay) requiring cooldown or approval. `[Spike]`: S-03 (wallet apps may refuse overlays/accessibility), S-07 (icon change reliability).
  - **B, work profile:** wallets live in a managed profile that QHAWIX hides or suspends. `[Spike]` S-01.
  - **C, device administration:** hide, suspend or block uninstall of any app. Requires factory reset provisioning. `[Requisito]` S-02.
- Prefer hide or suspend over uninstall. Uninstall is destructive and forces re-login; never do it silently.
- Always provide a person-verified restore path and a clear indicator of which tier is active.

**Guardian Pay**
- No simulated transfers. It analyzes a real payment request (text or screenshot) with the Sentinel rules and the four dimensions, then produces allow / warn / hold.
- A hold is enforced through the Refuge gate (cooldown, no wallet access until verified), plus guided independent verification and optional trusted-contact approval. It cannot block a payment inside another app; say so.
- Independent verification sources: official app, back of the card, account statement, curated directory with source and date, or an official site typed by the person. Reject any contact supplied by the requester.
- "Freeze account" is not possible without wallet integration: offer guided steps and deep links to official lock screens and hotlines, plus Refuge concealment. Direct integration is `[Futuro]` and needs an official agreement.

**Trust Circle**
- A trusted contact does **not** need the app or an invitation: the person picks a contact from the system picker (no `READ_CONTACTS`; typed name/number is only the manual fallback) and the contact is active immediately (owner decision, 2026-10-17; it replaces the earlier "mutual consent" rule). Two kinds exist: `phoneOnly` (no app) and `appUser` (installed and linked, through an optional invitation to install QHAWIX).
- Module onboarding asks for notifications just in time before the circle is used. Default data is on-device (`LocalTrustCircleRepository`); the mock under `data/mock/` is for tests only.
- `phoneOnly` contacts receive alerts and the SOS **by SMS or WhatsApp only**, as a message composed on the person's own phone. QHAWIX servers must never message someone who did not install the app (spam and privacy risk). Live temporary location sharing and remote Refuge requests require the app; the UI must say so next to that contact instead of hiding the feature.
- Alerts (voice clone, payment hold, Refuge on) go by push first for `appUser` contacts, SMS/WhatsApp as fallback. Location sharing is temporary and consented by the person sharing it. Never send an alert that implies an emergency response QHAWIX cannot guarantee. Tell the person to let a new contact know, because that contact may receive messages from them.

**Logbook**
- Append-only per case while it exists; deleting a case removes evidence, decisions, links and timeline with no tombstone containing case data. Event summaries contain no quotes, secrets, contacts or amounts.

**AURA**
- Text and curated resources first. No simulated voice or institutional authority. Assistant answers are bounded and cite their basis.

## Tech Stack

| Layer | Choice | Notes |
| --- | --- | --- |
| App | Flutter / Dart, Android only for now | `ui/ios/` exists from scaffolding; build nothing for it. |
| Native bridge | Kotlin platform channels | Needed for foreground service, call screening, device/profile administration, activity-alias icon. Keep it behind Dart ports. |
| App state | `ChangeNotifier` + `provider`, navigation with `go_router` | Do not add Riverpod or BLoC alongside. |
| Backend | Supabase: Auth, Postgres with RLS, Realtime, Edge Functions (TypeScript on **Deno**) | Gateway holds provider keys. Replaces the master spec's Cloudflare Worker. |
| Providers | URL reputation, voice-synthesis detection, voice agent and telephony: **to be chosen** | Reconfirm price, quota and terms before choosing; record the choice as an ADR. |
| Distribution | Lovable landing; signed APK in GitHub Releases | Landing is a separate repo linked from `integrations/landing`. |

Package versions in the master spec are starting references, not verified. Pin the SDK and lockfile in Phase 1.

## Project Structure

```
api/supabase/
  config.toml
  migrations/        # Versioned SQL; the only way the schema changes
  functions/         # Edge Functions (reputation, voice detection, alerts, honeypot webhooks)
  tests/             # pgTAP tests for every RLS policy
ui/lib/
  app/               # bootstrap, router, dependency injection        (to create)
  core/              # errors, Clock, limits, permissions, common types
  features/<module>/ # sentinel, qr_shield, echotrap, refuge, guardian_pay,
                     # trust_circle, logbook, aura, privacy            (to create)
    domain/          # pure Dart: rules, state machines, entities, repository/port interfaces
    data/            # implementations, gateway client, platform-channel adapters, mappers
    view/            # screens and presentational widgets
    viewmodel/       # immutable screen state, commands, stale-response discard
ui/android/          # Kotlin: services, receivers, device-admin and call-screening components
ui/test/ ui/integration_test/
contracts/           # API schemas and event contracts                  (to create)
docs/                # master spec and original sources (read-only evidence)
odd/tasks/           # feature tracking documents
```

## Architecture Rules

1. **Dependencies point inward**: `view -> viewmodel -> domain <- data`. `domain` imports nothing from Flutter, `http`, Supabase, platform channels or `data`.
2. **Platform capabilities are ports** in `domain/` (for example `WalletConcealment`, `ContextProvider`, `AudioWindowSource`, `CallScreener`, `ExternalBrowserPort`), implemented in `data/` over platform channels. This keeps every tier and provider swappable and every rule testable without a device.
3. **Time is injected** through the `Clock` port; use monotonic time for cooldowns and detect civil-clock regressions.
4. **Commands are idempotent**: double tap, retry or a duplicate alert never repeats an effect.
5. **ViewModels discard stale async responses** (check session, case, revision and active command) and release camera, microphone and listeners on dispose.
6. **DTOs never reach widgets**; one mapper per feature. Contracts carry `schemaVersion`; rule sets carry a version.
7. **RLS on every exposed table**, with allowed and denied cases tested. Authorization lives in the database, never in the client.
8. **Schema changes only via migrations.** Never edit an applied migration; add a new one.
9. **The gateway** validates strictly, uses fixed provider hosts, returns filtered schema-validated JSON (never raw provider output), applies rate limits and timeouts, and logs only random ID, result code, latency, provider, version and counts. Rate limiting must be durable (a table or equivalent), not in-memory.

## Permissions Policy

Request each permission just in time, at the module that needs it, with an explanation, and make the module degrade gracefully when denied (with a manual alternative where one exists).

| Permission / role | Module | Notes |
| --- | --- | --- |
| Camera | QR Shield | Only when opening the scanner; URL paste as alternative |
| Microphone + foreground service (microphone type) | EchoTrap | Started by the person; visible notification |
| Call-screening role | EchoTrap | No audio access |
| Location, including background "all the time" | Refuge | Local processing; explain why; zones not tracking |
| Usage stats / overlay | Refuge tier A | Subject to spike S-03 |
| Device or profile administration | Refuge tier B/C | Explicit enrollment flow |
| Notifications | Trust Circle, all alerts | |
| Accessibility service | **Avoid.** | Not approved; wallet apps may refuse to run with it. Needs an ADR. |
| Contacts, SMS, call log | **Not requested.** | Trusted contacts are entered explicitly |

## UX and Language Rules

- **Code, identifiers, comments and commit messages are in English.** User-facing app and landing copy is in **neutral Spanish**; `docs/` is Spanish.
- Accessibility is required: screen reader, 200% text scale, 48 dp touch targets, icon plus text (never color alone), and a manual alternative for every camera, microphone or location task.
- Emergency-adjacent screens (Refuge, SOS) must be operable with one hand and a discreet gesture, and must not reveal that concealment is active to someone watching.

## Commands

Run from the repository root unless noted. Verified on the skeleton: `flutter analyze`, `flutter test`, `npx supabase --version`.

| Task | Command |
| --- | --- |
| Install app deps | `cd ui && flutter pub get` |
| Analyze | `cd ui && dart analyze` (mechanical fixes: `dart fix --apply`) |
| Test | `cd ui && flutter test` |
| Run app | `cd ui && flutter run --dart-define-from-file=env/local.json` |
| Start local backend (needs Docker) | `cd api && npx supabase start` |
| Serve functions locally | `cd api && npx supabase functions serve` |
| New function / migration | `cd api && npx supabase functions new <name>` / `npx supabase migration new <name>` |
| DB tests | `cd api && npx supabase test db` |

`ui/env/*.json` is gitignored except `env/example.json`. Provider keys and any service-role key never go in `ui/`.

## Testing

- **domain**: plain Dart unit tests with no Flutter or network: every `R-NN` rule, risk derivation, context-engine decisions (night, unusual place, panic, remote), concealment-tier selection, hold and restore flows.
- **data**: contract tests against gateway schemas and typed-error mapping with fakes; offline, timeout, 429, 5xx and invalid JSON must yield `unverifiable`.
- **view**: widget tests with fake repositories; verify no permission prompt on start and graceful denial.
- **android (Kotlin)**: instrumented tests for the foreground service lifecycle, call screening decisions and concealment adapters.
- **database**: pgTAP for every RLS policy.
- **device matrix**: features that depend on the OS or a third-party app (concealment, wallet gating, call forwarding, detector accuracy) can only be proven on **physical devices**. Record the device, Android version and result of each spike in `odd/tasks/` before building on it.
- Behavior changes follow RED then GREEN when a runnable test exists. Never visit active malware to demonstrate a block; use mocks or official test domains. Never clone a voice without the owner's explicit consent.
- Before saying a task is done, `dart analyze` and `flutter test` pass; report anything you could not run.

## Skills (load before working in the area)

| Area | Skill |
| --- | --- |
| Gateway, Edge Functions, Auth, RLS, CLI, debugging | `supabase` |
| Schema, migrations, RLS policies, SQL | `supabase-postgres-best-practices` |
| Flutter structure and layering | `flutter-apply-architecture-best-practices` |
| Models and JSON mapping | `flutter-implement-json-serialization` |
| Navigation | `flutter-setup-declarative-routing` |
| Responsive layout | `flutter-build-responsive-layout` |
| Overflow / constraint errors | `flutter-fix-layout-issues` |
| Widget tests | `flutter-add-widget-test` |
| Integration tests | `flutter-add-integration-test` |
| Static analysis | `dart-run-static-analysis` |

Skills come from `supabase/agent-skills` and `flutter/skills`; update them with `install-skill`, never by hand. Where a generic skill suggests another state manager or router, this file wins.

## Open Decisions and Spikes (do not silently resolve)

| Item | State |
| --- | --- |
| S-01 work-profile hiding and wallet compatibility | Unverified |
| S-02 device-administration hide/suspend and enrollment cost | Unverified |
| S-03 wallet apps vs overlay/accessibility | Unverified |
| S-04 programmatic lock of Android 15 Private Space | Unverified |
| S-05 voice-detector accuracy over speaker and phone line | Unmeasured |
| S-06 conditional call forwarding to the honeypot with Peruvian carriers | Unverified |
| S-07 reliability of changing QHAWIX's own icon across manufacturers | Unverified |
| Providers (URL reputation, voice detection, voice agent, telephony) | Not chosen; record an ADR |
| `supabase_flutter` in `ui/pubspec.yaml` | Now needed for Auth and Realtime; keep |
| `ui/ios/` folder | Present from scaffolding; Android only |
| Android package ID `pe.qhawix.qhawix` | Provisional until the owner is confirmed |
| Legal: recording or transcribing calls, location consent, privacy notice per country | Needs review before any external pilot |

## Implementation Order

Phase 0 spikes → platform base → Sentinel, QR Shield, Logbook → EchoTrap detector and Trust Circle alerts → Refuge tier A and Guardian Pay → Refuge tiers B/C and honeypot → AURA, landing, APK → security and device-matrix validation. Build domain and UX against fakes while spikes run, but never ship a fake as a feature.

## Git Workflow

- Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`). No AI attribution lines.
- Work on a feature branch (`feature/<name>`), never directly on `main`.
- Commit only when asked. Push, PR creation and merge are the user's decisions.
- Keep commits as reviewable work units: behavior, tests and docs together, about 400 changed lines at most.
- `.atl/` is local generated state and is gitignored.

## Boundaries

- Never commit secrets: provider keys, service-role key, JWT secret, keystore or its password, database password, `.env*` files.
- Never run destructive or remote-affecting commands (`db reset`/`db push` on a remote, `functions deploy`, `secrets set`, linking a project) without explicit approval of the target project and credentials.
- Never provision a device as a device owner, hide, suspend or uninstall apps on a real device without the owner's explicit consent; test on a dedicated device.
- Never edit the original documents in `docs/` or the contents of installed skills.
- Do not add dependencies, change the Flutter or Supabase major version, alter CI, add an accessibility service, or introduce a second state manager without approval.
- Do not copy code from the EchoTrap reference project; it is read-only material.
- Do not invent product scope. If neither the user, `README.md` nor this file says it, ask.
