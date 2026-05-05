# Spellbook Architecture

Spellbook is a macOS-first native Swift CLI for defining project commands as YAML-backed "spells", activating them as shell wrapper commands, and invoking them with safe params, switches, inheritance, overrides, and polished diagnostics. It ships as a single zero-runtime-dependency binary that makes project command workflows easier to share, run, and debug than ad hoc shell aliases.

This document summarizes the architectural boundaries contributors should preserve. Locked product behavior lives in [`product-decisions.md`](./product-decisions.md), sequencing and verified status live in [`roadmap.md`](./roadmap.md) and [`project-status.md`](./project-status.md), and detailed file responsibilities live in [`module-map.md`](./module-map.md).

## Intended Users

- **Project developer**: defines reusable commands in a project manifest and runs them as direct shell commands.
- **Team maintainer**: shares a parent manifest across multiple repositories through explicit inheritance.
- **Shell power user**: creates aliases, parameterized commands, and safe overrides for existing tools.
- **CI or scripted user**: runs commands in non-TTY contexts where interactive pickers must never fire.
- **New installer user**: installs Spellbook, initializes shell PATH integration, creates a starter manifest, and activates wrappers.
- **Troubleshooting user**: runs `doctor` / `list` / `help` to understand available spells, manifest inheritance, wrapper state, shadowing, and likely configuration mistakes.

## Design Principles

- **One native Swift binary, zero runtime dependencies.** No third-party parsing, mocking, snapshot, or CLI dependencies. The custom YAML subset is intentional and expanded only through explicit product decisions.
- **Core is deterministic and test-first.** All filesystem, process, terminal, and rendering concerns are isolated in CLI-facing modules.
- **Strict layering.** Models / Core / CLI dependencies flow downward only.
- **Rust/Elm-style errors.** Clear headers, context, carets where applicable, suggestions; deterministic snapshot coverage for every rendered variant.
- **Safe by default.** Placeholder substitution is shell-escaped; ambiguous or unsafe command definitions are caught before they run.
- **CI-friendly.** Non-TTY behavior is deterministic; interactive pickers never fire in scripted contexts.
- **English-only** for user-facing CLI output and repository documentation.

## Out of Scope

These were intentionally excluded from MVP. Adding them requires a new product decision, not just an implementation.

- **Linux as a first-class target.** Linux is best-effort until macOS is stable; not promised in initial user-facing docs.
- **Full YAML compatibility.** Only the deliberate subset specified in [`product-decisions.md`](./product-decisions.md).
- **Implicit command chaining** from adjacent spell names.
- **Raw placeholder insertion** and **exporting params as environment variables**.
- **Using the state file as a parse cache.** State is a diagnostic and diff-enabling snapshot, not a runtime execution cache (the Phase 3 manifest cache is a separate, versioned artifact — see [`product-decisions.md`](./product-decisions.md)).
- **Runtime dependency introduction** of any kind.

## Layers

Spellbook has three strict layers:

```text
Models <- Core <- CLI
```

`Models` contains immutable data structures only. Model files do not import Foundation, do not perform validation, and do not contain I/O.

`Core` contains business rules: manifest parsing, extends resolution, validation, argument resolution, type coercion, placeholder substitution, override resolution, directory walking, help generation, diffing, and completion generation. Core code is deterministic and test-first. It does not print, exit, read files directly, spawn processes, or depend on terminal state except through protocols.

`CLI` adapts the outside world to Core: filesystem access, wrapper generation, state file reads/writes, subprocess execution, terminal interaction, error rendering, command routing, installation bootstrap, and user prompts.

## Manifest Model

The default manifest file is `spells.yaml`, with `.spells.yaml` as an alternative. The format is YAML-valid, but only a deliberate subset is supported.

Spellbook supports two top-level shapes:

```yaml
extends: ../shared
spells:
  build:
    script: swift build
```

and compact mode:

```yaml
build:
  script: swift build
```

Canonical `spells:` mode is required for manifest metadata such as `extends:` and `version:`. Compact mode has no metadata; every root key is a spell.

Aliases are explicit:

```yaml
spells:
  test:
    aliases: [t, check]
    script: swift test

  deploy:
    switch:
      staging:
        aliases: [stg, s]
        script: ./deploy staging
```

Top-level aliases generate wrapper entrypoints. Switch aliases are extra tokens that select the same switch branch. Aliases are plain strings in MVP.

## Runtime Model

Running bare `spells` activates the current manifest by generating wrappers in `~/.spellbook/bin`. User spells are invoked through those wrappers, not as `spells <name>`.

Generated wrappers call the internal command:

```sh
exec spells run "<name>" --cwd "$PWD" -- "$@"
```

`spells run` is hidden from normal help. Every wrapper invocation fresh-parses the current merged manifest from `--cwd`; `state.json` is not an execution cache in MVP.

Scripts run through `/usr/bin/env bash -c <script>` by default. The `shell:` field can override the executable, but it accepts only an executable name or path in MVP. It does not accept shell arguments.

See [`product-decisions.md`](./product-decisions.md) for the full runtime, discovery, activation, override, placeholder, picker, silent-mode, state, and install semantics.

## Safety Rules

Placeholder substitution is shell-escaped by default. `{{param}}` inserts one safely quoted shell token, override placeholders such as `{{ls}}` insert the escaped external command path, and `...args` expands to individually escaped passthrough tokens.

Core must never guess when a user token can mean two things. Detectable collisions between spell aliases, switch aliases, param aliases, and enum values in the same parse context are validation errors with clear suggestions.

Top-level aliases cannot shadow commands in `$PATH`. Override is supported only when the canonical spell name is the command being shadowed.

## Module Responsibilities

The current file-level module map lives in [`module-map.md`](./module-map.md). Keep new files aligned with that ownership model unless the product decisions change.
