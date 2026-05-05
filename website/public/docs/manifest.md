---
title: Manifest
description: Complete syntax reference for spells.yaml — spells, params, switches, extends, placeholders, overrides, aliases, and the locked YAML subset.
---

A Spellbook manifest is a `spells.yaml` (or `.spells.yaml`) file. It supports two modes — **canonical** and **compact** — and a deliberately small YAML subset.

## Two manifest modes

### Canonical mode

Spells live under a `spells:` key, alongside optional manifest metadata.

```yaml
extends: ../shared
spells:
  hello:
    script: echo "Hello"
```

Use canonical mode when you need `extends:` or `version:`.

### Compact mode

Every top-level key is a spell. No manifest metadata.

```yaml
hello:
  script: echo "Hello"
```

The two modes cannot mix at the top level — if you declare any manifest metadata (`version`, `extends`, `spells`), every spell must move under `spells:`.

### Scalar shorthand

```yaml
hello: echo "Hello"
```

Equivalent to `hello:` with `script: echo "Hello"`.

## Top-level keys (canonical)

Exactly three are recognized: `version`, `extends`, `spells`. Anything else is a `reservedTopLevelKey` error.

`version: 1` is the only accepted version. Missing defaults to 1.

## Spell fields

```yaml
spells:
  deploy:
    description: Deploy to a target environment.
    aliases: [d, ship]
    silent: true
    working_dir: ./deploy
    shell: zsh
    override: false
    params:
      env:
    script: ./scripts/deploy.sh {{env}}
```

| Field | Meaning |
|---|---|
| `description` | One-line summary used by `spells list` and help. |
| `aliases` | Alternate names for this spell. |
| `params` | Positional arguments and named flags. |
| `switch` | Branching of the spell into named sub-paths (mutually exclusive with `script` + `params`). |
| `script` | Shell script run by the terminal command. |
| `silent` | If `true`, hide successful output (spinner shown in TTY). |
| `working_dir` | Override working directory; defaults to the manifest's directory. |
| `shell` | Shell binary used to interpret `script`. Defaults to `bash`. |
| `override` | Required when the spell name shadows an existing command on `$PATH`. |

You can also set the description from a same-line comment instead of the field:

```yaml
spells:
  build: swift build  ## Compile the package
```

When both forms are present, the `description:` field wins.

## Params

`params:` is always a **map** — each entry is `name:` followed by an optional body. List form (`- name`) is rejected at parse time.

### Positional (inferred)

```yaml
spells:
  greet:
    script: echo "Hello, {{name}}"
    params:
      name:
```

```sh
greet World      # Hello, World
```

A bare key with no body is a required positional param.

### Named flags

```yaml
spells:
  greet:
    script: echo "Hello, {{name}}"
    params:
      name:
        flags: -n, --name
        default: World
```

```sh
greet --name Alice   # Hello, Alice
greet                # Hello, World
```

### Types

Params support `string` (default), `int`, `double`, `number`, `bool`, and enum values.

```yaml
params:
  count:
    type: int
  verbose:
    type: bool
  env:
    values: [dev, staging, prod]
```

- Missing required params are errors.
- Missing optional params use the type's zero value or their declared default.
- Enum values are matched case-insensitively and canonicalized.
- Bool flags toggle when present without a value.

### Explicit mode

Group params under `required:` and `optional:` for explicit control. Mixing groups with bare params is an error.

```yaml
params:
  required:
    name:
  optional:
    greeting:
      default: Hello
```

### Passthrough args

Forward extra arguments with `...args` directly inside the script string:

```yaml
spells:
  test:
    script: swift test ...args
```

```sh
test --filter MyTest --verbose
# swift test --filter MyTest --verbose
```

Use `--` to stop Spellbook from parsing further arguments:

```sh
test -- --some-flag
```

All values are shell-escaped by default. More than one `...args` is a validation error.

## Switches

Define mutually exclusive command branches. The field is `switch:` (singular):

```yaml
spells:
  deploy:
    switch:
      staging:
        script: ./deploy.sh staging
      production:
        script: ./deploy.sh production
    default: staging
```

```sh
deploy             # ./deploy.sh staging (default)
deploy production  # ./deploy.sh production
```

Notes:

- `default:` is a sibling of `switch:` and references a branch key (or holds an inline command).
- Without a `default`, a TTY shows a picker; non-TTY contexts error with options listed.
- Branches accept the same fields as spells: own `params`, nested `switch`, `aliases`, runtime fields.
- A branch can be a scalar shorthand: `staging: ./deploy.sh staging`.

`script:` and `switch:` cannot coexist on the same node. Neither can `params:` and `switch:`.

## Aliases

```yaml
spells:
  test:
    aliases: [t, check]
    script: swift test
```

Both `t` and `check` generate wrappers that invoke the `test` spell. Help for an alias shows canonical help with an "alias for" note.

## Extends

Share spells across projects with `extends:`:

```yaml
extends: ../shared
spells:
  local-only:
    script: echo "just this project"
```

- A single string path. Arrays are not supported.
- Closer manifests win on whole-spell conflicts.
- Chains are supported — a parent can extend its own parent.
- `extends: ~` pulls from `~/spells.yaml` (home fallback).
- Cycles are detected and reported with the full chain.

Without `extends:`, Spellbook checks `~/spells.yaml` as a global fallback when no project manifest is found.

## Overrides

Wrap an existing `$PATH` command safely:

```yaml
spells:
  cat:
    override: true
    script: "{{cat}} -n ...args"
```

```sh
cat file.txt    # /usr/bin/cat -n file.txt
```

- `override: true` is required to shadow a `$PATH` binary.
- The override placeholder is `{{spell-name}}` — the spell's own name. It resolves to the next external `$PATH` match, skipping Spellbook wrappers.
- Shell builtins (`cd`, `export`, etc.) cannot be overridden.
- Aliases cannot shadow `$PATH` binaries even when the canonical spell uses `override`.

## Placeholders

Placeholders use `{{name}}` syntax. Only declared params and override placeholders resolve; everything else is left untouched so template strings (e.g. handlebars) survive.

| Placeholder | Behavior |
|---|---|
| `{{name}}` | Shell-escaped value of param `name`. |
| `{{spell-name}}` | In an `override: true` spell only — the original external command of the same name. |
| `...args` | Each passthrough token shell-escaped and joined by spaces. |

Substitutions are always shell-escaped — there is no raw insertion.

## YAML subset

Spellbook implements its own deliberately small YAML parser. Supported:

- Block maps and nested maps.
- Block sequences of scalars (`- foo`) and inline flow sequences (`[a, b]`). Sequences cannot contain maps or nested sequences.
- Folded and literal block scalars (`>`, `|`).
- Single- and double-quoted scalars.
- Comments (`#`) and same-line description comments (`## description`).
- Numeric, boolean, and null scalar literals.

Anchors, tags, complex keys, and merge keys are not supported.
