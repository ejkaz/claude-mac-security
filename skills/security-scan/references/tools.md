# Open-Source Security Toolkit (macOS)

What to install, what each closes, and how to run it. All free/open-source.

## Objective-See suite (Patrick Wardle) — the macOS gold standard
| Tool | Closes | Install | Run |
|---|---|---|---|
| **KnockKnock** | "Bespoke/hidden tool" gap — enumerates ALL persistent software, checks each against VirusTotal | `brew install --cask knockknock` | `/Applications/KnockKnock.app/Contents/MacOS/KnockKnock -whosthere -pretty` |
| **ReiKey** | Keyloggers — detects keystroke "event taps" | `brew install --cask reikey` | GUI, runs in background |
| **LuLu** | Exfil — outbound firewall, alerts on every connection (would catch a tool phoning home) | `brew install --cask lulu` | GUI; **needs one-time manual "Allow System Extension" approval** |
| **OverSight** | Covert recording — alerts on mic/camera activation | `brew install --cask oversight` | GUI |
| **BlockBlock** | Future installs — real-time persistence monitor | `brew install --cask blockblock` | GUI |

## Auditing & signatures
| Tool | Closes | Install | Run |
|---|---|---|---|
| **Lynis** | Hardening gaps — scored config audit + recommendations | `brew install lynis` | `lynis audit system` (report: `/var/log/lynis-report.dat`) |
| **ClamAV** | Known malware signatures | `brew install clamav` | `freshclam && clamscan -r ~/` |

## Capability vs. this skill's built-in sweep
- **scan.sh** = structural + name-based detection. Catches commodity EDR/DLP/MDM/RMM/spyware, kexts, standard persistence, network exposure. Fast, no installs.
- **KnockKnock + VirusTotal** = reputation-based. Closes the targeted/custom-implant gap scan.sh can't. **Run this when you want real assurance, not just "nothing obvious."**
- **ReiKey** = the keylogger detector — the one thing TCC GUI inspection can miss (a tap without a TCC entry).
- **LuLu** = ongoing visibility — the only tool here that keeps watching after the scan ends.

## Recommended cadence
- **Quarterly / on employer change / after installing unknown software:** `/security-scan deep` + KnockKnock.
- **Always-on:** LuLu (outbound visibility) + OverSight (cam/mic). Low-friction, high signal.
- **One-time hardening pass:** Lynis, action its top suggestions, re-score.
