# Holos Music — development setup

Current target: Android. Current development host: Windows.
Flutter app root: app/. Rust, WSL and the full Mornye backend are not required.

## Verified toolchain

| Component | Version / role |
| --- | --- |
| Flutter | 3.47.7; pinned in app/.fvmrc |
| Dart | 3.13.5, bundled with Flutter |
| Java | Android Studio JBR 25 |
| Gradle | 9.8.1, included wrapper |
| Android Gradle Plugin | 9.4.1 |
| Kotlin | 2.4.21 |
| App compile/target SDK | 37 |
| Minimum Android | API 24 / Android 7.0 |
| SDK platforms used by dependencies | 35, 36, 37.0 |
| Build Tools | 37.0.0 |
| NDK | 28.2.13676358, Flutter's pinned default |
| CMake | 3.22.1, installed during dependency build |

Install Flutter, Git, Android Studio and its SDK tools. SDK/platform packages
may be downloaded during the first build. A separate Gradle, Dart, Rust or WSL
installation is unnecessary. FVM is optional.

## Configure your terminal

From app/, using the standard Windows installation locations:

```powershell
$env:JAVA_HOME = Join-Path $env:ProgramFiles 'Android\Android Studio\jbr'
$env:ANDROID_HOME = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:Path = "$env:JAVA_HOME\bin;" + $env:Path
flutter --version
dart scripts/prepare_flutter_sdk.dart
flutter pub get
```

Adjust paths if installed elsewhere and ensure Flutter's bin directory is on PATH.
The SDK preparation script/patch comes from the pinned Mornye revision; it modifies
one semantics cache lookup in Flutter 3.47.7 and is repeatable. Use
`dart scripts/prepare_flutter_sdk.dart --check` to verify without applying changes.

Do not upgrade Flutter or copied dependencies casually. material_ui 1.6.0 is
pinned because a newer release conflicted with the copied expressive components.

## Run, check and build

From app/:

```powershell
flutter analyze
flutter test
flutter devices
flutter run -d <android-device-id>
flutter build apk --debug
```

Output: app/build/app/outputs/flutter-apk/app-debug.apk. Build output is ignored
and does not exist in a fresh clone. Debug APKs use a development signing key;
public release signing remains a separate task.

From app/android/, to see Gradle task progress or run native tests:

```powershell
.\gradlew.bat :app:assembleDebug --console=rich
.\gradlew.bat :app:testDebugUnitTest
```

Do not start another build while the same project is already building.
The wrapper scripts/JAR/properties are included for reproducibility. IDE files,
local.properties, generated plugin registration and caches are generated locally.

## Android CLI package-name workaround

The SDK compatibility wrapper split old semicolon package names incorrectly on
this machine. The successful direct installation used slash-separated names:

```powershell
$androidCli = Join-Path $env:ANDROID_HOME 'cmdline-tools\latest\bin\android.exe'
& $androidCli "--sdk=$env:ANDROID_HOME" sdk install 'ndk/28.2.13676358'
```

The same CLI was used for platforms/android-37.0 and build-tools/37.0.0.
Avoid installing the full Mornye toolchain for this smaller local-player app.

## Recorded verification

- Version 0.2.0: clean static analysis, 22 Flutter controller/widget tests and Android
  debug APK build passed. See MANUAL_TESTING_0.2.0.md for the versioned artifact,
  checksum and pending device checks. No new dependency downloads were needed.

- Static analysis: passed for the initial 0.1.0 implementation.
- Flutter controller/widget tests: 12 passed, using fake audio engines.
- Kotlin FLAC header checks: 6 passed via a compiled local runner.
- Android debug APK: initial and logo-update builds passed.
- Full Gradle JUnit run and real-device playback: not yet recorded.
- User manual review: pending; see MANUAL_TESTING_0.1.0.md.

The workspace is a local Git repository. No remote is configured and nothing has
been pushed by the agent. Only the user performs GitHub pushes after review.
