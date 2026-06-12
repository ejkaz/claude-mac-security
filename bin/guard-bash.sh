#!/bin/bash
# guard-bash.sh — optional PreToolUse guard for the Bash tool (see hooks/hooks.json).
# DISABLED by default, per the suite's read-only/on-demand spine.
# Hook contract: JSON on stdin; exit 0 = allow, exit 2 = block (stderr is fed back to the agent).

input=$(cat)
cmd=$(printf '%s' "$input" | /usr/bin/python3 -c \
  'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null)
[ -z "$cmd" ] && exit 0

# Pipe-to-shell installs: curl/wget piped into a shell executes unreviewed remote code.
if printf '%s' "$cmd" | grep -qE '(curl|wget)[^|;&]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z|da)?sh'; then
  echo "mac-security-suite guard: blocked pipe-to-shell install. Download the script, inspect it, then run it explicitly." >&2
  exit 2
fi

# Recursive force-delete.
if printf '%s' "$cmd" | grep -qE '\brm[[:space:]]+-[a-zA-Z]*(rf|fr)\b'; then
  echo "mac-security-suite guard: blocked 'rm -rf'. If intended, the user runs it directly." >&2
  exit 2
fi

exit 0
