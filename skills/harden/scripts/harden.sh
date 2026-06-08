#!/usr/bin/env bash
# harden :: read-only hardening posture audit.
# Native posture checks always run (no sudo). Lynis runs only if installed; full Lynis
# coverage wants sudo — surfaced, not auto-run with sudo here. Markdown to stdout.
set -uo pipefail

ts()   { date "+%Y-%m-%d %H:%M:%S %Z"; }
hr()   { printf '\n## %s\n\n' "$1"; }
note() { printf '%s\n' "$1"; }
code() { printf '```\n%s\n```\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

printf '# Hardening Audit (read-only)\n\n'
printf '_Host:_ `%s`  _Run:_ %s\n' "$(scutil --get LocalHostName 2>/dev/null || hostname)" "$(ts)"

# ── Core posture (native, no sudo) ─────────────────────────────────────────
hr "Core posture"
printf '| Control | State |\n|---|---|\n'
printf '| SIP | %s |\n'        "$(csrutil status 2>/dev/null | sed 's/System Integrity Protection status: //' | tr -d '.')"
printf '| Gatekeeper | %s |\n' "$(spctl --status 2>/dev/null)"
printf '| FileVault | %s |\n'  "$(fdesetup status 2>/dev/null | head -1)"
printf '| App Firewall | %s |\n' "$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | sed -E 's/.*\((State = [0-9])\)/\1/; s/State = 0/disabled/; s/State = [12]/enabled/')"
printf '| FW Stealth | %s |\n' "$(/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode 2>/dev/null | sed -E 's/.*is //')"

hr "Remote access"
code "$(systemsetup -getremotelogin 2>/dev/null || echo 'Remote Login: (needs sudo to read — check System Settings > Sharing)')"
note '**SSH authorized_keys:**'; code "$(cat "$HOME/.ssh/authorized_keys" 2>/dev/null || echo '(none)')"

hr "Software update posture"
code "$(softwareupdate --schedule 2>/dev/null || echo 'n/a')"

# ── GUI guardian presence (prevention layer the harness can't drive) ───────
hr "GUI guardians (real-time prevention)"
for app in BlockBlock OverSight RansomWhere; do
  if [ -d "/Applications/${app}.app" ]; then note "✅ ${app}.app installed."
  else note "⬜ ${app} not installed — recommended (objective-see.org)."; fi
done

# ── Lynis (optional, deeper) ───────────────────────────────────────────────
hr "Lynis hardening index"
if have lynis; then
  note "✅ Lynis installed. For full coverage run \`sudo lynis audit system\` (this audit runs unprivileged)."
  code "$(lynis audit system --quick --no-colors 2>/dev/null | grep -iE 'hardening index|warning|suggestion' | head -40 || echo '(run sudo lynis audit system for the full report)')"
  [ -f /var/log/lynis-report.dat ] && code "$(grep -E 'hardening_index=' /var/log/lynis-report.dat 2>/dev/null | tail -1)"
else
  note "_Lynis not installed (\`brew install lynis\`)._"
fi

# ── Privacy grants pointer (TCC is GUI-only) ───────────────────────────────
hr "Privacy grants (review in GUI — TCC.db is not CLI-readable)"
note "Check **System Settings > Privacy & Security**: Screen Recording, Accessibility, Input Monitoring, Full Disk Access. Confirm every grant is one you intentionally made; anything unexpected is a keylog/screen-capture vector."

printf '\n---\n_Audit-only. Every item is a recommendation — nothing is applied. Hardening index is hygiene, not immunity._\n'
