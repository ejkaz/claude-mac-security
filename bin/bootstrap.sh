#!/bin/bash
# bootstrap.sh — set up mac-security-suite on a NEW machine, end to end.
# Run from the installed plugin (or a repo clone). Idempotent — safe to re-run.
#
#   Phase 1 (this script):        toolchain + YARA rules + Quad9 profile + sentinel
#   Phase 2 (you, GUI — printed): LuLu approval, Full Disk Access, VT key, profile install
#   Phase 3 (re-run --seed):      seed JSON baselines once the gates are open
#
# Usage: bash bootstrap.sh          # phase 1 + gate checklist
#        bash bootstrap.sh --seed   # phase 3: seed baselines + verify

set -uo pipefail
BIN="$(cd "$(dirname "$0")" && pwd)"
DATA="$HOME/.mac-security-suite"
mkdir -p "$DATA/snapshots"

if [ "${1:-}" = "--seed" ]; then
  echo "== Seeding baselines (requires LuLu approved + FDA granted) =="
  ok=0; fail=0
  for kind in persistence egress posture; do
    if python3 "$BIN/snapshot.py" "$kind" > "$DATA/snapshots/$kind.json" 2>/dev/null; then
      python3 "$BIN/baseline_diff.py" "$kind" --init && ok=$((ok+1))
    else
      echo "  ❌ $kind snapshot failed — gate not cleared yet? (egress needs LuLu, persistence needs KnockKnock+FDA)"
      fail=$((fail+1))
    fi
  done
  echo
  echo "== Verify =="
  bash "$BIN/sentinel.sh" quick || true
  [ "$fail" = 0 ] && echo "✅ bootstrap complete — sentinel runs Mondays 09:15." \
                  || echo "⚠️ $fail baseline(s) pending — clear the gates and re-run: bootstrap.sh --seed"
  exit 0
fi

echo "== Phase 1: automated setup =="
bash "$BIN/install-tools.sh" --install --gui || true
bash "$BIN/get-yara-rules.sh" || true
bash "$BIN/make-quad9-profile.sh" || true
bash "$BIN/install-sentinel.sh"

cat <<'EOF'

== Phase 2: GUI gates (cannot be scripted on a non-MDM Mac) ==
  1. LuLu:        launch once → approve in System Settings > General >
                  Login Items & Extensions > Network Extensions → allow the
                  content-filter prompt. Recommended settings: allow Apple
                  programs ✓, allow installed ✓, DNS ✓, localhost ✓, simulators ✗.
  2. FDA:         System Settings > Privacy & Security > Full Disk Access →
                  add your terminal AND KnockKnock.app (cron runs need it).
  3. VT key:      free key at virustotal.com → run `vt init`.
  4. Quad9:       open ~/Desktop/Quad9-DoH.mobileconfig → approve in
                  System Settings > General > Device Management.
  5. Guardians:   launch BlockBlock + OverSight once, approve their prompts.
     (BlockBlock/OverSight casks need an interactive sudo password — if
      install-tools failed on them above, run: brew install --cask blockblock oversight)

== Phase 3: after the gates ==
  bash bootstrap.sh --seed     # seeds baselines + first sentinel run
EOF
