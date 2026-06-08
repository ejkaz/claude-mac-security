# Known-Good Baseline — EXAMPLE TEMPLATE

> This is a **template**. On first use, run `/mac-security:security-scan`, review the output,
> and replace the example items below with YOUR machine's confirmed-legit inventory. A scan
> line NOT in this baseline is a finding to investigate. Keep it curated — a stale baseline
> makes every run noisy. **Do not commit your real, populated baseline to a public repo** —
> it fingerprints your machine.

## How the diff works
Each scan emits a `## Fingerprint` block of sorted identifiers (launchd jobs, system
extensions, listening ports, login items). Compare line-by-line against this file. **New
lines = findings.** Removed lines are usually benign (uninstalled apps); note them.

## Confirmed-legit inventory (replace with your own)

### Posture (the secure state to hold)
- MDM: not enrolled (or: enrolled by `<employer>`) · SIP: enabled · Gatekeeper: enabled ·
  FileVault: On · Remote Login: Off · no SSH `authorized_keys` · default `/etc/hosts` · no proxy.

### System extensions
- `<your.vpn.extension>` (e.g. a VPN's WireGuard extension) — your own VPN. Watch for any
  unrecognized network-filter / endpoint-security extension (CrowdStrike, SentinelOne,
  Netskope, Zscaler) you didn't install.

### Monitoring / security agents
- `<employer compliance agent, if any>` — e.g. a SOC2 osquery-based agent. Verify it's
  vendor-signed, identify who deployed it, and confirm its capabilities (posture-only vs
  keylog/screen/message access).

### LaunchDaemons / LaunchAgents (vendor updaters are normal)
- Adobe / Google (keystone) / Microsoft / Docker / Zoom updaters are common and benign.
- Your own scheduled agents (e.g. `com.<you>.<job>`) — list them so they stop alerting.

### Listening ports (localhost-only is usually fine)
- `ControlCenter *:5000` / `*:7000` — AirPlay Receiver (disable if unused).
- `rapportd` — Apple Continuity (dynamic port). App updaters on `127.0.0.1` — localhost-only.

### Outbound destinations
- Name the legit ones for your tools (cloud AI APIs, browser push, vendor telemetry) so the
  firewall/scan skills don't re-flag them.

### Privacy grants (Screen Recording / Accessibility / Input Monitoring)
- List the apps you've intentionally granted (video-call screen-share, automation tools,
  dictation). Anything unexpected here is a keylog/screen-capture vector to investigate.

## Maintenance
When a scan flags a new item and you confirm it's legit, append it here with a one-line
justification + date.
