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
    the wiki pages do not cover. The game's record wins (CLAUDE.md); the wiki page stays as it is;
  * kb/classes/battlerage.md -- every record with a `Skill specialisation: br_<class>` line, by class:
    rage, cooldown, the denizen affliction it gives or the two it uses, and its own text.

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

    python tools/kb_abadmin.py           # write the three files
    python tools/kb_abadmin.py --check   # exit 1 if any of them is out of date
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
OUT_BR = os.path.join(ROOT, "kb", "classes", "battlerage.md")
OUT_SHIELD = os.path.join(ROOT, "kb", "classes", "shield.md")

# An empty slot ("Ability:  (Record #3293)") has no name and no skill: it is kept, not compared.
HEAD = re.compile(r"^Ability: (.*?) ?\(Record #(\d+)\)\s*$")
MAPS = re.compile(r"^Maps to record (\d+) \((.+)\)\.?\s*$")
ALIAS = re.compile(r"^The ability name (.+?) is mapped to this ability\.?\s*$")  # "CONCUSSION BOMB" too
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
# Up to two words and "balance" ("humour balance", "hydra head balance"), else one word: a wiki cost
# can run on into other text ("4.00 seconds of equilibrium symbol=Two isosceles triangles").
SECONDS = re.compile(r"(\d+(?:\.\d+)?)\s*seconds?(?:\s+of\s+((?:[A-Za-z]+\s+){0,2}balance\b|[A-Za-z]+))?", re.I)


def clock(text):
    """'1.00 seconds of equilibrium' -> (1.0, 'equilibrium'); '41.00 seconds' -> (41.0, 'cooldown');
    'Equilibrium' -> (None, 'equilibrium'); '' -> (None, None)."""
    return (clocks(text) or [(None, ((text or "").strip().lower() or None))])[0]


def clocks(text):
    """Every (seconds, clock) in a cost text: a wiki cost can name one per sub-command
    ("TRACK: 4.50 seconds of equilibrium PURSUE: 1.00 seconds of equilibrium")."""
    return [(float(m.group(1)), (m.group(2) or "cooldown").strip().lower())
            for m in SECONDS.finditer((text or "").strip())]


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
    """The game writes "none" where the wiki leaves the target empty: both are no target. The wiki's
    template residue goes ("Self unique=Yes")."""
    t = re.sub(r"\s*\bunique=\S*", "", (t or "").lower())
    t = re.sub(r"\s+", " ", t.strip()).rstrip(".")
    return "" if t == "none" else t


BARE_CLOCK = re.compile(r"(?:[a-z]+ ){0,2}balance|equilibrium")


def bare_clock(text):
    """The clock of a cost with no number: 'Equilibrium' -> 'equilibrium'. Other text (a mana cost,
    "Balance cost varies based on weapon speed") names no clock -> None."""
    t = re.sub(r"\s+", " ", (text or "").strip().lower())
    return t if BARE_CLOCK.fullmatch(t) else None


def cost_differs(game, wiki):
    """True only when both sides state a cost and a cost of the game's is not among the wiki's (the game
    can name two: "2.50 seconds of equilibrium and 20.00 seconds of voice balance"). A side that states
    only a clock ("Equilibrium") differs only in the clock."""
    gall, wall = clocks(game), clocks(wiki)
    if gall and wall:
        return any(c not in wall for c in gall)
    gk = gall[0][1] if gall else bare_clock(game)
    wk = wall[0][1] if wall else bare_clock(wiki)
    return bool(gk and wk and gk != wk)


def compare(recs, wiki):
    """(diffs, unlisted, uncovered): rows where the game and the wiki differ, records of a wiki skill
    that the wiki does not list, and {skill: [ids]} for the skills the wiki does not cover.
    A pointer record is skipped: the record it maps to is compared. So is an empty slot (no name)."""
    wiki_skills = {s for s, _ in wiki}
    diffs, unlisted, uncovered = [], [], {}
    for r in recs:
        if "maps_to" in r or not r["ability"]:
            continue
        skill = r.get("skill", "")
        if skill.lower() not in wiki_skills:
            uncovered.setdefault(skill or "unknown", []).append(r["id"])
            continue
        w = wiki.get((skill.lower(), r["ability"].lower()))
        if w is None:
            unlisted.append(r)
            continue
        # A side that states nothing is a gap, not a difference: only values both sides state are compared.
        notes = []
        if cost_differs(r.get("cooldown"), w.get("cooldown")):
            # The record can contradict itself: FREEZE's Cooldown line says 2.20 s, its Extra info
            # "Targetted cooldown: 3.00 seconds of equilibrium", which is the wiki's.
            extra = clocks(" ".join(r.get("extra", [])))
            notes.append("cost, but its Extra info gives the wiki's"
                         if any(c in extra for c in clocks(w.get("cooldown"))) else "cost")
        gt, wt = norm_target(r.get("target")), norm_target(w.get("target"))
        if gt and wt and gt != wt:
            notes.append("target")
        if notes:
            diffs.append((r, w, notes))
    return diffs, unlisted, uncovered


def cell(s):
    return (s or "").replace("|", "/") or "--"


DEFAULT_FLAGS = (0, 0, "No", "No")  # arms, legs, entangled, paralysed


def flags(r):
    return (r.get("arms"), r.get("legs"), r.get("entangled"), r.get("paralysed"))


def render_flags(recs):
    """How often a record with no Pre checks line carries the default flags: on such a record a flag is
    not evidence of what the game checks (kb/CONFLICTS.md #82)."""
    named = [r for r in recs if r["ability"] and "maps_to" not in r]
    filled = [r for r in named if r.get("prechecks")]
    empty = [r for r in named if not r.get("prechecks")]
    dflt = sum(1 for r in empty if flags(r) == DEFAULT_FLAGS)
    dflt_filled = sum(1 for r in filled if flags(r) == DEFAULT_FLAGS)
    para = sum(1 for r in filled if r.get("paralysed") == "Yes")
    para_empty = sum(1 for r in empty if r.get("paralysed") == "Yes")
    return [
        "## Pre checks and the flags",
        "",
        f"Of the {len(named)} named records that are not pointers, {len(filled)} have a `Pre checks:` line with a",
        f"value (\"balance, equilibrium, and prone\" and the like) and {len(empty)} do not. Of those {len(empty)},",
        f"{dflt} show the same flags: `Requires arms: 0`, `Requires legs: 0`, `Useable entangled: No`, `Useable",
        f"paralysed: No`, and {para_empty} say `Useable paralysed: Yes`. Of the {len(filled)} with a value, {dflt_filled} show",
        f"that set and {para} say `Useable paralysed: Yes`. So on a record with no Pre checks value, the flags look like",
        "defaults, not like the checks the game makes. FITNESS is such a record: it needs equilibrium as well as",
        "balance (CONFIRMED live) and fired under paralysis in our logs, but its record has no Pre checks value and",
        "says `Useable paralysed: No` (`kb/afflictions/class-cures.md`, \"The game's records\";",
        "`kb/CONFLICTS.md` #82). Check a flag against a log before code reads it.",
        "",
    ] + render_aggression(empty, filled) + render_limbs(named)


AGGRESSION = ("non-aggressive", "aggressive (blocked by shield/prismatic)", "aggressive (bypasses shield/prismatic)")


def render_aggression(empty, filled):
    """The `Aggression type` field has a default too: non-aggressive. DOUBLESTAB says it, and it is an attack on a
    player. The two aggressive values are statements."""
    def count(rs):
        return [sum(1 for r in rs if r.get("aggression") == a) for a in AGGRESSION]
    e, f = count(empty), count(filled)
    rows = ["| %s | %d | %d |" % (a, e[i], f[i]) for i, a in enumerate(AGGRESSION)]
    other = len(empty) + len(filled) - sum(e) - sum(f)
    out = [
        "### The `Aggression type` field",
        "",
        "| Aggression type | No Pre checks value | A Pre checks value |",
        "|---|---|---|",
    ] + rows + [""]
    if other:
        out += [f"{other} records have no `Aggression type` line, or another value.", ""]
    return out + [
        "`non-aggressive` is a default too. Subterfuge DOUBLESTAB, FLAY and PINSHOT and Venom BITE say it, and",
        "each is an attack on a player. So `non-aggressive` is no evidence that a shield lets an ability through.",
        "A record with a Pre checks value can say it too: Psionics EXCISE (2725), a kill on a player, does, and",
        "no log we hold shows an EXCISE. The two `aggressive` values are statements. Hypnosis IMPULSE (3251) says",
        "`aggressive (bypasses shield/prismatic)`, which the simulator does not follow yet (`kb/CONFLICTS.md` #83).",
        "The shield breakers say it as well (Bladedance PUNCTUATE 3158, Elementalism METEORITE 3273, Memorium",
        "FISSURE 2863), so `bypasses` means the ability reaches a shielded target. Per class: `shield.md`.",
        "",
    ]


def render_limbs(named, classes=None):
    """`Requires arms: 0` is a default as well: no Monk, Serpent or Blademaster record states an arm."""
    classes = class_skills() if classes is None else classes
    values = sorted({r.get("arms") for r in named if r.get("arms") is not None})
    rows = []
    for v in values:
        e = sum(1 for r in named if r.get("arms") == v and not r.get("prechecks"))
        f = sum(1 for r in named if r.get("arms") == v and r.get("prechecks"))
        rows.append(f"| {v} | {e} | {f} |")
    skill_of = {}
    for r in named:
        skill_of.setdefault(r["skill"], []).append(r)
    per = []
    for cls in sorted(classes):
        rs = [r for s in classes[cls] for r in skill_of.get(s, [])]
        armed = sum(1 for r in rs if (r.get("arms") or 0) >= 1)
        per.append((cls, armed, len(rs)))
    stated = ", ".join(f"{c} {a} of {n}" for c, a, n in sorted(per, key=lambda x: (-x[1], x[0])) if a)
    none = ", ".join(c for c, a, n in per if not a)
    return [
        "### The `Requires arms` field",
        "",
        "| Requires arms | No Pre checks value | A Pre checks value |",
        "|---|---|---|",
    ] + rows + [
        "",
        "`Requires arms: 0` is a default too. The records of these classes state no arm at all, although their",
        f"attacks use arms: {none}. The records that state one or two arms, per class: {stated}.",
        "What `1` means (one arm that works, or one arm free) is open, and no log we hold shows an ability refused",
        "for a broken arm. So a stated arm is a candidate for an arm-break plan (Psion Weaving and Emulation, Pariah",
        "Memorium and Pestilence), not a fact the code can use.",
        "",
    ]


def render_md(recs, diffs, unlisted, uncovered):
    pointers = sum(1 for r in recs if "maps_to" in r)
    empty = [r["id"] for r in recs if not r["ability"]]
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
        "Only a value that both sides state is compared. An empty wiki cell, or a game cost with no number",
        "(\"Equilibrium\"), is a gap, not a difference; such a cost differs only when its clock does. A wiki cost",
        "that names one cost per sub-command agrees when one of them is the game's. A record's Extra info can",
        "name a cost per mode that its Cooldown line does not (FREEZE: Cooldown 2.20 s, \"Targetted cooldown:",
        "3.00 seconds\"); where that is the wiki's cost, the row says so, and which one the game spends is open.",
        "",
        f"Records: {len(recs)} ({pointers} of them pointers to another record"
        + (f"; {len(empty)} empty slots with no name or skill, ids {', '.join(map(str, empty))}" if empty else "")
        + "). Differ from the wiki: "
        f"{len(diffs)}. Not listed on the wiki page of their skill: {len(unlisted)}. "
        f"Skills the wiki pages do not cover: {len(uncovered)}.",
        "",
    ]
    out += render_flags(recs)
    out += [
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


GIVES = re.compile(r"^Gives denizen affliction: (.+?)\.?\s*$", re.I)
USES = re.compile(r"^Uses denizen afflictions: (.+?)\.?\s*$", re.I)
RAGE = re.compile(r"^(\d+) rage$", re.I)


def battlerage(recs):
    """{specialisation: [record, ...]} for each record whose Skill specialisation starts "br_".
    A record also gets "gives", "uses" (from its Extra info) and "rage" (an int, or None)."""
    out = {}
    for r in recs:
        spec = r.get("specialisation") or ""
        if not spec.startswith("br_"):
            continue
        r = dict(r)
        extra = r.get("extra", [])
        r["gives"] = next((m.group(1) for m in map(GIVES.match, extra) if m), "")
        r["uses"] = next((m.group(1) for m in map(USES.match, extra) if m), "")
        m = RAGE.match(r.get("resource") or "")
        r["rage"] = int(m.group(1)) if m else None
        out.setdefault(spec, []).append(r)
    return out


def render_battlerage(recs):
    by = battlerage(recs)
    n = sum(len(v) for v in by.values())
    gives = sum(1 for v in by.values() for r in v if r["gives"])
    uses = sum(1 for v in by.values() for r in v if r["uses"])
    out = [
        "# Battlerage, from the game's records",
        "",
        "GENERATED by `tools/kb_abadmin.py` from `kb/raw/abadmin/` (the game's `ABADMIN SHOW <n>`). Do not edit:",
        "re-run the tool.",
        "",
        f"Every record with a `Skill specialisation: br_<class>` line: {n} records, {len(by)} classes. {gives} give a",
        f"denizen affliction and {uses} use one (their Extra info: \"Gives denizen affliction\", \"Uses denizen",
        "afflictions\"). The rage and the cooldown are the record's own. A record states no duration for the",
        "affliction it gives and no size for the bonus of one it uses. The text column is the record's Abfile text.",
        "It says whether an ability needs the affliction (\"providing\", \"Requires\") or only does more with it",
        "(\"increased damage\"); some say neither. The 17-rage abilities break a denizen's shield and state no",
        "cooldown.",
        "",
        "Which of these the basher sends, and what it leaves out: `.claude/projects/basher/battlerage-pve.md`,",
        "\"The game's battlerage records\".",
    ]
    for spec in sorted(by):
        name = spec[3:].replace("_", " ").title()
        out += ["", f"## {name} (`{spec}`)", "",
                "| ID | Ability | Syntax | Rage | Cooldown | Target | Gives | Uses | Text |",
                "|---|---|---|---|---|---|---|---|---|"]
        rows = sorted(by[spec], key=lambda r: (r["rage"] if r["rage"] is not None else 999, r["ability"].lower()))
        for r in rows:
            if "maps_to" in r:
                out.append(f"| {r['id']} | {cell(r['ability'])} | maps to record {r['maps_to']} ({cell(r['maps_name'])}) "
                           "| | | | | | |")
                continue
            text = re.sub(r"\s+", " ", r.get("abfile") or "").strip()
            out.append(f"| {r['id']} | {cell(r['ability'])} | {cell(' / '.join(r.get('syntax', [])))} | "
                       f"{r['rage'] if r['rage'] is not None else cell(r.get('resource'))} | {cell(r.get('cooldown'))} | "
                       f"{cell(r.get('target'))} | {cell(r['gives'])} | {cell(r['uses'])} | {cell(text)} |")
    return "\n".join(out) + "\n"


BLOCKED, BYPASSES = AGGRESSION[1], AGGRESSION[2]


def class_skills():
    """{class: [skill, ...]} from tools/kb_wiki_skills.py, the one list of each class's skills."""
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import kb_wiki_skills
    return kb_wiki_skills.CLASSES


def render_shield(recs, classes=None):
    """Per class and skill: the abilities whose record says a shield blocks them, and the ones it says go through."""
    classes = class_skills() if classes is None else classes
    named = [r for r in recs if r["ability"] and "maps_to" not in r]
    by_skill = {}
    for r in named:
        by_skill.setdefault(r["skill"], []).append(r)

    def names(rs, value):
        return ", ".join(f"{r['ability']} {r['id']}" for r in sorted(rs, key=lambda r: r["id"]) if r.get("aggression") == value)

    def row(skill):
        rs = by_skill.get(skill, [])
        silent = sum(1 for r in rs if r.get("aggression") not in (BLOCKED, BYPASSES))
        return f"| {skill} | {cell(names(rs, BYPASSES))} | {cell(names(rs, BLOCKED))} | {silent} of {len(rs)} |"

    stated = [r for r in named if r.get("aggression") in (BLOCKED, BYPASSES)]
    n_blocked = sum(1 for r in stated if r["aggression"] == BLOCKED)
    n_bypass = sum(1 for r in stated if r["aggression"] == BYPASSES)
    out = [
        "# Shields, from the game's records",
        "",
        "GENERATED by `tools/kb_abadmin.py` from `kb/raw/abadmin/` (the game's `ABADMIN SHOW <n>`). Do not edit:",
        "re-run the tool.",
        "",
        "A record's `Aggression type` is `aggressive (blocked by shield/prismatic)`, `aggressive (bypasses",
        "shield/prismatic)` or `non-aggressive`. `non-aggressive` is also the default: Subterfuge DOUBLESTAB (1235),",
        "an attack on a player, says it (`abadmin-vs-wiki.md`, \"The Aggression type field\"). So only the two",
        "`aggressive` values say anything about a shield.",
        "",
        f"{n_blocked} records say a shield blocks them, and {n_bypass} say they go through. The shield breakers are",
        "in the second group (PUNCTUATE 3158, METEORITE 3273, FISSURE 2863): `bypasses` means the ability reaches a",
        "shielded target, and a breaker then breaks the shield. The last column counts the records of the skill",
        "that say neither, so the records are silent on them.",
        "",
        "**A record is the game's data, not proof of what it enforces** (`kb/CONFLICTS.md` #82). No log we hold shows",
        "an attack of a `bypasses` record that is not a breaker landing through a shield, so code reads this list",
        "only after a log confirms the row it needs (#83 is IMPULSE). `Useable on: none` is a default too: IMPULSE",
        "says it, and it targets a player.",
    ]
    seen = set()
    for cls in sorted(classes):
        skills = classes[cls]
        seen.update(skills)
        out += ["", f"## {cls}", "",
                "| Skill | Bypasses a shield | Blocked by a shield | Records that say neither |",
                "|---|---|---|---|"] + [row(s) for s in skills]
    other = sorted(s for s in by_skill if s not in seen and any(r.get("aggression") in (BLOCKED, BYPASSES)
                                                                 for r in by_skill[s]))
    if other:
        out += ["", "## Skills of no class above", "",
                "Racial, general or Lord skills, and skills the wiki pages do not list under a class.", "",
                "| Skill | Bypasses a shield | Blocked by a shield | Records that say neither |",
                "|---|---|---|---|"] + [row(s) for s in other]
    return "\n".join(out) + "\n"


def render_json(recs):
    rows = [{k: v for k, v in r.items() if k != "abfile"} for r in recs]
    return json.dumps({"source": "kb/raw/abadmin/ (ABADMIN SHOW)", "count": len(rows), "abilities": rows},
                      indent=1, ensure_ascii=False, sort_keys=True) + "\n"


def build(ab_dir=AB_DIR, wiki_path=WIKI):
    recs = load_records(ab_dir)
    diffs, unlisted, uncovered = compare(recs, wiki_index(wiki_path))
    return (render_json(recs), render_md(recs, diffs, unlisted, uncovered), render_battlerage(recs),
            render_shield(recs))


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--check", action="store_true", help="exit 1 if a generated file is out of date")
    args = ap.parse_args()
    js, md, br, sh = build()
    stale = []
    for path, text in ((OUT_JSON, js), (OUT_MD, md), (OUT_BR, br), (OUT_SHIELD, sh)):
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
