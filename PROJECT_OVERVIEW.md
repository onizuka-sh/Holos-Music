# Holos Music

Last updated: 2026-10-27

## Purpose

Progressively transform multiple existing repositories into a cohesive, modern,
maintainable, open-source, cross-platform music application. Inspect and evaluate
existing code before deciding what to reuse, refactor, rewrite, or discard.

## Current status

- Active phase: Phase 7 — version 0.1.0 manual review pending.
- Workspace: repository root; Android Flutter application in app/.
- Initial inspection: workspace was empty; no existing application or Git repository.
- Current product scope: an Android player for the user's local FLAC files.
- First repository: https://github.com/mornyeapp/Mornye.git
- Active version: 0.1.0 in app/. Selected Mornye theme, font, seek controls and patched Android audio plugin copied/adapted.
- Next action: user installs app/build/app/outputs/flutter-apk/app-debug.apk and follows MANUAL_TESTING_0.1.0.md. Resolve reported issues before advancing.
- Verification: static analysis, 12 Flutter tests, 6 compiled Kotlin FLAC-header checks and Android APK build passed. User manual testing/acceptance remains pending.
- Current platform scope: Android only. Other platforms are deferred.
- Stack: Flutter/Dart with Mornye's audioplayers Android fork and a small Kotlin local-file bridge. No Rust or WSL required for 0.1.0. Mornye supplies selected components only.

## Working agreement

User rules are maintained in AGENTS.md: summarize implementations, leave manual
acceptance to the user, and never push to GitHub. The user reviews and pushes.
For downloads/builds requiring waiting, stop and hand control back to the user;
resume only when they ask to continue.

1. Read these documents and inspect relevant Git changes at each session start.
2. Work on one phase and one selected feature at a time.
3. Inspect actual source code; do not select a foundation from README claims alone.
4. Preserve working functionality and explain significant changes before editing.
5. Record what was changed, verified, left unverified, and what comes next.
6. Obtain the user's confirmation before major integration decisions following discovery.
7. Never delete source repositories or source files without explicit approval.
8. Keep secrets out of documentation and version control.

## Provisional possibilities

Current scope is local FLAC playback. Online discovery, provider extensions,
download queues and batch downloading are excluded. Earlier cloud, network and
Telegram ideas are outside the current scope. Metadata, artwork, playlists and
playback enhancements remain candidates in FEATURE_ROADMAP.md.

## Progress tracking

Use REPOSITORY_INVENTORY.md for discovery findings, FEATURE_ROADMAP.md for the
versioned task checklists, progress dashboard and release evidence, and this document for the active phase, decisions,
and next action. Create architecture
notes, integration log, testing guide, and deployment guide when their phases
require them rather than filling them with assumptions now.

Feature statuses: Proposed, Under Analysis, Planned, In Progress, Implemented,
Tested, Deployed, Deferred, Rejected. Distinguish implementation from verification.

## Decisions

- 2026-10-27: User wants a local FLAC player, not a downloader. Removed stages
  6 (provider integration), 9 (downloads), and 10 (batch downloads/processing)
  from the previous proposal. No code was removed from the reference repository.

- 2026-10-27: User confirmed Android-only development for now; other platforms later.

- 2026-10-26: Start with discovery, not application implementation.
- 2026-10-26: The first repository is a candidate, not the automatic foundation.
- 2026-10-26: Keep initial documentation minimal and defer technology decisions.
