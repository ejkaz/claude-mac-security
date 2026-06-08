#!/usr/bin/env bash
# persistence-watch :: read-only persistence snapshot.
# Prefers KnockKnock (JSON + VirusTotal); falls back to native enumeration.
# No sudo, no mutations. Emits Markdown to stdout.
# VirusTotal: export VT_KEY=<key> to enable reputation ratios.
set -uo pipefail

ts()   { date "+%Y-%m-%d %H:%M:%S %Z"; }
hr()   { printf '\n## %s\n\n' "$1"; }
note() { printf '%s\n' "$1"; }
code() { printf '```\n%s\n```\n' "$1"; }

printf '# Persistence Watch (read-only)\n\n'
printf '_Host:_ `%s`  _Run:_ %s\n' "$(scutil --get LocalHostName 2>/dev/null || hostname)" "$(ts)"

# ── KnockKnock (preferred) ─────────────────────────────────────────────────
KK=""
for c in "/Applications/KnockKnock.app/Contents/MacOS/KnockKnock" "$(command -v KnockKnock 2>/dev/null)"; do
  [ -n "$c" ] && [ -x "$c" ] && { KK="$c"; break; }
done

hr "KnockKnock snapshot"
if [ -n "$KK" ]; then
  note "✅ KnockKnock found. (Needs Full Disk Access on this terminal to read all locations.)"
  if [ -n "${VT_KEY:-}" ]; then
    note "_VirusTotal reputation: ENABLED._"
    code "$("$KK" -whosthere -pretty -skipApple -key "$VT_KEY" 2>&1 | head -400 || true)"
  else
    note "_VirusTotal reputation: off (export VT_KEY=<key> to enable)._"
    code "$("$KK" -whosthere -pretty -skipApple 2>&1 | head -400 || true)"
  fi
else
  note "❌ KnockKnock not installed (\`brew install --cask knockknock\`) — native fallback below."
fi

# ── Native fallback enumeration (always runs as cross-check) ────────────────
hr "launchd — system daemons / agents"
note '**/Library/LaunchDaemons:**'; code "$(ls /Library/LaunchDaemons/ 2>/dev/null)"
note '**/Library/LaunchAgents:**'; code "$(ls /Library/LaunchAgents/ 2>/dev/null)"
note '**~/Library/LaunchAgents:**'; code "$(ls "$HOME/Library/LaunchAgents/" 2>/dev/null)"
note '**Loaded non-Apple jobs:**'; code "$(launchctl list 2>/dev/null | grep -iv com.apple | grep -v '^PID')"

hr "System & kernel extensions"
code "$(systemextensionsctl list 2>/dev/null || echo 'none')"

hr "Login items (per-user)"
code "$(osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null | tr ',' '\n' | sed 's/^ *//' || echo '(none / not readable)')"

hr "cron"
code "$(crontab -l 2>/dev/null || echo '(no user crontab)')"

printf '\n---\n_Read-only. Diff vs references/persistence_baseline.md; NEW items are findings. Any nonzero VirusTotal hit on an unsigned/unknown binary → escalate to malware-triage._\n'
