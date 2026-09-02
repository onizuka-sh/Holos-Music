# Repository inventory

## Mornye — Under Analysis

- Origin: https://github.com/mornyeapp/Mornye.git
- Received: 2026-10-26.
- Local checkout: `references/Mornye`, branch main.
- Inspected revision: `c90ec6478ad3e808ef22ba9464f8ad05054dde7b`.
- Scope so far: contributing guide, Flutter and Rust version pins, Cargo manifest,
  Android Gradle configuration, CI workflow, and native backend build script.
- Stack: Flutter/Dart UI, Rust backend, native platform bridges.
- Proposed role: reference candidate; no foundation or reuse decision yet.
- Local clone complete; working tree verified clean. Runtime verification pending.
- License: repository declares LGPL-3.0-only with incorporated GPL terms;
  component-level notices still need inspection before reuse.
- Build finding: Android shell build accepts Linux/macOS hosts, not native Windows.
  Windows desktop PowerShell helper inspected: requires Rust and MSVC; its
  prebuilt Windows bindings mean a separate LLVM install is unnecessary.
- Feature discovery: see [MORNYE_FEATURE_CATALOG.md](MORNYE_FEATURE_CATALOG.md) for source evidence.
- Next: user selects specific Mornye features; then trace their dependencies, licenses and tests before planning adaptation.

## Intake

Accept a repository URL, absolute local folder path, or source archive. Record
the branch/tag/commit inspected, origin, license, and any existing local changes.
If available, capture known working features, run instructions, and known issues.
Do not include credentials or secret environment values.

## Analysis workflow

1. Read repository instructions and documentation; inspect Git state and structure.
2. Inspect source entry points, languages, frameworks, dependency versions,
   module boundaries, and important files.
3. Trace features through UI, storage, APIs, authentication, and integrations.
4. Review configuration, environment variable names, build steps, tests,
   packaging, and deployment arrangements.
5. Assess maintainability, limitations, technical debt, security concerns, and
   licensing constraints on reuse.
6. Run appropriate checks after reviewing setup scripts and requirements.
   Clearly distinguish observed behavior, code-derived findings, and unverified claims.
7. Map useful functionality to reuse, refactor, rewrite, defer, or reject, with
   rationale, dependencies, conflicts, interface needs, and independent tests.
8. Recommend a role and next step; seek confirmation before major integration decisions.

## Per-repository record

Create an individual analysis document when the first repository arrives. Include
source references for findings and a feature comparison table with these fields:

| Feature | Source files | Verification evidence | Proposed treatment | Dependencies and conflicts | Integration and test approach |
| --- | --- | --- | --- | --- | --- |

Record unresolved questions rather than inferring missing behavior. Update this
inventory with a link to each analysis, inspected revision, status, and proposed role.
