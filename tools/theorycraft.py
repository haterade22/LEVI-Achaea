"""Theorycraft a fight: a scripted Serpent against a victim, a real log in the same columns, or a fork from a real row.

Plan step 7.2, stage 1. The engine is tools/sim/fight.lua (with victim.lua and attackers.lua) in Lua 5.1 under lupa. Its
rules come from kb/sim/rules.json (tools/kb_rules.py), and every run names the rules it used that are not MEASURED or READ.
A run is a MODEL, not a log, and it never predicts a live opponent's herb.

    # the user's example: a scripted fight, clocks.json medians, no noise
    python tools/theorycraft.py --victim runewarden --gap 1.83 --median \\
        --script "dstab curare kalmia" "dstab curare kalmia" "dstab gecko slike"

    # a real fight, in the engine's columns
    python tools/theorycraft.py --log Z5 --from 196 --rows 30

    # a fork: the board and clocks of Z5 row 204, then a different attack, with the race over 200 seeds
    python tools/theorycraft.py --log Z5 --at 204 --then "dstab curare vernalius" --seeds 200

Our own DSTAB gap is not measured (no log of our Serpent), so a scripted run needs --gap until the spar lands.
"""

import argparse
import hashlib
import json
import math
import os
import sys
import types

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kb_timing as kb  # noqa: E402
import kb_replay as rp  # noqa: E402
import kb_events as ke  # noqa: E402
import kb_sim as ks  # noqa: E402

try:
    import lupa.lua51 as lupa
except ImportError:  # pragma: no cover
    lupa = None

ROOT = kb.ROOT
SIM = os.path.join(ROOT, "tools", "sim")
RULES = os.path.join(ROOT, "kb", "sim", "rules.json")
LUA_FILES = ("forward.lua", "victim.lua", "attackers.lua", "fight.lua")

# The victim classes the CLI knows, and the logger whose eat clock, shield cost and items describe each one. A class with
# no logger here takes the pooled eat clock, which clocks.json marks not usable.
VICTIMS = {
    "runewarden": ("Runewarden", "Claes", "herb"),
    "alchemist": ("Alchemist", "Elmer", "mineral"),
    "monk": ("Monk", "Elmer", "mineral"),
    "shikudo": ("Monk", "Elmer", "mineral"),
    "depthswalker": ("Depthswalker", "Nikita", "mineral"),
}
LOG_VICTIM = {"az": "runewarden", "Z5": "alchemist", "g": "shikudo", "X": "depthswalker"}
CLASS_CURES = (("class.fitness", "fitness"), ("class.salt", "salt"), ("class.accelerate", "accelerate"))
CLASS_LOCKOUT = {"fitness": "clock.fitness", "salt": "clock.salt", "accelerate": "class.accelerate.lockout"}
ABBR = {"asthma": "ast", "paralysis": "par", "anorexia": "ano", "slickness": "slk", "impatience": "imp",
        "weariness": "wea", "stupidity": "stu", "recklessness": "rek", "bal": "bal", "eq": "eq"}
CLASS_LABEL = {"fitness": "FIT", "salt": "SALT", "accelerate": "ACC"}
CHANNELS = ("eat", "smoke", "salve", "focus", "tree", "class")


# ---------------------------------------------------------------------------------------------
# The rules and the model
# ---------------------------------------------------------------------------------------------


CRLF, LF = bytes([13, 10]), bytes([10])


def file_sha(path):
    """sha256 of a file with its line ends made LF, so a CRLF checkout prints the same hash."""
    with open(path, "rb") as fh:
        return hashlib.sha256(fh.read().replace(CRLF, LF)).hexdigest()


def load_rules():
    with open(RULES, encoding="utf-8") as fh:
        return json.load(fh)


def value(rules, key):
    return rules["rules"][key]["value"]


def clock(rules, key):
    """A measured clock as the engine draws it: with its quantiles when the rule has them (rule draw.shape)."""
    v = value(rules, key)
    out = {"median": v["median"], "sd": v["sd"], "min": v["min"]}
    for k in ("p10", "p90", "max"):
        if k in v:
            out[k] = v[k]
    return out


def profile(name):
    name = name.lower()
    if name in VICTIMS:
        cls, logger, items = VICTIMS[name]
        return {"name": name, "cls": cls, "logger": logger, "items": items}
    for cls in rp.BLOCKERS:
        if cls.lower() == name:
            return {"name": name, "cls": cls, "logger": None, "items": "herb"}
    raise SystemExit("theorycraft: unknown victim %r. Known: %s" % (name, ", ".join(sorted(set(VICTIMS) | {c.lower() for c in rp.BLOCKERS}))))


def options(args):
    return {"random_pool": getattr(args, "random_pool", "norandomcure"), "flay_order": getattr(args, "flay_order", "named")}


def build_model(rules, prof, opts=None):
    """The rules table as the engine reads it. Returns (model, used): used lists each rule key the model rests on.

    opts: random_pool "norandomcure" (the rule's value) or "package" (its alternative, treeCurableAffsV3), and flay_order
    "named" (the wiki: a FLAY names what it strips) or "auto" (rule attack.flay.order's alternative)."""
    opts = opts or {}
    r = rules["rules"]
    used = set()
    lists = {"eat": [], "smoke": [], "salve": [], "focus": [], "random": []}
    herb, prio = {}, {}
    items = {"eat": {}, "smoke": {}, "salve": {}}
    package_pool = set(r["random_cure.pool"]["alt"][0])
    for key in sorted(r):
        if not key.startswith("cure.") or key == "cure.options_join":
            continue
        aff = key[5:]
        v = r[key]["value"]
        for opt in v.get("options", []):
            ch = opt["channel"]
            if ch in lists and aff not in lists[ch]:
                lists[ch].append(aff)
            if ch in ("smoke", "salve") and aff not in items[ch]:
                items[ch][aff] = opt["item"]
        pooled = (aff in package_pool) if opts.get("random_pool") == "package" else not v.get("no_random_cure")
        if pooled:
            lists["random"].append(aff)
        if v.get("herb"):
            herb[aff] = v["herb"]
            items["eat"][aff] = v.get(prof["items"]) or v["herb"]
        if "prio." + aff in r:
            prio[aff] = r["prio." + aff]["value"]
    used.update(("cure.options_join", "random_cure.pool", "ssc.order", "ssc.delay", "ssc.phi", "focus.order", "tree.cures",
                 "tree.pick", "tree.policy", "label.true"))
    eat_key = "clock.eat.%s" % prof["logger"] if prof["logger"] else "clock.eat"
    clocks = {"eat": clock(rules, eat_key), "smoke": clock(rules, "clock.smoke"), "salve": clock(rules, "clock.salve_short"),
              "focus": clock(rules, "clock.focus"), "tree": clock(rules, "clock.tree"),
              "rebounding": clock(rules, "clock.rebounding")}
    used.update((eat_key, "clock.smoke", "clock.salve_short", "clock.focus", "clock.tree"))
    blocked = {}
    for ch in ("eat", "salve", "smoke", "focus", "tree"):
        blocked[ch] = value(rules, "channel.%s.blocked_by" % ch)[0]
        used.add("channel.%s.blocked_by" % ch)
    classcure = None
    for key, kind in CLASS_CURES:
        cc = value(rules, key)
        if prof["cls"] not in cc["classes"]:
            continue
        lockout_key = cc["lockout"]
        if lockout_key.startswith("clock."):
            lockout = clock(rules, lockout_key)
        else:
            lockout = {"median": value(rules, lockout_key), "sd": 0, "min": value(rules, lockout_key)}
        cures, count = cc["cures"], 1
        if isinstance(cures, str) and cures in r:
            count, cures = value(rules, cures), "one"
            used.add(cc["cures"])
        spends = {}
        for what, ref in cc["spends"].items():
            if isinstance(ref, str) and ref in r:
                spends[what] = value(rules, ref)
                used.add(ref)
            else:
                spends[what] = ref
        classcure = {"kind": kind, "cures": cures, "count": count, "blocked_by": cc["blocked_by"], "lockout": lockout,
                     "needs_bal": "bal" in cc["needs"], "needs_eq": "eq" in cc["needs"],
                     "spends_bal": spends.get("bal", False), "spends_eq": spends.get("eq", False)}
        used.update((key, lockout_key, "class.cure.policy"))
    dagaz = None
    dz = value(rules, "class.dagaz")
    if prof["cls"] in dz["classes"]:
        dagaz = {"period": clock(rules, dz["period"]), "first": dz["first"][0]}
        used.update(("class.dagaz", dz["period"], "class.dagaz.phase"))
    blocker = r.get("classcure.blocker.%s" % prof["cls"])
    if blocker:
        used.add("classcure.blocker.%s" % prof["cls"])
    ssc = value(rules, "ssc.delay")
    chain = sorted(({"aff": a, "at": t} for a, t in value(rules, "timed.hypochondria").items()), key=lambda c: c["at"])
    venoms = {}
    for key in sorted(r):
        if key.startswith("venom."):
            affs = r[key]["value"]["affs"]
            venoms[key[6:]] = {"affs": [a for a in affs if a != "random"], "random": "random" in affs}
    cost_key = "defence.shield.cost.%s" % prof["logger"]
    if cost_key not in r:
        cost_key = "defence.shield.cost"
    reraise = clock(rules, "defence.shield.reraise")
    model = {"lists": lists, "herb": herb, "items": items, "prio": prio, "clocks": clocks, "blocked": blocked,
             "classcure": classcure, "dagaz": dagaz, "labelBlocker": blocker["value"] if blocker else None,
             "ssc": {"min": ssc["min"], "median": ssc["median"], "max": ssc["max"]}, "phi": value(rules, "ssc.phi"),
             "shield": {"cost": value(rules, cost_key), "whileParalysed": value(rules, "defence.shield.while_paralysed"),
                        "reraise": reraise},
             "shieldKeys": [cost_key, "defence.shield.reraise", "defence.shield.while_paralysed"],
             "sileris": {"harden": clock(rules, "defence.sileris.harden")},
             "reboundItem": value(rules, "defence.rebounding.smoke")[1 if prof["items"] == "mineral" else 0],
             "chain": chain, "venoms": venoms, "dstabVenoms": value(rules, "attack.dstab.venoms"),
             "flayOrder": "auto" if opts.get("flay_order") == "auto" else "named"}
    return model, used


def rules_for_actions(rules, lines, affs, used):
    """Add the rules a script rests on (review TC-07): attack.<kind> for each kind of action, the DSTAB venom count only for a
    DSTAB, venom.<word> only for a DSTAB, BITE or FLAY argument, attack.flay.order for a FLAY, and timed.hypochondria when
    hypochondria is up at the start, given, or brought by a venom of the script."""
    r = rules["rules"]
    hypo = "hypochondria" in affs
    for line in lines:
        words = line.lower().split()
        if not words:
            continue
        kind = words[0]
        if "attack." + kind in r:
            used.add("attack." + kind)
        if kind == "dstab":
            used.add("attack.dstab.venoms")
        if kind == "flay":
            used.add("attack.flay.order")
        if kind in ("dstab", "bite", "flay"):
            for word in words[1:]:
                if "venom." + word in r:
                    used.add("venom." + word)
                    hypo = hypo or "hypochondria" in r["venom." + word]["value"]["affs"]
        if kind == "give" and "hypochondria" in words[1:]:
            hypo = True
    if hypo:
        used.add("timed.hypochondria")


def options_used(args, used):
    """The rules whose alternative ran (review RUL-6), as {key: what ran}, and the shape of the draws (rule draw.shape)."""
    alts = {}
    if getattr(args, "random_pool", "norandomcure") == "package":
        alts["random_cure.pool"] = "the package's tree pool"
    if getattr(args, "flay_order", "named") == "auto":
        alts["attack.flay.order"] = "auto"
    if getattr(args, "tree", "now") == "hold":
        alts["tree.policy"] = "hold"
    if getattr(args, "tree_pick", "random") == "priority":
        alts["tree.pick"] = "priority"
    if args.median:
        # --median takes the top pick everywhere (victim.lua V.pick, V.pickRandom).
        alts["ssc.phi"] = "1.0, the top affliction always (--median)"
        # With --tree-pick priority, the drawn runs pick by priority too, so it is not the median run's only.
        alts.setdefault("tree.pick", "priority (--median)")
    # A run that draws its clocks rests on their shape, and so do the --seeds runs of a --median page (review R3-fork-3).
    if not args.median or getattr(args, "seeds", 0):
        shape_used(args, used, alts)
    return alts


def shape_used(args, used, alts):
    """The run rests on rule draw.shape: it draws a clock, or a --median fork takes the median of the part of a clock
    above the time already run, which the shape sets (review R3-engine-2)."""
    used.add("draw.shape")
    if getattr(args, "clock_draw", "quantiles") == "normal":
        alts["draw.shape"] = "normal"
    if not args.median or getattr(args, "seeds", 0):
        used.add("attack.gap.own.sd")


def seeds_lines(args, dagaz_drawn=False):
    """The P lines of a --median page come from drawn runs, not from the median run above them (review R3-fork-3). The
    text comes from the arguments the drawn runs took (reviews R4-cli-2, R4-docs-3)."""
    if not (args.median and args.seeds):
        return []
    pick = "by priority (--tree-pick priority)" if args.tree_pick == "priority" else "random (rule tree.pick)"
    gap = ("the gap drawn (sd %.2f, --gap-sd)" % args.gap_sd) if args.gap_sd > 0 else         ("the gap fixed at %.2f s (--gap-sd 0)" % args.gap)
    dagaz = ", the first Dagaz tick drawn over one period (class.dagaz.phase)" if dagaz_drawn else ""
    return ["SEEDS The MODEL P lines come from %d drawn runs, not from the median run above: clocks by rule draw.shape (%s),"
            " SSC delays and picks drawn (ssc.phi), the tree's pick %s, %s%s. An ALT value marked --median is the"
            " median run's only." % (args.seeds, getattr(args, "clock_draw", "quantiles"), pick, gap, dagaz)]


def no_channel_lines(rules, start_affs, result, model):
    """Afflictions of the run whose only cures are on the lungs or the elixir, which the engine does not run (review
    RUL-5). A random cure (the tree, a class cure) can take one in the model's random pool; nothing in the engine cures
    one outside it (review R3-fork-10: pressure has no_random_cure)."""
    seen = set(start_affs) | {ev["name"] for ev in result["events"] if ev["kind"] == "gain"}
    pool = set(model["lists"]["random"])
    random_ok, never = [], []
    for aff in sorted(seen):
        rule = rules["rules"].get("cure." + aff)
        if not rule:
            continue
        chans = [o["channel"] for o in rule["value"].get("options", [])]
        other = sorted({c for c in chans if c in ("lungs", "elixir")})
        if other and not any(c in ("eat", "smoke", "salve", "focus") for c in chans):
            (random_ok if aff in pool else never).append("%s (%s)" % (aff, " or ".join(other)))
    out = []
    if random_ok:
        out.append("NO CHANNEL %s: the engine runs no lungs or elixir channel, so only a random cure (the tree, a class"
                   " cure) can take them." % ", ".join(random_ok))
    if never:
        out.append("NO CHANNEL %s: the engine runs no lungs or elixir channel, and they are not in the random pool, so"
                   " nothing in the engine cures them." % ", ".join(never))
    return out


def horizon_lines(result, n_actions, horizon, t0):
    """A script the horizon cut (review LUA-N2-3). The run holds past the horizon until the eat that was down at the last
    action that ran comes back (fight.lua, review R3-engine-3), so only the script stops there (review R4-docs-7). With
    no eat down at that action, the run stops at the horizon (review R5: the clause printed on every cut)."""
    cut = result.get("notRun")
    if not cut:
        return []
    hold = result.get("hold")
    if cut >= n_actions:
        then = "No action ran before the horizon, so the run stops there."
    elif hold is not None and hold - t0 > horizon:
        then = "The run then holds to %+.2f, when the eat that was down at its last action comes back." % (hold - t0)
    else:
        then = "No eat that was down at its last action is still down at the horizon, so the run stops there."
    return ["HORIZON %d of the %d actions did not run: the script stops at the horizon, %.2f s after its start"
            " (--horizon). %s" % (cut, n_actions, horizon, then)]


def soft_rules(rules, used):
    """The rules a run rests on that are not MEASURED or READ, and the MEASURED rules that are not usable."""
    out = {"ASSUMED": [], "WIKI": [], "PLAYER": [], "SWEEP": []}
    for key in sorted(used):
        rule = rules["rules"].get(key)
        if not rule:
            continue
        if rule["tag"] in out:
            out[rule["tag"]].append(key)
        elif rule["tag"] == "MEASURED" and rule.get("usable") is False:
            out["SWEEP"].append(key)
    return out


# ---------------------------------------------------------------------------------------------
# Lua
# ---------------------------------------------------------------------------------------------


class Engine:
    """One Lua 5.1 runtime with the four files loaded and wired (one runtime: lupa refuses to mix two)."""

    def __init__(self):
        if lupa is None:
            raise SystemExit("theorycraft: needs lupa with Lua 5.1 (python -m pip install lupa)")
        self.lua = lupa.LuaRuntime(unpack_returned_tuples=True)
        mods = []
        for name in LUA_FILES:
            with open(os.path.join(SIM, name), encoding="utf-8") as fh:
                mods.append(self.lua.execute(fh.read()))
        forward, victim, attackers, fight = mods
        self.F = fight.wire(forward, victim, attackers)
        self.A = attackers
        self.V = victim
        self.R = forward

    def table(self, obj):
        return self.lua.table_from(obj, recursive=True)

    def script(self, lines, model_lua):
        # Lua returns the actions alone, or nil and the reason; lupa gives a tuple only for the second.
        got = self.A.script(self.table(list(lines)), model_lua)
        if isinstance(got, tuple):
            raise SystemExit("theorycraft: %s" % got[1])
        return got

    def run(self, start, script, model_lua, env, seed):
        out = self.F.run(self.table(start), script, model_lua, self.table(env), seed)
        return py(out)


def py(obj):
    """A Lua table as Python: a table with keys 1..n is a list, an empty table is a list, any other is a dict."""
    if lupa.lua_type(obj) != "table":
        return obj
    keys = list(obj.keys())
    if not keys:
        return []
    if all(isinstance(k, int) for k in keys) and sorted(keys) == list(range(1, len(keys) + 1)):
        return [py(obj[k]) for k in range(1, len(keys) + 1)]
    return {k: py(v) for k, v in obj.items()}


# ---------------------------------------------------------------------------------------------
# The timeline
# ---------------------------------------------------------------------------------------------

HEAD = "%7s %-3s %-30s %-28s %6s | %-6s %-6s %-6s %-6s %-6s %-6s %-6s %6s"


def rel(at, t0):
    return "%.2f" % (at - t0)


def phase_text(phase, down, places=2):
    """A PHASE with its sign. One that rounds to 0 takes its sign from down, as kb_events.signed does (review LUA-N2-10)."""
    if phase is None:
        return "-"
    if round(phase, places) == 0:
        return ("+" if down else "-") + "%.*f" % (places, 0.0)
    return "%+.*f" % (places, phase)


def cell(snap, ch, t0):
    why = snap["shut"].get(ch)
    if ch == "class" and why == "none":
        return "-"
    if why is False or why is None:
        return "up"
    if why == "clock":
        return rel(snap["ready"][ch], t0)
    return "x:" + ABBR.get(why, why[:3])


def group(events):
    """Rows: an action and the gains and losses it caused. Recovery lines and the other lines of one attack are not rows."""
    rows = []
    for ev in events:
        if ev.get("part") or ev["kind"] == "recover":
            continue
        if ev["kind"] in ("gain", "lose") and rows and rows[-1]["head"]["t"] == ev["t"] and \
                rows[-1]["head"]["kind"] in ("attack", "give", "cure", "classcure", "timed"):
            rows[-1]["parts"].append(ev)
            continue
        rows.append({"head": ev, "parts": []})
    return rows


WORDS = {"eat": "eat", "smoke": "smoke", "salve": "apply", "focus": "focus", "tree": "touch tree", "fitness": "FITNESS",
         "salt": "salt", "accelerate": "accelerate", "dagaz": "dagaz tick"}


def action_text(ev, model):
    kind, name = ev["kind"], ev["name"]
    if kind in ("attack", "give"):
        text = ev.get("text") or name
        result = ev.get("result")
        if result and result not in ("hit", "give"):
            text += " [%s]" % result
        return text
    if kind in ("cure", "classcure"):
        return ("%s %s" % (WORDS.get(name, name), ev.get("item") or "")).strip()
    if kind == "label":
        return "LABEL %s %s" % (name, ev["args"][0])
    if kind == "timed":
        return "%s chain" % name
    return name


def change_text(row):
    out = []
    for ev in row["parts"]:
        out.append(("+" if ev["kind"] == "gain" else "-") + ev["name"])
    return " ".join(out)


def timeline(result, model, t0, cls_label):
    lines = [HEAD % ("t", "who", "action", "change", "A", "V eat", "smk", "slv", "foc", "tree", cls_label, "DGZ", "PHASE")]
    for row in group(result["events"]):
        ev = row["head"]
        snap = (row["parts"][-1] if row["parts"] else ev)["snap"]
        phase = ""
        if ev["kind"] == "attack" and ev.get("action") == "dstab":
            phase = phase_text(ev.get("phase"), ev.get("down"))
        # The A column: when the attacker acts next. An attack or a give carries its own drawn time; the snapshot is
        # taken before the action sets it (review LUA-N2-11). 0.0 is a time: `0.0 in (False, None)` is True in Python.
        nxt = ev.get("next") if ev["kind"] in ("attack", "give") else snap["act"]
        act = rel(nxt, t0) if nxt is not None and nxt is not False else "-"
        dgz = rel(snap["dagaz"], t0) if snap["dagaz"] is not False else "-"
        lines.append(HEAD % ("%.2f" % (ev["t"] - t0), ev["side"], action_text(ev, model)[:30], change_text(row)[:28], act,
                             cell(snap, "eat", t0), cell(snap, "smoke", t0), cell(snap, "salve", t0),
                             cell(snap, "focus", t0), cell(snap, "tree", t0), cell(snap, "class", t0), dgz, phase))
    return lines


# ---------------------------------------------------------------------------------------------
# The races
# ---------------------------------------------------------------------------------------------


def cut_attack(result, actions):
    """True when the horizon cut an attack (a DSTAB, BITE or FLAY) from the script, not only a wait or a give."""
    cut = result.get("notRun") or 0
    return any(a.split()[0].lower() in ("dstab", "bite", "flay") for a in actions[len(actions) - cut:] if a.split())


def lua_races(result):
    """The engine's races (fight.lua F.races) as display rows, labelled by the actions' numbers in the script."""
    return [{"label": "%d->%s" % (r["from"], r.get("to", "-")), "t": r["t"], "gap": r.get("gap"), "phase": r.get("phase"),
             "down": r.get("down"), "winner": r.get("winner"), "by": r.get("by")} for r in result["races"]]


def race_lines(races, t0, probs=None, delay=(0.10, 0.18), cut=False, gap_drawn=True):
    """probs: (counts, seeds) from race_probs. cut: the horizon cut an attack from the script (cut_attack), so the last
    race has no next attack for that reason. gap_drawn: the drawn runs drew the gap (--gap-sd above 0)."""
    out = []
    for k, race in enumerate(races):
        if race.get("phase") is not None:
            phase = "PHASE %s at the strike" % phase_text(race["phase"], race.get("down"))
        else:
            phase = "no PHASE: no eat clock known at the strike"
        if race.get("winner") is None:
            # The horizon cut only the next attack of the last race (review R3-engine-4). A cut wait or give is no
            # attack, so the race is unpaired for its own reason (review R5-cli-3).
            if race.get("gap") is None and cut and k == len(races) - 1:
                why = "unpaired: the horizon cut the script before another attack ran"
            elif race.get("gap") is None:
                why = "unpaired: no attack after it within %.0f s" % kb.DISENGAGED
            elif race["gap"] >= kb.DISENGAGED:
                why = "unpaired: the next attack came %.2f s later (disengaged)" % race["gap"]
            else:
                why = "unpaired: no eat clock at the next attack (no eat spent yet)"
            out.append("RACE %s  %s (%s)." % (race["label"], why, phase))
        else:
            t_next = race["t"] + race["gap"] - t0
            if race["winner"] == "herb":
                text = "herb back %.2f < strike %.2f: herb first by %.2f" % (t_next - race["by"], t_next, race["by"])
            else:
                text = "strike %.2f < herb back %.2f: strike first by %.2f" % (t_next, t_next + race["by"], race["by"])
            out.append("RACE %s  %s (%s)." % (race["label"], text, phase))
        if probs is not None:
            counts, seeds = probs
            seen, paired, strike = counts.get(race["label"], (0, 0, 0))
            if paired:
                out.append("           MODEL P(strike first) = %.2f (%d of %d paired seeds; the race %s is in %d of %d"
                           " seeds; eat draw, SSC delay %.2f-%.2f, %s)." % (
                               strike / paired, strike, paired, race["label"], seen, seeds, delay[0], delay[1],
                               "gap draw" if gap_drawn else "gap fixed"))
            else:
                out.append("           MODEL: the race %s is in %d of %d seeds, paired in none." % (race["label"], seen,
                                                                                                      seeds))
    return out


def race_probs(races_of, seeds, seed0):
    """For each race, by its label (from->to): seeds in which it is run, seeds in which it is paired, and seeds in which
    the strike came first. A race is keyed by its label, not by its place in the list: a shield that blocks a different
    DSTAB in another seed moves every later race up the list (review N2-4, LUA-N2-2)."""
    counts = {}
    for i in range(seeds):
        for race in races_of(seed0 + i):
            c = counts.setdefault(race["label"], [0, 0, 0])
            c[0] += 1
            if race.get("winner"):
                c[1] += 1
                c[2] += race["winner"] == "strike"
    return counts, seeds


def log_race_line():
    with open(ke.OUT_JSON, encoding="utf-8") as fh:
        data = json.load(fh)
    s = data["race_summary"]["all"]
    g = data["golden"]["row"]
    return ["LOGS  strike first %d of %d paired DSTABs (%.0f%%) in the four Serpent logs: THEIR curing, not ours"
            " (kb/sim/events.md)." % (s["strike_first"], s["paired"], 100.0 * s["strike_first"] / s["paired"]),
            "      Anchor Z5 row %d: PHASE %+.3f at the strike, %s first by %.3f s." % (g["row"], g["phase"], g["winner"],
                                                                                    g["by"])]


# ---------------------------------------------------------------------------------------------
# The notes under a run
# ---------------------------------------------------------------------------------------------


def tree_lines(result, gaps, t0):
    out = []
    for ev in result["events"]:
        if ev["kind"] == "cure" and ev["name"] == "tree":
            back = ev["snap"]["ready"]["tree"]
            span = back - ev["t"]
            counts = ", ".join("%d strikes at %.3f s" % (int(span // g), g) for g in gaps)
            out.append("TREE  down %.2f-%.2f: %s. A window is not a cause (foundations.md:189-190)." % (
                ev["t"] - t0, back - t0, counts))
    return out


def class_lines(rules, model, prof, dagaz_note):
    cc = model["classcure"]
    out = []
    if cc:
        rule = rules["rules"][CLASS_LOCKOUT[cc["kind"]]]
        if rule["tag"] == "MEASURED" and not rule.get("usable"):
            note = "n=%d, not usable: swept %.2f-%.2f" % (rule["n"], rule["alt"][0], rule["alt"][-1])
        elif rule["tag"] == "ASSUMED":
            note = "ASSUMED: swept %s" % ", ".join("%.1f" % a for a in rule["alt"])
        else:
            note = "usable"
        spend = ""
        if cc.get("spends_eq"):
            spend = " It spends %.2f s of equilibrium." % cc["spends_eq"]
        elif cc.get("spends_bal"):
            spend = " It spends %.2f s of balance." % cc["spends_bal"]
        count = " It takes %d afflictions (rule class.accelerate.cures)." % cc["count"] if cc.get("count", 1) > 1 else ""
        out.append("%-5s lockout %.2f is %s. %s shuts it.%s%s" % (CLASS_LABEL[cc["kind"]], cc["lockout"]["median"], note,
                                                                 " or ".join(cc["blocked_by"]).capitalize(), spend, count))
    if model["dagaz"]:
        out.append("DGZ   Dagaz ticks every %.2f s (not usable: swept); voyria first. %s" % (model["dagaz"]["period"]["median"],
                                                                                      dagaz_note))
    if model["labelBlocker"] is None:
        out.append("LABEL %s has no class-cure blocker in ACTIVE_CURE_BLOCKERS, so the true label counts its class cure as"
                   " shut." % prof["cls"])
    return out


def label_line(result, t0):
    def when(at):
        return "at %.2f" % (at - t0) if at is not None else "never"
    return "LABELS soft %s, true %s (kb_replay.is_true)." % (when(result.get("softAt")), when(result.get("trueAt")))


def assumed_lines(rules, used, median, alts, seeds=0, gap_sd=None):
    soft = soft_rules(rules, used)
    out = []
    for tag in ("ASSUMED", "WIKI", "PLAYER"):
        out.append("%-7s used: %s." % (tag, ", ".join(soft[tag]) or "none"))
    # Another Serpent's gap gives the median only: a draw adds the gap's own noise (rule attack.gap.own.sd), not that
    # rule's p10-p90 spread (review R3-fork-4).
    gaps = [k for k in soft["SWEEP"] if k.startswith("attack.gap.others.")]
    sweep = [k for k in soft["SWEEP"] if k not in gaps]
    # Review LUA-N2-8: a run without --median draws these clocks over their measured spread.
    if not median:
        how = "drawn over the measured spread"
    elif seeds:
        how = "the median ran; the P lines drew them over the measured spread"
    else:
        how = "the median ran"
    out.append("SWEEP   (MEASURED, not usable; %s): %s." % (how, ", ".join(sweep) or "none"))
    for key in gaps:
        median_gap = rules["rules"][key]["value"]["median"]
        noise = ("no noise" if (median and not seeds) or not gap_sd else
                 "a draw adds +/- 3 x %.2f s (--gap-sd, rule attack.gap.own.sd)" % gap_sd)
        out.append("GAP     %s (MEASURED, not usable): its median %.2f only, not its p10-p90 spread; %s." % (
            key, median_gap, noise))
    # Only a rule the run used: --flay-order auto with no FLAY ran nothing (review RUL-6 residual).
    out.append("ALT     (the rule's alternative ran): %s." % (
        "; ".join("%s = %s" % (k, alts[k]) for k in sorted(alts) if k in used) or "none"))
    return out


# ---------------------------------------------------------------------------------------------
# Scripted runs
# ---------------------------------------------------------------------------------------------


def env_for(args, gap, median, defences, snap=True):
    return {"median": median, "clockDraw": getattr(args, "clock_draw", "quantiles"), "gap": gap,
            "gapSd": 0 if median else args.gap_sd, "gapFloor": args.gap_floor,
            "defences": {"shield": "shield" in defences, "rebounding": "rebounding" in defences},
            "tree": args.tree, "treePick": args.tree_pick, "tail": args.tail, "horizon": args.horizon, "snap": snap}


def defence_rules(model, defences, used):
    """The rules a kept defence rests on: the shield's cost and re-raise only when the victim keeps a shield (review
    N2-11), and the rebounding clock only when it keeps rebounding."""
    if "shield" in defences:
        used.update(model["shieldKeys"] + ["attack.shield"])
    if "rebounding" in defences:
        used.update(("attack.rebounding", "defence.rebounding.delay", "clock.rebounding", "defence.rebounding.smoke"))


def scripted(args):
    if args.gap is None:
        raise SystemExit("theorycraft: our own DSTAB gap is not measured (rule attack.gap.own). Give --gap; other Serpents:"
                         " median 1.83, p10 1.73, min 1.545 (kb/mechanics/clocks.json).")
    rules = load_rules()
    prof = profile(args.victim)
    model, used = build_model(rules, prof, options(args))
    used.add("attack.gap.own")
    alts = options_used(args, used)
    defence_rules(model, args.defences, used)
    engine = Engine()
    model_lua = engine.table(model)
    script = engine.script(args.script, model_lua)
    # The victim keeps the defences it is given: they are up at the start.
    start = {"t0": 0.0, "affs": args.affs, "firstAt": 0.0,
             "defs": {"shield": "shield" in args.defences, "rebounding": "rebounding" in args.defences}}
    env = env_for(args, args.gap, args.median, args.defences)
    result = engine.run(start, script, model_lua, env, args.seed)
    # The rules of the actions that ran: an action the horizon cut rests on nothing (review LUA-N2-3).
    rules_for_actions(rules, args.script[:len(args.script) - (result.get("notRun") or 0)], args.affs, used)
    if model["dagaz"] and args.median:
        alts["class.dagaz.phase"] = "half a period (--median)"
    lines = header(args, rules, prof, model)
    cls_label = CLASS_LABEL.get(model["classcure"]["kind"], "CLS") if model["classcure"] else "CLS"
    lines += timeline(result, model, 0.0, cls_label)
    probs = None
    if args.seeds:
        env_n = env_for(args, args.gap, False, args.defences, snap=False)
        probs = race_probs(lambda seed: lua_races(engine.run(start, script, model_lua, env_n, seed)), args.seeds, args.seed)
    lines += race_lines(lua_races(result), 0.0, probs, (model["ssc"]["min"], model["ssc"]["max"]),
                        cut=cut_attack(result, args.script), gap_drawn=args.gap_sd > 0)
    lines += horizon_lines(result, len(args.script), args.horizon, 0.0)
    lines += log_race_line()
    lines += tree_lines(result, sorted({args.gap, 1.545}, reverse=True), 0.0)
    dagaz_note = "Its first tick is at half a period (--median)." if args.median else \
        "Its first tick is drawn over one period (rule class.dagaz.phase)."
    lines += class_lines(rules, model, prof, dagaz_note)
    lines += no_channel_lines(rules, args.affs, result, model)
    lines += seeds_lines(args, bool(model["dagaz"]))
    lines += assumed_lines(rules, used, args.median, alts, args.seeds, args.gap_sd)
    lines.append(label_line(result, 0.0))
    if args.jsonl:
        write_jsonl(args.jsonl, result["events"])
    return lines


def header(args, rules, prof, model):
    out = ["MODEL, NOT A LOG. Freeze %s, rules %s." % (rules["freeze_sha256"][:12], file_sha(RULES)[:12])]
    if args.median:
        out.append("ILLUSTRATIVE: clocks.json medians, no noise, top-priority picks.")
    else:
        out.append("ONE DRAW: seed %d. Clocks, SSC delays and picks are drawn; %s." % (
            args.seed, "the gap too" if args.gap_sd > 0 else "the gap is fixed at %.2f s (--gap-sd 0)" % args.gap))
    gap = args.gap
    if abs(gap - 1.83) < 1e-9:
        out.append("DSTAB 1.83 = other Serpents' median (n=195). Ours is unmeasured until the spar.")
    else:
        out.append("DSTAB %.3f from --gap (rule attack.gap.own, ASSUMED). Other Serpents: median 1.83, p10 1.73, min 1.545"
                   " (n=195)." % gap)
    eat = model["clocks"]["eat"]["median"]
    out.append("VICTIM %s: eat clock %.3f (%s), SSC delay %.2f (%.2f-%.2f)." % (
        prof["cls"], eat, ("logger %s" % prof["logger"]) if prof["logger"] else "pooled, not usable",
        model["ssc"]["median"], model["ssc"]["min"], model["ssc"]["max"]))
    return out


def write_jsonl(path, events):
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        for ev in events:
            fh.write(json.dumps(clean(ev), sort_keys=True) + "\n")


def clean(ev):
    out = {}
    for k, v in ev.items():
        if k == "snap":
            continue
        if isinstance(v, float):
            v = round(v, 6)
        out[k] = v
    return out


# ---------------------------------------------------------------------------------------------
# A real log, in the engine's columns
# ---------------------------------------------------------------------------------------------

LOG_CHANNEL = {"eat": "eat", "smoke": "smoke", "salve": "salve", "focus": "focus", "tree": "tree", "fitness": "class",
               "salt": "class", "accelerate": "class"}
LOG_BLOCKED = {"eat": "anorexia", "salve": "slickness", "smoke": "asthma", "focus": "impatience", "tree": "paralysis"}

# Board tokens the lock table (kb_replay.TOKENS) and kb_sim.EXTRA_TOKENS leave out, and the limb names the engine uses.
FORK_TOKENS = {"disl": "disloyalty", "VOY": "voyria", "VOYR": "voyria", "DISR": "disrupted", "PSHOT": "pinshot",
               "pinshot": "pinshot", "hmrc": "homunculusmercury"}
LIMB_NAMES = {"leftleg1": "brokenleftleg", "rightleg1": "brokenrightleg", "leftarm1": "brokenleftarm",
              "rightarm1": "brokenrightarm", "leftleg2": "damagedleftleg", "rightleg2": "damagedrightleg",
              "leftarm2": "damagedleftarm", "rightarm2": "damagedrightarm"}
NOT_AFFLICTIONS = ("SOFTLOCKED", "TRUELOCKED")


def board(family, tokens):
    """(afflictions, unknown tokens) of one prompt's board, in the engine's names. The lock tokens come from
    kb_replay.TOKENS, the rest from kb_sim.EXTRA_TOKENS and FORK_TOKENS. The lock table alone dropped hypochondria,
    darkshade, nausea and others (review TC-03). A token no table names is returned, so the page can show it."""
    terms, _, _ = rp.read_terms(family, tokens)
    names = {LIMB_NAMES.get(t, t) for t in (terms or set())}
    lock = rp.TOKENS.get(family, {})
    extra = dict(ks.EXTRA_TOKENS.get(family, {}), **FORK_TOKENS)
    unknown = []
    for tok in tokens or []:
        if tok in extra:
            names.add(extra[tok])
        elif tok not in lock and tok not in NOT_AFFLICTIONS and not rp.BLEED_TOKEN.match(tok) \
                and not rp.PRESSURE_TOKEN.match(tok):
            unknown.append(tok)
    return names, unknown


def channel_of(ev):
    if ev["kind"] not in ("cure", "classcure"):
        return None
    if ev["name"] == "eat":
        return {"eat": "eat", "smoke": "smoke"}.get(ev["args"][0])
    return LOG_CHANNEL.get(ev["name"])


def intervals(events):
    """channel -> list of (start event, its recovery event or None)."""
    out = {}
    for k, ev in enumerate(events):
        ch = channel_of(ev)
        if not ch:
            continue
        back = None
        names = {"class": (ev["name"],)}.get(ch, (ch,))
        for later in events[k + 1:]:
            if later["kind"] == "recover" and later["name"] in names:
                back = later
                break
            if channel_of(later) == ch:
                break
        out.setdefault(ch, []).append((ev, back))
    return out


def state_at(spans, ch, row):
    """The span of `ch` that is down at `row`: (start, back) or None."""
    for start, back in reversed(spans.get(ch, [])):
        if start["row"] <= row:
            if back is None or back["row"] > row:
                return start, back
            return None
    return None


def last_back(spans, ch, row):
    """The last recovery of `ch` at or before `row`, or None."""
    for start, back in reversed(spans.get(ch, [])):
        if back is not None and back["row"] <= row:
            return back
    return None


def log_view(args):
    key = args.log
    log = ke.load(key)
    events = ke.stream(log)
    spans = intervals(events)
    races = {(r["src"], r["row"]): r for r in ke.race(log, events)}
    first = [ev for ev in events if ev["row"] >= args.start]
    if not first:
        raise SystemExit("theorycraft: no event at or after row %d" % args.start)
    t0 = first[0]["t"]
    cls_label = {"az": "FIT", "Z5": "SALT", "g": "FIT", "X": "ACC"}[key]
    out = ["THE LOG %s (%s), from row %d. Times from row %d's stamp; a channel shows the time its recovery line came." % (
        key, os.path.basename(ke.log_path(key)), args.start, first[0]["row"]),
           "The board is the logger's own belief, not the truth. PHASE is the race table's (kb/sim/events.md).",
           "%5s %7s %-3s %-28s %-36s | %-6s %-6s %-6s %-6s %-6s %-6s %6s  %s" % (
               "row", "t", "who", "action", "change", "V eat", "smk", "slv", "foc", "tree", cls_label, "PHASE", "board")]
    terms = set()
    for ev in events:
        if ev["kind"] == "prompt" and ev["row"] < args.start:
            terms = board(log.family, ev["args"])[0]
    shown, late = 0, False
    for row in group_log(first):
        ev = row["head"]
        if args.to and ev["row"] > args.to:
            break
        if ev["kind"] == "prompt":
            terms = board(log.family, ev["args"])[0]
            continue
        for part in row["parts"]:
            if "|" in part["name"]:
                continue
            if part["kind"] == "gain":
                terms.add(part["name"])
            else:
                terms.discard(part["name"])
        cells = []
        for ch in CHANNELS:
            blocked = LOG_BLOCKED.get(ch)
            span = state_at(spans, ch, ev["row"])
            if span:
                start, back = span
                cells.append(("%.2f" % (back["t"] - t0)) if back else "dn")
            elif blocked and blocked in terms:
                cells.append("x:" + ABBR[blocked])
            else:
                cells.append("up")
        race = races.get((key, ev["row"])) if ev["name"] == "dstab" else None
        phase = ke.signed(race["phase"], race["down"]) if race and race["phase"] is not None else ""
        act = log_action(ev)
        # A row after the log's last prompt has no stamp of its own: its time is the last prompt's, a floor (review EV-3).
        when = ("%.2f" % (ev["t"] - t0)) if not ev.get("late") else (">=%.2f" % (ev["t"] - t0))
        late = late or bool(ev.get("late"))
        out.append("%5d %7s %-3s %-28s %-36s | %-6s %-6s %-6s %-6s %-6s %-6s %6s  %s" % (
            ev["row"], when, ev["side"], act[:28], change_text(row)[:36], *cells, phase,
            " ".join(sorted(ABBR.get(x, x[:4]) for x in terms))))
        shown += 1
        if not args.to and shown >= args.rows:
            break
    if late:
        out.append("A time with >= is a floor: the row comes after the log's last prompt, so it has that prompt's stamp"
                   " (kb_events 'late').")
    return out


def group_log(events):
    rows = []
    for ev in events:
        if ev["kind"] in ("gain", "lose") and rows and rows[-1]["head"]["kind"] not in ("prompt",):
            rows[-1]["parts"].append(ev)
            continue
        # The game's cost lines ("Equilibrium used") are not actions: the fork reads them for the victim's clocks.
        if ev["kind"] in ("recover", "attack.part", "spend"):
            continue
        if ev["kind"] in ("gain", "lose"):
            rows.append({"head": dict(ev, kind="line", name="(line)"), "parts": [ev]})
            continue
        rows.append({"head": ev, "parts": []})
    return rows


def log_action(ev):
    if ev["kind"] == "cure" and ev["name"] == "eat":
        return "eat %s" % ev["args"][1]
    if ev["kind"] == "cure" and ev["name"] == "salve":
        return "apply to %s" % ev["args"][0]
    return ev["name"]


# ---------------------------------------------------------------------------------------------
# A fork from a real row
# ---------------------------------------------------------------------------------------------


# The last line that proves a defence up or down. A prick line proves the shield down: a shield prints its own block
# line instead (g row 24). A prick with no rebound line in its packet proves rebounding down (g rows 1527-1530). Both
# rebound lines prove it up: "The attack rebounds back onto <name>!" and "The attack rebounds off your aura of
# protection!" (X 713-716; review N2-7). The coating is up at the hardening line (az 1466; quicksilver: X 2345) and at a
# pet's bite that meets it (X 38-39: "its fangs sinking into the waxy coating"; review R3-fork-9), and down at a line that
# strips or dissolves it, or at a bite that lands (a pet's or the Serpent's: the coating blocks both).
SHIELD_UP, SHIELD_DOWN = ("shield.up", "blocked.shield"), ("flay.shield", "shield.down", "dstab", "dstab.miss", "bite")
REB_LINES = ("rebounded", "rebounded.aura")
REB_UP, REB_DOWN = ("rebounding.up",) + REB_LINES, ("flay.rebounding", "rebounding.down")
SILERIS_UP, SILERIS_DOWN = ("sileris.up", "snake.blocked"), ("sileris.down", "snake.hit", "bite")
# The victim's own balance and equilibrium: the cost line's name, the recovery's name, and the place in the prompt flags
# (kb_replay.prompt_balances).
OWN = (("bal", 0, "balance"), ("eq", 1, "equilibrium"))
# A fork with no --gap: other Serpents' median DSTAB gap (rule attack.gap.others.dstab).
FORK_GAP = 1.83


def defences_at(upto):
    state = {"shield": (False, None), "rebounding": (False, None), "sileris": (False, None)}
    for k, ev in enumerate(upto):
        name = ev["name"]
        if name in SHIELD_UP:
            state["shield"] = (True, ev["row"])
        elif name in SHIELD_DOWN:
            state["shield"] = (False, ev["row"])
        if name in REB_UP:
            state["rebounding"] = (True, ev["row"])
        elif name in REB_DOWN:
            state["rebounding"] = (False, ev["row"])
        elif name == "dstab":
            packet = [e for e in upto[k + 1:] if e["t"] == ev["t"]]
            if not any(e["name"] in REB_LINES for e in packet):
                state["rebounding"] = (False, ev["row"])
        if name in SILERIS_UP:
            state["sileris"] = (True, ev["row"])
        elif name in SILERIS_DOWN:
            state["sileris"] = (False, ev["row"])
    return {k: v[0] for k, v in state.items()}, {k: v[1] for k, v in state.items()}


def is_rebounding_smoke(ev, items):
    return ev["kind"] == "cure" and ev["name"] == "smoke" and bool(ev["args"]) and ev["args"][0] in items


def kept_defences(upto, items):
    """The defences this logger keeps: those the log shows up, or on their way, by the row (review LUA-N2-5). The fork's
    victim raises them again, as the logger did. A defence the log never showed is not kept."""
    kept = []
    if any(ev["name"] in SHIELD_UP for ev in upto):
        kept.append("shield")
    if any(ev["name"] in REB_UP or is_rebounding_smoke(ev, items) for ev in upto):
        kept.append("rebounding")
    return kept


def tail_hi(c, draw="quantiles"):
    """The highest draw of a clock under the draw's shape (victim.lua V.tails and V.clockAfter, rule draw.shape)."""
    if draw != "normal" and "p10" in c and "p90" in c and "max" in c:
        return min(c["max"], c["p90"] + (c["p90"] - c["p10"]))
    top = c["median"] + 3 * c.get("sd", 0)
    return min(c["max"], top) if "max" in c else top


def pending_defences(upto, items, t0, model, draw="quantiles"):
    """The log's FLAY of the shield, its smoke for rebounding and its apply of the coating that have not come back by the
    row: (shield event, rebounding event, coating event), each None when nothing is on its way. One older than its clock's
    highest draw never came back in the log, so the engine does not count it (7 of 26 FLAYs of the shield saw no shield
    within 20 s: rule defence.shield.reraise).

    Only a FLAY starts the shield's re-raise. "shield.down" is the logger's own movement or action dropping its shield
    (all 10 in the four logs), not a FLAY, and the rule is measured from a FLAY (review R3-fork-2)."""
    shield = reb = coat = None
    for ev in upto:
        if ev["name"] == "flay.shield":
            shield = ev
        elif ev["name"] in SHIELD_UP:
            shield = None
        if is_rebounding_smoke(ev, items):
            reb = ev
        elif ev["name"] in REB_UP:
            reb = None
        if ev["name"] == "sileris.apply":
            coat = ev
        elif ev["name"] in SILERIS_UP or ev["name"] == "sileris.down":
            coat = None
    if shield is not None and t0 - shield["t"] > tail_hi(model["shield"]["reraise"], draw):
        shield = None
    if reb is not None and t0 - reb["t"] > tail_hi(model["clocks"]["rebounding"], draw):
        reb = None
    if coat is not None and t0 - coat["t"] > tail_hi(model["sileris"]["harden"], draw):
        coat = None
    return shield, reb, coat


def impulse_in_packet(events, i):
    """True when an impulse line comes before event i in its packet (X 574, before the X 575 cost line)."""
    for ev in reversed(events[:i]):
        if ev["kind"] == "prompt":
            return False
        if ev["name"] == "impulse.fired":
            return True
    return False


def own_clocks(log, events, end_row, board_row, t0):
    """The victim's balance and equilibrium at the row (reviews RUL-1, N2-3, LUA-N2-4): {name: (back, how)} for each one
    that is down. The prompt's flags decide up or down when the log prints them (Z5, g and X; az prints none). The time
    comes from the game's own cost lines ("Equilibrium used: 3.40s.", X 4366) when one is open, else from the log's next
    recovery line: a cost spent before the row comes back when it comes back, whatever the attacker does after it.

    A cost line that lands while an earlier one is open ENDS it, and only its own cost counts (review R4-fork-1). In the
    four logs, 5 of the 6 overlaps are like this: a CONCENTRATE after disrupted (az 2995: back at 3034, 0.03 s from its
    own 2.00 s; Z5 4970: 0.11 s from its own 1.70 s), and three g balance costs whose return the stream does not read
    (the Shikudo prints one line per limb, g 788-790). The exception is the impulse: its cost line follows "Your
    equilibrium is thrown off" in the same packet and ADDS to the open cost (X 529 + X 575 back at X 638, 0.05 s from the
    sum). A prompt that shows the flag down outranks a cost that ran out, and the log's next recovery line gives the
    return. A down flag with no line that gives its return (Z5 5468-5590: disrupted, then death) keeps it down: back is
    inf (review RUL-1 residual)."""
    text = None
    if board_row is not None:
        text = next((row.text for row in log if row.kind == "prompt" and row.n + 1 == board_row), None)
    flags = rp.prompt_balances(log.family, text) if text else (None, None)
    out = {}
    for name, idx, word in OWN:
        flag = flags[idx]
        end, spent, opened = None, [], None
        for i, ev in enumerate(events):
            if ev["row"] > end_row:
                break
            if ev["name"] == name + ".used":
                cost = float(ev["args"][0])
                if end is not None and ev["t"] < end and impulse_in_packet(events, i):
                    end += cost
                    spent.append("%.2f s at row %d after an impulse, added" % (cost, ev["row"]))
                elif end is not None and ev["t"] < end:
                    end = ev["t"] + cost
                    spent = ["%.2f s at row %d, which ends the open cost of row %d" % (cost, ev["row"], opened)]
                    opened = ev["row"]
                else:
                    end, spent, opened = ev["t"] + cost, ["%.2f s at row %d" % (cost, ev["row"])], ev["row"]
            elif ev["kind"] == "recover" and ev["name"] == name:
                end, spent, opened = None, [], None
        if flag is True:
            continue
        lines = "the game's cost line" + ("s" if len(spent) > 1 else "")
        if end is not None and (end > t0 or flag is None):
            out[name] = (end, "%s spent %s (%s)" % (word, " and ".join(spent), lines))
            continue
        if flag is not False:
            continue
        back = next((ev for ev in events if ev["row"] > end_row and ev["kind"] == "recover" and ev["name"] == name
                     and not ev.get("late")), None)
        why = ("its cost line ran out (%s)" % " and ".join(spent)) if end is not None else "no cost line"
        if back is not None:
            out[name] = (back["t"], "%s down at prompt row %d with %s: back at the log's own recovery line, row %d" % (
                word, board_row, why, back["row"]))
        else:
            out[name] = (float("inf"), "%s down at prompt row %d with %s, and no later line gives its return" % (
                word, board_row, why))
    return out


def fork(args):
    own_gap = args.gap is not None
    if not own_gap:
        args.gap = FORK_GAP
        gap_note = "DSTAB gap 1.83 = other Serpents' median (n=195): the fork's attacker is another Serpent."
    else:
        gap_note = "DSTAB gap %.3f from --gap." % args.gap
    key = args.log
    rules = load_rules()
    prof = profile(LOG_VICTIM[key])
    model, used = build_model(rules, prof, options(args))
    # The gap the fork rests on (review N2-10, RUL-7): ours, ASSUMED, or the other Serpents', MEASURED and not usable.
    used.add("attack.gap.own" if own_gap else "attack.gap.others.dstab")
    alts = options_used(args, used)
    log = ke.load(key)
    events = ke.stream(log)
    at = args.at
    # A wrapped prompt spans two or more physical rows (kb_timing Row.span), and its event carries the first one. A later
    # row is the prompt's own row, not a line of the next packet (review R5-fork-1: X 590 is the board row of prompt 589).
    span_note = ""
    for row in log:
        if row.kind == "prompt" and row.n + 1 < at <= row.n + row.span:
            span_note = " Row %d is a later row of prompt row %d." % (at, row.n + 1)
            at = row.n + 1
            break
    upto = [ev for ev in events if ev["row"] <= at]
    if not upto:
        raise SystemExit("theorycraft: row %d is before the first event" % at)
    # A row is in the packet that ends at the next prompt, and it has that prompt's stamp (kb_timing's one stamp rule).
    # Unless the row is a prompt, the fork starts at the packet's end, so the afflictions of a DSTAB at the row are on the
    # board (review TC-12). That holds for a row with no event too: its stamp is the next prompt's.
    end_row = at
    if not (upto[-1]["kind"] == "prompt" and upto[-1]["row"] == at):
        for ev in events:
            if ev["row"] > at:
                upto.append(ev)
                if ev["kind"] == "prompt":
                    break
        end_row = upto[-1]["row"]
    # A row after the log's last prompt has no stamp of its own, and the death line is there (review R3-fork-7). A row
    # with no event after it (X 6625, past the end of a file) has no prompt to close its packet (review R4-fork-2).
    if upto[-1]["kind"] != "prompt" or end_row < at or any(ev["kind"] == "death" for ev in upto):
        last = [ev["row"] for ev in events if ev["kind"] == "prompt" and not any(
            d["kind"] == "death" and d["row"] <= ev["row"] for d in events)]
        raise SystemExit("theorycraft: row %d is after the log's last prompt (row %d) or its death line: a fork needs a"
                         " prompt's stamp and a live victim. Fork at row %d or before." % (at, last[-1], last[-1]))
    t0 = upto[-1]["t"]
    # The board: the last prompt at or before the end, then the gain and cure lines after it.
    prompts = [ev for ev in upto if ev["kind"] == "prompt"]
    terms, unknown = board(log.family, prompts[-1]["args"]) if prompts else (set(), [])
    board_row = prompts[-1]["row"] if prompts else None
    for ev in upto:
        if board_row is not None and ev["row"] > board_row and ev["kind"] in ("gain", "lose") and "|" not in ev["name"]:
            (terms.add if ev["kind"] == "gain" else terms.discard)(ev["name"])
    # The clocks. A channel down at the row comes back one model clock after the log spent it, drawn from the part of the
    # clock above the time already run (fight.lua start.downFrom, victim.lua V.clockAfter): never before t0, since the log
    # has not printed its recovery line (review TC-04). One whose longest draw has run out comes back at t0, with its
    # line, so a race over the log and the run sees the eat come back (review LUA-N2-6). A channel up at the row keeps
    # its last recovery time, so a race's PHASE counts from it (review TC-09).
    spans = intervals(events)
    ready, down_from, down_at_start, own_notes = {}, {}, {}, []
    for ch in CHANNELS:
        if ch == "class" and not model["classcure"]:
            continue
        span = state_at(spans, ch, end_row)
        if span:
            down_from[ch] = span[0]
        else:
            last = last_back(spans, ch, end_row)
            if last is not None:
                ready[ch] = last["t"]
    for name, (back, how) in sorted(own_clocks(log, events, end_row, board_row, t0).items()):
        if back == float("inf"):
            own_notes.append("%s: the fork keeps it down" % how)
        elif back <= t0:
            own_notes.append("%s; it comes back at +0.00" % how)
            back = t0
            down_at_start[name] = True
        else:
            own_notes.append("%s: back at %+.2f" % (how, back - t0))
        ready[name] = back
    defs, proof = defences_at(upto)
    items = value(rules, "defence.rebounding.smoke")
    kept = kept_defences(upto, items)
    shield_ev, reb_ev, coat_ev = pending_defences(upto, items, t0, model, args.clock_draw)
    hits = ke.attacks(upto)
    last_hit = hits[-1] if hits else None
    start = {"t0": t0, "affs": sorted(terms), "ready": ready, "defs": defs, "downAtStart": down_at_start,
             "downFrom": {ch: ev["t"] for ch, ev in down_from.items()}}
    if last_hit is not None:
        start["firstFrom"] = last_hit["t"]
    else:
        start["firstAt"] = t0
    pending = []
    if shield_ev is not None and "shield" in kept and not defs["shield"]:
        start["shieldFrom"] = shield_ev["t"]
        pending.append("the shield comes back one re-raise delay after the FLAY at row %d (%+.2f)" % (
            shield_ev["row"], shield_ev["t"] - t0))
    if reb_ev is not None and not defs["rebounding"]:
        start["reboundingFrom"] = reb_ev["t"]
        used.add("defence.rebounding.smoke")
        pending.append("rebounding comes up one clock.rebounding after the %s smoke at row %d (%+.2f)" % (
            reb_ev["args"][0], reb_ev["row"], reb_ev["t"] - t0))
    if coat_ev is not None and not defs["sileris"]:
        # The log's apply with no hardening line yet: the coating is on its way (review R3-fork-8).
        start["silerisFrom"] = coat_ev["t"]
        used.add("defence.sileris.harden")
        pending.append("the coating hardens one defence.sileris.harden after the apply at row %d (%+.2f), unless"
                       " slickness is on at that mark (rule defence.sileris.slickness_harden%s)" % (
                           coat_ev["row"], coat_ev["t"] - t0, "; slickness is on the board" if "slickness" in terms else ""))
    if args.median and (start["downFrom"] or "shieldFrom" in start or "reboundingFrom" in start
                        or "silerisFrom" in start):
        # A --median fork takes the median of the part of a running clock above the time already run, and the shape
        # sets that part (review R3-engine-2).
        shape_used(args, used, alts)
    # A kept shield that is down with no FLAY on its way never comes back in the run, so its rules are not used.
    defence_rules(model, [d for d in kept if d != "shield" or defs["shield"] or "shieldFrom" in start], used)
    dagaz_note, dagaz_drawn = "", bool(model["dagaz"])
    if model["dagaz"]:
        ticks = [ev for ev in upto if ev["name"] == "dagaz"]
        period = model["dagaz"]["period"]["median"]
        if ticks:
            # Roll forward from the last printed tick: a tick with nothing to cure prints nothing (review TC-05). The
            # phase then comes from the log, so the rule class.dagaz.phase is not used.
            nxt, k = ticks[-1]["t"] + period, 1
            while nxt <= t0:
                nxt, k = nxt + period, k + 1
            start["dagazNext"] = nxt
            used.discard("class.dagaz.phase")
            dagaz_drawn = False
            dagaz_note = "Its phase comes from row %d, the last printed tick, %d period(s) on." % (ticks[-1]["row"], k)
        else:
            dagaz_note = "No tick is printed before the row, so its phase is %s." % (
                "half a period (--median)" if args.median else "drawn over one period")
            if args.median:
                alts["class.dagaz.phase"] = "half a period (--median)"
    hchon = [ev for ev in upto if ev["kind"] == "gain" and ev["name"] == "hypochondria"]
    if "hypochondria" in terms and hchon:
        start["chainAt"] = hchon[-1]["t"]
    engine = Engine()
    model_lua = engine.table(model)
    script = engine.script(args.then, model_lua)
    env = env_for(args, args.gap, args.median, kept)
    env["rowBase"] = end_row
    env["src"] = key
    result = engine.run(start, script, model_lua, env, args.seed)
    rules_for_actions(rules, args.then[:len(args.then) - (result.get("notRun") or 0)], terms, used)
    notes = []
    for ch in CHANNELS:
        if ch not in down_from:
            continue
        ev, back = down_from[ch], result["startReady"][ch]
        if back <= t0 + 1e-9:
            notes.append("%s down since row %d (%+.2f); the model clock's longest draw has run out, so it comes back at"
                         " +0.00" % (ch, ev["row"], ev["t"] - t0))
        else:
            notes.append("%s down since row %d (%+.2f): back at %+.2f by the model, past the %.2f s already run" % (
                ch, ev["row"], ev["t"] - t0, back - t0, t0 - ev["t"]))
    notes += own_notes
    # The log's last attack, counted as kb_events counts attacks (a second line in one bundle is not a new attack).
    last_hit_row = last_hit["row"] if last_hit else None

    def races_of(res):
        """The fork's races by kb_events.race() over the log up to the row plus the engine's events, so the logged DSTAB
        races the first forked action (review TC-06), and both read one definition. A race from an earlier log DSTAB is
        the log's, not the fork's; the last log attack stays, paired or not. A forked action is #<its number in --then>."""
        labels = {ev["row"]: "row %d" % ev["row"] for ev in upto}
        for strike in res["strikes"]:
            labels[end_row + strike["index"]] = "#%d" % strike["act"]
        stream = upto + res["events"]
        rows = ke.race(types.SimpleNamespace(id=key), stream)
        hits = ke.attacks(stream)
        out = []
        for r in rows:
            if r["row"] <= end_row and r["row"] != last_hit_row:
                continue
            gap, nxt_row = r["gap"], r["next_row"]
            if gap is None:
                # kb_events.race() drops a next attack DISENGAGED or more away. Keep it, so the race reads
                # "disengaged" with its #to, not "no attack" or "the horizon cut" (review R3-engine-4).
                later = next((h for h in hits if h["row"] > r["row"] and h["t"] - r["t"] >= kb.BUNDLED), None)
                if later is not None:
                    gap, nxt_row = round(later["t"] - r["t"], 3), later["row"]
            out.append({"label": "%s->%s" % (labels.get(r["row"], r["row"]), labels.get(nxt_row, "-")), "t": r["t"],
                        "gap": gap, "phase": r["phase"], "down": r["down"], "winner": r["winner"], "by": r["by"]})
        return out

    cls_label = CLASS_LABEL.get(model["classcure"]["kind"], "CLS") if model["classcure"] else "CLS"
    packet = span_note + ("" if end_row == at else " Row %d is inside a packet: the fork starts at its end, prompt row"
                                                    " %d." % (at, end_row))
    first_at = result["firstAt"]
    if last_hit is None:
        first = "First action at +0.00: the log shows no attack before the row."
    elif first_at <= t0:
        first = "First action at +0.00: one gap after the log's last attack (row %d, %+.2f) is at or before the row." % (
            last_hit["row"], last_hit["t"] - t0)
    else:
        first = "First action at %+.2f: one gap (%s) after the log's last attack (row %d, %+.2f)." % (
            first_at - t0, ("%.2f s" % args.gap) if args.median or not args.gap_sd > 0 else ("drawn around %.2f s" %
                                                                                               args.gap), last_hit["row"],
            last_hit["t"] - t0)
    out = ["MODEL, NOT A LOG: a fork of %s row %d (%s). Freeze %s." % (key, at, os.path.basename(ke.log_path(key)),
                                                                      rules["freeze_sha256"][:12]),
           "START at the stamp of row %d.%s The board is the logger's belief at prompt row %s plus the lines after it: %s."
           % (end_row, packet, board_row, ", ".join(sorted(terms)) or "empty"),
           "      " + ("; ".join(notes) if notes else "no channel's clock is down (an affliction can still shut one)") + "."]
    if unknown:
        out.append("      Board tokens no table names (left out): %s." % ", ".join(unknown))
    out += ["      Defences: shield %s (row %s), rebounding %s (row %s), sileris %s (row %s). %s" % (
               "up" if defs["shield"] else "down", proof["shield"] or "-", "up" if defs["rebounding"] else "down",
               proof["rebounding"] or "-", "up" if defs["sileris"] else "down", proof["sileris"] or "-", gap_note),
            "      The logger keeps %s (the log shows them by the row)%s." % (
               " and ".join(kept) or "no shield and no rebounding", ("; " + "; ".join(pending)) if pending else ""),
            "      " + first]
    out += ["ILLUSTRATIVE: medians, no noise." if args.median else "ONE DRAW: seed %d." % args.seed]
    out += timeline(result, model, t0, cls_label)
    probs = None
    if args.seeds:
        env_n = dict(env_for(args, args.gap, False, kept, snap=False), rowBase=end_row, src=key)
        probs = race_probs(lambda seed: races_of(engine.run(start, script, model_lua, env_n, seed)), args.seeds, args.seed)
    out += race_lines(races_of(result), t0, probs, (model["ssc"]["min"], model["ssc"]["max"]),
                      cut=cut_attack(result, args.then), gap_drawn=args.gap_sd > 0)
    out += horizon_lines(result, len(args.then), args.horizon, t0)
    out += log_race_line()
    out += class_lines(rules, model, prof, dagaz_note)
    out += no_channel_lines(rules, terms, result, model)
    out += seeds_lines(args, dagaz_drawn)
    out += assumed_lines(rules, used, args.median, alts, args.seeds, args.gap_sd)
    out.append(label_line(result, t0))
    nxt = [ev for ev in events if ev["row"] > end_row and ev["name"] in ke.GAP_ATTACKS][:3]
    if nxt:
        out.append("LOG   what happened instead: " + "; ".join("row %d %s at %+.2f" % (ev["row"], ev["name"], ev["t"] - t0)
                                                         for ev in nxt) + ".")
    if args.jsonl:
        write_jsonl(args.jsonl, result["events"])
    return out


# ---------------------------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------------------------


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--victim", help="the victim's class: %s" % ", ".join(sorted(VICTIMS)))
    ap.add_argument("--script", nargs="+", help="the attacker's actions, one per balance")
    ap.add_argument("--gap", type=float, help="our attack gap in seconds (not measured: give it)")
    ap.add_argument("--gap-sd", type=float, default=0.09, help="the gap's noise (rule attack.gap.own.sd)")
    ap.add_argument("--gap-floor", type=float, default=None, help="no gap below this")
    ap.add_argument("--median", action="store_true", help="medians, no noise, top-priority picks")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--seeds", type=int, default=0, help="also run this many seeds for the race probability")
    ap.add_argument("--affs", nargs="*", default=[], help="afflictions up at the start")
    ap.add_argument("--defences", nargs="*", default=[], choices=("shield", "rebounding"),
                    help="the victim keeps these up: up at the start, and the shield is raised again after a FLAY")
    ap.add_argument("--tree", default="now", choices=("now", "hold"), help="rule tree.policy")
    ap.add_argument("--tree-pick", default="random", choices=("random", "priority"), help="rule tree.pick")
    ap.add_argument("--random-pool", default="norandomcure", choices=("norandomcure", "package"),
                    help="rule random_cure.pool: NoRandomCure off (the value), or the package's tree pool (the alternative)")
    ap.add_argument("--flay-order", default="named", choices=("named", "auto"),
                    help="rule attack.flay.order: a FLAY strips what it names (the wiki), or shield, rebounding, sileris")
    ap.add_argument("--tail", type=float, default=2.5, help="seconds to run after the last action")
    ap.add_argument("--horizon", type=float, default=60.0)
    ap.add_argument("--clock-draw", default="quantiles", choices=("quantiles", "normal"),
                    help="rule draw.shape: draw a clock from its quantiles (the value), or around its median (the alternative)")
    ap.add_argument("--log", choices=ke.KEYS, help="a Serpent log: az, Z5, g or X")
    ap.add_argument("--from", dest="start", type=int, help="show the log from this row")
    ap.add_argument("--to", type=int, help="up to this row")
    ap.add_argument("--rows", type=int, default=40)
    ap.add_argument("--at", type=int, help="fork the log at this row")
    ap.add_argument("--then", nargs="+", help="the fork's actions")
    ap.add_argument("--jsonl", help="write the run's event stream (version 1, view true) to this file")
    args = ap.parse_args(argv)
    # The engine floors every gap (fight.lua F.gapDraw): at --gap-floor, else at BUNDLED. A gap under the floor would run
    # at the floor while the page printed the gap asked for, and --gap 0 crashed the TREE line (reviews LUA-N2-12,
    # R3-engine-5).
    if not (args.gap_sd >= 0 and math.isfinite(args.gap_sd)):
        raise SystemExit("theorycraft: --gap-sd must be a finite 0 or more (a negative sd still draws the gap).")
    if args.gap is not None and not math.isfinite(args.gap):
        raise SystemExit("theorycraft: --gap must be a finite number of seconds.")
    if args.gap_floor is not None and not args.gap_floor >= 0.01:
        raise SystemExit("theorycraft: --gap-floor must be at least 0.01 s (a shorter step can round to now).")
    # A fork with no --gap runs other Serpents' median, so its gap is checked too (reviews R4-cli-1, R4-docs-1).
    gap, what = args.gap, "--gap %s" % args.gap
    if gap is None and args.log and args.at is not None and args.start is None:
        gap, what = FORK_GAP, "the fork's gap %.2f (other Serpents' median; no --gap)" % FORK_GAP
    if args.gap_floor is not None:
        if gap is not None and not gap >= args.gap_floor:
            raise SystemExit("theorycraft: %s is under --gap-floor %.2f. Give a --gap at or above the floor." % (
                what, args.gap_floor))
    elif gap is not None and not gap >= kb.BUNDLED:
        raise SystemExit("theorycraft: %s is under the gap floor %.2f s (BUNDLED: two lines within %.1f s are one"
                         " attack). Give --gap-floor to go lower." % (what, kb.BUNDLED, kb.BUNDLED))
    if args.log and args.start is not None:
        lines = log_view(args)
    elif args.log and args.at is not None:
        if not args.then:
            raise SystemExit("theorycraft: a fork needs --then")
        lines = fork(args)
    elif args.victim and args.script:
        lines = scripted(args)
    else:
        ap.print_help()
        return 2
    print("\n".join(line.rstrip() for line in lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())
