#!/usr/bin/env python3
"""Generate kb/afflictions/catalog.md: the game's cure table joined to our code.

One row per affliction, answering both sides of a fight:
  * how it is cured (the game's HELP 13.7.2 table, kept verbatim in kb/raw/), and
  * what OUR code believes: which herb the target tracker thinks cures it, and
    the priority our server-side curing gives it (PvP default + PvE bash delta).

Disagreements between the game text and the code are flagged in the last column.
Re-run after changing any of the source tables:

    python tools/kb_catalog.py
"""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ATAXIA = os.path.join(ROOT, "src_new", "scripts", "levi_ataxia", "levi", "ataxia")
HELP = os.path.join(ROOT, "kb", "raw", "help", "13.7.2_afflictions-and-what-cures-them.txt")
OUT = os.path.join(ROOT, "kb", "afflictions", "catalog.md")
LIVE = os.path.join(ROOT, "kb", "raw", "live", "whatcures.txt")
TRACKED_HERBS = ("kelp", "ginseng", "goldenseal", "lobelia", "ash", "bellwort", "bloodroot")

SRC = {
    "wide": os.path.join(ATAXIA, "curing", "002_Wide_Groups.lua"),
    "v3": os.path.join(ATAXIA, "affliction_tracking_core", "007_Branching_State_Tracker.lua"),
    "pvp": os.path.join(ATAXIA, "ataxia", "001_Default_Curing_Prios.lua"),
    "bash": os.path.join(ATAXIA, "ataxia", "008_Bash_Curing_Profile.lua"),
}

# HELP display name -> code key, where they are not simply the squashed name.
# Entries marked ASSUMED are a guess at equivalence, not a confirmed rename.
NAME_MAP = {
    "lover'seffect": "lovers",
    "pacifism": "pacified",
    "transfixed": "transfixation",
    "ablaze": "burning",            # ASSUMED: code tracks fire as `burning` (stacking)
    "freezing": "frozen",           # ASSUMED: code splits cold into shivering -> frozen
    "internaltrauma": "serioustrauma",  # ASSUMED: code has mildtrauma + serioustrauma
}
ASSUMED = {"ablaze", "freezing", "internaltrauma"}
# Limb families: one HELP row covers six limbs; show the code's family keys.
FAMILIES = {"crippledlimb": "broken", "damagedlimb": "damaged", "mangledlimb": "mangled"}


def read(path):
    with open(path, encoding="utf-8") as fh:
        return fh.read()


def lua_list_table(text, name):
    """Parse `name = { herb = {"a", "b"}, ... }` into {aff: [herbs]}."""
    body = text.split(name + " = {", 1)[1].split("\n}", 1)[0]
    out = {}
    for herb, lst in re.findall(r"(\w+) = \{([^}]*)\}", body):
        for aff in re.findall(r'"(\w+)"', lst):
            out.setdefault(aff, []).append(herb)
    return out


def lua_prios(text, func):
    body = text.split("function " + func, 1)[1].split("\nend", 1)[0]
    return {k: int(v) for k, v in re.findall(r'\["(\w+)"\]\s*=\s*(\d+)', body)}


def parse_help():
    rows, last = [], None
    pat = re.compile(r"^(\S[A-Za-z' ]*?):?\s{2,}(\w+)(?: \(\*+\))?(?:\s+(\w+(?: \w+)?)\s{2,}(\w+))?\s*$")
    cont = re.compile(r"^\s{10,}(\w+)\s+(\w+(?: \w+)?)\s{2,}(\w+)\s*$")
    in_table = False
    for line in read(HELP).splitlines():
        if line.startswith("----------"):
            in_table = True
            continue
        if not in_table:
            continue
        if not line.strip():
            if rows:
                break
            continue
        m = cont.match(line)
        if m and last:  # a second cure for the row above (Slickness)
            last["alts"].append((m.group(1), m.group(2), m.group(3)))
            continue
        m = pat.match(line)
        if m:
            last = {"name": m.group(1).strip(), "action": m.group(2),
                    "herb": m.group(3) or "", "mineral": m.group(4) or "", "alts": []}
            rows.append(last)
    return rows


def parse_live():
    """WHATCURES captures: {aff: [(action, curative), ...]}. A later capture of the same
    affliction replaces an earlier one, so the newest line wins."""
    out = {}
    if not os.path.exists(LIVE):
        return out
    pat = re.compile(r"The affliction '(.+?)' is cured by: (.+?)\.?\s*$")
    for line in read(LIVE).splitlines():
        m = pat.search(line)
        if not m:
            continue
        cures = []
        for part in m.group(2).split(" / "):
            words = part.strip().split(" ", 1)
            cures.append((words[0].lower(), words[1].lower() if len(words) > 1 else ""))
        out[m.group(1).lower().replace(" ", "")] = cures
    return out


def live_text(cures):
    return " / ".join(f"{a} {c}".strip() for a, c in cures) if cures else ""


def live_flags(key, cures, wide, v3):
    """Compare a live WHATCURES answer to the herb the target tracker uses."""
    if not cures:
        return []
    herbs = {c.replace("prickly ash", "ash") for a, c in cures if a == "eat"}
    tracked = set(wide.get(key) or v3.get(key) or [])
    live_tracked = herbs & set(TRACKED_HERBS)
    if live_tracked and not (live_tracked & tracked):
        return [f"**live WHATCURES says {'/'.join(sorted(live_tracked))}, tracker says {'/'.join(sorted(tracked)) or 'nothing'}**"]
    return []


def main():
    wide = lua_list_table(read(SRC["wide"]), "curingTable")
    v3text = read(SRC["v3"])
    v3 = lua_list_table(v3text, "curingTableV3")
    smoke = set(re.findall(r'"(\w+)"', v3text.split("smokeCureTableV3 = {", 1)[1].split("}", 1)[0]))
    salve = lua_list_table(v3text, "salveCureTableV3")
    pvp = lua_prios(read(SRC["pvp"]), "ataxia_defaultCuringPrios")
    bash = lua_prios(read(SRC["bash"]), "ataxia_bashCuringPrios")
    live = parse_live()

    def tracker(key):
        herbs = wide.get(key) or v3.get(key)
        parts = list(herbs or [])
        if key in smoke:
            parts.append("smoke")
        if key in salve:
            parts.append("salve:" + "/".join(salve[key]))
        return ", ".join(parts)

    def prio(key):
        p = pvp.get(key)
        b = bash.get(key)
        p_s = "" if p is None else str(p)
        b_s = "" if b is None else str(b)
        return p_s, b_s

    lines = [
        "# Affliction catalog",
        "",
        "> GENERATED by `tools/kb_catalog.py` -- do not hand-edit; re-run it instead.",
        "> Game columns: `kb/raw/help/13.7.2_afflictions-and-what-cures-them.txt` (HELP 13.7.2).",
        "> Code columns: target tracker = `curingTable` (`curing/002_Wide_Groups.lua`), falling back to",
        "> `curingTableV3` / `smokeCureTableV3` / `salveCureTableV3` (`affliction_tracking_core/007`);",
        "> priorities = `ataxia_defaultCuringPrios()` (PvP, `ataxia/001`) and the PvE bash DELTA",
        "> `ataxia_bashCuringPrios()` (`ataxia/008`; blank = keeps the PvP value). Lower = cured sooner;",
        "> 25 = low, 26 = never cured (kept as a defence); >= 20 is parked in the bash set.",
        "> **Live** = the game's own `WHATCURES` output (`kb/raw/live/whatcures.txt`). It outranks HELP,",
        "> which is partly stale. Paste more `WHATCURES <aff>` lines into the inbox to fill this column.",
        "",
        "| Affliction | Action | Herb | Mineral | Live (WHATCURES) | Code key | Tracker cures with | PvP prio | Bash prio | Flags |",
        "|---|---|---|---|---|---|---|---|---|---|",
    ]
    covered = set()
    for r in parse_help():
        squashed = r["name"].lower().replace(" ", "")
        flags = []
        if squashed in FAMILIES:
            fam = FAMILIES[squashed]
            keys = sorted(k for k in pvp if k.startswith(fam))
            covered.update(keys)
            key_s = f"`{fam}*` ({len(keys)} keys)"
            trk, p_s, b_s = "salve (limb)", "per limb", "per limb"
        else:
            key = NAME_MAP.get(squashed, squashed)
            covered.add(key)
            key_s = f"`{key}`"
            if squashed in ASSUMED:
                flags.append("name mapping ASSUMED")
            trk = tracker(key)
            p_s, b_s = prio(key)
            lv = live.get(key) or live.get(squashed)
            if r["action"] == "Eat" and r["herb"]:
                herb = r["herb"].lower().replace("prickly ash", "ash")
                tracked = wide.get(key) or v3.get(key)
                live_herbs = {c.replace("prickly ash", "ash") for a, c in (lv or []) if a == "eat"}
                if lv and herb not in live_herbs:
                    flags.append(f"HELP stale ({herb}); live confirms {'/'.join(sorted(live_herbs)) or live_text(lv)}")
                elif tracked and herb not in tracked:
                    flags.append(f"**HELP says {herb}, tracker says {'/'.join(tracked)}**")
                elif not tracked and herb in TRACKED_HERBS:
                    flags.append("not in tracker cure tables")
            flags += live_flags(key, lv, wide, v3)
            if not p_s and not b_s:
                flags.append("no SSC priority in our tables")
        action = r["action"] + "".join(f" / {a[0]}" for a in r["alts"])
        herb = r["herb"] + "".join(f" / {a[1]}" for a in r["alts"])
        mineral = r["mineral"] + "".join(f" / {a[2]}" for a in r["alts"])
        lv_s = "" if squashed in FAMILIES else live_text(live.get(NAME_MAP.get(squashed, squashed)) or live.get(squashed))
        lines.append(f"| {r['name']} | {action} | {herb} | {mineral} | {lv_s} | {key_s} | {trk} | {p_s} | {b_s} | {'; '.join(flags)} |")

    extra = sorted(k for k in pvp if k not in covered and not re.search(r"\d$", k))
    lines += [
        "",
        "## In our priority table but not in HELP 13.7.2",
        "",
        "HELP 13.7.2 is a short, partly stale list (see `kb/afflictions/README.md`). These afflictions are",
        "real -- our curing priorities name them -- but their cures still need a source in `kb/raw/`.",
        "Paste `WHATCURES <aff>` / `AFFLICTION SHOW <aff>` output into the inbox to fill them in.",
        "",
        "| Code key | Live (WHATCURES) | Tracker cures with | PvP prio | Bash prio | Flags |",
        "|---|---|---|---|---|---|",
    ]
    for k in extra:
        p_s, b_s = prio(k)
        lines.append(f"| `{k}` | {live_text(live.get(k))} | {tracker(k)} | {p_s} | {b_s} | {'; '.join(live_flags(k, live.get(k), wide, v3))} |")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(lines) + "\n")
    print(f"Wrote {OUT}: {len(parse_help())} HELP rows, {len(extra)} code-only afflictions.")


if __name__ == "__main__":
    main()
