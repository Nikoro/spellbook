#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Spellbook quality gate: Swift file length"

while IFS= read -r file; do
  lines="$(wc -l < "$file" | tr -d ' ')"
  if (( lines > 200 )); then
    echo "error: $file has $lines lines; max is 200"
    exit 1
  fi
done < <(find Sources Tests -name '*.swift' -type f 2>/dev/null)

