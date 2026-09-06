# Holos Music 0.2.0 — local library manual review

Status: implemented; static analysis, 22 Flutter tests and Android debug APK build passed.
User manual acceptance pending. Flutter tests use fake platform/audio services;
real folder permissions, persistence and decoding still need your device review.
Package remains org.holosmusic.holos_music; version 0.2.0 / code 2.

APK: [Holos-Music-v0.2.0-debug.apk](app/build/app/outputs/flutter-apk/Holos-Music-v0.2.0-debug.apk)
Minimum Android: 7.0 (API 24). Install over 0.1.0 using the same debug signing key.
This universal debug APK is approximately 163.2 MiB.

SHA-256: `2791B0BA53BD482E1C019EE81B8BBA6A945D7A57C73E838B1A33C0040E56B5FB`

## Check on your Android device/emulator

- [ ] Update over 0.1.0 and launch; the library home screen and Now playing action appear.
- [ ] Add a Music folder and accept Android's folder-access prompt. Include FLACs
  in nested folders plus a few unrelated files; only valid FLAC tracks should appear.
- [ ] Use two different files with the same filename/title in different folders;
  both should remain. Add overlapping parent/child folders; the same document
  should appear only once.
- [ ] Select a song; verify metadata, audible playback, pause/resume and seeking.
- [ ] Return to the library and select another song; no queue/autoplay-next is expected yet.
- [ ] Close/reopen the app (or stop/relaunch it); saved folder choices and tracks remain.
- [ ] Add a new FLAC to the folder, then Rescan; it appears without duplicate rows.
- [ ] Start scanning a larger folder, check progress counts and Cancel scan.
  Cancellation occurs at a file boundary; the previously saved library remains.
- [ ] Cancel the folder picker; existing library and selected folders remain intact.
- [ ] Select an empty folder or a folder with invalid/corrupt FLAC test copies;
  confirm an empty state/skipped-file message and continued responsiveness.
- [ ] Revoke/make a folder inaccessible, then reopen/rescan; cached tracks are
  unavailable with recovery instructions. Reselect the folder and scan to recover.
- [ ] Remove a folder using its remove button and confirm the dialog. It disappears
  from the library; its actual files remain on the device.
- [ ] Open Now playing and use Open FLAC file; 0.1.0 single-file functionality still works.
- [ ] Check normal/larger text, long folder/song names and scrolling.

No library operation writes tags or deletes source files. Removing a source changes
the app's metadata cache/access grants only. Background playback and queues remain
future milestones. No cloud/provider/downloader features are introduced.

Send device model, Android version, failed check and short reproduction/message.
Explicitly confirm acceptance before we advance to 0.3.0.
