# Trust Circle (Red de Confianza)

UI for the Trust Circle module, backed by an in-memory **mock** repository.
Every screen shows the "Datos de ejemplo" banner and no mock action ever claims
that something was sent or delivered.

Run it on a phone from `ui/`:

```
flutter run -t lib/dev/trust_circle_demo_main.dart
```

## Screen map

| Screen | File | Reached from |
| --- | --- | --- |
| Circle overview (entry of the "Red" tab) | `view/trust_circle_screen.dart` | tab |
| Add contact + pending invitation | `view/add_contact_screen.dart` | overview |
| Contact detail (permissions, channels, pause, remove) | `view/contact_detail_screen.dart` | contact row |
| Alert preferences | `view/alert_preferences_screen.dart` | overview |
| SOS | `view/sos_screen.dart` | overview |
| Check-in and safe arrival | `view/check_in_screen.dart` | overview |
| Remote Refuge requests | `view/refuge_requests_screen.dart` | overview |
| Verification placeholder | `view/refuge_verification_screen.dart` | a request |
| Family keyword | `view/family_keyword_screen.dart` | overview |

Layers: `domain/` (pure Dart, `Clock` port, `TrustCircleRepository` port) ->
`data/mock/` -> `viewmodel/` (`TrustCircleViewModel`, `FamilyKeywordViewModel`,
both discard stale responses and run a command once on double tap) -> `view/`.
`trustCircleProviders()` wires them; it accepts a repository and a clock for tests.

## Lovable component -> Flutter widget

| Lovable (`lovable/src`) | Flutter |
| --- | --- |
| `panel` utility, stat card | `QhawixCard` (existing), `SummaryPanel` (new) |
| `PageHeader` | `PageHeader` (new) |
| `SeverityChip` | `StatusChip` (new; neutral states, icon + text) and existing `RiskBadge` for risk |
| `DemoNote` | `MockDataBanner` (existing) |
| Settings rows (`label` + `Switch`) | `ToggleRow` (new) |
| Filter pills in `historial` | `SegmentedChoice` (new, single choice) and existing `QhawixChip` (filters) |
| Key/value lines in cards | `KeyValueRow` (new) |
| Round icon holders (`rounded-full bg-muted`) | `InitialsAvatar` (new) |
| `Button` variants default / outline / destructive / ghost | `PrimaryButton` / `SecondaryButton` / `DestructiveButton` / `TertiaryButton` (existing) |
| Inline destructive confirm in `ajustes` | `showConfirmationDialog` (existing) |
| Daily-limit `Slider` in `finanzas` | not ported: the circle has no numeric limit (durations use `SegmentedChoice`) |
| Owl mascot | not used: this module is all risk, gate and error states |

New shared widgets are in `core/widgets/` and use only theme tokens.

## Differences between the prototype and DESIGN.md (DESIGN.md followed)

| Topic | Lovable | DESIGN.md | Followed |
| --- | --- | --- | --- |
| Color space and palette | oklch grays, pure black primary | hex Ink `#11141A` and a teal accent | DESIGN.md |
| Risk colors | green "Seguro", amber, red, gray | muted risk set, no "safe" state | DESIGN.md |
| "Seguro" label | exists | forbidden: unverifiable is never safe | DESIGN.md |
| Radius | 12 px panels, pill buttons | 16 dp cards, pill buttons | DESIGN.md |
| Touch targets | `h-10`, `py-1.5` pills (about 32-40 px) | 48 dp minimum | DESIGN.md |
| Navigation | six items with a sidebar on desktop | five tabs, phone first | DESIGN.md |
| Destructive confirm | inline button swap | dialog with consequence text and focus on Cancel | DESIGN.md |
| Motion | `animate-rise`, owl keyframes | at most 300 ms, reduced motion respected | DESIGN.md |
| Mascot on alert screens | owl with `alert` state | no mascot on risk, gate or error screens | DESIGN.md |
| State by color | chips rely partly on color | icon + text always | DESIGN.md |
| Toasts | `sonner` toast on every action | results stay on screen as a banner | DESIGN.md (honest, persistent wording) |
| Fonts | DM Sans and Inter | same | both |

## Open points

- `Clock` lives in `domain/clock.dart` because `core/` was out of the allowed
  surface; AGENTS.md puts it in `core/`. Move it when a shared port exists.
- Screens navigate with `Navigator.push`; wire them into `go_router` when the
  app shell exists.
- Verification before approving a remote Refuge request is a placeholder that
  says so; approving only changes example data.
- The default repository is the mock until a Supabase-backed one exists.
