---
title: Getting Started
description: Install Spellbook on macOS, set up shell integration, create your first manifest, activate wrappers, and run a spell — in five minutes.
---

Spellbook turns a `spells.yaml` file in your project into real shell commands. This page walks through the full path from install to running your first spell.

## Install

The fastest way is the curl one-liner:

```sh
curl -fsSL https://raw.githubusercontent.com/Nikoro/spellbook/main/install.sh | sh
```

The installer downloads the latest macOS binary, places it on your `$PATH`, and offers to wire up shell integration on the spot.

Other install options:

- **Homebrew** — `brew install nikoro/tap/spellbook`
- **Manual** — download the latest archive from [GitHub Releases](https://github.com/Nikoro/spellbook/releases) and put the `spells` binary somewhere on your `$PATH`.

Verify the install:

```sh
spells --version
```

## Shell integration

Activated wrappers live under `~/.spellbook/bin/` and need to be on your `$PATH`. The installer offers to add this for you. To do it manually:

```sh
# zsh (~/.zshrc) or bash (~/.bashrc)
eval "$(spells init zsh)"

# fish (~/.config/fish/config.fish)
spells init fish | source
```

`spells init <shell>` prints the snippet to stdout — it does not edit your dotfiles. See [Shell Integration](./shell-integration/) for per-shell details.

## Create your first manifest

Inside any project directory:

```sh
spells create
```

This writes a minimal `spells.yaml`. The simplest possible manifest is just a map of spell names to scripts:

```yaml
build: swift build -c release
test:
  aliases: [t]
  script: swift test ...args
```

Spellbook discovers `spells.yaml` (or `.spells.yaml`) by walking up from your current directory, so you can run `build` from anywhere inside the project tree.

## Activate

Run the bare command from inside your project:

```sh
spells
```

Spellbook validates the manifest, generates wrapper executables under `~/.spellbook/bin/`, and atomically updates its state snapshot. After activation, `build` and `test` are real commands you can invoke directly:

```sh
build              # swift build -c release
t --filter Foo     # swift test --filter Foo
```

If activation fails — duplicate names, missing parents, path shadowing — Spellbook prints a structured error and refuses to write any wrapper, so you never end up in a half-activated state.

## Add a parameter

Add a positional param to a spell:

```yaml
greet:
  script: echo "Hello, {{name}}"
  params:
    - name
```

Reactivate, then:

```sh
spells           # re-activate after edits
greet World      # Hello, World
```

The `{{name}}` placeholder resolves to the value you pass and is shell-escaped before substitution. See [Manifest](./manifest/#params) for types, defaults, and named flags.

## Next steps

- [Manifest reference](./manifest/) — every field, switch, extends path, and placeholder rule.
- [CLI reference](./cli/) — every subcommand, flag, and exit code.
- [Examples](./examples/) — real `spells.yaml` files for Swift, Node.js, Python, monorepos, and more.
- [Shell Integration](./shell-integration/) — zsh/bash/fish setup, completion, troubleshooting.
- [Troubleshooting](./troubleshooting/) — `spells doctor`, common errors, recovery steps.
