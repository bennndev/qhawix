# App shell: module menu and per-module onboarding

Objective: main menu with QHAWIX modules; opening a module runs that module's onboarding (permissions + short setup) before its screen. Visual system from `DESIGN.md`; Lovable is reference only (do not edit `lovable/`).
Branch: `feature/ui`. Test runner: `cd ui && dart analyze && flutter test`. Delivery: commit work units; do not push.

## Specs
- S1. "Un menú principal con los módulos" and "cuando se elija cada módulo abrir el onboarding con los permisos que cada uno necesita."
- S2. "Utiliza el DESIGN.md y lo de lovable" — DESIGN.md is authoritative for tokens, five tabs (Inicio, Analizar, Refugio, Red, Bitácora) and ModuleCard; Lovable informs layout spirit only.
- S3. Onboarding is per module (just-in-time permissions), not one global permission dump at app start.
- S4. UI copy neutral Spanish; code/commits English. No edits under `lovable/`.

## Tasks
- [x] T1 (S1–S4): app shell, router, home/analyze module menus, generic module onboarding, wire existing Refuge/Trust Circle/stubs — route: inline — commit pending
- [ ] T2: device check of the shell on the Honor — when owner reconnects

## Log
- L1 (2026-10-17): owner asked for a main module menu that opens per-module onboarding with the permissions each needs, using DESIGN.md and Lovable; device temporarily disconnected.
- L2: T1 implemented under `ui/lib/app/`; DESIGN five tabs win over Lovable's six-tab Vigía nav; `flutter test test/app/app_shell_test.dart` green.
