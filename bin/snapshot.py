#!/usr/bin/env python3
"""Canonical JSON snapshot for the mac-security-suite diff engine.

Usage: snapshot.py <persistence|egress|posture>

Emits {section: {key: detail}} on stdout — stable keys, diff-friendly details.
Set VT_KEY to include VirusTotal ratios in persistence snapshots (informational;
VT fields are excluded from diff identity since denominators drift).
Read-only: never mutates system state.
"""
import json
import os
import re
import subprocess
import sys

DATA = os.path.expanduser("~/.mac-security-suite")


def run(cmd, timeout=600):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout).stdout
    except Exception:
        return ""


def snap_persistence():
    kk = "/Applications/KnockKnock.app/Contents/MacOS/KnockKnock"
    if not os.path.exists(kk):
        sys.exit("KnockKnock not installed")
    cmd = [kk, "-whosthere", "-skipApple"]
    vt_key = os.environ.get("VT_KEY")
    if vt_key:
        cmd += ["-key", vt_key]
    raw = run(cmd)
    data = json.loads(raw)
    out = {}
    for cat, items in data.items():
        sec = {}
        for it in items:
            if not isinstance(it, dict):
                continue
            path = it.get("path", "?")
            sig = it.get("signature(s)")
            sig = sig if isinstance(sig, dict) else {}
            auths = sig.get("signatureAuthorities") or []
            hashes = it.get("hashes")
            sha = hashes.get("sha256", "") if isinstance(hashes, dict) else str(hashes or "")
            sec[path] = {
                "signer": auths[0] if auths else "UNSIGNED",
                "sha256": sha,
                "_vt": it.get("VT detection", ""),  # informational; excluded from diff
            }
        out[cat] = sec
    return out


def snap_egress():
    raw = run(["lulu-cli", "list"], timeout=60)
    rules = {}
    current = None
    for line in raw.splitlines():
        m = re.match(r"^\[(.+)\]$", line.strip())
        if m:
            current = m.group(1)
            continue
        m = re.match(r"^\s*[0-9A-F-]{36}\s*\|\s*(\w+)\s*\|\s*(\S+ \S+)\s*\|\s*type=(\S+)", line)
        if m and current:
            action, endpoint, rtype = m.group(1), m.group(2), m.group(3)
            rules.setdefault(current, []).append(f"{action} {endpoint} ({rtype})")
    return {"lulu_rules": {k: {"rules": sorted(v)} for k, v in rules.items()}}


def snap_posture():
    checks = {
        "sip": run(["csrutil", "status"]).strip(),
        "gatekeeper": run(["spctl", "--status"]).strip(),
        "filevault": run(["fdesetup", "status"]).strip(),
        "app_firewall": run(["/usr/libexec/ApplicationFirewall/socketfilterfw", "--getglobalstate"]).strip(),
        "stealth_mode": run(["/usr/libexec/ApplicationFirewall/socketfilterfw", "--getstealthmode"]).strip(),
    }
    posture = {k: {"state": v} for k, v in checks.items()}

    sysext = {}
    for line in run(["systemextensionsctl", "list"]).splitlines():
        m = re.search(r"(\S+\.\S+)\s+\((\S+)\)\s+(.+?)\t\[(.+)\]", line)
        if m:
            sysext[m.group(1)] = {"state": m.group(4)}

    launchd = {}
    for d in ["/Library/LaunchDaemons", "/Library/LaunchAgents",
              os.path.expanduser("~/Library/LaunchAgents")]:
        try:
            for f in sorted(os.listdir(d)):
                if f.endswith(".plist"):
                    launchd[f"{d}/{f}"] = {"state": "present"}
        except OSError:
            pass

    return {"posture": posture, "system_extensions": sysext, "launchd_files": launchd}


def main():
    kind = sys.argv[1] if len(sys.argv) > 1 else ""
    fn = {"persistence": snap_persistence, "egress": snap_egress, "posture": snap_posture}.get(kind)
    if not fn:
        sys.exit(__doc__)
    json.dump(fn(), sys.stdout, indent=1, sort_keys=True)
    print()


if __name__ == "__main__":
    main()
