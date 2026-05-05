#!/bin/sh
# Render homebrew/spellbook.rb for a specific release tag.
# Usage: homebrew/bump.sh v1.0.0 > Formula/spellbook.rb
set -eu

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <tag>" >&2
    echo "  example: $0 v1.0.0" >&2
    exit 1
fi

tag="$1"
version="${tag#v}"
repo="Nikoro/spellbook"
base="https://github.com/${repo}/releases/download/${tag}"

fetch_sha() {
    arch="$1"
    curl -fsSL "${base}/spells-macos-${arch}.sha256" \
        | awk '{print $1}'
}

arm_sha="$(fetch_sha arm64)"
x86_sha="$(fetch_sha x86_64)"

template="$(dirname "$0")/spellbook.rb"
sed \
    -e "s/^  version .*/  version \"${version}\"/" \
    -e "s/REPLACE_WITH_ARM64_SHA256/${arm_sha}/" \
    -e "s/REPLACE_WITH_X86_64_SHA256/${x86_sha}/" \
    "$template"
