"""File the in-game fight logs into kb/raw/logs/ours/ and summarise them.

The package's fight recorder (misc_scripts/026_Fight_Log.lua, `fightlog` in Mudlet) writes one file
per fight to <mudlet profile>/fightlogs/<date>_<time>_<Opponent>.log. Each row is
"<HH:MM:SS.mmm> <kind> <text>"; the kinds are explained in the file's second header line.

    python tools/fightlog_import.py              # copy new logs, print a summary of each
    python tools/fightlog_import.py --dry-run    # summary only, copy nothing
    python tools/fightlog_import.py some.log     # file and summarise these logs only

Logs are copied, never moved or edited: the Mudlet folder keeps its copy, and a log already filed
with the same content is skipped.
"""
import argparse
import collections
import glob
import os
import re
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEST = os.path.join(ROOT, "kb", "raw", "logs", "ours")
PROFILES = os.path.join(os.path.expanduser("~"), ".config", "mudlet", "profiles")
ROW = re.compile(r"^(\d\d):(\d\d):(\d\d)\.(\d\d\d) (\S+) ?(.*)$")
HEADER = re.compile(r"\| opponent (\S+) \| our class (.+?) \| (.+)$")


def find_logs(profiles):
    return sorted(glob.glob(os.path.join(profiles, "*", "fightlogs", "*.log")))


QUEUE = re.compile(r"^queue (?:add\S*|insert|prepend) \S+ (.*)$", re.I)


def commands(text):
    """The first word of each command in what we sent, seen through a server queue entry:
    "queue addclearfull freestand stand;combo agathon sweep" -> stand, combo."""
    m = QUEUE.match(text.strip())
    payload = m.group(1) if m else text
    return [part.split()[0].lower() for part in payload.split(";") if part.split()]


def summarise(path):
    kinds = collections.Counter()
    gained = collections.Counter()
    sent = collections.Counter()
    first = last = None
    info = {"opponent": "?", "class": "?", "why": "?", "stopped": "(still recording, or cut short)"}
    with open(path, encoding="utf-8", errors="replace") as fh:
        for raw in fh:
            line = raw.rstrip("\n")
            if line.startswith("# LEVI fight log"):
                m = HEADER.search(line)
                if m:
                    info["opponent"], info["class"], info["why"] = m.groups()
                continue
            if line.startswith("# stopped: "):
                info["stopped"] = line[len("# stopped: "):]
                continue
            m = ROW.match(line)
            if not m:
                continue
            h, mi, s, ms, kind, text = m.groups()
            t = int(h) * 3600 + int(mi) * 60 + int(s) + int(ms) / 1000
            if first is None:
                first = t
            last = t
            kinds[kind] += 1
            if kind == "+aff":
                gained[text] += 1
            elif kind == ">":
                for word in commands(text):
                    sent[word] += 1
    span = 0.0
    if first is not None:
        span = last - first if last >= first else last + 86400 - first  # past midnight
    return info, kinds, gained, sent, span


def report(path):
    info, kinds, gained, sent, span = summarise(path)
    print(f"\n{os.path.basename(path)}")
    print(f"  vs {info['opponent']} | we were {info['class']} | {info['why']} | {span:.0f} s")
    print(f"  stopped: {info['stopped']}")
    print("  rows: " + ", ".join(f"{k} {n}" for k, n in sorted(kinds.items())))
    if gained:
        print("  afflictions we got: " + ", ".join(f"{a} x{n}" for a, n in gained.most_common(12)))
    if sent:
        print("  commands we sent (first word): " + ", ".join(f"{c} x{n}" for c, n in sent.most_common(8)))


def same_file(a, b):
    if not os.path.exists(b) or os.path.getsize(a) != os.path.getsize(b):
        return False
    with open(a, "rb") as fa, open(b, "rb") as fb:
        return fa.read() == fb.read()


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("logs", nargs="*", help="log files (default: every <profile>/fightlogs/*.log)")
    ap.add_argument("--profiles", default=PROFILES, help="Mudlet profiles folder")
    ap.add_argument("--dry-run", action="store_true", help="summarise only, copy nothing")
    args = ap.parse_args()

    logs = args.logs or find_logs(args.profiles)
    if not logs:
        sys.exit(f"No fight logs under {args.profiles}. In Mudlet: `fightlog status` shows the folder.")
    copied = skipped = 0
    for src in logs:
        dst = os.path.join(DEST, os.path.basename(src))
        if os.path.abspath(src) == os.path.abspath(dst) or same_file(src, dst):
            skipped += 1
        elif not args.dry_run:
            os.makedirs(DEST, exist_ok=True)
            shutil.copyfile(src, dst)
            copied += 1
        report(src)
    verb = "would copy" if args.dry_run else "copied"
    print(f"\n{len(logs)} log(s): {verb} {len(logs) - skipped if args.dry_run else copied}, "
          f"{skipped} already filed. Folder: {os.path.relpath(DEST, ROOT)}")


if __name__ == "__main__":
    main()
