#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Spellbook quality gate: naming rules"

if find Sources Tests \( -name '*Manager.swift' -o -name '*Helper.swift' -o -name '*Utils.swift' -o -name '*Util.swift' \) -type f 2>/dev/null | grep -q .; then
  echo "error: avoid *Manager/*Helper/*Utils/*Util files; name the domain responsibility explicitly"
  find Sources Tests \( -name '*Manager.swift' -o -name '*Helper.swift' -o -name '*Utils.swift' -o -name '*Util.swift' \) -type f 2>/dev/null
  exit 1
fi

if grep -R -n -E '^(public |internal |private |fileprivate |open )?(final )?(class|struct|actor|enum) [A-Za-z0-9_]*(Manager|Helper|Utils|Util)\b' Sources Tests 2>/dev/null; then
  echo "error: avoid *Manager/*Helper/*Utils/*Util types; name the domain responsibility explicitly"
  exit 1
fi
