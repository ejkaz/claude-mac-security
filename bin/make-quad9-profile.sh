#!/bin/bash
# make-quad9-profile.sh — generate a Quad9 DNS-over-HTTPS configuration profile.
# Encrypted + malware-filtered DNS with NO resident daemon (the suite's answer
# to dnscrypt-proxy). Output: ~/Desktop/Quad9-DoH.mobileconfig — double-click it,
# then approve in System Settings > General > Device Management.

set -euo pipefail
OUT="${1:-$HOME/Desktop/Quad9-DoH.mobileconfig}"
U1=$(uuidgen); U2=$(uuidgen)

cat > "$OUT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PayloadContent</key>
  <array>
    <dict>
      <key>DNSSettings</key>
      <dict>
        <key>DNSProtocol</key><string>HTTPS</string>
        <key>ServerURL</key><string>https://dns.quad9.net/dns-query</string>
        <key>ServerAddresses</key>
        <array>
          <string>9.9.9.9</string>
          <string>149.112.112.112</string>
          <string>2620:fe::fe</string>
          <string>2620:fe::9</string>
        </array>
      </dict>
      <key>PayloadDescription</key><string>Quad9 DNS over HTTPS (malware-domain filtering, DNSSEC)</string>
      <key>PayloadDisplayName</key><string>Quad9 DoH</string>
      <key>PayloadIdentifier</key><string>net.quad9.dns.$U1</string>
      <key>PayloadType</key><string>com.apple.dnsSettings.managed</string>
      <key>PayloadUUID</key><string>$U1</string>
      <key>PayloadVersion</key><integer>1</integer>
      <key>ProhibitDisablement</key><false/>
    </dict>
  </array>
  <key>PayloadDescription</key><string>Encrypted, malware-filtered DNS via Quad9. No resident daemon.</string>
  <key>PayloadDisplayName</key><string>Quad9 Encrypted DNS (DoH)</string>
  <key>PayloadIdentifier</key><string>net.quad9.dns.profile.$U2</string>
  <key>PayloadType</key><string>Configuration</string>
  <key>PayloadUUID</key><string>$U2</string>
  <key>PayloadVersion</key><integer>1</integer>
</dict>
</plist>
EOF

plutil -lint "$OUT"
echo "→ open \"$OUT\", then approve in System Settings > General > Device Management."
echo "→ verify afterwards: curl -s https://on.quad9.net/ | grep -o 'ARE using quad9'"
