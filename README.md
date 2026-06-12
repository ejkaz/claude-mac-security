# mac-security-suite

A **read-only, on-demand** macOS security harness, packaged as a [Claude Code](https://claude.com/claude-code) plugin. Open-source tooling only. No resident daemons, no self-surveillance — every check snapshots state, diffs against a known-good baseline, and surfaces only what changed.

> **Design spine:** read-only · on-demand · baseline-and-diff · recommend-never-mutate.
> The agent drives a headless scanning layer; real-time GUI guardians (BlockBlock, OverSight) stay out-of-band. Aligned with the [drduh macOS Security & Privacy Guide](https://github.com/drduh/macOS-Security-and-Privacy-Guide): threat-model first, OS hardening + an egress firewall + persistence alerts get you ~90% of the value.

## Install

```
/plugin marketplace add ejkaz/claude-mac-security
/plugin install mac-security-suite@claude-mac-security
```

**New machine?** One command does the rest (toolchain, YARA rules, Quad9 DNS profile, weekly sentinel), then prints the unscriptable GUI gates (LuLu approval, Full Disk Access, VirusTotal key) and how to seed your baselines after:

```
PLUGIN=~/.claude/plugins/marketplaces/claude-mac-security
bash "$PLUGIN/bin/bootstrap.sh"          # phase 1 + GUI checklist
bash "$PLUGIN/bin/bootstrap.sh" --seed   # after the gates: seed baselines + first run
```

Baselines, snapshots, and the trend ledger are per-machine state in `~/.mac-security-suite/` — each machine seeds its own; nothing machine-identifying ships in this repo. To audit the toolchain piecemeal instead: `bash "$PLUGIN/bin/install-tools.sh"` (read-only; `--install` to provision).

## Skills

| Skill | Does | Built on |
|---|---|---|
| `/mac-security:security-scan` | Read-only sweep: monitoring agents, persistence, malware sigs, network exposure, hardening posture. Diffs a baseline. | native macOS + osquery |
| `/mac-security:firewall` | Egress advisor — review/curate LuLu's per-process allowlist; diff live connections. | LuLu + lulu-cli + Netiquette |
| `/mac-security:persistence-watch` | Enumerate all persistence, diff a baseline, VirusTotal reputation per binary. | KnockKnock |
| `/mac-security:malware-triage <path>` | On-demand triage of a file/app: signature + IOC + capability + reputation. | ClamAV · YARA · capa · vt-cli |
| `/mac-security:harden` | Hardening-index score + audit-only CIS/NIST checklist. Never auto-applies. | Lynis · mSCP |

A `security-analyst` subagent interprets findings (attribution, capability-vs-activity, triage).

## Diff engine & sentinel (v0.2)

Deterministic, zero-LLM core under the skills — prose diffing replaced by canonical JSON:

| Tool | Does |
|---|---|
| `bin/snapshot.py <kind>` | Canonical `{section: {key: detail}}` snapshot — `persistence` (KnockKnock), `egress` (LuLu rules), `posture` (SIP/Gatekeeper/FileVault/firewall, system extensions, launchd inventory) |
| `bin/baseline_diff.py <kind>` | Diff snapshot vs JSON baseline. **Added/changed = findings (exit 1)**; removed = informational. `--init` seeds. |
| `bin/accept_delta.py <kind> <key> -m "why"` | Promote a confirmed-legit delta into the baseline with a dated justification (required). |
| `bin/sentinel.sh` | The ONE scheduled job: snapshot → diff → trend ledger (`~/.mac-security-suite/ledger.jsonl`). Notifies only on findings; silent when clean. Weekly quick, auto-deep (VirusTotal) monthly. Install: `bash bin/install-sentinel.sh`. |

Data lives in `~/.mac-security-suite/` (baselines, snapshots, ledger, reports) — never in this repo.
For full persistence coverage from launchd, grant **KnockKnock.app** Full Disk Access (terminal FDA doesn't extend to cron).

The optional `hooks/hooks.json` PreToolUse guard (blocks `curl|sh` pipe-to-shell installs and `rm -rf`) ships **enabled** as of v0.2.

## Toolchain (all open-source)

**Headless / agent-driven:** LuLu + [lulu-cli](https://github.com/woop/lulu-cli) · [KnockKnock](https://github.com/objective-see/KnockKnock) · [Netiquette](https://github.com/objective-see/Netiquette) · ClamAV · [YARA](https://github.com/VirusTotal/yara) · [capa](https://github.com/mandiant/capa) · [vt-cli](https://github.com/VirusTotal/vt-cli) · [Lynis](https://github.com/CISOfy/lynis) · osquery (ad-hoc CLI only).

**GUI guardians (install-and-forget, not agent-drivable):** [BlockBlock](https://objective-see.org/products/blockblock.html), [OverSight](https://objective-see.org/products/oversight.html), [RansomWhere?](https://objective-see.org/products/ransomwhere.html).

**Deliberately excluded:** Santa lockdown, osqueryd + Fleet, Pi-hole, resident AV, Little Snitch (not OSS) — friction / attack-surface / paid for a personal non-MDM Mac.

## Scope & honesty

This catches commodity/commercial tooling and standard persistence. It does **not** guarantee detection of a bespoke, fileless, or well-hidden targeted implant. The VirusTotal reputation layer narrows that gap; nothing closes it entirely.

## License

MIT © Eric Kazmaier
