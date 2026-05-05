---
name: commit
description: Prepare and create repository commits using Conventional Commits, quality gates, changelog policy, and clean attribution. Use when the user asks to commit, prepare a commit, write commit messages, or decide whether changelog entries are needed.
---

# Commit Workflow

Use this skill whenever creating or preparing a commit.

## Rules

- Use Conventional Commits: `<type>(<scope>): <summary>`.
- Keep summaries imperative, lowercase after the scope unless a proper noun requires capitalization.
- Prefer domain scopes: `manifest`, `parser`, `args`, `validation`, `runtime`, `wrappers`, `state`, `doctor`, `errors`, `tooling`, `docs`, `ci`, `release`.
- Commit only changes relevant to the user's request.
- Never add AI branding or attribution trailers.
- Never add `Co-authored-by`, `Generated-by`, `Created-by`, tool signatures, emojis, or model/vendor names to commit messages.
- Run `scripts/check.sh` before committing.
- If checks fail, fix the issue or report the blocker. Do not commit failing code.

## Types

- `feat` — user-facing feature
- `fix` — bug fix
- `test` — tests only
- `docs` — documentation
- `chore` — tooling, config, repo setup
- `refactor` — behavior-preserving restructuring
- `perf` — performance
- `ci` — CI/release automation

## Changelog Policy

Spellbook uses Keep a Changelog.

Update `CHANGELOG.md` under `[Unreleased]` only for notable user-facing or release-relevant changes:

- new commands or flags
- manifest syntax changes
- behavior changes
- important bug fixes
- packaging/install changes
- security or compatibility notes

Do not update the changelog for internal-only refactors, test-only changes, mechanical cleanup, or planning churn unless the user asks.

In the final response, state either:

- `Changelog: updated under [Unreleased].`
- `Changelog: not updated, internal-only change.`

## Procedure

1. Inspect `git status --short --ignored`.
2. Review the diff for unrelated or ignored files.
3. Decide whether `CHANGELOG.md` needs an `[Unreleased]` entry.
4. Run `scripts/check.sh`.
5. Stage only relevant files.
6. Commit with a Conventional Commit message and no trailers.
7. Report the commit hash, message, checks, changelog decision, and any ignored local reference files.
