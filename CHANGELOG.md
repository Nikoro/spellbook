# Changelog

All notable changes to Spellbook will be documented in this file.

The format is based on Keep a Changelog, and this project uses Conventional Commits.

## [Unreleased]

## [0.1.0] - 2026-05-05

### Added

- Phase 3 wrapper-level completion with a custom fuzzy Spellbook picker:
  - `spells complete <wrapper> --cword N -- <tokens...>` hidden oracle emitting tab-separated candidate lines and `__SPELLBOOK_FALLTHROUGH__` sentinel.
  - `spells pick` hidden subcommand that reads newline-delimited candidates from stdin and drives `TTYPickerHarness` through `DevTTYSource`.
  - Versioned manifest cache (`SBMC` magic + u16 format version + length-prefixed extends chain + binary manifest payload) at `$SPELLBOOK_HOME/state/<sha256>/manifest.bin`. Best-effort writes wired into Activation / List / Doctor / Diff / Clean. Freshness validated against extends-chain mtimes; stale cache served as fallback on broken manifest.
  - Shell integrations for zsh (zle widget + precmd resume via `print -z`), bash (`bind -x` TAB handler rewriting `READLINE_LINE`), fish (`bind \t` TAB handler using `commandline -rt`).
  - Fuzzy matcher (exact > prefix > word-boundary > consecutive > shorter) with highlighted matched positions.
- Initial product decisions, architecture notes, local skills, and quality gates.
- Commit workflow skill, Conventional Commits policy, and Keep a Changelog baseline.

### Changed

- Completed MVP runtime argument resolution semantics for bool flags, negative numeric values, `--` passthrough handling, and structured argument-resolution errors.
- Added scalar type validation, enum canonicalization, and integrated runtime type enforcement before script execution.
- Added safe parameter placeholder substitution, preserved external template syntax, and shell-escaped `...args` passthrough expansion.
- `spells init <shell>` now emits the Phase 3 integration script (supersedes the Phase 1 PATH-only snippet).

### Fixed

- `spells doctor` now reports manually removed wrappers as `[WARN] Missing wrappers: <names> — rerun spells`, instead of declaring "Wrappers: up to date" when the wrapper file has been deleted but `state.json` still advertises it.
- `spells doctor` now surfaces unsupported `state.json` schema versions as `[ERROR] State: unsupported state version <N> (expected <M>) — delete state.json and re-activate`, instead of silently swallowing the read error and reporting `noManifestFound`.
- Concurrent `spells` activations against the same `SPELLBOOK_HOME` now serialize on a POSIX `flock` against `$SPELLBOOK_HOME/state.lock`, so `bin/` and `state.json` stay consistent under parallel invocations.
