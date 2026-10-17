# AGENTS.md

## Project Overview

Qhawix is a hackathon MVP (Hack the Andes, Track 04: banking cybersecurity, Peru). Product scope, evidence and open decisions live in `docs/` (start with `docs/propuesta-qhawix.md` and `docs/especificacion-implementacion-qhawix.md`). Tracking lives in `odd/tasks/`. Do not invent product scope: if the docs do not say it, ask.

## Tech Stack

- **UI**: Flutter 3 / Dart 3 (Android and iOS), in `ui/`.
- **Backend**: Supabase (Postgres, Auth, Realtime, Storage, Edge Functions), in `api/`. Edge Functions are TypeScript on Deno, not Node.
- **Client SDK**: `supabase_flutter`, used only inside the `data` layer.

## Project Structure

```
api/supabase/
  config.toml
  migrations/     # Versioned SQL. The only way the schema changes.
  functions/      # Edge Functions (TypeScript/Deno), one folder each
  tests/          # pgTAP tests for RLS and database functions
ui/lib/
  core/           # config, router, theme, error types, shared infrastructure
  features/<feature>/
    domain/       # Entities, repository interfaces, use cases. Pure Dart.
    data/         # DTOs, datasources (Supabase), repository implementations, mappers
    presentation/ # Pages (containers) and widgets (presentational)
docs/             # Product and research documents
odd/tasks/        # Feature tracking documents
```

## Architecture Rules (decoupling)

1. **Dependencies point inward**: `presentation -> domain <- data`. `domain` imports nothing from Flutter, Supabase or `data`.
2. **Supabase stays in `data/`**. No `Supabase.instance` or `supabase_flutter` import in `domain/` or `presentation/`. The UI depends on repository interfaces, injected from `core/`.
3. **DTOs never reach widgets**. Repositories map DTO -> domain entity in one mapper per feature. A schema change is absorbed there.
4. **Features are vertical and self-contained**. A feature may use `core/` but never imports another feature's `data/` or `presentation/`. Share through `domain/` or `core/`.
5. **Containers vs presentational**: pages own state and call use cases; widgets receive data and callbacks and have no business logic.
6. **Authorization lives in the database**: RLS on every table in an exposed schema. The client is never trusted. Sensitive or multi-step logic goes in an Edge Function, not in Flutter.
7. **Schema changes only via migrations** in `api/supabase/migrations/`. Never edit the remote database by hand. Never edit an applied migration; add a new one.
8. **No service-role key in the client**. Only the anon key and the project URL are allowed in `ui/`.

## Commands

Run from the repo root unless noted.

- UI deps: `cd ui && flutter pub get`
- UI run: `cd ui && flutter run --dart-define-from-file=env/local.json`
- UI analyze: `cd ui && dart analyze` (apply mechanical fixes with `dart fix --apply`)
- UI tests: `cd ui && flutter test`
- Local backend (needs Docker): `cd api && npx supabase start` / `npx supabase stop`
- New migration: `cd api && npx supabase migration new <name>`
- Reset local DB and re-apply migrations: `cd api && npx supabase db reset`
- DB tests: `cd api && npx supabase test db`
- Serve functions: `cd api && npx supabase functions serve`

`ui/env/*.json` holds `SUPABASE_URL` and `SUPABASE_ANON_KEY` and is gitignored. Commit an `env/example.json` with placeholder values only.

## Code Conventions

- Code, comments, identifiers and UI strings are in English unless the task states otherwise. Product documents in `docs/` are in neutral Spanish.
- Dart: `snake_case` files, `UpperCamelCase` types, null-safe, immutable entities (`final` fields, `const` constructors). Follow `analysis_options.yaml`; no `// ignore` without a reason.
- Repository methods return domain types and surface failures as typed errors from `core/error`, never raw Supabase exceptions.
- SQL: `snake_case`, plural table names, explicit schema, `timestamptz` for times, foreign keys indexed, RLS policies named after what they allow.
- Edge Functions: validate input, return typed JSON errors, never log secrets or personal data.
- Reuse existing helpers for shared state before writing a new one.

## Testing

- **domain**: plain Dart unit tests, no Flutter or network.
- **data**: repository tests with a fake datasource; mapper tests for every DTO.
- **presentation**: widget tests with fake repositories. Add integration tests only for critical user flows.
- **database**: pgTAP tests in `api/supabase/tests/` for every RLS policy (allowed and denied cases) and database function.
- Behavior changes follow RED -> GREEN: write the failing test first when a runnable test exists.
- Before saying a task is done: `dart analyze` and `flutter test` pass for `ui/`; `supabase test db` passes when `api/` changed. Report any check you could not run.

## Skills (load before working in the area)

| Area | Skill |
| --- | --- |
| Any Supabase task (Auth, RLS, Edge Functions, Realtime, CLI, debugging) | `supabase` |
| Schema, migrations, RLS policies, indexes, SQL | `supabase-postgres-best-practices` |
| Flutter structure and layering | `flutter-apply-architecture-best-practices` |
| Models and JSON mapping | `flutter-implement-json-serialization` |
| Navigation and deep links | `flutter-setup-declarative-routing` |
| Responsive layouts | `flutter-build-responsive-layout` |
| Overflow and constraint errors | `flutter-fix-layout-issues` |
| Widget tests | `flutter-add-widget-test` |
| Integration tests | `flutter-add-integration-test` |
| Static analysis and lint fixes | `dart-run-static-analysis` |

Supabase skills come from `supabase/agent-skills`; Flutter and Dart skills from `flutter/skills`. Update them with the `install-skill` skill, never by hand-editing copies.

## Git Workflow

- Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`). No AI attribution lines.
- Work on a feature branch (`feature/<name>`), never directly on `main`.
- Commit only when asked. Push, PR creation and merge are the user's decisions.
- Keep commits as reviewable work units: behavior, tests and docs together, about 400 changed lines at most.

## Boundaries

- Never commit secrets: no service-role key, JWT secret, database password or `.env` files.
- Never run destructive database commands against a remote project (`db reset`, `db push`, dropping data) without explicit approval.
- Do not link or deploy to a remote Supabase project without explicit approval of the project and the credentials to use.
- Do not edit `.atl/` or the contents of installed skills by hand.
- Do not add dependencies, change the Flutter or Supabase major version, or alter CI without approval.
- Do not copy code from the EchoTrap reference project or change its files; it is read-only reference material.
