# Roadmap

Product scope and pending work live here. [Architecture](architecture.md) owns the
layer boundaries; [product decisions](product-decisions.md) owns the public contract.
This is a planning document, not a record of previous agent sessions or test runs.

## Product scope

- A macOS executable, `spells`, and a dependency-free `SpellbookKit` library.
- A custom YAML parser, manifest discovery and inheritance, validation, parameter
  resolution, overrides, placeholders and explicit shell execution.
- Atomic activation writes, versioned state, per-spell origins and a process lock
  protecting concurrent wrapper/state updates.
- Interactive choices with terminal capability detection and a numbered fallback.
- Structured diagnostics, root and spell help, listing, doctor, create, init,
  clean, diff and activation summaries.
- Root-command completion plus wrapper-level completion through the completion
  oracle, manifest cache, fuzzy ranking and terminal picker.
- An Apple Silicon release binary, curl installer and draft Homebrew formula.

[Testing](testing.md) defines the verification required for changes;
[quality gates](quality-gates.md) defines release performance and E2E criteria.
Past measurements and completed work remain in git and the changelog. A passing
historical run is not evidence that the current checkout passes.

### Phase 3 follow-ups

- `spells run <wrapper>` does not write the manifest cache on its success path because `RunResolver` does not surface `ActivationResult`. Completion still works because the first activation / list / doctor / diff / clean populates the cache, and subsequent completions validate freshness against extends-chain mtimes.
- `DevTTYSource` restores termios via `defer` but does not install signal handlers (SIGINT / SIGTERM / SIGWINCH). Killing a picker mid-session with Ctrl-C still cleans up because `defer` fires; proactive signal forwarding is a polish item.
- A shell-subprocess E2E suite (driving real zsh/bash/fish under PTY and asserting on the command line mutation) is a release-hardening item. Current coverage stops at the oracle + headless picker; zsh and bash 5 were live-walked through QA 31.* on 2026-04-22.
- Fish was not live-verified on the 2026-04-22 host (fish not installed). The contract is enforced by unit tests.
- TAB after `<wrapper> ` (trailing space) on a no-params spell makes the oracle emit a `runAsIs` candidate with an empty value rather than the `endOfGrammarFallThrough` sentinel. zsh and bash handlers parse the empty value as a no-op candidate and silently no-op, so file completion never fires. Spec FR-51 expects fallthrough in this position. The no-space variant (`<wrapper><TAB>`) takes the `cword == 0` branch in `WrapperCompletionResolver.resolveNoSpaceTab` and works correctly. Fix: extend the equivalent detection to the `cword >= 1` path (probably promote any `runAsIs`-only result into `endOfGrammarFallThrough` in `WrapperCompletionResolver` so handlers don't have to special-case it).

## Open Questions And Deferred Decisions

These were intentionally not decided at MVP time. None of them block the first public release.

### CLI / packaging

- What final public URL, repository release path, and domain should the curl installer use?
- Should the Homebrew tap ship with the first public MVP, or remain a draft until after initial user feedback? ([`homebrew/README.md`](../homebrew/README.md) plans the dedicated `Nikoro/homebrew-spellbook` tap for 1.0.)
- What exact README examples should be treated as canonical public examples for the first release?
- How much Linux verification should be done before mentioning Linux as experimental rather than unsupported?

### Phase 3 wrapper completion (post-v1)

- Should flag aliases and switch aliases ever be rendered in the picker (as a secondary column, or via a "verbose picker" toggle)? Deferred from v1 — picker shows canonical names only.
- Should `override: true` wrappers optionally delegate to the overridden binary's own shell completion once Spellbook's grammar is exhausted? Deferred from v1 — v1 falls through to file completion.
- Should passthrough (`...args`) ever be completion-aware (e.g. delegate to the wrapped command's completion as declared in a manifest hint)? Out of scope for v1.
- Orphan cache cleanup: when a project directory is deleted, its `manifest.bin` lingers in `$SPELLBOOK_HOME/state/`. Should `spells doctor` reap orphans, or is a lazy size cap acceptable? Not blocking v1.
- What exact cache-hit latency target do we want to assert in release-mode smoke tests (e.g. p95 under 10 ms on a 50-spell manifest)? Pick after an initial measurement.

### Website (post-launch)

See [`website.md`](./website.md) for the website-specific deferred list (custom domain, JSON-LD structured data, Algolia DocSearch, PR previews, Lighthouse CI, blog/RSS, per-page OG images, recorded demo video).

## Release milestones

1. Resolve a parameterized command entirely through Core.
2. Exercise override and subprocess behavior through CLI adapters.
3. Verify pickers and silent mode in a real terminal and in dumb-terminal mode.
4. Render structured errors and help through the public executable.
5. Activate atomic wrappers and versioned state, then execute an installed wrapper.
6. Run the complete unit/integration gates and release-mode E2E scenarios.
7. Verify release artifacts and installation with the supported shell matrix.

## Risks

- YAML edge cases need focused parser tests and a realistic fixture corpus.
- Terminal behavior varies in tmux, SSH and uncommon emulators; test fallback modes.
- Shell availability varies; keep the macOS-first support statement and explicit overrides.
- Inheritance through symlinks needs canonical path cycle detection.
- Chatty commands need bounded buffering and live fallback.
- State evolution needs version refusal or migration and actionable doctor errors.
- Concurrent activations must hold the state lock across wrapper and state writes.

No release, deployment or publication follows automatically from this checklist.
