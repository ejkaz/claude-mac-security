# Known-Good Egress Baseline

Confirmed-legit outbound destinations. A flow NOT listed here, from an unexpected process,
is a finding. Append confirmed-legit destinations with a date + justification.

## Confirmed-legit destinations
- **Anthropic** `160.79.104.0/24`, `2607:6bc0::/32` — Claude / Claude Code / Cursor / Codex.
- **Google** — Chrome FCM push (`:5228`), Google/GCP ranges (`34.x`, `35.190.x`, `142.251.x`).
- **Adobe** — Adobe + AWS ranges (Creative Cloud sync, updaters).
- **Microsoft** — OneDrive / Office updaters.
- **Apple** — iCloud / Continuity (skip with `-skipApple` in Netiquette).

## Known listening (localhost-only, benign)
- Adobe / `Creative` / OneDrive on `127.0.0.1` · `Adobe *:1929x` localhost.
- `ControlCenter *:5000` / `*:7000` — AirPlay Receiver (disable if unused).
- `rapportd` — Apple Continuity (dynamic port).
- `Superhuman 127.0.0.1:*` — email app, localhost-only.

## Maintenance
On a confirmed-legit new destination, append here with date so it stops surfacing.
