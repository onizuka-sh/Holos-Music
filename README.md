# Holos Music

An Android player for local FLAC files. Current milestone: **0.2.0 — local library** (manual review pending).

Open [app/](app/) in Android Studio as a Flutter project. Selected Mornye components
are copied/adapted for this initial version; design improvements will follow.

## Current functionality

Version 0.1.0 opens a local FLAC file, shows metadata and supports play/pause/seek.
Version 0.2.0 adds persistent folders, recursive scans, a song list and playback
from the library. Playback pauses when leaving the app. Queues and background
controls follow the [version roadmap](FEATURE_ROADMAP.md).

This is a development preview. The user accepted 0.1.0; 0.2.0 automated checks and
APK build passed, with manual acceptance pending. See [0.2.0 manual checks](MANUAL_TESTING_0.2.0.md).

## Run and verify

Use Flutter **3.47.7** with its bundled Dart SDK, Android Studio's Java runtime,
and the Android SDK. Rust and WSL are not required. From app/:

```powershell
flutter --version
dart scripts/prepare_flutter_sdk.dart
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter run -d <android-device-id>
```

The preparation script applies the same Mornye SDK fix used during development;
review it before running it against a shared Flutter installation. See
[development setup](DEVELOPMENT_SETUP.md) for Java/SDK configuration and versions.
`app/.fvmrc` pins Flutter for optional FVM use; `app/pubspec.lock` pins packages.

For native parser tests, from app/android/:

```powershell
.\gradlew.bat :app:testDebugUnitTest
```

The Gradle wrapper is included. A phone needs USB debugging for flutter run;
an emulator can also install a locally built APK by drag-and-drop.
See [manual checks](MANUAL_TESTING_0.1.0.md).

To format, analyze, test and build in one step, run from the repository root:

```powershell
.\scripts\verify-and-build.ps1
```

It stops on the first failure and saves output to app/build/verification.log.
Run flutter pub get first on a fresh checkout. Use -FlutterPath with the full
flutter.bat path if Flutter is not on PATH.

## Repository layout

| Location | Purpose |
| --- | --- |
| app/lib/ | Flutter interface and playback integration |
| app/android/ | Android project, native file bridge and resources |
| app/test/ | Flutter controller/widget checks |
| app/android/app/src/test/ | Native parser tests |
| app/third_party/ | Required copied Android audio plugin and its notices |
| app/assets/ | Runtime assets and canonical logo master |
| app/scripts/, app/patches/ | Reproducible Flutter SDK preparation |
| scripts/ | Repository-level asset generation |

Reference checkouts, SDKs, IDE files, caches, build reports, APKs and signing keys
are excluded from source control. The local references/Mornye checkout is not
needed by the app: all required reused code is included under app/.

## Branding

Canonical logo source: app/assets/brand/holos_logo_source.png. From the repository root:

```powershell
.\scripts\generate-app-icons.ps1
```

To import a replacement, pass `-Source <path-to-square-png>`. Rebuild/reinstall afterward.
The canonical master preserves the supplied artwork; generated sizes are used by the app.

## Project records

- [Roadmap and progress](FEATURE_ROADMAP.md)
- [Project overview](PROJECT_OVERVIEW.md)
- [Repository inventory](REPOSITORY_INVENTORY.md)
- [Mornye feature catalog](MORNYE_FEATURE_CATALOG.md)
- [Repository audit](REPOSITORY_AUDIT.md)

## License and attribution

See [LICENSE](LICENSE), [COPYING](COPYING) and [NOTICE](NOTICE).
[Component provenance](app/NOTICE_HOLOS.md) records copied code and modifications.
Third-party components retain their own licenses. The app includes Mornye's
patched audioplayers Android implementation; its UI dependencies match Mornye's
compatible pinned versions.

The user reviews, commits and pushes the repository. No GitHub push is automated.
