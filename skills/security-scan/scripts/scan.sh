#!/usr/bin/env bash
# security-scan :: Tier 1 — read-only macOS monitoring/malware/posture sweep.
# No sudo, no mutations. Emits a Markdown report to stdout.
# Pair with deep.sh for the privileged (sudo) + reputation (tool) tiers.
set -uo pipefail

ts() { date "+%Y-%m-%d %H:%M:%S %Z"; }
hr() { printf '\n## %s\n\n' "$1"; }
note() { printf '%s\n' "$1"; }
code() { printf '```\n%s\n```\n' "$1"; }

printf '# Security Scan — Tier 1 (read-only)\n\n'
printf '_Host:_ `%s`  _Run:_ %s\n' "$(scutil --get LocalHostName 2>/dev/null || hostname)" "$(ts)"
printf '_Scope: monitoring agents, persistence, malware signatures, network exposure, hardening baseline. No sudo, no changes._\n'

# ── Management / enrollment ────────────────────────────────────────────────
hr "Device management (MDM)"
code "$(profiles status -type enrollment 2>/dev/null || echo 'profiles: unavailable')"
note "_Expect: not enrolled. Enrollment = employer can push policies / remote-wipe._"

# ── Extensions (EDR / network filters / kexts live here) ───────────────────
hr "System & kernel extensions"
note '**System extensions:**'
code "$(systemextensionsctl list 2>/dev/null || echo 'none')"
note '**Third-party kernel extensions:**'
code "$(kextstat 2>/dev/null | grep -iv com.apple | tail -n +2 || true)"
note "_Empty kext list = good. Watch for unrecognized network-filter/endpoint-security extensions (CrowdStrike, SentinelOne, Netskope, Zscaler)._"

# ── Persistence: launchd ───────────────────────────────────────────────────
hr "Launch daemons & agents (persistence)"
note '**/Library/LaunchDaemons (system, root):**'
code "$(ls /Library/LaunchDaemons/ 2>/dev/null)"
note '**/Library/LaunchAgents:**'
code "$(ls /Library/LaunchAgents/ 2>/dev/null)"
note '**~/Library/LaunchAgents (per-user):**'
code "$(ls "$HOME/Library/LaunchAgents/" 2>/dev/null)"
note '**Loaded non-Apple launchd jobs:**'
code "$(launchctl list 2>/dev/null | grep -iv com.apple | grep -v '^PID')"

# ── Persistence: shell / cron / ssh / hosts ────────────────────────────────
hr "Shell, cron, SSH, hosts"
note '**Shell rc files (non-comment lines):**'
for f in "$HOME/.zshrc" "$HOME/.zshenv" "$HOME/.zprofile" "$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.profile"; do
  [ -f "$f" ] && { printf '_%s_\n' "$f"; code "$(grep -vE '^\s*#|^\s*$' "$f")"; }
done
note '**User crontab:**'
code "$(crontab -l 2>/dev/null || echo '(none)')"
note '**SSH authorized_keys (who can remote-in):**'
code "$(cat "$HOME/.ssh/authorized_keys" 2>/dev/null || echo '(none)')"
note '**/etc/hosts (non-default redirects):**'
code "$(grep -vE '^\s*#|^\s*$' /etc/hosts 2>/dev/null)"

# ── Known monitoring / EDR / DLP / time-tracker / RMM / spyware ─────────────
hr "Known-agent signature scan"
SIG='crowdstrike|falcon|sentinel|carbonblack|jamf|kandji|mosyle|addigy|tanium|cylance|defender|mdatp|wdav|netskope|zscaler|forcepoint|guardian|hubstaff|teramind|activtrak|timedoctor|veriato|interguard|kolide|fleetd|santa|snitch|teamviewer|anydesk|screenconnect|datto|ninja|automate|wandera|jumpcloud|insightidr|huntress|qualys|nessus|rapid7'
HITS="$(ps axco command 2>/dev/null | sort -u | grep -iE "$SIG" || true)"
code "${HITS:-(no known monitoring/EDR/DLP/RMM/spyware agents matched)}"
note "_Note: matches arent always bad (e.g. Microsoft Defender Shim ships dormant with Office). Verify whether the daemon is actually running + who deployed it._"

# ── Hardening baseline ─────────────────────────────────────────────────────
hr "Hardening baseline"
printf '| Control | State |\n|---|---|\n'
printf '| SIP | %s |\n' "$(csrutil status 2>/dev/null | sed 's/System Integrity Protection status: //')"
printf '| Gatekeeper | %s |\n' "$(spctl --status 2>/dev/null)"
printf '| FileVault | %s |\n' "$(fdesetup status 2>/dev/null)"
printf '| Remote services loaded | %s |\n' "$(launchctl list 2>/dev/null | grep -iE 'sshd|screensharing|vnc|RemoteDesktop|remotemanagement' | awk '{print $3}' | paste -sd, - || echo none)"

# ── Network exposure ───────────────────────────────────────────────────────
hr "Network exposure"
note '**Listening ports (your user):**'
code "$(lsof -iTCP -sTCP:LISTEN -nP 2>/dev/null | awk 'NR>1{print $1, $9}' | sort -u)"
note '**Established outbound (your user, deduped):**'
code "$(lsof -i -nP 2>/dev/null | grep ESTABLISHED | awk '{print $1, $9}' | sort -u | sed 's/->.*->/->/' | head -50)"
note '**DNS servers:**'
code "$(scutil --dns 2>/dev/null | awk '/nameserver/{print $3}' | sort -u)"
note '**System proxies:**'
code "$(scutil --proxies 2>/dev/null | grep -iE 'Enable|Server' | grep -v ': 0' || echo '(none enabled)')"
note '**VPN / network services:**'
code "$(scutil --nc list 2>/dev/null || echo '(none)')"

# ── Fingerprint (stable, sorted — for diffing against baseline) ────────────
hr "Fingerprint"
note "_Sorted identifiers for mechanical diff vs references/baseline.md. New lines on a later run = investigate._"
{
  ls /Library/LaunchDaemons/ 2>/dev/null | sed 's/^/launchd-system: /'
  ls /Library/LaunchAgents/ 2>/dev/null | sed 's/^/launchagent-system: /'
  ls "$HOME/Library/LaunchAgents/" 2>/dev/null | sed 's/^/launchagent-user: /'
  systemextensionsctl list 2>/dev/null | grep -oE '[a-z0-9.]+\.[A-Za-z-]+ \(' | sed 's/ ($//;s/^/sysext: /'
  lsof -iTCP -sTCP:LISTEN -nP 2>/dev/null | awk 'NR>1{print "listen: "$1" "$9}' | sort -u
} | sort -u | code "$(cat)"

printf '\n---\n_Tier 1 complete. For BTM dump, firewall state, TCC grants, profiles, root-CA trust, and reputation scans (KnockKnock/Lynis), run `/security-scan deep`._\n'
