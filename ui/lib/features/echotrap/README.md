# EchoTrap

EchoTrap is an isolated QHAWIX module. The application shell, other modules, and global startup are not part of this feature.

## What it does

- Opens Android's regular phone dialer for outgoing calls. The person confirms the call there.
- Saves the owner's EchoTrap number in their authenticated profile and keeps manually added contacts in encrypted local storage.
- Offers Android's call-screening role for incoming calls. Android only supplies visible numbers not already in the phone's address book; EchoTrap does not request access to that address book. It compares received numbers with EchoTrap contacts, warns about unmatched numbers, and allows every call without calling unknown numbers spam.
- After the person returns to EchoTrap, activates speakerphone, gives microphone permission, and starts visible capture, it checks short microphone windows. A local voice-activity gate avoids sending silence. Deepgram transcribes the windows, local rules look for risky requests, and TruthScan checks the first ten seconds for synthetic-audio signs.
- When the conversation mentions a supported bank, including Banco de la Nación, and the person separately consents to source lookup, it searches Exa results limited to official bank and Peruvian public-authority domains. The query contains only the bank name, never the audio or transcript. If `APIFY_API_TOKEN` is configured, Apify fetches up to three matching official pages to provide a fuller excerpt; Exa's excerpt is the fallback. The screen presents links, dates and excerpts as source material. These results do not verify the caller or prove wrongdoing.
- Red and yellow findings create a high-priority notification with vibration when Android notifications are enabled. Warnings can also be spoken by the phone's text-to-speech. Android does not route that speech into the cellular call as a controllable agent voice.

## Platform boundary

Android third-party apps cannot take the audio path of another app's carrier call. `CallScreeningService` receives number and call metadata before the call rings, but not audio; it can allow, reject, or silence. Android does not deliver hidden/restricted numbers or numbers already in the phone's address book unless the app requests broader contact access; EchoTrap does not request that access. EchoTrap only allows calls. The microphone foreground service is separate and may receive silence while a cellular call is active, depending on Android version and device. The UI reports that condition instead of treating it as a safe result.

Answering an unknown carrier call as a voice agent and recording its message is not available to this app. That requires a carrier forwarding arrangement and an inbound phone number connected to QHAWIX's call service. The existing LiveKit SIP address is a service endpoint, not a phone number; no carrier number or trunk is configured here. No fake agent, recording or answer state is shown. LiveKit's docs confirm that PSTN calls require a number and SIP provider, while its direct phone-number inventory is currently for US numbers: https://docs.livekit.io/telephony/start/sip-trunk-setup/ and https://docs.livekit.io/telephony/start/phone-numbers/.

## Configuration

The Flutter app needs only the Supabase project URL and its public publishable key at build time:

```powershell
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLIC_PUBLISHABLE_KEY
```

Set these provider secrets on the Supabase project (or in a local ignored env file):

- `DEEPGRAM_API_KEY`
- `TRUTHSCAN_API_KEY`
- `EXA_API_KEY`
- `APIFY_API_TOKEN` (optional; retrieves limited excerpts from up to three already-verified official results)

The functions also need Supabase's `SUPABASE_URL` and `SUPABASE_ANON_KEY` runtime values to validate the signed-in user. Never put provider keys or a Supabase secret/service-role key in Flutter. The API keys pasted into the chat were exposed; generate replacements before configuring or deploying them.

Only the person who signs in can call the functions. Audio is processed ephemerally by QHAWIX and is not written to its database or files; the chosen providers receive the permitted audio. Review their current retention terms before production use. Provider failure produces an unverifiable result.

## Build and local backend

Use the repository's Flutter checks from `ui/`. For local functions, copy `api/supabase/.env.echotrap.example` to `api/supabase/.env.echotrap.local`, put newly rotated keys there, start Supabase from `api/`, and serve functions with `npx supabase functions serve --env-file supabase/.env.echotrap.local`. Remote deployment requires selecting and linking the intended Supabase project first.

For a phone UI preview without Supabase credentials, build a debug APK with `--dart-define=ECHOTRAP_PREVIEW=true`. The preview opens the dialer, contact list, and protection screen. Audio analysis remains disabled, and the preview flag does not bypass sign-in in release builds.
