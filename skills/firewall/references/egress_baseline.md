# Known-Good Egress Baseline — EXAMPLE TEMPLATE

> Template. Populate from your own `Netiquette -list -pretty` + `lulu-cli list` output and keep
> private — your real destination list fingerprints your machine. A flow NOT listed here, from
> an unexpected process, is a finding.

## Confirmed-legit destinations (replace with your own)
- Cloud AI APIs your tools use (e.g. an LLM provider's IP range).
- Browser push (e.g. Chrome FCM on `:5228`, Google/GCP ranges).
- Vendor sync/telemetry you accept (Adobe, Microsoft/OneDrive, your VPN's servers).
- Apple iCloud / Continuity (skip with `-skipApple` in Netiquette).

## Known listening (localhost-only is usually benign)
- App helpers on `127.0.0.1` (updaters, sync daemons).
- `ControlCenter *:5000` / `*:7000` — AirPlay Receiver (disable if unused).
- `rapportd` — Apple Continuity (dynamic port).

## Maintenance
On a confirmed-legit new destination, append here with date so it stops surfacing. Hand
unrecognized IPs to `malware-triage` or `vt ip <addr>` before baselining.
