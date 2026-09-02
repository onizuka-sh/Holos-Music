# GitHub source-layout audit

Date: 2026-10-27. No staging, commit or push performed by this audit.

## Corrected

- Included Gradle wrapper scripts and JAR: previously ignored, despite documentation
  referring to them for manual builds/tests.
- Excluded nested build folders/reports and APK/AAB outputs, as well as existing
  SDK paths, caches, IDE files, references and signing material.
- Added root license texts/notice while preserving app and vendored notices.
- Included Flutter version pin and upstream SDK preparation script/patch needed
  to reproduce the development SDK on a fresh checkout.
- Standardized the canonical logo master under app/assets/brand/. The redundant
  original root upload is preserved locally and ignored; no user file was deleted.
- Replaced the generated app README and contradictory old WSL/full-Mornye setup notes.
- Added consistent source line-ending/binary handling.

## Intentional locations

- app/ is the Flutter project; open that folder in Android Studio.
- Root Markdown files are project records; AGENTS.md remains at root for agent rules.
- app/third_party/audioplayers_android is required source, not disposable build output.
- Logo source plus generated Flutter/Android sizes are intentional. Only the runtime
  image is declared as a Flutter asset; the large master is not bundled separately.
- app/pubspec.lock and app/.metadata are source-controlled app metadata.
- APKs belong in local build output or a future user-managed GitHub release, not source Git.

## Before the user's push

- Review `git status --short` and `git diff --cached --stat` after staging yourself.
- Finish the manual checks in MANUAL_TESTING_0.1.0.md; acceptance is still pending.
- Retain component/font license files and attribution.
- Choose/configure the GitHub remote yourself. The agent never pushes.

This audit checks repository layout, ignore rules, obvious credential patterns and
documentation consistency. A build from a completely fresh clone has not been run.
