---
title: Shell Integration
description: Set up Spellbook in zsh, bash, and fish — PATH wiring, lazy loading, wrapper-level TAB completion, and per-shell troubleshooting.
---

Spellbook ships shell integration scripts for **zsh, bash, and fish** with full parity. The integration does two things: puts wrappers on your `$PATH`, and registers TAB completion that opens a Spellbook picker when you press TAB on a wrapper.

## What `spells init` produces

```sh
spells init zsh
spells init bash
spells init fish
```

`spells init <shell>` writes a snippet to **stdout** — it never edits your dotfiles. You decide where it goes:

- **zsh** — append to `~/.zshrc`, or write to a fragment under `~/.config/spellbook/init.zsh` and `source` it from `~/.zshrc`.
- **bash** — append to `~/.bashrc` (Linux) or `~/.bash_profile` (macOS interactive login).
- **fish** — write to `~/.config/fish/conf.d/spellbook.fish` (auto-loaded).

The snippet:

1. Sets `$SPELLBOOK_HOME` to its default (`~/.spellbook`).
2. Adds `$SPELLBOOK_HOME/bin` to your `$PATH`.
3. Binds the TAB key to the Spellbook completion handler.

## Wrapper completion

Phase 3 wrapper-level completion gives every activated wrapper a Spellbook picker on TAB:

```sh
deploy <TAB>          # opens picker of switches and required positionals
deploy --env=<TAB>    # opens picker of enum values
test st<TAB>          # fuzzy filter, auto-fills if 1 match remains
```

Behavior summary:

- 0 matches → shell bell.
- Exactly 1 match → auto-fill into the command line.
- 2+ matches → open the Spellbook picker (`/dev/tty`-driven, not the shell's default under-prompt list).
- End of grammar (passthrough or unknown token) → fall through to the shell's file/directory completion.

The picker uses the same input contract as the runtime picker: arrows, vim keys (`j`/`k`), Enter, ESC, `q`, and 1-9 direct-select when the filter is empty.

## Per-shell notes

### zsh

The integration installs a `zle` widget that hijacks TAB only for command lines whose first word is a Spellbook wrapper. Other commands fall back to zsh's default completion system (`compdef`, fzf-tab, etc.) untouched.

If you use `zsh-autosuggestions` or `zsh-syntax-highlighting`, source them after the Spellbook init snippet — they expect to wrap the prompt.

### bash

bash 5.x is required for the binding model the integration uses (`bind -x` with TAB). On macOS, the system bash is 3.2; install bash 5 from Homebrew (`brew install bash`) and add it to `/etc/shells` if you want to use it as your login shell.

bash's readline uses TAB for symbolic completion by default. The Spellbook integration takes over only when the line starts with a wrapper; otherwise readline's TAB still fires.

### fish

fish completions live under `~/.config/fish/completions/`. The Spellbook integration registers a TAB binding via `bind \t`, which fires the Spellbook completion handler before fish's native completion engine runs. Native completions still fire for commands outside the Spellbook wrapper set.

## Lazy loading

The integration is intentionally minimal — under 50 lines of shell per snippet. There is no manifest parsing, no per-wrapper registration script, no startup-time PATH scan. The TAB handler is the only hot path.

When you press TAB, the handler invokes:

```sh
spells complete <wrapper> --cword <N> -- <token0> <token1> ...
```

This is the single completion oracle. It validates a cached merged manifest against the mtimes of every file in the extends chain; if anything is newer than the cache, it re-parses live and rewrites the cache. Cache-hit latency is in the single-digit milliseconds.

## Refresh after editing the manifest

You don't need to re-run `spells` to refresh completion — the cache is invalidated by mtime. You **do** need to re-run `spells` to make a new wrapper appear on `$PATH`. Existing wrappers complete from the live manifest immediately.

## Troubleshooting

### Wrapper not found

```text
$ build
zsh: command not found: build
```

`$SPELLBOOK_HOME/bin` is not on your `$PATH`. Run `spells init <shell>` again, paste the snippet into your rc file, and restart the shell.

### TAB doesn't open a picker

Check that the integration's TAB binding is registered:

- zsh: `bindkey '^I'` should reference the Spellbook widget.
- bash: `bind -p | grep TAB` should show the Spellbook handler.
- fish: `bind \t` should be in the Spellbook conf.d snippet.

If another plugin (fzf-tab, command-not-found, etc.) installs its own TAB binding *after* Spellbook, source the Spellbook snippet last.

### `/dev/tty` errors in completion

Some terminal multiplexer setups (`tmux` with detached sessions, screen sharing tools) lose `/dev/tty` access. The picker falls back to a numbered prompt in that case. If you see a hard error, run `spells doctor` to confirm `/dev/tty` is reachable.

### Completion is empty when you expect candidates

Run the oracle directly to see what Spellbook returns:

```sh
spells complete deploy --cword 1 -- deploy ''
```

If the output is empty, the manifest cache is stale or the spell is unknown. `spells doctor` checks both.

### Completion log

When `spells complete` falls back due to a parse error, it appends to a per-project log file under `$SPELLBOOK_HOME/state/<projectHash>/complete.log`. `spells doctor` surfaces these.

## Manual install (no `spells init`)

If you'd rather hand-author the integration:

```sh
export SPELLBOOK_HOME="$HOME/.spellbook"
export PATH="$SPELLBOOK_HOME/bin:$PATH"
```

This gives you working wrappers without TAB completion. The completion handler must be installed via `spells init` — it's shell-specific and not safe to copy by hand.
