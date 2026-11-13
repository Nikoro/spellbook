#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

scripts/quality/python.sh scripts/quality/check_duplicates.py "$@"

checks=(
  "scripts/check-file-size.sh"
  "scripts/check-one-type-per-file.sh"
  "scripts/check-naming.sh"
  "scripts/check-architecture.sh"
  "scripts/check-swiftlint.sh"
  "scripts/check-swiftlint-directives.sh"
  "scripts/check-swift-build.sh"
  "scripts/check-swift-test.sh"
  "scripts/audit-design.sh"
)

for check in "${checks[@]}"; do
  "$check"
done
