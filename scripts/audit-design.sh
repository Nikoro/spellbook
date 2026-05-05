#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Spellbook design audit: pattern/refactor candidates (warning-only)"

if [[ ! -d Sources ]]; then
  echo "Spellbook design audit: Sources not found; skipping until Swift scaffolding exists."
  exit 0
fi

swift_files="$(find Sources Tests -name '*.swift' -type f 2>/dev/null || true)"
if [[ -z "$swift_files" ]]; then
  echo "Spellbook design audit: no Swift files found."
  exit 0
fi

warned=0

warn() {
  warned=1
  echo "warning: $1"
}

if grep -R -n -E '^(public |internal |private |fileprivate |open )?(final )?(class|struct|actor|enum) [A-Za-z0-9_]*(Service|Processor|Handler)\b' Sources Tests 2>/dev/null; then
  warn "generic type names (*Service/*Processor/*Handler) found; justify them or prefer domain names"
fi

if grep -R -n -E 'switch .*\\{|case ' Sources/spells/Core 2>/dev/null | awk -F: '{ count[$1]++ } END { for (file in count) if (count[file] >= 8) print file ":" count[file] }' | grep -q .; then
  echo "review candidates: Core files with many switch/case branches"
  grep -R -n -E 'switch .*\\{|case ' Sources/spells/Core 2>/dev/null | awk -F: '{ count[$1]++ } END { for (file in count) if (count[file] >= 8) print "  " file " (" count[file] " switch/case lines)" }'
  warn "consider whether behavior belongs on an enum, rule type, strategy, or renderer"
fi

if grep -R -n -E 'Regex|NSRegularExpression|#/' Sources/spells/Core 2>/dev/null | awk -F: '{ count[$1]++ } END { for (file in count) if (count[file] >= 3) print file ":" count[file] }' | grep -q .; then
  echo "review candidates: Core files with repeated regex usage"
  grep -R -n -E 'Regex|NSRegularExpression|#/' Sources/spells/Core 2>/dev/null | awk -F: '{ count[$1]++ } END { for (file in count) if (count[file] >= 3) print "  " file " (" count[file] " regex lines)" }'
  warn "consider named parsers/value objects instead of scattered regexes"
fi

if grep -R -n -E 'init\\([^)]*,[^)]*,[^)]*,[^)]*,[^)]*\\)' Sources 2>/dev/null; then
  warn "initializer with many parameters found; consider an input struct or smaller type"
fi

if grep -R -n -E '"[A-Z0-9_]{3,}"|\"--[a-zA-Z0-9_-]+\"|\"[a-zA-Z0-9_]+:\"' Sources/spells/Core 2>/dev/null | awk -F: '{ count[$1]++ } END { for (file in count) if (count[file] >= 8) print file ":" count[file] }' | grep -q .; then
  echo "review candidates: Core files with many protocol/manifest string literals"
  grep -R -n -E '"[A-Z0-9_]{3,}"|\"--[a-zA-Z0-9_-]+\"|\"[a-zA-Z0-9_]+:\"' Sources/spells/Core 2>/dev/null | awk -F: '{ count[$1]++ } END { for (file in count) if (count[file] >= 8) print "  " file " (" count[file] " literal lines)" }'
  warn "consider named constants or domain value objects"
fi

if (( warned == 0 )); then
  echo "Spellbook design audit: no obvious refactor-pattern candidates."
else
  echo "Spellbook design audit: review warnings above during Senior Refactor Pass."
fi

exit 0
