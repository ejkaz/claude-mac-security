---
name: firewall
description: >-
  Outbound (egress) firewall advisor built on LuLu + lulu-cli. Reviews what your Mac is
  phoning home to, curates LuLu's per-process allowlist programmatically, and diffs live
  connections via Netiquette against a known-good baseline. Read-only by default — proposes
  rule changes; you approve before any write. Invoke with /mac-security:firewall (review),
  firewall rules (list LuLu rules), firewall connections (snapshot live egress). Trigger
  phrases: "what is my mac connecting to", "egress firewall", "lulu rules", "outbound
  connections", "block this app from phoning home", "review my firewall".
---

# Firewall (egress advisor)

LuLu is the OSS per-process outbound firewall. Its rules live in
`/Library/Objective-See/LuLu/rules.plist` (NSKeyedArchiver). `lulu-cli` (MIT, built for
AI agents) reads/writes them from the command line; **Netiquette** snapshots live
connections as JSON. This skill drives both — read-first, write only on approval.

## Preflight

```
bash ${CLAUDE_PLUGIN_ROOT}/bin/install-tools.sh   # confirms lulu, lulu-cli, Netiquette
```
LuLu must have been launched once and its system extension approved. `lulu-cli` writes
require `sudo`; surface the command, let the user run it.

## Modes

| Invocation | What it does |
|---|---|
| `firewall` (default) | Review posture: list current rules + snapshot live egress, attribute each destination, flag anything unexpected vs `references/egress_baseline.md`. |
| `firewall rules` | `lulu-cli list` — dump the current allow/block rule set, grouped by process. |
| `firewall connections` | `Netiquette -list -names -pretty -skipApple` → parse JSON, diff vs baseline, surface NEW listeners/flows. |
| `firewall recent` | `lulu-cli recent 50` — most recently prompted/created rules (catches "what did I just approve"). |

## Procedure

1. **Snapshot live egress** (read-only, no sudo):
   ```
   Netiquette -list -names -pretty -skipApple
   ```
   Parse the JSON. For each process→remote, attribute the destination (cloud AI APIs,
   browser push, vendor telemetry, etc. — see `references/egress_baseline.md`).
2. **List current LuLu rules**:
   ```
   lulu-cli list
   ```
3. **Diff** both against `references/egress_baseline.md`. Surface only NEW destinations /
   processes. A flow to an unrecognized IP from an unexpected process is the finding.
4. **For anything suspicious**, hand the hash/destination to the `malware-triage` skill or
   run `vt ip <addr>` for reputation.
5. **Propose** rule changes as concrete commands; do NOT run writes yourself:
   ```
   sudo lulu-cli add --process "/path/bin" --action block --endpoint "1.2.3.4:443"
   sudo lulu-cli reload      # rules only load at ext startup; batch writes, then ONE reload
   ```
   Warn: `reload` restarts the system extension → ~8s filtering gap. Batch all changes,
   reload once.

## Guardrails
- **Read before write.** Default mode never mutates rules.
- **Batch + single reload.** Never reload per-rule.
- **Attribution over alarm.** Most egress is legit vendor telemetry; name it, don't flag it.
- When confirmed-legit, append the destination to `references/egress_baseline.md` so it
  stops surfacing. See [[security-scan]] baseline pattern.

## Files
- `references/egress_baseline.md` — known-good destinations + processes (diff target).
