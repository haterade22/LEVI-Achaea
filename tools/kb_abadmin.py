#!/usr/bin/env python3
"""Turn the game's ABADMIN records (kb/raw/ab/*.txt) into kb/classes/abadmin.json + abadmin-vs-wiki.md.

`kbcapture abilities` (Mudlet, misc_scripts/025) asks `ABADMIN SHOW <n>` for every id, and
tools/kb_capture_import.py files each answer as kb/raw/ab/<skill>_<ability>_<id>.txt. This tool reads
every file there and writes:

  * kb/classes/abadmin.json -- one entry per id: ability, skill, known, syntax, target, cooldown
    (text, seconds, and the clock it spends), resource, extra information and the details text;
  * kb/classes/abadmin-vs-wiki.md -- where the game's record and the wiki's (kb/classes/abilities.json)
    differ in cost or target. The game's record wins (CLAUDE.md); the wiki page stays as it is.

An AB cost is the BASE cost. Our own equilibrium is that base times ataxia_eqFactor (misc_scripts/033:
the Aldar Diadem, x0.85, and Rain); kb/mechanics/balance-and-queueing.md, "Our speed factors".

abilities.json is NOT changed here: its cooldowns feed kb_timing.py -> clocks.json -> kb_rules.py and
kb_sim.py, which CI checks.

    python tools/kb_abadmin.py           # write both files
    python tools/kb_abadmin.py --check   # exit 1 if either file is out of date
"""
import argparse
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AB_DIR = os.path.join(ROOT, "kb", "raw", "ab")
WIKI = os.path.join(ROOT, "kb", "classes", "abilities.json")
OUT_JSON = os.path.join(ROOT, "kb", "classes", "abadmin.json")
OUT_MD = os.path.join(ROOT, "kb", "classes", "abadmin-vs-wiki.md")

HEAD = re.compile(r"^(.+?) \((.+?)\)\s+ABADMIN ID:\s*(\d+)\s*(?:Known:\s*(.+?))?\s*$")
FIELD = re.compile(r"^(Syntax|Works on/against|Cooldown|Resource|Extra Information|Required):\s*(.*)$")
RULE = re.compile(r"^-{20,}\s*$")
SECONDS = re.compile(r"(\d+(?:\.\d+)?)\s*seconds?(?:\s+of\s+(balance|equilibrium))?", re.I)


def clock(text):
    """'1.00 seconds of equilibrium' -> (1.0, 'equilibrium'); '41.00 seconds' -> (41.0, 'cooldown')."""
    m = SECONDS.search(text or "")
    if not m:
        return None, None
    return float(m.group(1)), (m.group(2) or "cooldown").lower()


def parse_record(text):
    """One ABADMIN record -> dict, or None if the text holds no ABADMIN header."""
    lines = text.splitlines()
    rec, i = None, 0
    while i < len(lines):
        m = HEAD.match(lines[i])
        i += 1
        if m:
            rec = {"id": int(m.group(3)), "ability": m.group(1).strip(), "skill": m.group(2).strip(),
                   "known": (m.group(4) or "").strip()}
            break
    if rec is None:
        return None
    details, in_details = [], False
    for line in lines[i:]:
        if RULE.match(line):
            if in_details:
                break
            continue
        if in_details:
            details.append(line.strip())
            continue
        if line.startswith("Details:"):
            in_details = True
            rest = line[len("Details:"):].strip()
            if rest:
                details.append(rest)
            continue
        f = FIELD.match(line)
        if f:
            key = {"Works on/against": "target", "Extra Information": "extra"}.get(f.group(1), f.group(1).lower())
            rec[key] = f.group(2).strip()
    secs, kind = clock(rec.get("cooldown"))
    rec["seconds"], rec["clock"] = secs, kind
    rec["details"] = " ".join(d for d in details if d).strip()
    return rec


def load_records(ab_dir=AB_DIR):
    out = {}
    for p in sorted(glob.glob(os.path.join(ab_dir, "*.txt"))):
        with open(p, encoding="utf-8", errors="replace") as fh:
            rec = parse_record(fh.read())
        if rec:
            rec["file"] = os.path.basename(p)
            out[rec["id"]] = rec  # a second file of one id: the later name wins
    return [out[k] for k in sorted(out)]


def wiki_index(path=WIKI):
    """{(skill, ability): entry} from abilities.json; its per-ability `skill` field is the ability name."""
    if not os.path.exists(path):
        return {}
    with open(path, encoding="utf-8") as fh:
        data = json.load(fh)
    idx = {}
    for skill, block in data.items():
        for a in block.get("abilities", []):
            idx[(skill.lower(), (a.get("skill") or "").lower())] = a
    return idx


def norm_target(t):
    return re.sub(r"\s+", " ", (t or "").strip().lower())


def compare(recs, wiki):
    """Rows where the game and the wiki differ, and the records the wiki does not hold."""
    diffs, missing = [], []
    for r in recs:
        w = wiki.get((r["skill"].lower(), r["ability"].lower()))
        if w is None:
            missing.append(r)
            continue
        notes = []
        ws, wk = clock(w.get("cooldown"))
        if (r["seconds"], r["clock"]) != (ws, wk) and (r["seconds"] is not None or ws is not None):
            notes.append("cost")
        if r.get("target") and norm_target(r.get("target")) != norm_target(w.get("target")):
            notes.append("target")
        if notes:
            diffs.append((r, w, notes))
    return diffs, missing


def cell(s):
    return (s or "").replace("|", "/") or "--"


def render_md(recs, diffs, missing):
    out = [
        "# ABADMIN records against the wiki",
        "",
        "GENERATED by `tools/kb_abadmin.py` from `kb/raw/ab/` (the game's `ABADMIN SHOW <n>`, captured by",
        "`kbcapture abilities`) and `kb/classes/abilities.json` (the wiki). Do not edit: re-run the tool.",
        "",
        "The game's record wins where the two differ (CLAUDE.md). Every cost here is the BASE cost. Our own",
        "equilibrium is that base times `ataxia_eqFactor` (`misc_scripts/033_Artefacts.lua`: the Aldar",
        "Diadem, x0.85, and Rain), as `kb/mechanics/balance-and-queueing.md` (\"Our speed factors\") says.",
        "",
        f"Records: {len(recs)}. Differ from the wiki: {len(diffs)}. Not on the wiki: {len(missing)}.",
        "",
        "## Where the game and the wiki differ",
        "",
    ]
    if diffs:
        out += ["| ID | Skill | Ability | Game cost | Wiki cost | Game target | Wiki target | Differs |",
                "|---|---|---|---|---|---|---|---|"]
        for r, w, notes in diffs:
            out.append(f"| {r['id']} | {cell(r['skill'])} | {cell(r['ability'])} | {cell(r.get('cooldown'))} | "
                       f"{cell(w.get('cooldown'))} | {cell(r.get('target'))} | {cell(w.get('target'))} | "
                       f"{', '.join(notes)} |")
    else:
        out.append("None.")
    out += ["", "## Not on the wiki", ""]
    if missing:
        out += ["| ID | Skill | Ability | Cost | Target | File |", "|---|---|---|---|---|---|"]
        for r in missing:
            out.append(f"| {r['id']} | {cell(r['skill'])} | {cell(r['ability'])} | {cell(r.get('cooldown'))} | "
                       f"{cell(r.get('target'))} | `kb/raw/ab/{r['file']}` |")
    else:
        out.append("None.")
    return "\n".join(out) + "\n"


def render_json(recs):
    return json.dumps({"source": "kb/raw/ab/ (ABADMIN SHOW)", "count": len(recs), "abilities": recs},
                      indent=1, ensure_ascii=False, sort_keys=True) + "\n"


def build(ab_dir=AB_DIR, wiki_path=WIKI):
    recs = load_records(ab_dir)
    diffs, missing = compare(recs, wiki_index(wiki_path))
    return render_json(recs), render_md(recs, diffs, missing)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--check", action="store_true", help="exit 1 if a generated file is out of date")
    args = ap.parse_args()
    js, md = build()
    stale = []
    for path, text in ((OUT_JSON, js), (OUT_MD, md)):
        old = None
        if os.path.exists(path):
            with open(path, encoding="utf-8") as fh:
                old = fh.read()
        if old == text:
            continue
        if args.check:
            stale.append(os.path.relpath(path, ROOT))
        else:
            with open(path, "w", encoding="utf-8", newline="\n") as fh:
                fh.write(text)
            print(f"wrote {os.path.relpath(path, ROOT)}")
    if stale:
        print("out of date (run python tools/kb_abadmin.py): " + ", ".join(stale))
        sys.exit(1)


if __name__ == "__main__":
    main()
