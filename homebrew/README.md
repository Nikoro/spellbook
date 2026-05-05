# Homebrew tap (draft)

Draft Homebrew formula for Spellbook. Lives inside the main repo until the
dedicated tap (`Nikoro/homebrew-spellbook`) is published; that way a single PR
bumps version, URL, and SHA256 together.

## Files

- `spellbook.rb` — formula template. `version`, `sha256` placeholders get filled
  in per release.
- `bump.sh` — convenience script that fetches the published SHA256 files from a
  GitHub Release, rewrites `spellbook.rb`, and writes it to stdout.

## Publishing the tap (post-1.0)

1. Create a dedicated repo `Nikoro/homebrew-spellbook` with a `Formula/`
   directory.
2. Copy `homebrew/spellbook.rb` (rendered for the current release) into
   `Formula/spellbook.rb` in that repo.
3. Users can then install with:
   ```sh
   brew tap nikoro/spellbook
   brew install spellbook
   ```
4. Each subsequent release: tag `vX.Y.Z` here, wait for `release.yml` to attach
   the binaries, then run `homebrew/bump.sh vX.Y.Z > ../homebrew-spellbook/Formula/spellbook.rb`
   in the tap repo and open a PR.

`homebrew-core` submission is explicitly out of scope until Spellbook has users
and stable API; the tap is the long-term distribution path alongside the curl
installer (`install.sh`).

## Local formula sanity check

```sh
brew install --build-from-source ./homebrew/spellbook.rb
```

Requires the release artifacts to exist at the expected URL first. For local
development prefer the curl installer path in `install.sh`.
