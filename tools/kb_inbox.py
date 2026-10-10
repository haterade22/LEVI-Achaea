#!/usr/bin/env python3
"""Track what has been ingested from the knowledge-base inbox file.

The user keeps ONE running text file of pasted Achaea material (HELP files,
AB output, announcements, logs). This tool answers "what is new since the last
ingest?" by diffing that file against a snapshot taken at the last ingest.

    python tools/kb_inbox.py status [--src PATH]   # print new/changed text
    python tools/kb_inbox.py mark   [--src PATH]   # record the file as ingested

Paste separators are optional: a line of five or more '=' starts a new chunk,
and the status output numbers the chunks so each can be filed separately.
Only `mark` writes anything (kb/inbox/snapshot.txt), and only after the
/kb-ingest skill has filed everything `status` reported.
"""
import argparse
import difflib
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SNAPSHOT = os.path.join(ROOT, "kb", "inbox", "snapshot.txt")
DEFAULT_SRC = os.path.join(os.path.expanduser("~"), "OneDrive", "Desktop",
                           "Achaea Knowledge Base.txt")
SEPARATOR = re.compile(r"^={5,}\s*$")


def read_lines(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        return [line.rstrip("\r\n") for line in fh]


def new_regions(old, new):
    """Return [(start_line, [lines])] for every inserted or replaced block."""
    regions = []
    matcher = difflib.SequenceMatcher(a=old, b=new, autojunk=False)
    for tag, _i1, _i2, j1, j2 in matcher.get_opcodes():
        if tag in ("insert", "replace") and j2 > j1:
            regions.append((j1 + 1, new[j1:j2]))
    return regions


def chunks(start, lines):
    """Split one region on separator lines, dropping blank-only chunks."""
    out, cur, cur_start = [], [], start
    for offset, line in enumerate(lines):
        if SEPARATOR.match(line):
            out.append((cur_start, cur))
            cur, cur_start = [], start + offset + 1
        else:
            cur.append(line)
    out.append((cur_start, cur))
    return [(s, c) for s, c in out if any(l.strip() for l in c)]


def cmd_status(src):
    new = read_lines(src)
    old = read_lines(SNAPSHOT) if os.path.exists(SNAPSHOT) else []
    removed = sum(i2 - i1 for tag, i1, i2, _j1, _j2 in
                  difflib.SequenceMatcher(a=old, b=new, autojunk=False).get_opcodes()
                  if tag in ("delete", "replace"))
    found = [c for s, region in new_regions(old, new) for c in chunks(s, region)]
    if not found:
        print("Nothing new since the last ingest.")
    for n, (start, body) in enumerate(found, 1):
        print(f"----- CHUNK {n}: source lines {start}-{start + len(body) - 1} -----")
        print("\n".join(body))
    if removed:
        print(f"\nNOTE: {removed} previously-ingested line(s) were changed or removed "
              "in the source. Raw files are never edited; check whether the curated "
              "entries built from them need correcting.")


def cmd_mark(src):
    os.makedirs(os.path.dirname(SNAPSHOT), exist_ok=True)
    with open(SNAPSHOT, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(read_lines(src)) + "\n")
    print(f"Snapshot updated: {len(read_lines(src))} lines marked as ingested.")


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("command", choices=["status", "mark"])
    ap.add_argument("--src", default=DEFAULT_SRC, help="inbox text file")
    args = ap.parse_args()
    if not os.path.exists(args.src):
        sys.exit(f"Inbox file not found: {args.src}")
    {"status": cmd_status, "mark": cmd_mark}[args.command](args.src)


if __name__ == "__main__":
    main()
