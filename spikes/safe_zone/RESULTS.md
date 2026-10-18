# Safe-zone spike: results

Date: 2026-10-17. Spike app: `spikes/safe_zone/` (package `pe.qhawix.spike`, Android only).

## Status in one paragraph

Device phase run on 2026-10-17 on the real phone: **HONOR RMO-NX3 (model RMO_NX3), MagicOS 7.1.0, Android 13 (SDK 33)**, dual SIM (slot 0 in service on Claro, slot 1 out of service), Google Play services present, serial `AWYRVB3A27001174`. The APK was built with `--dart-define-from-file=spike.local.json` and installed over adb. Recipient: "the owner second phone" (number never logged or written here). **Real SMS sent: 3** (limit 6): two from Q8 (the UI button fired twice, once by an automation slip) and one from Q1. All messages start with `Prueba QHAWIX:`.

Headline results: SMS from the UI isolate works with `SENT` and `DELIVERED` (Q8). **A real SMS was sent from an alarm callback with the process killed (Q1 pass), but only the first alarm after a fresh install ever ran: every later alarm fired at OS level and its broadcast was dropped by the Honor startup manager** (details below, root cause unverified). The geofence registered and its ENTER callback ran, so the wiring is proven; delivery with a dead process is not yet proven. No custom Kotlin was written.

| Item | State |
| --- | --- |
| `flutter analyze` | 2 `info` lints only, no errors |
| `flutter test` | 1 test passes |
| `flutter build apk --debug` | OK (151 MB, debug) |
| Custom Kotlin written | None. Only `MainActivity.kt` from `flutter create` (unchanged) |
| Real SMS sent | 3 of 6 |

## Package versions (all verified on pub.dev API and in the pub cache)

| Package | Version | Published | License (LICENSE file read) |
| --- | --- | --- | --- |
| `native_geofence` | 1.3.1 | 2026-06-10 | MIT (Chunky Tofu Studios LLC) |
| `another_telephony` | 0.4.1 | 2025-04-11 | MIT (copyright Shounak Mulay, original author; fork) |
| `geolocator` | 14.1.1 | 2026-09-27 | MIT (Baseflow) |
| `android_alarm_manager_plus` | 5.1.2 | 2026-10-01 | BSD-3-Clause (Chromium Authors text) |
| `flutter_local_notifications` | 22.3.2 | 2026-10-12 | BSD-3-Clause (Michael Bui) |
| `permission_handler` | 13.0.2 (+ `permission_handler_android` pinned **13.0.1**, see below) | 2026-09-04 | MIT (Baseflow) |
| `flutter_native_contact_picker` | 0.0.12 | 2026-04-27 | BSD-3-Clause (Jayesh Pansheriya) |
| `path_provider` | 2.1.6 | 2026-06-15 | BSD-3-Clause (Flutter Authors) |

License findings: the five that the report left `unverified` are now verified (`flutter_local_notifications` BSD-3, `permission_handler` MIT, `geolocator` MIT, plus `path_provider` BSD-3; `flutter_secure_storage` and `cryptography` were out of scope). All permissive, no cost, no copyleft. Persistence choice: a **plain file** (`getApplicationSupportDirectory()/spike_log.txt`, append with flush) instead of `shared_preferences`, because each Dart isolate keeps its own SharedPreferences cache, so a value written by the UI isolate is not seen by a background isolate unless `reload()` is called; a file append is visible to every isolate immediately.

## Q1 to Q8

| Q | Verdict | Evidence |
| --- | --- | --- |
| Q1 Alarm to SMS, process dead | **Partial (pass once, then blocked by the OEM)** | First alarm after install, with `am kill` verified (`pidof` empty before the alarm; pid changed from 27733 to 27958; no `app_start` line, so the UI never ran): `20:41:35 q1_alarm_scheduled ok=true in=60s`, `20:42:37.745 alarm_fired id=1`, `20:42:37.903 sms_attempt tag=Q1 alarm perm_sms=PermissionStatus.granted`, `20:42:39.929 sms_status SENT`, `20:42:40.293 sms_status DELIVERED`. `DELIVERED` arrived because the process stayed up through the 20 s grace period. Fired 2 s late (due 20:42:35). **`am force-stop` comparison:** `dumpsys alarm` listed 5 entries for the package before and **0 right after `am force-stop`**; the 60 s alarm never fired (no log line, no SMS). This is the documented Android limit: a force-stopped app loses its alarms (and geofences) until the person opens it again. See "Alarm delivery finding" below for the failures of later alarms. |
| Q2 Geofence exit, process dead | **Partial** | Registered a 100 m circle at the phone position: `20:53:13 geofence_registered ... r=100.0` then `20:53:14.679 geofence event=enter loc=Location(<redacted>) ids=spike_home`. The ENTER arrived about 1.1 s after registration through `NativeGeofenceBroadcastReceiver` into the Dart callback, and the log write worked. **Not proven with a dead process:** in the race test (`am kill` the instant `geofence_registered` was logged) the UI process was in the foreground and was not killed (`am kill` only kills background processes; pid unchanged; no `Start proc ... for broadcast`). A second attempt with `run-as ... kill -9` failed (`unknown pid`), and re-registering the same fence did not re-fire an initial ENTER. The exit, the SMS from the geofence isolate and dead-process delivery stay in the owner checklist. |
| Q3 Reboot | **Untested (`adb reboot` not allowed)** | Static only, see the BOOT_COMPLETED note below. |
| Q4 Countdown with Cancel | **Untested** | Left for the owner: the countdown ends in an alarm, and alarm delivery was unreliable on this phone (Q1 finding), so a UI-automation run would not be conclusive. Nothing is known about the PIN screen over a locked phone. |
| Q5 Permissions flow | **Partial** | `adb shell pm grant` worked for `ACCESS_FINE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`, `SEND_SMS` and `POST_NOTIFICATIONS` on a fresh install (all `granted=true` in `dumpsys package`; `ACCESS_COARSE_LOCATION` stays false because only fine was granted). Before any grant, `dumpsys` showed `SEND_SMS` and `ACCESS_BACKGROUND_LOCATION` with the flag **`RESTRICTION_INSTALLER_EXEMPT`**: apps installed through adb are exempt from restricted settings, so **no "restricted settings" prompt appeared for this install method** (Android 15 and a sideload through a browser or file manager remain untested). The in-app `permission_handler` dialogs (step count, background-location settings page) were **not exercised**: owner checklist item 1. The battery exemption can be set by adb (`cmd deviceidle whitelist +pe.qhawix.spike`): it moved the standby bucket from 10 (active) to 5 (exempted) but did not fix alarm delivery. |
| Q6 Contact picker, no permission | **Partial (pass for the permission part)** | The system picker opened (`com.hihonor.contacts/ContactSelectionActivity`) while the app holds no contacts permission. The `dumpsys package pe.qhawix.spike` grep for `READ_CONTACTS` and `READ_SMS` printed nothing (grep exit 1): neither is declared nor granted. The phone's contact list is empty, so no contact could be chosen and the app logged `q6_contact_picked null`. The owner must pick a real contact to see the returned name and number. |
| Q7 One-shot location in a background isolate | **Pass (once)** | After a fresh install and `am kill`: `20:48:11 q7_alarm_scheduled in=15s`, `20:48:28.645 alarm_fired id=2`, `20:48:28.828 loc_try tag=Q7 alarm isolate service=true perm=LocationPermission.always`, `20:48:28.979 loc_ok tag=Q7 alarm isolate lat/lng=<redacted> acc=20.0m`. 150 ms from callback to fix (a cached location was probably available). `getCurrentPosition` works in the alarm isolate with background location granted. Not tested in the geofence isolate. |
| Q8 SMS status in UI / background, dual SIM | **Pass (UI and alarm isolate)** | UI: `20:40:12.121 q8_ui_send`, `20:40:14.511 sms_status SENT`, `20:40:14.958 sms_status DELIVERED` (repeated 20:40:18 to 20:40:20). Alarm isolate: `SENT` and `DELIVERED` logged too (Q1 lines above). Dual SIM: the SMS goes out on the default SMS subscription (`subscriptionId = -1`); the plugin has no API to list SIMs or to ask which to use, so the person gets no choice. Slot 1 was out of service, so a send from a no-service SIM was not exercised. Note: every isolate reports the name `main` (`Isolate.current.debugName`), so isolates were told apart by pid and by the absence of `app_start`. |

### Alarm delivery finding (real, root cause unverified)

Observed on this Honor phone: after the Q1 force-stop run, **five Q7 alarms were scheduled (20:45:09, 20:46:45, 20:49:14, 20:50:34, 20:51:43) and none ran its callback**: no log line, no location. The first alarm after a fresh install ran both times (Q1 at 20:42; Q7 after `adb uninstall` and reinstall at 20:48:28), so the first Q7 run looked fine.

Evidence:
- The alarms were **not dropped** by AlarmManager: `dumpsys alarm` for the package reports `4 wakeups` and `last -2m12s`, and logcat shows `W/AlarmManager: WAKEUP alarm ... pkg: pe.qhawix.spike ... AlarmBroadcastReceiver` at each due time.
- In the failing cases the broadcast was swallowed at once: `HwMtmBroadcastResourceManager: iaware_brjob not process: ResolveInfo{... AlarmBroadcastReceiver}`, `StartupByBroadcastRecorder: iaware_brjob record startup time error`, `BroadcastQueue: Finished with ordered broadcast` within about 3 ms, and **no `Start proc ... for broadcast`**. In the working case logcat has `Start proc 29972:pe.qhawix.spike/u0a571 for broadcast {...AlarmBroadcastReceiver}`.
- Not the standby bucket (`am get-standby-bucket` = 10, active) and not Doze (`mState=ACTIVE`). Exempting the app from battery optimization (deviceidle whitelist, bucket 5) and retesting (20:51:43) still failed. No `adb shell dumpsys alarm` entry was left pending: alarms had fired.
- The phone is an HONOR with MagicOS 7.1 (log tags `HnAlarmManagerService`, `iaware`, `SWAP_*`, `com.hihonor.*`).

Best explanation (**unverified**): the Honor/Huawei startup-by-broadcast manager refuses to start a killed app's process for a background broadcast once the app has been killed or force-stopped, unless the person allows auto-launch for it; a fresh install is allowed once. To confirm, the owner should open Settings > Apps > App launch for the spike, switch to manual management and allow auto-launch, secondary launch and run in background, then repeat Q1. If it then works, the product needs a guided "allow auto-start" step per manufacturer, and this phone is not an "it just works" case.

Geofencing also delivers through a `PendingIntent` broadcast, so dead-process geofence delivery is at risk from the same OEM block until the owner tests it.

## Build and manifest findings (these are real, verified by building)

1. **`permission_handler` 13.0.2 does not build on Flutter 3.41.6 / AGP 8.11 as resolved.** It pulls `permission_handler_android` **14.1.0**, whose `android/build.gradle.kts` hard-codes `com.android.tools.build:gradle:9.0.1`, a `kotlin { compilerOptions }` block that only compiles with AGP 9 built-in Kotlin, and (14.0.0 changelog) requires `compileSdk 37`. Error: `Script compilation errors ... Unresolved reference: compilerOptions`. **Workaround used:** `dependency_overrides: permission_handler_android: 13.0.1` in the spike `pubspec.yaml`. For the real app, decide between pinning 13.0.1 or moving the toolchain to AGP 9. 14.1.0 also changes `Permission.status` so it never returns `permanentlyDenied` on Android.
2. **`flutter_local_notifications` 22.3.2 needs core library desugaring** (`isCoreLibraryDesugaringEnabled = true` and `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")` in `android/app/build.gradle.kts`). It is Gradle configuration, not native code.
3. The first build takes about 3 minutes; the debug APK is 151 MB.
4. `native_geofence` README says the app needs minSdk 23; `flutter.minSdkVersion` satisfied it.

Permissions in the merged manifest: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`, `SEND_SMS`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`, `USE_EXACT_ALARM`, `SCHEDULE_EXACT_ALARM`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, plus plugin or tooling additions `FOREGROUND_SERVICE`, `VIBRATE`, `ACCESS_NETWORK_STATE`, and `INTERNET` (debug build only). Not declared: `READ_SMS`, `READ_CONTACTS`, `READ_PHONE_STATE`, accessibility.

Components added: services `NativeGeofenceForegroundService`, `AlarmService`, `GeolocatorLocationService`, and WorkManager services (`SystemAlarmService`, `SystemJobService`, `SystemForegroundService`) that arrive transitively; receivers `NativeGeofenceBroadcastReceiver`, `NativeGeofenceRebootBroadcastReceiver`, `AlarmBroadcastReceiver`, `RebootBroadcastReceiver`, WorkManager proxies. The geofence and alarm entries are copied from the plugin READMEs into the app manifest; the notification plugin needed no manifest entries for an action that opens the UI. `GoogleApiActivity` comes from Play services (geofencing needs Play services).

Note on the spec: `SCHEDULE_EXACT_ALARM` is denied by default since Android 14; `USE_EXACT_ALARM` is auto-granted but restricted by Play policy (acceptable for the sideloaded APK).

### BOOT_COMPLETED and direct boot (Q3 note)

Both plugins re-register from a `BOOT_COMPLETED` receiver only. Neither plugin's Android sources (grep of both `android/` folders returned nothing) nor the app manifest contain `LOCKED_BOOT_COMPLETED`, and the two receivers are not `directBootAware`. **LOCKED_BOOT_COMPLETED is therefore not handled.** On a device with credential-encrypted storage `BOOT_COMPLETED` is delivered only **after the first unlock** following a reboot, so after a restart nothing is re-registered, and no safe-zone alert can fire, until the person unlocks the phone once. This is a user-visible limit to document. The owner's reboot test should confirm it by comparing the re-registration timestamp in the log with the unlock time.

## What only the owner can test (numbered checklist)

The phone is already set up (app installed, permissions granted by adb). Keep the log open: `adb shell run-as pe.qhawix.spike cat files/spike_log.txt`.

0. **First, fix the OEM block (Honor/MagicOS):** Settings > Apps > App launch > the spike > manual management, allow auto-launch, secondary launch and run in background. Then press "Q7 alarma 15 s", HOME, `adb shell am kill pe.qhawix.spike`, and check that `alarm_fired id=2` appears. Do it twice in a row: only the first run ever worked before the change.
1. Q5: uninstall and reinstall (no `pm grant`), press "Pedir todos en orden", and note every dialog, the number of taps, and where background location sends you (Settings page).
2. Q1 (only after item 0 works twice): "Q1 alarma 60 s", HOME, `am kill`; expect `alarm_fired id=1`, `sms_status SENT` (one real SMS). Do not use `force-stop` (documented to cancel alarms).
3. Q2: "Registrar geocerca" (radius 100), press HOME, `am kill`, then walk more than about 150 m away and wait; expect `geofence event=exit` with its timestamp (measure the delay from when you crossed the line), `loc_ok` and `sms_status SENT` (one real SMS). Walk back: expect `enter`. If nothing arrives with the app killed, the same OEM block is the first suspect.
4. Q3: with the geofence registered and the "Q3 alarma 10 min" scheduled, run `adb reboot`, **do not open the app, unlock the phone once**, wait 3 minutes and read the log: expect a post-unlock `geofence event=enter` and `reboot_alarm_ok`. Also leave a second reboot locked (do not unlock) for 5 minutes and confirm nothing is logged until the first unlock.
5. Q4: "Q4 cuenta regresiva", lock the phone, tap Cancelar on the lock screen notification. Record whether the PIN screen shows over the lock screen or only after unlocking. PIN `1234`: expect `countdown_cancelled_by_pin` and no SMS. Repeat without tapping: expect `countdown_end_sending`. Repeat with the app killed before tapping Cancelar.
6. Q6: add one contact to the phone, press "Q6 elegir contacto", pick it, and note what the screen shows (name and number). Re-run `adb shell dumpsys package pe.qhawix.spike | grep -E "READ_CONTACTS|READ_SMS"`: expect no output.
7. Optional: repeat item 2 on a Samsung or Pixel phone to separate OEM behavior from plugin behavior.

SMS budget used so far: 3 of 6. Items 2 and 3 need one real SMS each; item 5 needs one more.

## Recommendation

**Go with changes, conditional on the OEM auto-launch test (checklist item 0).** What the device phase established: the Flutter-only stack builds and runs; SMS sending from Dart works with `SENT` and `DELIVERED` (Q8), also from a headless alarm callback with the app killed (Q1, once); `getCurrentPosition` works in a background isolate (Q7); geofence registration and the callback wiring work (Q2, ENTER); no custom Kotlin was needed.

What is not proven and could force a change: **background delivery after the first kill on this Honor phone.** Alarms were not dropped by Android but the Honor startup manager refused to start the process for the broadcast, which is an OEM policy, not a plugin bug, and it affects every Flutter plugin (and the paid `flutter_background_geolocation` too, because it also needs a process start from a system broadcast). If the owner's item 0 fixes it, keep these packages and add a guided per-manufacturer "allow auto-start" step plus the battery-optimization request; if it does not, **Q1/Q2 dead-process delivery on Honor is the question that would force a fallback**, and the realistic fallback is a foreground service started by the person (visible notification), not the paid plugin. Other changes needed regardless: pin `permission_handler_android` 13.0.1 (or move to AGP 9), enable core library desugaring, handle that nothing re-registers after a reboot until the first unlock (`BOOT_COMPLETED` only), accept that `force-stop` cancels alarms and geofences until the app is opened again (document it), and plan that the person cannot choose a SIM on a dual-SIM phone with `another_telephony`.
