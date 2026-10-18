# Refuge (Refugio): safe-zone alerts

Flutter side of `contracts/safe-zone-channel.md`. The person defines a home zone and an alert
window; while monitoring runs, Android sends an **SMS by itself** to the chosen recipients when
they are away from home during the window. **Everything here is real**: tests and alerts send
real SMS. Nothing is mocked in the app.

Run it on a phone from `ui/` (real channel, real SMS):

```
flutter run -t lib/dev/safe_zone_demo_main.dart
```

> **Recipients come from the Trust Circle's mock repository for now.** The demo entry wires
> `trustCircleProviders()` (in-memory example contacts) above `refugeProviders()`. The SMS
> destinations are therefore example numbers until the Trust Circle has a real repository; edit
> the numbers in `trust_circle/data/mock/` locally to test with a real phone.

## Screens

| Screen | File | Reached from |
| --- | --- | --- |
| Hub (`RefugeScreen`): monitoring state, permission health, config summary, event history, tests, stop | `view/refuge_screen.dart` | module entry |
| Onboarding wizard, 7 steps (what it does, recipients, home, parameters, sending, permissions, review) | `view/safe_zone_onboarding_screen.dart`, `view/onboarding_steps.dart` | hub when nothing is configured; hub "Editar ..." opens it at that step |
| One permission rationale at a time | `core/widgets/permission_rationale_screen.dart` (reused) | wizard and hub |

If nothing is configured, `RefugeScreen` shows the wizard. Off Android, or without Google Play
services, it says the feature is not available on this device.

## Layers

`domain/` (pure Dart: `SafeZoneConfig` with `issues()`, `AlertWindow.inWindow`, `SafeZoneStatus`,
`SafeZoneEvent`, typed `SafeZoneError`s, ports `SafeZonePlatform` and `AlertRecipientSource`,
`Clock`) -> `data/` (`MethodChannelSafeZonePlatform`, `SafeZoneMapper` = the only place that knows
the wire JSON, `TrustCircleRecipientSource` reads only `trust_circle/domain`) -> `viewmodel/`
(`SafeZoneStatusViewModel`, `SafeZoneSetupViewModel` shared by the onboarding and the settings
edit; both discard stale async results and run a command once on double tap) -> `view/`.

`refugeProviders()` wires them; it accepts a platform, a recipient source and a clock for tests.
`trustCircleProviders()` must be above it in the tree when the default recipient source is used.

## Honest wording

`sent` is shown as "entregado a la red del operador", never as delivered to the person. The limits
(events take minutes, the phone maker may stop the app, SIM balance, Google Play services) are
shown in the first onboarding step and on the hub. Every SMS-sending action asks for a
confirmation that says it is a real SMS.

## Known gaps

- The contract has no history call in v1 (`getEvents` is optional): the hub shows the events
  received while the app is alive plus the last one native stored.
- End-to-end behavior (real exits, the countdown and a real SMS) needs the Kotlin side and a
  physical device; only the Dart side is covered by tests (fake platform used only in tests).
