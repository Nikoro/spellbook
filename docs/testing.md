# Testing Guide

Spellbook uses focused tests with no runtime dependencies. [`architecture.md`](./architecture.md) defines design principles, [`product-decisions.md`](./product-decisions.md) defines behavior, and [`roadmap.md`](./roadmap.md) tracks phase sequencing.

## Test Strategy

Core is test-first. For Core changes, use a red-green-refactor loop:

1. Add one focused test through the public API.
2. Run the narrow test and confirm it fails for the intended reason.
3. Implement the smallest useful change.
4. Run the narrow test, then the full check.
5. Refactor while keeping tests green.

CLI and Foundation wrappers are test-after. Cover the happy path and the important edge cases, especially filesystem writes, subprocess arguments, wrapper output, terminal decisions, bootstrap behavior, and state handling.

## Coverage Policy

Strict TDD applies to deterministic Core modules: YAML tokenizer/parser, manifest parser, extends resolver, validator, param resolver, type validator, placeholder resolver, override resolver, directory walker, help generator, diff detection, and completion Core logic.

Test-after applies to adapters around Foundation and OS behavior: script execution, wrapper generation, state file writes, environment/bootstrap behavior, and shell integration.

Direct unit tests are not required for `main.swift`, low-level ANSI constants, raw `termios` FFI, or the raw terminal dance itself unless behavior moves into a testable abstraction.

Coverage targets for the public MVP:

- About 80% line coverage in Core.
- Every `SpellbookError` variant rendered by CLI snapshot tests.
- Every MVP builtin subcommand covered by at least one app-level integration test.
- Every release-critical workflow covered by a real-process E2E scenario before public release.

## Test Layout

Production and test files should stay close to a 1:1 mapping:

```text
Sources/SpellbookKit/Core/YAMLParser.swift
Tests/SpellbookTests/Core/YAMLParserTests.swift
```

Use manual mocks from `Tests/SpellbookTests/Mocks/`. Do not add mock-generation dependencies.

Current mocks live under `Tests/SpellbookTests/Mocks/`. Highlights:

- `MockFileSystem`: path/content maps, known directories, permission-denied paths, and filesystem call logs.
- `MockTerminal`: queued keystrokes, captured output, configurable TTY/color/dumb-terminal behavior.
- `MockProcessRunner` and `MockCapturingRunner`: canned process results plus a call log; capturing variant returns stdout/stderr buffers.
- `MockManifestLoader`, `MockManifestReader`, `MockManifestContentReader`: loader/reader fakes for activation, doctor, and parser tests.
- `MockPathBinaryChecker`: $PATH-shadow lookups for override resolution.
- `MockStateStore`, `MockFileWriter`, `MockWrapperWriter`: state and wrapper persistence fakes (`WrapperWriteError` companion type).
- `MockChoiceProvider`: queued picker outcomes for finite-choice flows.
- `RecordingFileLock`: deterministic flock substitute for activation lock tests.
- `MutableTTYSource` / `ClassTTYSourceWrapper`: programmable TTY input streams for the picker harness.
- `Snapshot`: helper utilities for plain-text snapshot tests.

See `Tests/SpellbookTests/Mocks/` for the complete list and call-log shapes.

Snapshot tests use the local snapshot helper. Snapshots should be plain text and deterministic. `RECORD_SNAPSHOTS=1 swift test` may be used to regenerate snapshots when intentional rendering changes occur.

Error snapshots should cover every `SpellbookError` case with color disabled. Color variants should use small spot checks rather than duplicating every case.

## Integration And E2E

App-level integration tests should exercise `SpellbookApp.run([...])` or its eventual injectable equivalent with mocked protocols. Each MVP builtin command should have at least one happy-path integration test and focused edge cases where behavior is risky.

Real-process E2E lives in `scripts/e2e.sh`. It is intentionally not part of `scripts/check.sh`, but it is release-blocking once scenarios exist. E2E should be idempotent, create a fresh temp directory, clean up through `trap`, use `SPELLBOOK_HOME` or equivalent isolation, and avoid polluting the real `~/.spellbook`.

## Commands

Run a focused test while developing when useful:

```bash
swift test --filter SpellbookTests.SomeTests
```

Run the full required gate after code changes:

```bash
scripts/check.sh
```

Run real-process E2E separately before release work:

```bash
scripts/e2e.sh
```

`scripts/e2e.sh` is intentionally not part of the per-change hook.

## What To Test

- Parser and validator behavior should be tested through public Core APIs.
- Errors should assert structured `SpellbookError` values where possible.
- CLI rendering should use snapshots once `ErrorReporter` exists.
- Protocol-backed I/O should use manual mocks.
- Raw terminal details and `main.swift` do not need unit tests unless behavior moves into testable Core/CLI types.
