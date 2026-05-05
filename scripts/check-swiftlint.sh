#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f .swiftlint.yml ]]; then
  echo "Spellbook quality gate: .swiftlint.yml not found; skipping swiftlint."
  exit 0
fi

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "Spellbook quality gate: swiftlint not installed; skipping lint locally (CI/container must enforce)."
  exit 0
fi

echo "Spellbook quality gate: swiftlint"
swiftlint lint --config .swiftlint.yml