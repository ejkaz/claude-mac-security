#!/bin/bash
# install-sentinel.sh — install (or refresh) the weekly sentinel launchd job.
# Mondays 09:15 local. Quick mode weekly; sentinel auto-escalates to deep
# (VirusTotal) on its first run each month. Logs to ~/.mac-security-suite/sentinel.log.
#
# Usage: bash install-sentinel.sh            # install/refresh
#        bash install-sentinel.sh --remove   # uninstall

set -euo pipefail
LABEL="com.eric.mac-security-sentinel"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
BIN="$(cd "$(dirname "$0")" && pwd)"

if [ "${1:-}" = "--remove" ]; then
  launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
  rm -f "$PLIST"
  echo "sentinel removed"
  exit 0
fi

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$BIN/sentinel.sh</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Weekday</key><integer>1</integer>
    <key>Hour</key><integer>9</integer>
    <key>Minute</key><integer>15</integer>
  </dict>
  <key>StandardOutPath</key><string>$HOME/.mac-security-suite/sentinel.log</string>
  <key>StandardErrorPath</key><string>$HOME/.mac-security-suite/sentinel.log</string>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "sentinel installed: $LABEL (Mondays 09:15, runs $BIN/sentinel.sh)"
echo "NOTE: for full persistence coverage in cron, grant KnockKnock.app Full Disk Access"
echo "      (FDA on your terminal does not extend to launchd jobs)."
