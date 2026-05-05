---
title: Examples
description: Real-world spells.yaml examples for Swift, Node.js, Python, static sites, Docker, database migrations, monorepos with extends, and home manifests.
---

A grab-bag of `spells.yaml` files copy-pasteable into real projects. Each example is a complete manifest — drop it in your project root, run `spells`, and the wrappers come live.

## Swift project

```yaml
build: swift build -c release

test:
  aliases: [t]
  script: swift test ...args

format: swift-format format --in-place --recursive Sources Tests

lint: swiftlint --strict
```

```sh
spells
build              # swift build -c release
t --filter Foo     # swift test --filter Foo
format
```

## Node.js / Bun project

```yaml
dev: bun run dev

test:
  aliases: [t]
  script: bun test ...args

lint:
  silent: true
  script: bun run lint

deploy:
  switch:
    staging:    bun run deploy:staging
    production: bun run deploy:production
  default: staging
```

## Python project

```yaml
spells:
  venv:
    script: |
      rm -rf .venv
      python3 -m venv .venv
      .venv/bin/pip install -e '.[dev]'

  run:
    script: .venv/bin/python -m myapp ...args

  test:
    script: .venv/bin/pytest ...args

  fmt:
    script: |
      .venv/bin/ruff format .
      .venv/bin/ruff check --fix .
```

## Static site

```yaml
dev: bun run dev
build: bun run build
preview: bun run preview --host

deploy:
  description: Push the built site to GitHub Pages.
  script: |
    bun run build
    git -C dist init
    git -C dist add .
    git -C dist commit -m "Deploy"
    git -C dist push -f origin HEAD:gh-pages
```

## Docker

```yaml
up: docker compose up -d
down: docker compose down

logs:
  script: docker compose logs -f ...args

shell:
  description: Open a shell in the named container.
  script: docker compose exec ...args bash
```

```sh
logs                 # tails all services
logs api             # tails the api service
shell api            # opens a bash in the api container
```

## Database migrations

```yaml
db:
  switch:
    migrate:
      switch:
        up:     ./scripts/db migrate up
        down:   ./scripts/db migrate down
        status: ./scripts/db migrate status
      default: status
    seed:
      params:
        dataset:
          values: [small, full]
          default: small
      script: ./scripts/db seed {{dataset}}
    reset:
      description: Drop, recreate, migrate, and seed.
      script: |
        ./scripts/db reset
        ./scripts/db migrate up
        ./scripts/db seed small
```

```sh
db migrate           # ./scripts/db migrate status (default)
db migrate up
db seed              # ./scripts/db seed small
db seed full
db reset
```

## Monorepo with `extends`

A team-wide parent manifest at `~/team/spells.yaml`:

```yaml
spells:
  test:
    script: turbo run test ...args
  build: turbo run build
  lint: turbo run lint
```

A per-package child manifest in `apps/web/spells.yaml`:

```yaml
extends: ../../../team/spells.yaml
spells:
  dev: turbo run dev --filter web

  # `build` is inherited from the parent.
  # Override it locally:
  build: turbo run build --filter web --concurrency=4
```

Closer-manifest-wins on whole-spell conflicts. The child's `dev` is added; the child's `build` replaces the parent's.

## Override an existing command

```yaml
spells:
  cat:
    override: true
    script: "{{cat}} -n ...args"

  ls:
    override: true
    script: "{{ls}} --color=auto ...args"
```

```sh
cat README.md       # /usr/bin/cat -n README.md
ls -la              # /bin/ls --color=auto -la
```

`{{cat}}` resolves to the next external `$PATH` match outside `~/.spellbook/bin`.

## Personal home manifest

`~/spells.yaml` — used as the fallback when no project manifest is found in the current directory chain:

```yaml
spells:
  g:
    description: Pretty git log.
    script: git log --oneline --graph --decorate ...args

  clean-branches:
    description: Delete merged local branches.
    script: |
      git fetch --prune
      git branch --merged | grep -vE '^\*|main|master' | xargs -r git branch -d

  ports:
    description: Show open TCP listeners.
    script: lsof -nP -iTCP -sTCP:LISTEN
```

Spells in the home manifest are available everywhere you don't have a project manifest. See `spells doctor` for the discovered fallback path.
