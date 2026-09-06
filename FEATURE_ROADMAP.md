# Holos Music — version roadmap and progress tracker

Last updated: 2026-10-27

## Scope

An independent Android player for local FLAC files, developed through small usable
releases. Mornye supplies selected reference implementations, with appropriate
licensing and attribution. It is not the default application foundation.

Excluded: music downloading, online providers/extensions/discovery, cloud/network/
Telegram sources, online metadata/lyrics fetching, audio conversion, CUE splitting,
concert services and Discord integration. Other platforms are deferred.
Local playlist import/export is included and never downloads referenced music.

## Current progress

| Item | Current state |
| --- | --- |
| Active phase | 0.2.0 manual review pending |
| Active implementation version | 0.2.0 |
| Application implementation | 0.1.0 accepted; 0.2.0 implemented and debug APK built, user review pending |
| Versions tested / released | 0.1.0 user accepted; public release confirmation not recorded |
| Stack and architecture | Flutter, audioplayers Android fork, Kotlin local-file bridge; no Rust/WSL |
| Reference | Mornye at c90ec6478ad3e808ef22ba9464f8ad05054dde7b |
| Next task | User follows MANUAL_TESTING_0.2.0.md; fix issues before advancing |

Tools and installation results are in [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md).
Rust, WSL and Mornye's full dependency tree are conditional on selected reuse.

## Tracking rules

- `[ ]` = unfinished/unverified; `[x]` = completed with evidence.
- The user manually reviews/tests every implementation. Automated checks are
  recorded separately and do not constitute manual acceptance. Never push to
  GitHub; the user handles publishing source after review. See AGENTS.md.
- During downloads/builds requiring waiting, stop polling and hand control back
  to the user. Resume when they say continue.
- Keep task IDs stable. Update checkboxes, dashboard, evidence and next task after each session.
- Use statuses: Planned, In Progress, Implemented, Tested, Released, Deferred.
  Record a concrete reason and next action for any blocker.
- Implementation tasks need code/configuration plus focused verification. Tested
  requires the version's acceptance checks and applicable shared checks below.
  Released requires an actual distributed build; starting the next version is insufficient.
- Read this file and relevant Git changes at session start. Finish the active milestone
  before moving to another major milestone.
- Track completed tasks and tested/released milestones separately. Checkbox counts
  are not a meaningful percentage estimate because tasks differ in size.
- Create actual release history with screenshots, changelogs and source revisions.
  Do not fabricate history or delay completed work to suggest artificial progress.

## Version dashboard

| Version | Outcome | Status | Implemented | Tested | Released | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| 0.1.0 | Open/play one FLAC file | Tested | Yes | User accepted | Unconfirmed | User said done and authorized next version; detailed device/sample matrix not reported |
| 0.2.0 | Scan a local collection | Implemented | Yes | No | No | Clean analysis, 22 Flutter tests, APK build passed; user review pending |
| 0.3.0 | Queue and continuous listening | Planned | No | No | No | — |
| 0.4.0 | Background listening | Planned | No | No | No | — |
| 0.5.0 | Browse/search a larger library | Planned | No | No | No | — |
| 0.6.0 | Restore playback and favorites | Planned | No | No | No | — |
| 0.7.0 | Local playlists | Planned | No | No | No | — |
| 0.8.0 | Metadata and artwork | Planned | No | No | No | — |
| 0.9.0 | Personalization/local lyrics | Planned | No | No | No | — |
| 0.10.0 | Sound controls | Planned | No | No | No | — |
| 0.11.0 | Recovery and refinement | Planned | No | No | No | — |
| 1.0.0 | Stable local FLAC player | Planned | No | No | No | — |
| 1.1.0 | Optional statistics/Rewind | Deferred | No | No | No | — |
| 1.2.0 | Optional AutoMix | Deferred | No | No | No | — |
| 1.3.0 | Optional haptics | Deferred | No | No | No | — |
| 1.4.0 | Optional advanced USB output | Deferred | No | No | No | — |

Pre-1.0 versions are previews. Minor versions introduce coherent capabilities;
patch releases fix shipped behavior, e.g. 0.4.1. Increase Android versionCode for
every distributed build. Dates remain open until capacity and complexity are known.
Scope can change, but changes must be recorded and release gates updated explicitly.

## Preparation — before implementation

- [x] P-01: Establish workspace and project documentation.
- [x] P-02: Confirm Android as the current platform.
- [x] P-03: Confirm local FLAC player scope and exclude downloader functionality.
- [x] P-04: Clone Mornye and record the inspected revision.
- [x] P-05: Produce the source-based feature inventory.
- [x] P-06: Document version sequence and progress tracking.
- [x] P-07: Trace Mornye's minimum FLAC playback path, bridges, dependencies and tests;
  identify which pieces can be adapted independently.
- [x] P-08: Review licenses/notices for specifically selected code and assets.
- [x] P-09: Recommend the minimal Holos Music stack/architecture and obtain confirmation
  before major integration decisions; determine whether Rust/native reuse is useful.
- [x] P-10: Select/verify the build route and required tools; assess native Windows
  before requiring WSL. Record reproducible build commands.
- [x] P-11: Establish application Git repository, ignore rules and checkpoint practices;
  preserve the separate reference checkout and user changes.
- [ ] P-12: Decide application ID, supported Android versions and test devices;
  prepare an owned/licensed FLAC test collection.

Evidence: [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md),
[REPOSITORY_INVENTORY.md](REPOSITORY_INVENTORY.md),
[MORNYE_FEATURE_CATALOG.md](MORNYE_FEATURE_CATALOG.md).

## 0.1.0 — first playback

Outcome: open one FLAC file and listen inside Holos Music. Depends on preparation.

- [x] V01-01: Create minimal Android app/build configuration and player screen.
- [x] V01-02: Select a file using Android's picker; support content URIs and denied access.
- [x] V01-03: Implement FLAC playback, play/pause and seeking.
- [x] V01-04: Display title, artist when present, duration and position.
- [x] V01-05: Implement idle/loading/playing/paused/ended/error states and accessible controls.
- [x] V01-06: Add diagnostic logging suitable for playback failures.
- [x] V01-T: User accepted first playback and authorized advancement. Detailed
  device/sample results (16/24-bit, corrupt files, seeking, cancellation/access) were not supplied.
- [ ] V01-R: Complete the shared release checklist and distribute a preview APK.

Pass: accessible local FLAC plays and seeks correctly; invalid input is recoverable.
Background playback and bit-perfect output are not promised in this version.

## 0.2.0 — local library

Outcome: browse a persistent FLAC song list. Depends on tested 0.1.0.

- [x] V02-01: Select folders and persist granted folder access.
- [x] V02-02: Scan nested folders for FLAC without blocking the UI.
- [x] V02-03: Persist source identifiers and basic metadata; avoid duplicates on rescans.
- [x] V02-04: Show the library and start playback from a selected song.
- [x] V02-05: Add manual rescan, progress/cancellation, empty and permission-recovery states.
- [ ] V02-T: Test nested folders, duplicate filenames, restarts, new files and lost permissions.
- [ ] V02-R: Complete the shared release checklist.

Pass: selected folders survive restart and repeat scans accurately reflect accessible music.

## 0.3.0 — playback queue

Outcome: listen through multiple tracks. Depends on tested 0.2.0.

- [ ] V03-01: Add explicit queue/current-track state and automatic track advancement.
- [ ] V03-02: Add next/previous, play-next, append, remove and reorder actions.
- [ ] V03-03: Add shuffle and repeat off/all/one with predictable behavior.
- [ ] V03-T: Test empty/single/large queues, current-track removal, missing files,
  shuffle changes and repeat boundaries.
- [ ] V03-R: Complete the shared release checklist.

Pass: the queue, actual playback and displayed current track stay consistent.

## 0.4.0 — background listening

Outcome: listen with screen off and while using other apps. Depends on tested 0.3.0.

- [ ] V04-01: Implement Android media session/foreground playback service and relevant permissions.
- [ ] V04-02: Add notification/lock-screen metadata and controls.
- [ ] V04-03: Support headset/Bluetooth media buttons and route changes.
- [ ] V04-04: Handle audio focus, interruptions and headphone disconnects; document resume behavior.
- [ ] V04-T: Test sustained screen-off listening, app switching, locking, calls/focus loss,
  Bluetooth reconnects and service lifecycle on supported Android versions.
- [ ] V04-R: Complete the shared release checklist.

Pass: background controls and interruption behavior are reliable on real devices.

## 0.5.0 — library browsing

Outcome: find music in a larger collection. Depends on tested 0.4.0.

- [ ] V05-01: Add album, artist and folder views with consistent metadata grouping.
- [ ] V05-02: Add local search, sorting and relevant filters.
- [ ] V05-03: Reconcile moved/deleted files and provide missing-entry cleanup.
- [ ] V05-04: Keep large lists responsive; implement empty/search failure states.
- [ ] V05-T: Test missing/multiple artists, identical album titles, non-Latin text,
  renamed files and concurrent scanning/playback with a representative large library.
- [ ] V05-R: Complete the shared release checklist.

Pass: results match the library; cleanup removes stale entries without deleting music.

## 0.6.0 — everyday convenience

Outcome: resume sessions, favorite music and use a sleep timer. Depends on tested 0.5.0.

- [ ] V06-01: Persist track, queue, position, shuffle and repeat state.
- [ ] V06-02: Restore session after restart without unexpected autoplay.
- [ ] V06-03: Add persistent track/artist favorites.
- [ ] V06-04: Add sleep timer, remaining time and cancellation.
- [ ] V06-T: Test process restart, unavailable restored files, favorites across rescans
  and sleep-timer expiry with screen off.
- [ ] V06-R: Complete the shared release checklist.

Pass: saved state survives restart and unavailable files/timer expiry behave predictably.

## 0.7.0 — playlists

Outcome: organize and exchange local playlists. Depends on tested 0.6.0.

- [ ] V07-01: Create/rename/delete playlists and add/remove/reorder tracks.
- [ ] V07-02: Add custom playlist covers.
- [ ] V07-03: Import M3U/M3U8; define local-reference CSV columns if CSV is retained.
- [ ] V07-04: Export playlists with documented path/encoding rules; report unresolved
  references and never turn imported entries into download requests.
- [ ] V07-T: Test persistence, duplicates, missing tracks, malformed imports, non-Latin
  paths and export/import round trips.
- [ ] V07-R: Complete the shared release checklist.

Pass: playlist edits persist; round trips preserve resolvable tracks and order.

## 0.8.0 — metadata and maintenance

Outcome: inspect/edit FLAC tags/artwork and review duplicates. Depends on tested 0.7.0.

- [ ] V08-01: Display detailed metadata and embedded/local artwork with fallbacks.
- [ ] V08-02: Add supported tag/artwork editing with safe writes and read-only/source-access handling.
- [ ] V08-03: Refresh library/player metadata after successful edits.
- [ ] V08-04: Add explained duplicate matching/review; no automatic file deletion.
- [ ] V08-T: Read back edited tags, verify decoded audio is preserved, test interrupted/
  failed writes and duplicate false positives. Use disposable test copies.
- [ ] V08-R: Complete the shared release checklist.

Pass: edits preserve audio and the original on failure; duplicates remain non-destructive.

## 0.9.0 — personalization and local lyrics

Outcome: read local lyrics and personalize the player. Depends on tested 0.8.0.

- [ ] V09-01: Read embedded plain/synchronized lyrics and accessible sidecar LRC files.
- [ ] V09-02: Add system/light/dark/AMOLED themes and accent preferences.
- [ ] V09-03: Add selected font/layout preferences with persistence.
- [ ] V09-04: Add Android home-screen widget linked to the existing media session.
- [ ] V09-T: Test lyric seek/timing, missing/malformed lyrics, theme restoration,
  screen readers/large text and widget refresh/control after track changes/restart.
- [ ] V09-R: Complete the shared release checklist.

Pass: settings persist, timed lyrics follow playback and widgets control the same session.

## 0.10.0 — sound controls

Outcome: customize sound and inspect audio details. Depends on tested 0.9.0 and engine support.

- [ ] V10-01: Show codec/rate/depth and available route details; distinguish file
  properties from the device's actual audio output.
- [ ] V10-02: Add supported equalizer controls, presets and bypass.
- [ ] V10-03: Read ReplayGain tags and implement normalization with clipping/preamp policy;
  add track/album scanning if retained after dependency review.
- [ ] V10-04: Explain unsupported routes/effects and preserve ordinary playback.
- [ ] V10-T: Test audible effect changes, gain/clipping behavior, preset persistence
  and speaker/wired/Bluetooth route changes on real devices.
- [ ] V10-R: Complete the shared release checklist.

Pass: effects behave as documented; quality displays make no unverified bit-perfect claims.

## 0.11.0 — recovery and refinement

Outcome: recover personal organization and improve daily reliability. Depends on tested 0.10.0.

- [ ] V11-01: Export/import versioned settings, favorites, playlists and custom covers;
  define playback-state inclusion. Source music is excluded from backups by default.
- [ ] V11-02: Validate backups and preview merge/replace behavior before restoration.
- [ ] V11-03: Resolve/report missing source references and request folder access on a new device.
- [ ] V11-04: Add cache size/cleanup controls that preserve source files and collections.
- [ ] V11-05: Address measured responsiveness, memory/battery problems and accessibility gaps.
- [ ] V11-T: Test round-trip restore, corrupt/incompatible backups, interrupted restores,
  low storage, cache rebuilding and upgrade migrations.
- [ ] V11-R: Complete the shared release checklist.

Pass: state restores predictably, failure preserves existing data and cleanup never deletes music.

## 1.0.0 — stable local FLAC player

Outcome: release a dependable Android local player. Depends on all included previews being tested.

- [ ] V100-01: Freeze included scope and document supported Android/device matrix.
- [ ] V100-02: Resolve release-blocking playback, crash, permission and data-loss issues.
- [ ] V100-03: Run full regression and sustained background listening tests.
- [ ] V100-04: Verify latest-preview upgrades, migrations, permission recovery, tag writes
  and backup restoration on real devices.
- [ ] V100-05: Finalize identity, accessibility, privacy/help information and component/asset notices.
- [ ] V100-06: Document reproducible build/signing/release steps, secure signing material
  and recovery procedures that respect Android versionCode restrictions.
- [ ] V100-T: Validate release candidate with all required checks passing and no open blockers.
- [ ] V100-R: Distribute signed 1.0.0 APK, tag exact source and archive release evidence.

Pass: the documented experience works on the supported matrix without known release blockers.
Store submission is optional; choose the distribution channel separately.

## Optional post-1.0 work — deferred until selected

### 1.1.0 — listening statistics and Rewind

- [ ] O11-01: Define local-only listening events, retention and deletion controls.
- [ ] O11-02: Add counts/listening-time views and Rewind with insufficient-data states.
- [ ] O11-T: Verify counting across pause/seek/repeat/restart and history deletion.
- [ ] O11-R: Complete shared release checklist if selected.

### 1.2.0 — AutoMix

- [ ] O12-01: Review analysis/transition dependencies and extraction feasibility.
- [ ] O12-02: Implement optional local analysis/transitions with ordinary-playback fallback.
- [ ] O12-T: Test difficult FLAC pairs, queue changes, analysis failures and effect interactions.
- [ ] O12-R: Complete shared release checklist if selected.

### 1.3.0 — music haptics

- [ ] O13-01: Define hardware support and opt-in controls; implement playback-linked haptics.
- [ ] O13-T: Verify timing, pause/interruption stopping, battery impact and unsupported devices.
- [ ] O13-R: Complete shared release checklist if selected.

### 1.4.0 — advanced USB DAC output

- [ ] O14-01: Review native dependencies/licensing and supported hardware.
- [ ] O14-02: Add selected bit-perfect/exclusive modes with truthful route reporting and fallback.
- [ ] O14-03: Evaluate direct USB/DSD separately; DSD expands the FLAC scope and needs selection.
- [ ] O14-T: Test actual hardware, attach/detach, rate changes, safe volume and effect bypass.
- [ ] O14-R: Complete shared release checklist if selected.

## Shared verification — every applicable version

1. Inspect Git state and preserve unrelated changes; review reused code/notices.
2. Run appropriate formatting/static checks, focused automated tests and an app build.
3. Install/exercise changed behavior on a real Android device; document model,
   Android version, output route and limitations. Add emulator coverage where useful.
4. Check normal, empty, cancelled, denied-access and error/recovery paths.
5. Recheck previous core playback and affected persistent data behavior.
6. Verify labels, focus, text scaling and visible recovery for new UI.
7. Keep diagnostics useful without unnecessarily recording private paths/metadata.
8. Record failed and unrun checks explicitly; keep unresolved work unchecked.

## Shared release checklist

Copy this template into each release's evidence record. A version's `-R` task is
complete only after all applicable steps below pass.

- [ ] Intended implementation and acceptance checks pass.
- [ ] Known limitations and approved scope deferrals are documented.
- [ ] Version name/code, source revision and build commands are recorded.
- [ ] APK installation/upgrade/launch are verified.
- [ ] Signing is appropriate for distribution; keys/secrets are excluded from Git.
- [ ] Changelog/release notes and required attribution are ready.
- [ ] Screenshot/demo demonstrates the actual improvement.
- [ ] APK/checksum and test results are saved; build is distributed.
- [ ] Source tag/release link and dashboard are updated.

## Evidence record template

| Field | Record |
| --- | --- |
| Version / task IDs | Exact scope verified |
| Date / source revision | Build identity |
| Files / adapted source | Changes and reference provenance |
| Commands and results | Actual build/check/test commands, pass/fail/not-run |
| Device and audio samples | Android version/route; owned/licensed FLAC rate/depth |
| Known issues | Reproduction and severity |
| Artifact | APK path/checksum, screenshot/demo, release link |
| Conclusion | Implemented, Tested, Released or blocked with reason |

### 0.1.0 implementation checkpoint

- Branding update: user-supplied HolosMusicApplogo.png retained as master under
  app/assets/brand/; generated all launcher densities, adaptive icon and splash
  resources, and added header/credits logo. Dimensions/XML verified. Updated debug
  APK build passed in session 51076; manual icon/splash review pending.
- Local regeneration: scripts/generate-app-icons.ps1; canonical source is
  app/assets/brand/holos_logo_source.png. Duplicate original upload removed during
  user-authorized cleanup after hash verification.

- User authorized copying selected Mornye implementation/style and deferring redesign.
- Source is in app/; exact provenance and modifications are in app/NOTICE_HOLOS.md.
- Implemented source: single local FLAC picker/STREAMINFO validation, metadata,
  play/pause/seek, idle/loading/ended/error states, retry and foreground lifecycle handling.
- Flutter 3.47.7: `flutter analyze --no-pub` passed; `flutter test --no-pub --reporter expanded`
  passed all 12 tests. Tests use fake audio engines and do not verify Android decoding.
- Six FlacHeaderTest Kotlin checks compiled with Android Studio's Kotlin compiler
  and executed directly through a small local runner; all passed. Gradle JUnit execution pending.
- Android SDK command-line tools, platform-tools, platforms 35/36/37.0,
  Build Tools 37.0.0, NDK 28.2.13676358 and CMake 3.22.1 installed.
- Build session 4490 finished unsuccessfully: the SDK compatibility wrapper split
  `ndk;28.2.13676358` incorrectly, so the required NDK was not installed.
- Recovery completed: installed NDK directly using the current CLI. Retried build
  session 58585 passed: `flutter build apk --debug --no-pub` produced
  app/build/app/outputs/flutter-apk/app-debug.apk (162.7 MiB).
- APK metadata verified: org.holosmusic.holos_music, version 0.1.0/code 1,
  min SDK 24, target SDK 37. SHA-256 and manual checks: [MANUAL_TESTING_0.1.0.md](MANUAL_TESTING_0.1.0.md).
- No phone connected at last check. User manual testing/acceptance not performed.
- Git initialized locally; no remote configured and no push performed.
- Implementation tasks checked against source, automated checks and successful
  Android compilation. Device acceptance V01-T and release V01-R remain unchecked.

## Open decisions and blockers

### 0.2.0 implementation evidence

- Native SAF folder picker retains read grants; recursive scans run on a worker.
- Private AtomicFile JSON metadata snapshot commits after successful scanning;
  cancellation keeps the last snapshot. No source music is written/deleted.
- Stable document identities deduplicate overlapping folder selections without
  merging distinct songs that happen to have identical filenames/titles.
- Library UI, progress/cancel, unavailable-folder recovery/removal and selected-track
  playback added. Existing single-file player is reachable through Now playing.
- Verification session 21546 caught two constant-expression errors in test fixtures;
  fixed before successful session 38028.
- `scripts/verify-and-build.ps1`: format, clean analysis, 22 Flutter tests and debug
  APK build passed. Tests use fake native/audio services; no device acceptance claimed.
- APK metadata: org.holosmusic.holos_music, version 0.2.0/code 2, min SDK 24,
  target SDK 37. Artifact/checksum/checklist: MANUAL_TESTING_0.2.0.md.
- User manual acceptance and release gates remain unchecked. Nothing committed/pushed.

| ID | Decision | Impact / next action |
| --- | --- | --- |
| D-01 | Stack/audio engine | Resolved for 0.1: Flutter/audioplayers + small Kotlin bridge |
| D-02 | Selected reuse and notices | Reviewed for copied components; notices retained; distribution review continues at release |
| D-03 | Build route | Resolved: native Windows debug APK build passed; no WSL/Rust |
| D-04 | Android/device support | Determines APIs/test coverage; complete P-12 |
| D-05 | Distribution/signing | Decide before first distributed 0.1 APK |

## Scope history and session checkpoint

- 2026-10-27: Android-only, local FLAC scope confirmed; downloader/provider/batch stages removed.
- 2026-10-27: Version plan expanded into checklists, dashboard and evidence gates.
- 2026-10-27: Repository layout/ignore/license/reproducibility audit recorded in
  REPOSITORY_AUDIT.md. No GitHub push; manual acceptance remains pending.
- Current checkpoint: 0.1.0 accepted; 0.2.0 checks/build passed; user manual review pending.
- Cleanup: removed verified duplicate APKs/logo, unused slider and temporary reports/
  native-check output; reclaimed 329.6 MiB. Versioned APKs and required source preserved.
- Next session: collect 0.2.0 manual results, fix issues or record acceptance before 0.3.0.
- New ideas: evaluate value, dependencies, reuse evidence and effort before scheduling;
  do not silently add them to the active release.
