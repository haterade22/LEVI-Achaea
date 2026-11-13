#!/usr/bin/env python3
"""Turn the game's ABADMIN SHOW records (kb/raw/abadmin/*.txt) into kb/classes/abadmin.json + abadmin-vs-wiki.md.

`kbcapture abilities` (Mudlet, misc_scripts/025) asks `ABADMIN SHOW <n>` for every id, and
tools/kb_capture_import.py files each answer as kb/raw/abadmin/<skill>_<ability>_<id>.txt. This tool
reads every file there and writes:

  * kb/classes/abadmin.json -- one entry per id: ability, skill, skillpoints, blurb, syntax, target,
    range, aggression, the arms and legs it needs, whether it works entangled or paralysed, cooldown
    (text, seconds, and the clock it spends), resource, drain, specialisation, the record a pointer
    record maps to, and the other names that map to it. The ability's text (Abfile) stays in the raw
    file, which `file` names;
  * kb/classes/abadmin-vs-wiki.md -- where the game's record and the wiki's (kb/classes/abilities.json)
    differ in cost or target, the abilities of a wiki skill that the wiki does not list, and the skills
    the wiki pages do not cover. The game's record wins (CLAUDE.md); the wiki page stays as it is.

The record layout (the first live run, 2026-11-13):
    Ability: Obliviate (Record #2115)
    Associated skill: Attainment
    Skillpoints required: 38999
    Blurb: ...
    Syntax: OBLIVIATE <target>        (more syntax lines can follow, with no label)
    Extra info: ...
    Abfile:
    <the ability's text, any number of lines>
    Useable on: denizens
    Pre checks:
    Ability range: none / Aggression type / Requires arms / Requires legs / Useable entangled /
    Useable paralysed / Cooldown / Resource / Drain / Skill specialisation
    The ability name X is mapped to this ability.   (zero or more)
A pointer record holds only "Ability", "Associated skill" and "Maps to record 785 (FIST).".

An ABADMIN cost is the BASE cost. Our own equilibrium is that base times ataxia_eqFactor (misc_scripts/033:
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
AB_DIR = os.path.join(ROOT, "kb", "raw", "abadmin")
WIKI = os.path.join(ROOT, "kb", "classes", "abilities.json")
OUT_JSON = os.path.join(ROOT, "kb", "classes", "abadmin.json")
OUT_MD = os.path.join(ROOT, "kb", "classes", "abadmin-vs-wiki.md")

HEAD = re.compile(r"^Ability: (.+) \(Record #(\d+)\)\s*$")
MAPS = re.compile(r"^Maps to record (\d+) \((.+)\)\.?\s*$")
ALIAS = re.compile(r"^The ability name (\S+) is mapped to this ability\.?\s*$")
# The game's label -> the JSON key.
FIELDS = {
    "Associated skill": "skill", "Skillpoints required": "skillpoints", "Blurb": "blurb",
    "Syntax": "syntax", "Extra info": "extra", "Abfile": "abfile", "Useable on": "target",
    "Pre checks": "prechecks", "Ability range": "range", "Aggression type": "aggression",
    "Requires arms": "arms", "Requires legs": "legs", "Useable entangled": "entangled",
    "Useable paralysed": "paralysed", "Cooldown": "cooldown", "Resource": "resource", "Drain": "drain",
    "Skill specialisation": "specialisation",
}
FIELD = re.compile(r"^(" + "|".join(re.escape(k) for k in FIELDS) + r"):(?: (.*))?$")
LISTS = {"syntax", "extra", "prechecks"}  # a line with no label continues these
# The labels that come after the Abfile text. Only one of these ends it, so a "Note: ..." line in
# the text stays text.
AFTER_TEXT = {"target", "prechecks", "range", "aggression", "arms", "legs", "entangled", "paralysed",
              "cooldown", "resource", "drain", "specialisation"}
INTS = {"skillpoints", "arms", "legs"}
# One word, or a word and "balance" ("humour balance"): a wiki cost can run on into other text
# ("4.00 seconds of equilibrium symbol=Two isosceles triangles").
SECONDS = re.compile(r"(\d+(?:\.\d+)?)\s*seconds?(?:\s+of\s+([A-Za-z]+(?:\s+balance)?))?", re.I)


def clock(text):
    """'1.00 seconds of equilibrium' -> (1.0, 'equilibrium'); '41.00 seconds' -> (41.0, 'cooldown');
    'Equilibrium' -> (None, 'equilibrium'); '' -> (None, None)."""
    text = (text or "").strip()
    m = SECONDS.search(text)
    if m:
        return float(m.group(1)), (m.group(2) or "cooldown").strip().lower()
    return None, (text.lower() or None)


def parse_record(text):
    """One ABADMIN SHOW record -> dict, or None if the text holds no record."""
    lines = text.splitlines()
    start = next((i for i, l in enumerate(lines) if HEAD.match(l)), None)
    if start is None:
        return None
    m = HEAD.match(lines[start])
    rec = {"id": int(m.group(2)), "ability": m.group(1).strip()}
    key, abfile = None, []
    for line in lines[start + 1:]:
        f = FIELD.match(line)
        fkey = FIELDS[f.group(1)] if f else None
        if key == "abfile" and fkey not in AFTER_TEXT:
            abfile.append(line)
            continue
        if f:
            key, val = fkey, (f.group(2) or "").strip()
            if key in LISTS:
                rec.setdefault(key, [])
                if val:
                    rec[key].append(val)
            elif key != "abfile":
                rec[key] = int(val) if key in INTS and val.isdigit() else val
            continue
        mm = MAPS.match(line)
        if mm:
            rec["maps_to"], rec["maps_name"] = int(mm.group(1)), mm.group(2)
            continue
        al = ALIAS.match(line)
        if al:
            rec.setdefault("aliases", []).append(al.group(1))
            continue
        if not line.strip():
            continue
        if key in LISTS:
            rec[key].append(line.strip())
        else:
            rec.setdefault("other", []).append(line.strip())
    rec["abfile"] = "\n".join(abfile).strip()
    rec["seconds"], rec["clock"] = clock(rec.get("cooldown"))
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
    """The game writes "none" where the wiki leaves the target empty: both are no target."""
    t = re.sub(r"\s+", " ", (t or "").strip().lower()).rstrip(".")
    return "" if t == "none" else t


def compare(recs, wiki):
    """(diffs, unlisted, uncovered): rows where the game and the wiki differ, records of a wiki skill
    that the wiki does not list, and {skill: [ids]} for the skills the wiki does not cover.
    A pointer record is skipped: the record it maps to is compared."""
    wiki_skills = {s for s, _ in wiki}
    diffs, unlisted, uncovered = [], [], {}
    for r in recs:
        if "maps_to" in r:
            continue
        skill = r.get("skill", "")
        if skill.lower() not in wiki_skills:
            uncovered.setdefault(skill or "unknown", []).append(r["id"])
            continue
        w = wiki.get((skill.lower(), r["ability"].lower()))
        if w is None:
            unlisted.append(r)
            continue
        notes = []
        ws, wk = clock(w.get("cooldown"))
        if (r["seconds"] is not None or ws is not None) and (r["seconds"], r["clock"]) != (ws, wk):
            notes.append("cost")
        if norm_target(r.get("target")) != norm_target(w.get("target")):
            notes.append("target")
        if notes:
            diffs.append((r, w, notes))
    return diffs, unlisted, uncovered


def cell(s):
    return (s or "").replace("|", "/") or "--"


def render_md(recs, diffs, unlisted, uncovered):
    pointers = sum(1 for r in recs if "maps_to" in r)
    out = [
        "# ABADMIN SHOW records against the wiki",
        "",
        "GENERATED by `tools/kb_abadmin.py` from `kb/raw/abadmin/` (the game's `ABADMIN SHOW <n>`, captured by",
        "`kbcapture abilities`) and `kb/classes/abilities.json` (the wiki). Do not edit: re-run the tool.",
        "",
        "The game's record wins where the two differ (CLAUDE.md). Every cost here is the BASE cost. Our own",
        "equilibrium is that base times `ataxia_eqFactor` (`misc_scripts/033_Artefacts.lua`: the Aldar",
        "Diadem, x0.85, and Rain), as `kb/mechanics/balance-and-queueing.md` (\"Our speed factors\") says.",
        "",
        f"Records: {len(recs)} ({pointers} of them pointers to another record). Differ from the wiki: "
        f"{len(diffs)}. Not listed on the wiki page of their skill: {len(unlisted)}. "
        f"Skills the wiki pages do not cover: {len(uncovered)}.",
        "",
        "## Where the game and the wiki differ",
        "",
    ]
    if diffs:
        out += ["| ID | Skill | Ability | Game cost | Wiki cost | Game target | Wiki target | Differs |",
                "|---|---|---|---|---|---|---|---|"]
        for r, w, notes in diffs:
            out.append(f"| {r['id']} | {cell(r.get('skill'))} | {cell(r['ability'])} | {cell(r.get('cooldown'))} | "
                       f"{cell(w.get('cooldown'))} | {cell(r.get('target'))} | {cell(w.get('target'))} | "
                       f"{', '.join(notes)} |")
    else:
        out.append("None.")
    out += ["", "## Not listed on the wiki page of their skill", ""]
    if unlisted:
        out += ["| ID | Skill | Ability | Cost | Target | File |", "|---|---|---|---|---|---|"]
        for r in unlisted:
            out.append(f"| {r['id']} | {cell(r.get('skill'))} | {cell(r['ability'])} | {cell(r.get('cooldown'))} | "
                       f"{cell(r.get('target'))} | `kb/raw/abadmin/{r['file']}` |")
    else:
        out.append("None.")
    out += ["", "## Skills the wiki pages do not cover", "",
            "`kb/classes/abilities.json` holds the class skills only. These records are in `abadmin.json`.", ""]
    if uncovered:
        out += ["| Skill | Records | IDs |", "|---|---|---|"]
        for skill in sorted(uncovered, key=str.lower):
            ids = uncovered[skill]
            out.append(f"| {cell(skill)} | {len(ids)} | {min(ids)}-{max(ids)} |")
    else:
        out.append("None.")
    return "\n".join(out) + "\n"


def render_json(recs):
    rows = [{k: v for k, v in r.items() if k != "abfile"} for r in recs]
    return json.dumps({"source": "kb/raw/abadmin/ (ABADMIN SHOW)", "count": len(rows), "abilities": rows},
                      indent=1, ensure_ascii=False, sort_keys=True) + "\n"


def build(ab_dir=AB_DIR, wiki_path=WIKI):
    recs = load_records(ab_dir)
    diffs, unlisted, uncovered = compare(recs, wiki_index(wiki_path))
    return render_json(recs), render_md(recs, diffs, unlisted, uncovered)


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
