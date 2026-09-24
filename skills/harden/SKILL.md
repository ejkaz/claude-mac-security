---
name: harden
description: >-
  Audits macOS hardening without changing anything: a Lynis hardening-index score, an optional
  mSCP (NIST/CIS) check-only compliance run, GUI-guardian presence (BlockBlock, OverSight,
  RansomWhere), and a prioritized drduh-aligned checklist of recommended actions. Never
  auto-applies fixes. Use when: "harden my mac", "hardening audit", "lynis score", "cis
  benchmark", "am I hardened", "security hardening checklist". NOT for detecting monitoring agents
  or spyware (→ security-scan), inbound or outbound traffic, open ports or firewall rules (→
  firewall), autostart items (→ persistence-watch), or checking a specific file or a risky click
  (→ malware-triage).
---

# Harden

Audit-only hardening advisor. It scores posture and proposes a checklist; it never applies
fixes (mSCP `--fix` is invasive and must stay a human decision on a personal machine).
Threat-model-first, aligned with the drduh macOS Security & Privacy guide and NIST mSCP.

## Preflight
```
bash ${CLAUDE_PLUGIN_ROOT}/bin/install-tools.sh   # confirms lynis
```

## Run

```
bash ${CLAUDE_PLUGIN_ROOT}/skills/harden/scripts/harden.sh
```
Read-only posture audit: core controls, remote access, GUI-guardian presence, and Lynis
index if installed. For full Lynis coverage, follow up with `sudo lynis audit system`.

## Procedure

1. **Baseline posture** (built-in, no install — same checks as [[security-scan]]):
   ```
   csrutil status                                   # SIP
   spctl --status                                   # Gatekeeper
   fdesetup status                                  # FileVault
   /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate --getstealthmode
   sudo systemsetup -getremotelogin                 # Remote Login (SSH)
   ```
2. **Lynis hardening audit**:
   ```
   sudo lynis audit system
   ```
   Parse `/var/log/lynis-report.dat` (key=value). Pull the **hardening index** and any
   `warning[]` / `suggestion[]` lines. Track the index over time across runs.
3. **mSCP compliance (optional, audit-only)**: if the user wants CIS Level 1 / NIST 800-53
   rigor, generate the baseline's `*_compliance.sh` from usnistgov/macos_security and run it
   with `--check` ONLY. Never `--fix` unattended.
4. **GUI guardian presence**: confirm BlockBlock, OverSight, (RansomWhere?) are installed —
   these are the real-time prevention layer the harness can't drive. Recommend install if
   missing.
5. **Privacy-grant review**: route Screen Recording / Accessibility / Input Monitoring
   checks to the GUI panes (TCC.db is unreadable via CLI). Name the expected legit grants
   from the baseline; flag anything unexpected.

## Output
A prioritized checklist: **control → current state → recommended action → effort**. Lead
with high-ROI, low-friction items (FileVault, firewall stealth mode, DNS hygiene) before
high-friction ones. Mark each as recommended, not applied. Note the drduh stance where it
diverges from CIS (e.g. drduh is skeptical of resident AV and Santa on a personal Mac).

## Guardrails
- **Audit-only.** Never runs mSCP `--fix` or mutates system settings. Every item is a
  recommendation the user executes.
- Distinguish must-fix (FileVault off, firewall off) from nice-to-have hardening.
- Be honest: a high Lynis score is hygiene, not immunity.

## Files
- (Lynis writes `/var/log/lynis-report.dat`; mSCP cloned at runtime if used.)
