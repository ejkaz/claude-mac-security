# Known-Good Persistence Baseline — EXAMPLE TEMPLATE

> Template. Populate from your own `KnockKnock -whosthere -pretty` output and keep private —
> a real persistence inventory fingerprints your machine. A KnockKnock entry NOT listed here
> is a finding. Append confirmed-legit items with a date + justification.

## LaunchDaemons / LaunchAgents (vendor updaters are normal)
- Common-benign: Adobe, Google (keystone), Microsoft (Office/OneDrive), Docker, Zoom updaters.
- Employer compliance agent (if any) — verify vendor-signed + who deployed it.
- Your own scheduled agents (`com.<you>.<job>`) — list them so they stop alerting.

## System / kernel extensions
- `<your.vpn.extension>` only, if you run a VPN. No EDR/network-filter extension you didn't
  install. Empty kext list = good.

## Login items / dylib inserts / browser extensions
- KnockKnock surfaces these too — review and list the legit ones (your launch-at-login apps,
  your browser extensions). Unsigned dylib inserts into common apps are high-signal findings.

## Maintenance
On a confirmed-legit new item, append here with date. Any nonzero VirusTotal detection on an
unsigned/unknown binary → escalate to `malware-triage`, do not baseline.
