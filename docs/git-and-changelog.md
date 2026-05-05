# Git And Changelog

Use this guide only when the user asks for a commit, commit message, changelog decision, or release-note decision.

## Commit Workflow

Use the `commit` skill when committing.

Before every commit:

- Check `git status --short --ignored`.
- Identify unrelated user changes and leave them alone.
- Decide whether `CHANGELOG.md` needs an `[Unreleased]` entry.
- Run `scripts/check.sh`.
- Stage only files related to the task.

## Commit Format

Use Conventional Commits:

```text
<type>(<scope>): <summary>
```

Examples:

```text
docs(agent): split Claude guidance into docs
test(parser): cover scalar block sequences
feat(parser): parse canonical manifests
fix(args): reject ambiguous param aliases
refactor(core): extract placeholder escaping
```

Do not add AI/tool attribution, `Co-authored-by`, `Generated-by`, `Created-by`, model/vendor names, or emoji.

## Changelog Policy

`CHANGELOG.md` follows Keep a Changelog. Update `[Unreleased]` for user-facing or release-relevant changes:

- New commands.
- Manifest syntax changes.
- Behavior changes.
- Important bug fixes.
- Packaging or install changes.
- Security or compatibility notes.

Do not add changelog entries for routine refactors, internal tests, mechanical cleanup, or planning-only edits unless the user asks.
