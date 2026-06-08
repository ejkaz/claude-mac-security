---
name: persistence-watch
description: >-
  Enumerates everything that persists on macOS (launchd, login items, cron, dylib hijacks,
  browser extensions, etc.) using KnockKnock's JSON CLI with built-in VirusTotal reputation,
  then diffs against a known-good baseline so recurring runs surface only NEW persistence.
  Read-only. Invoke with /mac-security:persistence-watch. Trigger phrases: "what persists
  on my mac", "knockknock", "new launch items", "persistence check", "autoruns for mac",
  "did something install itself".
---

# Persistence Watch

KnockKnock is "AutoRuns for macOS" — it snapshots all persistence locations and (with a
VirusTotal key) attaches detection ratios per binary hash. This skill runs it headless,
diffs the JSON against a baseline, and surfaces only what changed — the same
baseline-and-diff pattern as [[security-scan]], scoped to persistence with VT reputation.

## Preflight
```
bash ${CLAUDE_PLUGIN_ROOT}/bin/install-tools.sh   # confirms knockknock
```
**Full Disk Access** must be granted to your terminal (System Settings > Privacy &
Security > Full Disk Access) or KnockKnock can't read several persistence locations.
A VirusTotal key (`vt init`, free) enables the reputation column.

## Procedure
1. **Snapshot** (no sudo; needs FDA):
   ```
   KnockKnock -whosthere -pretty -skipApple                  # without VT
   KnockKnock -whosthere -pretty -skipApple -key "$VT_KEY"   # with VirusTotal ratios
   ```
2. **Parse the JSON.** Categories: launch items, login items, cron, kernel/system
   extensions, dylib inserts, browser extensions, etc.
3. **Diff** vs `references/persistence_baseline.md`. NEW items are findings; removed items
   are usually benign uninstalls (note them, don't alarm).
4. **For each new item**: attribute the installer (vendor updater / user app / employer
   compliance / unknown) and report any VT detections. Any nonzero VT detection on an
   unsigned/unknown binary → escalate, hand to `malware-triage`.
5. **On confirmation legit**, append to `references/persistence_baseline.md`.

## Cross-check
KnockKnock's launchd view overlaps the `security-scan` launchd enumeration and an ad-hoc
`osqueryi --json "SELECT * FROM launchd;"`. When something looks off, cross-check across
all three — agreement raises confidence, disagreement is itself a signal.

## Guardrails
- Read-only. Never disables or removes a persistence item — propose the `launchctl
  bootout` / file removal as a command for the user to run.
- Empty/quiet categories are normal, not suspicious.
- VT absence ≠ safe; VT detection ≠ certain. Reputation is one input, not a verdict.

## Files
- `references/persistence_baseline.md` — known-good persistence inventory (diff target).
