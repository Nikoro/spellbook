# Development Workflow

Use this guide when changing code as an agent. Product shape comes from [`architecture.md`](./architecture.md), exact behavior comes from [`product-decisions.md`](./product-decisions.md), and sequencing comes from [`roadmap.md`](./roadmap.md).

## Before Changing Code

Read the relevant architecture, product decision, roadmap, or module-map section first, then inspect the existing implementation and tests. Prefer local patterns over new abstractions.

If the requested behavior conflicts with the architecture principles or product decisions, call that out before implementing. If the docs are silent and the choice affects user-visible behavior, ask instead of guessing.

## Change Style

- Keep edits scoped to the requested behavior.
- Preserve `Models <- Core <- CLI`.
- Prefer domain names over generic names such as `Manager`, `Helper`, `Utils`, or `Util`.
- Add abstractions only when they remove real complexity or name a repeated domain rule.
- Keep models immutable and logic-free.
- Keep Core deterministic and free of direct I/O.
- Keep CLI responsible for filesystem, subprocesses, terminal state, rendering, and process exit codes.

## Refactor Pass

After tests are green, review changed files once before finalizing:

- Can a function be shorter without becoming clever?
- Did a repeated domain rule emerge that belongs in Core?
- Are names specific to Spellbook concepts?
- Are layer boundaries still clean?
- Do tests describe behavior through public APIs?
- Are error cases understandable to a user?

Do not refactor unrelated files while doing this pass.

## Documentation Changes

Keep `CLAUDE.md` as an index only. Put durable agent guidance in `docs/`, product shape changes in `docs/architecture.md`, behavior decisions in `docs/product-decisions.md`, and sequencing/status changes in `docs/roadmap.md` or `docs/project-status.md`.

Repo Markdown is written in English.
