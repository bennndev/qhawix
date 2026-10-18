# Aura Mascot Interactions and Restrained Branding

## Objective

Make the Aura entry screen more interactive by reusing the existing Guardian mascot animation system and place QHAWIX branding without disrupting the current mobile hierarchy.

## Problem and Why

Aura is currently a placeholder while Guardian already has eight implemented animation states. The user wants more interactive Aura animations and a restrained, structured QHAWIX logo treatment that preserves UI/UX.

## Scope

- Reuse the existing Guardian mascot component and its state meanings; do not change generated mascot assets or animation engine.
- Add a small set of honest, user-triggered Aura interactions tied to existing QHAWIX modules or curated local content. Do not imply AI analysis, verified caller identity, microphone listening, QR scanning, or successful protection when no such operation ran.
- Preserve the current navigation, design tokens, accessibility semantics, reduced-motion support, and responsive behavior.
- Use the existing QHAWIX wordmark unless approved logo artwork is present. The inspected Flutter branch has no dedicated project-logo asset; graphic-logo integration remains pending the user-provided asset.
- No backend, model, audio, or new package integration in this slice.

## Constraints

- Current branch: `feature/ui`, based on `origin/feature/ui`.
- Existing mascot states: `idle`, `thinking`, `working`, `success`, `listening`, `scanning`, `alert`, and `stealth`; only use a state when its documented meaning matches the real interaction.
- Keep interactive targets at least 48 dp, maintain semantic labels, avoid persistent overlays, and respect reduced motion.
- User requested work under “CIMM”; that acronym is not defined in current project docs or memory. Proceed with the repository’s documented test-first/task-tracking workflow without claiming CIMM compliance until clarified.

## Authorized Edit Surfaces

- `ui/lib/features/aura/view/aura_screen.dart`
- `ui/lib/features/aura/aura_providers.dart`
- `ui/lib/features/aura/viewmodel/**`
- `ui/test/features/aura/**`
- `ui/lib/app/home_screen.dart`
- `ui/lib/app/analyze_screen.dart`
- `ui/lib/core/widgets/module_card.dart`
- `ui/lib/features/trust_circle/view/sos_screen.dart`
- `ui/lib/features/trust_circle/view/trust_circle_onboarding_screen.dart`
- `ui/test/app/**`
- `ui/test/core/widgets/**`
- `ui/test/features/trust_circle/**`

The approved logo asset path will be added here only after the user supplies the official artwork.

## Tasks

### AUR-01 — Add truthful Aura interactions using Guardian animations

- [x] Add two compact, on-device Aura guides for access-code requests and payment pressure, with actionable steps and their QHAWIX basis.
- [x] Reuse the existing mascot states truthfully: idle by default and alert only after the user selects a concern; no artificial loading or simulated detection.
- [x] Add widget tests for both guides, reset behavior, visible content, semantics, reduced motion, dark theme, and narrow/large-text layout.

**Route:** delegated direct. Trigger: Aura implementation requires coordinated view/state/test changes and source reading before edits.

**Acceptance criteria:**

- Aura no longer renders only its placeholder text.
- Every interactive action has a truthful result; no unsupported detection or security guarantee is shown.
- Guardian animation remains accessible and does not obscure content or introduce overflow on narrow screens.
- Focused Aura widget tests pass; `dart analyze` and `flutter test` pass when available.

**Applicable checks:** test-first when a deterministic widget test applies; `cd ui && flutter test`; `cd ui && dart analyze`; structural review for touch targets, semantics, reduced motion, and responsive layout.

### AUR-02 — Integrate the official QHAWIX logo subtly

- [ ] Pending the user supplying the approved logo artwork and variant. Keep the current wordmark until then.

**Acceptance criteria:**

- Logo uses the approved asset, appears once in an existing brand/header region, and does not crowd the 96 dp mascot or add a banner/overlay.
- Decorative imagery does not duplicate spoken brand text.

**Route:** pending external asset; no substitute mark will be invented.

### AUR-03 — Fix Trust Circle notification rationale crash

- [x] Replace the single notification-permission bullet with exactly three accurate points: purpose, permission/data scope, and what happens if declined.
- [x] Add a widget regression test that opens the notification rationale and verifies its three bullets render without assertion failure.
- [ ] Preserve the shared `PermissionRationaleScreen` exactly-three-bullets contract.

**Route:** delegated direct. Trigger: diagnosis spans a shared component, a feature caller, and a regression test; the bounded explorer identified the caller and exact mismatch.

**Acceptance criteria:**

- Trust Circle notification onboarding no longer trips the assertion.
- The three bullets describe actual notification/contact behavior and do not overstate permissions.
- The focused regression test fails before the copy fix and passes afterward.

**Applicable checks:** focused Trust Circle widget test; `cd ui && flutter test --no-pub`; `cd ui && dart analyze`; `git diff --check`.

**Progress:** The caller now supplies three notification-specific bullets and a focused widget regression test is present. `git diff --check` passes. The focused Flutter test was attempted twice (including one independent verification attempt) but the Flutter/Dart process produced no output and hung until stopped; full tests and analysis remain unverified. At the user's explicit request, this work was committed as `6db0dff` despite inconclusive functional verification. Resume by diagnosing the Flutter runner in the user's Android Studio/Windows environment, then rerun the focused test and analyzer before closing this task.

### AUR-04 — Add truthful Aura phases and align module cards

- [ ] Keep Home's Aura in `idle`; add a distinct, discreet Aura facet to Analyze without implying scanning or analysis is running on its placeholder module list.
- [ ] Connect operation states only to real Trust Circle SOS execution/results; leave listening/scanning unconnected while their feature screens remain placeholders.
- [ ] Center module icons in their visual column and retain readable, separated heading/description hierarchy; do not disturb bottom-navigation geometry.
- [ ] Add/update widget tests for state transitions, icon/card alignment, and narrow/large-text layouts.

**Route:** delegated direct. Trigger: coordinated cross-screen UI, state wiring, and widget tests across multiple non-trivial files.

**Acceptance criteria:**

- Aura has distinct visual phases in Home and Analyze, without duplicating the same active state or implying an unperformed operation.
- Real SOS progress and outcome states match the command result; no fake detection or protection claim is introduced.
- Icons/actions are centered as requested while cards remain accessible, responsive, and readable.
- Analyze has one clear page title, visible breathing room between its subtitle and the first card, and a sufficiently legible discreet Aura mark (no muddy dark-on-dark treatment).
- Applicable focused tests, full Flutter tests, and static analysis pass.

**Applicable checks:** test-first where deterministic widget outcomes exist; `cd ui && flutter test --no-pub`; `cd ui && dart analyze`; `git diff --check`; structural review of semantics, responsive layout, and state-to-operation mapping.

**Progress:** The UI and focused tests are implemented, but the focused Flutter batch and `dart analyze` both hung without output and were stopped; verification is inconclusive. `git diff --check` passes. The existing SOS `ActionResult` maps both message-composer success and failure to `saved`, so the mascot deliberately does not show a success state for that ambiguous result; only an explicit `rejected` result shows `alert`. Distinguishing composer outcomes requires a future typed domain-result change outside this UI slice. No commit was made.

**Screenshot follow-up:** Addressed the reported Analyze screenshot issues: the app bar now shows `QHAWIX` so there is one prominent `Analizar` heading; an explicit 16 dp gap separates the subtitle from the first card; the `stealth` Aura mark uses a themed foreground against the accent tile. The focused test checks both owl foreground contrast ratios and the subtitle/card gap at 320 dp width and 1.5x text scale. `git diff --check` passes; the focused Analyze test hangs without output, so visual/widget verification remains inconclusive.

## Verification Evidence

- Baseline branch tip: `e5a4f9f` (`origin/feature/ui`).
- Baseline worktree had only the pre-existing untracked `.idea/` directory; preserve it.
- Forecast: approximately 150–250 authored changed lines for AUR-01; AUR-02 size depends on the supplied asset. Delivery strategy: `ask-on-risk`.
- Follow-up forecast: approximately 300–400 authored changed lines for AUR-03 and AUR-04 combined (generated files excluded). Keep `ask-on-risk`; if the forecast or running count exceeds approximately 400 lines, pause before commit and ask once for the chain strategy.

## Progress and Next Step

- [x] Confirm current branch and map Aura/mascot/branding implementation.
- [x] Implement AUR-01 through one bounded writer; run applicable checks.
- [ ] Verify and close the Trust Circle notification-rationale fix under AUR-03; focused Flutter/Dart commands currently hang without output.
- [ ] Verify and close the implemented Aura phases and card alignment under AUR-04; focused Flutter/Dart commands currently hang without output.
- [ ] Revisit AUR-02 when approved logo artwork is supplied.

**AUR-01 verification:** `cd ui && flutter test --no-pub` — PASS, 434 tests; `cd ui && dart analyze` — PASS, no issues; `git diff --check` — PASS. The initial test runner stalled before a baseline RED could be observed, so no RED claim is made; the final widget tests and full suite passed against the restored committed lockfile.

**AUR-01 commit:** `28d6968` — `feat(aura): add local safety guidance interactions`.

**AUR-03/AUR-04 implementation readback:** Analyze uses the discreet `stealth` mascot state while Home remains `idle`; module icons are centered in a fixed 48 dp column; SOS shows `working` while the command is pending and `alert` only for an explicit rejected result. Ambiguous `saved` and `exampleOnly` outcomes do not show success. Widget tests cover these states, screen layout, icon centering, and exactly three rationale bullets.

**AUR-03/AUR-04 verification:** `git diff --check` — PASS. The focused widget test batch and `dart analyze` — HUNG/inconclusive (no output, stopped once). Independent read-only review found no remaining severity findings. Native risk assessment returned `high/unassessable` because the candidate includes untracked test files requiring explicit inventory; receipt-driven development is disabled. AUR-03 was committed as `6db0dff` and AUR-04 as `d247a2b`, at the user's request despite inconclusive functional verification.

**Analyze screenshot follow-up verification:** `git diff --check` — PASS; focused Analyze widget test — HUNG/inconclusive at 30 seconds. Independent read-only review found no severity findings. `dart format` also hung, so the test was formatted manually and remains unverified. Included in commit `d247a2b`.
