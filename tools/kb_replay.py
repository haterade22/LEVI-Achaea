#!/usr/bin/env python3
"""Replay every log through what the victim could see, and test lock labels and route rules against the deaths.

    python tools/kb_replay.py            # write kb/mechanics/replay.md
    python tools/kb_replay.py --check    # regenerate in memory, diff, exit 1 on any difference (CI runs this)
    python tools/kb_replay.py --gate     # print the board check, the deaths, the rules and the bars to the terminal

This is step 4 of the timing plan. The route rules below came from these same logs, so a warning count is in-sample and
proves little. The false-alarm count is the stronger evidence. The next kill in a new log is the real test.

Input is what tools/kb_timing.py parses, plus the class-grab triggers and the lock-breaker table in src_new, which this
tool only reads. Output is byte-identical across runs and across Windows and Linux: everything is sorted, nothing reads
the clock or the machine, and the page is written as LF in UTF-8.
"""
import argparse
import difflib
import glob
import json
import os
import re
import sys

import kb_timing as kb

ROOT = kb.ROOT
OUT_MD = os.path.join(ROOT, "kb", "mechanics", "replay.md")
GRABS = os.path.join(ROOT, "src_new", "triggers", "levi_ataxia", "for_levi", "leviticus", "determine_class")
LOCK_LUA = os.path.join(ROOT, "src_new", "scripts", "levi_ataxia", "levi", "ataxia", "can(x)", "003_Lock_breakers.lua")
AFFLICTIONS = os.path.join(ROOT, "kb", "afflictions", "afflictions.json")

# ---------------------------------------------------------------------------------------------
# THE METRIC (frozen before this tool ran)
# ---------------------------------------------------------------------------------------------

CHAIN_GAP = 10.0        # Episodes of one level under this far apart are one chain.
FALSE_WINDOW = 15.0     # A chain with no death this close after its end is a false alarm.
LOCK_LOOKBACK = 60.0    # A death has a "lock alert" if the softlock test held in this window before it.
WARN_BAR = 5.0          # G1: a warning must be at least this long.
TWOHAND_WINDOW = 30.0   # runewarden.2h: a two-handed weapon seen in this window.
AGREEMENT_BAR = 90.0    # Step 1: a client under this is out of the gate.
MEASURE_MIN_N = 10      # A board measure with less than this is shown, and it does not decide.
UNRESOLVED = 0.5        # foundations.md, item 13: a margin under this is unresolved. It decides no bar here.

# A bleed reading on a prompt or a "You bleed" line is one tick. Ticks came 5.5 s apart in unbroken runs: median 5.5,
# largest 5.61 (attacker, 2N1HTSWZ, WKuEakBZ, JDvzR7j7). So a reading is current for one tick and a little more.
BLEED_TICK = 6.0

# A channel with a start line and no recovery line is down for at most twice its clock (foundations.md, Clocks). The
# recovery line can be lost: a blackout hides the victim's own lines (docs/kill-paths.md, Blackout).
CHANNEL_MAX = {"eat": 3.0, "lungs": 3.0, "salve": 8.0, "focus": 10.0, "tree": 28.0, "classcure": 20.0}

# ---------------------------------------------------------------------------------------------
# THE BOARD: tokens as each client prints them, and the name the rules use
# ---------------------------------------------------------------------------------------------

# The tokens come from the board census over all logs, and were checked against the game's "You have been afflicted
# with X" lines. Nikita's r is recklessness (9 of 9) and his s is sensitivity (2 of 2). Sentinel's lower-case par is
# paranoia and PAR is paralysis (kill-paths.md, The method). A limb at level 1 is broken, and at level 2 it also needs
# restoration (`JDvzR7j7` rows 1749-1752, `OwkA-G99` rows 3158-3161).
SYSTEM_TOKENS = {
    "AST": "asthma", "ANO": "anorexia", "SLCK": "slickness", "IMP": "impatience", "SAND": "sandfever", "PAR": "paralysis",
    "wear": "weariness", "PR": "prone", "IMPALED": "impaled", "haem": "haemophilia", "PYR": "pyramides",
    "fls": "flushings", "reb": "rebbies", "myc": "mycalium", "STUP": "stupidity", "rek": "recklessness",
    "ll1": "leftleg1", "rl1": "rightleg1", "la1": "leftarm1", "ra1": "rightarm1",
    "LL2": "leftleg2", "RL2": "rightleg2", "LA2": "leftarm2", "RA2": "rightarm2",
}
TOKENS = {
    "claes": SYSTEM_TOKENS, "elmer": SYSTEM_TOKENS, "earth": SYSTEM_TOKENS, "mystor": SYSTEM_TOKENS,
    "nikita": {
        "AST": "asthma", "ANO": "anorexia", "SLI": "slickness", "IMP": "impatience", "PAR": "paralysis", "w": "weariness",
        "PR": "prone", "haem": "haemophilia", "STU": "stupidity", "r": "recklessness",
        "ll1": "leftleg1", "rl1": "rightleg1", "la1": "leftarm1", "ra1": "rightarm1",
        "LEFTLEG2": "leftleg2", "RIGHTLEG2": "rightleg2", "LEFTARM2": "leftarm2", "RIGHTARM2": "rightarm2",
    },
    "sentinel": {
        "AST": "asthma", "ANO": "anorexia", "SLI": "slickness", "IMP": "impatience", "PAR": "paralysis", "WEA": "weariness",
        "prone": "prone", "hae": "haemophilia", "stu": "stupidity",
        "ll1": "leftleg1", "rl1": "rightleg1", "la1": "leftarm1", "ra1": "rightarm1",
        "Ll2": "leftleg2", "Rl2": "rightleg2", "La2": "leftarm2", "Ra2": "rightarm2",
    },
    # Our recorder's board is the +aff and -aff names from GMCP. These are the game's names, so the map holds only limbs.
    "ours": {
        "brokenleftleg": "leftleg1", "brokenrightleg": "rightleg1", "brokenleftarm": "leftarm1", "brokenrightarm": "rightarm1",
        "damagedleftleg": "leftleg2", "damagedrightleg": "rightleg2", "damagedleftarm": "leftarm2", "damagedrightarm": "rightarm2",
        "mangledleftleg": "leftleg2", "mangledrightleg": "rightleg2", "mangledleftarm": "leftarm2", "mangledrightarm": "rightarm2",
    },
}
PRESSURE_TOKEN = re.compile(r"^pressure\((\d+)\)$")
BLEED_TOKEN = re.compile(r"^bld\(?(\d+)\)?$")
BLEED_ON_PROMPT = {"claes": re.compile(r"\((\d+)B\)"), "earth": re.compile(r"\((\d+)B\)"), "elmer": re.compile(r"\((\d+)B\)"),
                   "mystor": re.compile(r"\bBl:(\d+)")}
# These three families hold the reading on every prompt while it lasts, so no token means no bleeding.
BLEED_LIVE = {"nikita", "sentinel", "mystor"}

PLAGUES = ("pyramides", "flushings", "rebbies", "mycalium", "sandfever")
LEGS1 = ("leftleg1", "rightleg1")
LEGS2 = ("leftleg2", "rightleg2")
LEGS_BROKEN = LEGS1 + LEGS2

# What each format can show. Elmer's board has no prone and no limb tokens: 0 of 3,036 prompts, in four logs. Mystor,
# Nikita and Sentinel never showed a plague, so their tokens are not known. Elmer and the Earth Lord use Claes's board
# template, so they get his plague tokens (ASSUMED: neither has fought a Pariah). Only Claes and Elmer print pressure(n).
# A term a format cannot show is "not evaluable", and a rule never guesses it.
CAPS = {
    "claes": {"board", "prone", "legs", "plagues", "pressure_board"},
    "elmer": {"board", "plagues", "pressure_board"},
    "earth": {"board", "prone", "legs", "plagues"},
    "mystor": {"board", "prone", "legs"},
    "nikita": {"board", "prone", "legs"},
    "sentinel": {"board", "prone", "legs"},
    "blademaster": set(),
    "ours": {"board", "prone", "legs", "plagues"},
}


def read_terms(family, board):
    """Turn a prompt's tokens into the names the rules use. Returns (terms, pressure, bleed). A token with no name stays
    out: the rules read only the names here."""
    if board is None:
        return None, None, None
    table = TOKENS.get(family, {})
    terms, pressure, bleed = set(), None, None
    for tok in board:
        m = PRESSURE_TOKEN.match(tok)
        if m:
            pressure = int(m.group(1))
            continue
        m = BLEED_TOKEN.match(tok)
        if m:
            bleed = int(m.group(1))
            continue
        if family == "ours":
            terms.add(table.get(tok, tok))
        elif tok in table:
            terms.add(table[tok])
    return terms, pressure, bleed


# ---------------------------------------------------------------------------------------------
# THE LINES the rules read
# ---------------------------------------------------------------------------------------------

PRESSURE_GAIN = re.compile(r"^As the dark intent of \w+ falls upon you, you feel the air surrounding you begin to thrum")
PRESSURE_LESS = re.compile(r"^As the pressure around you normalises somewhat")
PRESSURE_CLEAR = re.compile(r"^The oppressive pressure weighing down on you lifts")
LINE_EVENTS = (
    ("infest", re.compile(r"something shifting and undulating beneath your skin")),
    ("decisive", re.compile(r"\bdecisively snaps \w+ fingers")),
    ("impale", re.compile(r"plunges it deep into your helpless body impaling it")),
    ("trip", re.compile(r"^[A-Z][a-z]+ swiftly sweeps your feet out from beneath you with")),
    ("planting", re.compile(r"^Planting \w+ foot between yours, ")),
)
# "in his hands" is how the game prints a two-handed wield (`CxxKSMq` row 1296: both the bastard sword and the hammer).
# The attack lines are the package's own 2H signatures (028_Knight_2H_Class_Grab.lua).
TWOHAND = re.compile(
    r"^[A-Z][a-z]+ starts to wield .+ in (?:his|her|their) hands\."
    r"|^[A-Z][a-z]+ brings .+ down upon you with a brutal overhand blow"
    r"|^[A-Z][a-z]+ explodes upward from a low crouch, driving .+ toward your"
    r"|^[A-Z][a-z]+ comes around with a terrible swing of .+ toward your"
    r"|^[A-Z][a-z]+ unleashes a terrible blow at your .+ with"
    r"|^(?!You\b).*\b(?:bastard sword|warhammer)\b")
DEATH = re.compile(r"^You have been slain by (.+?)\.?\s*$")
BLEED_LINE = re.compile(r"^You bleed (\d+) health")

LIMB_WORDS = r"(left leg|right leg|left arm|right arm|head|torso)"
LIMB_ORDER = ("head", "torso", "left arm", "right arm", "left leg", "right leg")
# Three readouts of the logger's own limbs. "dealt" is game text. A row of six numbers is the Earth Lord client's ledger:
# the order fits every "LIMB DAMAGE" row before it (`OwkA-G99` rows 2927-2935). In the Sentinel family the same shape is
# the TARGET's limbs (`Sentinel` rows 3, 843), so it is read only in family earth. A prompt's own block is also the target.
LIMB_DEALT = re.compile(r"you perceive that \w+ ha(?:s|ve) dealt ([\d.]+)% damage to your " + LIMB_WORDS)
LIMB_ECHO = re.compile(r"^ LIMB DAMAGE: " + LIMB_WORDS + r" \(([\d.]+)%\)")
LIMB_MY = re.compile(r"^My (Left leg|Right leg|Left arm|Right arm|Head|Torso): ([\d.]+)%")
LIMB_ROW = re.compile(r"\[([\d.]+)\|([\d.]+)\|([\d.]+)\|([\d.]+)\|([\d.]+)\|([\d.]+)\]\s*$")
LIMB_RESET = re.compile(r"^\[SLC\]: Reset " + LIMB_WORDS + r" counts|^Your " + LIMB_WORDS + r" feels stronger and healthier")
LIMB_RESET_ALL = re.compile(r"^\[SLC\]: Reset all limb counts")

# The own-cure lines come from curing_bals/006_Active_Used.lua and 007_Active_Ready.lua. A channel's start and recovery
# lines come from kb_timing, so the two tools read a clock the same way.
ACTIVE_USED = re.compile(
    r"^(?:Directing the energy of salt, you surround yourself|You inhale deeply, purging yourself of your asthmatic condition"
    r"|You let out a great keening|You press the Fool tarot to your forehead|Focusing inward, you purge your body"
    r"|You feel a soothing warmth filling your extremities|You accelerate your body's ability to purge afflictions"
    r"|You summon spirits of fire to burn off|You summon up the magma that courses beneath your outer layers)")
ACTIVE_READY = re.compile(
    r"^(?:You may channel alchemical energy to heal yourself once again|You may purge your lungs once again"
    r"|You may heal another affliction|Your body has recovered enough to shrug afflictions once again"
    r"|You may cure your afflictions with spiritual energy once again|You may accelerate time to cleanse your afflictions once again"
    r"|You may purge your great form of afflictions once again|You may boil your blood once again"
    r"|You may purge yourself of weakness once again)")
RECOVERY_LINES = (("eat", re.compile(r"^You may eat another plant or mineral")),
                  ("lungs", re.compile(r"^Your lungs have recovered enough to smoke")),
                  ("salve", re.compile(r"^You may apply another salve to yourself")),
                  ("tree", re.compile(r"^You may utilise the tree tattoo again")),
                  ("focus", re.compile(r"^Your mind is able to focus once again")),
                  ("classcure", ACTIVE_READY))

# Balance and equilibrium print as flags on the prompt, in four shapes. Claes and Sentinel print neither, so there they
# are unknown, and an exit that needs them is not counted as open.
FLAGS = {
    "earth": re.compile(r"R:\d+ \d\d:\d\d\.\d\d-([a-zA-Z*]*)-"),
    "elmer": re.compile(r"Rage:\d+ \d\d:\d{3} -([a-zA-Z*]*)-"),
    "nikita": re.compile(r"\d+e \d+w ([a-zA-Z]*) "),
    "ours": re.compile(r"\s([a-z]*)-\d*-?$"),
}
MYSTOR_FLAGS = re.compile(r"^\[(B|-)\|(E|-)\]")


def prompt_balances(family, text):
    """(balance, equilibrium) as True, False or None when this format does not print them."""
    if family == "mystor":
        m = MYSTOR_FLAGS.match(text)
        return (m.group(1) == "B", m.group(2) == "E") if m else (None, None)
    regex = FLAGS.get(family)
    if not regex:
        return None, None
    m = regex.search(text)
    if not m:
        return None, None
    return "x" in m.group(1), "e" in m.group(1)


# ---------------------------------------------------------------------------------------------
# CLASS EVIDENCE: what the log itself shows, up to the moment it is read
# ---------------------------------------------------------------------------------------------

# These triggers date from 2026-03-05, before all of the 2026-11-01 logs, so they cannot have been fitted to them. The
# knight triggers (011, 028, 029, 030) are left out. They are shared by all knights, and the package falls back to
# "Runewarden" only because it has no better answer. `OwkA-G99` row 46 shows why: a Blademaster prints the 011 line.
GENERIC_GRABS = ("011_", "028_", "029_", "030_")
GRAB_CLASS_BY_FILE = {"006_": "Monk", "017_": "Jester"}
# A long pattern folds onto an indented row (001_Airlord_Class_Grab.lua:43-44), so a pattern runs up to its "type:" row.
GRAB_PATTERN = re.compile(r"^- pattern: (.*(?:\n {4}\S.*)*)$", re.M)
GRAB_CLASS = re.compile(r'setAttackerClass\(matches\[2\], "([^"]+)"\)')
NOT_A_NAME = {"A", "An", "The", "You", "Your", "Someone", "Something"}
# The logger's own class echoes. A knight word says nothing about which knight (Legacy prints "2H" for `CxxKSMq` row 226).
LEGACY = re.compile(r"^\[Legacy\]: Curing against (\w+) \((\w+)\)")
LEGACY_CLASS = {"Airlord": "Airlord", "Apostate": "Apostate", "Pariah": "Pariah", "RunewardenSnB": "Runewarden",
                "Sentinel": "Sentinel", "Serpent": "Serpent", "Tekura": "Monk"}
TARGET_ECHO = re.compile(r"Target set to: (\w+) \(Level \d+ (\w+)\)")
TARGET_CLASS = {"Shikudo": "Monk", "Tekura": "Monk"}
# Lines the package has no trigger for. Only a Runewarden sketches: `2N1HTSWZ` row 47 and `J7Xnr_Jg` row 384. Only runes flash
# on a weapon: `CxxKSMq` row 755. Rows are 0-based. The flash line prints in that one log, the log its warning counts on, so
# it was chosen after reading that log, and RULE_FAMILY_NOTE says so on the page. It wraps before the name, so the name comes
# from the next row.
SKETCHING = re.compile(r"^(?:With a pointed stick, )?([A-Z][a-z]+) (?:begins|finishes) sketching a ")
RUNE_FLASH = re.compile(r"^The \w+ rune flashes bright upon .+ in the hands of\s*([A-Z][a-z]+)?\.?\s*$")
NAME_ROW = re.compile(r"^([A-Z][a-z]+)\.?\s*$")


def read_grabs():
    """The package's class signatures, as [(regex, class)]."""
    out = []
    for path in sorted(glob.glob(os.path.join(GRABS, "*_Class_Grab.lua"))):
        base = os.path.basename(path)
        if base.startswith(GENERIC_GRABS):
            continue
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        m = GRAB_CLASS.search(text)
        cls = m.group(1) if m else GRAB_CLASS_BY_FILE.get(base[:4])
        if not cls:
            continue
        for pattern in GRAB_PATTERN.findall(text):
            out.append((re.compile(" ".join(part.strip() for part in pattern.split("\n"))), cls))
    return out


SIGNS = read_grabs()
_sign_cache = {}


def line_class(text):
    """(person, class) if this line shows one, else None. Lines repeat a lot, so the answer is kept per text."""
    if text in _sign_cache:
        return _sign_cache[text]
    found = None
    m = LEGACY.match(text)
    if m:
        cls = LEGACY_CLASS.get(m.group(1))
        found = (m.group(2), cls) if cls else None
    if not found:
        m = TARGET_ECHO.search(text)
        if m:
            found = (m.group(1), TARGET_CLASS.get(m.group(2), m.group(2)))
    if not found:
        m = SKETCHING.match(text)
        if m:
            found = (m.group(1), "Runewarden")
    if not found:
        for regex, cls in SIGNS:
            m = regex.search(text)
            if m and m.groups() and m.group(1) and m.group(1) not in NOT_A_NAME:
                found = (m.group(1), cls)
                break
    _sign_cache[text] = found
    return found


# ---------------------------------------------------------------------------------------------
# THE LOGGER'S CLASS: only for the existing "true" label and the class cure
# ---------------------------------------------------------------------------------------------

LOGGER_CLASS_WORDS = {"shikudo": "Monk", "runewarden-snb": "Runewarden", "runewarden": "Runewarden", "earthlord": "Earth Lord",
                      "alchemist": "Alchemist", "depthswalker": "Depthswalker", "blademaster": "Blademaster"}
# kb/afflictions/class-cures.md:51 (HELP). The code has no row for an Earth Lord, and reads it the other way round. See
# class_cure_blocked and kb/CONFLICTS.md #54.
CURE_BLOCKERS_EXTRA = {"Earth Lord": "weariness"}


def read_blockers():
    """ACTIVE_CURE_BLOCKERS from the code, so the label replays what the package does today."""
    with open(LOCK_LUA, encoding="utf-8") as fh:
        text = fh.read()
    block = text[text.index("ACTIVE_CURE_BLOCKERS = {"):]
    block = block[:block.index("\n}")]
    return dict(re.findall(r'(\w+) = \{"(\w+)"\}', block))


BLOCKERS = read_blockers()


def logger_class(log):
    if log.family == "ours":
        return log.our_class
    if "shikudo-group" in log.name:
        return "Monk"
    for part in log.name.split("_"):
        if "-vs-" in part:
            return LOGGER_CLASS_WORDS.get(part.split("-vs-")[0])
    return None


def client_of(log):
    """The client a log came from. Our four recordings are one client, whatever class we played."""
    return "Ours, recorder" if log.family == "ours" else log.logger


# ---------------------------------------------------------------------------------------------
# THE ROUTE RULES, as data. Written from the tells in docs/kill-paths.md, which came from these deaths, and fixed before this
# tool ran them.
# ---------------------------------------------------------------------------------------------

# An exit is an action that could still break the route. It names the channel it needs, and what shuts it.
# only_if: the exit means nothing unless this is on the board.
EXIT_TREE = {"name": "touch tree", "channel": "tree", "blocked_by": ["paralysis"], "does": "cures one random affliction"}
EXIT_LEAVE = {"name": "leave the room", "channel": "move", "blocked_by": ["prone", "paralysis", "impaled"] + list(LEGS_BROKEN),
              "does": "resets the race: Latency came 10.3 s later when the victim left first (foundations.md, item 12)"}
EXIT_RESTORE = {"name": "apply restoration to a leg", "channel": "salve", "blocked_by": ["slickness"],
                "does": "takes a level off the leg, 4 s; then mending, then stand"}
EXIT_STAND = {"name": "stand", "channel": "balance", "blocked_by": ["paralysis"] + list(LEGS_BROKEN), "only_if": ["prone"],
              "does": "ends prone, which these routes need"}
EXIT_WRITHE = {"name": "writhe off the blade", "channel": "balance", "blocked_by": [], "only_if": ["impaled"],
               "does": "ends the impale (time to free 2.01-5.54 s, clocks study)"}

RULES = (
    {
        "id": "pariah.latency", "class": "Pariah",
        "cite": "docs/kill-paths.md:133, `Vr.NkCGD`, `WKuEakBZ`",
        "clauses": (
            {"text": "3 or more of the five plagues on the board", "terms": (("count_min", PLAGUES, 3),)},
            {"text": "2 or more plagues, then Infest (\"undulating\")",
             "terms": (("count_min", PLAGUES, 2), ("then", "infest"))},
        ),
        "exits": ({"name": "eat a plague cure", "channel": "eat", "blocked_by": ["anorexia"],
                   "does": "takes a plague off the count (cure-channels.md)"}, EXIT_TREE, EXIT_LEAVE),
    },
    {
        "id": "pariah.scourge", "class": "Pariah",
        "cite": "docs/kill-paths.md:134, `4c_SeyaA`",
        "clauses": (
            {"text": "bleeding 150 or more with haemophilia", "terms": (("bleed_min", 150), ("all", ("haemophilia",)))},
            {"text": "\"decisively snaps\" with haemophilia up", "terms": (("event", "decisive"), ("all", ("haemophilia",)))},
        ),
        "exits": ({"name": "eat ginseng or ferrum", "channel": "eat", "blocked_by": ["anorexia"],
                   "does": "cures haemophilia, a term of the route (foundations.md, Refuted: 20 of 20 on ferrum)"},
                  EXIT_TREE, EXIT_LEAVE),
    },
    {
        "id": "airlord.pressure", "class": "Airlord",
        "cite": "docs/kill-paths.md:135, `s98kPGv6`",
        "clauses": (
            {"text": "pressure(3) or higher on the board", "terms": (("pressure_board_min", 3),)},
            {"text": "3 or more pressure gains by the line, less the losses", "terms": (("pressure_line_min", 3),)},
        ),
        "exits": ({"name": "eat pear or calcite", "channel": "lungs", "blocked_by": ["anorexia"],
                   "does": "removes one pressure, and spends the lungs (cure-channels.md)"},
                  {"name": "smoke elm or valerian", "channel": "lungs", "blocked_by": ["asthma"],
                   "does": "takes deadening or manaleech off, so the next gain is smaller (fit 6 of 6, cause INFERRED)"}),
    },
    {
        "id": "runewarden.2h", "class": "Runewarden",
        "cite": "docs/kill-paths.md:136, `CxxKSMq`",
        "clauses": (
            {"text": "prone with a leg at level 2", "terms": (("all", ("prone",)), ("any", LEGS2))},
            {"text": "an impale while a bastard sword or two-handed weapon was seen in the last 30 s",
             "terms": (("impale",), ("event_within", "twohand", TWOHAND_WINDOW))},
        ),
        "exits": (EXIT_RESTORE, EXIT_STAND, EXIT_WRITHE),
    },
    {
        "id": "blademaster.legs", "class": "Blademaster",
        "cite": "docs/kill-paths.md:138, `OwkA-G99`",
        "clauses": (
            {"text": "one leg at 60% or more and the other at 50% or more", "terms": (("legs_pct", 60.0, 50.0),)},
            {"text": "\"Planting his foot\" with a broken leg", "terms": (("event", "planting"), ("any", LEGS_BROKEN))},
        ),
        "exits": (EXIT_RESTORE, EXIT_STAND, EXIT_LEAVE),
    },
    {
        "id": "sentinel.tripimpale", "class": "Sentinel",
        "cite": "docs/kill-paths.md:139, `JDvzR7j7`, `uW_VbgR`",
        "clauses": (
            {"text": "TRIP's prone with a leg broken", "terms": (("then_while", "trip", "prone"), ("any", LEGS_BROKEN))},
            {"text": "an impale", "terms": (("impale",),)},
        ),
        "exits": (EXIT_RESTORE, EXIT_STAND, EXIT_WRITHE),
    },
    {
        "id": "generic.limb", "class": None,
        "cite": "docs/kill-paths.md:50 (SKULLBASH: prone and head), :138 (both legs), :141 (DISPATCH: head parked, then prone)",
        "clauses": (
            {"text": "both legs at 90% or more", "terms": (("legs_pct", 90.0, 90.0),)},
            {"text": "the head at 90% or more with prone", "terms": (("head_pct", 90.0), ("all", ("prone",)))},
        ),
        "exits": (EXIT_RESTORE, EXIT_STAND, EXIT_LEAVE),
    },
)

# The named-exit output for a lock (G5). Smoke, salve and eat are shut by the softlock itself, so only these remain.
LOCK_EXITS = (
    {"name": "focus", "channel": "focus", "blocked_by": ["impatience"], "does": "cures anorexia, or a mental first"},
    EXIT_TREE,
    {"name": "class cure", "channel": "classcure", "blocked_by": [], "does": "the logger's own lock breaker"},
)

TERM_NEEDS = {
    "count_min": "plagues", "pressure_board_min": "pressure_board", "legs_pct": "limb_pct", "head_pct": "limb_pct",
}


def term_needs(term):
    """What a term needs the format to show. Lines and bleed ticks print in every family."""
    kind = term[0]
    if kind in TERM_NEEDS:
        return TERM_NEEDS[kind]
    if kind == "all" and "prone" in term[1]:
        return "prone"
    if kind == "any":
        return "legs"
    if kind == "all":
        return "board"
    if kind == "then_while":
        return term[2]
    return None


def format_caps(log):
    caps = set(CAPS.get(log.family, ()))
    readouts = 0
    for row in log:
        if row.kind == "line" and (LIMB_DEALT.search(row.text) or LIMB_ECHO.match(row.text) or LIMB_MY.match(row.text)):
            readouts += 1
    if readouts:
        caps.add("limb_pct")
    return caps, readouts


# ---------------------------------------------------------------------------------------------
# THE WALK: one forward pass. Nothing here can read a row after the prompt it is at.
# ---------------------------------------------------------------------------------------------


class Seen:
    """What the victim can know at one prompt: its board, and the lines up to it. walk() yields this object at each prompt.
    The lines of a packet print with the prompt that closes it, which is also where the one stamp rule puts them."""

    def __init__(self, log):
        self.family = log.family
        self.row = None
        self.t = None
        self.terms = None
        self.events = {}           # event -> first row of it in this packet
        self.event_t = {}          # event -> stamp of the last packet that held it
        self.bleed = 0
        self.bleed_t = None
        self.pressure_board = None
        self.pressure_line = 0
        self.limbs = dict.fromkeys(LIMB_ORDER, 0.0)
        self.classes = {}          # person -> class, the latest evidence
        self.class_rows = {}       # class -> first row that showed it
        self.clock = {}            # channel -> stamp of the start, while it is down
        self.bal = self.eq = None
        self.death_row = None
        self.killer = None
        self.death_t = None

    def channel_ready(self, channel):
        """True, False, or None when this format cannot say."""
        if channel == "balance":
            return self.bal
        if channel == "move":
            # Moving needs both: Elmer queues his moves in the free queue, and a failed leave costs balance (foundations, item 12).
            if self.bal is None or self.eq is None:
                return None
            return self.bal and self.eq
        start = self.clock.get(channel)
        return start is None or self.t - start >= CHANNEL_MAX[channel]


def walk(log):
    """Yield a Seen at each prompt, until the logger dies. The death row sets death_t and the walk stops there."""
    s = Seen(log)
    pending_start = set()
    bleed_line = False
    await_name = False
    earth = log.family == "earth"
    for row in log:
        if row.kind == "prompt":
            s.row = row
            s.t = row.own
            s.terms, s.pressure_board, token_bleed = read_terms(log.family, row.board)
            for channel in pending_start:
                s.clock[channel] = s.t
            pending_start = set()
            for event in s.events:
                s.event_t[event] = s.t
            regex = BLEED_ON_PROMPT.get(log.family)
            m = regex.search(row.text) if regex else None
            if bleed_line:
                # One stamp rule: the line's time is this prompt.
                s.bleed_t = s.t
                bleed_line = False
            if m:
                s.bleed, s.bleed_t = int(m.group(1)), s.t
            elif log.family in BLEED_LIVE:
                s.bleed, s.bleed_t = token_bleed or 0, s.t
            elif s.bleed_t is not None and s.t - s.bleed_t > BLEED_TICK:
                s.bleed = 0
            s.bal, s.eq = prompt_balances(log.family, row.text)
            yield s
            s.events = {}
            continue
        if row.kind != "line" or not row.text:
            continue
        text = row.text
        m = DEATH.match(text)
        if m:
            # Every client log ends its last packet in the death, with no prompt after it. So the stamp here is the LAST
            # prompt before the death row, and each warning is a floor: the true death came a little later.
            s.death_row, s.killer, s.death_t = row.n, m.group(1), s.t
            return
        if await_name:
            await_name = False
            m = NAME_ROW.match(text)
            if m:
                s.classes[m.group(1)] = "Runewarden"
                s.class_rows.setdefault("Runewarden", row.n)
        m = RUNE_FLASH.match(text)
        if m:
            if m.group(1):
                s.classes[m.group(1)] = "Runewarden"
                s.class_rows.setdefault("Runewarden", row.n)
            else:
                await_name = True
        found = line_class(text)
        if found:
            s.classes[found[0]] = found[1]
            s.class_rows.setdefault(found[1], row.n)
        for event, regex in LINE_EVENTS:
            if regex.search(text):
                s.events.setdefault(event, row.n)
        if TWOHAND.search(text):
            s.events.setdefault("twohand", row.n)
        if PRESSURE_CLEAR.search(text):
            s.pressure_line = 0
        elif PRESSURE_GAIN.search(text):
            s.pressure_line += 1
        elif PRESSURE_LESS.search(text):
            s.pressure_line = max(0, s.pressure_line - 1)
        m = BLEED_LINE.match(text)
        if m:
            s.bleed = int(m.group(1))
            bleed_line = True
        read_limb_line(s, text, earth)
        read_channel_line(pending_start, s, text)
    # A log with no death just stops here.


def read_limb_line(s, text, earth):
    m = LIMB_DEALT.search(text)
    if m:
        s.limbs[m.group(2)] += float(m.group(1))
    m = LIMB_ECHO.match(text)
    if m:
        s.limbs[m.group(1)] = float(m.group(2))
    m = LIMB_MY.match(text)
    if m:
        s.limbs[m.group(1).lower()] = float(m.group(2))
    if earth:
        m = LIMB_ROW.search(text)
        if m:
            for name, value in zip(LIMB_ORDER, m.groups()):
                s.limbs[name] = float(value)
    m = LIMB_RESET.match(text)
    if m:
        s.limbs[m.group(1) or m.group(2)] = 0.0
    elif LIMB_RESET_ALL.match(text):
        s.limbs = dict.fromkeys(LIMB_ORDER, 0.0)


def read_channel_line(pending, s, text):
    channel = None
    m = kb.EAT_START.match(text)
    if m:
        what = m.group(1)
        if kb.EAT_LUNGS.search(what):
            channel = "lungs"
        elif not kb.EAT_MOSS.search(what) and not kb.EAT_NOT_A_CLOCK.search(what):
            channel = "eat"
    elif kb.SMOKE_START.match(text):
        channel = "lungs"
    elif kb.SALVE_START.match(text):
        channel = "salve"
    elif kb.TREE_START.match(text):
        channel = "tree"
    elif kb.FOCUS_START.match(text):
        channel = "focus"
    elif ACTIVE_USED.match(text):
        channel = "classcure"
    if channel:
        pending.add(channel)
        return
    for name, regex in RECOVERY_LINES:
        if regex.match(text):
            pending.discard(name)
            s.clock.pop(name, None)
            return


# ---------------------------------------------------------------------------------------------
# LABELS, CHAINS AND RULES
# ---------------------------------------------------------------------------------------------


def lock_count(terms):
    """ataxia_lockComponents: asthma, slickness or bloodfire, anorexia."""
    return sum((("asthma" in terms), ("slickness" in terms or "bloodfire" in terms), ("anorexia" in terms)))


def is_softlock(terms):
    return lock_count(terms) == 3


def class_cure_blocked(s, cls, game=False):
    """not ataxia_canActive(), as the code runs it today (003_Lock_breakers.lua:226-254).

    The code has no row for an Earth Lord. For a class holding "Elemental" it returns true only WITH weariness up
    (003_Lock_breakers.lua:240-245), the reverse of class-cures.md:51. That is what the existing label does today, so the
    replay does it too. game=True uses the game's blocker instead. Only the reproduction of the earlier count uses it."""
    start = s.clock.get("classcure")
    if start is not None and s.t - start < CHANNEL_MAX["classcure"]:
        return True
    terms = s.terms
    if cls == "Earth Lord" and not game:
        return "weariness" not in terms
    blocker = BLOCKERS.get(cls) or (CURE_BLOCKERS_EXTRA.get(cls) if game else None)
    if blocker is None:
        return True
    both_arms = ("leftarm1" in terms or "leftarm2" in terms) and ("rightarm1" in terms or "rightarm2" in terms)
    if both_arms and blocker != "weariness":
        return True
    return blocker in terms


def is_true(s, cls, game=False):
    """ataxia_promptLocks: soft, then hard, then true."""
    terms = s.terms
    return (is_softlock(terms) and ("impatience" in terms or "sandfever" in terms) and "paralysis" in terms
            and class_cure_blocked(s, cls, game))


LABELS = ("2-of-3", "softlock", "true")


def eval_term(term, s):
    """Is this term true at this prompt? Only s is read, and s holds nothing later than this prompt."""
    kind = term[0]
    terms = s.terms
    if kind == "count_min":
        return terms is not None and sum(1 for x in term[1] if x in terms) >= term[2]
    if kind == "all":
        return terms is not None and all(x in terms for x in term[1])
    if kind == "any":
        return terms is not None and any(x in terms for x in term[1])
    if kind == "bleed_min":
        return s.bleed >= term[1]
    if kind == "pressure_board_min":
        return s.pressure_board is not None and s.pressure_board >= term[1]
    if kind == "pressure_line_min":
        return s.pressure_line >= term[1]
    if kind == "event":
        return term[1] in s.events
    if kind == "impale":
        return "impale" in s.events or (terms is not None and "impaled" in terms)
    if kind == "event_within":
        seen = s.event_t.get(term[1])
        return term[1] in s.events or (seen is not None and s.t - seen <= term[2])
    if kind == "legs_pct":
        left, right = s.limbs["left leg"], s.limbs["right leg"]
        return (left >= term[1] and right >= term[2]) or (right >= term[1] and left >= term[2])
    if kind == "head_pct":
        return s.limbs["head"] >= term[1]
    raise ValueError("unknown term %r" % (term,))


def eval_clause(clause, s, latches, key):
    """A "then" term is a latch: the event must come while the other terms hold, and it lasts while they hold.

    Infest counts only after the two plagues, so an Infest with one plague does not arm it. then_while is the same for an
    event and one board term (TRIP, while prone)."""
    others = True
    then = None
    for term in clause["terms"]:
        if term[0] == "then":
            then = (term[1], None)
        elif term[0] == "then_while":
            then = (term[1], term[2])
        elif not eval_term(term, s):
            others = False
    if then is None:
        return others
    event, hold = then
    holds = others if hold is None else (s.terms is not None and hold in s.terms)
    if not holds:
        latches.discard(key)
        return False
    if event in s.events:
        latches.add(key)
    return others and key in latches


def clause_missing(clause, caps):
    """The needs of a clause that this format cannot show. A clause with any is not evaluable."""
    return [need for need in (term_needs(t) for t in clause["terms"]) if need and need not in caps]


def exit_state(ex, s, cls):
    """The state of one exit at this prompt: open, shut by X, clock down, unknown, or n/a."""
    terms = s.terms or set()
    for need in ex.get("only_if", ()):
        if need not in terms:
            return "n/a"
    blocked_by = list(ex["blocked_by"])
    if ex["channel"] == "classcure":
        blocker = BLOCKERS.get(cls) or CURE_BLOCKERS_EXTRA.get(cls)
        if blocker is None:
            return "unknown"
        blocked_by = [blocker]
    if s.terms is None:
        return "unknown"
    for b in blocked_by:
        if b in terms:
            return "shut by " + b
    ready = s.channel_ready(ex["channel"])
    if ready is None:
        return "unknown"
    return "open" if ready else "clock down"


def exit_report(exits, s, cls):
    return [(ex["name"], ex["channel"], exit_state(ex, s, cls)) for ex in exits]


class Track:
    """Episodes of one level in one log."""

    def __init__(self):
        self.episodes = []
        self.open = None

    def feed(self, on, s, payload=None):
        if on:
            if self.open is None:
                self.open = [s.t, s.row.n, s.t, s.row.n, payload]
            else:
                self.open[2], self.open[3] = s.t, s.row.n
        elif self.open is not None:
            self.episodes.append(self.open)
            self.open = None

    def close(self):
        if self.open is not None:
            self.episodes.append(self.open)
            self.open = None


def merge_chains(episodes, gap=CHAIN_GAP):
    """A chain is episodes of the same level under gap seconds apart. Each chain keeps what its first episode saw."""
    chains = []
    for t0, n0, t1, n1, payload in episodes:
        if chains and t0 - chains[-1]["end"] < gap:
            chains[-1]["end"], chains[-1]["end_row"] = t1, n1
            chains[-1]["episodes"] += 1
        else:
            chains.append({"start": t0, "start_row": n0, "end": t1, "end_row": n1, "episodes": 1, "seen": payload})
    return chains


def judge(chain, death_t, last_row):
    """fatal, false, or open. A fatal chain is not a false alarm. A chain still running at the last prompt of a log with no
    death has no future to read (`uW_VbgR` is cut there), so it stays open and counts as neither."""
    if death_t is not None and chain["start"] <= death_t and chain["end"] >= death_t - FALSE_WINDOW:
        return "fatal"
    if death_t is None and chain["end_row"] == last_row:
        return "open"
    return "false"


class Replay:
    """Everything one log gave. Built by one forward pass."""

    def __init__(self, log):
        self.log = log
        self.cls = logger_class(log)
        self.client = client_of(log)
        self.same_fight = log.name in kb.SAME_FIGHT
        self.death_row = None
        self.killer = None
        self.death_t = None
        self.class_rows = {}
        self.classes_at_death = {}
        self.first_t = None
        self.last_t = None
        self.last_prompt = None
        self.labels = {}
        self.rules = {}
        self.fought = set()
        self.caps, self.readouts = format_caps(log)
        self.soft_last = None
        self.missing = {}
        self.evaluable = {}
        # What this fight showed of runewarden.2h's own terms, and from when its class was known.
        self.terms_2h = dict.fromkeys(("prone", "leg2", "both", "impaled", "twohand"), 0)
        self.allowed_from = {}


def count_2h_terms(rep, s):
    """Count what runewarden.2h needs. A PASS on false alarms says little if a fight never showed these."""
    terms = s.terms or set()
    prone = "prone" in terms
    leg2 = any(x in terms for x in LEGS2)
    rep.terms_2h["prone"] += prone
    rep.terms_2h["leg2"] += leg2
    rep.terms_2h["both"] += prone and leg2
    rep.terms_2h["impaled"] += "impaled" in terms or "impale" in s.events
    rep.terms_2h["twohand"] += "twohand" in s.events


def run_log(log, rules=RULES):
    """Replay one log. Returns a Replay. Every decision reads only the Seen at that prompt."""
    rep = Replay(log)
    tracks = {name: Track() for name in LABELS}
    tracks["true, game blocker"] = Track()
    rule_tracks = {rule["id"]: Track() for rule in rules}
    latches = set()
    for rule in rules:
        missing = {}
        for i, clause in enumerate(rule["clauses"]):
            need = clause_missing(clause, rep.caps)
            if need:
                missing[i] = need
        rep.missing[rule["id"]] = missing
        rep.evaluable[rule["id"]] = len(missing) < len(rule["clauses"])
    if log.family is None:
        return rep
    s = None
    for s in walk(log):
        rep.first_t = s.t if rep.first_t is None else rep.first_t
        rep.last_t = s.t
        rep.last_prompt = s.row.n
        count_2h_terms(rep, s)
        if s.terms is not None:
            count = lock_count(s.terms)
            tracks["2-of-3"].feed(count >= 2, s)
            soft = count == 3
            payload = {"exits": exit_report(LOCK_EXITS, s, rep.cls), "bal": s.bal, "eq": s.eq} if soft else None
            tracks["softlock"].feed(soft, s, payload)
            if soft:
                rep.soft_last = s.t
            tracks["true"].feed(soft and is_true(s, rep.cls), s, payload)
            tracks["true, game blocker"].feed(soft and is_true(s, rep.cls, True), s, payload)
        known = set(s.classes.values())
        for rule in rules:
            allowed = rule["class"] in known if rule["class"] else not known
            if allowed:
                rep.fought.add(rule["id"])
                rep.allowed_from.setdefault(rule["id"], s.t)
            hit = None
            for i, clause in enumerate(rule["clauses"]):
                if i in rep.missing[rule["id"]]:
                    continue
                # The latch runs even before the class is known: what the victim saw stays seen.
                if eval_clause(clause, s, latches, (rule["id"], i)) and allowed and hit is None:
                    hit = clause["text"]
            payload = None
            if hit:
                payload = {"clause": hit, "exits": exit_report(rule["exits"], s, rep.cls),
                           "class_row": s.class_rows.get(rule["class"])}
            rule_tracks[rule["id"]].feed(bool(hit), s, payload)
    for track in list(tracks.values()) + list(rule_tracks.values()):
        track.close()
    if s is not None:
        rep.death_row, rep.killer, rep.death_t = s.death_row, s.killer, s.death_t
        rep.class_rows = dict(s.class_rows)
        rep.classes_at_death = dict(s.classes)
    rep.labels = {name: merge_chains(tracks[name].episodes) for name in tracks}
    rep.rules = {rule["id"]: merge_chains(rule_tracks[rule["id"]].episodes) for rule in rules}
    return rep


# ---------------------------------------------------------------------------------------------
# AFTERWARDS, FOR THE REVIEWER. These read ahead on purpose, and no rule or bar uses them.
# ---------------------------------------------------------------------------------------------

USE_LINES = {"focus": kb.FOCUS_START, "touch tree": kb.TREE_START, "class cure": ACTIVE_USED}
REFUSAL_LINES = {"class cure": re.compile(r"^Your body is too weary to perform such a feat")}


def channel_back(log, row_n, t, channel):
    """Seconds until this channel's next recovery line after row_n, or None."""
    regex = dict(RECOVERY_LINES).get(channel)
    if regex is None:
        return None
    for row in log:
        if row.n <= row_n or row.kind != "line":
            continue
        if regex.match(row.text):
            return (row.time - t) if row.time is not None else None
    return None


def first_use(log, row_n, name, stop_row, t):
    """What the log shows after an alert: the first use of this exit, and the first refusal, as (seconds, row) or None."""
    use, refused = None, None
    regex, refuse = USE_LINES.get(name), REFUSAL_LINES.get(name)
    for row in log:
        if row.n <= row_n or row.kind != "line" or row.n >= stop_row or row.time is None:
            continue
        if regex and use is None and regex.match(row.text):
            use = (row.time - t, row.n)
        if refuse and refused is None and refuse.match(row.text):
            refused = (row.time - t, row.n)
    return use, refused


# ---------------------------------------------------------------------------------------------
# STEP 1: THE BOARD CHECK
# ---------------------------------------------------------------------------------------------

# The terms the rules read that have a game line. The lines come from `AFFLICTION SHOW` (kb/afflictions/afflictions.json),
# a live capture that does not come from these logs. Prone and the limb levels have no such line.
CHECK_TERMS = ("anorexia", "asthma", "flushings", "haemophilia", "impatience", "mycalium", "paralysis", "pyramides",
               "rebbies", "sandfever", "slickness", "weariness")
# Elmer's and the Earth Lord's client prints SOFTLOCKED only with impatience up: `Z5cyffxx` row 4976 shows asthma, slickness
# and anorexia with no echo, and every echo has IMP. So the echo means softlock + impatience, and that is what it is checked
# against. The first run compared it with plain softlock. See POST_HOC.
ECHO_NEEDS_IMPATIENCE = {"elmer", "earth"}
VLOCK = re.compile(r"^\[VLOCK,")


def check_lines():
    with open(AFFLICTIONS, encoding="utf-8") as fh:
        data = json.load(fh)
    gain, cure = [], []
    for term in CHECK_TERMS:
        gain.append((data[term]["afflicted_msg"][:40], term))
        cure.append((data[term]["cured_msg"][:40], term))
        gain.append(("You have been afflicted with %s" % term, term))
        cure.append(("You have cured the %s affliction" % term, term))
    return gain, cure


def term_has_token(family, term):
    if family == "ours":
        return True
    return term in TOKENS.get(family, {}).values()


def lock_echo(log, row):
    """soft-or-higher and true, by the logger's own echo. None when this family prints no echo of the logger's own lock."""
    if log.family in ("elmer", "earth"):
        board = row.board or []
        return ("SOFTLOCKED" in board or "TRUELOCKED" in board), ("TRUELOCKED" in board)
    if log.family == "mystor":
        return row.lock in ("s", "v", "h", "true"), row.lock == "true"
    if log.family == "sentinel":
        lock = row.lock or ""
        return "soft" in lock, "true" in lock
    return None


def board_check(logs):
    """Compare the parsed board with the logger's echoes and with the game's lines. Returns {client: counts}.

    Gain: a gain line, then is the term on the next prompt's board? Cure: a cure line, then is it off? A packet with both a
    gain and a cure of one term is left out, because nothing says which came last."""
    gains, cures = check_lines()
    out = {}
    for log in logs:
        if log.family is None:
            continue
        c = out.setdefault(client_of(log), {
            "gain_ok": 0, "gain_n": 0, "cure_ok": 0, "cure_n": 0, "soft_both": 0, "soft_echo": 0, "soft_board": 0,
            "literal_both": 0, "literal_echo": 0, "literal_board": 0, "true_both": 0, "true_echo": 0, "true_board": 0,
            "prompts": 0, "has_echo": False, "has_board": False, "gain_miss": [], "cure_miss": [], "logs": set(),
            "vlock_rows": 0, "vlock_soft": 0})
        c["logs"].add(log.id)
        got_gain, got_cure = set(), set()
        vlock_pending = 0
        for row in log:
            if row.kind == "line":
                if VLOCK.match(row.text):
                    c["vlock_rows"] += 1
                    vlock_pending += 1
                for prefix, term in gains:
                    if row.text.startswith(prefix):
                        got_gain.add(term)
                for prefix, term in cures:
                    if row.text.startswith(prefix):
                        got_cure.add(term)
                continue
            if row.kind != "prompt":
                continue
            c["prompts"] += 1
            terms = read_terms(log.family, row.board)[0]
            if terms is None:
                continue
            c["has_board"] = True
            if vlock_pending:
                if is_softlock(terms):
                    c["vlock_soft"] += vlock_pending
                vlock_pending = 0
            for term in sorted(got_gain - got_cure):
                if term_has_token(log.family, term):
                    c["gain_n"] += 1
                    if term in terms:
                        c["gain_ok"] += 1
                    elif len(c["gain_miss"]) < 12:
                        c["gain_miss"].append("%s:%d %s" % (log.id, row.n, term))
            for term in sorted(got_cure - got_gain):
                if term_has_token(log.family, term):
                    c["cure_n"] += 1
                    if term not in terms:
                        c["cure_ok"] += 1
                    elif len(c["cure_miss"]) < 12:
                        c["cure_miss"].append("%s:%d %s" % (log.id, row.n, term))
            got_gain, got_cure = set(), set()
            echo = lock_echo(log, row)
            if echo is None:
                continue
            c["has_echo"] = True
            soft = is_softlock(terms)
            hard = soft and ("impatience" in terms or "sandfever" in terms) and "paralysis" in terms
            meant = soft and "impatience" in terms if log.family in ECHO_NEEDS_IMPATIENCE else soft
            count_pair(c, "soft", echo[0], meant)
            count_pair(c, "literal", echo[0], soft)
            count_pair(c, "true", echo[1], hard)
    return out


def count_pair(c, name, echo, board):
    if echo and board:
        c[name + "_both"] += 1
    elif echo:
        c[name + "_echo"] += 1
    elif board:
        c[name + "_board"] += 1


def board_measures(c):
    """Every measure of one client, as (name, ok, n). The lock echoes count only prompts where either side says locked,
    because nearly all prompts have no lock, and those would flatter the figure."""
    rows = [("gain lines", c["gain_ok"], c["gain_n"]), ("cure lines", c["cure_ok"], c["cure_n"])]
    if c["has_echo"]:
        rows.append(("softlock echo", c["soft_both"], c["soft_both"] + c["soft_echo"] + c["soft_board"]))
        rows.append(("true echo", c["true_both"], c["true_both"] + c["true_echo"] + c["true_board"]))
    return rows


def client_agreement(c):
    """The client's figure is its LOWEST measure with n >= 10. A board that is good on gains and bad on cures still misleads
    a rule, so a pooled figure would hide the fault. None when nothing could be compared."""
    if not c["has_board"]:
        return None
    pct = [100.0 * ok / n for _, ok, n in board_measures(c) if n >= MEASURE_MIN_N]
    return min(pct) if pct else None


# ---------------------------------------------------------------------------------------------
# STEPS 2 TO 4: DEATHS, BASELINES, RULES, THE GATE
# ---------------------------------------------------------------------------------------------

EARLIER = {"2-of-3": (6, 31.9, 20), "softlock": (6, 18.9, 11), "true": (5, 14.5, 0)}


def death_scope(rep):
    """Why a death is out of scope, or None. Guards and group fights have no route for a 1v1 rule (foundations.md, Limits)."""
    if rep.killer and not rep.killer[:1].isupper():
        return "killed by a denizen (guards), so no player's route"
    if rep.log.family == "ours":
        return "our own recording of a group fight, with no route (foundations.md, Limits)"
    return None


def lock_alert(rep):
    """Did the softlock test hold in the 60 s before death?"""
    if rep.death_t is None or rep.soft_last is None:
        return False
    return rep.death_t - rep.soft_last <= LOCK_LOOKBACK


def median(values):
    ordered = sorted(values)
    return kb.percentile(ordered, 0.5) if ordered else None


def label_results(reps, clients_only=False, count_open=False, true_key="true"):
    """Warned, the warning's median and range, false alarms and open chains, per label, over every log with a board.

    clients_only and count_open and true_key exist only to reproduce the earlier count. The fight in kb.SAME_FIGHT stays out,
    because it is the same fight as our recording."""
    out = {}
    for name in LABELS:
        key = true_key if name == "true" else name
        warned, false, opened = [], [], []
        for rep in reps:
            if rep.same_fight or rep.log.family is None or (clients_only and rep.log.family == "ours"):
                continue
            fatal = []
            for chain in rep.labels.get(key, ()):
                verdict = judge(chain, rep.death_t, rep.last_prompt)
                if verdict == "fatal":
                    fatal.append(chain)
                elif verdict == "open" and not count_open:
                    opened.append((rep.log.id, chain["start_row"]))
                else:
                    false.append((rep.log.id, chain["start_row"]))
            if fatal:
                warned.append((rep.log.id, rep.death_t - fatal[0]["start"], fatal[0]["start_row"]))
        values = [w[1] for w in warned]
        out[name] = {"warned": warned, "n": len(warned), "median": median(values), "min": min(values) if values else None,
                     "max": max(values) if values else None, "false": false, "open": opened}
    return out


def rule_results(reps, rules=RULES, excluded=()):
    """Per rule: warnings on deaths, false alarms in survived fights, false alarms before a later death, and what it was
    tested on. A log of an excluded client counts nowhere."""
    out = {}
    for rule in rules:
        rid = rule["id"]
        r = {"warned": [], "false_survived": [], "false_lost": [], "open": [], "fought_survived": [], "fought_lost": [],
             "not_evaluable": [], "tested_on": []}
        for rep in reps:
            if rep.same_fight or rep.log.family is None or rep.client in excluded:
                continue
            fought = rid in rep.fought
            if fought and not rep.evaluable[rid]:
                r["not_evaluable"].append((rep.log.id, "all clauses: needs " + ", ".join(sorted(
                    {n for needs in rep.missing[rid].values() for n in needs}))))
                continue
            if fought and rep.missing[rid]:
                for i in sorted(rep.missing[rid]):
                    r["not_evaluable"].append((rep.log.id, rule["clauses"][i]["text"]))
            if fought:
                (r["fought_lost"] if rep.death_t is not None else r["fought_survived"]).append(rep.log.id)
                if rep.death_t is None and rep.log.family != "ours":
                    r["tested_on"].append(rep.log.id)
            fatal = []
            for chain in rep.rules.get(rid, ()):
                verdict = judge(chain, rep.death_t, rep.last_prompt)
                if verdict == "fatal":
                    fatal.append(chain)
                elif verdict == "open":
                    r["open"].append((rep.log.id, chain["start_row"]))
                elif rep.death_t is None:
                    r["false_survived"].append((rep.log.id, chain["start_row"]))
                else:
                    r["false_lost"].append((rep.log.id, chain["start_row"]))
            if fatal:
                r["warned"].append({"log": rep.log.id, "seconds": rep.death_t - fatal[0]["start"], "chain": fatal[0],
                                    "killer": rep.killer, "off_before": min(rep.death_t - c["end"] for c in fatal)})
        # A recording of ours is a group fight (death_scope): a class in the room may be on our side. Harkon, a Pariah, is in our
        # party in ours/081532_Tabethys. So it tests no 1v1 rule. Its false alarms still count, so this only moves a bar toward FAIL.
        r["untested"] = not r["tested_on"]
        n_false, n_warned = len(r["false_survived"]), len(r["warned"])
        r["fraction"] = n_false / float(n_false + n_warned) if n_false + n_warned else None
        out[rid] = r
    return out


def build_deaths(reps, rule_res, excluded):
    deaths = []
    for rep in reps:
        if rep.death_t is None or rep.same_fight:
            continue
        d = {"log": rep.log.id, "file": rep.log.name, "row": rep.death_row, "killer": rep.killer, "t": rep.death_t,
             "scope": death_scope(rep), "lock": lock_alert(rep),
             "soft_before": (rep.death_t - rep.soft_last) if rep.soft_last is not None else None,
             "classes": dict(rep.classes_at_death), "class_rows": dict(rep.class_rows), "client": rep.client,
             "excluded": rep.client in excluded, "rules": [], "family": rep.log.family, "labels": {}}
        for rule in RULES:
            for w in rule_res[rule["id"]]["warned"]:
                if w["log"] != rep.log.id:
                    continue
                seen = w["chain"]["seen"]
                exits = []
                for name, channel, state in seen["exits"]:
                    back = None
                    if state == "clock down":
                        back = channel_back(rep.log, w["chain"]["start_row"], w["chain"]["start"], channel)
                    exits.append((name, channel, state, back))
                d["rules"].append({"rule": rule["id"], "seconds": w["seconds"], "row": w["chain"]["start_row"],
                                   "clause": seen["clause"], "exits": exits, "off_before": w["off_before"],
                                   "tested": not rule_res[rule["id"]]["untested"], "class_row": seen["class_row"]})
        for name in LABELS:
            for chain in rep.labels[name]:
                if judge(chain, rep.death_t, rep.last_prompt) != "fatal":
                    continue
                entry = {"seconds": rep.death_t - chain["start"], "row": chain["start_row"], "seen": chain["seen"], "checks": []}
                if chain["seen"]:
                    for ex_name, _, state in chain["seen"]["exits"]:
                        if state == "open":
                            use, refused = first_use(rep.log, chain["start_row"], ex_name, rep.death_row, chain["start"])
                            entry["checks"].append((ex_name, use, refused))
                d["labels"][name] = entry
                break
        deaths.append(d)
    return deaths


def build_gate(deaths, rule_res, labels):
    """The frozen bars. Numbers are compared with them and never the other way round."""
    no_lock = [d for d in deaths if not d["lock"]]
    in_scope = [d for d in no_lock if not d["scope"] and not d["excluded"]]
    counted = []
    for d in in_scope:
        best = [w for w in d["rules"] if w["seconds"] >= WARN_BAR and w["tested"]]
        if best:
            first = max(best, key=lambda w: (w["seconds"], w["rule"]))
            counted.append({"death": d, "warning": first})
    attackers = sorted({c["death"]["killer"] for c in counted})
    with_exit = []
    for c in counted:
        names = [e[0] for e in c["warning"]["exits"] if e[2] == "open"]
        with_exit.append((c["death"]["log"], c["warning"]["rule"], names))
    soft = labels["softlock"]
    soft_false, soft_warned = len(soft["false"]), soft["n"]
    soft_fraction = soft_false / float(soft_false + soft_warned) if soft_false + soft_warned else None
    g4_rows, g4 = [], True
    for rule in RULES:
        r = rule_res[rule["id"]]
        if r["untested"]:
            g4_rows.append((rule["id"], "UNTESTED", None))
            continue
        ok = r["fraction"] is None or r["fraction"] <= soft_fraction
        g4 = g4 and ok
        g4_rows.append((rule["id"], "PASS" if ok else "FAIL", r["fraction"]))
    lock_deaths = [d for d in deaths if d["lock"] and not d["scope"] and not d["excluded"]]
    g5_rows = []
    for d in lock_deaths:
        first = d["labels"].get("softlock")
        names = []
        if first and first["seen"]:
            names = [name for name, _, state in first["seen"]["exits"] if state == "open"]
        g5_rows.append({"log": d["log"], "soft": first, "names": names, "true": d["labels"].get("true"), "killer": d["killer"]})
    n_g5 = sum(1 for row in g5_rows if row["names"])
    g1, g2 = len(counted) >= 4, len(attackers) >= 3
    g3 = bool(counted) and all(names for _, _, names in with_exit)
    return {"no_lock": no_lock, "in_scope": in_scope, "counted": counted, "g1": g1, "attackers": attackers, "g2": g2,
            "with_exit": with_exit, "g3": g3, "soft_fraction": soft_fraction, "soft_false": soft_false, "soft_false_list": soft["false"],
            "soft_warned": soft_warned, "g4_rows": g4_rows, "g4": g4, "lock_deaths": lock_deaths, "g5_rows": g5_rows,
            "n_g5": n_g5, "g5": n_g5 >= 4, "result": g1 and g2 and g3 and g4}


# The route that killed each in-scope no-lock death, read from the death rows and docs/kill-paths.md:133-138. A warning from
# another rule can still reach 5 s: `4c_SeyaA` shows Latency's plagues, and the kill was SCOURGE (rows 3001-3006). This table
# is hand read, so it decides no bar. A new log is simply not in it.
KILL_ROUTE = {"s98kPGv6": "airlord.pressure", "CxxKSMq": "runewarden.2h", "4c_SeyaA": "pariah.scourge",
              "Vr.NkCGD": "pariah.latency", "WKuEakBZ": "pariah.latency", "OwkA-G99": "blademaster.legs"}
HEALTH_LOST = re.compile(r"^Health lost")


def plan_reading(a):
    """The plan's own gate sentence read alone, and two stricter readings of it. The plan's sentence has no UNTESTED, G3 or G4
    term, so it counts every rule. None of this decides a bar. Returns one dict per reading, loosest first."""
    alone, matched, still_on, mismatch = [], [], [], []
    for d in a["gate"]["in_scope"]:
        warned = [w for w in d["rules"] if w["seconds"] >= WARN_BAR]
        if not warned:
            continue
        alone.append(d)
        route = KILL_ROUTE.get(d["log"])
        hit = [w for w in warned if w["rule"] == route]
        if hit:
            matched.append(d)
            if any(w["off_before"] <= WARN_BAR for w in hit):
                still_on.append(d)
        else:
            own = [w["seconds"] for w in d["rules"] if w["rule"] == route]
            mismatch.append({"log": d["log"], "warning": warned[0]["rule"], "route": route, "own": own[0] if own else None})
    total = len(a["gate"]["in_scope"])
    read = lambda deaths: {"n": len(deaths), "total": total, "attackers": sorted({d["killer"] for d in deaths}),
                           "logs": [d["log"] for d in deaths]}
    return {"alone": read(alone), "matched": read(matched), "still_on": read(still_on), "mismatch": mismatch,
            "passes": len(alone) >= 4}


def chance_of_warning(span, chains):
    """If each chain fell uniformly at random in its fight, the chance that at least one reads as a warning of WARN_BAR or more
    under this page's metric: it starts at least WARN_BAR before death, and ends at most FALSE_WINDOW before it."""
    miss = 1.0
    for length in chains:
        room = span - length
        if room <= 0:
            # The chain fills the fight, so it has nowhere else to fall.
            return 1.0 if span >= WARN_BAR else 0.0
        low, high = max(0.0, span - FALSE_WINDOW - length), min(room, span - WARN_BAR)
        miss *= 1.0 - max(0.0, high - low) / room
    return 1.0 - miss


def null_rule(a):
    """A rule with no skill: an alarm at the first `Health lost` row. It warns on every death and has one false alarm per log
    the logger survived. This shows how much G1, G2 and G4 can pass by themselves."""
    usable = [rep for rep in a["reps"] if rep.log.family and not rep.same_fight]
    fatal = [rep for rep in usable if rep.death_t is not None]
    clients = [rep for rep in usable if rep.log.family != "ours"]
    client_fatal = [rep for rep in clients if rep.death_t is not None]
    fraction = lambda deaths, logs: float(len(logs) - len(deaths)) / len(logs) if logs else None
    by_log = {rep.log.id: rep for rep in usable}
    rows = []
    for d in a["gate"]["in_scope"]:
        rep = by_log[d["log"]]
        first = next((row.time for row in rep.log if row.kind == "line" and row.time is not None and HEALTH_LOST.match(row.text)), None)
        span = rep.death_t - rep.first_t
        chains = [c["end"] - c["start"] for rule in RULES for c in rep.rules[rule["id"]]]
        best = max([w["seconds"] for w in d["rules"]] or [0.0])
        rows.append({"log": d["log"], "killer": d["killer"], "lead": None if first is None else rep.death_t - first, "span": span,
                     "best": best, "share": best / span if span else None, "chance": chance_of_warning(span, chains)})
    counted = {c["death"]["log"] for c in a["gate"]["counted"]}
    return {"rows": rows, "expected": sum(r["chance"] for r in rows), "expected_counted": sum(r["chance"] for r in rows if r["log"] in counted),
            "n_counted": len(counted), "deaths": len(fatal), "logs": len(usable), "fraction": fraction(fatal, usable),
            "client_deaths": len(client_fatal), "client_logs": len(clients), "client_fraction": fraction(client_fatal, clients)}


def like_against_like(a):
    """G4's two sides count differently. A rule's fraction leaves out false alarms in logs where the logger died, and the softlock
    baseline keeps them. This gives both sides the same count, for the page. The bar stays as written."""
    fatal_logs = {rep.log.id for rep in a["reps"] if rep.death_t is not None}
    soft = a["labels"]["softlock"]
    in_fatal = [f for f in soft["false"] if f[0] in fatal_logs]
    survived = len(soft["false"]) - len(in_fatal)
    rows = []
    for rule in RULES:
        r = a["rules"][rule["id"]]
        false = len(r["false_survived"]) + len(r["false_lost"])
        total = false + len(r["warned"])
        rows.append((rule["id"], false, total, false / float(total) if total else None))
    return {"in_fatal": in_fatal, "survived": survived, "warned": soft["n"],
            "baseline": survived / float(survived + soft["n"]) if survived + soft["n"] else None, "rows": rows}


def analyse(logs, force_excluded=None):
    """Everything the page needs. force_excluded names clients to take out whatever their figure, for the sensitivity row."""
    reps = [run_log(log) for log in logs]
    board = board_check(logs)
    excluded = sorted(k for k, c in board.items() if client_agreement(c) is not None and client_agreement(c) < AGREEMENT_BAR)
    a = gate_for(reps, excluded)
    a.update({"reps": reps, "board": board})
    if force_excluded is not None:
        a["sensitivity"] = gate_for(reps, sorted(set(excluded) | set(force_excluded)))
    return a


def gate_for(reps, excluded):
    labels = label_results(reps)
    rule_res = rule_results(reps, RULES, set(excluded))
    deaths = build_deaths(reps, rule_res, set(excluded))
    return {"excluded": excluded, "labels": labels, "rules": rule_res, "deaths": deaths,
            "gate": build_gate(deaths, rule_res, labels)}


# ---------------------------------------------------------------------------------------------
# THE RECORD OF THE FIRST RUN
# ---------------------------------------------------------------------------------------------

# Copied from the terminal output of the first run, the first time the rules met a death. It never changes.
FIRST_RUN = (
    ("Board check", "Elmer 55.2% (softlock echo 53 of 96), out of G1 and G5. All others 98.6% or more"),
    ("Deaths", "14; lock alert 6; no lock alert 8"),
    ("Baselines", "2-of-3: 7, 24.6 s, 21 false. Softlock: 6, 18.9 s, 11 false. True: 5, 14.5 s, 0 false"),
    ("pariah.latency", "warned 3 (6.78, 13.38, 13.45 s); 0 false in survived fights; UNTESTED"),
    ("pariah.scourge", "warned 2 (2.95, 3.95 s); 0 false in survived fights; UNTESTED"),
    ("airlord.pressure", "warned 1 (53.80 s); 3 false in survived fights"),
    ("runewarden.2h", "warned 1 (10.79 s); 0 false in survived fights"),
    ("blademaster.legs", "warned 1 (18.41 s); 0 false in survived fights; UNTESTED"),
    ("sentinel.tripimpale", "warned 1 (8.52 s, on a lock death); 0 false in survived fights"),
    ("generic.limb", "warned 0; 0 false"),
    ("G1", "FAIL: 2 (bar 4), 6 in scope of 8"),
    ("G2", "FAIL: Blonk, Talo"),
    ("G3", "FAIL: 1 of 2 (`s98kPGv6` had none open)"),
    ("G4", "FAIL: airlord.pressure 0.75 against softlock 0.647"),
    ("G5", "FAIL: 1 of 5 (`LcJC-rJ5`). Elmer's `Z5cyffxx` was out"),
    ("RESULT", "FAIL"),
)
# What changed after the first run. No rule and no threshold is on this list.
POST_HOC = (
    "**Elmer's lock echo (the check, not a rule).** The first run compared SOFTLOCKED with plain softlock and got 53 of 96, "
    "which put Elmer out of the gate. Reading the rows showed the echo needs impatience too: all 53 echoes have IMP, and the "
    "43 prompts with softlock and no echo have no IMP (`Z5cyffxx` row 4976, `2N1HTSWZ` row 1130). Against softlock + impatience "
    "it agrees 53 of 53. This was found by looking at the result, so the agreement is partly by construction, and the "
    "gain and cure lines (which do not depend on it) are the independent check. Effect: `Z5cyffxx` joins G5. The table in "
    "[With Elmer out](#with-elmer-out) shows every bar both ways.",
    "**A leak in the first run's exclusion (a bug).** The first run took an excluded client out of G1 and G5, and left its "
    "logs in G4. Exclusion now covers every bar.",
    "**Class evidence: a folded pattern (a parser bug).** The first run read the first row of a YAML pattern that folds "
    "onto a second (`001_Airlord_Class_Grab.lua`:43-44). Now it reads both. No result changed.",
    "**A bleed line took the stamp of the prompt before it (a parser bug).** It now takes the next prompt's, as the one stamp "
    "rule says, and a line before a log's first prompt no longer lasts for ever. No result changed.",
    "**The `true` label's Earth Lord branch (a replay fix).** The first run read an Earth Lord's cure as always blocked. The code reads it as "
    "blocked unless weariness is up. `uW_VbgR` has no weariness on those prompts. No result changed.",
    "**Display and tidying.** Our four recordings are now one client in the board check, two citations and one exit note were reworded, and the "
    "pressure lines moved out of a table with the same regexes. No result changed.",
    "**A prompt that wraps before its limb block (a parser bug, found on review).** The parser joined a wrapped row only with a bracket open. 155 prompts of "
    "`3ys7NuHA` wrap after `Kai: ` with every bracket closed, so their boards read empty. They join now. Effect: airlord.pressure's chains in that log "
    "change to rows 577-751, 3120-3166 and 4160-4531 (they were 577-751, 3120-3135 and 4429-4508). The false count stays 3, so G4 stays 0.75. No bar moved.",
    "**A label read as a board (a parser bug, found on review).** Two of Nikita's prompts print `--TR/Hardlock(touch tree)` with the board on the next row "
    "(`kAQnlFAW` row 1249, `X8pRorzR` row 363), and the parser read `touch tree` as the board. No bar moved.",
    "**Ids that hold an underscore (display).** `SeyaA`, `Jg` and `VbgR` are now `4c_SeyaA`, `J7Xnr_Jg` and `uW_VbgR`, as in `kb/raw/logs/README.md`. No result changed.",
)

# ---------------------------------------------------------------------------------------------
# THE PAGE
# ---------------------------------------------------------------------------------------------

BAR_TEXT = (
    ("G1", "Non-lock routes warn at least 5 s before death on at least 4 of the \"no lock alert\" deaths."),
    ("G2", "Those warnings span at least 3 different attackers. Report by attacker: a single player counts once however many fights."),
    ("G3", "At each counted warning at least one named exit is open."),
    ("G4", "False alarms per rule, counted over every log where the rule's class fought and the logger survived. Bar: each rule's "
           "false-alarm fraction, false / (false + warned), is no worse than the softlock baseline in step 3. A rule with no "
           "survived fight to test on is labelled UNTESTED and does not count toward G1."),
    ("G5", "For lock deaths: a new \"named exit\" output is compared with the existing true label. It adds value only if it names "
           "an open exit at the first alert on at least 4 of those deaths. Check the exit it names against what the log shows "
           "was available."),
)
RESULT_TEXT = ("RESULT: PASS only if G1, G2, G3 and G4 hold. Print PASS or FAIL per bar with its numbers. If it FAILS, the plan "
               "says: keep hand-written rules and build no general evaluator. State that plainly.")
RULE_FAMILY_NOTE = ("A class rule fires only when the log has shown that class by that moment. The evidence is the package's own "
                    "`determine_class/*_Class_Grab.lua` patterns (dated 2026-03-05, so not fitted to these logs; the shared "
                    "knight patterns are left out), the logger's `[Legacy]: Curing against` and `Target set to` echoes, and "
                    "two Runewarden lines the package lacks (sketching, a rune flashing on a weapon). The rune flash line is seen only in "
                    "`CxxKSMq`, the log it counts on, so that warning rests on a line chosen after reading that log.")


def fmt2(value):
    return "-" if value is None else "%.2f" % value


def fmt1(value):
    return "-" if value is None else "%.1f" % value


def verdict(ok):
    return "PASS" if ok else "FAIL"


def exit_text(e):
    name, channel, state, back = e
    text = "%s (%s): %s" % (name, channel, state)
    if back is not None:
        text += ", back +%.2f s" % back
    return text


def class_text(d):
    if not d["classes"]:
        return "not shown"
    if d["killer"] in d["classes"]:
        cls = d["classes"][d["killer"]]
        return "%s (row %s)" % (cls, d["class_rows"].get(cls))
    return ", ".join("%s: %s" % (k, d["classes"][k]) for k in sorted(d["classes"]))


def gate_rows(a):
    """The bars, as (bar, numbers, verdict)."""
    g = a["gate"]
    rules = a["rules"]
    tot = len(g["no_lock"])
    out_scope = sum(1 for d in g["no_lock"] if d["scope"])
    rows = [("G1", "%d counted, bar 4. Denominator: %d no-lock-alert deaths, of which %d are out of scope. Counted: %s" % (
        len(g["counted"]), tot, out_scope,
        "; ".join("`%s` %s %.2f s" % (c["death"]["log"], c["warning"]["rule"], c["warning"]["seconds"]) for c in g["counted"]) or "none"),
        verdict(g["g1"]))]
    rows.append(("G2", "%d attackers, bar 3: %s" % (len(g["attackers"]), ", ".join(g["attackers"]) or "none"), verdict(g["g2"])))
    rows.append(("G3", "%d of %d counted warnings had a named exit open at the first prompt: %s" % (
        sum(1 for _, _, n in g["with_exit"] if n), len(g["with_exit"]),
        "; ".join("`%s`: %s" % (log, ", ".join(names) or "none") for log, _, names in g["with_exit"]) or "none"), verdict(g["g3"])))
    parts = []
    for rid, state, fraction in g["g4_rows"]:
        r = rules[rid]
        parts.append("%s %s" % (rid, "UNTESTED" if state == "UNTESTED" else "%s %s (%d false, %d warned)" % (
            state, fmt2(fraction) if fraction is not None else "no alarm", len(r["false_survived"]), len(r["warned"]))))
    rows.append(("G4", "Softlock baseline %.3f (%d false, %d warned). %s" % (
        g["soft_fraction"], g["soft_false"], g["soft_warned"], "; ".join(parts)), verdict(g["g4"])))
    rows.append(("G5", "%d of %d lock deaths named an open exit at the first softlock alert, bar 4: %s" % (
        g["n_g5"], len(g["g5_rows"]),
        "; ".join("`%s`: %s" % (r["log"], ", ".join(r["names"])) for r in g["g5_rows"] if r["names"]) or "none"), verdict(g["g5"])))
    return rows


def plan_sentence(reading):
    """The plan's gate sentence, and which way it falls. A reader must see which reading produced the stop."""
    alone = reading["alone"]
    text = ("The plan's own gate sentence (step 4: non-lock routes warn at least 5 s on at least 4 of the no-lock-alert deaths, report by "
            "attacker) has no UNTESTED, G3 or G4 term. Read alone it gives %d of %d from %d attackers (%s). " % (
                alone["n"], alone["total"], len(alone["attackers"]), ", ".join(alone["attackers"]) or "none"))
    if reading["passes"]:
        return text + "This FAIL comes from the stricter bars. The user decided on 2026-11-01 that these bars stand, so step 5 is on hold."
    return text + "That reading fails too."


def plain_result(a):
    if a["gate"]["result"]:
        return ("**RESULT: PASS.** G1, G2, G3 and G4 hold on these logs. The rules are in-sample, so this allows step 5's shadow "
                "work and proves nothing about the next fight.")
    return ("**RESULT: FAIL.** If these bars stand, the plan says: keep hand-written rules and build no general evaluator. A later log can "
            "change this page, but no rule may change to pass it. " + plan_sentence(plan_reading(a)))


def render_board(a):
    out = ["## Step 1: the board check", "",
           "A board is a logger's belief. A client's figure is its LOWEST measure with n >= 10, because a good gain count can hide "
           "a bad cure count. **The gain and cure lines are game text** from `AFFLICTION SHOW` (`kb/afflictions/afflictions.json`) or "
           "`You have been afflicted with`, and they cover only the terms the rules read. A packet with a gain and a cure of one "
           "term is left out. The echo measures count only prompts where either side says locked, because almost all prompts "
           "have no lock and would flatter the figure.", ""]
    rows = []
    for client in sorted(a["board"]):
        c = a["board"][client]
        figure = client_agreement(c)
        m = dict((name, (ok, n)) for name, ok, n in board_measures(c))
        cell = lambda key: ("%d of %d" % m[key]) if key in m and m[key][1] else "-"
        if not c["has_board"]:
            state = "no board on any prompt, so not evaluable"
        elif figure is None:
            state = "too few to judge"
        else:
            state = "in the gate" if figure >= AGREEMENT_BAR else "OUT OF THE GATE"
        rows.append([client, ", ".join(sorted(c["logs"])), c["prompts"], cell("gain lines"), cell("cure lines"), cell("softlock echo"),
                     cell("true echo"), "-" if figure is None else "%.1f%%" % figure, state])
    out += kb.table(["Client", "Logs", "Prompts", "Gain lines", "Cure lines", "Softlock echo", "True echo", "Figure", "Verdict"], rows)
    out += [""]
    claes = a["board"].get("Claes")
    if claes:
        out += ["**No echo of their own lock:** Claes, Nikita and our recorder. Nikita's client prints a label on only 2 prompts, "
                "`TR/Hardlock(touch tree)` (`kAQnlFAW` row 1249, `X8pRorzR` row 363), too few to compare. Claes's `[VLOCK, ...]` rows are his tracker of the "
                "TARGET: %d rows, and his own board is softlocked at %d of them (`Vr.NkCGD` row 654 prints `[VLOCK, diz, clum[75], ...]` "
                "above his own board `[myc AST haem SCYT fls]`). So they test nothing here." % (claes["vlock_rows"], claes["vlock_soft"]), ""]
    elmer = a["board"].get("Elmer")
    if elmer:
        out += ["**Elmer's echo is not plain softlock.** Read literally it agrees %d of %d (%.1f%%), the figure on the first run. It "
                "prints SOFTLOCKED only with impatience up, so the table checks softlock + impatience. See "
                "[First run and post-hoc changes](#first-run-and-post-hoc-changes)." % (
                    elmer["literal_both"], elmer["literal_both"] + elmer["literal_echo"] + elmer["literal_board"],
                    100.0 * elmer["literal_both"] / max(1, elmer["literal_both"] + elmer["literal_echo"] + elmer["literal_board"])), ""]
    misses = [(k, a["board"][k]) for k in sorted(a["board"]) if a["board"][k]["gain_miss"] or a["board"][k]["cure_miss"]]
    if misses:
        out += ["Disagreeing rows: " + "; ".join(
            "%s: %s" % (k, ", ".join(c["gain_miss"] + c["cure_miss"])) for k, c in misses) + ".", ""]
    out += ["**Excluded from the gate:** %s." % (", ".join(a["excluded"]) or "no client"), ""]
    return out


def render_deaths(a):
    deaths = a["deaths"]
    lock = [d for d in deaths if d["lock"]]
    none = [d for d in deaths if not d["lock"]]
    out_scope = [d for d in deaths if d["scope"]]
    out = ["## Step 2: the deaths", "",
           "Found by the game's own line, `You have been slain by`. A death has a lock alert if the softlock test "
           "(asthma + anorexia + slickness or bloodfire, `ataxia_promptLocks` in `003_Lock_breakers.lua`) held at any time in the last "
           "60 s. Every client log ends in its death packet with no prompt after it, so the death's time is the LAST prompt "
           "before the death row, and every warning here is a floor.", "",
           "**%d deaths: %d with a lock alert, %d with none.** %d are out of scope and stay in the counts. On the logs of 2026-11-01 "
           "the earlier work said 13, 6 and 7. The difference is one death: our own recording `ours/112717_Tabethys`, which that count "
           "did not read. Its last softlock was %s s before death, outside the 60 s window." % (
               len(deaths), len(lock), len(none), len(out_scope),
               next((fmt1(d["soft_before"]) for d in deaths if d["log"] == "ours/112717_Tabethys"), "-")), ""]
    rows = []
    for d in deaths:
        rows.append([d["log"], d["row"], d["killer"], class_text(d), "lock alert" if d["lock"] else "none",
                     fmt1(d["soft_before"]), d["scope"] or "in scope"])
    out += kb.table(["Log", "Death row", "Attacker", "Class shown, first row", "Alert", "Last softlock, s before death", "Scope"], rows)
    return out + [""]


def render_baselines(a):
    labels = a["labels"]
    repro = label_results(a["reps"], clients_only=True, count_open=True, true_key="true, game blocker")
    out = ["## Step 3: the baselines", "",
           "**The metric.** A chain is episodes of the same level under 10 s apart. Warning = death minus chain start. False alarm = no "
           "death within 15 s of the chain's end. A fatal chain is not a false alarm. A logger who leaves or kills first has no death, "
           "so that chain counts as a false alarm by this definition: the earlier numbers count it, and the rule bars must use the "
           "same count. A chain still running at the last prompt of a log with no death is `open` and counts as neither: `uW_VbgR` "
           "is cut there, with the logger truelocked.", "",
           "Replayed from the code as it stands: 2-of-3 is 2 or more of `ataxia_lockComponents`; softlock is all 3; true is softlock + "
           "impatience or sandfever + paralysis + `not ataxia_canActive()`.", ""]
    rows = []
    for name in LABELS:
        l = labels[name]
        e = EARLIER[name]
        rows.append([name, l["n"], fmt1(l["median"]), "%s-%s" % (fmt1(l["min"]), fmt1(l["max"])), len(l["false"]),
                     len(l["open"]), "%d, %.1f s, %d" % e, "%d, %s s, %d" % (repro[name]["n"], fmt1(repro[name]["median"]), len(repro[name]["false"]))])
    out += kb.table(["Label", "Warned", "Median s", "Range s", "False alarms", "Open", "Earlier work (warned, median, false)",
                     "Earlier count, reproduced"], rows)
    matches = all(repro[name]["n"] == EARLIER[name][0] and round(repro[name]["median"], 1) == EARLIER[name][1]
                  and len(repro[name]["false"]) == EARLIER[name][2] for name in LABELS)
    out += ["",
            "**Why the columns differ.** The earlier count read client logs only, took the chain still running in `uW_VbgR` as a false "
            "alarm, and gave the Earth Lord's cure the game's blocker. The last column applies those three choices to this run, and it %s. "
            "On the logs of 2026-11-01, this run differs for these reasons:" % (
                "matches the earlier numbers" if matches else "no longer matches them, because new logs have been filed"),
            "- Our recordings are in: `ours/112717_Tabethys` adds a 1.85 s warning on 2-of-3, and one false alarm on softlock and two on 2-of-3. "
            "That moves the 2-of-3 median from 31.9 s to 24.6 s.",
            "- The open chain is not a false alarm here. On softlock that removes one, so softlock lands on the same 11 by coincidence.",
            "- `true` fires on `uW_VbgR` at row 554, because `ataxia_canActive` reads an Elemental Lord's cure as blocked unless weariness is up "
            "(`003_Lock_breakers.lua`:240-245, the reverse of the game's rule, `kb/CONFLICTS.md` #54). That is what the package does today. The chain "
            "is open, so it is not a false alarm.",
            "- The earlier note gave `true` a range of 0-98 s. This run's low is %s s (`EveP2TVe` row 969, 1 s stamps). The earlier script is "
            "not kept, so the 0 cannot be traced." % fmt1(labels["true"]["min"]),
            "",
            "False alarms, softlock: " + ", ".join("`%s` %d" % f for f in labels["softlock"]["false"]) + ".",
            "", "False alarms, 2-of-3: " + ", ".join("`%s` %d" % f for f in labels["2-of-3"]["false"]) + ".",
            ""]
    return out


def render_rules(a):
    out = ["## Step 4: the route rules", "",
           "These are data in `tools/kb_replay.py` (`RULES`), written from the tells in `docs/kill-paths.md`, which came from these deaths, "
           "and fixed before this tool ran them. Each sees only the board "
           "and the lines up to the prompt it is at. " + RULE_FAMILY_NOTE, ""]
    rows = []
    for rule in RULES:
        exits = "; ".join("%s (%s; shut by %s): %s" % (e["name"], e["channel"], ", ".join(e["blocked_by"]) or "nothing", e["does"]) for e in rule["exits"])
        rows.append([rule["id"], rule["class"] or "unknown", " OR ".join(c["text"] for c in rule["clauses"]), rule["cite"], exits])
    out += kb.table(["Rule", "Class", "Fires on", "Suggested by", "Exits: channel, what shuts it, what it does"], rows)
    out += ["", "**Channels.** `eat`, `lungs`, `salve`, `tree`, `focus` and `classcure` are down from their start line to their recovery line, "
            "at most twice the clock. `balance` and `move` read the prompt's flags, and on Claes's and Sentinel's prompts they are `unknown`, "
            "which does not count as open. `move` needs balance and equilibrium.", "",
            "**Left out on purpose.** Parry has no clock and always reads open, so naming it would pass G3 by itself. Clot is shut by haemophilia, so "
            "it cannot help a Scourge.", "",
            "### Per rule", ""]
    rows = []
    g4 = dict((rid, state) for rid, state, _ in a["gate"]["g4_rows"])
    for rule in RULES:
        r = a["rules"][rule["id"]]
        rows.append([rule["id"], len(r["warned"]),
                     ", ".join("`%s` %.2f" % (w["log"], w["seconds"]) for w in r["warned"]) or "-",
                     len(r["false_survived"]), fmt2(r["fraction"]) if r["fraction"] is not None else "no alarm", g4[rule["id"]],
                     ", ".join("`%s`" % x for x in r["fought_survived"]) or "none",
                     len(r["false_lost"]), len(r["open"])])
    out += kb.table(["Rule", "Deaths warned", "Warning s", "False, survived fights", "False / (false + warned)", "G4",
                     "Tested on (class fought, logger lived)", "False, before a later death (not in the bar)", "Open"], rows)
    out += [""]
    if a["rules"]["sentinel.tripimpale"]["fought_survived"] == ["uW_VbgR"]:
        out += ["`sentinel.tripimpale` was tested only on `uW_VbgR`, a 24 s fragment that stops with the logger truelocked, so its survival is not shown, "
                "and no TRIP lands in it. Its PASS means little.", ""]
    out += runewarden_2h_note(a)
    out += ["**A survived fight counts a chain even when the logger won by killing first:** `3ys7NuHA` is a win, so its three pressure chains are false "
            "alarms by the definition. The softlock baseline counts its wins the same way (`2N1HTSWZ`, `X8pRorzR`).", "",
            "Every chain, so a reviewer can check it (the row is 0-based; add 1 for `grep -n`):", ""]
    rows = []
    for rule in RULES:
        for rep in a["reps"]:
            if rep.same_fight or rep.log.family is None:
                continue
            for chain in rep.rules.get(rule["id"], ()):
                rows.append([rule["id"], rep.log.id, judge(chain, rep.death_t, rep.last_prompt), chain["start_row"], chain["end_row"],
                             "%.1f" % (chain["end"] - chain["start"]), chain["seen"]["clause"]])
    out += kb.table(["Rule", "Log", "Verdict", "First row", "Last row", "Length s", "First clause"], rows)
    out += ["", "### Not evaluable", "",
            "Where the rule's class fought and the format cannot show a term. Nothing is guessed. A rule that is not evaluable at all in a log is "
            "not tested by that log.", ""]
    rows = []
    for rule in RULES:
        for log, what in a["rules"][rule["id"]]["not_evaluable"]:
            rows.append([rule["id"], log, what])
    out += kb.table(["Rule", "Log", "What cannot be read"], rows) if rows else ["None."]
    limbs = [(rep.log.id, rep.readouts) for rep in a["reps"] if rep.log.family and rep.readouts]
    out += ["", "Limb percent comes from the game's `you perceive that ... dealt` lines and the clients' own readouts. Logs with any: " +
            ", ".join("`%s` %d" % x for x in limbs) + ". Claes's logs print only some of the hits (`CxxKSMq` has 6), so his ledger runs low.", ""]
    return out


def runewarden_2h_note(a):
    """runewarden.2h can pass G4 only by never meeting its own conditions. Say so while that is true, so a later log can clear it."""
    r = a["rules"]["runewarden.2h"]
    reps = [rep for rep in a["reps"] if rep.log.id in r["fought_survived"]]
    if not reps or any(rep.terms_2h["prone"] or rep.terms_2h["leg2"] or rep.terms_2h["impaled"] or rep.terms_2h["twohand"] for rep in reps):
        return []
    live = ", ".join("`%s` %.1f of %.1f s" % (rep.log.id, rep.last_t - rep.allowed_from["runewarden.2h"], rep.last_t - rep.first_t) for rep in reps)
    text = ("`runewarden.2h`: its %d survived fights show 0 prompts with prone or a level 2 leg and no two-handed weapon, so its PASS means little. "
            "It could not have raised an alarm there. Seconds its class was known: %s." % (len(reps), live))
    g4 = dict((rid, state) for rid, state, _ in a["gate"]["g4_rows"])
    counted = sorted({c["warning"]["rule"] for c in a["gate"]["counted"]})
    if all(g4.get(rid) != "PASS" or rid == "runewarden.2h" for rid in counted):
        text += " The other counted rules (%s) fail G4, so no rule both warned on a no-lock death and passed a real false-alarm test." % (
            ", ".join(rid for rid in counted if rid != "runewarden.2h") or "none")
    return [text, ""]


def render_death_table(a):
    out = ["## The per-death table", "",
           "One row per rule that warned. The exits are as they stood at the chain's first prompt, which is what the bars read. `back +N s` is "
           "the next recovery line, read ahead for the reviewer. No rule and no bar uses it. The row is 0-based; add 1 for `grep -n`.", ""]
    rows = []
    for d in a["deaths"]:
        alert = "lock alert" if d["lock"] else "none"
        scope = d["scope"] or "in scope"
        if not d["rules"]:
            rows.append([d["log"], d["killer"], class_text(d), alert, scope, "no rule warned", "-", "-", "-", d["row"]])
        for w in d["rules"]:
            state = "tested" if w["tested"] else "UNTESTED"
            opened = [e[0] for e in w["exits"] if e[2] == "open"]
            rows.append([d["log"], d["killer"], class_text(d), alert, scope, "%s (%s): %s" % (w["rule"], state, w["clause"]),
                         "%.2f" % w["seconds"], "; ".join(exit_text(e) for e in w["exits"]), ", ".join(opened) or "none", w["row"]])
    out += kb.table(["Log", "Attacker", "Class shown", "Alert", "Scope", "First warning by rule", "Seconds", "Exits named", "Open", "Reviewer can check row"], rows)
    return out + [""]


def render_g5(a):
    g = a["gate"]
    out = ["## G5: named exits on the lock deaths", "",
           "The output is the state of the three exits a softlock leaves: focus, tree, and the class cure. It is read at the first prompt of the fatal "
           "softlock chain, because the `true` label is too late to name one: by its own definition impatience, paralysis and the blocker have shut all "
           "three.", ""]
    rows = []
    for r in g["g5_rows"]:
        soft = r["soft"]
        true = r["true"]
        flags = "-"
        exits = "-"
        checks = "-"
        if soft and soft["seen"]:
            exits = "; ".join("%s: %s" % (n, st) for n, _, st in soft["seen"]["exits"])
            flags = "balance %s, equilibrium %s" % (flag_text(soft["seen"]["bal"]), flag_text(soft["seen"]["eq"]))
            parts = []
            for name, use, refused in soft["checks"]:
                text = "%s: " % name
                text += "used +%.2f s (row %d)" % use if use else "not used before death"
                if refused:
                    text += ", refused +%.2f s (row %d)" % refused
                parts.append(text)
            checks = "; ".join(parts) or "-"
        rows.append([r["log"], r["killer"],
                     "%.1f (row %d)" % (true["seconds"], true["row"]) if true else "no `true` alert",
                     "%.1f (row %d)" % (soft["seconds"], soft["row"]) if soft else "-",
                     exits, ", ".join(r["names"]) or "none", flags, checks])
    out += kb.table(["Log", "Attacker", "`true` warning s", "Softlock warning s", "Exits at the softlock alert", "Open", "Flags at the alert", "What the log shows"], rows)
    true_open = sum(1 for r in g["g5_rows"] if r["true"] and r["true"]["seen"] and any(st == "open" for _, _, st in r["true"]["seen"]["exits"]))
    true_n = sum(1 for r in g["g5_rows"] if r["true"])
    out += ["", "At the `true` alert itself, %d of %d lock deaths have an open exit. FITNESS also needs balance and equilibrium (foundations.md). Claes's prompt prints "
            "neither, so `LcJC-rJ5`'s class cure is open by board and clock only. The last column is the check against the log: read it beside the flags." % (true_open, true_n), ""]
    return out


def flag_text(value):
    return "not printed" if value is None else ("up" if value else "down")


def render_context(a):
    """The numbers a reader will ask for, labelled so that nobody counts them."""
    g = a["gate"]
    in_scope = g["in_scope"]
    any_warn = [d for d in in_scope if any(w["seconds"] >= WARN_BAR for w in d["rules"])]
    attackers = sorted({d["killer"] for d in any_warn})
    soon = []
    for d in any_warn:
        best = None
        for w in d["rules"]:
            if w["seconds"] < WARN_BAR:
                continue
            for e in w["exits"]:
                if e[2] == "open":
                    best = 0.0
                elif e[3] is not None and (best is None or e[3] < best):
                    best = e[3]
        soon.append((d["log"], best))
    reading = plan_reading(a)
    null = null_rule(a)
    fair = like_against_like(a)
    mismatch = " ".join("On `%s` the warning is %s, but the kill was %s, whose own rule warned %s s." % (
        m["log"], m["warning"], m["route"], fmt2(m["own"])) for m in reading["mismatch"])
    out = ["## Not counted: what the bars left out", "",
           "**None of this counts toward a bar.** It is here because it shows what a later log could change.", "",
           "- **The plan's sentence, read alone.** " + plan_sentence(reading),
           "- **One change after the first run (2026-11-03), and it moves no bar toward a pass.** Filing the group fight of that day took `pariah.latency` and "
           "`pariah.scourge` out of UNTESTED and turned G1 and G2 to PASS: 5 counted, attackers Blonk, Reyl, Talo. The only survived fight was "
           "`ours/081532_Tabethys`, where the Pariah is Harkon, a member of OUR party (`(Party): Tabethys says, \"Harkon you need to WALK AHEAD and break walls.\"`). "
           "A recording of ours now tests no rule, as a death in one already had no route. Its false alarms still count.",
           "- **Rules with no survived fight.** With the UNTESTED rules included, rules warned 5 s or more on %d of the %d in-scope no-lock-alert deaths, from "
           "%d attackers (%s). No fight its logger survived exists for %s, so nothing says how often they cry wolf. The false alarms they did raise before a "
           "later death are in the per-rule table." % (len(any_warn), len(in_scope), len(attackers), ", ".join(attackers),
                                                       ", ".join(rid for rid, st, _ in g["g4_rows"] if st == "UNTESTED") or "no rule"),
           "- **That count overstates what the rules saw.** If the rule that warned must match the kill: %d of %d, attackers %s. %s If its chain must also still be on "
           "within 5 s of death: %d of %d (%s). A chain that went off earlier counts only because the metric's 15 s window reaches back to it." % (
               reading["matched"]["n"], reading["matched"]["total"], ", ".join(reading["matched"]["attackers"]) or "none", mismatch,
               reading["still_on"]["n"], reading["still_on"]["total"], ", ".join("`%s`" % x for x in reading["still_on"]["logs"]) or "none"),
           "- **The first prompt is a hard moment for G3.** Soonest an exit was open or back, per death, in seconds after the chain's first prompt: %s. "
           "foundations.md calls a margin under 0.5 s unresolved. The bar reads the first prompt as written." % (
               ", ".join("`%s` %s" % (log, "none" if best is None else "%.2f" % best) for log, best in soon)),
           "- **G4 compares unlike counts.** A rule's fraction leaves out false alarms in logs where the logger died, and the softlock baseline keeps them: %d of its %d "
           "are in fatal logs (%s). That favours the rules. The bar allows it, so the verdict above stands. With both sides on the same count, the baseline over survived "
           "logs is %d / (%d + %d) = %s, and the rules with those false alarms added are: %s." % (
               len(fair["in_fatal"]), len(g["soft_false_list"]), ", ".join("`%s` %d" % f for f in fair["in_fatal"]) or "none",
               fair["survived"], fair["survived"], fair["warned"], fmt2(fair["baseline"]),
               "; ".join("%s %d/%d = %s" % (rid, false, total, fmt2(x)) for rid, false, total, x in fair["rows"] if total)),
           "- **A rule with no skill.** An alarm at the fight's first `Health lost` row warns on every death and has one false alarm per survived log: "
           "%d / %d = %.3f over all %d logs (%d / %d = %.3f on client logs), against the softlock baseline %.3f. %s Read a later PASS on those bars beside the table below." % (
               null["logs"] - null["deaths"], null["logs"], null["fraction"], null["logs"],
               null["client_logs"] - null["client_deaths"], null["client_logs"], null["client_fraction"], g["soft_fraction"],
               "So it would clear G1, G2 and G4." if null["fraction"] <= g["soft_fraction"] else "So it would clear G1 and G2, and not G4."),
           "- **5 s is easy to clear by chance.** The last column places each of a log's chains uniformly in its fight and reads them with this page's metric. That expects "
           "%.1f of %d deaths warned, and %.2f of the %d counted. Fights escalate toward the end, so uniform placement is only a rough floor." % (
               null["expected"], len(null["rows"]), null["expected_counted"], null["n_counted"]),
           ""]
    out += kb.table(["Log", "Attacker", "Fight started, lead s", "Longest rule warning s", "Share of the fight", "Chance of 5 s or more"],
                    [[r["log"], r["killer"], fmt2(r["lead"]), fmt2(r["best"]), "%.0f%%" % (100.0 * r["share"]) if r["share"] is not None else "-", "%.2f" % r["chance"]]
                     for r in null["rows"]])
    return out + [""]


def render_elmer(a):
    s = a["sensitivity"]
    g, h = a["gate"], s["gate"]
    rows = []
    for key, label, fn in (
            ("g1", "G1", lambda x: "%d counted" % len(x["counted"])),
            ("g2", "G2", lambda x: ", ".join(x["attackers"]) or "none"),
            ("g3", "G3", lambda x: "%d of %d" % (sum(1 for _, _, n in x["with_exit"] if n), len(x["with_exit"]))),
            ("g4", "G4", lambda x: "; ".join("%s %s" % (r, st) for r, st, _ in x["g4_rows"] if st != "UNTESTED") or "nothing tested"),
            ("g5", "G5", lambda x: "%d of %d" % (x["n_g5"], len(x["g5_rows"])))):
        rows.append([label, "%s: %s" % (verdict(g[key]), fn(g)), "%s: %s" % (verdict(h[key]), fn(h))])
    rows.append(["RESULT", verdict(g["result"]), verdict(h["result"])])
    out = ["### With Elmer out", "",
           "The first run put Elmer out on a literal reading of his echo. If the literal reading stood, the bars would read as below. **The result is the same.**"
           if g["result"] == h["result"] else
           "The first run put Elmer out on a literal reading of his echo. If the literal reading stood, the bars would read as below. **THE RESULT DIFFERS.**", ""]
    out += kb.table(["Bar", "Elmer in (this page)", "Elmer out"], rows)
    return out + [""]


def render_first_run(a):
    out = ["## First run and post-hoc changes", "",
           "This tool ran the rules against the deaths once, and this is what they did. **No rule and no threshold changed after that run.** Anything below that did change "
           "is marked POST-HOC and counts toward no bar.", ""]
    out += kb.table(["Item", "First run"], [list(x) for x in FIRST_RUN])
    out += ["", "**POST-HOC changes:**", ""] + ["- " + p for p in POST_HOC] + [""]
    return out + render_elmer(a)


def render_page(a, logs):
    g = a["gate"]
    skipped = [log for log in logs if log.family is None]
    latest = max(log.date for log in logs if log.date)
    out = ["---",
           "topic: replay",
           "confidence: MEASURED, in-sample (counted from log rows; boards are the loggers' beliefs; nothing here was run live)",
           "generated: true  # GENERATED by `python tools/kb_replay.py`. Do not hand-edit. CI runs --check.",
           "sources:",
           "  - kb/raw/logs/",
           "  - kb/raw/logs/ours/",
           "  - kb/afflictions/afflictions.json",
           "  - docs/kill-paths.md",
           "  - kb/mechanics/foundations.md",
           "code:",
           "  - tools/kb_replay.py",
           "  - tools/kb_timing.py",
           "  - src_new/triggers/levi_ataxia/for_levi/leviticus/determine_class/",
           "  - src_new/scripts/levi_ataxia/levi/ataxia/can(x)/003_Lock_breakers.lua",
           "latest_filed: %s" % latest,
           "---",
           "",
           "# Replay: do route rules warn before a death?",
           "",
           "**These rules came from these same logs, so a warning count is in-sample and proves little. The false-alarm count is the stronger evidence. "
           "Real validation is the next kill in a new log. Samples are not independent:** six logs are Mystor against one opponent, nine are Claes, and several "
           "were played within 30 minutes.",
           "",
           "**GENERATED by `python tools/kb_replay.py`. Do not hand-edit.** Every warning and false alarm is a counterfactual read from a log. Nothing here was "
           "run in a fight. The model is [foundations.md](foundations.md), and the clocks are [clocks.md](clocks.md).",
           "",
           plain_result(a),
           "",
           "## The gate", "",
           "These bars are copied here word for word. They were written before this tool's first run. The first commit of this tool is later than that run, so the "
           "repository cannot show the order. G2 to G5 and the UNTESTED clause come from the task that built this tool. The plan's step 4 has one gate sentence, shown in "
           "[Not counted](#not-counted-what-the-bars-left-out).", ""]
    out += ["- **%s.** %s" % (k, v) for k, v in BAR_TEXT]
    out += ["- " + RESULT_TEXT, ""]
    out += kb.table(["Bar", "Numbers", "Verdict"], [list(r) for r in gate_rows(a)])
    out += ["", "**RESULT: %s.**" % verdict(g["result"]), ""]
    out += render_context(a)
    out += render_board(a)
    out += render_deaths(a)
    out += render_baselines(a)
    out += render_rules(a)
    out += render_death_table(a)
    out += render_g5(a)
    out += render_first_run(a)
    out += ["## Logs read", "",
            "%d logs. Skipped: %s (prompts with no time in them, so no warning can be measured). `2026-10-27_shikudo-group-mhaldor` is the same fight as "
            "`ours/112717_Tabethys`, and the two `2026-11-03_shikudo-group-alias` logs hold the recordings of 2026-11-03 (`kb_timing.SAME_FIGHT`), so they stay out of every count. The ids are the ones [clocks.md](clocks.md) uses." % (
                len(logs), ", ".join("`%s`" % log.name for log in skipped) or "none"), ""]
    rows = []
    for rep in a["reps"]:
        log = rep.log
        result = "not read" if log.family is None else ("same fight" if rep.same_fight else ("died" if rep.death_t is not None else "no death shown"))
        rows.append([log.id, log.name, log.family or "none", rep.client or "-", log.prompts, result])
    out += kb.table(["Id", "File", "Family", "Client", "Prompts", "Result"], rows)
    out += [""]
    return "\n".join(out)


def generate():
    logs = kb.load_all()
    a = analyse(logs, force_excluded=("Elmer",))
    return {OUT_MD: render_page(a, logs)}


def rel(path):
    return os.path.relpath(path, ROOT).replace(os.sep, "/")


def check(files):
    bad = 0
    for path in sorted(files):
        if os.path.exists(path):
            # A Windows checkout may hold CRLF. The content is what must match.
            with open(path, "rb") as fh:
                have = fh.read().decode("utf-8").replace("\r\n", "\n")
        else:
            have = None
        if have == files[path]:
            print("ok      " + rel(path))
            continue
        bad += 1
        print("DIFFERS " + rel(path))
        if have is not None:
            diff = difflib.unified_diff(have.split("\n"), files[path].split("\n"), "on disk", "generated", lineterm="", n=0)
            for i, line in enumerate(diff):
                if i >= 20:
                    print("  ...")
                    break
                print("  " + line[:160])
    if bad:
        print("Run: python tools/kb_replay.py")
    return bad


def print_gate(a):
    print("BOARD CHECK")
    for client in sorted(a["board"]):
        c = a["board"][client]
        figure = client_agreement(c)
        print("  %-30s %s  %s" % (client, "-" if figure is None else "%.1f%%" % figure,
                                  ", ".join("%s %d/%d" % m for m in board_measures(c))))
    print("  excluded: %s" % (", ".join(a["excluded"]) or "none"))
    print("DEATHS")
    for d in a["deaths"]:
        print("  %-22s row %-6d %-34s %-10s %s" % (d["log"], d["row"], d["killer"][:34], "lock alert" if d["lock"] else "none",
                                                   "OUT: " + d["scope"][:44] if d["scope"] else ""))
        for w in d["rules"]:
            print("      %-22s %6.2f s row %-6d %-8s %s" % (w["rule"], w["seconds"], w["row"], "tested" if w["tested"] else "UNTESTED",
                                                            "; ".join(exit_text(e) for e in w["exits"])))
    print("BASELINES")
    for name in LABELS:
        l = a["labels"][name]
        print("  %-9s warned %d median %s range %s-%s false %d open %d   earlier %r" % (
            name, l["n"], fmt1(l["median"]), fmt1(l["min"]), fmt1(l["max"]), len(l["false"]), len(l["open"]), EARLIER[name]))
    print("RULES")
    for rule in RULES:
        r = a["rules"][rule["id"]]
        print("  %-22s warned %d false(survived) %d false(lost) %d open %d fought survived %s not evaluable %d %s" % (
            rule["id"], len(r["warned"]), len(r["false_survived"]), len(r["false_lost"]), len(r["open"]),
            ",".join(r["fought_survived"]) or "none", len(r["not_evaluable"]), "UNTESTED" if r["untested"] else ""))
    print("GATE")
    for bar, numbers, ok in gate_rows(a):
        print("  %s %s: %s" % (bar, ok, numbers))
    print("RESULT: %s" % verdict(a["gate"]["result"]))
    reading = plan_reading(a)
    print("NOT COUNTED: the plan's sentence alone %d of %d (%s); rule matches the kill %d (%s); chain still on within 5 s %d (%s)" % (
        reading["alone"]["n"], reading["alone"]["total"], ", ".join(reading["alone"]["attackers"]),
        reading["matched"]["n"], ", ".join(reading["matched"]["attackers"]),
        reading["still_on"]["n"], ", ".join(reading["still_on"]["logs"])))


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--check", action="store_true", help="regenerate in memory, diff, exit 1 on any difference")
    ap.add_argument("--gate", action="store_true", help="print the gate to the terminal")
    args = ap.parse_args()
    if args.gate:
        logs = kb.load_all()
        print_gate(analyse(logs, force_excluded=("Elmer",)))
        return
    files = generate()
    if args.check:
        sys.exit(1 if check(files) else 0)
    for path in sorted(files):
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(files[path])
        print("wrote " + rel(path))


if __name__ == "__main__":
    main()
