---
name: security-scan
description: >-
  Read-only macOS security sweep — detects monitoring/surveillance agents (MDM,
  EDR, DLP, RMM, time-trackers, spyware), persistence (launchd, shell rc, cron,
  login items, BTM), malware signatures, network exposure, privacy-permission
  grants (screen recording / keylogging vectors), and hardening posture (SIP,
  Gatekeeper, FileVault, firewall). Diffs against a known-good baseline so
  recurring runs surface only what CHANGED. Optional reputation layer via
  KnockKnock + VirusTotal and Lynis hardening audit. Invoke with /security-scan
  (quick), /security-scan deep (privileged + tools), or /security-scan harden
  (hardening checklist). Trigger phrases: "security scan", "scan my mac",
  "is anything monitoring me", "check for spyware/malware", "what's watching
  my machine", "audit my laptop", "harden my mac", "check my security posture".
---

# Security Scan

Read-only audit of a macOS machine for **monitoring tools, persistence, malware, network exposure, and hardening gaps.** Never mutates system state — it reports and recommends; the user approves any change. Born from a real investigation of an osquery-based SOC2 compliance agent — the lesson baked in: distinguish *capability present* from *actively running*, and attribute every agent to its deployer before alarming.

**Trigger:** `/mac-security:security-scan` · `… deep` · `… harden`

## Modes

| Mode | What runs | Sudo |
|---|---|---|
| `quick` (default) | `scripts/scan.sh` — MDM, extensions, launchd, shell/cron/ssh/hosts, known-agent signatures, hardening baseline, network exposure, fingerprint | none |
| `deep` | quick **+** `scripts/deep.sh` — emits a sudo block for the user (`sfltool dumpbtm`, firewall, remote-login, profiles, root-CA trust, TCC GUI guidance) **+** runs KnockKnock + Lynis if installed | user runs sudo block via `!` |
| `harden` | reads latest report + `references/baseline.md`, produces a hardening checklist of recommended (not auto-applied) actions | none |

## How to run

1. **Execute the scan:**
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/skills/security-scan/scripts/scan.sh
   ```
   For deep mode also run `${CLAUDE_PLUGIN_ROOT}/skills/security-scan/scripts/deep.sh` and hand the user the Tier-2 sudo block to paste with `!`.

2. **Diff against baseline.** Read `references/baseline.md`. Compare the scan's `## Fingerprint` block line-by-line. **Flag every NEW line** (new launchd job, new system extension, new listening port, new login item) — these are the findings. Removed lines are usually benign (uninstalled apps) but note them.

3. **Interpret, don't just dump.** For each delta: what is it, who likely installed it (user / vendor updater / employer / unknown), and does it have a monitoring/exfil/keylog capability. Distinguish *capability present* from *actively running*. Benign-but-noisy items (Adobe/Microsoft/Google updaters, screen-share permissions for Zoom/Slack) belong in the baseline, not the alert list.

4. **Write the report** to a local audits directory (defaults below; override per your setup):
   ```
   ${CLAUDE_PLUGIN_DATA}/audits/security_scan_<YYYYMMDD_HHMMSS>.md
   ```
   (or any private location you prefer, e.g. a notes vault). Lead with a verdict line
   (✅ clean / ⚠️ N deltas to review), then the deltas, then the full scan appended.
   Keep reports out of any public repo — they fingerprint your machine.

5. **Update the baseline** only when the user confirms a new item is legitimate — append it to `references/baseline.md` with a one-line justification so it stops alerting next run.

## Interpretation guardrails

- **Permission ≠ activity.** Screen Recording / Accessibility / Input Monitoring grants mean an app *can* capture, not that it *is*. macOS shows a purple/orange indicator during active capture.
- **Name match ≠ threat.** `Microsoft Defender Shim` ships dormant with Office; a real EDR shows a running `wdavdaemon` + daemon plist. Confirm the process is live and identify the deployer.
- **TCC.db is unreadable via CLI** (SIP-protected even as root unless the binary has Full Disk Access). Always route screen/keystroke-permission checks to the GUI panes — never claim you read them when you didn't.
- **Empty local logs are normal**, not suspicious, for TLS-logging agents (results ship to the network, nothing retained locally). Absence of local evidence ≠ proof a thing never happened; the authoritative record is server-side.
- **Be honest about coverage.** This catches commodity/commercial tooling and standard persistence. It does NOT guarantee detection of a bespoke, fileless, or well-hidden targeted implant. Recommend the reputation layer (KnockKnock + VirusTotal) to close that gap; say so plainly.

## Files

- `scripts/scan.sh` — Tier 1 read-only sweep → Markdown.
- `scripts/deep.sh` — Tier 2 sudo block + Tier 3 reputation tools.
- `references/baseline.md` — known-good snapshot; the diff target. Keep current.
- `references/tools.md` — open-source toolkit (Objective-See suite, Lynis, ClamAV) and what each closes.

## Recurring use

Run from time to time (post-onboarding to a new employer, after installing unfamiliar software, quarterly hygiene). To automate, pair with the `schedule` skill for a monthly run that appends to `audits/` and pings on any new delta. Keep `baseline.md` curated — a stale baseline turns every run into noise.
