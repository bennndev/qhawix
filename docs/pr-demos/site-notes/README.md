# Personal site notes demo

Real QHAWIX Flutter UI, recorded 2026-10-21. Synthetic account and local fake auth, quota and Atomic Memory services; the backend executes the committed handler with its test fixtures. No cloud project or Android device was used.

The 20-second video shows manual QR content review, explicit consent to send the normalized hostname, saving a note with its code redacted, and confirmed deletion. The security verdict stays “No verificado”; the note never unlocks opening the URL. The displayed saved timestamp comes from the fixture.

For recording only, a temporary copy of the Android app gained Flutter web scaffolding. Its reputation provider used the existing UnconfiguredQrReputationRepository because the native Web Risk client uses dart:io HttpClient, unavailable on web. No note-feature code was substituted. This is a developer web preview, not native Android verification.

Validation: 508 Flutter tests, Dart analysis, 20 Deno handler tests, Deno checks/lint/format. The local Supabase pgTAP quota test and native Android device verification remain to be run by maintainers before enabling this optional feature. It is off by default.

Files: screenshot.png, demo.gif and demo.mp4. Backend fixtures: api/supabase/functions/qr-site-notes/test_fixtures.ts. Handler tests: api/supabase/functions/qr-site-notes/handler_test.ts. Flutter build defines for a local preview are SUPABASE_URL=http://127.0.0.1:4605, SUPABASE_ANON_KEY=local-demo-anon-not-a-secret and QR_SITE_NOTES_ENABLED=true. Never use a production project for the fake-provider demo.
