#!/usr/bin/env python3
"""Collect every class's skills and abilities from the Achaea wiki into the knowledge base.

The wiki has one page per skill (https://wiki.achaea.com/Alchemy), and every ability on it is a
`{{Skill_detail |skill= |description= |lessons= |syntax= |required= |target= |cooldown= |detail= }}`
block. This tool fetches each page's RAW wikitext (`?action=raw`), keeps it verbatim in
kb/raw/wiki/<Skill>.wiki (the evidence), and generates:

  * kb/classes/abilities.json      -- every ability, keyed by skill, for code and tools
  * kb/classes/<class>.md          -- one readable page per class (GENERATED, do not hand-edit)

Each ability also lists the AFFLICTIONS its text names, matched against the game's own affliction
list (kb/afflictions/afflictions.json), because afflictions are the core of the KB.

Confidence: WIKI. The wiki can lag the game; in-game `AB <skill>` output wins where they differ.

    python tools/kb_wiki_skills.py              # fetch what is missing, then build
    python tools/kb_wiki_skills.py --refresh    # re-fetch every page
    python tools/kb_wiki_skills.py --offline    # build from what is already in kb/raw/wiki/
"""
import argparse
import html
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, "kb", "raw", "wiki")
OUT = os.path.join(ROOT, "kb", "classes")
AFFS = os.path.join(ROOT, "kb", "afflictions", "afflictions.json")
URL = "https://wiki.achaea.com/{}?action=raw"
AGENT = "LEVI-Achaea-KB/1.0 (personal reference; one request a second)"

# wiki.achaea.com/Category:Classes, captured 2026-10-11. Fledgling skills, then the full-member
# skill. A "|" in the table (Formulation | Sublimation) is an either/or, so both are listed.
CLASSES = {
    "Alchemist": ["Alchemy", "Physiology", "Formulation", "Sublimation"],
    "Apostate": ["Evileye", "Necromancy", "Apostasy"],
    "Bard": ["Bladedance", "Composition", "Sagas", "Woe"],
    "Blademaster": ["TwoArts", "Striking", "Shindo"],
    "Depthswalker": ["Aeonics", "Shadowmancy", "Terminus"],
    "Druid": ["Groves", "Metamorphosis", "Reclamation"],
    "Infernal": ["Weaponmastery", "Oppression", "Malignity"],
    "Jester": ["Tarot", "Pranks", "Puppetry"],
    "Magi": ["Elementalism", "Crystalism", "Artificing"],
    "Monk": ["Tekura", "Shikudo", "Kaido", "Telepathy"],
    "Occultist": ["Occultism", "Tarot", "Domination"],
    "Paladin": ["Weaponmastery", "Excision", "Valour"],
    "Pariah": ["Memorium", "Pestilence", "Charnel"],
    "Priest": ["Spirituality", "Devotion", "Zeal"],
    "Psion": ["Weaving", "Psionics", "Emulation"],
    "Runewarden": ["Weaponmastery", "Runelore", "Discipline"],
    "Sentinel": ["Metamorphosis", "Woodlore", "Skirmishing"],
    "Serpent": ["Subterfuge", "Venom", "Hypnosis"],
    "Shaman": ["Spiritlore", "Curses", "Vodun"],
    "Sylvan": ["Propagation", "Groves", "Weatherweaving"],
    "Unnamable": ["Weaponmastery", "Anathema", "Dominion"],
}
# Skill names whose plain page is a disambiguation page, and the page that is the skill.
PAGE = {
    "Anathema": "Anathema (skill)",
    "Devotion": "Devotion (skill)",
    "Venom": "Venom (Skill)",
}
# Shown on the class page next to the skill.
NOTES = {
    ("Bard", "Woe"): "Cyrene citizens only; everyone else takes Sagas",
    ("Bard", "Sagas"): "the full-member skill for Bards outside Cyrene (Cyrene citizens may take Woe)",
    ("Alchemist", "Sublimation"): "alternative to Formulation (uses Hashan's Wellspring)",
    ("Monk", "Shikudo"): "alternative to Tekura (requires transcendent Tekura)",
    ("Apostate", "Evileye"): "Live (Mystor's log, 2026-10-11): DEADEYES takes affliction words, paralysis among them, "
                             "and SICKEN gives MANALEECH first, then slickness once manaleech is up. The paralysis-first "
                             "text below is outdated. See kb/CONFLICTS.md",
    ("Monk", "Telepathy"): "Players (the user and Mystor, 2026-10-11): a mind lock is needed only to reach a target "
                           "OUTSIDE your room and for certain skills such as Radiance (which cannot be used on a "
                           "target in your room) and Sapience (which watches a locked target). The 15 abilities the "
                           "wiki marks with an asterisk need only the target in the room, as the wiki also says, even "
                           "where their text says 'locked'. The wiki puts every unmarked one behind the lock, and most "
                           "of those take no target argument (MIND BLACKOUT, MIND TERROR); which of them work in the "
                           "same room without a lock is open, blackout above all (kb/CONFLICTS.md #7). "
                           "See kb/combat/shikudo.md. Changed 2026-10-23: locks and lock-based abilities treat an "
                           "adjacent room as the same area, so one room across an area border no longer breaks a "
                           "lock or cancels Radiance (kb/changes/2026-10-23_classleads.md)",
}
# The class-lead post of 2026-10-23 changed these skills after the wiki was captured. The note
# points at the curated page, which has the details, the AB data and the code join.
CHANGES_2026_10_23 = "kb/changes/2026-10-23_classleads.md"
for _key, _text in {
    ("Magi", "Crystalism"): "DESTABILISE needs balance AND equilibrium; new OVERLOAD (VIBE DESTABILISE <vibe> "
                            "<target> <affliction>: paralysis, asthma, slickness, anorexia or stupidity)",
    ("Magi", "Elementalism"): "new PEBBLE (CAST PEBBLE AT <target>, earth, 2.30 s eq, 90 mana): breaks one healthy limb",
    ("Psion", "Psionics"): "new PULSE (PSI PULSE <target>, 1.00 s eq): reads how heavily the target bleeds",
    ("Serpent", "Hypnosis"): "SUGGEST and SEAL used off balance take a fixed, unmodifiable equilibrium",
    ("Serpent", "Subterfuge"): "HYPERSIGHT works as a star sigil on an evading Serpent you afflicted or damaged recently; "
                               "the snake's sileris strip is progressive (faster with darkshade, much faster with "
                               "scytherus, at once with both)",
    ("Alchemist", "Physiology"): "tempered MELANCHOLIC caps passive mana regen (level 2 at 2 stacks, 1 at 4, none at 6)",
    ("Alchemist", "Sublimation"): "HALOPHILIC costs 3x reagents and clears vines (one toss, two with a Druid in the area)",
    ("Priest", "Spirituality"): "ANGEL PANIC gives slickness instead of fear on a hellsight target; under HERESY a "
                                "2+ verse prayer forces an extra ablaze tick on ablaze enemies",
    ("Blademaster", "Striking"): "on a broken head, STRIKE EYES also gives hallucinations and TEMPLE also dizziness",
    ("Sentinel", "Woodlore"): "new GRAPPLE (GRAPPLE <direction>, 2.50 s bal): springs your laid trap to pull you "
                              "into the adjacent room",
    ("Jester", "Pranks"): "used SUICIDEMICE return after an arena match; MICE shows each mouse's bomb type",
    ("Occultist", "Domination"): "summoning entities on the Chaos Plane has a different message",
    ("Runewarden", "Weaponmastery"): "DWB EXPEND gives a uniform relapse message; new Two Handed RETALIATE",
    ("Paladin", "Weaponmastery"): "DWB EXPEND gives a uniform relapse message; new Two Handed RETALIATE",
    ("Infernal", "Weaponmastery"): "DWB EXPEND gives a uniform relapse message; Oppression invests can be appended "
                                   "to relevant blunt attacks; new Two Handed RETALIATE",
    ("Infernal", "Oppression"): "new ACCUSATION",
    ("Druid", "Reclamation"): "EMBRACE no longer requires vines",
    ("Druid", "Groves"): "LASTHARVEST removed; VIGOUR and similar drain sunlight only when there is enough to cast",
    ("Sylvan", "Groves"): "LASTHARVEST removed; VIGOUR and similar drain sunlight only when there is enough to cast",
    ("Druid", "Metamorphosis"): "WREATHE adds burning stacks and WYVERN FRENZY can be wreathed; INCINERATE kills "
                                "below 40%, rising with burning stacks to 60%; FLAME must be re-summoned within "
                                "30 s of a morph, or it clears with backlash",
    ("Sentinel", "Metamorphosis"): "FLAME must be re-summoned within 30 s of a morph, or it clears with backlash; "
                                   "WREATHE and INCINERATE changed (wyvern, Druid only)",
    ("Unnamable", "Weaponmastery"): "DWB EXPEND gives a uniform relapse message; new Two Handed RETALIATE",
}.items():
    _note = f"Changed 2026-10-23: {_text} ({CHANGES_2026_10_23})"
    NOTES[_key] = f"{NOTES[_key]}. {_note}" if _key in NOTES else _note
FIELDS = ("skill", "description", "lessons", "syntax", "required", "target", "cooldown", "detail")


def fetch(skill, refresh):
    path = os.path.join(RAW, f"{skill}.wiki")
    if os.path.exists(path) and not refresh:
        return open(path, encoding="utf-8").read(), False
    page = PAGE.get(skill, skill)
    for _ in range(3):  # follow #REDIRECT [[Target]] (TwoArts -> Two Arts, Pestilence -> Pestilence (skill))
        req = urllib.request.Request(URL.format(urllib.parse.quote(page.replace(" ", "_"))),
                                     headers={"User-Agent": AGENT})
        with urllib.request.urlopen(req, timeout=30) as r:
            text = r.read().decode("utf-8", "replace")
        m = re.match(r"\s*#redirect\s*\[\[([^\]]+)\]\]", text, re.I)
        if not m:
            break
        page = m.group(1)
        time.sleep(1.0)
    os.makedirs(RAW, exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)
    return text, True


HTML_TAGS = r"</?(?:br|p|span|div|b|i|u|small|big|code|nowiki|sup|sub|font|center|tt|em|strong)\b[^>]*>"


def clean(value, sep=" "):
    """Wikitext -> plain text. Only REAL html tags are removed: `<target>` and `<direction>` are
    command placeholders in a syntax line, and stripping every <...> deleted them. <br> becomes
    `sep`, so a syntax line keeps its alternative forms apart (`RATTLE <target> / RATTLE ...`)."""
    v = re.sub(r"<br\s*/?>", sep, value, flags=re.I)
    v = v.replace("{{!}}", "|")
    v = re.sub(r"\[\[(?:[^|\]]*\|)?([^\]]*)\]\]", r"\1", v)
    v = re.sub(r"'''?", "", v)
    v = re.sub(HTML_TAGS, " ", v, flags=re.I)
    return re.sub(r"[ \t\r\n]+", " ", html.unescape(v)).strip()


def wikitable(block):
    """A MediaWiki table ({| ... |}) -> a Markdown table. Rows are split on "|-", header cells start
    with "!" and data cells with "|" ("!!" / "||" separate cells on one line); a cell's attributes
    (style="..."|) are dropped. When every row starts with a header cell, the row labels are the
    table's columns (Tekura's belt table runs rank / belt / kata across), so it is transposed."""
    rows, cur = [], []
    for line in block.splitlines()[1:]:
        t = line.strip()
        if t.startswith("|}"):
            break
        if t.startswith("|-"):
            if cur:
                rows.append(cur)
            cur = []
            continue
        if not t or t[0] not in "!|":
            continue
        is_head = t[0] == "!"
        for c in re.split(r"!!|\|\|", t[1:]):
            m = re.match(r"\s*[a-z-]+\s*=[^|\[]*\|(.*)$", c, re.S)    # style="..."|content
            cur.append((is_head, clean(m.group(1) if m else c)))
    if cur:
        rows.append(cur)
    if not rows:
        return ""
    if all(r and r[0][0] for r in rows) and len({len(r) for r in rows}) == 1:
        rows = [list(col) for col in zip(*rows)]                        # transpose
    width = max(len(r) for r in rows)
    lines = []
    for i, r in enumerate(rows):
        cells = [c for _, c in r] + [""] * (width - len(r))
        lines.append("| " + " | ".join(x.replace("|", "\\|") for x in cells) + " |")
        if i == 0:
            lines.append("|" + "---|" * width)
    return "\n".join(lines)


def intro(text):
    """The page's own words before the ability list: its lead paragraphs and any italic note under the
    abilities heading. They carry rules that apply to every ability -- Telepathy's lead says some
    abilities need only the target in the room, and its note says (*) marks them -- and the class
    pages used to drop both, so a "(*)" in a description meant nothing (2026-10-11).
    A ":''This page is about ...''" line above the first heading is a disambiguation hatnote, not
    content, so it is dropped, and notes are read only below that heading. A wiki table in the lead
    becomes a Markdown table paragraph (it used to leak as one line of raw {| ... |} markup)."""
    first = text.find("{{Skill_detail")
    head = text if first < 0 else text[:first]
    lead_end = re.search(r"^=", head, re.M)          # any heading, "=X=" or "==X=="
    lead = head if not lead_end else head[:lead_end.start()]
    tables = []

    def keep_table(m):
        tables.append(wikitable(m.group(0)))
        return "\n\n@@TABLE%d@@\n\n" % (len(tables) - 1)
    lead = re.sub(r"^\{\|.*?^\|\}", keep_table, lead, flags=re.M | re.S)
    lead = re.sub(r"^:+\s*''.*$", "", lead, flags=re.M)                # hatnotes
    lead = re.sub(r"\{\{[^{}]*\}\}", " ", lead)                     # templates
    lead = re.sub(r"\[\[(?:File|Image):[^\]]*\]\]", " ", lead, flags=re.I)
    paras = []
    for p in re.split(r"\n\s*\n", lead):
        m = re.fullmatch(r"\s*@@TABLE(\d+)@@\s*", p)
        paras.append(tables[int(m.group(1))] if m else clean(p))
    below = head[lead_end.start():] if lead_end else ""
    notes = [clean(m) for m in re.findall(r"^:+\s*''+(.+?)(?:''+)?\s*$", below, re.M)]
    return [p for p in paras if p], [n for n in notes if n]


def blocks(text):
    """Every {{Skill_detail ...}} block, brace-balanced (a field may hold {{...}} itself)."""
    out, i = [], 0
    while True:
        i = text.find("{{Skill_detail", i)
        if i < 0:
            return out
        depth, j = 0, i
        while j < len(text):
            if text.startswith("{{", j):
                depth, j = depth + 1, j + 2
            elif text.startswith("}}", j):
                depth, j = depth - 1, j + 2
                if depth == 0:
                    break
            else:
                j += 1
        out.append(text[i + len("{{Skill_detail"):j - 2])
        i = j


def parse(block):
    rec, key = {}, None
    for part in re.split(r"\n\s*\|", "\n" + block):
        m = re.match(r"\s*(\w+)\s*=(.*)", part, re.S)
        if m and m.group(1) in FIELDS:
            key = m.group(1)
            rec[key] = clean(m.group(2), " / " if key == "syntax" else " ")
        elif key:
            rec[key] += " " + clean(part)
    return rec


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--refresh", action="store_true")
    ap.add_argument("--offline", action="store_true")
    args = ap.parse_args()

    affs = set(json.load(open(AFFS))) if os.path.exists(AFFS) else set()
    # Affliction names that are also everyday words ("a silver ring", "bound to", "justice is done")
    # are not tagged: a match on them says nothing. Check the ability text for these by hand.
    affs -= {"silver", "bound", "justice", "horror", "corruption", "revealed", "betrayal", "hatred",
             "condemned", "guilt", "tension", "pressure", "isolation", "penitence", "convergence",
             "inquisition", "enlightenment", "succumbed", "reeling", "cremated", "petrified", "hindered",
             "latched", "diminished", "lovers", "peace", "generosity", "indifference", "sleeping"}
    aff_re = re.compile(r"\b(" + "|".join(sorted(map(re.escape, affs), key=len, reverse=True)) + r")\b", re.I) if affs else None

    skills = sorted({s for ss in CLASSES.values() for s in ss})
    data, missing = {}, []
    for skill in skills:
        try:
            if args.offline:
                path = os.path.join(RAW, f"{skill}.wiki")
                if not os.path.exists(path):
                    missing.append((skill, "not fetched"))
                    continue
                text, fetched = open(path, encoding="utf-8").read(), False
            else:
                text, fetched = fetch(skill, args.refresh)
                if fetched:
                    time.sleep(1.0)
        except Exception as e:  # a missing page or network error: report, keep going
            missing.append((skill, str(e)))
            continue
        abilities = [parse(b) for b in blocks(text)]
        abilities = [a for a in abilities if a.get("skill")]
        if not abilities:
            missing.append((skill, "page has no Skill_detail blocks"))
        for a in abilities:
            found = sorted({m.lower() for m in aff_re.findall(" ".join(a.get(f, "") for f in ("description", "detail")))}) if aff_re else []
            a["afflictions"] = found
        page = PAGE.get(skill, skill).replace(" ", "_")
        lead, notes = intro(text)
        data[skill] = {"source": f"kb/raw/wiki/{skill}.wiki", "url": f"https://wiki.achaea.com/{page}",
                       "intro": lead, "notes": notes, "abilities": abilities}

    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "abilities.json"), "w", encoding="utf-8", newline="\n") as fh:
        json.dump(data, fh, indent=1, sort_keys=True)
        fh.write("\n")

    cell = lambda s: (s or "").replace("|", "\\|")
    # Prose outside a code span: a bare "*" pairs up into italics (the "(*)" marker vanished, and the
    # note explaining it lost its own asterisk) and "<animal>" is read as an HTML tag and dropped.
    # Never applied to the backticked syntax cell, where an escape would show literally.
    md_esc = lambda s: (s or "").replace("*", "\\*").replace("<", "&lt;")
    for cls, ss in CLASSES.items():
        md = [f"# {cls}: skills and abilities", "",
              "> GENERATED by `tools/kb_wiki_skills.py` from the Achaea wiki. Confidence: **WIKI** -- in-game",
              "> `AB <skill>` wins where they differ. The combat dossier for this class is",
              f"> `.claude/classes/{cls.lower()}.md`.", ""]
        for skill in ss:
            if skill not in data:
                md += [f"## {skill}", "", "(not fetched: see `tools/kb_wiki_skills.py` output)", ""]
                continue
            abil = data[skill]["abilities"]
            note = NOTES.get((cls, skill))
            md += [f"## {skill} ({len(abil)} abilities)", ""] + ([f"*{md_esc(note)}.*", ""] if note else [])
            md += [p for para in data[skill].get("intro", [])
                   for p in ((para if para.startswith("| ") else md_esc(para)), "")]
            md += [f"*Wiki note: {md_esc(n)}*" for n in data[skill].get("notes", [])] + ([""] if data[skill].get("notes") else [])
            md += [f"Source: [{data[skill]['url']}]({data[skill]['url']}) "
                   f"(raw: `{data[skill]['source']}`)", "",
                   "| Ability | Syntax | Cost | Cooldown / balance | Works on | Afflictions named |",
                   "|---|---|---|---|---|---|"]
            for a in abil:
                # The wiki marks some abilities "(*)" at the end of the description; the page's note says
                # what it means (Telepathy: usable without a mind lock). Show it beside the name.
                star = " (*)" if (a.get("description") or "").rstrip().endswith("(*)") else ""
                md.append(f"| **{cell(a.get('skill'))}**{star} | `{cell(a.get('syntax'))}` | {cell(md_esc(a.get('required')))} | "
                          f"{cell(md_esc(a.get('cooldown')))} | {cell(md_esc(a.get('target')))} | {', '.join(a['afflictions'])} |")
            md += ["", "### Details", ""]
            for a in abil:
                md.append(f"- **{a.get('skill')}**: {md_esc(a.get('description'))} {md_esc(a.get('detail'))}".rstrip())
            md.append("")
        with open(os.path.join(OUT, f"{cls.lower()}.md"), "w", encoding="utf-8", newline="\n") as fh:
            fh.write("\n".join(md) + "\n")

    total = sum(len(v["abilities"]) for v in data.values())
    print(f"{len(data)}/{len(skills)} skills, {total} abilities -> kb/classes/abilities.json + {len(CLASSES)} class pages")
    for skill, why in missing:
        print(f"  MISSING {skill}: {why}")


if __name__ == "__main__":
    main()
