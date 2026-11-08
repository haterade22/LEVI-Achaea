"""The four Serpent logs as one event stream, a census of what each log shows, and the race between the DSTAB and the eat.

Plan step 7.2, stage 1a: logs first. The engine (tools/sim/fight.lua) writes the same stream, version 1, so one scorer can
read a sim fight and a real log:

    {"v": 1, "src": "Z5", "t": 12.929, "side": "A", "kind": "attack", "name": "dstab", "args": [], "view": "lines", "row": 196}

side is A (the Serpent), V (the logger, the victim) or W (no actor: a timed effect, a pet, a venom tick). row is the 1-based
editor line. t is the next prompt's stamp (kb_timing's one stamp rule). view is "lines": what the game printed.

The race: at each DSTAB, is the victim's eat still down? PHASE is the time until the eat comes back: positive means down,
negative means up that long already. A pair (this DSTAB, the next attack) is won by the strike when the eat is still down at
the next attack. The PHASE, not the clock lengths, decides it: Z5 rows 196-260 (foundations.md, item 5).

    python tools/kb_events.py            # write kb/sim/events.md and events.json
    python tools/kb_events.py --check    # the files match the logs, and the golden race row holds
    python tools/kb_events.py --dump Z5  # the stream of one log as JSON Lines
"""

import argparse
import collections
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kb_timing as kb
import kb_replay as rp

ROOT = kb.ROOT
GATES = os.path.join(ROOT, "tools", "sim", "gates_whole.json")
AFFLICTIONS = os.path.join(ROOT, "kb", "afflictions", "afflictions.json")
OUT_JSON = os.path.join(ROOT, "kb", "sim", "events.json")
OUT_MD = os.path.join(ROOT, "kb", "sim", "events.md")
STREAM_VERSION = 1

# The four logs in which a Serpent attacks the logger, as gates_whole.json freezes them. Keys as in foundations.md.
KEYS = ("az", "Z5", "g", "X")

WHO = kb.WHO
# name, side, kind, pattern. The patterns read game text only: a client's own echoes are not events. Each one was checked
# against the four logs on 2026-11-07; the census on events.md counts them.
LINES = (
    ("dstab", "A", "attack", r"^" + WHO + r" quickly pricks you with (?:his|her) dirk"),
    ("dstab.second", "A", "attack.part", r"^Striking like a snake, " + WHO + r" follows the first attack with another"),
    ("dstab.miss", "A", "attack", r"^" + WHO + r" misses you with (?:his|her) dirk"),
    ("bite", "A", "attack", r"^" + WHO + r" sinks (?:his|her) fangs into your body"),
    ("flay.shield", "A", "attack", r"^" + WHO + r" flays away your shield defence"),
    ("flay.rebounding", "A", "attack", r"^" + WHO + r" flays away your aura of rebounding defence"),
    ("flay.whip", "A", "attack", r"^With fluid grace, " + WHO + r" snaps (?:his|her) wrist"),
    ("blocked.shield", "A", "attack", r"^" + WHO + r"'s attack rebounds off your magical shield"),
    ("rebounded", "A", "attack.part", r"^The attack rebounds back onto " + WHO + r"!"),
    # It follows the second-venom line of a rebounded DSTAB (g rows 1529-1530).
    ("rebounded.aura", "W", "attack.part", r"^The attack rebounds off your aura of protection!"),
    ("snap", "A", "hypnosis", r"^" + WHO + r" snaps (?:his|her) fingers in front of you"),
    # The bare form: g row 1531, after a DSTAB that rebounded. Who it fires at is not shown.
    ("snap.bare", "A", "hypnosis", r"^" + WHO + r" snaps (?:his|her) fingers\.$"),
    # An IMPULSE that bites. All 22 of the four logs' BITEs had this line from the same Serpent in their packet, and all 22
    # of these lines had a BITE there, with the suggestion's affliction between the two (az 1238-1242, Z5 534-537, X 293-296).
    ("gaze.command", "A", "hypnosis", r"^" + WHO + r" fixes (?:his|her) gaze to yours and hisses a sharp command"),
    ("shrug", "A", "classcure", r"^" + WHO + r" hunches (?:his|her) shoulders and lets out a soft hiss"),
    ("impulse.fired", "W", "hypnosis", r"^Your equilibrium is thrown off by an awakened mental impulse"),
    # Any pet, not only a snake: az and g print "An emerald tree snake", X "A small grey-brown rattlesnake", and Z5
    # "A saw-scaled viper" (rows 101, 378; the throat form at 2744). The Serpent's own BITE line starts with a name.
    ("snake.hit", "W", "pet", r"^An? [\w\s'-]+? sinks its fangs into your neck"),
    ("snake.blocked", "W", "pet", r"^An? [\w\s'-]+? lunges for your throat, its fangs sinking into"),
    ("agony", "W", "venom", r"^You scream out in agony as a vicious venom tears through your body"),
    ("vomit", "W", "venom", r"^You cannot contain the convulsions in your stomach any longer"),
    # Darkshade's burn as we enter a room. With the logger's darkshade tag in front of it, it is the gain line (az 605-606,
    # X 796-797, 1032-1033, 2820-2821); with darkshade already on the board it is a tick (X 2268, 3866, 5199). stream()
    # emits the gain only when the last prompt's board has no darkshade.
    ("darkshade.burn", "W", "venom", r"^Your skin prickles and burns\."),
    ("eat", "V", "cure", kb.EAT_START.pattern),
    # Claes's firefly-jar pipe prints its own smoke line once (az 573, after "[Curing]: SMOKE SKULLCAP" at 572); the aura
    # came up 8.475 s later (az 743). kb_timing.SMOKE_START misses it, so clocks.json lacks that lungs sample (review
    # R3-docs-2; kb/CONFLICTS.md row 66). The item comes from the logger's [Curing] line.
    ("smoke", "V", "cure", r"^(?:You take a long drag|Fireflies dance around the jar-shaped bowl of your pipe as smoke"
                           r" gently rises)"),
    ("salve", "V", "cure", kb.SALVE_START.pattern),
    ("sip", "V", "cure", kb.SIP_START.pattern),
    ("tree", "V", "cure", kb.TREE_START.pattern),
    ("focus", "V", "cure", kb.FOCUS_START.pattern),
    ("fitness", "V", "classcure", kb.FITNESS_START.pattern),
    ("salt", "V", "classcure", kb.SALT_START.pattern),
    # Nikita's client prints "ACCELERATED. " in front of the game line (X row 2088), so this one searches.
    ("accelerate", "V", "classcure", r"You accelerate your body's ability to purge afflictions"),
    ("dagaz", "V", "classcure", kb.DAGAZ_TICK.pattern),
    ("shield.up", "V", "defence", r"^You touch the tattoo and a nearly invisible magical shield forms around you"),
    ("rebounding.up", "V", "defence", r"^You feel an aura of rebounding surround you"),
    # The apply line is the action. The coating is up at the hardening line (az 1466; az 1465 is "[DEF]: Fangbarrier").
    # Claes uses the herb; Elmer and Nikita use the mineral, quicksilver (X 763-764 "Defense gained: fangbarrier", g 237-238).
    ("sileris.apply", "V", "defence", r"^You apply a (?:sileris berry|quicksilver droplet) to yourself"),
    ("sileris.up", "V", "defence", r"^The (?:sileris berry juice hardens into a supple purple shell"
                                   r"|quicksilver hardens into a supple metallic shell)"),
    # Three ways the coating goes: a FLAY strips it with the other defences (az 9), it dissolves, or it sloughs off. The
    # "begins to dissolve" and "begins to itch and burn" lines are warnings, and the coating is still up (X).
    ("sileris.down", "V", "defence", r"^The protective (?:coating covering your skin is ripped away"
                                     r"|barrier coating your skin dissolves\."
                                     r"|covering coating your skin sloughs off)"),
    # Our own aura falls when we attack (the attacker's own line is "<name>'s aura of weapons rebounding disappears").
    ("rebounding.down", "V", "defence", r"^Your aura of weapons rebounding disappears"),
    ("shield.down", "V", "defence", r"^Your (?:movement causes your magical shield to dissipate"
                                    r"|action causes the nearly invisible magical shield around you to fade away)"),
    # Five shapes: Z5 257 and 5530; "cannot do that" (az 1352, Z5 613); "unable to do that" (az, X 470); "are unable to
    # drop anything" (X 3782); "Paralysed as you are, your body is not able to pick up anything" (X 3781).
    ("refused.paralysis", "V", "refused", r"^(?:Your state of paralysis prevents you from doing that"
                                          r"|You are paralysed and (?:cannot do that|unable to do that|are unable to)"
                                          r"|Paralysed as you are, your body is not able to)"),
    # A salve on slick skin: no salve clock is spent (X 656-657 and 1667-1668 have no "You may apply another salve" after
    # them). stream() turns the salve line in front of it into salve.refused.
    ("refused.slickness", "V", "refused", r"^The salve slides off your oily skin"),
    ("refused.weary", "V", "refused", r"^Your body is too weary to perform such a feat"),
    # The game's own cost lines (CONFIG SEEBALANCES). args: the seconds. A fork reads the victim's balance and equilibrium
    # from them (az prints only equilibrium: 24 lines; Z5, g and X print both).
    ("bal.used", "V", "spend", r"^Balance used: *([\d.]+)"),
    ("eq.used", "V", "spend", r"^Equilibrium used: *([\d.]+)"),
    ("refused.balance", "V", "refused", r"^You must regain (?:balance|equilibrium) first"),
    ("refused.humour", "V", "refused", r"^You are unable to manipulate another's humours at this time"),
    # Class cures sent in their lockout: Salt (Z5 758, 914, 988) and Accelerate (X 2097).
    ("refused.salt", "V", "refused", r"^You have not recovered enough to heal yourself with alchemical energy once again"),
    ("refused.accelerate", "V", "refused", r"You have not recovered enough to accelerate time in that way again so soon"),
    # The Alchemist's own STUDY in its lockout (Z5 301): an offence refusal, not a cure.
    ("refused.study", "V", "refused", r"^You have not recovered enough to study the physiological composition"),
    ("death", "V", "death", rp.DEATH.pattern),
)
LINES = [(n, s, k, re.compile(p)) for n, s, k, p in LINES]
SEARCHED = {"accelerate", "refused.accelerate"}
# The attacks that end a gap, as kb_timing.build_opponents reads them. A second line of a DSTAB is part of the same attack.
GAP_ATTACKS = {"dstab", "dstab.miss", "bite", "flay.shield", "flay.rebounding", "flay.whip", "blocked.shield"}
# The engine's FLAY that strips nothing and cannot whip prints no line in the logs; it is still an attack (review N2-5).
GAP_ATTACKS.add("flay")
BALANCE_ATTACKS = {"dstab", "bite", "flay"}
RECOVERIES = dict((name, regex) for name, regex, _ in kb.RECOVERY)
RECOVERIES["shrug"] = re.compile(r"^Your body has recovered enough to shrug afflictions once again")
# Nikita's client prints "ACCELERATE BACK. " in front of the game line (X row 2409), so this one searches too.
RECOVERIES["accelerate"] = re.compile(r"You may accelerate time to cleanse your afflictions once again")
RECOVERIES_SEARCHED = {"accelerate"}
# Balance and equilibrium come back (kb_timing.RECOVERED_ALL, RECOVERED_EQ). The engine names them "bal" and "eq" too.
RECOVERIES["bal"] = kb.RECOVERED_ALL
RECOVERIES["eq"] = kb.RECOVERED_EQ
SMOKE_ITEM = re.compile(r"^You take a long drag of (.+?) off your pipe")
DARK_TOKEN = re.compile(r"^dark", re.I)
EAT_ITEM = re.compile(r"^You (?:quickly )?eat (?:an? |some )?(.+?)\.?\s*$")
# An eat whose recovery line comes this much later has lost its line, or a slowing affliction stretched it. The eat clock's
# p90 is 1.62 s or less for every logger in clocks.json; its max, 5.24 s, is one such outlier.
EAT_MAX = 3.0
# A short head of a game line is enough to know it, when the server wrapped it onto a second row (X wraps at 96 columns).
WRAP_MIN = 25


def gates():
    with open(GATES, encoding="utf-8") as fh:
        return json.load(fh)


def log_path(key):
    name = gates()["inputs"]["serpent_logs"][key]
    return os.path.join(kb.LOGS, name)


def load(key):
    log = kb.parse(log_path(key))
    log.id = key
    return log


# ---------------------------------------------------------------------------------------------
# Gain and cure lines, from the game's own messages
# ---------------------------------------------------------------------------------------------


PLACEHOLDER = re.compile(r"\$\([^)]*\$\)")


class Template:
    """A message with a $(...$) placeholder ("Thank $(creator$)! Your clumsiness has been cured."). match() takes the whole
    message, or the head a wrap left on the row, as the plain path does (review EV-5 residual). The game wraps at a space,
    so a head ends at a space of the message. A head must end in its own words, not inside a placeholder: "Thank .+" would
    take any line that starts with "Thank". Its own words must hold a letter: "Thank .+?!" would take any "Thank ...!"
    row (review EV-5 nit)."""

    def __init__(self, msg):
        self.full = self.compile(PLACEHOLDER.split(msg))
        self.heads = []
        words = msg.split(" ")
        for k in range(1, len(words)):
            parts = PLACEHOLDER.split(" ".join(words[:k]))
            if re.search(r"[A-Za-z]", parts[-1]):
                self.heads.append(re.compile(self.compile(parts).pattern + r"\s*$"))

    @staticmethod
    def compile(parts):
        return re.compile("^" + ".+?".join(re.escape(p) for p in parts))

    def match(self, text):
        return self.full.match(text) or any(h.match(text) for h in self.heads)


def template(msg):
    """A message with a $(...$) placeholder as a Template, else None."""
    if "$(" not in msg:
        return None
    return Template(msg)


def messages():
    """(gains, cures): lists of (message, affliction, regex or None, args). afflictions.json holds the game's AFFLICTION SHOW
    text. When afflictions show one message for several afflictions, SHARED picks one with a cited row, and a message
    SHARED does not resolve names them all, joined by "|", so that no event claims an affliction the line does not prove."""
    with open(AFFLICTIONS, encoding="utf-8") as fh:
        affs = json.load(fh)
    out = {"afflicted_msg": collections.defaultdict(list), "cured_msg": collections.defaultdict(list)}
    for name in sorted(affs):
        for field in out:
            msg = (affs[name].get(field) or "").strip()
            if len(msg) >= WRAP_MIN:
                out[field][msg].append(name)
    tables = []
    for field in ("afflicted_msg", "cured_msg"):
        table = []
        for msg, names in sorted(out[field].items()):
            name = SHARED.get(msg) or "|".join(names)
            table.append((msg, name, template(msg), ["shared"] if "|" in name else []))
        tables.append(table)
    gains, cures = tables
    gains += [(msg, name, template(msg), list(args)) for msg, name, args in EXTRA_GAINS]
    return gains, cures


# Gain lines that afflictions.json does not hold, or holds in another form. Each one cites the rows that name it: the
# logger's own tag ("[AFF]: X" or "You have been afflicted with X.") prints just in front of a gain line.
EXTRA_GAINS = [
    # The anorexia a SNAP sets off 9-11 s later (az rows 529-530). Only Claes's log shows it (CONFLICTS #61).
    ("The thought of food revolts you all of a sudden.", "anorexia", ["suggested"]),
    ("Your mind feels somewhat slower and more plodding.", "stupidity", []),  # Z5 535-536, 6 in Z5
    # Wrapped in X (418-419; 9 in X), whole in az 3774.
    ("You realise that your heroic actions can no longer continue unnoticed, and you take it upon yourself to rectify the "
     "situation.", "recklessness", []),
    ("You are gripped with fear - you cannot leave the ground.", "vertigo", []),  # X 294-295, 8 in X; az 3798; Z5 4937
    # Disrupted: afflictions.json has no message ("none"). Claes's "[AFF]: Disrupted" follows each one (az 331-332; 7 in az,
    # 2 in g), with DISR on the next board.
    ("Your mental equilibrium scatters suddenly, upset by some unknown source.", "disrupted", []),
    # Darkshade in sunlight: Nikita's "You have been afflicted with paralysis." follows it (X 1520-1521, 6555).
    ("The sun has rendered you too weak to move a muscle.", "paralysis", ["sun"]),
    # Pinshot: afflictions.json has no message ("none"). The logger's tag follows each one (az 13-14 "[AFF]: Pinshot", X
    # 3290-3291 "You have been afflicted with pinshot."; 7 in the four logs: az 2, Z5 2, g 1, X 2). Review EV-6 residual:
    # the 7 pinshot cures had no gain.
    ("Your left foot explodes in white hot pain as an arrow slams into it.", "pinshot", []),
    # Our own homunculus, turned on us by fratricide (Z5 1290-1291, 2671, 5112).
    ("A diminutive homunculus resembling $(name$) claws into your flesh with dirty nails.", "homunculusmercury", []),
]

# One message, several afflictions in afflictions.json. The loggers tag only disloyalty: Z5 332-333 ("[AFF]: Disloyalty")
# and X 344-345 ("You have been afflicted with disloyalty.").
SHARED = {
    "You feel ugliness radiating from you.": "disloyalty",
    "You no longer will inspire disloyalty among friends.": "disloyalty",
}


GAINS, CURES = messages()


def match_message(text, table):
    """(name, args) for each affliction a row names: by the whole message, by the head a wrap left on this row, or by a
    template's regex."""
    text = text.strip()
    if len(text) < WRAP_MIN:
        return []
    found = {}
    for msg, name, regex, args in table:
        if regex is not None:
            hit = regex.match(text)
        else:
            hit = text.startswith(msg) or msg.startswith(text)
        if hit:
            found[name] = args
    return sorted(found.items())


# ---------------------------------------------------------------------------------------------
# The stream
# ---------------------------------------------------------------------------------------------


def event(key, row, side, kind, name, args=None, t=None):
    return {"v": STREAM_VERSION, "src": key, "t": row.time if t is None else t, "side": side, "kind": kind, "name": name,
            "args": args or [], "view": "lines", "row": row.n + 1}


def eat_channel(text):
    m = kb.EAT_START.match(text)
    what = m.group(1)
    if kb.EAT_MOSS.search(what):
        return "moss"
    if kb.EAT_LUNGS.search(what):
        return "smoke"
    if kb.EAT_NOT_A_CLOCK.search(what):
        return None
    return "eat"


def stream(log):
    """Every event of one log, in row order.

    A row after the last prompt has no stamp of its own (kb_timing's one stamp rule needs a next prompt). Both losses end
    there: the death line and the last venom lines (az 3913-3916, Z5 5625-5631). Such a row gets the last prompt's stamp, a
    floor on its true time, and "late": true. The census counts late events; the race and the supplier delays skip them."""
    key = log.id
    out = []
    last_cure = None
    last_stamp = None
    board = []
    curing = None  # the logger's last "[Curing]: X" line: (row number, X)
    for row in log:
        if row.kind == "line" and row.text:
            m = kb.CURING.match(row.text)
            if m:
                curing = (row.n, m.group(1))
        if row.kind == "prompt":
            out.append(dict(event(key, row, "V", "prompt", "prompt", list(row.board or [])), t=row.own))
            last_cure = None
            last_stamp = row.own
            board = list(row.board or [])
            continue
        if row.kind != "line" or not row.text:
            continue
        late = row.time is None
        if late and last_stamp is None:
            continue
        t = last_stamp if late else None

        def make(side, kind, name, args=None):
            ev = event(key, row, side, kind, name, args, t)
            if late:
                ev["late"] = True
            return ev

        text = row.text
        hit = None
        for name, side, kind, regex in LINES:
            m = regex.search(text) if name in SEARCHED else regex.match(text)
            if not m:
                continue
            args = []
            if name == "eat":
                channel = eat_channel(text)
                if channel is None:
                    break
                item = EAT_ITEM.match(text)
                args = [channel, item.group(1) if item else ""]
            elif name == "salve":
                args = [m.group(1)]
            elif name == "smoke":
                item = SMOKE_ITEM.match(text)
                if item:
                    args = [item.group(1)]
                elif curing and row.n - curing[0] <= kb.CURING_REACH and curing[1].startswith("SMOKE "):
                    args = [curing[1][len("SMOKE "):].lower()]
                else:
                    args = [""]
            elif kind == "spend":
                args = [m.group(1)]
            elif name == "refused.slickness":
                # The salve line in front of it, in the same packet, spent nothing: it is a refused salve.
                for ev in reversed(out):
                    if ev["kind"] == "prompt":
                        break
                    if ev["name"] == "salve":
                        ev.update(name="salve.refused", kind="refused")
                        break
            hit = make(side, kind, name, args)
            if "who" in regex.groupindex:
                hit["who"] = m.group("who")
            break
        if hit and hit["name"] == "darkshade.burn":
            out.append(hit)
            if not any(DARK_TOKEN.match(tok) for tok in board):
                out.append(make("V", "gain", "darkshade", ["burn"]))
            continue
        if hit:
            out.append(hit)
            # The victim's own cure actions: a channel cure, or a class cure (Salt, Accelerate, Dagaz, FITNESS).
            if hit["side"] == "V" and hit["kind"] in ("cure", "classcure"):
                last_cure = hit
            continue
        for channel, regex in RECOVERIES.items():
            if (regex.search(text) if channel in RECOVERIES_SEARCHED else regex.match(text)):
                out.append(make("V", "recover", channel))
                hit = True
                break
        if hit:
            continue
        for name, args in match_message(text, GAINS):
            out.append(make("V", "gain", name, list(args)))
        for name, args in match_message(text, CURES):
            ev = make("V", "lose", name, list(args))
            if last_cure is not None:
                # The cure line closest after an action, inside one packet, names what the action took.
                ev["by"] = last_cure["name"]
            out.append(ev)
    return out


# ---------------------------------------------------------------------------------------------
# The census
# ---------------------------------------------------------------------------------------------


def census(events):
    counts = collections.Counter()
    for ev in events:
        if ev.get("late") and ev["kind"] != "prompt":
            counts["late"] += 1
        if ev["kind"] in ("prompt", "gain", "lose"):
            continue
        if ev["kind"] == "recover":
            counts["recover." + ev["name"]] += 1
            continue
        counts[ev["name"]] += 1
        if ev["name"] == "eat":
            counts["eat." + ev["args"][0]] += 1
    gains = collections.Counter(ev["name"] for ev in events if ev["kind"] == "gain")
    loses = collections.Counter(ev["name"] for ev in events if ev["kind"] == "lose")
    return counts, gains, loses


# ---------------------------------------------------------------------------------------------
# The race
# ---------------------------------------------------------------------------------------------


def attacks(events):
    """One entry per attack: a second line of the same ability inside one bundle is not a new attack (kb_timing)."""
    out = []
    for ev in events:
        if ev["name"] not in GAP_ATTACKS or ev.get("late"):
            continue
        family = "flay" if ev["name"].startswith("flay") else ev["name"]
        if out and out[-1]["family"] == family and ev["t"] - out[-1]["t"] < kb.BUNDLED:
            continue
        out.append(dict(ev, family=family))
    return out


def is_eat(ev):
    """An eat on the eat clock: not moss, not pear or calcite (they spend the lungs), not quartz."""
    return ev["kind"] == "cure" and ev["name"] == "eat" and ev["args"][0] == "eat" and not ev.get("late")


def eat_state(events, row):
    """The eat clock just before `row`: (the eat in progress, its recovery line), either one None when the log does not show
    it. An eat whose recovery line comes more than EAT_MAX later has lost its line, and it counts as not shown."""
    start = None
    for ev in events:
        if ev["row"] >= row:
            break
        if is_eat(ev):
            start = ev
    if start is None:
        return None, None
    for ev in events:
        if ev["row"] > start["row"] and ev["kind"] == "recover" and ev["name"] == "eat" and not ev.get("late"):
            if ev["t"] - start["t"] > EAT_MAX:
                return start, None
            return start, ev
    return start, None


def phase_at(back, ev):
    """PHASE at an attack: the eat's return minus the attack's time. Rows in one packet share a stamp, so on a tie the row
    order decides: a return line after the attack line means the eat was still down (+0.000), before it means up (-0.000)."""
    phase = round(back["t"] - ev["t"], 3)
    down = back["row"] > ev["row"]
    return phase, down


def race(log, events):
    rows = []
    hits = attacks(events)
    for k, ev in enumerate(hits):
        if ev["name"] != "dstab":
            continue
        nxt = None
        for later in hits[k + 1:]:
            if later["t"] - ev["t"] >= kb.BUNDLED:
                nxt = later
                break
        row = {"src": log.id, "row": ev["row"], "t": ev["t"], "phase": None, "down": None, "eat_clock": None,
               "next_row": None, "next": None, "gap": None, "eats": None, "winner": None, "by": None, "first_eat": None,
               "delay": None}
        start, back = eat_state(events, ev["row"])
        if back is not None:
            row["phase"], row["down"] = phase_at(back, ev)
        # The next attack bounds the eats between, even when it comes too late to pair (DISENGAGED).
        end = nxt["row"] if nxt else None
        if nxt is not None and nxt["t"] - ev["t"] >= kb.DISENGAGED:
            nxt = None
        # The eats between this strike and the next attack, and how long the first one waited for the eat to be up.
        between = [e for e in events if is_eat(e) and e["row"] > ev["row"] and (end is None or e["row"] < end)]
        if between and (back is not None or start is None):
            ready = max(ev["t"], back["t"]) if back is not None else ev["t"]
            row["delay"] = round(between[0]["t"] - ready, 3)
            row["first_eat"] = between[0]["args"][1]
        if nxt is None:
            rows.append(row)
            continue
        row.update(next_row=nxt["row"], next=nxt["family"], gap=round(nxt["t"] - ev["t"], 3), eats=len(between))
        start2, back2 = eat_state(events, nxt["row"])
        if back2 is not None:
            p2, down2 = phase_at(back2, nxt)
            row["winner"] = "strike" if down2 else "herb"
            row["by"] = abs(p2)
            row["eat_clock"] = round(back2["t"] - start2["t"], 3)
        rows.append(row)
    return rows


def median(values):
    values = sorted(values)
    if not values:
        return None
    return round(kb.percentile(values, 0.5), 3)


def summary(rows):
    paired = [r for r in rows if r["winner"]]
    strike = [r for r in paired if r["winner"] == "strike"]
    return {"dstab": len(rows), "paired": len(paired), "strike_first": len(strike), "herb_first": len(paired) - len(strike),
            "strike_first_down": sum(1 for r in strike if r["down"]),
            "one_eat_between": sum(1 for r in paired if r["eats"] == 1),
            "phase_median": median([r["phase"] for r in rows if r["phase"] is not None]),
            "gap_median": median([r["gap"] for r in paired]),
            "eat_clock_median": median([r["eat_clock"] for r in paired if r["eat_clock"] is not None]),
            "delay_median": median([r["delay"] for r in rows if r["delay"] is not None and r["delay"] >= 0])}


def golden(rows, spec):
    """The frozen golden row: Z5 row 196, strike first by 0.567, PHASE +0.602."""
    for r in rows:
        if r["src"] == spec["log"] and r["row"] == spec["strike_row"]:
            ok = (r["next_row"] == spec["next_strike_row"] and r["winner"] == "strike"
                  and abs(r["phase"] - spec["phase_at_strike"]) <= spec["tolerance"]
                  and abs(r["by"] - spec["strike_first_by"]) <= spec["tolerance"])
            return ok, r
    return False, None


# ---------------------------------------------------------------------------------------------
# The suppliers: afflictions with no attacker line in front of them (foundations.md, Timed effects)
# ---------------------------------------------------------------------------------------------

# foundations.md calls each of these single-source. Each log re-measures them here.
CHAIN = ("nausea", "lethargy", "impatience")
SNAP_REACH = 15.0
SNAKE_REACH = 20.0


def suppliers(events):
    """Delays, in seconds, per supplier. A chain delay runs from the hypochondria gain to the first gain of that affliction
    before the hypochondria is cured. A SNAP delay runs to the next suggested anorexia line inside SNAP_REACH. A snake gap
    runs between two pet lines (hit or coated) inside SNAKE_REACH. Late events (after the last prompt) are skipped."""
    out = {"hypochondria." + a: [] for a in CHAIN}
    out["snap.anorexia"] = []
    out["snake.gap"] = []
    for k, ev in enumerate(events):
        if ev.get("late"):
            continue
        if ev["kind"] == "gain" and ev["name"] == "hypochondria":
            seen = set()
            for later in events[k + 1:]:
                if later.get("late"):
                    break
                if later["kind"] == "lose" and later["name"] == "hypochondria":
                    break
                if later["kind"] == "gain" and later["name"] == "hypochondria":
                    break
                if later["kind"] == "gain" and later["name"] in CHAIN and later["name"] not in seen:
                    seen.add(later["name"])
                    out["hypochondria." + later["name"]].append(round(later["t"] - ev["t"], 3))
        elif ev["name"] == "snap":
            for later in events[k + 1:]:
                if later["t"] - ev["t"] > SNAP_REACH or later.get("late"):
                    break
                # Only the suggested line: a venom's anorexia in the same window is not the SNAP's (Z5 5189 to 5221).
                if later["kind"] == "gain" and later["name"] == "anorexia" and "suggested" in later["args"]:
                    out["snap.anorexia"].append(round(later["t"] - ev["t"], 3))
                    break
    snakes = [ev for ev in events if ev["name"] in ("snake.hit", "snake.blocked") and not ev.get("late")]
    for a, b in zip(snakes, snakes[1:]):
        if b["t"] - a["t"] <= SNAKE_REACH:
            out["snake.gap"].append(round(b["t"] - a["t"], 3))
    return out


SUPPLIER_ROWS = (
    ("hypochondria.nausea", "Hypochondria to nausea", "+3.12, one fight (Z5)"),
    ("hypochondria.lethargy", "Hypochondria to lethargy", "+6.24, one fight (Z5)"),
    ("hypochondria.impatience", "Hypochondria to impatience", "+9.31, one fight (Z5)"),
    ("snap.anorexia", "SNAP to anorexia", "9.0-11.0, 7 of 7, one player (az)"),
    ("snake.gap", "Snake line to snake line", "about 8.1, one fight (g)"),
)


def spread(values):
    if not values:
        return "-"
    st = kb.stats(values)
    if st["n"] == 1:
        return "%.2f (n=1)" % st["median"]
    return "%.2f (%.2f-%.2f, n=%d)" % (st["median"], st["min"], st["max"], st["n"])


# ---------------------------------------------------------------------------------------------
# The page
# ---------------------------------------------------------------------------------------------


CENSUS_ROWS = (
    ("dstab", "DSTAB: 'quickly pricks you with his dirk'"),
    ("dstab.second", "DSTAB, second venom: 'Striking like a snake, ... follows the first attack with another' (follows hits and misses)"),
    ("dstab.miss", "DSTAB missed: 'misses you with his dirk'"),
    ("bite", "BITE: 'sinks his fangs into your body'"),
    ("flay.shield", "FLAY of the shield"),
    ("flay.rebounding", "FLAY of rebounding"),
    ("flay.whip", "FLAY, the whip lands: 'With fluid grace, ... snaps his wrist'"),
    ("blocked.shield", "An attack stopped by our shield"),
    ("rebounded", "An attack rebounded onto the Serpent: 'The attack rebounds back onto ...!'"),
    ("rebounded.aura", "'The attack rebounds off your aura of protection!'"),
    ("snap", "SNAP: 'snaps his fingers in front of you'"),
    ("snap.bare", "SNAP, bare: 'snaps his fingers.'"),
    ("gaze.command", "IMPULSE: 'fixes his gaze to yours and hisses a sharp command' (in the packet of each BITE, 22 of 22)"),
    ("impulse.fired", "'Your equilibrium is thrown off by an awakened mental impulse'"),
    ("gain:hypochondria", "'A terrible sense of unease comes over you' (the hypochondria gain line)"),
    ("shrug", "The Serpent's SHRUG: 'hunches his shoulders and lets out a soft hiss'"),
    ("snake.hit", "A pet's bite lands (az and g: a tree snake, X: a rattlesnake, Z5: a saw-scaled viper)"),
    ("snake.blocked", "A pet's bite meets the waxy coating"),
    ("agony", "'You scream out in agony as a vicious venom tears through your body'"),
    ("vomit", "Nausea's vomit line"),
    ("darkshade.burn", "Darkshade's burn: 'Your skin prickles and burns.' (a gain only when the board lacks darkshade)"),
    ("eat.eat", "Eat, on the eat clock"),
    ("eat.moss", "Eat moss or potash (own clock)"),
    ("eat.smoke", "Eat pear or calcite (spends the lungs)"),
    ("smoke", "Smoke"),
    ("salve", "Salve"),
    ("salve.refused", "Salve on slick skin: 'The salve slides off your oily skin' (no salve clock spent)"),
    ("sip", "Sip"),
    ("tree", "Tree"),
    ("focus", "Focus"),
    ("fitness", "FITNESS"),
    ("salt", "Salt (Alchemist)"),
    ("accelerate", "Accelerate (Depthswalker)"),
    ("dagaz", "Dagaz rune tick"),
    ("shield.up", "Our shield goes up"),
    ("rebounding.up", "Our rebounding comes up"),
    ("sileris.apply", "Sileris applied"),
    ("sileris.up", "Sileris hardens: the coating is up"),
    ("sileris.down", "The coating goes: ripped away, dissolves, or sloughs off"),
    ("shield.down", "Our shield falls: we moved or acted"),
    ("rebounding.down", "Our rebounding falls: 'Your aura of weapons rebounding disappears'"),
    ("refused.paralysis", "Refused: paralysis"),
    ("refused.weary", "Refused: too weary"),
    ("refused.slickness", "Refused: a salve on slick skin"),
    ("refused.balance", "Refused: balance or equilibrium"),
    ("refused.humour", "Refused: the humour clock"),
    ("refused.salt", "Refused: Salt in its lockout"),
    ("refused.accelerate", "Refused: Accelerate in its lockout"),
    ("refused.study", "Refused: the Alchemist's STUDY in its lockout"),
    ("eq.used", "'Equilibrium used: N s.' (the game's cost line)"),
    ("bal.used", "'Balance used: N s.'"),
    ("recover.eq", "'You have recovered equilibrium'"),
    ("recover.bal", "'You have recovered balance on all limbs'"),
    ("recover.salt", "Salt is back: 'You may channel alchemical energy to heal yourself once again'"),
    ("recover.accelerate", "Accelerate is back: 'You may accelerate time to cleanse your afflictions once again'"),
    ("death", "Death"),
    ("late", "Events after the last prompt (stamped at that prompt, marked late)"),
)


def fmt(value, sign=False):
    if value is None:
        return "-"
    return ("%+.3f" if sign else "%.3f") % value


def signed(phase, down):
    """A PHASE of 0.000 takes its sign from the row order."""
    if phase is None:
        return "-"
    if phase == 0:
        return "+0.000" if down else "-0.000"
    return fmt(phase, True)


def render(data):
    g = data["golden"]
    ties = [r for r in data["race"] if r["winner"] and r["by"] == 0]
    lines = [
        "---",
        "topic: the Serpent logs as events, and the race between the DSTAB and the eat",
        "confidence: MEASURED (counted from log rows; boards are the loggers' beliefs)",
        "generated_by: tools/kb_events.py",
        "---",
        "",
        "# The Serpent logs: census and race",
        "",
        "**GENERATED. Do not edit.** Run `python tools/kb_events.py`. Plan step 7.2, stage 1a: the logs first, before the engine.",
        "",
        "Freeze file `tools/sim/gates_whole.json`, sha256 `%s`." % data["freeze_sha256"],
        "",
        "## The race, in one row",
        "",
        "At a DSTAB, is the victim's eat still down? **PHASE** is the time until the eat comes back: positive means down, negative",
        "means up that long already. A pair (this DSTAB, the next attack) is won by **the strike** when the eat is still down at the",
        "next attack, and by **the herb** when it is back. The clock lengths alone do not decide it: where each clock stands does.",
        "",
        "**Golden row: %s.** `%s` row %s: PHASE %s at the strike; the next attack at row %s, %s s later; the eat clock %s s;"
        " the %s first by %s s." % (
            "PASS" if g["pass"] else "FAIL", g["row"]["src"] if g["row"] else "-", g["row"]["row"] if g["row"] else "-",
            fmt(g["row"]["phase"], True) if g["row"] else "-", g["row"]["next_row"] if g["row"] else "-",
            fmt(g["row"]["gap"]) if g["row"] else "-", fmt(g["row"]["eat_clock"]) if g["row"] else "-",
            g["row"]["winner"] if g["row"] else "-", fmt(g["row"]["by"]) if g["row"] else "-"),
        "",
        "## The race, per log",
        "",
        "| Log | DSTABs | Paired | Strike first | of them, eat down at the strike | Herb first | One eat between |"
        " PHASE at the strike, median | Gap, median | Eat clock, median | Delay to the first eat, median |",
        "|---|---|---|---|---|---|---|---|---|---|---|",
    ]
    for key in KEYS + ("all",):
        s = data["race_summary"][key]
        lines.append("| %s | %d | %d | %d | %d | %d | %d | %s | %s | %s | %s |" % (
            key, s["dstab"], s["paired"], s["strike_first"], s["strike_first_down"], s["herb_first"], s["one_eat_between"],
            fmt(s["phase_median"], True), fmt(s["gap_median"]), fmt(s["eat_clock_median"]), fmt(s["delay_median"])))
    lines += [
        "",
        "- A DSTAB is unpaired when no attack follows within 10 s (`kb_timing.DISENGAGED`), or when the log shows no eat and",
        "  recovery pair around the next attack. An eat whose recovery line comes more than %.1f s later counts as not shown." % EAT_MAX,
        "- Rows in one packet share a stamp. On a tie the row order decides: a recovery line after the attack line means the",
        "  eat was still down.",
        "- **One eat between**: the victim ate once between the two attacks. In a strike-first pair, that eat came back and was",
        "  spent again before the next attack: the herb cured one thing, and the next strike landed on a spent eat.",
        "- The delay to the first eat runs from the later of the strike and the eat's return, to the first eat before the next",
        "  attack. A negative delay (an eat in the same packet as the strike) is left out of its median. It is the logger's",
        "  reaction, not a pure SSC delay: an affliction the logger did not cure with the eat also waits here.",
        "- The loggers ran their own curing, so these are THEIR races, not ours.",
        "- %d paired rows tie at the stamp (the eat's return and the next attack in one packet). The row order gave %d to the"
        % (len(ties), sum(1 for r in ties if r["winner"] == "strike")),
        "  strike and %d to the herb: %s." % (sum(1 for r in ties if r["winner"] == "herb"),
                                             ", ".join("%s %d" % (r["src"], r["row"]) for r in ties)),
        "",
        "## Census",
        "",
        "Game lines only: a client's own echoes are not counted. The 'gaze' line is an IMPULSE that bites: each of the 22 BITEs",
        "has it in its packet, and each of the 22 'gaze' lines a BITE (az 1238-1242, Z5 534-537, X 293-296).",
        "",
        "The second-venom line follows every DSTAB, hit or miss: second-venom lines = pricks + misses in %s."
        % ", ".join("%s %s" % (k, "yes" if data["census"][k]["lines"].get("dstab.second", 0)
                                == data["census"][k]["lines"].get("dstab", 0) + data["census"][k]["lines"].get("dstab.miss", 0)
                                else "NO") for k in KEYS),
        "",
        "| Line | " + " | ".join(KEYS) + " |",
        "|---|" + "---|" * len(KEYS),
    ]
    for name, title in CENSUS_ROWS:
        field, key = ("gains", name[5:]) if name.startswith("gain:") else ("lines", name)
        lines.append("| %s | %s |" % (title, " | ".join(str(data["census"][k][field].get(key, 0)) for k in KEYS)))
    lines += ["", "**Afflictions gained, by the game's own line** (`afflictions.json` `afflicted_msg`, plus the %d lines in"
              " `kb_events.EXTRA_GAINS`, each with the rows that tag it), the ten most:" % len(EXTRA_GAINS), "",
              "Where afflictions.json gives several afflictions one message, `kb_events.SHARED` picks one from the loggers'"
              " own tags (the ugliness lines are disloyalty). An unresolved shared message names all of them, joined by `|`.",
              ""]
    for key in KEYS:
        top = sorted(data["census"][key]["gains"].items(), key=lambda kv: (-kv[1], kv[0]))[:10]
        lines.append("- `%s`: %s" % (key, ", ".join("%s %d" % kv for kv in top) or "none"))
    lines += ["", "## Suppliers, re-measured in every log", "",
              "`kb/mechanics/foundations.md` (Timed effects) calls each of these single-source. Median (min-max, n); `-` means none.",
              "", "| Supplier | foundations.md before 2026-11-07 | " + " | ".join(KEYS) + " |", "|---|---|" + "---|" * len(KEYS)]
    for name, title, old in SUPPLIER_ROWS:
        lines.append("| %s | %s | %s |" % (title, old, " | ".join(spread(data["census"][k]["suppliers"][name]) for k in KEYS)))
    lines += ["", "A chain delay runs from the hypochondria gain to the first gain of that affliction before the hypochondria is",
              "cured. A SNAP delay runs to the next suggested anorexia line ('The thought of food revolts you all of a sudden.')",
              "within %.0f s. A venom's anorexia does not count." % SNAP_REACH,
              "A snake gap runs between two pet lines (a hit or the waxy coating) within %.0f s." % SNAKE_REACH,
              "Late events (after the last prompt) are left out of these delays."]
    lines += ["", "## Every DSTAB", "",
              "| Log | Row | t | PHASE | Next | Next row | Gap | Eats between | Eat clock | Winner | By | First eat | Delay |",
              "|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for r in data["race"]:
        lines.append("| %s | %d | %.3f | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |" % (
            r["src"], r["row"], r["t"], signed(r["phase"], r["down"]), r["next"] or "-", r["next_row"] or "-", fmt(r["gap"]),
            "-" if r["eats"] is None else r["eats"], fmt(r["eat_clock"]), r["winner"] or "-", fmt(r["by"]),
            r["first_eat"] or "-", fmt(r["delay"], True)))
    return "\n".join(lines) + "\n"


def build():
    data = {"generated_by": "tools/kb_events.py", "stream_version": STREAM_VERSION, "census": {}, "race": [], "race_summary": {}}
    import kb_rules
    data["freeze_sha256"] = kb_rules.freeze_hash()
    for key in KEYS:
        log = load(key)
        events = stream(log)
        counts, gains, loses = census(events)
        data["census"][key] = {"log": os.path.basename(log_path(key)), "family": log.family, "prompts": log.prompts,
                               "lines": dict(sorted(counts.items())), "gains": dict(sorted(gains.items())),
                               "loses": dict(sorted(loses.items()))}
        data["census"][key]["suppliers"] = suppliers(events)
        rows = race(log, events)
        data["race"] += rows
        data["race_summary"][key] = summary(rows)
    data["race_summary"]["all"] = summary(data["race"])
    ok, row = golden(data["race"], gates()["stage1"]["golden_race_row"])
    data["golden"] = {"pass": ok, "row": row}
    return data


def dump(data):
    return json.dumps(data, indent=1, sort_keys=True) + "\n"


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--check", action="store_true", help="fail if the files do not match the logs, or the golden row fails")
    ap.add_argument("--dump", metavar="KEY", choices=KEYS, help="print one log's stream as JSON Lines")
    args = ap.parse_args()
    if args.dump:
        for ev in stream(load(args.dump)):
            print(json.dumps(ev, sort_keys=True))
        return 0
    data = build()
    text_json, text_md = dump(data), render(data)
    if args.check:
        bad = []
        for path, text in ((OUT_JSON, text_json), (OUT_MD, text_md)):
            have = None
            if os.path.exists(path):
                with open(path, "rb") as fh:
                    have = fh.read().replace(b"\r\n", b"\n").decode("utf-8")
            if have != text:
                bad.append("STALE: %s. Run python tools/kb_events.py" % os.path.relpath(path, ROOT))
        if not data["golden"]["pass"]:
            bad.append("the golden race row fails: %r" % (data["golden"]["row"],))
        if bad:
            print("kb_events: " + "; ".join(bad))
            return 1
        print("kb_events: %d DSTABs, golden row PASS, files match the logs" % len(data["race"]))
        return 0
    for path, text in ((OUT_JSON, text_json), (OUT_MD, text_md)):
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(text)
    print("kb_events: wrote %d DSTABs; golden row %s" % (len(data["race"]), "PASS" if data["golden"]["pass"] else "FAIL"))
    return 0 if data["golden"]["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
