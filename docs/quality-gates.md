# Quality Gates

Website Biome adoption is a separate follow-up requiring an owner decision; this
rollout keeps the current site build and observable smoke checks. The approved
new developer checks are ShellCheck and Ruff for changed shell/Python tooling;
additional static type and duplicate-code analysis remain deferred.

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
- **Simple spell execution** finishes in under **750 ms**. Execution traverses the generated wrapper, `spells run`, manifest resolution, and the target shell, so this remains a realistic macOS compatibility budget.

Verification requirements are recorded in [`verification.md`](./verification.md).

## Release-Blocking E2E

`scripts/e2e.sh` is intentionally **not** part of the per-change quality gate, but it is **release-blocking** once scenarios exist for the change. Run it before tagging a release.

## Common Fixes

If a file is too long, split by domain type or responsibility.

If a function is too long or nested, extract a named domain operation or use guard clauses.

If a type name is generic, rename it to the Spellbook concept it represents.

If Core needs I/O, introduce or reuse a protocol and keep the implementation in CLI or a protocol adapter.

## Sandbox Note

Swift may need to write build/cache files outside the workspace on macOS. If `scripts/check.sh` fails with a cache or plist permission error, rerun the same command with the required permission rather than treating it as a project failure.


## Shared commit gates

Run `scripts/hooks/install.sh` to clone or fast-forward the clean shared tool in
ignored `.tools/commit_gate` and configure `scripts/hooks`. Git access and Python
>=3.11 are required. Missing, invalid or dirty installations block commits with a
repair command. Fix the shared tool upstream, never in the installed copy.

Pre-commit runs `commit_gate staged --no-review`, lightweight hook tests, the
unchanged `scripts/check.sh` sequence above, a whole-tree gate audit, then
`review --check` last. E2E remains a separate release check. Finalize staging,
run `scripts/quality/commit_gate.sh review`, start the fresh reviewer named by the
brief, and use `scripts/quality/commit_gate.sh trailers` for required trailers.
Commit-msg enforces the reviewed fingerprint and the required answers.

All five shared gates are enabled in `commit_gate.toml`. Mirror scope covers Core
and CLI behavior, with exact mappings for split helpers, real command-routing
integration tests, error snapshots and filesystem/process adapter suites. Models
and protocols remain immutable values and I/O seams with coverage through users.
The low-level `DevTTYSource` adapter retains the testing policy's specific manual
TTY exemption; picker logic is tested through the injected TTYSource harness.
The executable entrypoint delegates to the tested router. No blanket source or
documentation exception hides comments or journals.

`AGENTS.md` is the instruction index; `CLAUDE.md` imports it. Durable constraints
live in topic documents. Pending work belongs in the roadmap or task files;
completed session logs remain in git. The roadmap is present-tense scope and pending
work rather than checked-off historical progress.

## Developer analysis tools

Optional ShellCheck and Ruff checks are approved for repository tooling and run
when installed. They remain developer tools, never application dependencies.
Static type checking and duplicate scanning are deferred; adding them requires
an owner decision rather than a new mandatory runtime dependency.
