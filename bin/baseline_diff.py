#!/usr/bin/env python3
"""Deterministic baseline diff for mac-security-suite.

Usage:
  baseline_diff.py <kind> [--snapshot FILE] [--init] [--json]

kind: persistence | egress | posture
Compares ~/.mac-security-suite/snapshots/<kind>.json against
~/.mac-security-suite/baselines/<kind>.baseline.json.

ADDED and CHANGED keys are findings (exit 1). REMOVED keys are informational
(usually uninstalls — exit 0 if removals only). --init seeds the baseline from
the current snapshot. Fields starting with "_" (e.g. _vt, _meta) are excluded
from identity comparison.
"""
import json
import os
import sys

DATA = os.path.expanduser("~/.mac-security-suite")


def identity(detail):
    return {k: v for k, v in detail.items() if not k.startswith("_")}


def main():
    args = sys.argv[1:]
    if not args or args[0] not in ("persistence", "egress", "posture"):
        sys.exit(__doc__)
    kind = args[0]
    snap_path = f"{DATA}/snapshots/{kind}.json"
    if "--snapshot" in args:
        snap_path = args[args.index("--snapshot") + 1]
    base_path = f"{DATA}/baselines/{kind}.baseline.json"

    snap = json.load(open(snap_path))

    if "--init" in args:
        os.makedirs(os.path.dirname(base_path), exist_ok=True)
        json.dump(snap, open(base_path, "w"), indent=1, sort_keys=True)
        print(f"baseline initialized: {base_path} "
              f"({sum(len(v) for v in snap.values())} items)")
        return

    if not os.path.exists(base_path):
        sys.exit(f"no baseline at {base_path} — run with --init first")
    base = json.load(open(base_path))

    added, removed, changed = [], [], []
    for sec in sorted(set(snap) | set(base)):
        s, b = snap.get(sec, {}), base.get(sec, {})
        for k in sorted(set(s) | set(b)):
            if k not in b:
                added.append((sec, k, s[k]))
            elif k not in s:
                removed.append((sec, k))
            elif identity(s[k]) != identity(b[k]):
                changed.append((sec, k, identity(b[k]), identity(s[k])))

    if "--json" in args:
        json.dump({"added": [{"section": s, "key": k, "detail": d} for s, k, d in added],
                   "removed": [{"section": s, "key": k} for s, k in removed],
                   "changed": [{"section": s, "key": k, "was": w, "now": n}
                               for s, k, w, n in changed]},
                  sys.stdout, indent=1)
        print()
    else:
        print(f"# {kind} diff — {len(added)} added / {len(changed)} changed / "
              f"{len(removed)} removed")
        for s, k, d in added:
            print(f"  ＋ [{s}] {k}  {json.dumps(identity(d))}")
        for s, k, w, n in changed:
            print(f"  ≠ [{s}] {k}  was={json.dumps(w)} now={json.dumps(n)}")
        for s, k in removed:
            print(f"  － [{s}] {k}  (removed — usually benign)")
        if not (added or changed or removed):
            print("  ✅ clean — matches baseline")

    sys.exit(1 if (added or changed) else 0)


if __name__ == "__main__":
    main()
