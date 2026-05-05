#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Spellbook quality gate: no SwiftLint bypasses"

if grep -R -n 'swiftlint:disable' Sources Tests 2>/dev/null; then
  echo "error: do not bypass SwiftLint; refactor instead"
  exit 1
fi

