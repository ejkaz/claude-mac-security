#!/bin/bash
# install-tools.sh — provision the open-source toolchain for mac-security-suite.
# Read-only stance: we install on-demand scanners, NOT resident daemons aimed at you.
# Nothing here is auto-run; the skills invoke these tools when you ask them to.
#
# Usage:
#   bash install-tools.sh            # show what's missing, install nothing
#   bash install-tools.sh --install  # install the headless CLI layer via brew
#   bash install-tools.sh --gui      # also install GUI guardians (BlockBlock/OverSight/etc.)

set -uo pipefail

INSTALL=0; GUI=0
for a in "$@"; do
  case "$a" in
    --install) INSTALL=1 ;;
    --gui) GUI=1 ;;
  esac
done

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Install from https://brew.sh first." >&2
  exit 1
fi

# Headless CLI layer (agent-drivable, on-demand, no resident daemons)
FORMULAE=(clamav yara lynis)                       # brew formulae
# dnscrypt-proxy deliberately dropped (resident daemon). For encrypted+filtered DNS with
# zero residency, install a Quad9 DoH configuration profile instead — see manual steps.
CASKS=(lulu knockknock)                            # brew casks (GUI apps w/ CLI hooks)
# capa + vt-cli: release binaries, not in brew core — handled below.

# GUI guardians (real-time prevention; the harness can't drive these — install & forget)
GUI_CASKS=(blockblock oversight)

have() { command -v "$1" >/dev/null 2>&1; }
cask_installed() { brew list --cask "$1" >/dev/null 2>&1; }

echo "== mac-security-suite toolchain =="
echo
echo "-- Headless CLI layer --"
for f in "${FORMULAE[@]}"; do
  if brew list "$f" >/dev/null 2>&1; then echo "  ✅ $f"; else
    echo "  ❌ $f (missing)"; [ "$INSTALL" = 1 ] && brew install "$f"
  fi
done
for c in "${CASKS[@]}"; do
  if cask_installed "$c"; then echo "  ✅ $c (cask)"; else
    echo "  ❌ $c (missing)"; [ "$INSTALL" = 1 ] && brew install --cask "$c"
  fi
done

# lulu-cli — MIT, built for agent-driven LuLu rule management
if have lulu-cli; then echo "  ✅ lulu-cli"; else
  echo "  ❌ lulu-cli (missing — brew install woop/tap/lulu-cli)"
  [ "$INSTALL" = 1 ] && brew install woop/tap/lulu-cli
fi
# vt-cli — VirusTotal reputation (release binary; not in brew)
if have vt; then echo "  ✅ vt (vt-cli)"; else
  echo "  ❌ vt-cli (missing — gh release download -R VirusTotal/vt-cli -p MacOSX.zip, unzip, move 'vt' into PATH, de-quarantine)"
fi
# capa — Mach-O capability triage (release binary; not in brew)
if have capa; then echo "  ✅ capa"; else
  echo "  ❌ capa (missing — gh release download -R mandiant/capa -p '*macos-arm64.zip', unzip, move into PATH, de-quarantine)"
fi
# YARA rules — fetched, not vendored
if [ -d "$HOME/.mac-security-suite/yara-rules/elastic-macos" ]; then echo "  ✅ yara-rules (elastic-macos)"; else
  echo "  ❌ yara-rules (missing — bash bin/get-yara-rules.sh)"
  [ "$INSTALL" = 1 ] && bash "$(dirname "$0")/get-yara-rules.sh"
fi

echo
echo "-- GUI guardians (prevention; not agent-drivable) --"
for c in "${GUI_CASKS[@]}"; do
  if cask_installed "$c"; then echo "  ✅ $c"; else
    echo "  ⬜ $c (recommended — real-time $c protection)"
    [ "$GUI" = 1 ] && [ "$INSTALL" = 1 ] && brew install --cask "$c"
  fi
done
echo "  ⬜ RansomWhere? — behavioral ransomware backstop (objective-see.org, no brew cask)"

echo
echo "== Post-install manual steps (cannot be scripted on a non-MDM Mac) =="
echo "  1. ClamAV signatures:  freshclam   (first run downloads the DB)"
echo "  2. VirusTotal key:     vt init     (free key at virustotal.com)"
echo "  3. Full Disk Access:   System Settings > Privacy & Security > Full Disk Access"
echo "                         → add your terminal so KnockKnock + osquery tables work."
echo "  4. LuLu:               launch once, approve the system extension, then lulu-cli drives rules."
echo "  5. Encrypted DNS:      install a Quad9 DoH configuration profile (quad9.net) —"
echo "                         encrypted + malware-filtered DNS with no resident daemon."
echo
echo "Headless-only quick install:  bash install-tools.sh --install"
echo "Everything incl. GUI apps:    bash install-tools.sh --install --gui"
