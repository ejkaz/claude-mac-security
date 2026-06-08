# Known-Good Persistence Baseline

Confirmed-legit persistence items. A KnockKnock entry NOT listed here is a finding.
Append confirmed-legit items with a date + justification. Mirrors the
`security-scan` launchd baseline; KnockKnock sees a broader set (login items, dylib
inserts, browser extensions) — extend as those are reviewed.

## LaunchDaemons (system) — vendor updaters / app helpers
adobe (acc.installer, agsservice, ARMDC.Communicator, ARMDC.SMJobBlessHelper) · docker
(socket, vmnetd) · google (GoogleUpdater.wake.system, keystone.daemon) · microsoft
(autoupdate.helper, office.licensingV2.helper, OneDrive*UpdaterDaemon) · vanta.metalauncher
(employer SOC2 compliance) · zoom (ZoomDaemon)

## LaunchAgents (system)
adobe (AdobeCreativeCloud, ARMDCHelper, ccxprocess, GC.Invoker) · google (keystone.agent,
keystone.xpcservice) · microsoft (OneDriveStandaloneUpdater, SyncReporter, update.agent) ·
zoom (updater, updater.login.check)

## LaunchAgents (user) — incl. Eric's own
perplexity (CometUpdater.wake, keystone.*) · adobe (ccxprocess, GC.Invoker) · google
(GoogleUpdater.wake, keystone.*) · **com.eric.claude-rc** · **com.eric.morning-briefing** ·
**com.eric.weekly-pipeline-review**

## System extensions
- `ch.protonvpn.mac.WireGuard-Extension` (Proton VPN) — only system extension. No EDR.

## Maintenance
On a confirmed-legit new item, append here with date.
