#!/usr/bin/env bash
# Print the path of the baseline security-scan should diff against.
#
# A populated baseline fingerprints your machine, so it never lives in this repo.
# Resolution order:
#   1. $MAC_SECURITY_BASELINE, if set and the file exists
#   2. ~/.config/mac-security/baseline.md, if it exists
#   3. the bundled EXAMPLE template (references/baseline.md) — a note goes to stderr
# Read-only: never creates or edits a baseline.
set -euo pipefail
skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
private="${MAC_SECURITY_BASELINE:-$HOME/.config/mac-security/baseline.md}"
if [ -f "$private" ]; then
  printf '%s\n' "$private"
else
  printf '%s\n' "$skill_dir/references/baseline.md"
  printf 'note: no private baseline at %s — using the bundled EXAMPLE template\n' "$private" >&2
fi
