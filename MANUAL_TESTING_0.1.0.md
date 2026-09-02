# Holos Music 0.1.0 — manual review

Status: APK built successfully; user acceptance pending.

Logo update: supplied HolosMusicApplogo.png integrated into launcher/adaptive icons,
splash, header and credits. Updated debug APK built successfully in session 51076.
Visual acceptance on the user's device/emulator is pending.

APK: [app-debug.apk](app/build/app/outputs/flutter-apk/app-debug.apk)
Package: `org.holosmusic.holos_music`; version `0.1.0` / code `1`.
Minimum Android: 7.0 (API 24). This is a development/debug build, not a public release.

Transfer the APK to your phone, open it, and allow installation from that source
if Android prompts. No USB connection is needed for this manual installation.

## Check on your phone

- [ ] Install and launch; the empty player appears without crashing.
- [ ] Verify the supplied Holos logo in the launcher, startup screen, app header
  and Licenses and credits page after installing the rebuilt APK.
- [ ] Open a local 16-bit FLAC; confirm title/artist (or sensible fallbacks) and duration.
- [ ] Verify audible playback, pause/resume and seeking near the beginning/middle/end.
- [ ] Let a track finish; use Replay to start it again.
- [ ] Open a 24-bit FLAC if available; confirm playback and reported file properties.
- [ ] Select another file and cancel; the existing track remains available.
- [ ] Try a non-FLAC or corrupt test file; confirm a recoverable message and that a
  valid FLAC can subsequently be opened. Use disposable files for error testing.
- [ ] Leave the app and return; playback should pause, with no automatic restart.
- [ ] Try the screen with your normal text size and larger text; controls remain reachable.
- [ ] Open Licenses and credits; confirm the page is available.

Expected limits: one file at a time, foreground playback only, placeholder artwork,
no library/queue/background controls yet. Reopening after process death starts empty.
Audio information describes the file, not verified bit-perfect device output.

## Report results

Send your phone model, Android version, which checks failed, and the exact message
or short reproduction steps. A screenshot is useful for visual problems. Full logs
are unnecessary unless requested. Say explicitly when you accept this version.

## Automated evidence

- Flutter static analysis: passed.
- Flutter controller/widget tests: 12 passed (fake audio engines).
- Compiled Kotlin FLAC STREAMINFO parser checks: 6 passed through a local runner.
- Android debug APK compilation: passed, build session 58585.
- No device playback test or user acceptance claimed.

APK SHA-256:
`04D7F43FC4F9DC2616C238BD1A5F3B29CB8151CFC1D833D3CD21EA0E57A76496`
