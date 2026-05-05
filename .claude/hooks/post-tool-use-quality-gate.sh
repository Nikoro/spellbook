#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

if [[ ! -x scripts/check.sh ]]; then
  echo "Spellbook quality gate: scripts/check.sh is missing or not executable."
  exit 1
fi

scripts/check.sh

