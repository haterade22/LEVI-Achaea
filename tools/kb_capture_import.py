#!/usr/bin/env python3
"""File the in-game `kbcapture` output into kb/raw/live/.

`kbcapture` (Mudlet, misc_scripts/025_KB_Capture.lua) appends every answer it records to
<mudlet profile>/kb_capture.txt as blocks:

    ##### KBCAPTURE 2026-10-10T18:21:25Z | affliction show paralysis
    <the game's lines, verbatim>
    ##### END

This tool reads that file and:
  * copies it WHOLE to kb/raw/live/captures/ (the evidence; never edited),
  * writes each AFFLICTION SHOW answer to kb/raw/live/affliction_show/<aff>.txt (newest wins;
    git history keeps older ones),
  * appends new WHATCURES lines to kb/raw/live/whatcures.txt (read by tools/kb_catalog.py),
  * writes AFFLICTION LIST to kb/raw/live/affliction_list.txt and anything else to
    kb/raw/live/other/<command>.txt,
  * renames the source file to kb_capture.imported-<time>.txt so the next run starts clean,
  * regenerates kb/afflictions/catalog.md,
and reports every command that got no recognisable answer (usually a name the game does not use).

    python tools/kb_capture_import.py                 # newest kb_capture.txt in any Mudlet profile
    python tools/kb_capture_import.py --file <path>   # a specific file
    python tools/kb_capture_import.py --dry-run       # report only, write nothing
"""
import argparse
import glob
import os
import re
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIVE = os.path.join(ROOT, "kb", "raw", "live")
PROFILES = os.path.join(os.path.expanduser("~"), ".config", "mudlet", "profiles")
HEAD = re.compile(r"^##### KBCAPTURE (\S+) \| (.+?)( \| TIMEOUT)?$")
WHATCURES = re.compile(r"The affliction '.+?' is cured by: .+")


def find_capture():
    files = glob.glob(os.path.join(PROFILES, "*", "kb_capture.txt"))
    return max(files, key=os.path.getmtime) if files else None


def parse(text):
    """Return [{stamp, cmd, timeout, lines}] for every complete block."""
    blocks, cur = [], None
    for raw in text.splitlines():
        m = HEAD.match(raw)
        if m:
            cur = {"stamp": m.group(1), "cmd": m.group(2).strip().lower(),
                   "timeout": bool(m.group(3)), "lines": []}
        elif raw == "##### END" and cur is not None:
            while cur["lines"] and not cur["lines"][-1].strip():
                cur["lines"].pop()
            while cur["lines"] and not cur["lines"][0].strip():
                cur["lines"].pop(0)
            blocks.append(cur)
            cur = None
        elif cur is not None:
            cur["lines"].append(raw.rstrip())
    return blocks


def slug(cmd):
    return re.sub(r"[^a-z0-9]+", "_", cmd.lower()).strip("_")[:80]


def write(path, text, dry):
    if dry:
        return
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--file", help="capture file (default: newest kb_capture.txt in any profile)")
    ap.add_argument("--dry-run", action="store_true", help="report only, write nothing")
    ap.add_argument("--keep", action="store_true", help="do not rename the source file afterwards")
    args = ap.parse_args()

    src = args.file or find_capture()
    if not src or not os.path.exists(src):
        sys.exit("No kb_capture.txt found. Run `kbcapture afflictions` in Mudlet first.")
    with open(src, encoding="utf-8", errors="replace") as fh:
        text = fh.read()
    blocks = parse(text)
    if not blocks:
        sys.exit(f"{src}: no complete capture blocks.")

    when = time.strftime("%Y-%m-%d_%H%M%S")
    write(os.path.join(LIVE, "captures", f"kb_capture_{when}.txt"), text, args.dry_run)

    wc_path = os.path.join(LIVE, "whatcures.txt")
    existing = set()
    if os.path.exists(wc_path):
        with open(wc_path, encoding="utf-8") as fh:
            existing = {l.strip() for l in fh}
    new_wc, shows, others, silent = [], 0, 0, []

    for b in blocks:
        cmd, body = b["cmd"], [l for l in b["lines"]]
        nonblank = [l for l in body if l.strip()]
        if cmd.startswith("whatcures "):
            hits = [l.strip() for l in body if WHATCURES.search(l)]
            if not hits:
                silent.append((cmd, nonblank[0] if nonblank else "(no output)"))
            for h in hits:
                h = WHATCURES.search(h).group(0)
                if h not in existing:
                    existing.add(h)
                    new_wc.append(h)
        elif cmd.startswith("affliction show "):
            if not nonblank:
                silent.append((cmd, "(no output)"))
                continue
            aff = slug(cmd[len("affliction show "):])
            write(os.path.join(LIVE, "affliction_show", f"{aff}.txt"),
                  f"# {b['cmd']}  ({b['stamp']})\n" + "\n".join(body) + "\n", args.dry_run)
            shows += 1
        elif cmd == "affliction list":
            write(os.path.join(LIVE, "affliction_list.txt"),
                  f"# affliction list  ({b['stamp']})\n" + "\n".join(body) + "\n", args.dry_run)
            others += 1
        else:
            write(os.path.join(LIVE, "other", f"{slug(cmd)}.txt"),
                  f"# {b['cmd']}  ({b['stamp']})\n" + "\n".join(body) + "\n", args.dry_run)
            others += 1

    if new_wc and not args.dry_run:
        with open(wc_path, "a", encoding="utf-8", newline="\n") as fh:
            fh.write(f"# {time.strftime('%Y-%m-%d %H:%M')} (kbcapture)\n" + "\n".join(new_wc) + "\n")

    print(f"{src}: {len(blocks)} answers")
    print(f"  WHATCURES: {len(new_wc)} new line(s) -> kb/raw/live/whatcures.txt")
    print(f"  AFFLICTION SHOW: {shows} file(s) -> kb/raw/live/affliction_show/")
    print(f"  other: {others} file(s)")
    if silent:
        print(f"  {len(silent)} command(s) got no recognisable answer (often: the game uses another name):")
        for cmd, first in silent:
            print(f"    {cmd:40} {first[:90]}")

    if args.dry_run:
        print("(dry run: nothing written)")
        return
    if not args.keep:
        os.replace(src, os.path.join(os.path.dirname(src), f"kb_capture.imported-{when}.txt"))
    subprocess.run([sys.executable, "-I", os.path.join(ROOT, "tools", "kb_catalog.py")], check=False)


if __name__ == "__main__":
    main()
