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

## Verification Evidence

- Baseline branch tip: `e5a4f9f` (`origin/feature/ui`).
- Baseline worktree had only the pre-existing untracked `.idea/` directory; preserve it.
- Forecast: approximately 150–250 authored changed lines for AUR-01; AUR-02 size depends on the supplied asset. Delivery strategy: `ask-on-risk`.

## Progress and Next Step

- [x] Confirm current branch and map Aura/mascot/branding implementation.
- [x] Implement AUR-01 through one bounded writer; run applicable checks.
- [ ] Revisit AUR-02 when approved logo artwork is supplied.

**AUR-01 verification:** `cd ui && flutter test --no-pub` — PASS, 434 tests; `cd ui && dart analyze` — PASS, no issues; `git diff --check` — PASS. The initial test runner stalled before a baseline RED could be observed, so no RED claim is made; the final widget tests and full suite passed against the restored committed lockfile.

**AUR-01 commit:** pending.
