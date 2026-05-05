# Website

The Spellbook public website lives at [`nikoro.github.io/spellbook/`](https://nikoro.github.io/spellbook/) and is built from the [`website/`](../website/) directory in this repo. It hosts a custom landing page plus the canonical user documentation, separately from the internal docs in [`docs/`](.) (which target contributors and agents).

## Architecture

- **Astro 6 + Starlight** content site rooted at `website/`. The home route (`/`) is a hand-authored Astro page that bypasses the Starlight layout; all other routes live under `/docs/*` and `/changelog` and use Starlight.
- **Bun** is the package manager and runtime. `bun.lock` is committed; `npm`/`pnpm`/`yarn` are not used.
- **Astro config** sets `site: 'https://nikoro.github.io/spellbook'` and `base: '/spellbook'` so internal links and absolute URLs resolve under the GitHub Pages project subpath.
- **Content publishing pipeline** runs at build time, mirroring `src/content/docs/*.md` to `public/docs/*.md` (preserving frontmatter), generating `public/llms.txt` and `public/llms-full.txt`, and ingesting the repo-root [`CHANGELOG.md`](../CHANGELOG.md) into `src/content/docs/changelog.md`. The repo-root changelog is the single source of truth.
- **Search** is Pagefind, indexed at build time, accessible via the top-nav search box and `Cmd/Ctrl+K`.

## URL contracts

These are public contracts. AI agents and external links depend on them — do not break without a redirect plan.

- Every documentation page at `/docs/<slug>` has a sibling `/docs/<slug>.md` that returns the original markdown including frontmatter.
- `/llms.txt` lists every published `/docs/*` URL with a one-line description (sourced from each page's frontmatter `description`), in sidebar order.
- `/llms-full.txt` contains the full markdown of every published docs page concatenated in sidebar order with title separators.
- `/changelog.md` is also served as raw markdown.
- `/sitemap-index.xml` and `/robots.txt` are present and reference each other.

## Local development

```bash
cd website
bun install
bun dev
```

Serves at `http://localhost:4321/spellbook/`. Build with `bun run build`; the output goes to `website/dist/` and is what CI uploads to Pages.

## CI workflow

[`.github/workflows/site.yml`](../.github/workflows/site.yml) builds and deploys the site to GitHub Pages. It triggers only on changes under `website/**`, `CHANGELOG.md`, or the workflow file itself, so Swift-only commits do not rebuild the site. The pipeline:

1. Checkout, set up Bun.
2. Restore Astro/Pagefind cache.
3. `bun install --frozen-lockfile` and `bun run build`.
4. Lychee link checker (fails on internal 404; external links warn only).
5. Upload Pages artifact and deploy via `actions/deploy-pages@v4`.

GitHub Pages source must be set to "GitHub Actions" in repo settings (one-time manual step).

## Quality targets

- Lighthouse mobile (landing + at least one docs page): Performance ≥ 95, Accessibility ≥ 95, Best Practices ≥ 95, SEO = 100.
- Total uncached transfer for the landing page under 2 MB on dark theme first paint.
- Build + deploy in under 90 seconds on a warm cache.
- WCAG AA contrast on all body text in both dark and light themes.

## Testing posture

The site is content + static rendering, not algorithmic logic. Testing is biased toward observable behavior over unit tests of build scripts. There are intentionally no Vitest/Jest suites for the website; do not introduce them without a clear reason — the Swift TDD discipline ([`docs/testing.md`](./testing.md)) does not extend to the website.

The launch-time verification is:

- `bun run build` succeeds with zero errors and zero warnings.
- Lychee link checker passes on every CI run (zero internal 404s).
- Local smoke check (`bun dev`): landing renders, all docs pages render, sidebar lists every entry, top-nav links resolve, search returns results, theme toggle works, "Copy as Markdown" writes to clipboard.
- Deployed-site checks: every documented URL returns 200; every `/docs/<slug>.md` returns 200 and starts with `---`; `/llms.txt` and `/llms-full.txt` are non-empty plaintext and reference every docs page.

If the publishing module grows non-trivial transformation logic, add focused unit tests at that point — not before.

## Visual identity

- Brand wordmark and icon come from the repo-root `spellbook-wordmark.png` and `spellbook-icon.png`. The website uses optimized variants under `website/public/` (WebP + PNG fallback). The unoptimized originals must never be referenced from a site asset path.
- Accent palette is derived from the wordmark gradient: primary `#9B5CDC` (purple), secondary `#3DD9A1` (mint). The full gradient `linear-gradient(90deg, #3DD9A1 0%, #3FB8C9 35%, #6A78D6 70%, #9B5CDC 100%)` is the brand surface treatment used in hero accents and the wordmark itself.
- Dark canonical background: `#0E1015` (zinc-950 with a slight blue undertone, sampled from the wordmark background).
- Fonts: Geist (UI) and Geist Mono (code), with system font fallbacks defined.
- Default theme on first visit is dark; the toggle persists user choice via local storage.

## Deferred decisions

These were intentionally out of scope for the launch. Add only when there is a concrete reason — most are speculative until traffic data justifies them.

- **Custom domain.** Initial launch uses `nikoro.github.io/spellbook/`. Migration requires updating `astro.config.mjs#site`, removing `base`, and adding a `CNAME` file. No content rewrite needed.
- **Light mode parity.** Dark mode is the canonical brand expression; light mode works (Starlight default) but is not polished.
- **Per-page generated Open Graph images.** A single global `/og.png` is used for every page on launch.
- **JSON-LD structured data** (`SoftwareApplication`, `TechArticle`). Marginal value at the current site size.
- **Algolia DocSearch.** Pagefind is sufficient for the launch documentation size.
- **PR previews** via Cloudflare Pages or Netlify.
- **Lighthouse CI** that fails builds on score regression.
- **A blog or news section.** Updates flow through `CHANGELOG.md` and GitHub Releases.
- **An RSS feed for the changelog.** GitHub Releases already publishes one at `releases.atom`.
- **A dedicated `/comparison` docs page.** The landing page contains a comparison section.
- **Demo video as `.webm`/`.mp4`.** The hero currently uses an animated CSS demo (`data-demo-step` sequence in `src/pages/index.astro`); a recorded video is a possible future replacement, not a regression to fix.
- **Reuse of internal `docs/*.md` files** (`product-decisions.md`, `roadmap.md`, etc.) as user-facing content. Those remain internal specifications; site documentation is freshly written for the end user.
