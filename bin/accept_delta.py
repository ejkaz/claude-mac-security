#!/usr/bin/env python3
"""Accept a confirmed-legit delta into a baseline.

Usage:
  accept_delta.py <kind> <key> -m "justification"      # add/update one key from latest snapshot
  accept_delta.py <kind> --remove <key> -m "why"       # drop a stale key from the baseline
  accept_delta.py <kind> --all-removed -m "why"        # purge every removed-vs-snapshot key

Copies the item's current snapshot entry into the baseline with an audit
trail (_meta: accepted date + justification). The justification is required —
an unexplained baseline entry defeats the diff.
"""
import datetime
import json
import os
import sys

DATA = os.path.expanduser("~/.mac-security-suite")


def main():
    args = sys.argv[1:]
    if len(args) < 2 or args[0] not in ("persistence", "egress", "posture"):
        sys.exit(__doc__)
    kind = args[0]
    if "-m" not in args:
        sys.exit("justification required: -m \"why this is legit\"")
    note = args[args.index("-m") + 1]
    today = datetime.date.today().isoformat()

    base_path = f"{DATA}/baselines/{kind}.baseline.json"
    snap_path = f"{DATA}/snapshots/{kind}.json"
    base = json.load(open(base_path))
    snap = json.load(open(snap_path))

    def find(tree, key):
        return [(sec, items[key]) for sec, items in tree.items() if key in items]

    if "--all-removed" in args:
        purged = 0
        for sec in list(base):
            for k in list(base[sec]):
                if k not in snap.get(sec, {}):
                    del base[sec][k]
                    purged += 1
        print(f"purged {purged} removed key(s) ({note})")
    elif "--remove" in args:
        key = args[args.index("--remove") + 1]
        hits = find(base, key)
        if not hits:
            sys.exit(f"key not in baseline: {key}")
        for sec, _ in hits:
            del base[sec][key]
        print(f"removed [{', '.join(s for s, _ in hits)}] {key} ({note})")
    else:
        key = args[1]
        hits = find(snap, key)
        if not hits:
            sys.exit(f"key not in latest snapshot: {key} — run snapshot.py {kind} first")
        for sec, detail in hits:
            entry = dict(detail)
            entry["_meta"] = {"accepted": today, "why": note}
            base.setdefault(sec, {})[key] = entry
            print(f"accepted [{sec}] {key} ({note})")

    json.dump(base, open(base_path, "w"), indent=1, sort_keys=True)


if __name__ == "__main__":
    main()
