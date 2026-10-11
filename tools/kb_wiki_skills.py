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
}
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
        data[skill] = {"source": f"kb/raw/wiki/{skill}.wiki", "url": f"https://wiki.achaea.com/{page}",
                       "abilities": abilities}

    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "abilities.json"), "w", encoding="utf-8", newline="\n") as fh:
        json.dump(data, fh, indent=1, sort_keys=True)
        fh.write("\n")

    cell = lambda s: (s or "").replace("|", "\\|")
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
            md += [f"## {skill} ({len(abil)} abilities)", ""] + ([f"*{note}.*", ""] if note else []) + [f"Source: [{data[skill]['url']}]({data[skill]['url']}) "
                   f"(raw: `{data[skill]['source']}`)", "",
                   "| Ability | Syntax | Cost | Cooldown / balance | Works on | Afflictions named |",
                   "|---|---|---|---|---|---|"]
            for a in abil:
                md.append(f"| **{cell(a.get('skill'))}** | `{cell(a.get('syntax'))}` | {cell(a.get('required'))} | "
                          f"{cell(a.get('cooldown'))} | {cell(a.get('target'))} | {', '.join(a['afflictions'])} |")
            md += ["", "### Details", ""]
            for a in abil:
                md.append(f"- **{a.get('skill')}**: {a.get('description', '')} {a.get('detail', '')}".rstrip())
            md.append("")
        with open(os.path.join(OUT, f"{cls.lower()}.md"), "w", encoding="utf-8", newline="\n") as fh:
            fh.write("\n".join(md) + "\n")

    total = sum(len(v["abilities"]) for v in data.values())
    print(f"{len(data)}/{len(skills)} skills, {total} abilities -> kb/classes/abilities.json + {len(CLASSES)} class pages")
    for skill, why in missing:
        print(f"  MISSING {skill}: {why}")


if __name__ == "__main__":
    main()
