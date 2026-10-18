# QHAWIX safe-zone spike

Standalone Flutter app (package `pe.qhawix.spike`, Android only) that tests the Flutter-only
approach for the safe-zone SMS alerts. It is isolated from `ui/`. See `RESULTS.md`.

Every button marked "SMS REAL" sends a real text message from the phone's SIM.

```
flutter pub get
# optional: copy spike.local.example.json to spike.local.json (gitignored) and set SPIKE_NUMBER
flutter run -d <device> --dart-define-from-file=spike.local.json
# or: flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

The recipient number can also be typed on the screen. Log file on device:
`adb shell run-as pe.qhawix.spike cat files/spike_log.txt`
