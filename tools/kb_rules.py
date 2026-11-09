"""The rules of the whole-fight engine (plan step 7.2, stage 1), as one table with a tag and a source on every rule.

It joins the hand rules in kb/sim/rules_hand.json with the rules it reads from the knowledge base and the code:

    clocks      kb/mechanics/clocks.json                   MEASURED, with `usable`, and a range when not usable
    gaps        kb/mechanics/clocks.json stated.opponents  MEASURED: another Serpent's gap to its next attack
    cures       kb/afflictions/afflictions.json            READ: each affliction's cure options (alternatives)
    priorities  ataxia_defaultCuringPrios()                READ from the package, run under lupa
    venoms      .claude/databases/venoms.yaml              ASSUMED, with "off" as the alternative (the wiki's text is shown)
    blockers    ACTIVE_CURE_BLOCKERS (003_Lock_breakers)   READ, through kb_replay.BLOCKERS
    tree pool   treeCurableAffsV3 (008_V3_Integration)     the alternative to the ASSUMED random-cure pool

and writes kb/sim/rules.json (for the engine) and kb/sim/rules.md (for people). A verdict lists the ASSUMED, PLAYER and WIKI
rules it read, so nobody mistakes a model input for a fact.

    python tools/kb_rules.py            # write both files
    python tools/kb_rules.py --check    # the files match their inputs, and every rule has a tag and a source
"""

import argparse
import hashlib
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kb_timing as kb
import kb_replay as rp

try:
    import lupa.lua51 as lupa
except ImportError:
    lupa = None

ROOT = kb.ROOT
HAND = os.path.join(ROOT, "kb", "sim", "rules_hand.json")
CLOCKS = os.path.join(ROOT, "kb", "mechanics", "clocks.json")
AFFLICTIONS = os.path.join(ROOT, "kb", "afflictions", "afflictions.json")
VENOMS = os.path.join(ROOT, ".claude", "databases", "venoms.yaml")
PRIOS = os.path.join(ROOT, "src_new", "scripts", "levi_ataxia", "levi", "ataxia", "ataxia", "001_Default_Curing_Prios.lua")
MISC = os.path.join(ROOT, "src_new", "scripts", "levi_ataxia", "levi", "ataxia", "ataxia", "001_Miscellaneous_Aff_Tracking_Methods.lua")
V3 = os.path.join(ROOT, "src_new", "scripts", "levi_ataxia", "levi", "ataxia", "affliction_tracking_core", "008_V3_Integration.lua")
GATES = os.path.join(ROOT, "tools", "sim", "gates_whole.json")
OUT_JSON = os.path.join(ROOT, "kb", "sim", "rules.json")
OUT_MD = os.path.join(ROOT, "kb", "sim", "rules.md")

TAGS = ("MEASURED", "READ", "WIKI", "PLAYER", "ASSUMED")
# These tags describe a model input, not a fact: a run lists each one it read, and each one needs alternatives to sweep.
SOFT_TAGS = ("WIKI", "PLAYER", "ASSUMED")
# p90 - p10 of a normal draw is 2.563 standard deviations (the same rule as kb_sim.build_model).
SPREAD_TO_SD = 2.563
# Below this many samples a clock's range is min..max, not p10..p90: one stamp should not narrow it.
SMALL_N = 10
# The herb and its mineral share one eat (kb/afflictions/cure-channels.md:19). The engine prints the mineral, as the loggers ate.
LOGGERS_BY_LOG = {"az": "Claes", "Z5": "Elmer", "g": "Elmer", "X": "Nikita"}


def rel(path):
    return os.path.relpath(path, ROOT).replace("\\", "/")


def read_text(path):
    with open(path, "rb") as fh:
        return fh.read().replace(b"\r\n", b"\n").decode("utf-8")


def sha(path):
    with open(path, "rb") as fh:
        return hashlib.sha256(fh.read().replace(b"\r\n", b"\n")).hexdigest()


def freeze_hash():
    return sha(GATES)


# ---------------------------------------------------------------------------------------------
# Rules read from the knowledge base and the code
# ---------------------------------------------------------------------------------------------


def clock_value(st):
    return {"median": round(st["median"], 3), "sd": round(st["spread"] / SPREAD_TO_SD, 3), "min": round(st["min"], 3),
            "p10": round(st["p10"], 3), "p90": round(st["p90"], 3), "max": round(st["max"], 3)}


def clock_rules(clocks):
    out = {}
    for name in sorted(clocks["clocks"]):
        c = clocks["clocks"][name]
        st = c["stats"]
        if not st.get("n"):
            continue
        rule = {"value": clock_value(st), "tag": "MEASURED", "n": st["n"], "usable": bool(c["usable"]),
                "source": "kb/mechanics/clocks.json clocks.%s" % name}
        if not c["usable"]:
            # A clock that is not usable is a range to sweep, never one number.
            lo, hi = ("min", "max") if st["n"] < SMALL_N else ("p10", "p90")
            rule["alt"] = [round(st[lo], 3), round(st["median"], 3), round(st[hi], 3)]
            rule["note"] = "not usable (%s): swept %s..%s" % (c.get("why_not") or "see clocks.md", lo, hi)
        out["clock." + name] = rule
    # The eat clock is not usable pooled, so each victim gets its logger's own, printed where the client prints it.
    seen = {}
    for entry in clocks["clocks"]["eat"]["by_logger"]:
        who = entry["logger"].split()[0]
        if who not in LOGGERS_BY_LOG.values():
            continue
        best = seen.get(who)
        better = best is None or (entry["usable"] and not best["usable"]) or (
            entry["usable"] == best["usable"] and entry["method"] == "printed" and best["method"] != "printed")
        if better:
            seen[who] = entry
    for who in sorted(seen):
        entry = seen[who]
        st = entry["stats"]
        out["clock.eat.%s" % who] = {"value": clock_value(st), "tag": "MEASURED", "n": st["n"], "usable": bool(entry["usable"]),
                                     "source": "kb/mechanics/clocks.json clocks.eat.by_logger (%s, %s)" % (who, entry["method"])}
    return out


def gap_rules(clocks):
    out = {}
    for row in clocks["stated"]["opponents"]:
        st = row["stats"]
        if not st.get("n"):
            continue
        spread = st["p90"] - st["p10"]
        # The same rule as a clock (kb_timing.usable): n >= 10 and p90-p10 <= 0.2. A gap is a choice as well as a cost, so
        # every one of them is wide, and a wide gap is swept.
        ok, why = kb.usable({"n": st["n"], "spread": spread})
        rule = {"value": {"median": round(st["median"], 3), "p10": round(st["p10"], 3), "min": round(st["min"], 3),
                          "p90": round(st["p90"], 3), "sd": round(spread / SPREAD_TO_SD, 3)},
                "tag": "MEASURED", "n": st["n"], "usable": ok,
                "source": "kb/mechanics/clocks.json stated.opponents %s" % row["ability"],
                "note": "another Serpent's gap to its next attack: the earliest action, never when. Stated %s s" % row["stated"]}
        if not ok:
            rule["alt"] = [round(st["p10"], 3), round(st["median"], 3), round(st["p90"], 3)]
            rule["note"] += "; not usable (%s): swept p10..p90" % why
        out["attack.gap.others.%s" % row["ability"].lower()] = rule
    return out


def cure_option(text, lungs=("pear", "calcite")):
    """'eat bloodroot' -> {'channel': 'eat', 'item': 'bloodroot'}.

    Pear and calcite are eaten, so anorexia shuts them, but they spend the lungs clock (cure-channels.md:19, 33;
    replay.md:149): channel "lungs". APPLY HEALTH is the health elixir, not a salve (cure-channels.md:50-52): channel
    "elixir". The engine runs neither channel yet, and no Serpent venom gives an affliction only they cure."""
    words = text.split()
    verb, item = words[0], " ".join(words[1:])
    if verb == "eat":
        first = item.split()[0] if item else ""
        if first in lungs:
            return {"channel": "lungs", "item": item}
        return {"channel": "eat", "item": item}
    if verb == "smoke":
        return {"channel": "smoke", "item": item}
    if verb == "apply":
        salve = words[1] if len(words) > 1 else ""
        if salve == "health":
            return {"channel": "elixir", "item": item}
        return {"channel": "restoration" if salve == "restoration" else "salve", "item": item}
    if verb == "focus":
        return {"channel": "focus", "item": ""}
    if verb == "sip":
        return {"channel": "sip", "item": item}
    return {"channel": verb, "item": item}


def cure_rules(affs, lungs=("pear", "calcite")):
    out = {}
    for name in sorted(affs):
        entry = affs[name]
        options, herb, mineral = [], None, None
        for group in entry.get("cure_options") or []:
            for text in group:
                opt = cure_option(text, lungs)
                if opt not in options:
                    options.append(opt)
            if group and group[0].startswith("eat ") and herb is None and cure_option(group[0], lungs)["channel"] == "eat":
                herb = group[0][4:]
                mineral = group[1][4:] if len(group) > 1 and group[1].startswith("eat ") else herb
        # The game's flag, READ. What it means for the tree is the ASSUMED rule random_cure.pool.
        value = {"options": options, "no_random_cure": bool(entry["flags"].get("NoRandomCure", False))}
        if herb:
            value["herb"], value["mineral"] = herb, mineral
        out["cure." + name] = {"value": value, "tag": "READ", "source": entry.get("source") or rel(AFFLICTIONS)}
    return out


def prio_rules(lua):
    with open(PRIOS, encoding="utf-8") as fh:
        lua.execute(fh.read())
    table = lua.globals().ataxia_defaultCuringPrios()
    out = {}
    for name, value in sorted(table.items()):
        if isinstance(value, (int, float)):
            out["prio." + name] = {"value": value, "tag": "READ", "source": rel(PRIOS) + " ataxia_defaultCuringPrios()"}
    return out


VENOM_ENTRY = re.compile(r'^  (\w+):\n    affliction: "([^"]*)"\n    cure: "[^"]*"\n    weapon: (\w+)\n    source: "([^"]*)"\n'
                         r'    wiki: "([^"]*)"', re.M)


# A level-1 limb break, as the package names it (001_Miscellaneous_Aff_Tracking_Methods.lua:215, 233-245): the left limb
# first, the right one when the left is already broken. "a|b" means a, else b.
LIMB_BREAKS = {"crippled leg (level 1 break)": "brokenleftleg|brokenrightleg",
               "crippled arm (level 1 break)": "brokenleftarm|brokenrightarm"}


def venom_affs(text):
    """The afflictions a venom gives, as the engine names them. A damage venom gives none here."""
    if text in LIMB_BREAKS:
        return [LIMB_BREAKS[text]]
    if text.startswith("none") or "break" in text:
        return []
    if text.startswith("a random"):
        return ["random"]
    return [part.strip() for part in text.split("+")]


PACKAGE_TABLE = re.compile(r"^function venom_to_aff\(venom\).*?local venom_to_affliction = \{(.*?)^\s*\}", re.M | re.S)


def package_venoms():
    """{venom: (the package's affliction word, line)} from venom_to_aff in 001_Miscellaneous_Aff_Tracking_Methods.lua. The
    Hellforge rows after their comment are abilities, not venoms."""
    text = read_text(MISC)
    m = PACKAGE_TABLE.search(text)
    body = m.group(1).split("-- Hellforge")[0]
    first = text[:m.start(1)].count("\n") + 1
    out = {}
    for k, row in enumerate(body.split("\n")):
        for name, aff in re.findall(r'(\w+) = "(\w+)"', row):
            out[name] = (aff, first + k)
    return out


def venom_rules(text):
    """venoms.yaml's entries. A venom the package's own table holds (venom_to_aff) gives what the package believes, so truth
    and belief agree by construction; the yaml's "source" label is not trusted for that (selarnia is in the table but
    labelled wiki)."""
    package = package_venoms()
    out = {}
    for m in VENOM_ENTRY.finditer(text):
        line = text[:m.start()].count("\n") + 1
        name, aff, weapon, source, wiki = m.groups()
        affs = venom_affs(aff)
        if name in package:
            word, pline = package[name]
            src = ".claude/databases/venoms.yaml:%d; %s:%d (venom_to_aff)" % (line, rel(MISC), pline)
            note = "the package's own table (venom_to_aff), so truth and belief agree by construction"
            if [word] != affs and word not in ("legbreak", "armbreak"):
                note += ". The package's word is '%s'; the engine uses afflictions.json's name" % word
        else:
            src = ".claude/databases/venoms.yaml:%d (wiki)" % line
            note = "from the wiki's text only: the package's table does not hold it"
        # The wiki's prose is a reference, not a runnable alternative. The runnable one is "off": the venom gives nothing.
        out["venom." + name] = {"value": {"affs": affs, "weapon": weapon == "true"}, "alt": ["off"], "tag": "ASSUMED",
                                "source": src, "wiki": wiki, "note": note}
    return out


TREE_POOL = re.compile(r"^treeCurableAffsV3 = \{(.*?)^\}", re.M | re.S)


def random_pool_rule():
    """The afflictions the tree and the random class cures (Salt, Accelerate, Dagaz) can take. The game's NoRandomCure flag
    is READ; reading it as 'a random cure cannot take it' is ASSUMED (kb/afflictions/database.md:11-14). The alternative is
    the package's own tree pool."""
    text = read_text(V3)
    m = TREE_POOL.search(text)
    body = re.sub(r"--[^\n]*", "", m.group(1))
    pool = re.findall(r'"(\w+)"', body)
    line = text[:m.start()].count("\n") + 1
    return {"random_cure.pool": {
        "value": "NoRandomCure off", "alt": [pool], "tag": "ASSUMED",
        "source": "kb/afflictions/database.md:11-14; %s:%d (treeCurableAffsV3, the alternative)" % (rel(V3), line),
        "note": "every affliction the game does not mark NoRandomCure. The package's tree pool holds %d (--random-pool package)"
                % len(pool)}}


def blocker_rules():
    return {"classcure.blocker." + cls: {"value": aff, "tag": "READ",
                                         "source": "src_new/scripts/levi_ataxia/levi/ataxia/can(x)/003_Lock_breakers.lua:214"}
            for cls, aff in sorted(rp.BLOCKERS.items())}


def hand_rules(hand):
    out = {}
    for row in hand["rules"]:
        rule = {k: v for k, v in row.items() if k != "id"}
        out[row["id"]] = rule
    return out


# ---------------------------------------------------------------------------------------------
# The table
# ---------------------------------------------------------------------------------------------


def build():
    if lupa is None:
        sys.exit("kb_rules: needs lupa with Lua 5.1 (python -m pip install lupa)")
    with open(CLOCKS, encoding="utf-8") as fh:
        clocks = json.load(fh)
    with open(AFFLICTIONS, encoding="utf-8") as fh:
        affs = json.load(fh)
    with open(HAND, encoding="utf-8") as fh:
        hand = json.load(fh)
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    lungs = tuple(next(r["value"] for r in hand["rules"] if r["id"] == "channel.eat.lungs_items"))
    rules = {}
    for part in (clock_rules(clocks), gap_rules(clocks), cure_rules(affs, lungs), prio_rules(lua), venom_rules(read_text(VENOMS)),
                 blocker_rules(), random_pool_rule(), hand_rules(hand)):
        for key, rule in part.items():
            if key in rules:
                raise ValueError("rule %s is defined twice" % key)
            rules[key] = rule
    # A hand rule whose value is a clock ("clock.rebounding") is measured by that clock: it takes the clock's n.
    for key, rule in rules.items():
        v = rule.get("value")
        if isinstance(v, str) and v.startswith("clock.") and v in rules and "n" not in rule:
            rule["n"] = rules[v]["n"]
    inputs = {rel(p): sha(p)[:16] for p in (HAND, CLOCKS, AFFLICTIONS, VENOMS, PRIOS, MISC, V3, rp.LOCK_LUA, GATES)}
    return {"generated_by": "tools/kb_rules.py", "freeze_sha256": freeze_hash(), "inputs": inputs,
            "rules": {k: rules[k] for k in sorted(rules)}}


def problems(data):
    """Every rule has a tag and a source, and each soft rule has alternatives (or is verified elsewhere)."""
    out = []
    for key, rule in data["rules"].items():
        if rule.get("tag") not in TAGS:
            out.append("%s: tag %r is not one of %s" % (key, rule.get("tag"), ", ".join(TAGS)))
        if not rule.get("source"):
            out.append("%s: no source" % key)
        if rule.get("tag") in SOFT_TAGS and not rule.get("alt") and not rule.get("verified_by"):
            out.append("%s: a %s rule needs alternatives to sweep" % (key, rule["tag"]))
        if rule.get("tag") == "MEASURED" and not rule.get("n"):
            out.append("%s: a MEASURED rule needs n" % key)
        if rule.get("tag") == "MEASURED" and rule.get("usable") is False and not rule.get("alt"):
            out.append("%s: a MEASURED rule that is not usable needs a range to sweep" % key)
    return out


def short(value):
    if isinstance(value, dict):
        return ", ".join("%s %s" % (k, short(v)) for k, v in value.items())
    if isinstance(value, list):
        return " / ".join(short(v) for v in value)
    if value is None:
        return "none"
    return str(value)


def cell(text):
    return str(text).replace("|", "\\|").replace("\n", " ")


def render(data):
    rules = data["rules"]
    counts = {}
    for rule in rules.values():
        counts[rule["tag"]] = counts.get(rule["tag"], 0) + 1
    lines = [
        "---",
        "topic: whole-fight engine rules",
        "confidence: tagged per rule",
        "generated_by: tools/kb_rules.py",
        "---",
        "",
        "# The engine's rules",
        "",
        "**GENERATED. Do not edit.** Run `python tools/kb_rules.py`. Hand rules live in `kb/sim/rules_hand.json`.",
        "",
        "Every rule of the whole-fight engine (`tools/sim/fight.lua`) is here, with its tag and its source. A run of",
        "`tools/theorycraft.py` lists the ASSUMED, PLAYER and WIKI rules it read. Those are model inputs, not facts, and each one",
        "has alternatives so a sweep can run it.",
        "",
        "Freeze file `tools/sim/gates_whole.json`, sha256 `%s`." % data["freeze_sha256"],
        "",
        "| Tag | Rules | Means |",
        "|---|---|---|",
        "| MEASURED | %d | counted from log rows |" % counts.get("MEASURED", 0),
        "| READ | %d | stated in a file or in the code |" % counts.get("READ", 0),
        "| WIKI | %d | the wiki only; an in-game AB wins |" % counts.get("WIKI", 0),
        "| PLAYER | %d | a player said so |" % counts.get("PLAYER", 0),
        "| ASSUMED | %d | nothing supports it yet |" % counts.get("ASSUMED", 0),
        "",
        "## Rules of play",
        "",
        "| Rule | Value | Alternatives | Tag | n | Source | Note |",
        "|---|---|---|---|---|---|---|",
    ]
    bulk = ("cure.", "prio.", "venom.", "classcure.blocker.", "clock.", "attack.gap.others.")
    for key, rule in rules.items():
        if key.startswith(bulk) and key != "cure.options_join":
            continue
        lines.append("| `%s` | %s | %s | %s | %s | %s | %s |" % (
            key, cell(short(rule.get("value"))), cell(short(rule.get("alt", ""))), rule["tag"], rule.get("n", ""),
            cell(rule["source"]), cell(rule.get("note", ""))))
    lines += ["", "## Clocks", "",
              "Seconds. A clock that is not usable is swept over the range in the last column.", "",
              "| Rule | Median | SD | p10 | p90 | n | Usable | Swept | Source |", "|---|---|---|---|---|---|---|---|---|"]
    for key, rule in rules.items():
        if not key.startswith(("clock.", "attack.gap.others.")):
            continue
        v = rule["value"]
        lines.append("| `%s` | %.3f | %.3f | %.3f | %.3f | %d | %s | %s | %s |" % (
            key, v["median"], v["sd"], v["p10"], v["p90"], rule["n"], "yes" if rule.get("usable") else "no",
            short(rule.get("alt", "")), cell(rule["source"])))
    lines += ["", "## Class cures shut by", "", "From the code, so the engine's `true` label replays what the package does today.", "",
              "| Class | Blocker |", "|---|---|"]
    for key, rule in rules.items():
        if key.startswith("classcure.blocker."):
            lines.append("| %s | %s |" % (key.split(".", 2)[2], rule["value"]))
    venoms = [(k, r) for k, r in rules.items() if k.startswith("venom.")]
    own = sum(1 for _, r in venoms if "(venom_to_aff)" in r["source"])
    lines += ["", "## Venoms", "",
              "ASSUMED. %d of the %d come from the package's own table (`venom_to_aff`), so truth and belief agree by construction."
              " The other %d come from the wiki's text only. The runnable alternative of each is `off` (the venom gives"
              " nothing); the wiki's text is a reference. `a|b` means a, else b: the package breaks the left limb first."
              % (own, len(venoms), len(venoms) - own), "",
              "| Venom | Gives | On a weapon | From | Source | The wiki's text |", "|---|---|---|---|---|---|"]
    for key, rule in venoms:
        v = rule["value"]
        lines.append("| %s | %s | %s | %s | %s | %s |" % (
            key[6:], cell(", ".join(v["affs"])) or "nothing here", "yes" if v["weapon"] else "no",
            "package" if "(venom_to_aff)" in rule["source"] else "wiki", cell(rule["source"]), cell(rule.get("wiki", ""))))
    lines += ["", "## Cures", "", "READ from `kb/afflictions/afflictions.json`. The options are alternatives (`cure.options_join`). "
              "The priority is the package's default (`prio.*`); a lower number goes first. NoRandomCure is the game's flag;"
              " what it means for the tree is the ASSUMED rule `random_cure.pool`. Channel `lungs` is pear or calcite (eaten,"
              " shut by anorexia, on the lungs clock) and `elixir` is APPLY HEALTH: the engine runs neither yet.", "",
              "| Affliction | Options | Herb (mineral) | NoRandomCure | Priority |", "|---|---|---|---|---|"]
    for key, rule in rules.items():
        if not key.startswith("cure."):
            continue
        name = key[5:]
        if name == "options_join":
            continue
        v = rule["value"]
        opts = "; ".join("%s %s" % (o["channel"], o["item"]) if o["item"] else o["channel"] for o in v["options"])
        herb = "%s (%s)" % (v["herb"], v["mineral"]) if v.get("herb") else ""
        prio = rules.get("prio." + name, {}).get("value", "")
        lines.append("| %s | %s | %s | %s | %s |" % (name, cell(opts), herb, "yes" if v["no_random_cure"] else "no", prio))
    orphans = [k for k in rules if k.startswith("prio.") and "cure." + k[5:] not in rules]
    lines += ["", "## Priorities with no cure row", "",
              "The package's default priority for a stack (`burning4`) or an affliction afflictions.json does not list.", "",
              "| Rule | Priority | Source |", "|---|---|---|"]
    for key in orphans:
        lines.append("| `%s` | %s | %s |" % (key, rules[key]["value"], cell(rules[key]["source"])))
    lines += ["", "## Inputs", "", "| File | sha256 (16) |", "|---|---|"]
    for path, digest in data["inputs"].items():
        lines.append("| `%s` | `%s` |" % (path, digest))
    return "\n".join(lines) + "\n"


def dump(data):
    return json.dumps(data, indent=1, sort_keys=True, ensure_ascii=False) + "\n"


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--check", action="store_true", help="fail if the files do not match their inputs")
    args = ap.parse_args()
    data = build()
    bad = problems(data)
    if bad:
        print("kb_rules: %d problems" % len(bad))
        for line in bad:
            print("  " + line)
        return 1
    text_json, text_md = dump(data), render(data)
    if args.check:
        stale = []
        for path, text in ((OUT_JSON, text_json), (OUT_MD, text_md)):
            have = read_text(path) if os.path.exists(path) else None
            if have != text:
                stale.append(rel(path))
        if stale:
            print("kb_rules: STALE: %s. Run python tools/kb_rules.py" % ", ".join(stale))
            return 1
        print("kb_rules: %d rules, files match their inputs" % len(data["rules"]))
        return 0
    for path, text in ((OUT_JSON, text_json), (OUT_MD, text_md)):
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(text)
    print("kb_rules: wrote %d rules to %s and %s" % (len(data["rules"]), rel(OUT_JSON), rel(OUT_MD)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
