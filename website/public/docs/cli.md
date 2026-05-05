---
title: CLI
description: Reference for every Spellbook subcommand — synopsis, examples, and flags for activate, list, diff, doctor, clean, create, init, completion, and help.
---

`spells` is the single binary. All subcommands route through it. Interactive pickers never fire in non-TTY contexts.

## Synopsis

```sh
spells [<subcommand>] [args...]
```

Bare `spells` activates the merged manifest from your current directory. Every other path is an explicit subcommand.

## Subcommands

### `spells` (activate)

Validates the merged manifest and (re)generates wrappers under `~/.spellbook/bin/`. Wrapper writes are atomic — activation either fully succeeds or leaves the previous state untouched.

```sh
spells
```

### `spells list`

Print canonical spells and aliases for the current merged manifest. Override spells get an `[override]` marker.

```sh
spells list
spells list --verbose
```

`--verbose` adds parent-manifest provenance, default values, and switch terminals.

### `spells diff`

Show added, changed, and removed spells since the last activation snapshot — useful before re-activating in a project you haven't touched in a while.

```sh
spells diff
```

### `spells doctor`

Run the full diagnostic suite without changing any files: YAML validity, discovery, extends chain, `$PATH` integration, wrapper state, name shadowing, placeholder/param consistency, override usage, strict-mode warnings, case-insensitive entrypoint warnings.

```sh
spells doctor
spells doctor --fix
```

`--fix` re-activates to resolve state/wrapper drift.

### `spells clean`

Remove wrappers.

```sh
spells clean <name>      # remove a single wrapper + its state entry
spells clean --orphans   # remove wrappers whose spells no longer exist
spells clean --all       # remove every wrapper and clear this project's state
```

### `spells create`

Scaffold a minimal `spells.yaml`:

```sh
spells create            # creates spells.yaml with a sample spell
spells create build      # creates with a spell named `build`
```

Refuses to overwrite an existing manifest.

### `spells init <shell>`

Print shell integration (PATH + wrapper-level TAB completion) for the target shell. The output is written to stdout — `spells init` does not edit dotfiles.

```sh
# zsh (~/.zshrc) or bash (~/.bashrc)
eval "$(spells init zsh)"

# fish (~/.config/fish/config.fish)
spells init fish | source
```

The snippet sets `$SPELLBOOK_HOME`, adds `$SPELLBOOK_HOME/bin` to `$PATH`, and registers the TAB completion handler. See [Shell Integration](./shell-integration/) for what each shell expects.

On first activation, Spellbook offers to set this up automatically.

### `spells completion <shell>`

Print the legacy Phase 2 completion script for the `spells` keyword itself (subcommand completion + spell-name completion after `help` / `clean`). Wrapper-level completion lives in `spells init`.

```sh
spells completion zsh
```

### `spells help`

```sh
spells help
spells help <spell>
spells help <spell> <branch>
```

Spell-level help renders aliases, declared params with types and defaults, switch trees, and any nested switch help.

### `spells --version`

```sh
spells --version
```

### Hidden subcommands

- `spells run <wrapper>` — internal. Wrappers dispatch through this.
- `spells complete <wrapper> --cword N -- <tokens...>` — completion oracle. See [Shell Integration](./shell-integration/#wrapper-completion).

## Silent mode

`silent: true` on a spell runs commands with stdout/stderr buffered. On success the buffer is discarded; on failure it is flushed to your terminal. In a TTY a spinner shows progress. In non-TTY contexts the streams pass through unmodified — no spinner control characters in CI logs.

## Environment passed to spells

When a spell runs, Spellbook injects stable env vars for child processes — useful when a script wants to detect that it's running under Spellbook. Exact names are stable; check the README for the current set.

## Exit codes

The wrapper returns the exit code of the executed script. When activation, parsing, or argument resolution fail, Spellbook returns its own non-zero exit code with a structured error message. There is no `--exit-error` flag — non-zero exit codes are the default.
