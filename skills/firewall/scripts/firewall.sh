#!/usr/bin/env bash
# firewall :: read-only egress snapshot — LuLu rules + live connections.
# No sudo, no mutations. Emits Markdown to stdout. Rule WRITES are never done here;
# the skill proposes `lulu-cli add/delete` commands for the user to run.
set -uo pipefail

ts()   { date "+%Y-%m-%d %H:%M:%S %Z"; }
hr()   { printf '\n## %s\n\n' "$1"; }
note() { printf '%s\n' "$1"; }
code() { printf '```\n%s\n```\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

printf '# Firewall — egress snapshot (read-only)\n\n'
printf '_Host:_ `%s`  _Run:_ %s\n' "$(scutil --get LocalHostName 2>/dev/null || hostname)" "$(ts)"

# ── LuLu presence ──────────────────────────────────────────────────────────
hr "LuLu status"
if [ -d /Applications/LuLu.app ]; then
  note "✅ LuLu.app installed."
else
  note "❌ LuLu.app not found — install: \`brew install --cask lulu\` (then approve its system extension)."
fi
if have lulu-cli; then note "✅ lulu-cli on PATH."
else note "❌ lulu-cli missing — \`brew install woop/tap/lulu-cli\`."; fi

# ── LuLu rules (read-only) ─────────────────────────────────────────────────
hr "LuLu rules (current allow/block set)"
if have lulu-cli; then
  code "$(lulu-cli list 2>&1 || echo '(could not read rules — LuLu may not be initialized; launch it once)')"
else
  note "_lulu-cli not installed — skipping rule dump._"
fi

hr "LuLu recent rules (last 30)"
if have lulu-cli; then code "$(lulu-cli recent 30 2>&1 || true)"; else note "_n/a_"; fi

# ── Live connections via Netiquette (JSON) ─────────────────────────────────
hr "Live connections (Netiquette)"
NETIQ="/Applications/Netiquette.app/Contents/MacOS/Netiquette"
if [ -x "$NETIQ" ]; then
  code "$("$NETIQ" -list -names -pretty -skipApple 2>&1 || true)"
elif have Netiquette; then
  code "$(Netiquette -list -names -pretty -skipApple 2>&1 || true)"
else
  note "_Netiquette not installed (objective-see.org/products/netiquette.html) — using lsof fallback below._"
fi

# ── Built-in fallback: established outbound (no extra tools) ────────────────
hr "Established outbound (lsof fallback, deduped)"
code "$(lsof -nP -iTCP -sTCP:ESTABLISHED 2>/dev/null | awk 'NR>1{print $1, $9}' | sort -u | head -80)"

# ── System-level egress posture ────────────────────────────────────────────
hr "Application firewall posture"
code "$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate --getstealthmode 2>/dev/null || echo 'socketfilterfw: unavailable')"

printf '\n---\n_Read-only. To change LuLu rules, the skill proposes `sudo lulu-cli add/delete ...` then a single `sudo lulu-cli reload` (reload = ~8s filtering gap)._\n'
