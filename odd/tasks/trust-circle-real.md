# Trust Circle: real local data, onboarding, contact picker

Objective: Red de Confianza without mock/example data; module onboarding for needed permissions; add contacts via the system picker (no form fill as the primary path).
Branch: `feature/ui`. Test runner: `cd ui && dart analyze && flutter test`.

## Specs
- S1. "Ya no sea con datos mocks" / "Ya no datos mock para este módulo."
- S2. "Implementar el onboarding que te pida los permisos necesarios."
- S3. "Funcione seleccionando los contactos y no se tenga que rellenar los formularios."
- S4. No `READ_CONTACTS` (system picker only); servers never message phone-only contacts; UI Spanish; code English.

## Tasks
- [x] T1 (S1–S4): local repository, picker, onboarding, wire providers, drop banner for real data — inline

## Log
- L1 (2026-10-17): owner asked to remove mocks, add permission onboarding, and select contacts instead of filling forms.
- L2 (2026-10-17): wired `LocalTrustCircleRepository` + `NativeContactPicker`, module onboarding with notifications, picker-first add contact, banner only when `usesExampleData`, `POST_NOTIFICATIONS` in manifest; mock kept for tests/safe-zone demo.
