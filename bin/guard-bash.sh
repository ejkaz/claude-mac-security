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

# Recursive force-delete. Block only what the shell would execute: guard_exec_text.py drops grep
# patterns, quoted strings, comments and heredoc bodies unless something in the command could run
# them (bash -c, eval, a heredoc fed to a shell, ...). Fail closed: if the helper is missing or
# errors, anything but "ALLOW" blocks, i.e. the raw command is tested as before.
if printf '%s' "$cmd" | grep -qE '\brm[[:space:]]+-[a-zA-Z]*(rf|fr)\b'; then
  verdict=$(printf '%s' "$cmd" | /usr/bin/python3 -I "$(dirname "${BASH_SOURCE[0]}")/guard_exec_text.py" 2>/dev/null)
  if [ "$verdict" != "ALLOW" ]; then
    echo "mac-security-suite guard: blocked recursive force-delete (rm -rf). Do not retry it, rephrase it, or route it through another command." >&2
    echo "Instead: write to a NEW dir (mktemp -d, or out_\$(date +%H%M%S)), or 'trash <dir>' for scratch you are done with. Only the user runs the original rm -rf." >&2
    exit 2
  fi
fi

exit 0
