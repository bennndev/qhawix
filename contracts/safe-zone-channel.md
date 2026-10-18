# Safe-zone platform channel contract (v1)

> **Status (2026-10-17): the Kotlin engine described below was dropped.** The owner decided everything is Flutter with pub.dev packages and no custom Kotlin. What survives of this document is the **behavior**: the config object, the rule semantics, the method names (as the Dart `SafeZonePlatform` port in `ui/lib/features/refuge/domain/`), the event types and the limits. The MethodChannel and EventChannel transport, and the "small native PIN screen", are replaced by an adapter over packages (see `spikes/safe_zone/RESULTS.md` for what was proven on a real phone and what an OEM can block). The Dart adapter in `ui/lib/features/refuge/data/method_channel_safe_zone_platform.dart` targets the old channel and is a placeholder until that adapter exists.

Originally the single source of truth between the Flutter side (`ui/lib/features/refuge/`) and an Android side (Kotlin, `ui/android/`). Change it only by editing this file.

## What the feature does
The person defines a **home zone** (a circle) and an **alert window** (hours of the day). While monitoring is on, Android watches the zone in the background. When the person is **away from home during the window**, QHAWIX sends an **SMS to the chosen recipients by itself**, even if the app is closed. A cancellable countdown before sending is optional. Nothing is simulated: tests send real SMS and say so.

## Channels
- `MethodChannel("qhawix/safe_zone")`
- `EventChannel("qhawix/safe_zone/events")` (native to Dart, one JSON map per event)

All payloads are JSON-compatible maps. Times are milliseconds since epoch (UTC) unless stated. Minutes of the day are integers 0..1439 in the device's local time zone.

## Config object
```
{
  "monitoringEnabled": bool,
  "ownerName": string,            // 1..60 chars; shown in the fixed suffix of the SMS
  "home": { "lat": double, "lng": double },
  "radiusMeters": int,            // 100..5000. Below 100 the GPS error causes false alarms.
  "windowStartMinute": int,       // alert window start, local time
  "windowEndMinute": int,         // alert window end; may be smaller than start (crosses midnight)
  "mode": "awayDuringWindow" | "awayAnytime",   // default awayDuringWindow
  "minAwayMinutes": int,          // 0..60, default 5: alert only if still outside after N minutes
  "countdownSeconds": int,        // 0 = send immediately, else 15..300, default 60
  "dailyLimit": int,              // max alert episodes per day, 1..10, default 2
  "message": string,              // user text, 1..300 chars
  "recipients": [ { "name": string, "phone": string } ]   // 1..10, phone in E.164 or local digits
}
```
Validation (native rejects with `PlatformException(code: "invalid_config", message: <reason>)`): ranges above; at least one recipient while `monitoringEnabled` is true; `countdownSeconds > 0` requires a cancel PIN to be set (see `setCancelPin`).

## Rule semantics (pure logic, unit tested on both sides where it applies)
- The zone is a geofence on `home` with `radiusMeters`. Native keeps `awaySince` (set on EXIT, cleared on ENTER).
- `awayDuringWindow`: an alert **episode** starts when the person is outside the zone **and** local time is inside the window **and** they have been outside for at least `minAwayMinutes` (confirmed with a fresh one-shot location). If they left before the window opens, the check runs again **when the window opens** (schedule an alarm at `windowStartMinute`).
- `awayAnytime`: same, ignoring the window.
- One alert **per away episode**: after sending, nothing else is sent until the person re-enters the zone. At most `dailyLimit` episodes per local day; extra ones are suppressed and reported as an event.
- Window helper: `inWindow(minuteOfDay)` is true when `start <= m < end` if `start < end`, or `m >= start || m < end` if `start > end`. `start == end` means "always" and the UI must not offer it for `awayDuringWindow`.
- After a device reboot, monitoring is re-registered from the stored config (boot receiver).

## Methods (Dart calls native)
| Method | Arguments | Result |
| --- | --- | --- |
| `getStatus` | none | `{ monitoring: bool, playServicesAvailable: bool, permissions: { fineLocation, backgroundLocation, sendSms, notifications, batteryOptimizationIgnored: bool }, awaySinceMillis: int?, sentTodayEpisodes: int, lastEvent: Event? }` |
| `saveConfig` | Config | `{ ok: true }` (stores it; applies it if `monitoringEnabled`) |
| `loadConfig` | none | Config or `null` |
| `startMonitoring` | none | `{ ok: true }`; fails with `permission_missing` (message lists the missing ones) or `unavailable` |
| `stopMonitoring` | none | `{ ok: true }` |
| `requestPermission` | `{ kind: "fineLocation" \| "backgroundLocation" \| "sendSms" \| "notifications" \| "batteryOptimization" }` | `{ result: "granted" \| "denied" \| "opened_settings" }`. `backgroundLocation` needs `fineLocation` first; on Android 11+ it is granted from the system settings page, so native opens it and returns `opened_settings`; Dart re-reads `getStatus` when the app resumes. `batteryOptimization` opens the system screen for the ignore-battery-optimizations request. |
| `setCancelPin` | `{ pin: string }` (4..8 digits) | `{ ok: true }`. Native stores only a salted hash. |
| `hasCancelPin` | none | `{ set: bool }` |
| `currentLocation` | none | `{ lat, lng, accuracyMeters }` or error `permission_missing` (used to set home with "Usar mi ubicación actual") |
| `pickContact` | none | `{ name: string, phone: string }` or `null` if cancelled. Uses the system contact picker; the app holds no contacts permission. |
| `sendTestMessage` | `{ prefix: "Prueba" }` | Sends a **real SMS** to every recipient of the stored config through the same code path as an alert, text prefixed with "Prueba: ". Result `{ results: [ { phone, outcome: "sent" \| "permission_denied" \| "failed", detail } ] }`. `sent` means handed to the radio, not delivered. |
| `runEndToEndTest` | none | Runs the **full pipeline** (countdown with notification and PIN cancel, then SMS) as if an exit had just been confirmed, bypassing the zone and window checks but not the daily limit. Events are marked `test: true`. Real SMS. |
| `cancelCountdown` | none | `{ ok: bool }` (the Dart side normally never needs it; the notification action does the work) |

Errors are `PlatformException` with codes `invalid_config`, `permission_missing`, `unavailable`, `invalid_argument`, `failed`.

## Alert message sent
`<config.message>` + a fixed, non-removable suffix added by native: ` — Mensaje automático de QHAWIX enviado desde el celular de <owner>.` (the owner name is stored with the config as `ownerName`, a required string in Config, 1..60 chars). Long texts use `SmsManager.divideMessage`. Test messages are prefixed `Prueba: `.

## Countdown and cancel
If `countdownSeconds > 0`: a notification with a **neutral title ("QHAWIX")** and a Cancel action; the action opens a small native PIN screen; a correct PIN cancels (event `countdown_cancelled`), a wrong one does not. When the countdown ends without a correct PIN, the SMS is sent. The notification text must not reveal the reason to a bystander beyond a neutral phrase.

## Events (native to Dart)
Each event: `{ type: string, atMillis: int, test: bool, detail: string? }`.
Types: `monitoring_started`, `monitoring_stopped`, `exit_detected`, `entered_home`, `window_opened_while_away`, `away_confirmed`, `suppressed_outside_window`, `suppressed_daily_limit`, `suppressed_already_alerted`, `countdown_started`, `countdown_cancelled`, `sms_sent`, `sms_failed`, `permission_lost`.
Native also persists the last 50 events so `getStatus.lastEvent` and a history call are possible after a restart (`getEvents` is optional in v1).

## Storage and privacy
Config, away state, the PIN hash and the event log live only on the device (native private storage). No location is ever sent to a server by this feature. Recipients' phone numbers never leave the device except as the SMS destination.

## Permissions the Android side declares
`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`, `SEND_SMS`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, and whatever the exact-alarm or battery-optimization request strictly needs (justify each in a comment). Google Play restricts the SMS and background-location permissions; QHAWIX is distributed as a signed APK outside Play for now.

## Known limits to show to the person
Events can take minutes to arrive; the system or the phone maker may stop the app; it needs balance on the SIM; it needs Google Play services for geofencing; `sent` is not `delivered`.
