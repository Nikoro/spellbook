# Completion internals


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


See [product decisions](product-decisions.md) for the public completion contract and
[the roadmap](roadmap.md) for pending verification and follow-ups.
