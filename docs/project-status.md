# Project Status

This file records the latest verified implementation position for agents. [`roadmap.md`](./roadmap.md) is the authoritative sequencing checklist; [`architecture.md`](./architecture.md) summarizes intended users and design principles; [`product-decisions.md`](./product-decisions.md) owns locked behavior.

## Latest Verification

Verified on 2026-05-04 with:

```bash
scripts/check.sh
```

The latest live end-to-end walkthrough of the `spells complete` oracle (all 11 cases) and zsh + bash 5 wrapper-level completion with the Spellbook picker was completed on 2026-05-05 against `spells 0.1.0-dev`. Fish parity remains covered by unit tests only — fish was not installed on either verification host.

Result:

- `swift build` passed.
- `swift test` passed with **753 tests** across 101 suites.
- SwiftLint reported 0 violations; the quality gate passed.
- Package builds cleanly under Swift 6 language mode (`swiftLanguageMode(.v6)`) with strict concurrency enabled and zero warnings.
- Architecture, naming, file-size, one-type-per-file, and SwiftLint-directive gates passed.
- Design audit reported no obvious refactor-pattern candidates.
- Phase 2 remains closed (`spells diff`, list override markers, activation diff markers, `spells clean`, `doctor --fix`, `spells completion`).
- **Phase 3 wrapper-level completion shipped** — see below.
- Release-hardening BUGS 009 / 010 / 011 closed on 2026-04-27: doctor now reports manually-removed wrappers, surfaces unsupported state-version errors instead of swallowing them, and concurrent activations serialize on a `state.lock` flock.
- 20-spell activation: 81 ms (threshold <100 ms). Simple spell execution: 507 ms (threshold <750 ms three-fork budget).

## Phase 3 — Wrapper-level completion

Status: shipped, live-verified on zsh and bash 5.3.9. Summary:

- **Oracle**: `spells complete <wrapper> --cword N -- <tokens...>` emits tab-separated candidate lines (`value\tkind\tneedsValueNext\tdescription`) or the sentinel `__SPELLBOOK_FALLTHROUGH__`.
- **Manifest cache**: best-effort write of `$SPELLBOOK_HOME/state/<sha256>/manifest.bin` (magic `SBMC`, u16 format version, u16 extends-chain count, length-prefixed paths, binary manifest payload) from `ActivationCommand`, `ListCommand`, `DoctorCommand`, `DiffCommand`, `CleanCommand`. `spells run` cache write is a follow-up. Freshness validated against extends-chain mtimes; broken manifest falls back to stale cache.
- **Fuzzy matcher**: `FuzzyMatcher.rank` returns `[RankedCandidate]` with exact > prefix > word-boundary > consecutive > shorter ranking, case-insensitive, strips leading `-`/`--` for flag candidates, empty query preserves order.
- **Picker**: `TTYPickerHarness` drives `FuzzyPickerState` against a `TTYSource` protocol. Live rendering uses CRLF line endings and cursor-up-plus-erase-to-end reflow. `DevTTYSource` opens `/dev/tty` O_RDWR and uses `cfmakeraw` + `tcsetattr TCSANOW`, restoring saved termios via `defer`.
- **`spells pick`**: hidden CLI subcommand reads newline-delimited candidates from stdin, runs the harness against `DevTTYSource`, prints the selected line to stdout (empty on cancel). Used by all three integration scripts.
- **Shell integrations**: `spells init <shell>` emits a Phase 3 script:
  - zsh binds TAB to a `zle` widget that commits an empty line (releasing the terminal) and defers the picker to a precmd hook; the result is pushed back via `print -z`.
  - bash uses `bind -x '"\t": _spells_tab_complete'`; the handler rewrites `READLINE_LINE` / `READLINE_POINT` in place.
  - fish uses `bind \t __spells_tab_complete`; the handler replaces the current token via `commandline -rt --`.
  - All three run `spells pick` as a normal foreground command so readline/zle/fish-completion do not compete with the picker for `/dev/tty` keystrokes.

## Roadmap Position

The project is at the release hardening boundary:

- Core foundation + all Phase 1 + Phase 2 + Phase 3 deliverables verified.
- `ActivationCommand` (now lock-protected via `PosixFileLock`), `WrapperGenerator`, `StateFile`, `RunCommand`, `ListCommand`, `DoctorCommand`, `CreateCommand`, `InitCommand`, `DiffCommand`, `CleanCommand`, `CompletionCommand`, `CompleteCommand`, `PickCommand` are all wired through `SpellbookApp`.
- GitHub Actions CI (`ci.yml`) and release (`release.yml`) workflows are in place for macOS arm64 (Apple Silicon only).
- `install.sh` curl installer handles OS/arch detection, binary download, checksum verification, and shell integration.
- `README.md` covers install, usage, manifest format, params, switches, extends, overrides, passthrough, aliases, macOS-first support, and the Phase 3 wrapper-level TAB completion section.
- `scripts/e2e.sh` covers activation, wrapper invocation, extends merge, builtins, filesystem cases, performance smoke, Phase 2 scenarios. Phase 3 end-to-end scenarios are covered at unit/integration level in `Phase3CompletionE2ETests` and `Phase3PickerHeadlessTests`; a dedicated shell-driven suite is a follow-up.

Update this file whenever a verification pass materially changes the project position.
