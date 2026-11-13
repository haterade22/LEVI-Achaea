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
  * files each ABADMIN SHOW record (`kbcapture abilities`) as kb/raw/abadmin/<skill>_<ability>_<id>.txt,
    by the id in the record's OWN first line (a late answer lands in the next block); the newest
    capture of an id wins, and an old file of a renamed ability is removed (kb/raw/ab/ holds answers
    of the AB command, a different layout, and this tool does not touch it),
  * writes ARTEFACT POWER LIST OWNED to kb/raw/live/artefact_power_list_owned.txt and each
    ARTEFACT POWER SHOW <p> to kb/raw/artefacts/<p>.txt (`kbcapture artefacts`),
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
    # A late answer: `affliction show X` timed out empty and its record landed in the next block,
    # `whatcures X` (2026-10-23, transfixation). Filed under its own name it became a second
    # record of the same affliction (`stateoftransfixation`), so file it under X instead.
    late = None
    for b in blocks:
        own = slug(b["cmd"][len("affliction show "):]) if b["cmd"].startswith("affliction show ") else None
        late_key = late[1] if late and b["cmd"] == "whatcures " + late[0] else None
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
            key = own if (own and first) else (late_key if (late_key and first) else squash(m.group(1)))
            out[key] = (b["stamp"], b["cmd"] if key == own else f"affliction show {key}", rec)
            answered.add(("show", key))
            first = False
        late = (b["cmd"][len("affliction show "):], own) if (own and b["timeout"] and first) else None
        if own and any(l.startswith("There is no such affliction") for l in lines):
            out.setdefault(own, (b["stamp"], b["cmd"], ["There is no such affliction."]))
            answered.add(("show", own))
    return out, answered


def slug(cmd):
    return re.sub(r"[^a-z0-9]+", "_", cmd.lower()).strip("_")[:80]


# An ABADMIN SHOW record, as the game sends it (the first live run, 2026-11-13):
#   Ability: Obliviate (Record #2115)
#   Associated skill: Attainment
#   Skillpoints required: 38999 ... Cooldown: 41.00 seconds / Resource: 28 rage
# A pointer record holds only its first two lines and "Maps to record 785 (FIST).". An id with no
# ability answers "No such record.". (v4.7.494 matched "Pulse (Psionics)  ABADMIN ID: 3292", the
# header of the AB command: the files in kb/raw/ab/ hold AB answers and stay as they are.)
AB_HEAD = re.compile(r"^Ability: (.+) \(Record #(\d+)\)\s*$")
AB_SKILL = re.compile(r"^Associated skill: (.+?)\s*$")
AB_NONE = "No such record."
AB_CMD = re.compile(r"^abadmin show (\d+)$")
AB_DIR = os.path.join("kb", "raw", "abadmin")


def ab_ids(ab_dir):
    """{id: file name} for every ABADMIN SHOW record already filed in kb/raw/abadmin/."""
    have = {}
    for p in sorted(glob.glob(os.path.join(ab_dir, "*.txt"))):
        with open(p, encoding="utf-8", errors="replace") as fh:
            m = AB_HEAD.match(fh.readline())
        if m:
            have[int(m.group(2))] = os.path.basename(p)
    return have


def ab_records(blocks):
    """{id: (ability, skill, lines)} for every ABADMIN SHOW record in the `abadmin show` blocks.

    A record runs from its first line to the next record or the end of its block; lines before it (a
    room line that arrived first) are not part of it. It is keyed by the id in its own first line, not
    by the block's command: an answer that comes after the capture's timeout lands in the next block,
    and its first line still names it. A later copy of an id wins.
    """
    out = {}
    for b in blocks:
        if not AB_CMD.match(b["cmd"]):
            continue
        rec = None
        for line in b["lines"]:
            m = AB_HEAD.match(line)
            if m:
                rec = {"ability": m.group(1).strip(), "skill": "", "lines": [line]}
                out[int(m.group(2))] = rec
            elif rec is not None:
                rec["lines"].append(line)
                s = AB_SKILL.match(line)
                if s and not rec["skill"]:
                    rec["skill"] = s.group(1)
    for rec in out.values():
        while rec["lines"] and not rec["lines"][-1].strip():
            rec["lines"].pop()
    return {k: (r["ability"], r["skill"] or "unknown", r["lines"]) for k, r in out.items()}


def route_abadmin(blocks, have):
    """Return ({relative path: text}, stale [relative path], free [id], unanswered [(cmd, first line)]).

    Every record is written; the newest capture wins and git keeps the older text. `have` is ab_ids()
    of the files already there: a file that holds an id under another name (the ability or its skill
    was renamed) is stale, so one id never has two files. `free` holds the ids the game answered
    "No such record."; `unanswered` the commands whose id got neither a record nor that line.
    """
    recs = ab_records(blocks)
    files, stale = {}, []
    for ab_id in sorted(recs):
        ability, skill, lines = recs[ab_id]
        name = f"{slug(skill)}_{slug(ability)}_{ab_id}.txt"
        files[os.path.join(AB_DIR, name)] = "\n".join(lines) + "\n"
        if have.get(ab_id) not in (None, name):
            stale.append(os.path.join(AB_DIR, have[ab_id]))
    free, unanswered = [], []
    for b in blocks:
        m = AB_CMD.match(b["cmd"])
        if not m or int(m.group(1)) in recs:
            continue
        if any(l.strip() == AB_NONE for l in b["lines"]):
            free.append(int(m.group(1)))
        else:
            unanswered.append((b["cmd"], next((l for l in b["lines"] if l.strip()), "(no output)")))
    return files, stale, sorted(set(free)), unanswered


def route_artefacts(blocks):
    """Return ({relative path: text}, silent [cmd]) for ARTEFACT POWER LIST OWNED and SHOW <p>."""
    files, silent = {}, []
    for b in blocks:
        cmd, body = b["cmd"], b["lines"]
        if cmd == "artefact power list owned":
            path = os.path.join("kb", "raw", "live", "artefact_power_list_owned.txt")
        elif cmd.startswith("artefact power show "):
            path = os.path.join("kb", "raw", "artefacts", f"{slug(cmd[len('artefact power show '):])}.txt")
        else:
            continue
        if not any(l.strip() for l in body):
            silent.append(cmd)
            continue
        files[path] = f"# {cmd}  ({b['stamp']})\n" + "\n".join(body) + "\n"
    return files, silent


def is_routed(cmd):
    """A command the AB or artefact routes file, so it does not also go to kb/raw/live/other/."""
    return bool(AB_CMD.match(cmd)) or cmd == "artefact power list owned" \
        or cmd.startswith("artefact power show ")


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

    ab_files, ab_stale, ab_free, ab_unanswered = route_abadmin(blocks, ab_ids(os.path.join(ROOT, AB_DIR)))
    art_files, art_silent = route_artefacts(blocks)
    for rel, body in list(ab_files.items()) + list(art_files.items()):
        write(os.path.join(ROOT, rel), body, args.dry_run)
    for rel in ab_stale:
        if not args.dry_run and os.path.exists(os.path.join(ROOT, rel)):
            os.remove(os.path.join(ROOT, rel))
    silent += [(cmd, "(no output)") for cmd in art_silent]

    for b in blocks:
        cmd, body = b["cmd"], b["lines"]
        if cmd.startswith("whatcures ") or cmd.startswith("affliction show ") or is_routed(cmd):
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
    if ab_files or ab_free or ab_unanswered:
        print(f"  ABADMIN SHOW: {len(ab_files)} record(s) -> kb/raw/abadmin/; {len(ab_free)} id(s) the game "
              f"has no record for; {len(ab_stale)} old file(s) of a renamed ability removed")
        if ab_unanswered:
            again = " | ".join(cmd for cmd, _ in ab_unanswered)
            print(f"  {len(ab_unanswered)} id(s) got no answer. Ask again: kbcapture {again}")
            for cmd, first in ab_unanswered[:10]:
                print(f"    {cmd:40} {first[:90]}")
    if art_files:
        print(f"  ARTEFACT POWER: {len(art_files)} file(s) -> kb/raw/live/, kb/raw/artefacts/")
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
    if ab_files:
        subprocess.run([sys.executable, "-I", os.path.join(ROOT, "tools", "kb_abadmin.py")], check=False)


if __name__ == "__main__":
    main()
