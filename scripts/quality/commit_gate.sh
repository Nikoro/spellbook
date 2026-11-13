#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
GATE="$ROOT/.tools/commit_gate"
cd "$ROOT"
if [[ ! -f "$GATE/__main__.py" ]] || [[ ! -d "$GATE/.git" ]]; then
  printf >&2 'commit_gate is missing or is not a clone at %s; run scripts/hooks/install.sh.\n' "$GATE"
  exit 2
fi
if ! checkout_status="$("$ROOT/scripts/quality/commit_gate_git.sh" --git-dir="$GATE/.git" --work-tree="$GATE" status --porcelain)"; then
  printf >&2 'commit_gate is not a valid Git checkout at %s; repair the installation.\n' "$GATE"
  exit 2
fi
if [[ -n "$checkout_status" ]]; then
  printf >&2 'commit_gate has local changes at %s; fix the shared repository, then run scripts/hooks/install.sh.\n' "$GATE"
  exit 2
fi
exec "$ROOT/scripts/quality/python.sh" "$GATE" "$@"
