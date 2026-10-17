# AGENTS.md

> Placeholder. Replace each section with project-specific details.

## Project Overview

<!-- What is this project? One or two sentences on purpose and users. -->

## Tech Stack

<!-- Languages, frameworks, runtimes, key libraries. -->

## Project Structure

<!-- Main directories and what lives in each. -->

## Commands

<!-- Install, run, test, lint, build. Example:
- Install: `...`
- Dev: `...`
- Test: `...`
-->

## Code Conventions

<!-- Naming, formatting, architecture rules, patterns to follow or avoid. -->

## Testing

<!-- Test runner, where tests live, expectations before merging. -->

## Git Workflow

<!-- Branch naming, commit message format (e.g. Conventional Commits), PR rules. -->

## Design skills

Three skills are installed for the project (`.agents/skills/` and `.claude/skills/`). Each owns one job:

| Skill | Owns | Use it for |
| --- | --- | --- |
| `impeccable` | Design system and refinement | Critique, audit, polish, typography, colour, motion and tokens for existing UI, plus its PRODUCT.md and DESIGN.md context. Source of truth for visual decisions. |
| `design-taste-frontend` (Taste v2) | Art-direction exploration | New public-facing pages only (landing, marketing, portfolio), when explicitly asked. Not for dashboards, app screens or existing components. |
| `web-interface-guidelines` (Vercel) | Technical audit | Read-only review of accessibility, interaction and semantics. Reports findings, never redesigns. |

Overlap rules:

1. One owner per component per task. Never run two design skills to rewrite the same component in one turn.
2. When more than one applies, go in this order: explore (Taste, optional), build or refine (Impeccable), audit (Vercel).
3. Taste proposes, Impeccable adopts. A Taste direction only becomes part of the design system once it is recorded through Impeccable; until then DESIGN.md wins.
4. The Vercel audit is read-only: fixes go back to whoever owns the component.
5. Taste and Impeccable are on demand. Do not invoke them for backend, copy-only or non-UI tasks.

Installed revisions (reference for updates):

- `impeccable` 4.6.0, pbakaus/impeccable @ 08d5b470495d (Apache-2.0). One build per agent: `.claude/skills/impeccable` for Claude Code, `.agents/skills/impeccable` for Codex and Cursor. Its hooks are not installed.
- `design-taste-frontend` (taste-skill v2.0.0), Leonxlnx/taste-skill @ f624f37a8c65 (MIT). The experimental and v1 variants are not installed.
- `web-interface-guidelines`, vercel-labs/web-interface-guidelines @ 434b7f913646 (MIT). Derived from its `command.md` by adding only `name: web-interface-guidelines`.

Known limits:

- Claude Code prefers a personal skill over a project one, so `~/.claude/skills/impeccable` (v4.0.2) overrides the project copy there. Update or remove the personal copy to use 4.6.0.
- Taste's scripts need Node 22+ and Chrome, Edge or Chromium, use the network to find pictures and keep a history in `~/.taste-skill/`.
- Impeccable's launcher downloads its engine binary on first use from the repository's releases, verified against a checksum.

## Boundaries

<!-- What agents must NOT do: files to avoid, secrets handling, actions needing approval. -->
