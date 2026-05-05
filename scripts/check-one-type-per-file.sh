#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Spellbook quality gate: one top-level type per file"

while IFS= read -r file; do
  base="$(basename "$file")"
  if [[ "$base" == "main.swift" ]]; then
    continue
  fi

  count="$(grep -cE '^((public|internal|private|fileprivate|open|final)[[:space:]]+)*(struct|class|enum|actor|protocol)[[:space:]]' "$file" || true)"
  if (( count > 1 )); then
    echo "error: $file declares $count top-level types; max is 1"
    exit 1
  fi
done < <(find Sources Tests -name '*.swift' -type f 2>/dev/null)

