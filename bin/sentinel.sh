#!/bin/bash
# sentinel.sh — the suite's ONE scheduled job. Deterministic, zero-LLM, read-only.
# Snapshots persistence/egress/posture, diffs each against its JSON baseline,
# appends a trend-ledger line, and notifies ONLY when something was added/changed.
#
# Usage: sentinel.sh [quick|deep]
#   quick: no VirusTotal (default for the weekly run)
#   deep:  adds VT reputation to the persistence snapshot
# With no arg: quick, auto-escalating to deep on the first run of each month.
# Schedule via launchd (see bin/install-sentinel.sh).

set -uo pipefail
BIN="$(cd "$(dirname "$0")" && pwd)"
DATA="$HOME/.mac-security-suite"
mkdir -p "$DATA/snapshots" "$DATA/audits"
LEDGER="$DATA/ledger.jsonl"
TS="$(date +%Y-%m-%dT%H:%M:%S%z)"

MODE="${1:-auto}"
if [ "$MODE" = "auto" ]; then
  MODE=quick
  # deep once a month: first run on/after the 1st whose month isn't in the ledger yet
  MONTH="$(date +%Y-%m)"
  grep -q "\"mode\": \"deep\".*\"month\": \"$MONTH\"" "$LEDGER" 2>/dev/null || MODE=deep
fi
if [ "$MODE" = "deep" ]; then
  VT_KEY="$(awk -F'"' '/^apikey/{print $2}' "$HOME/.vt.toml" 2>/dev/null)"
  export VT_KEY
fi

REPORT="$DATA/audits/sentinel_$(date +%Y%m%d_%H%M%S).md"
TOTAL_ADDED=0; TOTAL_CHANGED=0; TOTAL_REMOVED=0; SUMMARY=""

{
  echo "# Sentinel run — $TS (mode: $MODE)"
  for kind in persistence egress posture; do
    if ! python3 "$BIN/snapshot.py" "$kind" > "$DATA/snapshots/$kind.json" 2>"$DATA/snapshots/$kind.err"; then
      echo; echo "## $kind: SNAPSHOT FAILED"; cat "$DATA/snapshots/$kind.err"
      SUMMARY="$SUMMARY $kind:ERR"
      continue
    fi
    echo
    DIFF_OUT="$(python3 "$BIN/baseline_diff.py" "$kind" 2>&1)"
    echo "$DIFF_OUT"
    counts="$(echo "$DIFF_OUT" | head -1 | grep -oE '[0-9]+ (added|changed|removed)' | awk '{print $1}' | tr '\n' ' ')"
    a=$(echo "$counts" | awk '{print $1+0}'); c=$(echo "$counts" | awk '{print $2+0}'); r=$(echo "$counts" | awk '{print $3+0}')
    TOTAL_ADDED=$((TOTAL_ADDED+a)); TOTAL_CHANGED=$((TOTAL_CHANGED+c)); TOTAL_REMOVED=$((TOTAL_REMOVED+r))
    SUMMARY="$SUMMARY $kind:+$a/≠$c/-$r"
  done
} > "$REPORT" 2>&1

printf '{"ts": "%s", "mode": "%s", "month": "%s", "added": %d, "changed": %d, "removed": %d, "report": "%s"}\n' \
  "$TS" "$MODE" "$(date +%Y-%m)" "$TOTAL_ADDED" "$TOTAL_CHANGED" "$TOTAL_REMOVED" "$REPORT" >> "$LEDGER"

FINDINGS=$((TOTAL_ADDED + TOTAL_CHANGED))
if [ "$FINDINGS" -gt 0 ]; then
  osascript -e "display notification \"$FINDINGS new delta(s):$SUMMARY — review $(basename "$REPORT")\" with title \"mac-security-suite sentinel\" sound name \"Basso\"" 2>/dev/null || true
  echo "⚠️ $FINDINGS finding(s) —$SUMMARY — $REPORT"
  exit 1
else
  # quiet on clean: ledger line only, no notification, drop the empty report
  rm -f "$REPORT"
  echo "✅ clean —$SUMMARY"
fi
