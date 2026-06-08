# Known-Good Baseline — Eric's MacBook Pro

Seeded 2026-06-01 from a full read-only investigation (the scan that prompted this skill). Items here are **confirmed legitimate** — the diff target. A scan line NOT in this baseline is a finding to investigate.

## Origin context
The skill was born from investigating **Vanta** (`/usr/local/vanta/`) — Parspec's SOC 2 compliance agent. Verdict: legitimate vendor software, Vanta-signed (Apple Team ID `632L25QNV4`), default config, deployed intentionally by Parspec (not MDM-enrolled — observe/report only). It's osquery-based; 99 scheduled queries = posture checks + the public osquery malware-IOC pack. Only behavioral signal is app `last_opened_time`; the live-query channel (every 4 min) is enabled but showed no local evidence of ad-hoc use. No keylogging/screen/message/password access.

## Confirmed-legit inventory

### Posture (must stay this way)
- MDM: **not enrolled** · SIP: **enabled** · Gatekeeper: **enabled** · FileVault: **On** · Remote Login: **Off** · no SSH `authorized_keys` · default `/etc/hosts` · no system proxy.

### System extensions
- `ch.protonvpn.mac.WireGuard-Extension` (Proton VPN, Team `J6S6Q257EK`) — user's own VPN. **Only** system extension. No EDR/network-filter extension present.
- Third-party kexts: none.

### Monitoring / security agents (legit)
- **Vanta** — `com.vanta.metalauncher` daemon, `/usr/local/vanta/` — employer compliance (see origin context).
- **Okta Verify** — SSO/MFA identity. Authenticates; does not monitor activity.
- `Microsoft Defender Shim.app` — dormant Office stub, NOT running EDR (no `wdavdaemon`, no daemon plist). Benign unless a live daemon appears.

### LaunchDaemons (system) — all vendor updaters / app helpers
adobe (acc.installer, agsservice, ARMDC.Communicator, ARMDC.SMJobBlessHelper) · docker (socket, vmnetd) · google (GoogleUpdater.wake.system, keystone.daemon) · microsoft (autoupdate.helper, office.licensingV2.helper, OneDriveStandaloneUpdaterDaemon, OneDriveUpdaterDaemon) · vanta.metalauncher · zoom (ZoomDaemon)

### LaunchAgents (system)
adobe (AdobeCreativeCloud, ARMDCHelper, ccxprocess, GC.Invoker) · google (keystone.agent, keystone.xpcservice) · microsoft (OneDriveStandaloneUpdater, SyncReporter, update.agent) · zoom (updater, updater.login.check)

### LaunchAgents (user) — incl. Eric's own
perplexity (CometUpdater.wake, keystone.agent, keystone.xpcservice) · adobe (ccxprocess, GC.Invoker) · google (GoogleUpdater.wake, keystone.agent, keystone.xpcservice) · **com.eric.claude-rc** (own) · **com.eric.morning-briefing** (own)

### Listening ports (legit)
`ControlCenter *:5000`, `*:7000` — AirPlay Receiver (disable if unused) · `rapportd *:53534` — Apple Continuity · Adobe/`Creative`/OneDrive on `127.0.0.1` (localhost-only) · `Adobe *:1929x` localhost.

### Outbound destinations (legit)
Claude/Cursor/Codex → Anthropic (`160.79.104.0/24`, `2607:6bc0::/32`) · Chrome → Google (`5228` FCM push, Google ranges) · Adobe → Adobe/AWS · Cursor → Cloudflare/AWS (AI + telemetry).

### Privacy grants — Screen Recording (confirmed by user, all legit)
Ghostty (remote setup), Claude (remote control — Eric-enabled), Chrome (web screen-share + computer-use), Slack (huddle screen-share), Zoom (meeting screen-share). _Accessibility / Input Monitoring not yet enumerated — check GUI on next deep run; expect Rectangle Pro (Accessibility), Wispr Flow (Input Monitoring/dictation)._

### Apps of note (not monitoring)
ProtonVPN, Okta Verify, plus dev/AI/productivity tools (Cursor, VS Code, Antigravity, ChatGPT, Gemini, Comet, Obsidian, Notion, Things3, Superhuman, Slack, Office, Adobe CC, Docker).

## Maintenance
When a future scan flags a new item and the user confirms it's legit, append it here with a one-line justification + date. Keep this current — a stale baseline makes every run noisy.
