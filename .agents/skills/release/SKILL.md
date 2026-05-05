---
name: release
description: Automate release preparation for Spellbook. Determines version bump, updates SpellbookVersion.swift / CHANGELOG.md / homebrew formula, commits, tags, and pushes. Use when the user wants to publish a new release.
---

You are preparing a new release for **Spellbook**, a macOS-first CLI (`spells`) that turns project-scoped YAML spellbooks into shell commands. The user may optionally provide a version number or bump keyword.

## Step 1: Parse User Input

Extract from `$ARGUMENTS`:
- **Explicit version** (e.g., `0.2.0`, `1.0.0`) — use this exact version
- **Bump keyword** (`major`, `minor`, or `patch`) — apply this bump to the current version
- **Empty** — auto-determine the bump type from commit analysis

## Step 2: Pre-flight Checks

Run these checks before doing anything else. If any fail, **abort immediately** with a clear error message.

1. **Clean working tree**: Run `git status --porcelain`. If there is any output, abort — tell the user to commit or stash their changes first.
2. **On main branch**: Run `git branch --show-current`. If the result is not `main`, abort — tell the user to switch to `main`.
3. **In sync with remote**: Run `git fetch origin main` then compare `git rev-parse HEAD` with `git rev-parse origin/main`. If they differ, abort — tell the user to pull or push first.
4. **`gh` CLI authenticated** (best-effort): Run `gh auth status`. If it fails, warn the user — push will still trigger CI, but follow-up monitoring will need manual gh login.

## Step 3: Quality Gates

Run the project's quality gates. If anything fails, **abort** and ask the user to fix the issues first.

```bash
scripts/check.sh
```

`scripts/check.sh` runs build, tests, SwiftLint, architecture/naming/file-size checks, and SwiftLint directive policy. Do **not** run `scripts/e2e.sh` here — it is heavier and the same gate runs in CI on the tag push (see `.github/workflows/release.yml`). Mention this to the user if the local check passes.

## Step 4: Analyze Commits & Determine Version

1. Get the latest git tag: `git describe --tags --abbrev=0` (if no tags exist yet — Spellbook has none at the time of writing — treat **all** commits as new and use `git log --oneline` instead).
2. Get current version from `Sources/SpellbookKit/SpellbookVersion.swift` (the `current` constant; expect a value like `"0.1.0-dev"`).
3. List all commits since the latest tag: `git log <latest_tag>..HEAD --oneline` (or full log if no tags).
4. Parse each commit using Conventional Commits format (`type(scope): description`):
   - Extract the **type** (e.g., `feat`, `fix`, `refactor`)
   - Extract the **scope** if present
   - Extract the **description**
   - Check for breaking changes: `BREAKING CHANGE:` in body/footer or `!` after type (e.g., `feat!:`)

5. **Determine version bump** (unless user provided explicit version or keyword):
   - Any breaking change → **MAJOR** bump
   - Any `feat` commit → **MINOR** bump
   - Only `fix`, `refactor`, `style`, `perf`, `docs` → **PATCH** bump
   - No user-facing commits (only `chore`, `test`, `ci`, `build`) → Use `AskUserQuestion` to ask whether to proceed with a PATCH release or abort

   **Pre-1.0 nuance:** while Spellbook is on `0.x`, breaking changes do **not** force a `1.0.0` jump. Treat breaking changes as a **MINOR** bump (`0.1.0 → 0.2.0`) and surface this in the summary so the user can override.

6. If user provided a bump keyword (`major`/`minor`/`patch`), apply it to the current version. Strip any pre-release suffix (`-dev`, `-rc.1`, etc.) before bumping.
7. If user provided an explicit version, validate it is higher than the current version (semver comparison, ignoring pre-release suffix).

## Step 5: Generate CHANGELOG Entry

Map commits to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) categories. Spellbook already follows this format and uses Conventional Commits (see `docs/git-and-changelog.md`).

| Commit type          | CHANGELOG category | Include? |
|----------------------|--------------------|----------|
| `feat`               | **Added**          | Yes      |
| `fix`                | **Fixed**          | Yes      |
| `refactor`           | **Changed**        | Yes      |
| `style`              | **Changed**        | Yes      |
| `perf`               | **Changed**        | Yes      |
| `chore`              | —                  | Skip     |
| `test`               | —                  | Skip     |
| `ci`                 | —                  | Skip     |
| `build`              | —                  | Skip     |
| `docs`               | —                  | Skip     |
| `chore(release)`     | —                  | Skip     |

Rules:
- **Prefer existing `[Unreleased]` content over re-deriving from commit log.** Spellbook's policy (`docs/git-and-changelog.md`) is to update `[Unreleased]` as features land. If there are entries already there, treat them as the source of truth and only add anything missing from commits since the last tag.
- **Only include categories that have actual entries.** Do NOT add empty categories.
- Write **human-friendly descriptions**, not raw commit messages.
- Group related commits when appropriate.

Format:
```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added

- Feature description

### Fixed

- Fix description
```

## Step 6: Review & Confirm

Present a summary to the user before making any file changes:

```
Release Summary
───────────────
Current version: A.B.C
New version:     X.Y.Z (BUMP_TYPE bump)

Commits since last release: N total (M user-facing, K skipped)

CHANGELOG preview:
──────────────────
## [X.Y.Z] - YYYY-MM-DD

### Added
- ...

### Fixed
- ...
```

Use `AskUserQuestion` to confirm: "Does this release summary look correct? Should I proceed with updating files?"

Allow the user to request edits to the CHANGELOG content before proceeding.

## Step 7: Update Files

1. **`Sources/SpellbookKit/SpellbookVersion.swift`**: Update `current` to the new version (no `-dev` suffix on a release).

2. **`CHANGELOG.md`**: Move entries currently under `## [Unreleased]` into a new `## [X.Y.Z] - YYYY-MM-DD` section directly below it. Leave `## [Unreleased]` empty (no category subheadings under it). The current `CHANGELOG.md` does **not** maintain comparison links at the bottom — do not invent any.

3. **`homebrew/spellbook.rb`** — leave the file alone. It is a template (`version "0.0.0"`, `REPLACE_WITH_*_SHA256` placeholders) rendered post-release by `homebrew/bump.sh vX.Y.Z`. Touching it here would corrupt the template. Mention `homebrew/bump.sh` in Step 11 instead.

## Step 8: Commit & Tag

1. Stage changes: `git add Sources/SpellbookKit/SpellbookVersion.swift CHANGELOG.md`
2. Create commit (Conventional Commits, no AI attribution per `docs/git-and-changelog.md`):
   ```
   git commit -m "chore(release): bump version to X.Y.Z"
   ```
3. Create annotated tag (the `release.yml` workflow triggers on `v*`):
   ```
   git tag -a vX.Y.Z -m "Release version X.Y.Z"
   ```

## Step 9: Verify Local Build

Rebuild release binary so the local `spells` binary carries the new version string:

```bash
swift build -c release
"$(swift build -c release --show-bin-path)/spells" --version 2>&1 | tail -3
```

Confirm the printed version matches `X.Y.Z`. If the build fails, warn the user but do **not** abort — the release commit and tag are already created locally and CI will rebuild on push.

## Step 10: Push to Repository

**IMPORTANT**: Pushing the tag triggers `.github/workflows/release.yml`, which:
1. Runs `scripts/check.sh` and `scripts/e2e.sh` as quality gates.
2. Builds release binaries on `macos-15` (arm64) and `macos-13` (x86_64).
3. Creates a GitHub Release with `spells-macos-arm64`, `spells-macos-x86_64`, and matching `.sha256` files, using auto-generated release notes.

Use `AskUserQuestion` to confirm: "Ready to push? This will trigger the GitHub Actions release build and publish a GitHub Release with the spells binaries."

If confirmed:
```
git push origin main --follow-tags
```

After pushing, inform the user:
- The `release.yml` workflow has been triggered.
- They can monitor: `gh run watch` or the repo's Actions tab.
- The GitHub Release will appear at `https://github.com/Nikoro/spellbook/releases/tag/vX.Y.Z` once the workflow finishes.

## Step 11: Post-Release — Homebrew Formula (optional)

After the GitHub Release is live (the `.sha256` artifacts must exist), the Homebrew formula can be regenerated. The tap (`Nikoro/homebrew-spellbook`) is **not yet published** as of writing — `homebrew/README.md` says it lands at 1.0. Mention this nuance to the user.

To render the formula for the new tag:
```
homebrew/bump.sh vX.Y.Z > /tmp/spellbook.rb
```

Show the diff vs. the in-repo template and ask the user whether to:
- commit the rendered formula to the future tap repo (manual, when the tap exists), or
- skip Homebrew bump for this release.

Do **not** overwrite `homebrew/spellbook.rb` in this repo — it must stay a template.

## Rollback Instructions

If something goes wrong after push:
```bash
# Delete remote tag (also cancels in-flight workflow effects on Releases not yet created)
git push origin :refs/tags/vX.Y.Z
# Delete local tag
git tag -d vX.Y.Z
# Revert the release commit
git revert HEAD
git push origin main
# If a GitHub Release was already created, delete it:
gh release delete vX.Y.Z --yes
```
