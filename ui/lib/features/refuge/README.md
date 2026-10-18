# Refuge (Refugio): safe-zone alerts

Flutter side of `contracts/safe-zone-channel.md`. The person defines a home zone and an alert
window; while monitoring runs, Android sends an **SMS by itself** to the chosen recipients when
they are away from home during the window. **Everything here is real**: tests and alerts send
real SMS. Nothing is mocked in the app.

Implemented with pub.dev packages (`PackagesSafeZonePlatform`): `native_geofence`,
`another_telephony`, `geolocator`, `android_alarm_manager_plus`, `flutter_local_notifications`,
`permission_handler`, `flutter_secure_storage`, `cryptography`. Spike verdict: **GO WITH CHANGES**
(Honor needs guided OEM auto-start). See `spikes/safe_zone/RESULTS.md`.

Run it on a phone from `ui/` (real SMS):

```
flutter run -t lib/dev/safe_zone_demo_main.dart
```

> **Demo recipients:** `safe_zone_demo_main.dart` injects the Trust Circle **mock** so the wizard
> has sample contacts. The main app uses the on-device Trust Circle store; pick real contacts there
> before enabling monitoring.

## Screens

| Screen | File | Reached from |
| --- | --- | --- |
| Hub (`RefugeScreen`): monitoring state, permission health, config summary, event history, tests, stop | `view/refuge_screen.dart` | module entry |
| Onboarding wizard, 8 steps (… permissions, **inicio automático**, review) | `view/safe_zone_onboarding_screen.dart`, `view/onboarding_steps.dart` | hub when nothing is configured; hub "Editar ..." opens it at that step |
| One permission rationale at a time | `core/widgets/permission_rationale_screen.dart` (reused) | wizard and hub |

If nothing is configured, `RefugeScreen` shows the wizard. Off Android it says the feature is not
available on this device.

## Layers

`domain/` (pure Dart: `SafeZoneConfig`, `SafeZoneEngine` episode rules, ports) ->
`data/` (`PackagesSafeZonePlatform`, `SafeZoneFileStore`, `safe_zone_background.dart` entry
points, `SafeZoneMapper`, `TrustCircleRecipientSource`; `MethodChannelSafeZonePlatform` kept only
for legacy channel tests) -> `viewmodel/` -> `view/`.

`refugeProviders()` defaults to the package adapter; tests inject `FakeSafeZonePlatform`.

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
