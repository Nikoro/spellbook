#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f Package.swift ]]; then
  echo "Spellbook quality gate: Package.swift not found; skipping swift build until Week 1 scaffolding exists."
  exit 0
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "Spellbook quality gate: swift toolchain not installed; skipping swift build (CI must enforce)."
  exit 0
fi

echo "Spellbook quality gate: swift build"
swift build

