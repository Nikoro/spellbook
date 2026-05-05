# Quality Gates

Every code change must pass:

```bash
scripts/check.sh
```

The script runs the project gates in the intended order:

- Swift file length.
- One top-level type per file, except `main.swift`.
- Naming guard.
- Architecture guard.
- SwiftLint.
- No SwiftLint bypass directives.
- `swift build`.
- `swift test`.
- Warning-only design audit.

## Rules

- Swift files must stay within the configured hard limits: 200 lines per file, 30 lines per function, 4 parameters per function, cyclomatic complexity 10, 3 nesting levels, one top-level type per file except `main.swift`, and 120 columns.
- Do not use `swiftlint:disable`.
- Do not edit lint config to make a task pass.
- Do not move forward with failing build or tests.
- Treat design-audit output as review input, not as an automatic refactor command.
- After tests are green, do a small refactor pass on changed files: verify names are domain-specific, layer boundaries are clean, tests cover public behavior, and no repeated rule wants a deeper module.

## Release-Time Performance Budgets

These are not enforced by `scripts/check.sh` but are release-blocking when measured in release-mode smoke tests:

- **20-spell activation** finishes in under **100 ms**.
- **Simple spell execution** finishes in under **750 ms**. Execution spans three forks — generated wrapper, `spells run`, and the target shell — so this is a realistic macOS budget rather than a tight one.

Latest measured values are recorded in [`project-status.md`](./project-status.md).

## Release-Blocking E2E

`scripts/e2e.sh` is intentionally **not** part of the per-change quality gate, but it is **release-blocking** once scenarios exist for the change. Run it before tagging a release.

## Common Fixes

If a file is too long, split by domain type or responsibility.

If a function is too long or nested, extract a named domain operation or use guard clauses.

If a type name is generic, rename it to the Spellbook concept it represents.

If Core needs I/O, introduce or reuse a protocol and keep the implementation in CLI or a protocol adapter.

## Sandbox Note

Swift may need to write build/cache files outside the workspace on macOS. If `scripts/check.sh` fails with a cache or plist permission error, rerun the same command with the required permission rather than treating it as a project failure.
