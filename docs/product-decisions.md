# Product Decisions

This document preserves the locked Spellbook behavior decisions. [`architecture.md`](./architecture.md) describes intended users, design principles, and out-of-scope items; this file owns detailed product semantics that agents and implementers should not reinvent.

## Wrapper Lifecycle

- Activation is additive. A project activation writes wrappers into `~/.spellbook/bin/`; another project activation adds or overwrites wrappers for its own entrypoints but does not remove unrelated wrappers automatically.
- Wrapper collisions are resolved at invocation time because every wrapper asks `spells run` to parse the manifest from the caller's current working directory.
- If a global wrapper is invoked from a directory whose merged manifest does not define that spell, the run command should use `state.json` to explain which activated projects do define it and suggest changing directory, adding the spell locally, or using future cleanup commands.
- Explicit cleanup is Phase 2: `spells clean <name>`, `spells clean --all`, and `spells clean --orphans`.
- Wrappers reference `spells` through `$PATH`; there is no absolute engine path and no duplicate `~/.spellbook/engine` binary.

## Discovery

- Manifest discovery walks up from the logical current working directory to `/`.
- The first manifest found wins.
- Supported project manifest names are `spells.yaml` and `.spells.yaml`; when both exist in the same directory, `spells.yaml` wins and doctor should warn.
- If no project manifest is found, Spellbook checks `~/spells.yaml` as a deliberate global-spells fallback.
- A local project manifest always wins over the home fallback. Home spells are not implicitly merged into projects; projects that want shared home spells must use canonical mode with explicit `extends: ~`.
- Bare `spells` never creates a manifest automatically. If discovery finds nothing, it exits with a clear error and suggests `spells create`.
- Walk-up uses logical paths rather than resolving every symlink in the cwd path.
- A 60-iteration safety limit is a hard error for suspiciously deep parent walks.
- Permission denied while listing a parent directory stops walking silently. If no manifest and no home fallback are found, the final user-facing error remains "no manifest found".
- Mount point boundaries are not special; walking continues past them.
- A symlinked manifest file is followed and the canonical target path becomes the recorded origin for behavior such as `working_dir:` resolution.

## Manifest Shapes

- Spellbook supports canonical mode and compact mode.
- Canonical mode uses `spells:` for definitions and reserves top-level keys for metadata:

```yaml
extends: ../shared
spells:
  build:
    script: swift build
```

- Compact mode has no metadata; every top-level key is a spell definition:

```yaml
build:
  script: swift build
```

- `spells create` and public docs should generate canonical mode.
- If `spells:` exists, top-level spell definitions outside `spells:` are validation errors.
- `version:` is optional in canonical mode. Missing means version 1. MVP accepts only integer `1`.
- Canonical mode accepts only `version`, `extends`, and `spells` as metadata. Known future keys such as `env`, `settings`, and `defaults` are reserved-but-unsupported errors. Unknown keys are likely-spell errors that should suggest moving them under `spells:`.
- `extends:` is metadata and is recognized only in canonical mode. In compact mode, `extends` is just a spell name.
- Top-level `default:` is not supported. Bare `spells` always means activation.
- Shorthand scalar spells are supported in canonical and compact mode: `hello: echo hi` means a spell with `script: echo hi`.
- Shorthand cannot be combined with other fields such as aliases.
- Default `spells create` output is intentionally minimal and comment-free:

```yaml
spells:
  hello:
    script: echo "Hello from Spellbook"
```

- `spells create <name>` uses the requested name after validating it with the same spell-name rules as parsed manifests.

## Extends

- Only one parent is allowed per manifest. Longer chains are represented by parents that have their own parent.
- Parent manifests may be canonical or compact. A parent that needs its own `extends:` must be canonical.
- `extends:` values may point to `..`, relative directories, `~`, paths under `~`, absolute paths, or direct manifest files.
- If `extends:` points to a directory, Spellbook looks for `spells.yaml` and then `.spells.yaml` inside that directory.
- If `extends:` points to a file, Spellbook loads that exact file and allows any filename.
- Relative extends paths resolve relative to the file containing the directive.
- Cycles are detected through a visited set of canonical absolute paths and the error should show the cycle path.
- Missing parents are hard errors.
- Merge order is farther parent first, closer child last. Closer manifests win by whole-spell override.
- Spell aliases are part of a spell definition. When a child overrides a parent spell, aliases do not merge; the child must repeat aliases it wants to keep.
- Activation, list, doctor, help, and state snapshots operate on the full merged manifest.
- Parent spells get wrappers in a child project unless overridden by a closer manifest.

## Working Directory

- Every parsed spell carries an origin path.
- Explicit relative `working_dir:` resolves relative to the origin manifest directory.
- Absolute `working_dir:` values are used as-is.
- `~` expands to the user's home directory.
- Environment-variable expansion in `working_dir:` is not supported in MVP.
- Default `working_dir:` is the user's invocation cwd, matching shell-alias behavior.
- Doctor should warn when a script uses relative paths without `working_dir:`.

## YAML Subset

- Supported syntax: block maps, nested maps, inline flow sequences, scalar-only block sequences, block scalar `|`, quoted strings, single and double quotes, double-quoted escapes for newline, tab, quote, and backslash, `#` comments, same-line `##` descriptions, bool/null/int/double scalar literals, and empty values.
- Block sequences support scalar entries only. Nested maps or nested sequences inside block sequences are validation errors in MVP.
- Not supported: nested block sequences, map items inside block sequences, folded `>`, anchors and aliases, merge keys, explicit tags, and multi-document YAML.
- Indentation must use spaces. Tabs are forbidden with a specific error. Two or four spaces are accepted through auto-detection.
- Empty values (`key:`) are syntax markers whose meaning is decided by the manifest parser.
- The parser is intentionally two-layered: `YAMLParser` produces `YAMLNode`; `SpellbookParser` consumes `YAMLNode`.
- YAML syntax errors fail early with line and column context. Semantic validation collects all detected errors when possible.
- `YAMLNode.map` stores ordered `MapEntry` values with `key`, optional `description`, and `value`.
- Description comments attach only to map entries. Sequence items and scalars do not carry comments.

## Names And Aliases

- Spell names use `[a-zA-Z][a-zA-Z0-9_-]*`.
- Spell names become wrapper filenames, so spaces, slashes, dots, colons, leading digits, leading underscores, and leading hyphens are invalid.
- Param names use `[a-zA-Z_][a-zA-Z0-9_]*`. Hyphens are intentionally invalid for params.
- Spell names and aliases are case-sensitive.
- Doctor should warn when two visible entrypoints differ only by case.
- Top-level aliases may be a comma-separated string, a flow sequence, or a scalar block sequence.
- Activation generates wrappers for canonical spell names and their aliases.
- Alias wrappers dispatch to the canonical spell.
- Top-level spell names and top-level aliases share one namespace after extends merge.
- Aliases are plain strings in MVP. They cannot have descriptions, visibility flags, params, override settings, or separate behavior.
- Switch aliases are extra words selecting the same switch option. They are not param flags.
- Help invoked through an alias should render canonical help and include an "alias for <name>" note.

## Params

- Params support inferred mode and explicit mode.
- In inferred mode, a param with `flags:` is named; otherwise it is positional. A param with `default:` is optional; otherwise it is required.
- In explicit mode, params live under `required:` and `optional:` groups.
- Mixing inferred and explicit mode in the same spell is an error.
- `default:` inside a required param is an error.
- Positional order is required-first, then optional-positional. Explicit `required:` keys come before `optional:` keys. YAML key order is preserved.
- Param `flags:` may be a comma-separated string, a flow sequence, or a scalar block sequence.
- Flags are aliases for named params. They do not have to start with `-`; `-n` and `--name` are conventions.
- Param aliases share the terminal command input-token namespace with switch names, switch aliases, and enum values that can appear at the same parse position. Detectable collisions are validation errors; runtime must not guess.
- Named params consume the next argv token as their value.
- `name=value` and `--name=value` forms are not supported in MVP and should produce an error suggesting separate tokens.
- Missing required non-enum params are errors even in TTY. MVP has no free-text prompt.
- Missing optional values become the param type's zero value unless a default is declared.

## Bool And Enum Semantics

- Missing bool value is `false` unless a default is declared.
- A bool flag present without an explicit value toggles the current or default value.
- A bool flag followed by `true` or `false` consumes that explicit value.
- Invalid bool usage should produce a typed error with a concrete example.
- String enum matching is case-insensitive.
- Numeric enum matching uses numeric equivalence where applicable.
- Resolved enum output is the canonical value declared in `values`, not the user's raw casing or spelling.

## Placeholders And Passthrough

- `{{identifier}}` placeholders with no spaces and matching a known param name are substituted.
- In `override: true` spells, `{{spell-name}}` matching the exact spell name is substituted with the external command being overridden.
- Override placeholders use spell-name grammar, so hyphenated override spell names can work.
- Unknown placeholders pass through unchanged by design.
- Template syntax from other systems, such as GitHub Actions, Helm, and Jinja-like expressions with spaces or dots, should survive unchanged.
- `...args` is a special script token for passthrough args, not a placeholder.
- If a terminal script contains `...args`, all unconsumed argv tokens after switch and param parsing expand there as shell-escaped tokens.
- `--` stops Spellbook parsing and sends following tokens to passthrough. Those tokens still require `...args`; otherwise they are unexpected arguments.
- If a terminal script does not contain `...args`, unconsumed argv tokens are errors.
- More than one `...args` occurrence in a terminal script is a validation error.
- Substitution is single-pass. There is no recursive placeholder expansion.
- Placeholder substitutions are shell-escaped by default.
- `{{param}}` inserts one safely quoted shell token.
- Override placeholders insert the escaped external command path.
- `...args` inserts a space-joined list of individually escaped passthrough tokens.
- Raw placeholder syntax is not in MVP. Any future raw insertion must use a new explicit syntax instead of weakening safe placeholders.
- Doctor should warn for unknown `{{identifier}}` occurrences that look like likely Spellbook placeholders.
- Doctor should warn when a defined param is not referenced by `{{param}}` in any terminal script for that spell.
- In override mode, a param name equal to the spell name is an error.

## Switches

- `switch:` is a map of options. Each option is a named switch branch with optional aliases plus a command body.
- Switch option bodies may define their own script, params, nested switch, working directory, shell, silent mode, and descriptions.
- Supported option forms include scalar shorthand and map form with explicit `aliases:`.
- `default:` is a sibling of `switch:` at spell or branch level.
- A string default references a canonical switch option key.
- A map default is an inline command that runs when no switch arg is given.
- If default is absent, TTY invocations may use the picker and non-TTY invocations error with listed options.
- String defaults must reference canonical option names, not aliases.
- Top-level `script:` and `params:` cannot coexist with `switch:`. A command with default params must use inline `default:`.
- Nested switches are allowed recursively.
- Switch option names and aliases must be unique within the same switch map.
- Runtime options `silent`, `working_dir`, and `shell` inherit down the switch tree and may be overridden by deeper branches.
- `override` is top-level only.
- Params do not inherit through the switch tree in MVP.
- Descriptions do not inherit as data. Help may compose parent/child context for display.
- Every leaf must have a terminal script or another switch.

## Override Safety

- Wrapper generation uses this decision tree:
  - If the name is on the shell-state denylist, reject it.
  - If the name exists in `$PATH` outside `~/.spellbook/bin` and `override: true` is absent, reject it.
  - If the name exists in `$PATH` outside `~/.spellbook/bin` and `override: true` is present, allow it.
  - If the name does not exist in `$PATH`, allow it.
- The same path-shadow check applies to alias wrappers, but aliases never accept override. An alias shadowing `$PATH` is an error.
- Shell-state denylist: `cd alias unalias export set unset source . exec readonly shift return eval trap ulimit umask wait jobs fg bg disown hash type builtin command local declare typeset pushd popd dirs suspend times caller logout enable help let mapfile readarray read`.
- Override placeholders are resolved at runtime by walking `$PATH` excluding `~/.spellbook/bin`; first external match wins.
- Multi-level overrides through extends still resolve override placeholders to external binaries, never to spells.
- `{{spell-name}}` is optional. Doctor should warn when an override spell shadows an external command but no terminal script references the exact override placeholder.

## Interactive Picker

- Picker eligibility is limited to finite choices such as enum params and switches.
- Picker fires only when stdin is a TTY and the missing finite choice is in inferred mode or explicit required mode.
- Non-TTY invocations never prompt; they error with options and a suggestion to pass an explicit arg.
- There is no BooleanPicker in MVP.
- Raw terminal behavior uses POSIX `termios`, wrapped behind a terminal abstraction.
- Supported keys: arrows with wraparound, `j`, `k`, Enter, ESC, `q`, and direct number selection for 1-9 when the option count is at most 9.
- ESC uses a short delay to distinguish bare ESC from escape sequences.
- `TERM=dumb` falls back to a plain numbered prompt.
- ANSI color is suppressed when `NO_COLOR` is set or when output is non-TTY.

## Subcommands

- MVP commands: bare `spells` activation, hidden `spells run <name>`, `spells list [--verbose]`, `spells doctor`, `spells create [name]`, `spells init {zsh|bash|fish}`, help, and version.
- Phase 2 commands: `spells diff`, dynamic `spells completion {zsh|bash|fish}`, `spells clean`, and `spells doctor --fix`.
- Phase 3 commands: hidden `spells complete <wrapper> --cword N -- <tokens...>` completion oracle and hidden `spells pick` picker harness.
- Removed from the Dart reference for MVP: watch, detached watch, watch-kill variants, regenerate, deactivate, and update.
- Dispatch rule: if the first arg matches a reserved subcommand, run that builtin; otherwise report an unknown subcommand.
- User spells are invoked by generated wrapper names, not through `spells <name>`.
- `spells run` is an internal wrapper target and should be hidden from normal help and docs.
- Every wrapper invocation fresh-parses the current merged manifest from `--cwd`; `state.json` is not an execution cache in MVP.
- Implicit command chaining is not in MVP. Adjacent words are parsed as args to one spell.
- Phase 2 may explore explicit `and` chaining, but implicit chaining stays rejected as ambiguous.

## Errors

- Core errors are represented as rich `SpellbookError` cases, not preformatted strings.
- Core either throws single errors or returns batches, depending on the operation.
- Core never prints or exits.
- CLI owns exhaustive `SpellbookError` rendering.
- Error template shape is header, context, caret where applicable, body, and suggestion.
- Production messages are in English.
- Color detection respects `NO_COLOR`, `TERM=dumb`, and non-TTY stderr.
- Snapshot tests should cover every rendered error in plain mode, with a small color spot-check set.

## Silent Mode

- `silent: true` hides successful command noise in TTY sessions.
- While the child process runs, Spellbook shows an animated spinner on one terminal line.
- On exit 0, Spellbook clears the spinner and prints a concise success status; buffered output is discarded.
- On non-zero exit, Spellbook clears the spinner, prints a concise failure status with the exit code, and flushes buffered stdout and stderr to their original streams.
- Buffer cap is 1 MiB per stream. If either cap is exceeded, Spellbook disables silent mode mid-run, streams live, and prints a warning.
- Non-TTY mode treats silent as a no-op and forwards stdio normally.
- Ctrl-C should flush buffered output while the process exits so users see context.
- Spinner/status labels use the user-facing invocation path when available, including aliases and selected switch names.

## State File

- State lives at `~/.spellbook/state.json` unless an environment override is introduced for tests/E2E.
- State is versioned with `version: 1`.
- Projects are keyed by the canonical path of the discovered project root manifest.
- State records update time, extends chain, a hash of the manifest, and per-spell normalized definition hashes, wrapper paths, and origins.
- Per-spell hashes are computed after extends merge and before placeholder substitution.
- State supports future diffing and better stale/global-wrapper diagnostics.
- `RunCommand` may read state for diagnostics, but not as an execution cache in MVP.
- State uses `Codable` round-trip.
- Future incompatible state shapes should bump the version and either migrate or refuse with a fix instruction.
- Intended state shape:

```json
{
  "version": 1,
  "updated_at": "2026-04-13T10:30:00Z",
  "projects": {
    "/Users/me/proj": {
      "spells_yaml_hash": "sha256:abc",
      "chain": [
        "/Users/me/spells.yaml",
        "/Users/me/proj/spells.yaml"
      ],
      "spells": {
        "hello": {
          "hash": "sha256:def",
          "wrapper": "/Users/me/.spellbook/bin/hello",
          "origin": "/Users/me/proj/spells.yaml"
        }
      }
    }
  }
}
```

## Atomicity

- State writes use `state.json.tmp` followed by `rename` on the same filesystem.
- Wrapper generation writes hidden temporary files in `~/.spellbook/bin`, makes them executable, then renames them into place.
- Activation order is parse, validate, write temp wrappers, rename wrappers, write state.
- Validation failures have zero side effects.
- If wrapper writing fails before commit, previous visible wrappers and state remain intact.

## Script Execution

- Scripts run through `/usr/bin/env <shell> -c <script>`.
- Default shell executable is `bash`.
- The per-spell `shell:` field may override the executable name or path.
- MVP `shell:` accepts only an executable name or path, not shell arguments.
- Spellbook does not inject strict shell modes into scripts. Multiline scripts run exactly as written.
- Doctor should warn when a multiline bash-like script lacks an obvious strict-mode line such as `set -e` or `set -euo pipefail`.
- The child environment includes stable runtime metadata:
  - `SPELLBOOK_SPELL_NAME`
  - `SPELLBOOK_PROJECT_ROOT`
  - `SPELLBOOK_MANIFEST_PATH`
  - `SPELLBOOK_ORIGIN_PATH`
  - `SPELLBOOK_WORKING_DIR`
- Param values are not exported as environment variables in MVP.

## Shell Integration And Install

- Binary installation location is owned by the package manager or installer.
- Homebrew install is supported as an idiomatic macOS path, but it cannot mutate shell rc files. First-run bootstrap handles PATH setup.
- Curl installer is an MVP distribution path. It detects OS and architecture, downloads the matching release binary, installs to `$HOME/.local/bin/spells` or `/usr/local/bin/spells` if writable, detects the user's shell, and offers to append shell integration.
- Shell integration uses `eval "$(spells init <shell>)"` for zsh/bash and `spells init fish | source` for fish.
- `spells init` emits PATH setup plus Phase 3 wrapper-level TAB completion.
- zsh and bash init output:

```sh
# Spellbook integration v1 (<shell>)
export PATH="$HOME/.spellbook/bin:$PATH"
# ...shell-specific TAB binding...
```

- fish init output:

```fish
# Spellbook integration v1 (fish)
set -gx PATH $HOME/.spellbook/bin $PATH
# ...fish TAB binding...
```

- `spells completion <shell>` remains as the legacy Phase 2 completion surface for the `spells` keyword itself.
- `$SHELL` is used only for shell integration decisions, not for script execution.
- The curl installer should check whether shell integration already exists. If not, it prompts to append the integration line automatically, defaulting to yes, with a `# spellbook` comment header so users can find it later.
- If the installer prompt is declined, it prints the integration line and tells the user to add it manually.
- Bare `spells` should detect when `~/.spellbook/bin` is missing from the current PATH and offer first-run self-healing.
- Activation still proceeds even when PATH setup is missing, so wrappers are ready once the user restarts or sources their shell.
- Wrapper template:

```sh
#!/bin/sh
exec spells run "hello" --cwd "$PWD" -- "$@"
```

- Release packaging for MVP is GitHub Releases plus the curl installer.
- Homebrew tap/formula work is release hardening and should not block the first usable OSS release.
- `homebrew-core` is post-adoption.
- Linux is best-effort until macOS MVP is stable and should not be promised in the initial README.

## Wrapper-Level Completion (Phase 3)

Phase 2 dynamic completion only covered the `spells` keyword (subcommands and spell-name completion after `help`/`clean`). Phase 3 adds wrapper-level TAB completion for the user's spells (e.g. `sbdeploy <TAB>`, `hello<TAB>`, `sbtest --env=<TAB>`) with full parity across zsh, bash, and fish. Phase 2 completion stays as-is.

### Phase 3 Goals

- Every activated wrapper offers TAB completion of its switches, enum values, named flags, and nested switches, driven live from the current merged manifest.
- Completion UX uses the Spellbook picker (not the shell's default under-prompt list) whenever more than one candidate is available.
- Completion latency at TAB is imperceptible in the normal case (cache hit), correct in the edge case (manifest edited without re-activation).
- Full parity across zsh, bash, and fish. No shell is given a reduced surface.

### Phase 3 Non-Goals (v1)

- Showing alias forms in the picker when a canonical name exists. Picker shows canonical names only in v1.
- Completing inside passthrough (`...args`) beyond what the shell provides natively. After Spellbook's grammar is exhausted, file completion falls through to the shell default.
- `override: true` fallback to the overridden binary's own completion. Only Spellbook-declared params complete; beyond that, file completion falls through.
- Ghost-text preview of optional flags. Discovery happens through the picker triggered by `-<TAB>` / `--<TAB>` / `<space><TAB>`.

### Completion Oracle

- A hidden subcommand `spells complete <wrapper> --cword <N> -- <token0> <token1> ...` is the single completion oracle. It accepts shell-tokenized words and the cursor word index, and emits candidate lines to stdout.
- Wrapper-level completion is **dynamic** — every TAB invocation reflects the current merged manifest including edits made since the last activation, not a frozen snapshot.
- Wrapper-level completion is **performant** — the normal-case round-trip (cache hit) is below the threshold of human perception (target: single-digit ms of helper work, excluding picker UI time).

### Picker Candidacy And Triggers

Picker candidacy:

- 0 candidates match → shell bell (no picker, no output).
- Exactly 1 candidate matches → auto-fill the remainder into the command line (no picker).
- 2+ candidates match → open the Spellbook picker, pre-filtered to matching candidates; the classic under-prompt candidate list is never used.

Trigger rules:

- `<wrapper><TAB>` with no trailing space on a fully-typed wrapper name that is already a complete command → shell bell.
- `<wrapper><TAB>` on a wrapper that still requires an argument → picker of the required next token.
- `<wrapper> <TAB>` (space before TAB) → picker of all things addable at this slot (required positionals first if any, then optional flags / switches).
- `<wrapper> -<TAB>` or `<wrapper> --<TAB>` → picker of named flags only (both trigger the same flag picker).
- `<wrapper> <partial><TAB>` → fuzzy-match candidates; auto-fill if 1 match, picker if 2+.

Picker ordering:

- While any required positional or required switch is unsatisfied, the picker shows **only** the required next slot's candidates.
- Once all required slots are satisfied, the picker shows sectioned candidates: required positionals (if any), optional flags, switches, and a terminal "— run as-is —" entry when the command is already complete.

Two-step value pickers:

- When a picker selection is a flag that requires a value (e.g. `--env` bound to an enum), the helper auto-opens a second picker for the value immediately after inserting `--flag ` into the command line.
- For string/free-form flags, the helper inserts the flag and space but does not open a value picker.

### Fuzzy Matching And Picker Input

- Fuzzy filtering ranks: exact match first, then prefix match, then word-boundary match (kebab/camel/snake), then denser runs of consecutive matches, then shorter names as tie-breaker.
- Matched characters are visually highlighted in the picker.
- Filtering is case-insensitive; a leading `-` or `--` in the query is ignored when matching flags.
- Picker input contract:
  - Arrow keys and vim keys (`j`/`k`) always navigate the visible filtered list.
  - `1`-`9` act as direct-select only when the filter query is empty; once the user types any filter character, digits go to the query.
  - ESC clears the filter when non-empty, closes the picker when empty.

### Manifest Cache

- Every Spellbook command that parses a manifest on its success path (activation, `spells list`, `spells doctor`, `spells diff`, `spells clean`, and wrapper invocations) writes, as a best-effort side-effect, a serialized merged manifest to `$SPELLBOOK_HOME/state/<projectHash>/manifest.bin`. The cache write is non-blocking for the primary command and must not affect its exit code.
- The cache path is keyed on a deterministic SHA-256 hash of the absolute path of the project root manifest.
- `spells complete` validates the cache against mtimes of every file in the extends chain (the list is stored inside the cache artifact). If any source file's mtime is newer than the cache or the cache is missing, the helper parses the manifest live and overwrites the cache; otherwise it deserializes from the cache.
- Cache format is versioned with magic bytes (`SBMC`), `u16` format version, `u16` extends-path count, length-prefixed extends paths, and the binary manifest payload. Mismatched or corrupted cache files are treated as cache-miss; a live parse is performed.
- Broken manifest fallback: if a live parse fails (cycle, missing parent, syntax error), `spells complete` falls back to the existing cache (even if stale). If no cache exists, it emits an empty result (shell bell). Parse errors must never be written to stdout (they would be interpreted as candidates).
- `spells run` cache write is a follow-up — the Run resolver does not currently surface `ActivationResult`.

### Shell Registration

- `spells init <shell>` emits a shell-specific integration script containing PATH bootstrap and the TAB binding. The file is generated once and not regenerated by activation.
- The compdef / `complete -F` / fish-complete provider chain competes with `spells pick` for `/dev/tty` keystrokes, so the Phase 3 scripts bind TAB directly:
  - **zsh**: a `zle` widget commits an empty line (releasing the terminal) and defers the picker to a precmd hook; the result is pushed back via `print -z`.
  - **bash**: `bind -x '"\t": _spells_tab_complete'`; the handler rewrites `READLINE_LINE` / `READLINE_POINT` in place.
  - **fish**: `bind \t __spells_tab_complete`; the handler replaces the current token via `commandline -rt --`.
- All three run `spells pick` as a normal foreground command so readline / zle / fish-completion do not compete with the picker for `/dev/tty` keystrokes.
- No per-wrapper registration is needed — the handler is invoked for every wrapper because it is the TAB key itself.
- Wrapper-name completion (e.g. `h<TAB>` → `hello`) relies on the shell's default `$PATH` completion, not on Spellbook-provided registrations. Spellbook completion takes over only after the wrapper name is fully typed.

### End-Of-Grammar Fall-through

- When the user has typed beyond Spellbook's grammar for the current command (all slots filled, no passthrough, or unknown token the grammar cannot parse), the helper emits the sentinel `__SPELLBOOK_FALLTHROUGH__` that instructs the shell wrapper to delegate to the shell's default file/directory completion.
- Errors in the middle of the grammar (e.g. unknown flag) emit a bell (empty result), not file completion.

### Manifest Presentation

- Only the merged effective manifest is surfaced in the picker. Provenance (which parent in the extends chain defined a given spell) is not shown.
