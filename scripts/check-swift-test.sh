#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f Package.swift ]]; then
  echo "Spellbook quality gate: Package.swift not found; skipping swift test until Week 1 scaffolding exists."
  exit 0
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "Spellbook quality gate: swift toolchain not installed; skipping swift test (CI must enforce)."
  exit 0
fi

echo "Spellbook quality gate: swift test"

# On Linux, `swift test` intermittently hangs while running the XCTest bundle.
# Workaround: build the test binary once, then run every test suite in its own
# process with a short timeout. On hang we retry once. macOS can use the
# upstream `swift test` path.
if [[ "$(uname -s)" != "Linux" ]]; then
  swift test
  exit 0
fi

swift build --build-tests >/dev/null

binary=".build/debug/spellsPackageTests.xctest"
if [[ ! -x "$binary" ]]; then
  echo "error: test binary not found at $binary" >&2
  exit 1
fi

module="SpellbookTests"
mapfile -t suites < <(
  find Tests/"$module" -name '*Tests.swift' -type f \
    | sed -E 's#.*/([^/]+)\.swift$#\1#' \
    | sort -u
)

if [[ ${#suites[@]} -eq 0 ]]; then
  echo "error: no test suites discovered under Tests/$module" >&2
  exit 1
fi

run_suite() {
  local suite="$1"
  local tmp
  tmp="$(mktemp)"
  if timeout 20 stdbuf -o0 -e0 "$binary" "$module.$suite" >"$tmp" 2>&1; then
    if grep -q "Executed .* with 0 failures" "$tmp"; then
      rm -f "$tmp"
      return 0
    fi
  fi
  cat "$tmp"
  rm -f "$tmp"
  return 1
}

failed=()
for suite in "${suites[@]}"; do
  if run_suite "$suite"; then
    echo "  ok  $suite"
    continue
  fi
  echo "  retry $suite"
  if run_suite "$suite"; then
    echo "  ok  $suite (after retry)"
    continue
  fi
  failed+=("$suite")
  echo "  FAIL $suite"
done

if [[ ${#failed[@]} -gt 0 ]]; then
  echo "error: failing suites: ${failed[*]}" >&2
  exit 1
fi

echo "Spellbook quality gate: swift test OK (${#suites[@]} suites)"
