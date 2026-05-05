#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Spellbook quality gate: architecture boundaries"

MODELS_DIR="Sources/SpellbookKit/Models"
CORE_DIR="Sources/SpellbookKit/Core"

if [[ -d "$MODELS_DIR" ]] && grep -R -n '^import Foundation' "$MODELS_DIR" 2>/dev/null; then
  echo "error: Models must not import Foundation"
  exit 1
fi

if [[ -d "$CORE_DIR" ]] && grep -R -n -E '\b(FileManager|Process)\b' "$CORE_DIR" 2>/dev/null; then
  echo "error: Core must not use FileManager or Process directly; inject protocols instead"
  exit 1
fi

if [[ -d "$CORE_DIR" ]] && grep -R -n -E '\b(print|exit)\s*\(' "$CORE_DIR" 2>/dev/null; then
  echo "error: Core must not print or exit; return values or throw SpellbookError"
  exit 1
fi

