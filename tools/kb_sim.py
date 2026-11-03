"""Step 7, first stage: run logged asthma + weariness boards 20 s forward against a strong attacker.

The engine is tools/sim/forward.lua, in Lua 5.1 under lupa. This file reads the boards from the Serpent logs, builds the
model from the knowledge base, runs the sweep, and writes kb/sim/forward.md and forward.json.

The rules on the page were written before the first run (FIRST_RUN). A later change to a bar must be stated on the page.

    python tools/kb_sim.py            # write the pages (about 12 minutes)
    python tools/kb_sim.py --check    # page matches the data, data matches the inputs, a sample of cells re-runs
"""

import argparse
import collections
import glob
import hashlib
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kb_timing as kb
import kb_replay as rp

# Lua 5.1, as Mudlet and tools/run_lua_tests.py run it. A plain `import lupa` gives the newest Lua instead.
try:
    import lupa.lua51 as lupa
except ImportError:
    lupa = None

ROOT = kb.ROOT
ENGINE = os.path.join(ROOT, "tools", "sim", "forward.lua")
CLOCKS = os.path.join(ROOT, "kb", "mechanics", "clocks.json")
AFFLICTIONS = os.path.join(ROOT, "kb", "afflictions", "afflictions.json")
PRIOS = os.path.join(ROOT, "src_new", "scripts", "levi_ataxia", "levi", "ataxia", "ataxia", "001_Default_Curing_Prios.lua")
OUT_MD = os.path.join(ROOT, "kb", "sim", "forward.md")
OUT_JSON = os.path.join(ROOT, "kb", "sim", "forward.json")

# The four logs in which a Serpent attacks the logger. Keys as in foundations.md.
SERPENT_LOGS = {"az": "azbErKcK", "X": "X8pRorzR", "Z5": "Z5cyffxx", "g": "g-lD00-h"}
HORIZON = 20.0
RUNS = 400
SAMPLE_EVERY = 97       # --check re-runs this share of the cells.

# ---------------------------------------------------------------------------------------------
# Inputs a sweep can change. Each one is measured, and clocks.md or foundations.md holds the row.
# ---------------------------------------------------------------------------------------------

# DSTAB to the same person's next attack, in seconds, all loggers: min 1.545, p10 1.73, median 1.83, p90 3.10 (clocks.md).
# Within 0.25 s of the median 77% of the time, so the base draws a gap with a standard deviation of 0.2 s.
GAP_MIN, GAP_P10, GAP_MEDIAN, GAP_P90 = 1.545, 1.73, 1.83, 3.10
BASE_ENV = {
    "gap": GAP_MEDIAN, "floor": GAP_MIN, "gapSd": 0.2,
    "phi": 0.6,                     # Asthma won aurum 16 of 27 with weariness up (foundations.md, item 6).
    "lockout": 9.81,                # FITNESS, stamps of 0.01 s or better (clocks.md).
    "chain": 9.31,                  # Hypochondria to impatience (foundations.md, Timed effects; one fight).
    "impFirst": "logged",           # The time this board's own log showed impatience, once. No showing means no supply.
    "impEvery": None,
    "shieldWhileParalysed": False,  # 3 of 4 shield rows show paralysis cured first. One row (X) is not clear.
    "horizon": HORIZON,
}
# One input moves at a time, so a flip names the input that caused it.
SWEEP = (
    ("base", {}),
    ("gap 1.545 (min), no noise", {"gap": GAP_MIN, "gapSd": 0}),
    ("gap 1.73 (p10)", {"gap": GAP_P10}),
    ("gap 2.33 (median + 0.5)", {"gap": GAP_MEDIAN + 0.5}),
    ("gap 3.10 (p90)", {"gap": GAP_P90}),
    ("no timed impatience", {"impFirst": None}),
    ("impatience every 9.31", {"impFirst": 9.31, "impEvery": 9.31}),
    ("strongest: gap 1.545, impatience at +2 and every 9.31", {"gap": GAP_MIN, "gapSd": 0, "impFirst": 2.0, "impEvery": 9.31}),
    ("phi 0.33 (random inside the herb)", {"phi": 0.33}),
    ("phi 1.0 (priority always wins)", {"phi": 1.0}),
    ("shield cost 2.89 (ours)", {"eqCost": 2.89}),
    ("shield cost 4.00 (Claes)", {"eqCost": 4.0}),
    ("lockout 9.06", {"lockout": 9.06}),
    ("lockout 9.97", {"lockout": 9.97}),
    ("shield allowed while paralysed", {"shieldWhileParalysed": True}),
    ("FLAY gap 1.64 (median)", {"flayGap": 1.64}),
)
BASE_ROW = 0
STRONGEST_ROW = 7
ATTACKERS = ("lock", "soft", "keep")
POLICIES = tuple({"eq": e, "tree": t, "herb": h}
                 for e in ("hold", "once", "always") for t in ("now", "hold") for h in ("default", "asthma", "package", "packageLate"))

# The tokens the replay's rules do not read, but a herb does: they spend eats and they share herbs with the lock pieces. A
# token with no entry stays out, and the page lists it.
EXTRA_TOKENS = {
    "claes": {"ADD": "addiction", "DARK": "darkshade", "SCYT": "scytherus", "SENS": "sensitivity", "clum": "clumsiness",
              "conf": "confusion", "dizz": "dizziness", "frat": "fratricide", "hchon": "hypochondria", "leth": "lethargy",
              "maso": "masochism", "naus": "nausea", "vert": "vertigo", "gene": "generosity", "epi": "epilepsy",
              "hall": "hallucinations", "hsomn": "hypersomnia", "dem": "dementia"},
    "nikita": {"HYPOCHONDRIA": "hypochondria", "SCY": "scytherus", "VERT": "vertigo", "add": "addiction", "clu": "clumsiness",
               "dark": "darkshade", "epi": "epilepsy", "frat": "fratricide", "hyper": "hypersomnia", "leth": "lethargy",
               "maso": "masochism", "nau": "nausea"},
}
EXTRA_TOKENS["elmer"] = dict(EXTRA_TOKENS["claes"], FRAT="fratricide")
# Not herbs, or not what this stage models: it reads them, so that a new token still shows on the page.
NOT_MODELLED = {"DISR", "PSHOT", "pinshot", "VOYR", "VOY", "disl", "hmrc", "ddn", "SOFTLOCKED", "TRUELOCKED", "bld8", "bld16"}

ENGINE_CHANNELS = {"eat": "eat", "lungs": "smoke", "salve": "salve", "focus": "focus", "tree": "tree"}
SHIELD_TOUCH = re.compile(r"^You touch the tattoo and a nearly invisible magical shield")
EQ_USED = re.compile(r"^Equilibrium used: ([\d.]+)s")

# ---------------------------------------------------------------------------------------------
# The model, from the knowledge base
# ---------------------------------------------------------------------------------------------


def lua_runtime():
    return lupa.LuaRuntime(unpack_returned_tuples=True)


def default_prios(lua):
    """The real function from the package, so that the sim follows the table the package ships."""
    with open(PRIOS, encoding="utf-8") as fh:
        lua.execute(fh.read())
    table = lua.globals().ataxia_defaultCuringPrios()
    return {k: v for k, v in table.items() if isinstance(v, (int, float))}


def build_model(lua, names):
    """Clocks are rounded to 0.01 s, so a new log moves the model only when a median really moves."""
    with open(CLOCKS, encoding="utf-8") as fh:
        clocks = json.load(fh)["clocks"]
    with open(AFFLICTIONS, encoding="utf-8") as fh:
        affs = json.load(fh)
    prios = default_prios(lua)

    def median(name):
        return round(clocks[name]["stats"]["median"], 2)

    def sd(name):
        # p90 - p10 of a normal draw is 2.563 standard deviations.
        return round(clocks[name]["stats"]["spread"] / 2.563, 3)

    herb, focus = {}, []
    for name in sorted(names):
        for option in (affs.get(name) or {}).get("cure_options") or []:
            first = option[0]
            if first.startswith("eat ") and name not in herb:
                herb[name] = first[4:]
            if first == "focus mind" and name != "anorexia":
                focus.append(name)
    return {
        "clocks": {"eat": median("eat"), "smoke": median("smoke"), "salve": median("salve_short"), "focus": median("focus"),
                   "tree": median("tree"), "fitnessBal": 2.8},
        "sd": {"eat": sd("eat"), "smoke": sd("smoke"), "salve": sd("salve_short"), "focus": sd("focus"), "tree": sd("tree")},
        "prio": {k: prios[k] for k in sorted(names) if k in prios},
        "herb": herb,
        "eatList": sorted(herb),
        "focusList": sorted(focus),
        "allList": sorted(names),
    }


# ---------------------------------------------------------------------------------------------
# The boards
# ---------------------------------------------------------------------------------------------


def log_path(log_id):
    found = [p for p in glob.glob(os.path.join(ROOT, "kb", "raw", "logs", "**", "*"), recursive=True)
             if log_id in os.path.basename(p) and p.endswith((".txt", ".log"))]
    return sorted(found)[0]


def shield_cost(log):
    """The cost this character paid, as the game printed it."""
    rows = [r for r in log if r.kind == "line" and r.text]
    paid = collections.Counter()
    for i, row in enumerate(rows):
        if SHIELD_TOUCH.match(row.text):
            for later in rows[i + 1:i + 4]:
                m = EQ_USED.match(later.text)
                if m:
                    paid[float(m.group(1))] += 1
                    break
    return paid.most_common(1)[0][0] if paid else None


def board_affs(family, tokens, unknown):
    """(names the board holds). A limb and prone are not in this stage; `unknown` collects a token with no entry."""
    terms, _, _ = rp.read_terms(family, tokens)
    names = {t for t in terms if t in ("asthma", "anorexia", "slickness", "impatience", "paralysis", "weariness", "haemophilia",
                                       "stupidity", "recklessness")}
    extra = EXTRA_TOKENS.get(family, {})
    table = rp.TOKENS.get(family, {})
    for tok in tokens:
        if tok in extra:
            names.add(extra[tok])
        elif tok not in table and tok not in NOT_MODELLED and not rp.BLEED_TOKEN.match(tok) and not rp.PRESSURE_TOKEN.match(tok):
            unknown[tok] += 1
    return names


def extract_boards():
    """Each window of asthma + weariness up in the Serpent logs: the first prompt of it, and what the log then did."""
    boards, unknown, costs = [], collections.Counter(), {}
    with open(CLOCKS, encoding="utf-8") as fh:
        clocks = json.load(fh)["clocks"]
    clock_len = {"eat": clocks["eat"]["stats"]["median"], "lungs": clocks["smoke"]["stats"]["median"],
                 "salve": clocks["salve_short"]["stats"]["median"], "focus": clocks["focus"]["stats"]["median"],
                 "tree": clocks["tree"]["stats"]["median"], "classcure": clocks["fitness"]["stats"]["median"]}
    for key, log_id in SERPENT_LOGS.items():
        log = kb.parse(log_path(log_id))
        cls = rp.logger_class(log)
        cost = shield_cost(log)
        costs[key] = cost
        seq = []
        hchon_since = None
        for s in rp.walk(log):
            if s.terms is None:
                continue
            names = board_affs(log.family, s.row.board, unknown)
            hchon_since = (hchon_since if hchon_since is not None else s.t) if "hypochondria" in names else None
            seq.append({"t": s.t, "row": s.row.n, "names": names, "soft": rp.is_softlock(s.terms), "true": rp.is_true(s, cls),
                        "imp": "impatience" in s.terms, "clock": dict(s.clock), "bal": s.bal, "eq": s.eq,
                        "hchon_age": None if hchon_since is None else round(s.t - hchon_since, 2)})
        prev = False
        for i, p in enumerate(seq):
            both = {"asthma", "weariness"} <= p["names"]
            if both and not prev:
                seen = {"soft": None, "true": None, "imp": None}
                off = None
                span = 0.0
                for q in seq[i:]:
                    if q["t"] - p["t"] > HORIZON:
                        break
                    span = q["t"] - p["t"]
                    for what in seen:
                        if seen[what] is None and q[what]:
                            seen[what] = round(q["t"] - p["t"], 1)
                    if off is None and "asthma" not in q["names"]:
                        off = round(q["t"] - p["t"], 1)
                seen["off"] = off
                ready = {}
                for channel, stamp in p["clock"].items():
                    if channel in clock_len:
                        left = clock_len[channel] - (p["t"] - stamp)
                        name = ENGINE_CHANNELS.get(channel, "fitness")
                        if left > 0:
                            ready[name] = round(left, 2)
                # A flag that is down has an unknown time left: half the cost. Claes's prompt shows no flags, so up.
                if p["bal"] is False:
                    ready["bal"] = 1.4
                if p["eq"] is False:
                    ready["eq"] = round((cost or 3.4) / 2, 2)
                board = {"id": "%s:%d" % (key, p["row"]), "log": key, "class": cls, "fitness": rp.BLOCKERS.get(cls) == "weariness",
                         "affs": sorted(p["names"]), "ready": ready, "eqCost": cost or 3.4, "seen": seen, "span": round(span, 1)}
                if p["hchon_age"] is not None:
                    board["hchonAge"] = p["hchon_age"]
                boards.append(board)
            prev = both
    return boards, dict(unknown), costs


EATEN = re.compile(r"^You eat (?:a |an |some )?(.+?)\.?$")
HERB_WORDS = {"bloodroot": "bloodroot", "magnesium": "bloodroot", "kelp": "kelp", "aurum": "kelp", "goldenseal": "goldenseal",
              "plumbum": "goldenseal", "lobelia": "lobelia", "argentum": "lobelia", "ginseng": "ginseng", "ferrum": "ginseng",
              "ash": "ash", "stannum": "ash", "bellwort": "bellwort", "cuprum": "bellwort"}
SHIELD_FLAYED = re.compile(r"flays away your shield defence")
SHIELD_BOUNCED = re.compile(r"attack rebounds off your magical shield")
EVIDENCE_WINDOW = 10.0


def logged_eats():
    """What the eats went on, in the 10 s after each fitness board."""
    counts, first, boards = collections.Counter(), collections.Counter(), 0
    for key, log_id in SERPENT_LOGS.items():
        log = kb.parse(log_path(log_id))
        if rp.BLOCKERS.get(rp.logger_class(log)) != "weariness":
            continue
        rows = list(log)
        prev = False
        for i, row in enumerate(rows):
            if row.kind != "prompt" or row.board is None:
                continue
            terms = rp.read_terms(log.family, row.board)[0]
            both = {"asthma", "weariness"} <= terms
            if both and not prev:
                boards += 1
                eats = []
                for later in rows[i + 1:]:
                    if later.kind == "prompt" and later.own is not None and later.own - row.own > EVIDENCE_WINDOW:
                        break
                    m = EATEN.match(later.text) if later.kind == "line" and later.text else None
                    if m:
                        eats.append(next((v for k, v in HERB_WORDS.items() if k in m.group(1)), "other"))
                counts.update(eats)
                if eats:
                    first[eats[0]] += 1
            prev = both
    return {"boards": boards, "eats": dict(counts), "first": dict(first)}


def shield_answers():
    """How a Serpent answers a shield: how long it stays up, and how many new afflictions the FLAY packet brings."""
    times, gained, bounced = [], collections.Counter(), 0
    for log_id in SERPENT_LOGS.values():
        log = kb.parse(log_path(log_id))
        rows = [r for r in log if r.kind in ("line", "prompt")]
        up, last_t = None, None
        for j, row in enumerate(rows):
            if row.kind == "prompt":
                last_t = row.own if row.own is not None else last_t
                continue
            if not row.text:
                continue
            if SHIELD_TOUCH.match(row.text):
                up = last_t
            elif SHIELD_BOUNCED.search(row.text):
                bounced += 1
            elif SHIELD_FLAYED.search(row.text):
                if up is not None and last_t is not None:
                    times.append(round(last_t - up, 2))
                before = next((q for q in reversed(rows[:j]) if q.kind == "prompt" and q.board is not None), None)
                after = next((q for q in rows[j:] if q.kind == "prompt" and q.board is not None), None)
                if before is not None and after is not None:
                    new = rp.read_terms(log.family, after.board)[0] - rp.read_terms(log.family, before.board)[0]
                    gained[str(len(new))] += 1
                up = None
    times.sort()
    return {"flays": len(times), "median_up": times[len(times) // 2] if times else None, "gained": dict(gained), "bounced": bounced}


def model_names(boards):
    names = {"asthma", "anorexia", "slickness", "impatience", "paralysis", "weariness",
             "clumsiness", "darkshade", "nausea", "sensitivity", "haemophilia", "addiction"}
    for b in boards:
        names.update(b["affs"])
    return names


# ---------------------------------------------------------------------------------------------
# The sweep
# ---------------------------------------------------------------------------------------------


def to_lua(value):
    if value is None:
        return "nil"
    if value is True:
        return "true"
    if value is False:
        return "false"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, str):
        return '"%s"' % value
    if isinstance(value, (list, tuple)):
        return "{" + ",".join(to_lua(v) for v in value) + "}"
    return "{" + ",".join("[%s]=%s" % (to_lua(k), to_lua(value[k])) for k in sorted(value) if value[k] is not None) + "}"


class Engine:
    def __init__(self, lua=None):
        self.lua = lua or lua_runtime()
        with open(ENGINE, encoding="utf-8") as fh:
            self.forward = self.lua.execute(fh.read())

    def table(self, value):
        return self.lua.eval(to_lua(value))

    def cell(self, board_t, policy_t, env_t, model_t, n, seed):
        r = self.forward.cell(board_t, policy_t, env_t, model_t, n, seed)
        return {"close": int(r.close), "soft": int(r.soft), "softTime": round(float(r.softTime) / n, 3),
                "asthmaOff5": int(r.asthmaOff5), "fitness": int(r.fitness)}


def env_for(board, over, attacker):
    env = dict(BASE_ENV, eqCost=board["eqCost"], attacker=attacker)
    env.update(over)
    if env["impFirst"] == "logged":
        env["impFirst"] = board["seen"]["imp"]
    return env


def cell_seed(b, e, a):
    return (b + 1) * 1000003 + (e + 1) * 10007 + (a + 1) * 101


def sweep_for(board):
    """Every board runs the whole sweep. A board from another class runs as if the logger had FITNESS, and no verdict reads it."""
    return SWEEP


def run_sweep(engine, boards, model):
    model_t = engine.table(model)
    policies_t = [engine.table(p) for p in POLICIES]
    cells = {}
    for b, board in enumerate(boards):
        board_t = engine.table({k: board[k] for k in ("affs", "ready", "hchonAge") if k in board})
        for e, (name, over) in enumerate(sweep_for(board)):
            for a, attacker in enumerate(ATTACKERS):
                env_t = engine.table(env_for(board, over, attacker))
                seed = cell_seed(b, e, a)
                for p, policy_t in enumerate(policies_t):
                    cells["%d|%d|%d|%d" % (b, e, a, p)] = engine.cell(board_t, policy_t, env_t, model_t, RUNS, seed)
        print("  board %d of %d: %s" % (b + 1, len(boards), board["id"]), flush=True)
    return cells


# ---------------------------------------------------------------------------------------------
# Reading the result. Written before the first run.
# ---------------------------------------------------------------------------------------------

EFFECT_CLOSE = 0.03     # A closure rate must differ by this much to count: 3 points in 100.
EFFECT_SOFT = 0.5       # Softlock seconds must differ by this much: foundations.md, item 13.
SATURATED = 0.03        # Both closure rates within this of 0 or of 1: the row cannot compare the two choices.
MIN_COMPARISONS = 10    # With fewer live comparisons than this, a verdict is UNSETTLED.

FIRST_RUN = (
    "**Sanity, before any verdict.** At the strongest row, the attacker must be at least as strong as the logs, or a verdict means little.",
    "- **S1.** Each fitness board that reached the `true` label within 20 s in its log must reach it in the sim, with equilibrium held, "
    "tree at once and our default priority, for at least one attacker. The loggers ran their own priority tables, so this is not their policy.",
    "- **S2.** Over the fitness boards, the sum of the strongest attacker's chance of `true` must be at or above the number of "
    "boards that reached it in the log.",
    "- **S3.** Over all boards, the same for softlock.",
    "- If one fails, the page prints MODEL TOO WEAK, and a verdict counts only as a note.",
    "",
    "**A verdict.** For each board and policy, the attacker with the highest closure rate answers. The rates are averaged over "
    "the fitness boards. A decision is compared in each row of the sweep, under each setting of the other two decisions. A "
    "comparison is live unless both rates are within 3 points of 0 or of 1: such a row cannot compare the two choices.",
    "- **ROBUST:** one choice is better by at least 3 points in at least half of the live comparisons, and worse by 3 points in none.",
    "- **CONDITIONAL:** better by 3 points in some and worse by 3 points in others. The page names the rows on each side.",
    "- **UNSETTLED:** anything else. This includes no difference at all, and fewer than 10 live comparisons.",
    "- The same rule runs on softlock seconds, with a bar of 0.5 s, as a second reading. Every comparison is live there.",
)

CHANGED_BEFORE_RUN = (
    "**One change came after a smoke test and before any verdict ran.** The first base had the shortest gap and a timed impatience at "
    "+2 s. Every board then closed in 100% of runs, whatever the victim did, against 2 of 10 in the logs. A row like that cannot compare "
    "decisions. So the base became the median gap with noise, and each board's own logged impatience time. The old base stayed as the "
    "strongest row, the sanity check moved to it, and the live rule above was added."
)

AFTER_FIRST_RUN = (
    "**Four changes came after the first verdict run. No bar moved.** (1) That run read the rule in one direction only, so a decision "
    "that was worse in 43 comparisons and better in none read as no result. The rule now reads both ways. (2) The FLAY gap row was added, "
    "because a shield verdict depends on it. (3) Runs per cell went from 200 to 400, to reduce noise near the 3 point bar. (4) Two eat "
    "orders were added, because the package does not run the default order against a Serpent: `astWear` and `paraAst` in "
    "`001_Anti_Priorities.lua`, both active by default. The first run's labels on the closure rate: one shield UNSETTLED, a shield whenever "
    "equilibrium is up ROBUST, tree held UNSETTLED, asthma first ROBUST."
)


def p_close(cells, b, e, p):
    return max(cells["%d|%d|%d|%d" % (b, e, a, p)]["close"] for a in range(len(ATTACKERS))) / RUNS


def soft_seconds(cells, b, e, p):
    return max(cells["%d|%d|%d|%d" % (b, e, a, p)]["softTime"] for a in range(len(ATTACKERS)))


def p_soft(cells, b, e, p):
    return max(cells["%d|%d|%d|%d" % (b, e, a, p)]["soft"] for a in range(len(ATTACKERS))) / RUNS


def p_off(cells, b, e, p):
    """The attacker who leaves asthma up the longest answers."""
    return min(cells["%d|%d|%d|%d" % (b, e, a, p)]["asthmaOff5"] for a in range(len(ATTACKERS))) / RUNS


def policy_index(eq, tree, herb):
    return POLICIES.index({"eq": eq, "tree": tree, "herb": herb})


def sanity(boards, cells):
    logged = policy_index("hold", "now", "default")
    fit = [i for i, b in enumerate(boards) if b["fitness"]]
    closed = [i for i in fit if boards[i]["seen"]["true"] is not None]
    row = STRONGEST_ROW
    s1 = [{"board": boards[i]["id"], "logged_at": boards[i]["seen"]["true"], "sim": round(p_close(cells, i, row, logged), 3)}
          for i in closed]
    s2 = sum(p_close(cells, i, row, logged) for i in fit)
    soft_seen = sum(1 for b in boards if b["seen"]["soft"] is not None)
    s3 = sum(p_soft(cells, i, row, logged) for i in range(len(boards)))
    calibration = []
    for e, (name, _) in enumerate(SWEEP):
        calibration.append({"input": name, "true": round(sum(p_close(cells, i, e, logged) for i in fit), 2),
                            "soft": round(sum(p_soft(cells, i, e, logged) for i in range(len(boards))), 2),
                            "off_default": round(sum(p_off(cells, i, e, logged) for i in fit), 2),
                            "off_asthma": round(sum(p_off(cells, i, e, policy_index("hold", "now", "asthma")) for i in fit), 2)})
    return {
        "s1": s1, "s1_ok": all(r["sim"] > 0 for r in s1),
        "s2_sim": round(s2, 2), "s2_seen": len(closed), "s2_ok": s2 >= len(closed),
        "s3_sim": round(s3, 2), "s3_seen": soft_seen, "s3_ok": s3 >= soft_seen,
        "ok": all(r["sim"] > 0 for r in s1) and s2 >= len(closed) and s3 >= soft_seen,
        "calibration": calibration,
        "off_seen": sum(1 for i in fit if boards[i]["seen"]["off"] is not None and boards[i]["seen"]["off"] <= 5),
    }


def compare(boards, cells, axis, a_value, b_value, reader, effect, saturates):
    """Mean of (a - b) per sweep row and setting of the other decisions, over the fitness boards. Lower is better."""
    fit = [i for i, b in enumerate(boards) if b["fitness"]]
    rows = []
    others = [k for k in ("eq", "tree", "herb") if k != axis]
    values = {"eq": ("hold", "once", "always"), "tree": ("now", "hold"), "herb": ("default", "asthma")}
    for e, (name, _) in enumerate(SWEEP):
        for v1 in values[others[0]]:
            for v2 in values[others[1]]:
                base = {others[0]: v1, others[1]: v2}
                pa = policy_index(**dict(base, **{axis: a_value}))
                pb = policy_index(**dict(base, **{axis: b_value}))
                ra = sum(reader(cells, i, e, pa) for i in fit) / len(fit)
                rb = sum(reader(cells, i, e, pb) for i in fit) / len(fit)
                live = not saturates or not (max(ra, rb) <= SATURATED or min(ra, rb) >= 1 - SATURATED)
                rows.append({"input": name, others[0]: v1, others[1]: v2, "a": round(ra, 3), "b": round(rb, 3),
                             "diff": round(ra - rb, 3), "live": live})
    live_rows = [r for r in rows if r["live"]]
    better = [r for r in live_rows if r["diff"] <= -effect]
    worse = [r for r in live_rows if r["diff"] >= effect]
    winner = None
    if worse and better:
        label = "CONDITIONAL"
    elif better and len(better) * 2 >= len(live_rows) and len(live_rows) >= MIN_COMPARISONS:
        label, winner = "ROBUST", "first"
    elif worse and len(worse) * 2 >= len(live_rows) and len(live_rows) >= MIN_COMPARISONS:
        label, winner = "ROBUST", "second"
    else:
        label = "UNSETTLED"
    return {"label": label, "winner": winner, "rows": rows, "better": len(better), "worse": len(worse), "total": len(live_rows), "all": len(rows),
            "better_inputs": sorted({r["input"] for r in better}), "worse_inputs": sorted({r["input"] for r in worse}),
            "min": min(r["diff"] for r in rows), "max": max(r["diff"] for r in rows)}


def log_like_row(sanity_r):
    """Of the rows that move only the attack gap, the one whose softlock sum is nearest to the logs."""
    rows = [r for r in sanity_r["calibration"] if r["input"] == "base" or r["input"].startswith("gap ")]
    return min(rows, key=lambda r: abs(r["soft"] - sanity_r["s3_seen"]))["input"]


def policy_table(boards, cells, row_name):
    fit = [i for i, b in enumerate(boards) if b["fitness"]]
    e = [name for name, _ in SWEEP].index(row_name)
    out = []
    for p, policy in enumerate(POLICIES):
        out.append(dict(policy, close=round(sum(p_close(cells, i, e, p) for i in fit) / len(fit), 3),
                        soft=round(sum(soft_seconds(cells, i, e, p) for i in fit) / len(fit), 2),
                        off=round(sum(p_off(cells, i, e, p) for i in fit) / len(fit), 3)))
    return out


DECISIONS = (
    ("One shield now, against holding equilibrium", "eq", "once", "hold"),
    ("A shield whenever equilibrium is up, against holding equilibrium", "eq", "always", "hold"),
    ("Tree held for a softlock, against tree at once", "tree", "hold", "now"),
    ("Asthma at the top of the eat order, against the default order", "herb", "asthma", "default"),
    ("Asthma at the top, against the package's Serpent rules, asthma wins the tie", "herb", "asthma", "package"),
    ("Asthma at the top, against the package's Serpent rules, paralysis wins the tie", "herb", "asthma", "packageLate"),
)


def verdicts(boards, cells):
    out = []
    for title, axis, a, b in DECISIONS:
        close = compare(boards, cells, axis, a, b, p_close, EFFECT_CLOSE, True)
        soft = compare(boards, cells, axis, a, b, soft_seconds, EFFECT_SOFT, False)
        out.append({"title": title, "close": close, "soft": soft})
    return out


# ---------------------------------------------------------------------------------------------
# The files
# ---------------------------------------------------------------------------------------------


def input_hash(boards, model):
    blob = json.dumps({"boards": boards, "model": model, "sweep": SWEEP, "base": BASE_ENV, "attackers": ATTACKERS,
                       "policies": POLICIES, "runs": RUNS}, sort_keys=True)
    with open(ENGINE, "rb") as fh:
        engine = fh.read().replace(b"\r\n", b"\n")
    return hashlib.sha256(blob.encode("utf-8") + engine).hexdigest()


def pct(value):
    return "%.0f%%" % (value * 100)


def side(result, unit):
    span = "%s to %s %s" % (fmt(result["min"]), fmt(result["max"]), unit)
    if result["label"] == "ROBUST":
        who = "the first choice" if result["winner"] == "first" else "the second choice"
        count = result["better"] if result["winner"] == "first" else result["worse"]
        return "%s is better in %d of %d comparisons, and worse in none (%s)." % (who, count, result["total"], span)
    if result["label"] == "CONDITIONAL":
        return "the first choice is better in %d of %d and worse in %d (%s). Worse with: %s." % (
            result["better"], result["total"], result["worse"], span, "; ".join(result["worse_inputs"]))
    return "no clear result: better in %d of %d, worse in %d (%s)." % (result["better"], result["total"], result["worse"], span)


def fmt(value):
    return "%+.3f" % value


def render_page(data):
    boards, sanity_r, verdict_r = data["boards"], data["sanity"], data["verdicts"]
    fit = [b for b in boards if b["fitness"]]
    lines = ["---", "topic: forward simulator, first stage", "confidence: a model, not a measurement",
             "generated_by: tools/kb_sim.py", "engine: tools/sim/forward.lua", "---", "",
             "# Forward simulator: asthma + weariness boards", "",
             "**GENERATED. Do not edit.** Run `python tools/kb_sim.py`.", "",
             "This page compares the victim's decisions on real boards, 20 s forward, against a strong attacker. It does not say who "
             "wins a fight. It does not say what the best system is. A verdict goes live only through the plan's shadow step and the "
             "user's word.", ""]
    lines += ["## Result", ""]
    lines.append("**Sanity: %s.**" % ("PASS" if sanity_r["ok"] else "MODEL TOO WEAK"))
    for v in verdict_r:
        lines.append("- **%s: %s.** Closure rate: %s Softlock seconds, %s: %s" % (
            v["title"], v["close"]["label"], side(v["close"], "of the rate"), v["soft"]["label"], side(v["soft"], "s")))
    lines += ["", "A negative number means the first choice is safer. Each comparison uses the same seeds for both choices.", ""]
    lines += ["## Rules written before the first run", ""] + list(FIRST_RUN) + ["", CHANGED_BEFORE_RUN, "", AFTER_FIRST_RUN, ""]
    lines += ["## Sanity check", "", "| Check | Sim | Log | Pass |", "|---|---|---|---|"]
    for r in sanity_r["s1"]:
        lines.append("| S1 `%s`: chance of `true` | %s | at +%.1f s | %s |" % (r["board"], pct(r["sim"]), r["logged_at"], "yes" if r["sim"] > 0 else "NO"))
    lines.append("| S2 fitness boards: `true`, summed | %.2f | %d | %s |" % (sanity_r["s2_sim"], sanity_r["s2_seen"], "yes" if sanity_r["s2_ok"] else "NO"))
    lines.append("| S3 all boards: softlock, summed | %.2f | %d | %s |" % (sanity_r["s3_sim"], sanity_r["s3_seen"], "yes" if sanity_r["s3_ok"] else "NO"))
    lines += ["", "**Which row looks like the logs.** The policy is the one nearest to the logs. The log column is the same in every row: "
              "%d `true` on the fitness boards, %d softlocks on all boards." % (sanity_r["s2_seen"], sanity_r["s3_seen"]), "",
              "| Row | `true`, summed over fitness boards | Softlock, summed over all boards | Asthma off in 5 s, our default order | Asthma off in 5 s, asthma first |", "|---|---|---|---|---|"]
    for r in sanity_r["calibration"]:
        lines.append("| %s | %.2f | %.2f | %.2f | %.2f |" % (r["input"], r["true"], r["soft"], r["off_default"], r["off_asthma"]))
    lines += ["", "**Log, for the same columns:** %d, %d, and asthma off within 5 s on %d of %d fitness boards." % (
        sanity_r["s2_seen"], sanity_r["s3_seen"], sanity_r["off_seen"], len(fit)), "",
              "A sim number above the log is expected: this attacker never misses and never stops. Closure is a threshold in the "
              "attack rate, so a small change in the gap moves it a lot. **The logs clear asthma far sooner than this attacker lets our default "
              "order do.** The loggers ran their own tables, and a real attacker does not re-land paralysis on every strike. So read the "
              "asthma-first verdict as \"our table against asthma first, under pressure\", and not as what those loggers should have done.", ""]
    lines += ["## Every policy, at two rows", ""]
    for name, table in (("the base", data["table_base"]), ("`%s`, the gap row nearest to the logs" % data["log_like_row"], data["table_log_like"])):
        lines += ["**At %s,** over the %d fitness boards:" % (name, len(fit)), "",
                  "| Equilibrium | Tree | Eat order | Closure rate | Softlock s | Asthma off in 5 s |", "|---|---|---|---|---|---|"]
        for r in sorted(table, key=lambda r: (r["close"], r["soft"])):
            lines.append("| %s | %s | %s | %s | %.2f | %s |" % (r["eq"], r["tree"], r["herb"], pct(r["close"]), r["soft"], pct(r["off"])))
        lines.append("")
    ev, sh = data["evidence_eats"], data["evidence_shield"]
    total = sum(ev["eats"].values())
    lines += ["## The mechanism, from the logs", "",
              "The plan says a winner needs a mechanism in a real log, or it counts as a simulator bug.", "",
              "- **Asthma first.** In the 10 s after the %d fitness boards, bloodroot took %d of %d eats and kelp took %d. Bloodroot was the first eat on "
              "%d of %d. While asthma stays up the pipe stays shut, so slickness stays, so the salve stays shut (`cure-channels.md`)." % (
                  ev["boards"], ev["eats"].get("bloodroot", 0), total, ev["eats"].get("kelp", 0), ev["first"].get("bloodroot", 0), ev["boards"]),
              "- **The shield.** A Serpent flayed a shield %d times, a median %.2f s after it went up. The FLAY packet brought exactly one new affliction "
              "%d times, none %d times. %d strikes hit a shield and did nothing, which this model does not count. So a shield costs the attacker about "
              "one venom, and no time." % (sh["flays"], sh["median_up"], sh["gained"].get("1", 0), sh["gained"].get("0", 0), sh["bounced"]), ""]
    lines += ["## The closure rate per decision, by input", "",
              "The mean difference over the %d fitness boards, first choice minus second. The range covers the settings of the other "
              "two decisions." % len(fit), "",
              "| Input | " + " | ".join(v["title"] for v in verdict_r) + " |", "|---|" + "---|" * len(verdict_r)]
    for name, _ in SWEEP:
        row = ["| " + name]
        for v in verdict_r:
            diffs = [r["diff"] for r in v["close"]["rows"] if r["input"] == name]
            row.append("%s to %s" % (fmt(min(diffs)), fmt(max(diffs))))
        lines.append(" | ".join(row) + " |")
    lines += ["", "## The boards", "",
              "| Board | Class | FITNESS | Start | Log: soft, true, impatience (s) | Sim base: true, soft |", "|---|---|---|---|---|---|"]
    for b in boards:
        seen = b["seen"]
        # The base row, with the policy nearest to the logs.
        lines.append("| `%s` | %s | %s | %s | %s, %s, %s | %s, %s |" % (
            b["id"], b["class"], "yes" if b["fitness"] else "as if", " ".join(b["affs"]),
            seen["soft"] if seen["soft"] is not None else "-", seen["true"] if seen["true"] is not None else "-",
            seen["imp"] if seen["imp"] is not None else "-", pct(b["sim_close"]), pct(b["sim_soft"])))
    lines += ["", "A board with FITNESS \"as if\" comes from a logger with another class cure. It counts only in S3 and the softlock column.", ""]
    lines += ["## The model", ""]
    m = data["model"]
    lines += ["| Input | Value | Source |", "|---|---|---|",
              "| Eat, smoke, short salve, focus, tree | %.2f, %.2f, %.2f, %.2f, %.2f s | `clocks.json`, with the measured noise |" % (
                  m["clocks"]["eat"], m["clocks"]["smoke"], m["clocks"]["salve"], m["clocks"]["focus"], m["clocks"]["tree"]),
              "| Priority | the package's table | `ataxia_defaultCuringPrios()`, the real function |",
              "| Herb for each affliction | the first eat option | `afflictions.json` |",
              "| DSTAB | two venoms | MEASURED: 1 or 2 new afflictions in most packets |",
              "| FLAY of a shield | one venom, same gap | MEASURED: `azbErKcK`, the shield line and the whip are one attack |",
              "| Shield cost | the logger's own | Claes 4.00, Elmer and Nikita 3.40, ours 2.89 (`Equilibrium used`) |", ""]
    if data["unknown_tokens"]:
        lines += ["**Tokens with no entry, left out:** " + ", ".join("`%s` (%d)" % (k, v) for k, v in sorted(data["unknown_tokens"].items())) + ".", ""]
    lines += ["## What this stage cannot say", "",
              "- **The attacker is strong, not proven worst.** It is the strongest of three fixed orders.",
              "- **It has few suppliers:** DSTAB, FLAY, one timed impatience, and the hypochondria chain. It has no BITE, no hypnosis "
              "snap, no fratricide relapse and no limb damage.",
              "- **No rebounding and no parry.** Both favour the attacker here.",
              "- **Few boards.** The verdicts rest on %d boards from two loggers (`az`, `g`), who fought the same two Serpents." % len(fit),
              "- **No balance or mana economy.** The victim does nothing but cure. Holding offence is not tested, and a shield has no cost here "
              "except equilibrium and a late FITNESS.",
              "- **Margins under 0.5 s are not resolved** (foundations.md, item 13). A result that depends on one is not a result.", ""]
    return "\n".join(lines) + "\n"


def build():
    if lupa is None:
        raise SystemExit("lupa is not installed: pip install lupa")
    boards, unknown, costs = extract_boards()
    engine = Engine()
    model = build_model(engine.lua, model_names(boards))
    print("%d boards, %d fitness. Running %d policies." % (len(boards), sum(b["fitness"] for b in boards), len(POLICIES)), flush=True)
    cells = run_sweep(engine, boards, model)
    logged = policy_index("hold", "now", "default")
    for i, b in enumerate(boards):
        b["sim_close"] = p_close(cells, i, 0, logged)
        b["sim_soft"] = p_soft(cells, i, 0, logged)
    sanity_r = sanity(boards, cells)
    row_name = log_like_row(sanity_r)
    data = {"generated_by": "tools/kb_sim.py", "input_hash": input_hash(strip(boards), model), "boards": boards, "model": model,
            "unknown_tokens": unknown, "shield_cost": costs, "sanity": sanity_r, "verdicts": verdicts(boards, cells),
            "log_like_row": row_name, "table_base": policy_table(boards, cells, "base"), "table_log_like": policy_table(boards, cells, row_name),
            "evidence_eats": logged_eats(), "evidence_shield": shield_answers(),
            "cell_count": len(cells),
            # A sample only: every cell repeats from its seed, and --check re-runs these.
            "sample": {k: [cells[k]["close"], cells[k]["soft"], cells[k]["softTime"], cells[k]["asthmaOff5"], cells[k]["fitness"]]
                       for k in sorted(cells)[::SAMPLE_EVERY]}}
    os.makedirs(os.path.dirname(OUT_MD), exist_ok=True)
    with open(OUT_JSON, "w", encoding="utf-8", newline="\n") as fh:
        json.dump(data, fh, sort_keys=True, separators=(",", ":"))
        fh.write("\n")
    with open(OUT_MD, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(render_page(data))
    return data


def strip(boards):
    return [{k: v for k, v in b.items() if not k.startswith("sim_")} for b in boards]


def check():
    if lupa is None:
        print("skip: lupa is not installed")
        return 0
    with open(OUT_JSON, encoding="utf-8") as fh:
        data = json.load(fh)
    bad = 0
    with open(OUT_MD, encoding="utf-8") as fh:
        have = fh.read().replace("\r\n", "\n")
    if have != render_page(data):
        print("DIFFERS kb/sim/forward.md")
        bad += 1
    boards, _, _ = extract_boards()
    engine = Engine()
    model = build_model(engine.lua, model_names(boards))
    if input_hash(boards, model) != data["input_hash"]:
        print("STALE   kb/sim/forward.json: the boards, the model or the engine changed")
        bad += 1
    else:
        model_t = engine.table(model)
        keys = sorted(data["sample"])
        for key in keys:
            b, e, a, p = (int(x) for x in key.split("|"))
            board = boards[b]
            board_t = engine.table({k: board[k] for k in ("affs", "ready", "hchonAge") if k in board})
            env_t = engine.table(env_for(board, sweep_for(board)[e][1], ATTACKERS[a]))
            got = engine.cell(board_t, engine.table(POLICIES[p]), env_t, model_t, RUNS, cell_seed(b, e, a))
            if [got["close"], got["soft"], got["softTime"], got["asthmaOff5"], got["fitness"]] != data["sample"][key]:
                print("DIFFERS cell " + key)
                bad += 1
                break
        print("re-ran %d of %d cells" % (len(keys), data["cell_count"]))
    if bad:
        print("Run: python tools/kb_sim.py")
    else:
        print("ok      kb/sim/forward.md, kb/sim/forward.json")
    return bad


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.check:
        return 1 if check() else 0
    data = build()
    print("Sanity: %s" % ("PASS" if data["sanity"]["ok"] else "MODEL TOO WEAK"))
    for v in data["verdicts"]:
        print("%-68s close %-12s soft %s" % (v["title"], v["close"]["label"], v["soft"]["label"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
