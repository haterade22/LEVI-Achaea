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
# "...is cured by: X" or "...has no known cures." -- both are real answers (10 afflictions,
# amnesia and deepsleep among them, have no cure at all).
WHATCURES = re.compile(r"The affliction '(.+?)' (?:is cured by: .+|has no known cures\.)")
PAGER = re.compile(r"^\[(Type MORE if you wish to continue reading|File continued via MORE)")


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
            if PAGER.match(raw):
                continue  # the game's MORE prompts are paging, not part of the answer
            cur["lines"].append(raw.rstrip())
    return blocks


SHOW_LABEL = re.compile(r"^([A-Za-z()' ]+?):\s{2,}")


def squash(name):
    n = name.lower()
    for art in ("a ", "an "):
        if n.startswith(art):
            n = n[len(art):]
    return re.sub(r"[^a-z]", "", n)


def route(blocks):
    """Find every AFFLICTION SHOW record wherever it landed.

    Returns ({key: (stamp, cmd, lines)}, answered) where `answered` holds ("show", key) for every
    affliction that got a record or a refusal. A record found in its own `affliction show X` block
    is filed under X (so an old name like `disfigurement` keeps its own file); a record found in
    any other block is filed under its own name.
    """
    out, answered = {}, set()
    for b in blocks:
        own = slug(b["cmd"][len("affliction show "):]) if b["cmd"].startswith("affliction show ") else None
        lines, i, first = b["lines"], 0, True
        while i < len(lines):
            m = re.match(r"^Affliction:\s{2,}(.+)$", lines[i])
            if not m:
                i += 1
                continue
            rec = [lines[i]]
            i += 1
            while i < len(lines):
                l = lines[i]
                if SHOW_LABEL.match(l) and not l.startswith("Affliction:"):
                    rec.append(l)
                elif l.startswith("   ") and l.strip():
                    rec.append(l)  # an indented continuation (a second cure line)
                elif l.strip():
                    # flush-left text inside a record is not ours (a channel line); skip it
                    pass
                # A record runs to the next record or the end of the block. It does NOT end at the
                # last yes/no flag: some records carry `Default time:` / `Expire msg:` after it.
                if l.startswith("Affliction:"):
                    break
                i += 1
            key = own if (own and first) else squash(m.group(1))
            out[key] = (b["stamp"], b["cmd"] if key == own else f"affliction show {key}", rec)
            answered.add(("show", key))
            first = False
        if own and any(l.startswith("There is no such affliction") for l in lines):
            out.setdefault(own, (b["stamp"], b["cmd"], ["There is no such affliction."]))
            answered.add(("show", own))
    return out, answered


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
    archived = os.path.abspath(src).startswith(os.path.abspath(os.path.join(LIVE, "captures")))
    if not archived:
        write(os.path.join(LIVE, "captures", f"kb_capture_{when}.txt"), text, args.dry_run)

    wc_path = os.path.join(LIVE, "whatcures.txt")
    existing = set()
    if os.path.exists(wc_path):
        with open(wc_path, encoding="utf-8") as fh:
            existing = {l.strip() for l in fh}
    new_wc, shows, others = [], 0, 0

    # Route by CONTENT, not by which command a block was filed under. A lag spike longer than the
    # capture timeout shifts later answers into the next block (2026-10-11: the anorexia record
    # landed in `whatcures anorexia`, the blindness WHATCURES line in `affliction show bloodfire`),
    # but every answer names its affliction, so it can be filed where it belongs.
    show_records, answered = route(blocks)
    for b in blocks:
        for l in b["lines"]:
            m = WHATCURES.search(l)
            if m:
                answered.add(("whatcures", m.group(1).lower()))
                if m.group(0) not in existing:
                    existing.add(m.group(0))
                    new_wc.append(m.group(0))
    for key, (stamp, cmd, lines) in show_records.items():
        write(os.path.join(LIVE, "affliction_show", f"{key}.txt"),
              f"# {cmd}  ({stamp})\n" + "\n".join(lines) + "\n", args.dry_run)
        shows += 1
    silent = []
    for b in blocks:
        for kind, prefix in (("whatcures", "whatcures "), ("show", "affliction show ")):
            if b["cmd"].startswith(prefix) and (kind, slug(b["cmd"][len(prefix):])) not in answered:
                first = next((l for l in b["lines"] if l.strip()), "(no output)")
                silent.append((b["cmd"], first))

    for b in blocks:
        cmd, body = b["cmd"], b["lines"]
        if cmd.startswith("whatcures ") or cmd.startswith("affliction show "):
            continue
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
    subprocess.run([sys.executable, "-I", os.path.join(ROOT, "tools", "kb_affliction_db.py")], check=False)
    subprocess.run([sys.executable, "-I", os.path.join(ROOT, "tools", "kb_catalog.py")], check=False)


if __name__ == "__main__":
    main()
