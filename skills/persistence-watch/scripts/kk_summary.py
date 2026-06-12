#!/usr/bin/env python3
"""Summarize a KnockKnock -whosthere JSON file: one line per item with signer + VT ratio.
⚠️ marks unsigned binaries or nonzero VT detections. Usage: kk_summary.py <kk.json>"""
import json
import sys

d = json.load(open(sys.argv[1]))
for cat, items in d.items():
    if not items:
        continue
    print(f"{cat}: {len(items)}")
    for it in items:
        name = it.get("path", "?").rsplit("/", 1)[-1]
        sig = it.get("signature(s)") or {}
        auths = sig.get("signatureAuthorities") or []
        auth = auths[0] if auths else "UNSIGNED"
        vt = it.get("VT detection", "n/a")
        nonzero_vt = vt not in ("n/a", "0/0") and not vt.startswith("0/")
        flag = " ⚠️" if (not auths or nonzero_vt) else ""
        print(f"  {name} [{auth}] VT:{vt}{flag}")
