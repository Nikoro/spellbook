# Roadmap

This document is the task-sequencing reference. [`architecture.md`](./architecture.md) defines the product shape; [`product-decisions.md`](./product-decisions.md) defines locked behavior; this file tracks what is done, what remains, Phase 2, milestones, risks, and deferred decisions.

## Verified Position

Latest verified position: May 4, 2026.

Verification command:

```bash
scripts/check.sh
```

Plus a live end-to-end walkthrough of QA 30.* (`spells complete` oracle) and QA 31.3 / 31.8 (zsh + bash 5 picker integration) on 2026-04-22.

Result:

- Swift build passed.
- Swift test passed with **753 tests** across 101 suites.
- SwiftLint reported 0 violations; the quality gate passed.
- Package builds cleanly under Swift 6 language mode with strict concurrency and zero warnings.
- File-size, one-type-per-file, naming, architecture, and SwiftLint-directive gates passed.
- Design audit reported no obvious refactor-pattern candidates.
- Phase 2 closed (all items either shipped or explicitly rejected — see the Phase 2 section below).
- **Phase 3 closed**: wrapper-level completion with custom Spellbook picker shipped and live-verified on zsh and bash 5.3.9 — see the Phase 3 section below.
- Release-hardening bugs 009 / 010 / 011 closed on 2026-04-27 — see the section below.

## Completed Foundation

- [x] Swift package scaffold with executable target `spells` and library target `SpellbookKit`.
- [x] macOS Swift package baseline with zero runtime dependencies.
- [x] Directory layout under `Sources/SpellbookKit/{Models,Core,CLI,Protocols}` and `Tests/SpellbookTests/`.
- [x] Local quality-gate scripts and pre-commit hook.
- [x] E2E script skeleton with temp-dir cleanup.
- [x] Custom snapshot helper scaffold.
- [x] Version smoke behavior.
- [x] YAML map and node models.
- [x] YAML tokenizer for comments, indentation, description comments, quotes, and block scalars.
- [x] YAML parser for maps, nested maps, inline flow sequences, scalar block sequences, block scalars, quoted strings, empty values, and syntax errors.
- [x] Directory walker for visible/hidden manifests, walk-up, home fallback, depth limit, and permission-denied handling.
- [x] Manifest models for spells, params, switches, default branches, runtime fields, and manifests.
- [x] Spellbook parser for canonical and compact modes.
- [x] Mixed manifest detection and unsupported manifest version handling.
- [x] Scalar shorthand spell parsing.
- [x] Description handling with explicit descriptions taking precedence over `##` comments.
- [x] Inferred and explicit param parsing.
- [x] Flat and nested switch parsing with explicit aliases.
- [x] Polymorphic switch defaults as key references or inline commands.
- [x] Script/params plus switch mutual-exclusion checks at parse time.
- [x] Runtime fields for aliases, override, silent, working directory, and shell.
- [x] Extends resolver for single parent, parent chains, cycle detection, missing-parent errors, and closer-wins merge.
- [x] Semantic validator for most MVP rules, including param names, spell names, top-level namespace uniqueness, path shadows, required defaults, duplicate flags, duplicate passthrough, switch uniqueness, terminal switch leaves, and default branch references.
- [x] Param resolver coverage for positional routing, named flags, required checks, optional defaults, bool semantics, negative numeric values, `--` passthrough routing, unsupported equals forms, and structured argument errors.
- [x] Placeholder resolver coverage for known param substitution, preserved external template syntax, and safe `...args` expansion.

## Closed MVP Gaps

- [x] Case-insensitive spell/alias collision warning in `spells doctor` (implemented in `DoctorSemanticChecks.caseCollisionWarnings`, covered by `DoctorSemanticTests` cases `caseCollision_producesWarning`, `aliasCollisionWithName_producesWarning`, `noCaseCollision_noWarning`).
- [x] Type validation and enum canonicalization are implemented.
- [x] Override placeholder resolution is implemented via `PlaceholderResolver` with `OverrideLookup` protocol.
- [x] Override resolution is implemented via `OverrideResolver` with PATH walking and wrapper exclusion.
- [x] CLI is fully implemented with all MVP subcommands: run, list, doctor, create, init, help, version, and default activation.
- [x] Activation, wrapper generation, state file, runtime execution, and builtin commands are implemented.
- [x] Activation state preserves per-spell origin metadata across `extends`, including child overrides of parent spells.
- [x] First-run shell bootstrap detects missing PATH and offers interactive setup.
- [x] `scripts/e2e.sh` has release-mode scenarios covering activation, wrappers, builtins, filesystem regressions, extends/state-origin checks, failure diagnostics, fixture smoke when available, and performance.
- [x] GitHub Actions CI and release workflows created.
- [x] Curl installer created.
- [x] README.md with install, usage, manifest format, migration notes.
- [x] `StandardTerminal` implements real `termios` raw mode and ANSI cursor/line control; interactive picker works against both the protocol and the concrete terminal.
- [x] Homebrew tap/formula drafted in `homebrew/spellbook.rb` with a `bump.sh` helper that fills in version + per-arch SHA256 from the release artifacts. Publishing the dedicated tap (`Nikoro/homebrew-spellbook`) is a manual one-time setup tracked in `homebrew/README.md`; `homebrew-core` is post-adoption.

## MVP Sequence

### Runtime Core

- [x] Add `TypeValidator` for bool, int, double, number, string, enum canonicalization, and typed invalid-value errors.
- [x] Add override-placeholder support to `PlaceholderResolver` through `OverrideLookup` protocol.
- [x] Add tests for all runtime Core edge cases.

### Override And Execution Plumbing

- [x] Add `OverrideResolver` with `$PATH` walking, Spellbook wrapper exclusion, and shell-state denylist.
- [x] Expand protocols and mocks for filesystem (`MockFileSystem`), terminal (`MockTerminal`), process execution (`MockProcessRunner`), and environment behavior.
- [x] Add `ScriptExecutor` using `/usr/bin/env <shell> -c <script>` with default bash, cwd resolution, stdio forwarding, and exit status forwarding.
- [x] Add `EnvironmentBuilder` for `SPELLBOOK_*` env injection and `BootstrapResolver` for shell detection and bootstrap decisions.

### Terminal Interaction

- [x] Add real termios implementation to `StandardTerminal` for raw byte reading, ANSI operations, and cursor control.
- [x] Add `InteractivePicker` for finite enum/switch choices with arrows, vim keys, 1-9 direct selection, Enter, ESC, `q`, and dumb fallback (`NumberedPicker`).
- [x] Add `SilentRunner` for spinner, stdout/stderr buffering, failure flush, overflow fallback, and non-TTY no-op.
- [x] Add mock-terminal integration tests for picker selection and cancellation.

### Errors And Help

- [x] Add `ANSIColors`.
- [x] Add `ErrorTemplates`.
- [x] Add `ErrorReporter` with exhaustive `SpellbookError` rendering (split across `ErrorReporter`, `ErrorReporterRuntime`, `ErrorReporterNaming`, `ErrorReporterArgs`, `ErrorReporterCommand`).
- [x] Add plain snapshot coverage for rendered error variants (`ErrorSnapshotParseTests`, `ErrorSnapshotRuntimeTests`) and color spot-check set (`ErrorSnapshotColorTests`).
- [x] Add `HelpGenerator` for spell help, aliases, params, switches, and alias context.

### Activation And Runtime Commands

- [x] Add `StateSnapshot` and related Codable model types with version 1, snake_case JSON keys.
- [x] Add `StateFile` with version checking, round-trip tests, and atomic temp-file replace.
- [x] Add `WrapperGenerator` with atomic temp wrapper writes, chmod, and rename via `AtomicWrapperWriter`.
- [x] Add `ActivationCommand` pipeline: discover, parse, resolve extends, validate, generate wrappers, write state, print summary.
- [x] Add `RunCommand` as hidden wrapper target: resolve spell, select switch/default branch, resolve params, substitute placeholders, execute script, and diagnose stale/global wrappers with state.
- [x] Add integration coverage for fixture activation (`ActivationIntegrationTests`) and run pipeline (`RunPipelineIntegrationTests`).
- [x] Add release-mode E2E coverage to `scripts/e2e.sh` for activation, wrappers, builtins, regressions, filesystem cases, and performance smoke.

### Builtin Commands

- [x] Add `ListCommand` with compact and verbose output, including aliases next to canonical spells.
- [x] Add `DoctorCommand` for YAML, discovery, extends visualization, shell-init, wrapper, shadowing, placeholder, param, override-placeholder, and strict-mode warnings.
- [x] Add `CreateCommand` for minimal canonical manifest scaffolding, requested-name validation, and overwrite refusal.
- [x] Add `InitCommand` for zsh, bash, and fish PATH snippets.
- [x] Complete root help and version output.
- [x] Add first-run shell integration self-healing prompt through `BootstrapCommand`.
- [x] Complete `SpellbookApp` dispatch and reserved-name routing.

### Release Hardening

- [x] Run the full unit/integration suite and all E2E scenarios.
- [x] Measure activation of a 20-spell manifest and simple spell execution in release-mode smoke checks (latest run: activation 81ms vs enforced <100ms target; execution 507ms vs enforced <750ms three-fork budget — see [`quality-gates.md`](./quality-gates.md)).
- [x] Build release binary and record binary size and startup time. Measured 2026-04-21 on macOS arm64 host with `swift build -c release`: binary **884 KB**, `spells --version` startup **~53 ms median** over 5 runs. `release.yml` ships an arm64 binary per release (Apple Silicon only).
- [x] Write README install, usage, manifest example, migration notes, and macOS-first support statement.
- [x] Add `install.sh` curl installer with shell detection and interactive rc prompt.
- [x] Add GitHub Actions release workflow for macOS arm64 binary, and update the Homebrew tap if the tap is in scope for that release.
- [x] Draft Homebrew tap/formula (done — see `homebrew/` folder and `homebrew/README.md`); `homebrew-core` is post-adoption.

## Phase 2

Ordered by expected user value:

- [x] `spells diff` comparing state vs fresh merge and reporting added, changed, and removed spells. Implemented via `DiffDetector` (Core) + `DiffCommand` (CLI), with `DiffDetectorTests` (5 cases) and two e2e scenarios (`diff: reports added/changed/removed spells`, `diff: no-op when manifest matches state`).
- [x] Dynamic `spells completion zsh|bash|fish`. MVP scope: subcommand completion for every reserved subcommand plus spell-name completion after `help` / `clean` (the two subcommands that take a spell argument). Implementation: `CompletionResolver` emits a per-shell script; runtime queries `spells list` inside the generated functions, so completions stay fresh without parsing state files. Covered by `CompletionResolverTests` (5 cases) and two e2e scenarios.
- [x] `spells clean <name>`, `spells clean --all`, and `spells clean --orphans`. `CleanResolver` (pure) computes a `CleanPlan` from the current `ProjectState` + optional `manifest`; `CleanCommand` applies the plan via `WrapperWriter.removeWrapper` and rewrites the state file. Covered by `CleanResolverTests` (5 cases) and three e2e scenarios.
- [x] `spells doctor --fix` for trivial remediations. `DoctorFixer.assess` detects wrapper-drift warnings that a clean re-activation resolves; `DoctorCommand.run(fix:)` then re-runs activation and re-diagnoses. `DoctorOutput.fixNotes` carries a `[FIX]` trailer. Covered by `DoctorFixerTests` (5 cases) and two e2e scenarios.
- [x] Activation summary diff markers by reusing `DiffDetector`. `ActivationCommand` reads the previous `ProjectState`, runs `DiffDetector`, and threads the result into `ActivationSummary.changes`; `ActivationSummaryRenderer` turns them into `+/~/-` lines printed under the "Activated N spells, M wrappers" header. Covered by `ActivationSummaryRendererTests` and e2e scenario `activation: prints diff markers on re-activation`.
- [x] `spells list` override markers. `ListEntry` carries `override: Bool`; `ListCommand` renders `name  [override]` before the alias list. Covered by `ListCommandTests.list_overrideShowsMarker` and e2e scenario `list: override spells show marker`.
- [x] State file as parse cache — profiled 2026-04-21 and rejected. With 20 spells, `spells list` (parse + format) runs in ~57 ms against `spells --version` at ~53 ms, so the parse step itself is ~4 ms. Building an invalidation + hash-compare layer for that gain is not worth the complexity; the item is closed as "profiled, not needed".

## Phase 3 — Wrapper-level completion

All items shipped; see [`product-decisions.md` §"Wrapper-Level Completion (Phase 3)"](./product-decisions.md) for the locked spec.

- [x] **Oracle** (`spells complete <wrapper> --cword N -- <tokens...>`): `CompleteCommand` + `CompleteCommandArgs` + `CompleteOrchestrator` + `WrapperCompletionResolver` + `CompletionLineFormatter`. Emits tab-separated candidate lines or the `__SPELLBOOK_FALLTHROUGH__` sentinel. Covered by `CompleteOrchestratorTests` (4 cases), `CompletionLineFormatterTests` (4 cases), `WrapperCompletionResolverTests` + `WrapperCompletionGrammarTests` (22 cases), `CompleteCommandArgsTests` (6 cases).
- [x] **Fuzzy matcher** (`FuzzyMatcher.rank`, `FuzzyScorer`, `RankedCandidate`): exact > prefix > word-boundary > consecutive > shorter, case-insensitive, leading-dash strip. 14 cases in `FuzzyMatcherTests`.
- [x] **Manifest cache** (`ManifestCacheCodec` + `ManifestCacheWriterAdapter` + `ManifestCacheReaderAdapter`): binary format `SBMC` + u16 version + length-prefixed extends chain + manifest payload. Best-effort writes wired into Activation / List / Doctor / Diff / Clean via `ManifestCacheHook`. Freshness checked against extends-chain mtimes. Broken manifest falls back to stale cache. 11 codec cases + 3 writer cases.
- [x] **Picker state machine** (`FuzzyPickerState`, `FuzzyPickerInput`, `FuzzyPickerOutcome`): query / backspace / digit direct-select-vs-filter / arrow / Enter / ESC clear-then-close. 12 cases in `FuzzyPickerStateTests`.
- [x] **Terminal harness** (`TTYSource` protocol, `DevTTYSource`, `TTYPickerHarness`, `TTYInputDecoder`): opens `/dev/tty`, cfmakeraw + TCSANOW with termios restore via `defer`, CRLF line endings and cursor-up + erase-to-end reflow, dumb-terminal short-circuit. 11 input-decoder cases + 5 harness cases (via `MutableTTYSource` / `ClassTTYSourceWrapper` mocks).
- [x] **`spells pick` subcommand** (`PickCommand`, `PickCommandArgs`, `PickSubcommand`): reads newline-delimited candidates from stdin, drives the harness against `DevTTYSource`, prints the selection or nothing. 4 cases in `PickCommandArgsTests`.
- [x] **Shell integrations**: `spells init <shell>` emits a Phase 3 script (`ShellIntegrationScripts` + `ZshIntegrationScript` / `BashIntegrationScript` / `FishIntegrationScript`). All three bind TAB directly rather than going through the shell's completion subshell, because otherwise readline/zle/fish-completion compete with `spells pick` for `/dev/tty` keystrokes. 15 contract cases in `ShellIntegrationScriptsTests` + 5 in `InitResolverTests`.
- [x] **Headless E2E** (`Phase3CompletionE2ETests`, `Phase3PickerHeadlessTests`): 9 end-to-end scenarios covering every US-013 outcome without a real TTY.

## Release-Hardening Fixes (2026-04-27)

- [x] **Doctor detects manually removed wrappers.** `DoctorResolver.missingWrappers` probes every `state.spells[*].wrapper` through an injected `FileSystemProtocol` and emits `[WARN] Missing wrappers: <names> — rerun spells`. Covered by `DoctorWrapperStateTests.missingWrapperOnDisk_producesWarning` + `wrappersPresentOnDisk_producesInfo`.
- [x] **Doctor surfaces unsupported state-version errors.** `DoctorCommand.diagnose` no longer swallows state-read errors via `try?`; it captures `SpellbookError` and threads it into `DoctorInput.stateError`. `DoctorResolver.stateChecks` renders `[ERROR] State: unsupported state version <N> (expected <M>) — delete state.json and re-activate` alongside any manifest diagnostics. Covered by `DoctorWrapperStateTests.stateError_producesError` + `DoctorCommandTests.stateReadError_isReportedAsStateError`.
- [x] **Concurrent activations serialize on a flock.** New `FileLock` protocol + `PosixFileLock` (POSIX `flock(LOCK_EX)` on `$SPELLBOOK_HOME/state.lock`); `ActivationCommand.writePhase` wraps wrapper generation + state write inside `withExclusiveLock` so two parallel `spells &` invocations serialize and `bin/` ↔ `state.json` stay consistent. Covered by `PosixFileLockTests.concurrentHoldersObserveSerialAccess` + `ActivationLockTests`.

### Phase 3 follow-ups (non-blocking)

- `spells run <wrapper>` does not currently write the manifest cache on its success path because `RunResolver` does not surface `ActivationResult`. Completion still works because the first activation / list / doctor / diff / clean populates the cache, and subsequent completions validate freshness against extends-chain mtimes.
- `DevTTYSource` restores termios via `defer` but does not install signal handlers (SIGINT / SIGTERM / SIGWINCH). Killing a picker mid-session with Ctrl-C still cleans up because `defer` fires; proactive signal forwarding is a polish item.
- A shell-subprocess E2E suite (driving real zsh/bash/fish under PTY and asserting on the command line mutation) is a release-hardening item. Current coverage stops at the oracle + headless picker; zsh and bash 5 were live-walked through QA 31.* on 2026-04-22.
- Fish was not live-verified on the 2026-04-22 host (fish not installed). The contract is enforced by unit tests.
- TAB after `<wrapper> ` (trailing space) on a no-params spell makes the oracle emit a `runAsIs` candidate with an empty value rather than the `endOfGrammarFallThrough` sentinel. zsh and bash handlers parse the empty value as a no-op candidate and silently no-op, so file completion never fires. Spec FR-51 expects fallthrough in this position. The no-space variant (`<wrapper><TAB>`) takes the `cword == 0` branch in `WrapperCompletionResolver.resolveNoSpaceTab` and works correctly. Fix: extend the equivalent detection to the `cword >= 1` path (probably promote any `runAsIs`-only result into `endOfGrammarFallThrough` in `WrapperCompletionResolver` so handlers don't have to special-case it).

## Open Questions And Deferred Decisions

These were intentionally not decided at MVP time. None of them block the first public release.

### CLI / packaging

- What final public URL, repository release path, and domain should the curl installer use?
- Should the Homebrew tap ship with the first public MVP, or remain a draft until after initial user feedback? ([`homebrew/README.md`](../homebrew/README.md) currently plans the dedicated `Nikoro/homebrew-spellbook` tap for 1.0.)
- What exact README examples should be treated as canonical public examples for the first release?
- How much Linux verification should be done before mentioning Linux as experimental rather than unsupported?

### Phase 3 wrapper completion (post-v1)

- Should flag aliases and switch aliases ever be rendered in the picker (as a secondary column, or via a "verbose picker" toggle)? Deferred from v1 — picker shows canonical names only.
- Should `override: true` wrappers optionally delegate to the overridden binary's own shell completion once Spellbook's grammar is exhausted? Deferred from v1 — v1 falls through to file completion.
- Should passthrough (`...args`) ever be completion-aware (e.g. delegate to the wrapped command's completion as declared in a manifest hint)? Out of scope for v1.
- Orphan cache cleanup: when a project directory is deleted, its `manifest.bin` lingers in `$SPELLBOOK_HOME/state/`. Should `spells doctor` reap orphans, or is a lazy size cap acceptable? Not blocking v1.
- What exact cache-hit latency target do we want to assert in release-mode smoke tests (e.g. p95 under 10 ms on a 50-spell manifest)? Pick after an initial measurement.

### Website (post-launch)

See [`website.md`](./website.md) for the website-specific deferred list (custom domain, JSON-LD structured data, Algolia DocSearch, PR previews, Lighthouse CI, blog/RSS, per-page OG images, recorded demo video).

## Milestones

1. Core runtime can resolve a parameterized spell command fully in memory.
2. Override resolution and subprocess execution work through protocol-backed CLI adapters.
3. Picker and silent mode work in a real terminal with deterministic fallbacks.
4. Every structured error renders in the planned diagnostic style and root/spell help works.
5. Bare `spells` activation produces atomic wrappers and a versioned state file.
6. Generated wrappers invoke `spells run` and execute a simple spell successfully.
7. MVP builtin commands are implemented: list, doctor, create, init, help, and version.
8. Release binary is installable through GitHub Releases and the curl installer.
9. E2E scenarios pass for activation, wrapper invocation, extends, override, and representative failure diagnostics.

## Risks

- Custom YAML edge cases may still differ from user expectations. Mitigation: focused parser tests and fixture corpus from required behavior.
- Raw terminal behavior may vary in tmux, screen, SSH, or uncommon terminal emulators. Mitigation: dumb-terminal fallback and manual smoke matrix.
- `bash` may be absent on minimal Linux images. Mitigation: macOS-first MVP, clear error, and `shell:` override.
- Extends recursion through symlinks can be confusing. Mitigation: canonical path normalization for cycle detection.
- Doctor warnings may be noisy on unusual PATH setups. Mitigation: informative wording and warning severity rather than hard errors where safe.
- Silent mode can encounter chatty commands. Mitigation: 1 MiB per-stream buffer cap and live-stream fallback.
- Homebrew and curl installer flows can drift. Mitigation: shared `Environment` bootstrap logic.
- State schema can become stale over time. Mitigation: versioned state and explicit migration/refusal behavior, plus `spells doctor` surfacing `[ERROR] State: unsupported state version ...` (closed 2026-04-27).
- Concurrent activations against the same `SPELLBOOK_HOME` could leave `bin/` and `state.json` inconsistent. Mitigation: `PosixFileLock` (advisory `flock` on `state.lock`) wraps `ActivationCommand.writePhase` (closed 2026-04-27).

## Quality Gate

Every code change must pass:

```bash
scripts/check.sh
```

See `docs/quality-gates.md` for details.
