---
title: Troubleshooting
description: Diagnose Spellbook problems — read spells doctor output, fix common errors (missing parent, name shadowing, override required), and recover from wrapper conflicts.
---

When Spellbook fails it tries to fail loudly. Errors include a header, the failing context, a caret pointing at the offending token where applicable, a body that explains the rule, and a suggestion. Use this page when the error alone isn't enough.

## Start with `spells doctor`

```sh
spells doctor
```

`doctor` runs the full diagnostic suite without changing any files. It reports:

- **Manifest discovery** — which `spells.yaml` was found, or whether the home fallback is in use.
- **YAML and parse** — invalid YAML, unknown top-level keys, mixed canonical/compact mode.
- **Extends chain** — every parent file resolved, cycles detected, missing parents.
- **`$PATH` integration** — whether `$SPELLBOOK_HOME/bin` is on `$PATH`.
- **Wrapper state** — wrappers that no longer match a spell, and stale wrappers from deleted projects.
- **Name shadowing** — spells whose names collide with `$PATH` binaries without `override: true`.
- **Placeholders / params** — placeholder references that don't match a declared param.
- **Override usage** — overrides on names that aren't actually on `$PATH`.
- **Strict warnings** — case-insensitive entrypoint warnings, suspicious patterns.
- **Shell init** — whether your shell's init snippet is wired up.

`doctor` exits 0 unless something hard-fails. Add `--strict` to fail on warnings too.

## Common errors

### `spells: manifest not found`

You ran `spells` from outside any project tree, and there is no home manifest at `~/spells.yaml`. Either:

- `cd` into a project that has a `spells.yaml`, **or**
- create a home manifest with `spells create --home`.

### `parent manifest not found`

`extends:` points at a file or directory that doesn't exist.

```text
error: parent manifest not found
   --> spells.yaml:1
   |
 1 | extends: ../team/spells.yaml
   |          ^^^^^^^^^^^^^^^^^^^^
   = note: tried `/Users/me/team/spells.yaml`
```

Confirm the path resolves from the manifest's directory. Relative paths are resolved against the manifest, not the current working directory.

### `cycle detected in extends chain`

Two manifests extend each other, directly or via a chain. Spellbook stops parsing immediately. Break the cycle — usually one of the manifests should not be extending at all, or should extend a third common parent instead.

### `name shadows existing command`

A spell or alias collides with a binary on `$PATH`.

```text
error: name shadows existing command
   --> spells.yaml:3
   |
 3 |   ls:
   |   ^^
   = note: `ls` already exists on PATH at /bin/ls
   = help: add `override: true` to the spell to confirm intentional shadowing
```

If the shadow is intentional (e.g. you want a custom `ls`), add `override: true` and use `{{ls}}` (the spell's own name as a placeholder) to call the real binary inside your script. If it isn't, rename the spell.

### `override placeholder not allowed`

You wrote `{{foo}}` referencing the spell's own name in a spell that doesn't have `override: true`. Override placeholders only resolve for explicit overrides — otherwise the same name is interpreted as an unknown param.

### `unknown placeholder`

```text
error: unknown placeholder
   --> spells.yaml:6
   |
 6 |   script: ./deploy {{environemnt}}
   |                    ^^^^^^^^^^^^^^^
   = note: spell `deploy` declares params: env
```

Typo. Fix the placeholder name to match a declared param.

### `param mode mixed`

A spell declares some params with explicit `?`/types and others as flat names. Choose one mode and apply it consistently.

### `passthrough not supported on this script`

You used `...args` more than once in the same script, or the spell has both `script:` and `switch:` so passthrough has no terminal command to land on. `...args` is a literal token inside the `script` string — there is no `params: [...args]` form.

## Wrapper conflicts

After `spells`, a wrapper exists at `$SPELLBOOK_HOME/bin/<name>`. If two projects activate spells with the same name, the most recent activation wins — wrappers are global, not per-project.

When you run a wrapper from a different project, the wrapper passes your *current* working directory back to `spells run`, which discovers that project's manifest. Spells don't leak between projects unless you mean them to (via `extends`).

If you delete a project, its wrappers stay until you run `spells clean`. `doctor` flags stale wrappers explicitly.

## Activation problems

### "Activation succeeded" but the wrapper isn't on `$PATH`

`$SPELLBOOK_HOME/bin` isn't in your `$PATH`. Run `spells doctor` — the PATH check will say so. Fix by sourcing the integration snippet (see [Shell Integration](./shell-integration/)).

### Half-activated state

Activation is transactional — wrapper writes use temp files plus atomic rename, and the state file is updated last. A failed activation leaves the previous wrappers untouched. If you ever see something half-written, run `spells` again or `spells clean` to reset.

### Wrapper exits 127 (`spells: command not found`)

The wrapper invokes `spells` through `$PATH`. If the binary moved or `$PATH` was overridden, the wrapper can't dispatch back. Fix `$PATH`, or reinstall via the curl installer.

## Completion problems

See the [Shell Integration troubleshooting section](./shell-integration/#troubleshooting).

## Filing a bug

Reproduction template — please include in any GitHub issue:

1. `spells --version`
2. macOS version, shell + version (`zsh --version`, `bash --version`, etc.).
3. The minimum `spells.yaml` that reproduces the failure.
4. The exact command that triggers the bug.
5. The full error output (Spellbook's structured errors are usually enough).

[Open an issue on GitHub](https://github.com/Nikoro/spellbook/issues/new). Bugs that include a minimum `spells.yaml` get fixed faster than ones that don't.
