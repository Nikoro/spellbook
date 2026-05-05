# Module Map

This document describes Spellbook module boundaries and file responsibilities. [`architecture.md`](./architecture.md) describes the product shape, [`product-decisions.md`](./product-decisions.md) owns locked behavior, and [`roadmap.md`](./roadmap.md) owns sequencing and follow-up status.

## Layers

Spellbook keeps strict downward dependencies:

```text
Models <- Core <- CLI
```

- Models are immutable data structures with no Foundation imports and no behavior beyond simple value access.
- Core contains deterministic product logic and depends on protocols for outside-world decisions.
- CLI adapts filesystem, process execution, terminal behavior, error rendering, wrappers, state files, and prompts.

## Models

| File | Type | Responsibility |
| --- | --- | --- |
| `Sources/SpellbookKit/Models/SpellDefinition.swift` | struct | Single spell definition: identity, body, runtime fields, aliases, params, switches, default branch, override, silent, working directory, shell. |
| `Sources/SpellbookKit/Models/SpellIdentity.swift` | struct | Name, description, and top-level aliases. |
| `Sources/SpellbookKit/Models/SpellBody.swift` | struct | Terminal script, params, and switch branches. |
| `Sources/SpellbookKit/Models/SpellRuntime.swift` | struct | Runtime fields such as override, silent, working directory, and shell. |
| `Sources/SpellbookKit/Models/ParamDefinition.swift` | struct | Param name, description, shape, schema, flags, default, type, values, required/optional, positional/named. |
| `Sources/SpellbookKit/Models/ParamShape.swift` | struct | Positional/named and required/optional routing shape. |
| `Sources/SpellbookKit/Models/ParamSchema.swift` | struct | Param type, default, enum values, and validation-related schema. |
| `Sources/SpellbookKit/Models/ParamType.swift` | enum | Supported param types and type zero values. |
| `Sources/SpellbookKit/Models/SwitchDefinition.swift` | struct | Ordered switch options and default branch. |
| `Sources/SpellbookKit/Models/SwitchOptionDefinition.swift` | struct | Switch option name, aliases, description, and command body. |
| `Sources/SpellbookKit/Models/DefaultBranch.swift` | enum | No default, default key reference, or inline command default. |
| `Sources/SpellbookKit/Models/ParsedArguments.swift` | struct | Resolved param values and passthrough args. |
| `Sources/SpellbookKit/Models/SpellbookError.swift` | enum | Rich structured errors, with no rendering strings. |
| `Sources/SpellbookKit/Models/MapEntry.swift` | struct | Ordered YAML map entry with key, optional description, and value. |
| `Sources/SpellbookKit/Models/YAMLNode.swift` | enum | YAML syntax tree node. |
| `Sources/SpellbookKit/Models/YAMLLine.swift` | struct | Tokenized YAML line with indent and kind. |
| `Sources/SpellbookKit/Models/SpellbookManifest.swift` | struct | Parsed manifest metadata and spell definitions. |
| `Sources/SpellbookKit/Models/ManifestLocation.swift` | struct | Discovery result including project vs home fallback. |
| `Sources/SpellbookKit/Models/LoadedManifest.swift` | struct | Parent manifest loaded through extends plus its canonical path. |
| `Sources/SpellbookKit/Models/FileProbe.swift` | enum | Filesystem probe result for discovery. |
| `Sources/SpellbookKit/Models/StateSnapshot.swift` | struct | Codable state file root: version, projects, updated timestamp. |
| `Sources/SpellbookKit/Models/ProjectState.swift` | struct | Codable per-project state: manifest hash, extends chain, per-spell states. |
| `Sources/SpellbookKit/Models/SpellState.swift` | struct | Codable per-spell state: definition hash, wrapper path, origin manifest. |
| `Sources/SpellbookKit/Models/ActivationResult.swift` | struct | Preflight output: merged manifest, location, extends chain. |
| `Sources/SpellbookKit/Models/ActivationSummary.swift` | struct | Activation output: source, path, spell/wrapper counts. |
| `Sources/SpellbookKit/Models/BootstrapDecision.swift` | enum | First-run bootstrap decision: already configured, offer interactive, print manual, unknown shell. |
| `Sources/SpellbookKit/Models/BootstrapInput.swift` | struct | Input for bootstrap resolution: PATH, shell, home, TTY state, rc file content. |
| `Sources/SpellbookKit/Models/TerminalReadError.swift` | enum | Terminal read error case. |
| `Sources/SpellbookKit/Models/FileLockError.swift` | enum | Errors from POSIX file-locking adapters: open and lock failures with errno. |
| `Sources/SpellbookKit/Models/CompletionCandidate.swift` | struct | Phase 3 completion candidate: value, kind, description, needs-value marker. |
| `Sources/SpellbookKit/Models/CompletionCandidateKind.swift` | enum | switchOption / positionalValue / namedFlag / flagValue / runAsIs / fallthrough. |
| `Sources/SpellbookKit/Models/RankedCandidate.swift` | struct | Fuzzy-matcher result: candidate + score + matched positions. |
| `Sources/SpellbookKit/Models/DecodedManifestCache.swift` | struct | Decoded binary cache: merged manifest + extends chain + format version. |
| `Sources/SpellbookKit/Models/FuzzyPickerInput.swift` | enum | Picker input event: char / backspace / digit / arrow / confirm / cancel. |
| `Sources/SpellbookKit/Models/FuzzyPickerOutcome.swift` | enum | pending / accepted(index) / cancelled. |

## Core

| File | Responsibility | Test approach |
| --- | --- | --- |
| `Sources/SpellbookKit/Core/YAMLTokenizer.swift` | Strip comments, capture `##` descriptions, classify lines, track indentation, preserve block scalar bodies. | TDD |
| `Sources/SpellbookKit/Core/YAMLQuoteScanner.swift` | Track quote state while scanning YAML lines. | TDD through tokenizer/parser |
| `Sources/SpellbookKit/Core/YAMLTrimmer.swift` | Small YAML whitespace operations. | TDD through tokenizer/parser |
| `Sources/SpellbookKit/Core/YAMLParser.swift` | Convert tokenized YAML lines into `YAMLNode`, preserving order and reporting syntax errors. | TDD |
| `Sources/SpellbookKit/Core/YAMLParser+Scalar.swift` | Scalar splitting, unquoting, block scalar collection, and dedenting. | TDD through parser |
| `Sources/SpellbookKit/Core/YAMLParser+Sequence.swift` | Inline flow sequence and scalar block sequence parsing. | TDD through parser |
| `Sources/SpellbookKit/Core/SpellbookParser.swift` | Convert `YAMLNode` into `SpellbookManifest`, detect manifest mode, metadata, and top-level structure. | TDD |
| `Sources/SpellbookKit/Core/SpellBuilder.swift` | Build `SpellDefinition` values from parsed map fields. | TDD through parser |
| `Sources/SpellbookKit/Core/SpellRuntimeBuilder.swift` | Build runtime fields from spell or branch maps. | TDD through parser |
| `Sources/SpellbookKit/Core/ParamSectionParser.swift` | Parse inferred and explicit params. | TDD |
| `Sources/SpellbookKit/Core/ParamAttributes.swift` | Internal parsed param attributes before model construction. | TDD through param parser |
| `Sources/SpellbookKit/Core/ParamAttributesReader.swift` | Read param description, flags, default, type, and values from YAML. | TDD through param parser |
| `Sources/SpellbookKit/Core/ParamTypeReader.swift` | Normalize manifest type strings into `ParamType`. | TDD through param parser |
| `Sources/SpellbookKit/Core/ScalarListReader.swift` | Normalize comma-separated strings and sequences into string arrays. | TDD through parser |
| `Sources/SpellbookKit/Core/CommaSeparated.swift` | Split comma-separated scalar lists. | TDD through parser |
| `Sources/SpellbookKit/Core/SwitchSectionParser.swift` | Parse flat and nested switch maps with aliases and command bodies. | TDD |
| `Sources/SpellbookKit/Core/ExtendsResolver.swift` | Walk extends chains, detect cycles, load parents, and merge closer-wins. | TDD |
| `Sources/SpellbookKit/Core/ExtendsMerge.swift` | Merge child and parent manifests by whole-spell override. | TDD |
| `Sources/SpellbookKit/Core/SpellbookValidator.swift` | Batch semantic validation for names, params, scripts, switches, defaults, and path shadows. | TDD |
| `Sources/SpellbookKit/Core/TopLevelUniqueness.swift` | Check top-level spell and alias namespace uniqueness. | TDD through validator |
| `Sources/SpellbookKit/Core/SwitchUniqueness.swift` | Check switch option and switch alias uniqueness. | TDD through validator |
| `Sources/SpellbookKit/Core/DefaultBranchValidator.swift` | Validate switch default key references and alias misuse. | TDD through validator |
| `Sources/SpellbookKit/Core/ParamFlagUniqueness.swift` | Check duplicate param flags in a terminal command. | TDD through validator |
| `Sources/SpellbookKit/Core/PathShadowValidator.swift` | Validate path shadowing and override eligibility with a path checker protocol. | TDD through validator |
| `Sources/SpellbookKit/Core/ScriptPassthrough.swift` | Count terminal `...args` occurrences. | TDD through validator |
| `Sources/SpellbookKit/Core/SpellName.swift` | Spell-name grammar. | TDD through validator |
| `Sources/SpellbookKit/Core/ParamName.swift` | Param-name grammar. | TDD through validator |
| `Sources/SpellbookKit/Core/AsciiClass.swift` | ASCII letter/digit helpers for grammars. | TDD through grammar users |
| `Sources/SpellbookKit/Core/DuplicateTokens.swift` | Find duplicate tokens while preserving domain-specific reporting. | TDD through validator |
| `Sources/SpellbookKit/Core/DirectoryWalker.swift` | Walk up for manifest discovery, home fallback, visible/hidden precedence, denied dirs, and depth limit. | TDD |
| `Sources/SpellbookKit/Core/ParamResolver.swift` | Public argv-to-`ParsedArguments` entrypoint. | TDD |
| `Sources/SpellbookKit/Core/ArgvScanner.swift` | Internal scanner for flags, positionals, passthrough, sentinel, bool toggles, and required checks. | TDD through resolver |
| `Sources/SpellbookKit/Core/TypeValidator.swift` | Type and enum coercion with precise structured errors. | TDD |
| `Sources/SpellbookKit/Core/PlaceholderResolver.swift` | Safe placeholder and passthrough substitution. | TDD |
| `Sources/SpellbookKit/Core/OverrideResolver.swift` | `$PATH` walk, shell-state denylist, and lazy external command resolution. | TDD |
| `Sources/SpellbookKit/Core/ActivationResolver.swift` | Activation preflight: discover, parse, resolve extends, validate, return merged manifest with chain. | TDD |
| `Sources/SpellbookKit/Core/WrapperContent.swift` | Render wrapper script template for a spell name. | TDD |
| `Sources/SpellbookKit/Core/ManifestHasher.swift` | SHA-256 hashing for manifest content and normalized spell definitions. | TDD |
| `Sources/SpellbookKit/Core/HelpGenerator.swift` | Spell, switch, alias, and root help rendering data. | TDD |
| `Sources/SpellbookKit/Core/DiffDetector.swift` | State-vs-manifest diffing for Phase 2 and activation summaries. | TDD |
| `Sources/SpellbookKit/Core/CompletionResolver.swift` | Phase 2 `spells completion <shell>` script emitter for the `spells` keyword itself. | TDD |
| `Sources/SpellbookKit/Core/BootstrapResolver.swift` | First-run PATH detection and shell integration decision logic. | TDD |
| `Sources/SpellbookKit/Core/WrapperCompletionResolver.swift` | Phase 3 oracle: walk spell grammar, emit `[CompletionCandidate]` for any `(wrapper, tokens, cword)` tuple. Pure. | TDD |
| `Sources/SpellbookKit/Core/CompletionWalker.swift` | Recursive walker for switch / nested-switch / leaf spells. | TDD through resolver |
| `Sources/SpellbookKit/Core/LeafWalkState.swift` | Leaf grammar state: positionals consumed, flags seen, cursor position. | TDD through resolver |
| `Sources/SpellbookKit/Core/CompletionValueRules.swift` | Shared rules: whether a param value satisfies the grammar, and its candidate set. | TDD through resolver |
| `Sources/SpellbookKit/Core/CompletionRequest.swift` | Request container (tokens, cursor-word index, wrapper name). | TDD through resolver |
| `Sources/SpellbookKit/Core/CompletionLineFormatter.swift` | Tab-separated line protocol emitter for `spells complete` stdout. | TDD |
| `Sources/SpellbookKit/Core/CompleteOrchestrator.swift` | Thin orchestrator: resolver + fuzzy filter + formatter. | TDD |
| `Sources/SpellbookKit/Core/FuzzyMatcher.swift` | Subsequence matcher with ranking and matched positions. Pure. | TDD |
| `Sources/SpellbookKit/Core/FuzzyScorer.swift` | Score function: exact / prefix / word-boundary / consecutive / length tiebreak. | TDD through matcher |
| `Sources/SpellbookKit/Core/ManifestCacheCodec.swift` | Binary cache encoder/decoder (magic `SBMC`, versioned, extends-chain header). Pure. | TDD |
| `Sources/SpellbookKit/Core/ManifestCacheWriter.swift` | Internal binary buffer builder. | TDD through codec |
| `Sources/SpellbookKit/Core/ManifestCacheReader.swift` | Internal binary buffer reader. | TDD through codec |
| `Sources/SpellbookKit/Core/ManifestCacheDecoder.swift` | Manifest-payload decoder extensions. | TDD through codec |
| `Sources/SpellbookKit/Core/ManifestCacheTypes.swift` | Param-type code ↔ enum mapping for the cache payload. | TDD through codec |
| `Sources/SpellbookKit/Core/FuzzyPickerState.swift` | Picker state machine: query, filtered view, selection, navigation. Pure. | TDD |
| `Sources/SpellbookKit/Core/TTYPickerHarness.swift` | Terminal harness that drives the picker state through a `TTYSource`. | TDD against mock source |
| `Sources/SpellbookKit/Core/TTYInputDecoder.swift` | Byte → `FuzzyPickerInput` translator (Enter / ESC / arrows / digits / printable). | TDD |
| `Sources/SpellbookKit/Core/ShellIntegrationScripts.swift` | Shell enum + dispatcher to Phase 3 integration templates. | TDD |
| `Sources/SpellbookKit/Core/ZshIntegrationScript.swift` | zsh static integration template (zle widget + precmd resume). | Snapshot-style tests |
| `Sources/SpellbookKit/Core/BashIntegrationScript.swift` | bash static integration template (`bind -x` TAB handler). | Snapshot-style tests |
| `Sources/SpellbookKit/Core/FishIntegrationScript.swift` | fish static integration template (`bind \t` TAB handler). | Snapshot-style tests |

## CLI

| File | Responsibility | Test approach |
| --- | --- | --- |
| `Sources/SpellbookKit/CLI/SpellbookApp.swift` | Top-level router for activation and builtin subcommands. | Integration tests with mocks |
| `Sources/SpellbookKit/CLI/ActivationCommand.swift` | Activation pipeline: preflight, generate wrappers, write state, return summary. | Integration tests |
| `Sources/SpellbookKit/CLI/RunCommand.swift` | Hidden wrapper target: resolve spell from cwd, parse args, substitute, execute, diagnose stale wrappers. | Test-after/integration |
| `Sources/SpellbookKit/CLI/ListCommand.swift` | Compact and verbose spell listing. | Integration |
| `Sources/SpellbookKit/CLI/DoctorCommand.swift` | Diagnostics for manifests, path setup, wrappers, shadows, placeholders, strict mode, and extends. | Integration |
| `Sources/SpellbookKit/CLI/CreateCommand.swift` | Manifest scaffold command. | Test-after/integration |
| `Sources/SpellbookKit/CLI/InitCommand.swift` | zsh, bash, and fish shell integration snippets. | Test-after |
| `Sources/SpellbookKit/CLI/ScriptExecutor.swift` | Subprocess adapter using `/usr/bin/env <shell> -c`, cwd, stdio, env metadata, and exit forwarding. | Test-after |
| `Sources/SpellbookKit/CLI/WrapperGenerator.swift` | Atomic wrapper writer: collects entrypoints, writes via protocol, rollback on failure. | Test-after |
| `Sources/SpellbookKit/CLI/AtomicWrapperWriter.swift` | Foundation-based WrapperWriter: temp file, chmod, atomic rename. | Through WrapperGenerator tests |
| `Sources/SpellbookKit/CLI/SilentRunner.swift` | Spinner, buffering, overflow fallback, and non-TTY no-op around script execution. | Test-after |
| `Sources/SpellbookKit/CLI/InteractivePicker.swift` | Finite-choice picker using terminal abstraction. | Mock-terminal integration |
| `Sources/SpellbookKit/CLI/ErrorReporter.swift` | `SpellbookError` to user-facing output renderer. | Snapshot tests |
| `Sources/SpellbookKit/CLI/ErrorTemplates.swift` | Shared error header/context/body/suggestion helpers. | Snapshot tests |
| `Sources/SpellbookKit/CLI/ANSIColors.swift` | ANSI constants and color enablement. | Minimal spot checks |
| `Sources/SpellbookKit/CLI/StateFile.swift` | Codable state read/write, version checks, and atomic replace. | Test-after |
| `Sources/SpellbookKit/CLI/BootstrapCommand.swift` | First-run shell integration: reads env, prompts user, appends to rc file. | Test-after |
| `Sources/SpellbookKit/CLI/BootstrapSubcommand.swift` | Thin router for the post-activation bootstrap check. | Through SpellbookApp |
| `Sources/SpellbookKit/CLI/StandardTerminal.swift` | Production TerminalProtocol implementation using stdin/stdout. | Through BootstrapCommand |
| `Sources/SpellbookKit/CLI/SpellbookAppHelp.swift` | `spells help [spell]` helper extracted from the router. | Through SpellbookApp |
| `Sources/SpellbookKit/CLI/CompleteCommand.swift` | Phase 3 `spells complete` orchestrator (args → cache-or-live manifest → orchestrator → stdout). | Test-after |
| `Sources/SpellbookKit/CLI/CompleteCommandArgs.swift` | Arg parser for `<wrapper> --cword N -- <tokens...>`. | TDD |
| `Sources/SpellbookKit/CLI/CompleteSubcommand.swift` | Thin router wiring for `spells complete`. | Through SpellbookApp |
| `Sources/SpellbookKit/CLI/PickCommand.swift` | Phase 3 `spells pick`: drives `TTYPickerHarness` against `DevTTYSource`. | Test-after |
| `Sources/SpellbookKit/CLI/PickCommandArgs.swift` | Stdin parser for newline-delimited candidates. | TDD |
| `Sources/SpellbookKit/CLI/PickSubcommand.swift` | Thin router wiring for `spells pick`. | Through SpellbookApp |
| `Sources/SpellbookKit/CLI/DevTTYSource.swift` | POSIX `/dev/tty` adapter: O_RDWR, cfmakeraw + TCSANOW, restore saved termios. | Integration / live-manual |
| `Sources/SpellbookKit/CLI/ManifestCacheWriterAdapter.swift` | Best-effort atomic writer for `$SPELLBOOK_HOME/state/<sha256>/manifest.bin`. | Test-after |
| `Sources/SpellbookKit/CLI/ManifestCacheReaderAdapter.swift` | Freshness-aware cache reader (mtime check against extends chain). | Test-after |
| `Sources/SpellbookKit/CLI/ManifestCacheHook.swift` | Shared hook that wires cache writer to any command surfacing an `ActivationResult`. | Through each command's integration tests |
| `Sources/SpellbookKit/CLI/PosixFileLock.swift` | POSIX `flock(LOCK_EX)` adapter on `$SPELLBOOK_HOME/state.lock`. Used by `ActivationCommand.writePhase` to serialize wrapper + state writes across concurrent activations. | TDD + concurrency test |

## Protocols

| File | Responsibility |
| --- | --- |
| `Sources/SpellbookKit/Protocols/FileSystemProtocol.swift` | Filesystem probing and later read/write/list/rename/chmod/canonical operations. |
| `Sources/SpellbookKit/Protocols/ManifestLoader.swift` | Extends parent loading. |
| `Sources/SpellbookKit/Protocols/PathBinaryChecker.swift` | `$PATH` shadow checks without Core doing direct I/O. |
| `Sources/SpellbookKit/Protocols/TerminalProtocol.swift` | Terminal read/write/color/TTY operations. |
| `Sources/SpellbookKit/Protocols/ProcessRunner.swift` | Process execution abstraction for CLI integration tests. |
| `Sources/SpellbookKit/Protocols/WrapperWriter.swift` | Atomic wrapper write and remove operations. |
| `Sources/SpellbookKit/Protocols/StateStore.swift` | State snapshot read/write abstraction. |
| `Sources/SpellbookKit/Protocols/ManifestContentReader.swift` | Raw manifest content reading for hashing. |
| `Sources/SpellbookKit/Protocols/TTYSource.swift` | Phase 3 terminal abstraction for the picker harness: enter/restore raw mode, read byte, write, isTTY. |
| `Sources/SpellbookKit/Protocols/FileLock.swift` | Exclusive-lock abstraction wrapping a body in `withExclusiveLock`. Used by `ActivationCommand` to serialize concurrent activations. |

## Test Layout

- Production and test files should stay close to a 1:1 mapping.
- Core tests live under `Tests/SpellbookTests/Core/`.
- Model tests live under `Tests/SpellbookTests/Models/`.
- Manual mocks live under `Tests/SpellbookTests/Mocks/`.
- Integration tests live under `Tests/SpellbookTests/Integration/`.
- Error snapshots live under `Tests/SpellbookTests/__Snapshots__/`.
- Fixtures, when needed, are placed under `Tests/SpellbookTests/Fixtures/` (created on demand; the directory is not committed empty).
