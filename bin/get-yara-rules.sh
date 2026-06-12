#!/bin/bash
# get-yara-rules.sh — fetch/update a maintained macOS YARA rule set for malware-triage.
# Source: elastic/protections-artifacts (Elastic's production endpoint rules, actively maintained).
# Rules land OUTSIDE the repo (they're third-party content, refreshed not vendored).
#
# Usage: bash get-yara-rules.sh [dest_dir]
#   default dest: ~/.mac-security-suite/yara-rules

set -euo pipefail

DEST="${1:-$HOME/.mac-security-suite/yara-rules}"
mkdir -p "$DEST/elastic-macos"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Fetching elastic/protections-artifacts (shallow)..."
git clone --quiet --depth 1 https://github.com/elastic/protections-artifacts "$TMP/pa"

find "$TMP/pa/yara/rules" -name 'Macos_*.yar' -o -name 'MacOS_*.yar' | while read -r f; do
  cp "$f" "$DEST/elastic-macos/"
done

count=$(find "$DEST/elastic-macos" -name '*.yar' | wc -l | tr -d ' ')
if [ "$count" = "0" ]; then
  echo "❌ No macOS rules found — upstream layout may have changed. Inspect $TMP/pa/yara/rules." >&2
  exit 1
fi

echo "✅ $count macOS YARA rule files → $DEST/elastic-macos"
echo "Use: triage.sh <target> $DEST/elastic-macos"
echo "Refresh: re-run this script (it overwrites in place)."
