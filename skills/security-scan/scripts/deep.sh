#!/usr/bin/env bash
# security-scan :: deep tiers.
#   Tier 2 (privileged): prints the sudo command block for the USER to run via `! ...`
#            (sudo is non-interactive-hostile in the agent shell, and TCC.db is SIP-protected
#             even for root unless the calling binary has Full Disk Access).
#   Tier 3 (reputation): runs KnockKnock / Lynis / ClamAV if installed; else prints install cmds.
# Read-only. No mutations.
set -uo pipefail
hr() { printf '\n## %s\n\n' "$1"; }
code() { printf '```\n%s\n```\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

printf '# Security Scan — Deep (privileged + reputation)\n'

# ── Tier 2: privileged commands for the user to run ────────────────────────
hr "Tier 2 — run these yourself (paste with the \`!\` prefix, one line at a time)"
cat <<'EOF'
```
# Authoritative persistence list — ALL launch items + login items + BTM (incl. hidden)
sudo sfltool dumpbtm | grep -iE 'name:|developer:|type:|disposition:' | head -120

# Application firewall + stealth mode
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate --getstealthmode

# Remote login (SSH) and any Screen Sharing / VNC actually listening
sudo systemsetup -getremotelogin
sudo lsof -iTCP -sTCP:LISTEN -nP | grep -E ':22|:5900' || echo 'no SSH/VNC listening'

# Installed configuration profiles (rogue cert / proxy / restriction vector)
sudo profiles show -all 2>/dev/null | grep -iE 'profileIdentifier|payloadType|name' | head -60

# Non-Apple root CAs in the system trust store (TLS-interception vector)
security dump-trust-settings -d 2>/dev/null | grep -iE 'Cert ' | head
```
EOF
printf '\n**TCC privacy grants (keylogger / screen-capture vectors) — GUI only, CLI is SIP-blocked:**\n'
printf 'System Settings -> Privacy & Security -> **Screen Recording / Accessibility / Input Monitoring / Microphone / Camera**.\n'
printf 'Every toggled-ON app should be one you installed. An app you do not recognize here is the finding.\n'

# ── Tier 3: reputation / hardening tools ───────────────────────────────────
hr "Tier 3 — reputation & hardening scanners"

KK="/Applications/KnockKnock.app/Contents/MacOS/KnockKnock"
printf '### KnockKnock (persistence + VirusTotal)\n'
if [ -x "$KK" ]; then
  printf 'Running KnockKnock (this queries VirusTotal for each persistent item)...\n'
  code "$("$KK" -whosthere -pretty 2>/dev/null | head -200 || echo 'KnockKnock run failed')"
elif have knockknock; then
  code "$(knockknock -whosthere -pretty 2>/dev/null | head -200)"
else
  printf '_Not installed._ Install:\n'
  code "brew install --cask knockknock"
fi

printf '\n### Lynis (hardening audit + score)\n'
if have lynis; then
  printf 'Running Lynis quick audit...\n'
  code "$(lynis audit system --quick --quiet --no-colors 2>/dev/null | grep -iE 'warning|suggestion|hardening index' | head -60 || echo 'lynis run produced no parseable output')"
  printf '_Full report: `/var/log/lynis.log` and `/var/log/lynis-report.dat`._\n'
else
  printf '_Not installed._ Install:\n'
  code "brew install lynis"
fi

printf '\n### Optional Objective-See tools (install as wanted)\n'
cat <<'EOF'
```
brew install --cask lulu      # open-source outbound firewall — see everything that phones home
brew install --cask reikey    # detects keystroke event taps (keyloggers)
brew install --cask oversight  # alerts on mic/camera activation
brew install clamav            # signature antivirus: freshclam && clamscan -r ~/
```
EOF
printf '\n_LuLu needs a one-time manual macOS approval (Allow System Extension) after install — cannot be automated._\n'
printf '\n---\n_See `references/tools.md` for what each tool closes. Compare findings against `references/baseline.md`._\n'
