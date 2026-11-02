#!/usr/bin/env python3
"""Parse every combat log with one stamp rule, and generate the clocks page and the scoreboard.

    python tools/kb_timing.py                # write kb/mechanics/clocks.md, clocks.json and scoreboard.md
    python tools/kb_timing.py --check        # regenerate in memory, diff, exit 1 on any difference (CI runs this)
    python tools/kb_timing.py --counts       # prompts and wrapped prompts per family and per log
    python tools/kb_timing.py --score a.log  # score one recording: refusals, stale attacks, the step 3 pass bars

Library use, for kb_replay.py and fightlog_import.py:

    from kb_timing import parse
    log = parse("kb/raw/logs/ours/2026-10-27_112717_Tabethys.log")
    log.family, log.prompts, log.wrapped
    for row in log: row.n, row.time, row.kind, row.text, row.board

Input is kb/raw/logs/*.txt and kb/raw/logs/ours/*.log, never the HTML exports (git-ignored). The raw logs are
evidence, so this tool only reads them. Output is byte-identical across runs and across Windows and Linux: everything
is sorted, and files are written as LF in UTF-8.
"""
import argparse
import bisect
import collections
import difflib
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOGS = os.path.join(ROOT, "kb", "raw", "logs")
OURS = os.path.join(LOGS, "ours")
ABILITIES = os.path.join(ROOT, "kb", "classes", "abilities.json")
OUT_MD = os.path.join(ROOT, "kb", "mechanics", "clocks.md")
OUT_JSON = os.path.join(ROOT, "kb", "mechanics", "clocks.json")
OUT_SCORE = os.path.join(ROOT, "kb", "mechanics", "scoreboard.md")

# ---------------------------------------------------------------------------------------------
# THE PARSER
# ---------------------------------------------------------------------------------------------


class Row:
    """One row of a log.

    n      the 0-based physical row, the base the studies cite for most logs.
    time   the NEXT prompt's stamp, in seconds that never go back. A prompt's time is its own stamp. The studies
           mixed previous-prompt and next-prompt times, and that moved results (WK Latency 52.39 against 52.79), so
           there is one rule. A row after the last prompt has time None, because nothing stamps it.
    own    the row's own stamp where it carries one: every row of our recorder, and every prompt. A sent row needs
           this, because the next prompt can come 100 ms after the send.
    kind   prompt, line, or for our recorder also sent, +aff, -aff, +def, -def, +tar, -tar, note.
    text   the row as logged. A wrapped prompt holds all its physical rows, joined.
    board  for a prompt, the tokens of the logger's OWN board as printed. [] is an empty board. None means the family
           prints no board (Blademaster). Our recorder prints none either, so its board is the +aff/-aff set.
    lock   the logger's own lock word, kept out of the board: Mystor's [h] or [true], Sentinel's (Locks: ...).
    span   the physical rows this row used. Mystor's prompt is always 2 or more, because its stamp has its own row.
    """
    __slots__ = ("n", "time", "own", "kind", "text", "board", "lock", "span")

    def __init__(self, n, kind, text, own=None, board=None, lock=None, span=1):
        self.n = n
        self.time = None
        self.own = own
        self.kind = kind
        self.text = text
        self.board = board
        self.lock = lock
        self.span = span

    def __repr__(self):
        return "Row(%d, %s, %r, %r)" % (self.n, self.kind, self.time, self.text[:50])


class Log(list):
    """The rows of one file, and what the file says about itself."""
    # date is the date in the file name, except on our recorder, whose header gives the fight's date. A client log's date
    # is the day its export was saved (tools/kb_log_import.py takes it from the file's modified time), not the fight's.
    name = id = family = logger = date = version = our_class = rounds = resolution = None
    prompts = 0
    wrapped = 0        # prompts the server wrapped onto more rows, not counting Mystor's stamp row
    fixed_stamps = 0   # .00 stamps moved forward one second
    held_stamps = 0    # stamps that went back with no known cause, held at the previous stamp
    unstamped = 0      # prompt-shaped rows with no time in them


def hms_ms(m):
    return int(m.group(1)) * 3600 + int(m.group(2)) * 60 + int(m.group(3)) + int(m.group(4)) / 1000.0


def hms_cs(m):
    return int(m.group(1)) * 3600 + int(m.group(2)) * 60 + int(m.group(3)) + int(m.group(4)) / 100.0


def hms(m):
    return float(int(m.group(1)) * 3600 + int(m.group(2)) * 60 + int(m.group(3)))


def sec_ms(m):
    return int(m.group(1)) + int(m.group(2)) / 1000.0


def min_sec_cs(m):
    return int(m.group(1)) * 60 + int(m.group(2)) + int(m.group(3)) / 100.0


# name: prompt regex, decode, period the stamp wraps at, seconds per stamp digit, whether .00 stamps can be bad.
# The regexes come from the clocks study (wr95c68dw, "Line shapes"). Mystor's prompt is a head row and this stamp row.
FAMILIES = {
    "claes": (re.compile(r"^H:\S+\|\S+ M:\S+\|\S+\s+(\d\d):(\d\d):(\d\d):(\d{3})"), hms_ms, 86400, 0.001, False),
    "nikita": (re.compile(r"^\d+\(\d+%\|\d+%\).*?(\d\d):(\d\d):(\d\d)\.(\d\d)\s"), hms_cs, 86400, 0.01, True),
    "elmer": (re.compile(r"^H:.*?Rage:\d+ (\d\d):(\d{3}) -"), sec_ms, 60, 0.001, False),
    "earth": (re.compile(r"^H:.*?R:\d+ (\d\d):(\d\d)\.(\d\d)-"), min_sec_cs, 3600, 0.01, True),
    "blademaster": (re.compile(r"^H:.*?W:\S+\s+(\d\d):(\d\d):(\d\d) -"), hms, 86400, 1.0, False),
    "mystor": (re.compile(r"^(\d\d):(\d\d):(\d\d) \(\d+\) \[[^\]]*\]:"), hms, 86400, 1.0, False),
    "sentinel": (re.compile(r"^(\d\d):(\d\d):(\d\d):(\d{3}) \[\d+\] \[\d+\] "), hms_ms, 86400, 0.001, False),
}
MYSTOR_HEAD = re.compile(r"^\[[^\]]*\] \[[^\]]*\] H:")
# o6UKnyyy has prompts with no time in them ("9227h, 10560m cekdb-"), so it cannot be clocked at all.
UNSTAMPED_PROMPT = re.compile(r"^\d+h, \d+m ")

LOGGERS = (
    ("_claes_", "Claes"),
    ("runewarden-snb-vs-shikudo_defender", "Claes"),
    ("_nikita_", "Nikita"),
    ("_elmer_", "Elmer"),
    ("_unknown_earthlord", "Earth Lord (unnamed)"),
    ("shikudo-vs-runewarden-snb_attacker", "Shikudo attacker (unnamed)"),
    ("_unknown_blademaster", "Blademaster (unnamed)"),
    ("_mystor_", "Mystor"),
    ("_leviticus_", "Leviticus"),
    ("shikudo-group-mhaldor", "Ours, client log"),
)

# Mystor's system prints the lock it believes in front of the board. These are not afflictions, and a naive
# "last bracket" read of "K:64% [true] " would call one a board. Counted over his six logs: h 132, true 103, s 34, v 12.
MYSTOR_DECOYS = {"h", "s", "v", "true"}
LIMBS = re.compile(r"^[\d.|]+$")
DATE = re.compile(r"^(\d{4}-\d\d-\d\d)_")
LIMB_BLOCK = re.compile(r"\[[\d.]+(?:\|[\d.]+){5}\]")
# Elmer's prompt can wrap just before its limb block. The first row ends "Kai: ", with every bracket closed, and the next
# row is "64%[75.4|...][pressure(3) disl]" (3ys7NuHA rows 4160-4161; 155 of its 773 prompts).
LIMB_ROW_START = re.compile(r"^\d+%\[[\d.|]+\]")
# A board group: "-- (w|hyper)" or "-- ()". A label's own parenthesis, as in "--TR/Hardlock(touch tree)", has no space or
# "--" in front of it, so it is not a board (kAQnlFAW row 1249, X8pRorzR row 363).
NIKITA_BOARD = re.compile(r"(?:--|\s)\(([^()]*)\)")
# Family is a property of the file, so the head of it is enough. A log with no match reads to the end.
DETECT_ROWS = 3000


def read_rows(path):
    # Logs have CRLF or LF depending on the checkout (.gitattributes does not pin .txt or .log), so strip \r here.
    with open(path, "rb") as fh:
        text = fh.read().decode("utf-8", errors="replace").replace("\r", "")
    rows = text.split("\n")
    if rows and rows[-1] == "":
        rows.pop()
    return rows


def detect_family(rows):
    """The family whose prompt shape matches most rows, or None."""
    for sample in (rows[:DETECT_ROWS], rows):
        best, best_n = None, 0
        for name in sorted(FAMILIES):
            n = sum(1 for r in sample if FAMILIES[name][0].search(r))
            if n > best_n:
                best, best_n = name, n
        if best:
            return best
    return None


def depth(text):
    """How many brackets are still open. An open one means the server wrapped the prompt."""
    return (text.count("[") - text.count("]")) + (text.count("(") - text.count(")"))


def tokens(inner):
    return [t for t in re.split(r"[\s,|]+", inner.strip()) if t]


def take_wrapped(rows, i, text):
    """Join the rows a wrapped prompt ran onto, and return the text and the rows used.

    882 prompts in the claes, elmer and earth families have an open [ on their first row, for example azbErKcK rows
    3735-3736. A parser that stops at the first row loses "naus ANO disl]", and with it the warning. `--counts` gives the
    wrapped prompts of every family. Only a row that closes the bracket is taken, so a log cut mid-prompt (uW_VbgR row 556
    ends the file) does not swallow rows that are not part of the prompt."""
    used = 1
    if depth(text) <= 0 and not LIMB_BLOCK.search(text) and i + 1 < len(rows) and LIMB_ROW_START.match(rows[i + 1]):
        text, used = text + rows[i + 1], 2
    if depth(text) <= 0:
        return text, used
    for extra in (1, 2):
        if i + used - 1 + extra < len(rows):
            joined = text + "".join(rows[i + used:i + used + extra])
            if depth(joined) <= 0:
                return joined, used + extra
    return text, used


def board_from_tail(tail):
    """Claes, Elmer, Earth Lord: the last [...] that is not the limb block or the [ Target ]. The last one may be
    open, because a cut log can end inside it."""
    for group in reversed(re.findall(r"\[([^\[\]]*)(?:\]|$)", tail)):
        if LIMBS.match(group) or group.startswith(" "):
            continue
        return tokens(group)
    return []


def nikita_board(tail):
    # "-- (w|hyper|PAR)" or "-- ()(9 - nw)". The second group is the mapper's walk counter.
    m = NIKITA_BOARD.search(tail)
    return tokens(m.group(1)) if m else []


def sentinel_board(tail):
    # "|(Grulk)|[ [ sen ANO (Locks: soft, venom, hard, true) ]]  [0|0|0|0|18.1|12.1]", or "|(659477)|[]  "
    m = re.search(r"\|\([^)]*\)\|\[(.*?)\]\]?(?:\s|$)", tail)
    if not m:
        return [], None
    inner = m.group(1).lstrip(" [")
    lock = re.search(r"\(Locks: ([^)]*)\)", inner)
    if lock:
        inner = inner.replace(lock.group(0), " ")
    return tokens(inner), lock.group(1) if lock else None


def mystor_board(head):
    # "... K:34% [h] [haem, SLCK, ANO] Bl:393 ". The groups before K: are balance, defences, a count and the form.
    m = re.search(r"K:\d+%(.*)$", head, re.S)
    groups = re.findall(r"\[([^\[\]]*)\]", m.group(1)) if m else []
    lock = None
    if groups and groups[0].strip() in MYSTOR_DECOYS:
        lock = groups.pop(0).strip()
    return (tokens(groups[-1]) if groups else []), lock


def unwrap(log, raw, period, bad_cents, state):
    """Turn one printed stamp into seconds that never go back. state is [offset, the last time given out]."""
    offset, last = state
    t = raw + offset
    if t < last:
        fell = last - t
        if bad_cents and raw == int(raw) and fell <= 1.0:
            # A .00 stamp can print one second early: kAQnlFAW row 736 reads 04:00:30.00 between 04:00:30.99 and
            # 04:00:31.23. Only a .00 stamp that goes BACK is known bad. 13 of Nikita's 21 .00 stamps go forward, and
            # moving those would put them after the next prompt (L8LSw7xD row 815: 04:22:03.00, then 04:22:03.20).
            log.fixed_stamps += 1
            t += 1.0
        elif period < 3600 or fell > period / 2.0:
            # SS:mmm wraps at 60, so any step back is the wrap. A silent gap over 60 s cannot be seen in that family.
            # The longer periods wrap only on a large step: the hour for MM:SS, midnight for HH:MM:SS.
            state[0] = offset + period
            t = raw + state[0]
        else:
            log.held_stamps += 1
            t = last
    state[1] = t
    return t


def stamp_rows(log):
    """The one stamp rule: walk backward and give each row the next prompt's stamp."""
    next_time = None
    for row in reversed(log):
        if row.kind == "prompt":
            next_time = row.own
        row.time = next_time


def parse_client(rows, family, log):
    regex, decode, period, log.resolution, bad_cents = FAMILIES[family]
    state = [0.0, float("-inf")]
    i = 0
    while i < len(rows):
        text = rows[i]
        if family == "mystor":
            head, span = take_wrapped(rows, i, text) if MYSTOR_HEAD.match(text) else (None, 0)
            m = regex.match(rows[i + span]) if head and i + span < len(rows) else None
            if not m:
                log.append(Row(i, "line", text))
                i += 1
                continue
            board, lock = mystor_board(head)
            t = unwrap(log, float(decode(m)), period, bad_cents, state)
            log.append(Row(i, "prompt", head + "\n" + rows[i + span], own=t, board=board, lock=lock, span=span + 1))
            log.prompts += 1
            log.wrapped += 1 if span > 1 else 0
            i += span + 1
            continue
        m = regex.search(text)
        if not m:
            log.append(Row(i, "line", text))
            i += 1
            continue
        tail = text[m.end():]
        if family == "nikita" and not NIKITA_BOARD.search(tail) and i + 1 < len(rows) and rows[i + 1].startswith(" ("):
            # The tag, " (hyper|PAR|AST)", takes the next row when the prompt is long: 542 of Nikita's 2,077 prompts.
            joined, span = text + rows[i + 1], 2
        else:
            joined, span = take_wrapped(rows, i, text)
        tail = joined[m.end():]
        lock = None
        if family == "nikita":
            board = nikita_board(tail)
        elif family == "sentinel":
            board, lock = sentinel_board(tail)
        elif family == "blademaster":
            board = None
        else:
            board = board_from_tail(tail)
        t = unwrap(log, float(decode(m)), period, bad_cents, state)
        log.append(Row(i, "prompt", joined, own=t, board=board, lock=lock, span=span))
        log.prompts += 1
        log.wrapped += 1 if span > 1 else 0
        i += span
    stamp_rows(log)


# The export's id follows the result word, and it can hold an underscore: 4c_SeyaA, J7Xnr_Jg, uW_VbgR.
ID_AFTER_RESULT = re.compile(r"_(?:win|loss|noresult)_(.+)$")
OUR_ROW = re.compile(r"^(\d\d):(\d\d):(\d\d)\.(\d{3}) (\S+) ?(.*)$")
OUR_HEADER = re.compile(r"\| version (\S+) \| started (\S+) \S+ \| opponent (\S+) \| our class (.+?) \|")
OUR_KINDS = {"|": "line", "P": "prompt", ">": "sent"}


def parse_ours(rows, log):
    log.family, log.logger, log.resolution, log.rounds = "ours", "Ours, recorder", 0.001, "raw"
    state, afflictions = [0.0, float("-inf")], set()
    for i, text in enumerate(rows):
        if text.startswith("#"):
            m = OUR_HEADER.search(text)
            if m:
                log.version, log.date, _, log.our_class = m.groups()
                log.logger = "Ours, recorder (%s)" % log.our_class
                # Logs from before the field are raw (kb/raw/logs/README.md).
                log.rounds = "alias" if text.rstrip().endswith("rounds alias") else "raw"
            log.append(Row(i, "note", text))
            continue
        m = OUR_ROW.match(text)
        if not m:
            log.append(Row(i, "line", text))
            continue
        t = unwrap(log, float(hms_ms(m)), 86400, False, state)
        kind = OUR_KINDS.get(m.group(5), m.group(5))
        body = m.group(6)
        if kind == "+aff":
            afflictions.add(body)
        elif kind == "-aff":
            afflictions.discard(body)
        row = Row(i, kind, body, own=t)
        if kind == "prompt":
            row.board = sorted(afflictions)
            log.prompts += 1
        log.append(row)
    stamp_rows(log)


def parse_rows(name, rows):
    """parse(), for rows already in memory. Tests use this with rows copied from real logs."""
    log = Log()
    log.name = log.id = name
    m = DATE.match(name)
    log.date = m.group(1) if m else None
    if rows and rows[0].startswith("# LEVI fight log"):
        parse_ours(rows, log)
        return log
    log.family = detect_family(rows)
    if log.family is None:
        log.unstamped = sum(1 for r in rows if UNSTAMPED_PROMPT.match(r))
        log.extend(Row(i, "line", r) for i, r in enumerate(rows))
        return log
    for needle, who in LOGGERS:
        if needle in name:
            log.logger = who
            break
    parse_client(rows, log.family, log)
    return log


def parse(path):
    """Read one log file. Returns a Log: a list of Row, with family, prompts and wrapped on it.

    A file with no stamped prompt has family None and no row has a time. o6UKnyyy is the only one."""
    return parse_rows(os.path.basename(path), read_rows(path))


def load_all():
    """Every log, sorted by path. Short ids are for tables: the last part of the name, with the logger when two clash."""
    paths = sorted(glob.glob(os.path.join(LOGS, "*.txt"))) + sorted(glob.glob(os.path.join(OURS, "*.log")))
    logs = [parse(p) for p in paths]
    suffixes = collections.Counter()
    for log in logs:
        stem = os.path.splitext(log.name)[0]
        if log.family == "ours":
            log.id = "ours/" + stem.split("_", 1)[1]
        else:
            m = ID_AFTER_RESULT.search(stem)
            log.id = m.group(1) if m else stem.rsplit("_", 1)[-1]
        suffixes[log.id] += 1
    for log in logs:
        if suffixes[log.id] > 1:
            log.id = "%s/%s" % ((log.logger or "x").split()[0].lower(), log.id)
    return logs


# ---------------------------------------------------------------------------------------------
# STATISTICS
# ---------------------------------------------------------------------------------------------


def percentile(ordered, q):
    """Linear interpolation, the same answer on every Python."""
    if len(ordered) == 1:
        return ordered[0]
    pos = (len(ordered) - 1) * q
    low = int(pos)
    high = min(low + 1, len(ordered) - 1)
    return ordered[low] + (ordered[high] - ordered[low]) * (pos - low)


def stats(values):
    ordered = sorted(values)
    if not ordered:
        return {"n": 0}
    p10, p90 = percentile(ordered, 0.10), percentile(ordered, 0.90)
    return {"n": len(ordered), "min": round(ordered[0], 3), "p10": round(p10, 3),
            "median": round(percentile(ordered, 0.50), 3), "p90": round(p90, 3), "max": round(ordered[-1], 3),
            "spread": round(p90 - p10, 3)}


def usable(st):
    """The critique's rule (w8320bdop, item 7): a width over 0.2 s can hide a 1.9/2.1 mix, and n under 10 misses the
    median by more than the +-0.05 a clock needs. Returns (usable, the reason it is not)."""
    if st.get("n", 0) < 10:
        return False, "n=%d is under 10" % st.get("n", 0)
    if st["spread"] > 0.2:
        return False, "p90-p10 is %.3f, over 0.2" % st["spread"]
    return True, ""


# ---------------------------------------------------------------------------------------------
# CLOCKS
# ---------------------------------------------------------------------------------------------

# channel, its recovery line, and the label Mystor's system prints it under.
RECOVERY = (
    ("eat", re.compile(r"^You may eat another plant or mineral"), "Eat"),
    ("moss", re.compile(r"^You may eat another bit of irid moss or potash"), "Moss"),
    ("smoke", re.compile(r"^Your lungs have recovered enough to smoke"), "Smoke"),
    ("salve", re.compile(r"^You may apply another salve to yourself"), "Salve"),
    ("sip", re.compile(r"^You may drink another health or mana elixir"), "Sip"),
    ("tree", re.compile(r"^You may utilise the tree tattoo again"), "Tree"),
    ("focus", re.compile(r"^Your mind is able to focus once again"), "Focus"),
    ("fitness", re.compile(r"^You may purge your lungs once again"), None),
    ("immunity", re.compile(r"^Your system is able to absorb antidotes once again"), None),
    ("humour", re.compile(r"^You may manipulate another's humours once more"), None),
    ("salt", re.compile(r"^You may channel alchemical energy to heal yourself once again"), None),
)
CHANNEL_NAMES = (
    ("eat", "Eat"), ("smoke", "Smoke (lungs)"), ("salve_short", "Salve, short"), ("restoration", "Salve, restoration"),
    ("salve_unknown", "Salve, type not shown"), ("focus", "Focus"), ("sip", "Sip"), ("moss", "Moss, potash"),
    ("tree", "Tree"), ("fitness", "FITNESS lockout"), ("immunity", "Immunity sip"), ("humour", "Humour"),
    ("salt", "Alchemist salt lockout"), ("rebounding", "Rebounding after a smoke, third person"),
    ("dagaz", "Dagaz rune tick"),
)
EAT_START = re.compile(r"^You (?:quickly )?eat (.+)$")
# Moss and potash have their own clock (CONFLICTS #11).
EAT_MOSS = re.compile(r"\b(?:irid moss|potash)\b")
# Pear and calcite are eaten but spend the lungs: 29 of 29 such eats were followed by the lungs line with no smoke
# between them (kb/afflictions/cure-channels.md).
EAT_LUNGS = re.compile(r"\b(?:pear|calcite)\b")
# Quartz is eaten 1-3 ms after another herb by three players (ours/2026-10-27_112717 rows 7428, 7463, 7488), so it is
# not on the eat clock and must not restart it.
EAT_NOT_A_CLOCK = re.compile(r"\bquartz\b")
SMOKE_START = re.compile(r"^You take a long drag")
SALVE_START = re.compile(r"^You take out some salve and quickly rub it on your (\w+)")
SIP_START = re.compile(r"^You take a drink from")
TREE_START = re.compile(r"^You touch the tree of life tattoo")
FOCUS_START = re.compile(r"^You focus your mind intently")
FITNESS_START = re.compile(r"^You inhale deeply, purging yourself of your asthmatic condition")
HUMOUR_START = re.compile(r"^You glower at ")
SALT_START = re.compile(r"^Directing the energy of salt, .*purging yourself of ailments")
CURING = re.compile(r"^\[Curing\]: (.+)$")
HEALED = re.compile(r"stronger and healthier")
PRINTED = re.compile(r"\((\d+\.\d+)\)\.*\s*$")
MYSTOR_RECOV = re.compile(r"^\[(\w+) Recov: ([\d.]+)s\]")
DAGAZ_TICK = re.compile(r"^A rune like a rising sun upon the ground flares, bathing you with healing magic")
THIRD_SMOKE = re.compile(r"^([A-Z][a-z]+) takes a long drag off")
REBOUND_SEEN = re.compile(r"^You suddenly perceive the vague outline of an aura of rebounding around (\w+)")
# A gap this long between two ticks is a different rune or a different room, not one rune's cycle.
DAGAZ_MAX_GAP = 30.0
# This many rows on, a [Curing] row still names the action it announced (S:1540-1541, with an OUTR row between).
CURING_REACH = 3
SHORT_SALVES = ("APPLY MENDING", "APPLY EPIDERMAL", "APPLY CALORIC")
# The same fight as ours/2026-10-27_112717 up to 11:28:22, so its samples would count twice. It stays parsed and listed.
SAME_FIGHT = {"2026-10-27_shikudo-group-mhaldor.txt": "2026-10-27_112717_Tabethys.log"}


def clock_samples(log):
    """Every clock sample in a log, one per recovery line (or per tick for the interval clocks).

    A sample is (channel, printed, line, end row, start row). printed is the number the logger's client printed, as in
    "Tree (13.916)" or "[Eat Recov: 1.59s]". Those timers start at the action line, so latency does not change the length
    on average (printed minus line-to-line has median +0.001 in Claes's logs, n=615). line is the same interval from
    this tool's own stamps: the most recent start row paired with the next recovery row, each start used once."""
    samples, unpaired = [], collections.Counter()
    starts = {}
    curing_at, curing = -99, ""
    healed = False
    last_tick, third_smoke = None, {}
    for j, row in enumerate(log):
        if row.kind != "line" or row.time is None:
            continue
        text = row.text
        if not text:
            continue
        m = CURING.match(text)
        if m:
            curing_at, curing = j, m.group(1)
            continue
        named = curing if j - curing_at <= CURING_REACH else ""
        channel = None
        m = EAT_START.match(text)
        if m:
            what = m.group(1)
            if EAT_MOSS.search(what):
                channel = "moss"
            elif EAT_LUNGS.search(what):
                channel = "smoke"
            elif EAT_NOT_A_CLOCK.search(what):
                continue
            else:
                channel = "eat"
        elif SMOKE_START.match(text):
            channel = "smoke"
        elif SIP_START.match(text):
            channel = "immunity" if named.startswith("SIP IMMUNITY") else "sip"
        elif TREE_START.match(text):
            channel = "tree"
        elif FOCUS_START.match(text):
            channel = "focus"
        elif FITNESS_START.match(text):
            channel = "fitness"
        elif HUMOUR_START.match(text):
            channel = "humour"
        elif SALT_START.match(text):
            channel = "salt"
        else:
            m = SALVE_START.match(text)
            if m:
                # The [Curing] row names the salve. Skin only takes a short salve. Otherwise it stays unknown until a
                # limb line proves restoration. Its own length never sorts it, because that would be circular.
                channel = "salve"
                healed = False
                kind = "unknown"
                if named.startswith("APPLY RESTORATION"):
                    kind = "restoration"
                elif named.startswith(SHORT_SALVES) or m.group(1) == "skin":
                    kind = "salve_short"
                starts["salve_kind"] = kind
        if channel:
            starts[channel] = (row.time, row.n)
            continue
        if HEALED.search(text):
            healed = True
        if DAGAZ_TICK.match(text):
            if last_tick is not None and row.time - last_tick[0] < DAGAZ_MAX_GAP:
                samples.append(("dagaz", None, row.time - last_tick[0], row.n, last_tick[1]))
            last_tick = (row.time, row.n)
            continue
        m = THIRD_SMOKE.match(text)
        if m:
            third_smoke[m.group(1)] = (row.time, row.n)
            continue
        m = REBOUND_SEEN.match(text)
        if m:
            smoke = third_smoke.pop(m.group(1), None)
            if smoke:
                samples.append(("rebounding", None, row.time - smoke[0], row.n, smoke[1]))
            continue
        for name, regex, label in RECOVERY:
            if not regex.match(text):
                continue
            printed = None
            m = PRINTED.search(text)
            if m:
                printed = float(m.group(1))
            elif label and j + 1 < len(log) and log[j + 1].kind == "line":
                m = MYSTOR_RECOV.match(log[j + 1].text)
                if m and m.group(1) == label:
                    printed = float(m.group(2))
            start = starts.pop(name, None)
            line = row.time - start[0] if start else None
            out = name
            if name == "salve":
                kind = starts.pop("salve_kind", "unknown")
                if kind == "unknown" and healed:
                    kind = "restoration"
                out = kind if kind != "unknown" else "salve_unknown"
                healed = False
            if printed is None and line is None:
                unpaired[out] += 1
            else:
                samples.append((out, printed, line, row.n, start[1] if start else None))
            break
    return samples, unpaired


def preferred(sample, resolution):
    """The value a sample adds to a pool: the printed timer, or the line-to-line time when the stamps can resolve it."""
    if sample[1] is not None:
        return sample[1]
    if sample[2] is not None and resolution <= 0.01:
        return sample[2]
    return None


def build_clocks(logs):
    """Pool the samples by channel, by logger and by method. Each logger's row names its logs, dates and versions."""
    per_channel = collections.defaultdict(list)
    unpaired = collections.Counter()
    for log in logs:
        if log.family is None or log.name in SAME_FIGHT:
            continue
        found, missed = clock_samples(log)
        unpaired.update(missed)
        for s in found:
            per_channel[s[0]].append((log, s))
    out = {}
    for channel, title in CHANNEL_NAMES:
        items = per_channel.get(channel, [])
        valued = [(log.logger, preferred(s, log.resolution)) for log, s in items]
        valued = [(who, v) for who, v in valued if v is not None]
        st = stats([v for _, v in valued])
        ok, why = usable(st)
        # Take each logger out in turn. A pool can fail on one logger's timer and not on a disagreement about the clock.
        without = {who: stats([v for other, v in valued if other != who]).get("spread") for who in sorted({w for w, _ in valued})}
        methods = collections.Counter()
        for log, s in items:
            if s[1] is not None:
                methods["printed"] += 1
            elif s[2] is not None and log.resolution <= 0.01:
                methods["line"] += 1
            elif s[2] is not None:
                methods["line_1s"] += 1
        by_logger = {}
        for log, s in items:
            entry = by_logger.setdefault(log.logger, {"printed": [], "line": [], "line_1s": [], "logs": {},
                                                      "filed": set(), "versions": set()})
            if s[1] is not None:
                entry["printed"].append(s[1])
            if s[2] is not None:
                entry["line" if log.resolution <= 0.01 else "line_1s"].append(s[2])
            entry["logs"][log.id] = entry["logs"].get(log.id, 0) + 1
            entry["filed"].add(log.date or "-")
            entry["versions"].add(log.version or "-")
        rows = []
        for logger in sorted(by_logger):
            entry = by_logger[logger]
            for method in ("printed", "line", "line_1s"):
                if entry[method]:
                    mst = stats(entry[method])
                    mok, mwhy = usable(mst)
                    if method == "line_1s":
                        # p90-p10 reads 0 here only because the stamps are quantised. Mystor's Moss reads 6.00 on 1 s stamps
                        # against his printed 5.91, so the verdict would miss the +-0.05 that usable() asks for.
                        mok, mwhy = False, "1 s stamps cannot resolve this clock"
                    rows.append({"logger": logger, "method": method, "stats": mst, "usable": mok, "why_not": mwhy,
                                 "filed": sorted(entry["filed"]), "versions": sorted(entry["versions"]),
                                 "logs": {k: entry["logs"][k] for k in sorted(entry["logs"])}})
        out[channel] = {"title": title, "stats": st, "usable": ok, "why_not": why,
                        "methods": {k: methods[k] for k in sorted(methods)}, "by_logger": rows,
                        "unpaired": unpaired.get(channel, 0), "spread_without": without}
    return out


def board_has(prompts, times, start, end, regex):
    """Did any prompt from start to end show a token matching regex? times holds the sorted stamps of prompts."""
    i = bisect.bisect_left(times, start - 1e-9)
    while i < len(times) and times[i] <= end + 1e-9:
        for tok in prompts[i].board or []:
            if regex.match(tok):
                return True
        i += 1
    return False


# label, channel, the token as boards print it (SMAD or smad, sfrac(2); our recorder's GMCP names).
MODIFIERS = (
    ("Shadowmadness on focus", "focus", re.compile(r"(?i)^(?:smad|shadowmad)")),
    ("Skull fractures on sip", "sip", re.compile(r"(?i)^(?:sfrac|skullfract)")),
)


def build_modifiers(logs):
    """Compare a clock with and without an affliction on the board during that clock. The window is the sample itself:
    its length back from the recovery. Boards are the logger's belief, not game text, so this is a reading, not a proof."""
    out = []
    per_log = []
    for log in logs:
        if log.family is None or log.name in SAME_FIGHT:
            continue
        prompts = [r for r in log if r.kind == "prompt"]
        per_log.append((log, prompts, [r.time for r in prompts], {r.n: r for r in log}, clock_samples(log)[0]))
    for label, channel, regex in MODIFIERS:
        groups = {"with": [], "without": []}
        sources = collections.Counter()
        for log, prompts, times, by_row, samples in per_log:
            for s in samples:
                if s[0] != channel:
                    continue
                value = preferred(s, log.resolution)
                if value is None:
                    continue
                end = by_row[s[3]].time
                hit = board_has(prompts, times, end - value, end, regex)
                groups["with" if hit else "without"].append(value)
                if hit:
                    sources[log.id] += 1
        out.append({"label": label, "channel": channel, "with": stats(groups["with"]),
                    "without": stats(groups["without"]), "sources": {k: sources[k] for k in sorted(sources)}})
    return out


# ---------------------------------------------------------------------------------------------
# STATED AGAINST OBSERVED
# ---------------------------------------------------------------------------------------------

# name, skill and ability in kb/classes/abilities.json (None: the file has no row), the channel, the line. The skill is
# the logger's own class's skill: FITNESS is printed only by Monks here (Elmer, Mystor), and Engage only by Claes, a
# Runewarden. Another class's row can hold the same number today, and it would not follow a later change to this one.
# WRACK is not here. Its line, "wracking his sanguine humour", is also what a TRUEWRACK prints when it reaches one humour
# (Z5cyffxx row 503 printed the 2.6 of a truewrack), so the line cannot tell them apart.
OWN_COSTS = (
    ("FITNESS", "Kaido", "Fitness", "balance", r"^You inhale deeply, purging yourself of your asthmatic condition"),
    ("Truewrack", "Physiology", "Truewrack", "balance", r"^You send ripples throughout .* wracking \S+ \w+ and \w+ humours"),
    ("Reap", "Shadowmancy", "Reap", "balance", r"^You unleash a vicious reaping blow at "),
    ("Shield tattoo", None, None, "equilibrium", r"^You touch the tattoo and a nearly invisible magical shield"),
    ("Pommelstrike", "TwoArts", "Pommelstrike", "balance", r"^As you draw .* from its scabbard, you drive the pommel"),
    ("Homunculus attack", "Physiology", "Arms", "equilibrium", r"^Reaching into the mind of your homunculus, you command it to attack"),
    ("Engage", "Discipline", "Engage", "equilibrium", r"^(?:You move in to engage |Engage:\s+\()"),
    ("Concentrate", None, None, "equilibrium", r"^You begin intense concentration to restore your equilibrium"),
    ("Curseward", None, None, "equilibrium", r"^You bring a curseward into being"),
    ("Colossal fist", None, None, "balance", r"^With a roar you swing a colossal fist"),
)
OWN_COSTS = [(a, b, c, d, re.compile(e)) for a, b, c, d, e in OWN_COSTS]
USED = re.compile(r"^(Balance|Equilibrium) used: *([\d.]+)")
# Mystor's "[Bal Spent: 2.1s]" is this game line, renamed. It holds the same quantised values (w8320bdop, correction 2).
SPENT = re.compile(r"^\[(Bal|Eq) Spent: ([\d.]+)s\]")

WHO = r"(?P<who>[A-Z][a-z]+)"
# name, skill, ability, the family of attacks it belongs to, the lines. An attacker's next attack is any line of the family.
OPPONENT_ATTACKS = (
    ("DSTAB", "Subterfuge", "Doublestab", "serpent", (r"^" + WHO + r" quickly pricks you with (?:his|her) dirk",)),
    ("BITE", "Venom", "Bite", "serpent", (r"^" + WHO + r" sinks (?:his|her) fangs into your body",)),
    ("FLAY", "Subterfuge", "Flay", "serpent",
     (r"^" + WHO + r" flays away your (?:aura of rebounding|shield) defence",
      r"^With fluid grace, " + WHO + r" snaps (?:his|her) wrist")),
    ("Stare", "Evileye", "Asthma", "apostate", (r"^" + WHO + r" stares at you, giving you the evil eye",)),
    ("Reap", "Shadowmancy", "Reap", "depthswalker", (r"^" + WHO + r" lashes out with a swift, reaping blow at you",)),
)
OPPONENT_ATTACKS = [(a, b, c, d, [re.compile(x) for x in e]) for a, b, c, d, e in OPPONENT_ATTACKS]
# These lines end a gap, because the attacker spent the round, but they are not the ability itself.
OTHER_ATTACK_LINES = (
    ("serpent", re.compile(r"^" + WHO + r" misses you with (?:his|her) dirk")),
    ("serpent", re.compile(r"^" + WHO + r"'s attack rebounds off your magical shield")),
)
# The study's own filters (wr95c68dw). Under 0.3 s is one packet's bundle, not a gap, so the next attack is the first
# one past that. 10 s or more is the attacker roaming, not a round ("engaged means attack gaps under 10 s", wer5vpwgh).
BUNDLED = 0.3
DISENGAGED = 10.0
COOLDOWN = re.compile(r"^(\d+(?:\.\d+)?) seconds? of ((?:[a-z]+ )*balance|equilibrium)\.?(?: (?:symbol|channels|unique)[=:].*)?$")


def parse_cooldown(text):
    """'2.80 seconds of balance' -> (2.8, 'balance'). None when the field holds anything else. It never guesses."""
    m = COOLDOWN.match((text or "").strip())
    return (float(m.group(1)), m.group(2)) if m else None


def read_abilities():
    """Returns {(skill, ability): cooldown text}, and a census of the cooldown field."""
    with open(ABILITIES, encoding="utf-8") as fh:
        data = json.load(fh)
    table, unreadable, clean, blank = {}, [], 0, 0
    for skill in sorted(data):
        for row in data[skill]["abilities"]:
            text = (row.get("cooldown") or "").strip()
            table.setdefault((skill, row.get("skill", "")), text)
            if not text:
                blank += 1
            elif parse_cooldown(text):
                clean += 1
            else:
                unreadable.append({"skill": skill, "ability": row.get("skill", ""), "cooldown": text})
    return table, {"rows": clean + blank + len(unreadable), "clean": clean, "blank": blank, "unreadable": unreadable}


def stated_value(table, skill, ability):
    """What abilities.json says, and a plain reason when it says no number."""
    if skill is None:
        return None, "no row in abilities.json"
    text = table.get((skill, ability))
    if text is None:
        return None, "no row %s/%s" % (skill, ability)
    if not text:
        return None, "%s/%s: field is blank" % (skill, ability)
    parsed = parse_cooldown(text)
    if parsed is None:
        return None, "%s/%s: cannot read %r" % (skill, ability, text)
    return parsed, "%s/%s: %s" % (skill, ability, text)


def own_costs(logs):
    """Attribute each printed cost to a curated ability on the same channel in the same packet (the rows between two
    prompts). The cost line can come before or after the ability's line (Z5cyffxx rows 167-172), and a packet with two
    candidates is left out rather than guessed."""
    found = collections.defaultdict(lambda: collections.defaultdict(list))
    sources = collections.defaultdict(lambda: collections.defaultdict(collections.Counter))
    dates = collections.defaultdict(lambda: collections.defaultdict(set))
    ambiguous = collections.Counter()
    for log in logs:
        if log.family is None or log.name in SAME_FIGHT:
            continue
        lines, costs = [], []
        for row in log:
            if row.kind == "prompt":
                for channel, value in costs:
                    names = {name for name, ch in lines if ch == channel}
                    if len(names) == 1:
                        name = next(iter(names))
                        found[name][log.logger].append(value)
                        sources[name][log.logger][log.id] += 1
                        dates[name][log.logger].add(log.date or "-")
                    elif len(names) > 1:
                        ambiguous[channel] += 1
                lines, costs = [], []
            elif row.kind == "line" and row.text:
                m = USED.match(row.text)
                if m:
                    costs.append((m.group(1).lower(), float(m.group(2))))
                    continue
                m = SPENT.match(row.text)
                if m:
                    costs.append(("balance" if m.group(1) == "Bal" else "equilibrium", float(m.group(2))))
                    continue
                for name, _, _, channel, regex in OWN_COSTS:
                    if regex.match(row.text):
                        lines.append((name, channel))
                        break
    return found, sources, dates, ambiguous


def printed_cost_rows(logs):
    """Every printed cost row in the pooled logs, so the page can say how much of them the curated table covers."""
    total = 0
    for log in logs:
        if log.family is None or log.name in SAME_FIGHT:
            continue
        total += sum(1 for row in log if row.kind == "line" and row.text and (USED.match(row.text) or SPENT.match(row.text)))
    return total


def build_own(logs, table):
    found, sources, dates, ambiguous = own_costs(logs)
    rows = []
    for name, skill, ability, channel, _ in OWN_COSTS:
        stated, note = stated_value(table, skill, ability)
        stated_s = stated[0] if stated and stated[1] == channel else None
        if stated and stated[1] != channel:
            note += "; we measure %s" % channel
        by_logger = []
        for logger in sorted(found.get(name, {})):
            values = found[name][logger]
            st = stats(values)
            printed = collections.Counter("%g" % v for v in values)
            by_logger.append({
                "logger": logger, "stats": st,
                "printed": {k: printed[k] for k in sorted(printed, key=float)},
                "ratio": round(st["median"] / stated_s, 3) if stated_s else None,
                "filed": sorted(dates[name][logger]),
                "logs": {k: sources[name][logger][k] for k in sorted(sources[name][logger])},
            })
        rows.append({"ability": name, "channel": channel, "stated": stated_s, "stated_note": note,
                     "by_logger": by_logger})
    return rows, {k: ambiguous[k] for k in sorted(ambiguous)}


def opponent_events(log):
    """Each attacker's attack rows in order: (person, family) -> [(time, ability name or None, row)]."""
    events = collections.defaultdict(list)
    for row in log:
        if row.kind != "line" or row.time is None or not row.text:
            continue
        hit = None
        for name, _, _, family, patterns in OPPONENT_ATTACKS:
            for regex in patterns:
                hit = regex.match(row.text)
                if hit:
                    events[hit.group("who"), family].append((row.time, name, row.n))
                    break
            if hit:
                break
        if hit:
            continue
        for family, regex in OTHER_ATTACK_LINES:
            hit = regex.match(row.text)
            if hit:
                events[hit.group("who"), family].append((row.time, None, row.n))
                break
    return events


def build_opponents(logs, table):
    """The gap from each attack to that person's next attack. This is a distribution and it is never a cost: a clock gives
    the earliest action, never when (foundations.md, item 8). p10 is not a floor: 10% of gaps fall under it by definition."""
    gaps = collections.defaultdict(list)
    people = collections.defaultdict(lambda: collections.defaultdict(list))
    sources = collections.defaultdict(lambda: collections.defaultdict(collections.Counter))
    dropped = collections.defaultdict(collections.Counter)
    for log in logs:
        # 1 s stamps cannot resolve a gap of about 2 s.
        if log.family is None or log.name in SAME_FIGHT or log.resolution > 0.01:
            continue
        for (who, _), events in sorted(opponent_events(log).items()):
            for k, (t, name, _) in enumerate(events):
                # "flays away your shield" and "snaps her wrist" are one FLAY (azbErKcK rows 3628-3629), so a second line
                # of the same ability in one bundle adds no sample.
                if name is None or (k and events[k - 1][1] == name and t - events[k - 1][0] < BUNDLED):
                    continue
                gap = None
                for later in events[k + 1:]:
                    if later[0] - t >= BUNDLED:
                        gap = later[0] - t
                        break
                if gap is None:
                    dropped[name]["no next attack"] += 1
                elif gap >= DISENGAGED:
                    dropped[name]["10 s or more"] += 1
                else:
                    gaps[name].append(gap)
                    people[name][who].append(gap)
                    sources[name][who][log.id] += 1
    rows = []
    for name, skill, ability, _, _ in OPPONENT_ATTACKS:
        stated, note = stated_value(table, skill, ability)
        st = stats(gaps.get(name, []))
        near = sum(1 for g in gaps.get(name, []) if abs(g - st["median"]) <= 0.25) if st["n"] else 0
        by_person = []
        for who in sorted(people.get(name, {})):
            by_person.append({"person": who, "stats": stats(people[name][who]),
                              "logs": {k: sources[name][who][k] for k in sorted(sources[name][who])}})
        rows.append({"ability": name, "stated": stated[0] if stated else None, "stated_note": note, "stats": st,
                     "within_025_pct": round(100.0 * near / st["n"], 1) if st["n"] else None,
                     "ratio_to_stated": round(st["median"] / stated[0], 3) if stated and st["n"] else None,
                     "by_person": by_person,
                     "dropped": {k: dropped[name][k] for k in sorted(dropped[name])}})
    return rows


# ---------------------------------------------------------------------------------------------
# THE SCOREBOARD
# ---------------------------------------------------------------------------------------------

# The round aliases: the names in ataxia_ROUND_TYPES (ataxia/003_Queueing_Related.lua). A test alias such as lvprobe
# does not count, in the same way as tools/fightlog_import.py.
ROUND_ALIAS = r"lv(?:eq|bal|eqbal|class|free|freestand|full)"
SETALIAS = re.compile(r"^setalias (" + ROUND_ALIAS + r") (.*)$", re.I)
ALIAS_NAME = re.compile(r"^" + ROUND_ALIAS + r"$", re.I)
QUEUE_LINE = re.compile(r"^queue (add\S*|insert|prepend) (\S+) (.*)$", re.I)
ALIAS_HOLDS = re.compile(r"^# alias (" + ROUND_ALIAS + r") holds: (.*)$", re.I)
ALIAS_ECHO = re.compile(r'^Alias "(' + ROUND_ALIAS + r')" will now execute: "(.*)"\s*$', re.I)
RUN_LINE = re.compile(r"^\[System\]: Running queued (\w+) command: (.*)$")
ADDED_LINE = re.compile(r"^\[System\]: Added (.*) to your (\w+) queue")
REFUSAL = re.compile(r"^You must regain (?:balance|equilibrium) first")
WAS_ADDED = re.compile(r"^(.*) was added to your \w+ queue")
RECOVERED_EQ = re.compile(r"^You have recovered equilibrium")
RECOVERED_ALL = re.compile(r"^You have recovered balance on all limbs")
RECOVERED_LIMB = re.compile(r"^You have recovered balance on your (legs|left arm|right arm)")
SET_TARGET = re.compile(r"^(?:st|settarget) (\S+)", re.I)
# Any line that names an alias but is not one of its normal replies. "Complaint" is a catch-all on purpose: nobody has
# yet seen the game's wording for a refused setalias, so a pattern for it would be a guess.
ALIAS_WORD = re.compile(r"(?i)\balias(?:es)?\b|\b" + ROUND_ALIAS + r"\b")
ALIAS_NORMAL = re.compile(r'^(?:Alias "\S+" will now execute:|You have cleared alias|\[System\]: (?:Running queued|Added|Queued))')
# What spends a round, for the classes the plan reaches. A class's next log may add words here. mind lock and the rest are
# setup, because Elmer's alias sends "mind lock X" ahead of its combo (3ys7NuHA row 3496).
SPENDER = re.compile(
    r"^(?:combo\b|mind (?!lock\b|blackout\b|sapience\b|print\b|sense\b|cloak\b|cease\b|net\b)\w+"
    r"|kai (?:choke|crush|strike)\b|dsl\b|rsl\b|dispatch\b|arc\b|bisect\b|impale\b|disembowel\b|slice\b|rend\b|sketch\b)",
    re.I)
NOT_SETUP = re.compile(r"^assess\b", re.I)
# The study's active time: an attack was sent in the last 6 s (w8320bdop, Q5).
ACTIVE_WINDOW = 6.0

# The step 3 bars, frozen in the plan. A number is compared with these and never the other way round.
BARS = {
    "refusals": "<= 0.1 per recovery",
    "was_added": "<= 2",
    "setup": "every round",
    "superseded": "<= 5%",
    "rewrites": ">= 5 fire new text",
    "complaints": "none",
    "wrong_target": "none",
}
UNPROVEN_NOTE = ("The run line reads `Running queued <type> command: LVFREE`, the form we expected but have not proved "
                 "(plan, step 3 question 1). Check these rows by eye before trusting the alias numbers.")


def norm(text):
    return " ".join(text.lower().split())


def first_spender(pieces):
    for piece in pieces:
        piece = piece.strip()
        if SPENDER.match(piece):
            return piece
    return None


def all_spenders(text):
    """Every spender in an alias text, in order. srd's text is `combo T a/kai choke T`, and a rewrite can change only the rider."""
    return [piece.strip() for piece in text.split("/") if SPENDER.match(piece.strip())]


def spender_key(pieces):
    return " / ".join(norm(piece) for piece in pieces)


def fired_target(piece):
    """The word in a spender that names the target: 'combo T ...' or 'mind crush T'. None when the piece has none."""
    words = piece.split()
    index = 2 if words and words[0].lower() in ("mind", "kai") else 1
    return words[index].lower() if len(words) > index else None


def stems(text):
    return {w[:5] for w in re.findall(r"[a-z]+", text.lower()) if len(w) >= 3}


def which_text_fired(new_body, old_body, lines):
    """Did the game run the new text or the old one? Compare the words only one of them holds with the first-person rows
    after the run line. "new" and "old" each need the other side absent. Anything else is "unknown", and it is not a
    pass: the alias evidence (n=2) is proof by exactly this kind of reading."""
    new_piece = " ".join(all_spenders(new_body)) or new_body
    old_piece = " ".join(all_spenders(old_body)) or old_body
    only_new, only_old = stems(new_piece) - stems(old_piece), stems(old_piece) - stems(new_piece)
    seen = set()
    for line in lines:
        if re.search(r"(?i)\byou(?:r)?\b", line):
            seen |= stems(line)
    new_hit, old_hit = bool(only_new & seen), bool(only_old & seen)
    if new_hit and not old_hit:
        return "new"
    if old_hit and not new_hit:
        return "old"
    return "unknown"


def split_modes(log):
    """Split one recording at the first sent "setalias lv..." row, or at the first queue line naming a round alias:
    `aconfig rounds alias` can come mid-fight, and the control fight does exactly that. The shim skips setalias when the text
    has not changed, so after a toggle the queue line can be the first sign (003_Queueing_Related.lua). A log whose header
    already says alias is all alias. Returns [(mode, rows)].

    A later `aconfig rounds raw` prints nothing we can see, so it stays in the alias part. The count of raw queue lines
    in that part shows it, and the page says so."""
    if log.rounds == "alias":
        return [("alias", list(log))]
    for i, row in enumerate(log):
        if row.kind != "sent":
            continue
        text = row.text.strip()
        q = QUEUE_LINE.match(text)
        if SETALIAS.match(text) or (q and ALIAS_NAME.match(q.group(3).strip())):
            return [("raw", list(log[:i])), ("alias", list(log[i:]))]
    return [("raw", list(log))]


def score_flush(s, flush, entry, mode):
    """Setup before spender for the run lines of one flush (the run lines before one prompt).

    An alias part judges only its alias rounds. A raw attack there says nothing about alias delivery: the auto-queue can
    hold one across `aconfig rounds alias`, which sends no clear, and a one-piece finisher goes raw because the shim returns
    nil for fewer than 2 pieces. Those rows are listed in a note and do not count toward the bar."""
    for kind, _, row_n, body, later in flush:
        if kind != "alias" or not body:
            continue
        pieces = [norm(p) for p in body.split("/") if p.strip()]
        spender = first_spender(pieces)
        if not spender:
            continue
        s["setup_flushes"] += 1
        at = pieces.index(spender)
        setup = [i for i, p in enumerate(pieces) if not SPENDER.match(p) and not NOT_SETUP.match(p)]
        added = {norm(w) for w in later["added"]}
        if any(i > at for i in setup) or any(pieces[i] in added for i in setup):
            s["setup_rows"].append(row_n)
        else:
            s["setup_ok"] += 1
    raw = [item for item in flush if item[0] == "raw"]
    names = [norm(item[1]) for item in raw]
    attacks = [i for i, name in enumerate(names) if SPENDER.match(name)]
    if attacks and mode == "alias":
        s["raw_attack_rows"].extend(raw[i][2] for i in attacks)
    elif attacks:
        # The study's reading: did the queue entry, the first piece of the press, run ahead of the attack?
        s["setup_flushes"] += 1
        if entry is not None and norm(entry) in names[:attacks[0]]:
            s["setup_ok"] += 1
        else:
            s["setup_rows"].append(raw[attacks[0]][2])


def score_part(rows, mode="raw", carry=None):
    """Count one part of a recording. Returns a plain dict, with row numbers for anything worth checking by eye.

    carry is what an earlier part knew: the target, because a fight does not reset it at `aconfig rounds alias`, and the text
    of a `# alias ... holds:` note, because that row comes right after the header, in the raw part."""
    carry = carry or {}
    s = {"refusals": 0, "recoveries": 0, "was_added": 0, "setup_flushes": 0, "setup_ok": 0, "setup_rows": [],
         "fired": 0, "superseded": 0, "superseded_rows": [], "rewrites_sent": 0, "rewrites_echoed": 0,
         "rewrites_new": 0, "rewrites_old": 0, "rewrites_unknown": 0, "rewrite_rows": [],
         "complaints": 0, "complaint_rows": [], "wrong_target": 0, "target_checked": 0, "wrong_target_rows": [],
         "active_s": 0.0, "active_recoveries": 0, "alias_run_rows": 0, "alias_run_sample": None,
         "raw_presses": 0, "raw_attack_rows": []}
    bodies, sent_bodies, waiting = dict(carry.get("bodies", {})), {}, {}
    # The attacks the newest sends left standing. ADDCLEAR and a plain send replace them. QUEUE ADD appends, so a second
    # attack queued that way supersedes nothing (ours/2026-10-28_073547: sketch jera, then sketch algiz, by design).
    newest, target, entry = set(), carry.get("target"), None
    limbs = set()
    window_end, last_own = None, None
    flush, pending = [], []
    for row in rows:
        own = row.own if row.own is not None else last_own
        last_own = own
        if row.kind == "note":
            m = ALIAS_HOLDS.match(row.text)
            if m:
                bodies[m.group(1).lower()] = m.group(2)
            continue
        if row.kind == "prompt":
            # A prompt ends the flush: score it, and read which text the rewrites fired.
            score_flush(s, flush, entry, mode)
            for new_body, old_body, row_n, later in pending:
                s["rewrites_" + which_text_fired(new_body, old_body, later["lines"])] += 1
                s["rewrite_rows"].append(row_n)
            flush, pending = [], []
            continue
        if row.kind == "sent":
            text = row.text.strip()
            m = SET_TARGET.match(text)
            if m:
                target = m.group(1).lower()
            press = False
            m = SETALIAS.match(text)
            if m:
                s["rewrites_sent"] += 1
                sent_bodies[m.group(1).lower()] = m.group(2)
                spenders = all_spenders(m.group(2))
                if spenders:
                    newest = {spender_key(spenders)}
                    press = True
            else:
                q = QUEUE_LINE.match(text)
                payload = q.group(3).strip() if q else text
                if q and ALIAS_NAME.match(payload):
                    press = True
                elif q:
                    s["raw_presses"] += 1
                if SPENDER.match(payload):
                    if q and not q.group(1).lower().startswith("addclear"):
                        newest.add(norm(payload))
                    else:
                        newest = {norm(payload)}
                    press = True
            if press and own is not None:
                if window_end is None or own >= window_end:
                    s["active_s"] += ACTIVE_WINDOW
                else:
                    s["active_s"] += own + ACTIVE_WINDOW - window_end
                window_end = own + ACTIVE_WINDOW
            continue
        if row.kind != "line":
            continue
        text = row.text
        for item in flush:
            item[4]["lines"].append(text)
        recovered = False
        if REFUSAL.match(text):
            s["refusals"] += 1
        elif RECOVERED_EQ.match(text):
            recovered = True
        elif RECOVERED_ALL.match(text):
            recovered, limbs = True, set()
        else:
            # A Monk combo prints three limb lines and no "all limbs". They are one recovery: that is how the study's
            # 22 refusals per recovery comes out of 1,466 refusals and 66 recoveries.
            m = RECOVERED_LIMB.match(text)
            if m:
                if not limbs or m.group(1) in limbs:
                    recovered, limbs = True, set()
                limbs.add(m.group(1))
        if recovered:
            s["recoveries"] += 1
            if window_end is not None and own is not None and own <= window_end:
                s["active_recoveries"] += 1
        m = WAS_ADDED.match(text)
        if m:
            s["was_added"] += 1
            for item in flush:
                item[4]["added"].append(m.group(1))
            continue
        if ALIAS_WORD.search(text) and not ALIAS_NORMAL.match(text) and not text.startswith("("):
            s["complaints"] += 1
            s["complaint_rows"].append(row.n)
        m = ALIAS_ECHO.match(text)
        if m:
            s["rewrites_echoed"] += 1
            bodies[m.group(1).lower()] = m.group(2)
            continue
        m = ADDED_LINE.match(text)
        if m:
            name = m.group(1).strip()
            if ALIAS_NAME.match(name):
                waiting.setdefault(name.lower(), bodies.get(name.lower()) or sent_bodies.get(name.lower()))
            else:
                entry = name
            continue
        m = RUN_LINE.match(text)
        if not m:
            continue
        cmd = m.group(2).strip()
        later = {"lines": [], "added": []}
        if ALIAS_NAME.match(cmd):
            name = cmd.lower()
            # What the game has echoed is what it holds. With no echo at all, the text we sent is the best we have.
            body = bodies.get(name) or sent_bodies.get(name)
            s["alias_run_rows"] += 1
            s["alias_run_sample"] = s["alias_run_sample"] or text
            flush.append(("alias", cmd, row.n, body, later))
            first = waiting.pop(name, None)
            if body and first and norm(body) != norm(first):
                pending.append((body, first, row.n, later))
            spenders = all_spenders(body) if body else []
        else:
            flush.append(("raw", cmd, row.n, None, later))
            spenders = [cmd] if SPENDER.match(cmd) else []
        if spenders:
            s["fired"] += 1
            if spender_key(spenders) not in newest:
                s["superseded"] += 1
                s["superseded_rows"].append(row.n)
            named = [t for t in (fired_target(piece) for piece in spenders) if t]
            if target and named:
                s["target_checked"] += 1
                if any(t != target for t in named):
                    s["wrong_target"] += 1
                    s["wrong_target_rows"].append(row.n)
    score_flush(s, flush, entry, mode)
    for new_body, old_body, row_n, later in pending:
        s["rewrites_" + which_text_fired(new_body, old_body, later["lines"])] += 1
        s["rewrite_rows"].append(row_n)
    s["carry"] = {"target": target, "bodies": bodies}
    return s


def bar_verdicts(s):
    """Each bar: True, False, or None when the part holds nothing to measure."""
    per = s["refusals"] / float(s["recoveries"]) if s["recoveries"] else None
    pct = 100.0 * s["superseded"] / s["fired"] if s["fired"] else None
    return {
        "refusals": None if per is None else per <= 0.1,
        "was_added": s["was_added"] <= 2,
        "setup": None if not s["setup_flushes"] else s["setup_ok"] == s["setup_flushes"],
        "superseded": None if pct is None else pct <= 5.0,
        "rewrites": s["rewrites_new"] >= 5,
        "complaints": s["complaints"] == 0,
        # With no attack compared against a known target, nothing was measured, and "none" would be a false pass.
        "wrong_target": None if not s["target_checked"] else s["wrong_target"] == 0,
    }


def score_log(log):
    """Score every part of a recording. Returns a list of dicts."""
    parts = []
    carry = None
    for mode, rows in split_modes(log):
        timed = [r.own for r in rows if r.own is not None]
        s = score_part(rows, mode, carry)
        carry = s.pop("carry")
        s.update({"log": log.name, "id": log.id, "mode": mode, "class": log.our_class, "version": log.version,
                  "date": log.date, "first_row": rows[0].n if rows else None, "last_row": rows[-1].n if rows else None,
                  "seconds": round(timed[-1] - timed[0], 1) if timed else 0.0,
                  "active_s": round(s["active_s"], 1), "bars": bar_verdicts(s)})
        parts.append(s)
    return parts


def mark(verdict, mode):
    # Only an alias part is judged. A raw part is the baseline the bars were set against.
    if mode != "alias" or verdict is None:
        return ""
    return " PASS" if verdict else " FAIL"


def part_measures(p):
    """The measures of one part, as (measure, value, bar key)."""
    per = "%.2f" % (p["refusals"] / float(p["recoveries"])) if p["recoveries"] else "no recovery"
    pct = "%.1f%%" % (100.0 * p["superseded"] / p["fired"]) if p["fired"] else "no attack ran"
    rpm = "%.1f" % (p["active_recoveries"] * 60.0 / p["active_s"]) if p["active_s"] else "no attack sent"
    return [
        ("Refusals per recovery", "%s (%d / %d)" % (per, p["refusals"], p["recoveries"]), "refusals"),
        ("`was added to your` rows", "%d" % p["was_added"], "was_added"),
        ("Setup before spender, per flush", "%d of %d" % (p["setup_ok"], p["setup_flushes"]), "setup"),
        ("Superseded attacks that ran", "%s (%d / %d)" % (pct, p["superseded"], p["fired"]), "superseded"),
        ("Echoed rewrites whose new text fired", "%d new, %d old, %d not shown (%d sent, %d echoed)" % (
            p["rewrites_new"], p["rewrites_old"], p["rewrites_unknown"], p["rewrites_sent"], p["rewrites_echoed"]),
         "rewrites"),
        ("Alias complaints", "%d" % p["complaints"], "complaints"),
        ("Attacks naming a target other than the last set", ("%d of %d checked" % (p["wrong_target"], p["target_checked"]))
         if p["target_checked"] else "not measured: no `st` or `settarget` known when an attack ran", "wrong_target"),
        ("Rounds per minute in attack bursts", "%s (%d recoveries, %.1f s active)" % (
            rpm, p["active_recoveries"], p["active_s"]), None),
    ]


def part_notes(p):
    notes = []
    if p["mode"] == "alias":
        if p["alias_run_rows"]:
            notes.append(UNPROVEN_NOTE + " %d rows here; the first: `%s`." % (p["alias_run_rows"], p["alias_run_sample"]))
        else:
            notes.append("No run line names a round alias, so the fire-time measures saw no alias round. Find the real "
                         "wording in this log's `[System]: Running queued` rows before reading them.")
        if p["raw_presses"]:
            notes.append("%d queue lines in this part did not name an alias. The shim passes some through on purpose, and "
                         "`aconfig rounds raw` looks the same." % p["raw_presses"])
        if p["raw_attack_rows"]:
            notes.append("Raw attack rows in this alias part, which do not count toward the setup bar: %s." % (
                ", ".join(str(n) for n in p["raw_attack_rows"][:30])))
    for key, title in (("complaint_rows", "Complaint rows"), ("setup_rows", "Setup rows"), ("superseded_rows", "Superseded rows"),
                       ("wrong_target_rows", "Wrong target rows"), ("rewrite_rows", "Rewrite rows")):
        if p[key]:
            notes.append("%s: %s." % (title, ", ".join(str(n) for n in p[key][:30])))
    return notes


def score_text(path):
    """The scoreboard of one recording, for the terminal. fightlog_import.py --score prints this."""
    log = parse(path)
    if log.family != "ours":
        return "%s is not one of our recordings, so it has no round delivery to score." % log.name
    out = []
    for p in score_log(log):
        out.append("\n%s | %s rounds | %s | v%s | rows %s-%s | %.1f s" % (
            p["log"], p["mode"], p["class"], p["version"], p["first_row"], p["last_row"], p["seconds"]))
        for measure, value, key in part_measures(p):
            bar = BARS.get(key, "")
            extra = "  [bar: %s%s]" % (bar, mark(p["bars"].get(key), p["mode"])) if bar else ""
            out.append("  %-48s %s%s" % (measure, value, extra))
        for note in part_notes(p):
            out.append("  NOTE: " + note)
    return "\n".join(out)


# ---------------------------------------------------------------------------------------------
# THE PAGES
# ---------------------------------------------------------------------------------------------


def fmt(value):
    return "-" if value is None else "%.2f" % value


def stat_cells(st):
    if not st.get("n"):
        return ["0", "-", "-", "-", "-", "-"]
    return [str(st["n"]), fmt(st["min"]), fmt(st["p10"]), fmt(st["median"]), fmt(st["p90"]), fmt(st["max"])]


def table(header, rows):
    out = ["| " + " | ".join(header) + " |", "|" + "---|" * len(header)]
    out.extend("| " + " | ".join(str(c).replace("|", "\\|") for c in row) + " |" for row in rows)
    return out


def method_text(methods):
    return ", ".join("%s %d" % (k, methods[k]) for k in sorted(methods)) or "-"


def family_totals(logs):
    totals = {}
    for log in logs:
        if log.family is None:
            continue
        t = totals.setdefault(log.family, {"logs": 0, "prompts": 0, "wrapped": 0, "fixed": 0, "held": 0})
        t["logs"] += 1
        t["prompts"] += log.prompts
        t["wrapped"] += log.wrapped
        t["fixed"] += log.fixed_stamps
        t["held"] += log.held_stamps
    return {k: totals[k] for k in sorted(totals)}


def build_data(logs):
    table_, census = read_abilities()
    own, ambiguous = build_own(logs, table_)
    return {
        "generated_by": "tools/kb_timing.py",
        "latest_filed": max(log.date for log in logs if log.date),
        "families": family_totals(logs),
        "logs": [{"id": log.id, "file": log.name, "family": log.family, "logger": log.logger, "filed": log.date,
                  "version": log.version, "prompts": log.prompts, "wrapped": log.wrapped,
                  "fixed_stamps": log.fixed_stamps, "held_stamps": log.held_stamps,
                  "unstamped_prompts": log.unstamped, "in_pools": bool(log.family) and log.name not in SAME_FIGHT}
                 for log in logs],
        "clocks": build_clocks(logs),
        "modifiers": build_modifiers(logs),
        "stated": {"own": own, "own_ambiguous_packets": ambiguous, "opponents": build_opponents(logs, table_),
                   "own_printed_rows": printed_cost_rows(logs), "cooldown_field": census},
    }


def logger_widths(channel_data, logger):
    """A logger's printed and own-stamp widths on one channel, as text, or "" when they have only one of the two."""
    width = {r["method"]: r["stats"]["spread"] for r in channel_data["by_logger"] if r["logger"] == logger}
    if "printed" in width and "line" in width:
        return " (their printed timer %.3f, their own stamps %.3f)" % (width["printed"], width["line"])
    return ""


def pool_width_text(data):
    """One generated sentence per pool that fails on width. The numbers come from the samples, so this cannot go stale."""
    parts = []
    for channel, _ in CHANNEL_NAMES:
        c = data["clocks"][channel]
        # These two are not one clock: an unsorted salve mixes short and restoration, and a later smoke shortens a rebound.
        if c["usable"] or c["stats"].get("n", 0) < 10 or channel in ("salve_unknown", "rebounding"):
            continue
        passing = [(who, w) for who, w in sorted(c["spread_without"].items()) if w is not None and w <= 0.2]
        if passing:
            detail = "; ".join("without %s %.3f%s" % (who, w, logger_widths(c, who)) for who, w in passing)
        else:
            detail = "no single logger's removal passes it"
        parts.append("%s %.3f: %s." % (c["title"], c["stats"]["spread"], detail))
    if not parts:
        return ""
    return (" ".join(parts) + " A printed width far above the same logger's stamps, on the same recoveries, points to that "
            "logger's timer and not to the players disagreeing on the clock.")


def render_clocks(data):
    out = [
        "---",
        "topic: clocks",
        "confidence: MEASURED (counted from log rows; boards are the loggers' beliefs)",
        "generated: true  # GENERATED by `python tools/kb_timing.py`. Do not hand-edit. CI runs --check.",
        "sources:",
        "  - kb/raw/logs/",
        "  - kb/raw/logs/ours/",
        "  - kb/classes/abilities.json",
        "code:",
        "  - tools/kb_timing.py",
        "latest_filed: %s" % data["latest_filed"],
        "---",
        "",
        "# Clocks: stated against observed",
        "",
        "**GENERATED by `python tools/kb_timing.py`. Do not hand-edit.** `clocks.json` is the machine copy. "
        "The model that uses these numbers is [foundations.md](foundations.md). The control-fight score is in "
        "[scoreboard.md](scoreboard.md).",
        "",
        "**One stamp rule.** A row's time is the next prompt's stamp. Treat a margin under 0.5 s as unresolved, because "
        "lag bursts bundle rows.",
        "",
        "**Method per sample.** `printed` is a number the logger's client printed: `Tree (13.916)`, `[Eat Recov: 1.59s]`. "
        "`line` is the time from the most recent start row to the recovery row, on stamps of 0.01 s or better. `line_1s` "
        "is the same on 1 s stamps, so it is shown, never pooled and never usable. A pool takes one value per recovery line: printed if "
        "there is one, otherwise line. The tables by logger show line beside printed as a cross-check, so they count "
        "some recoveries twice.",
        "",
        "**Usable** means n >= 10 and p90-p10 <= 0.2. This tool does not relax that rule. Where a pool fails on width, this "
        "says what taking one logger out does. " + pool_width_text(data),
        "",
        "**Staleness.** The Filed and Version columns show where each sample came from. Filed is the date in the file name. "
        "For the 2026-11-01 batch that is the day the export was saved (`tools/kb_log_import.py` reads the file's modified "
        "time), and the fight came on or before it. The logs print no date. Three Claes logs filed 2026-11-01 overlap on the "
        "wall clock with no shared row (`WO7tC3kL` 18:36-18:43, `Vr.NkCGD` 18:41-18:42, `4c_SeyaA` 18:42-18:45), so they are "
        "different days. Only our recorder's header gives a fight's date and a version. So any client log may predate the "
        "2026-10-23 class leads, and a log filed before that date certainly does.",
        "",
        "## Clocks",
        "",
    ]
    rows = []
    for channel, _ in CHANNEL_NAMES:
        c = data["clocks"][channel]
        st = c["stats"]
        rows.append([c["title"]] + stat_cells(st) + [fmt(st.get("spread")), "yes" if c["usable"] else "no",
                                                     c["why_not"] or "-", method_text(c["methods"])])
    out += table(["Channel", "n", "min", "p10", "median", "p90", "max", "p90-p10", "Usable", "Why not", "Method, samples"], rows)
    out += ["", "Moss, potash and quartz are out of eat. Pear and calcite are on the smoke clock. A salve is sorted by the "
            "`[Curing]` row before it, by the skin, or by a following `stronger and healthier` limb line, and never by "
            "its own length. A salve with none of those stays in its own row. Rebounding reads the most recent third-person "
            "smoke. No line names the pipe, so a later smoke shortens a sample, and its width is not the clock's.", ""]
    missed = {c["title"]: c["unpaired"] for c in data["clocks"].values() if c["unpaired"]}
    if missed:
        out += ["Recovery lines with no printed value and no start row, so no sample: " +
                ", ".join("%s %d" % (k, missed[k]) for k in sorted(missed)) + ".", ""]
    out += ["## By logger", ""]
    for channel, _ in CHANNEL_NAMES:
        c = data["clocks"][channel]
        if not c["by_logger"]:
            out += ["### %s" % c["title"], "", "No samples.", ""]
            continue
        rows = []
        for r in c["by_logger"]:
            rows.append([r["logger"], r["method"]] + stat_cells(r["stats"]) + ["yes" if r["usable"] else "no",
                        ", ".join(r["filed"]), ", ".join(r["versions"]),
                        ", ".join("%s %d" % (k, r["logs"][k]) for k in r["logs"])])
        out += ["### %s" % c["title"], ""]
        out += table(["Logger", "Method", "n", "min", "p10", "median", "p90", "max", "Usable", "Filed", "Version",
                      "Logs (recoveries)"], rows)
        out += [""]
    out += ["## Modifiers", "",
            "A sample counts as \"with\" when any prompt during that clock shows the affliction on the logger's board.", ""]
    rows = []
    for m in data["modifiers"]:
        rows.append([m["label"], "with"] + stat_cells(m["with"]) + [", ".join("%s %d" % (k, m["sources"][k]) for k in m["sources"]) or "-"])
        rows.append([m["label"], "without"] + stat_cells(m["without"]) + ["all other samples"])
    out += table(["Modifier", "Board", "n", "min", "p10", "median", "p90", "max", "Logs"], rows)
    out += ["", "## Stated against observed", "",
            "**Own costs** are the game's own `Balance used` and `Equilibrium used` lines (Mystor's `[Bal Spent]` is the "
            "same line renamed). The ratio is the printed median over the value in `kb/classes/abilities.json`. A packet "
            "with two candidate abilities on one channel is left out: %s." % (
                ", ".join("%s %d" % (k, v) for k, v in data["stated"]["own_ambiguous_packets"].items()) or "none"),
            "",
            "%d of %d printed cost rows match a curated ability. The rest, including the Shikudo kick combos, are not in this "
            "table." % (sum(r["stats"]["n"] for a in data["stated"]["own"] for r in a["by_logger"]),
                        data["stated"]["own_printed_rows"]),
            ""]
    rows = []
    for a in data["stated"]["own"]:
        if not a["by_logger"]:
            rows.append([a["ability"], a["channel"], fmt(a["stated"]), a["stated_note"], "-", 0, "-", "-", "-", "-", "-"])
        for r in a["by_logger"]:
            printed = ", ".join("%s x%d" % (k, r["printed"][k]) for k in r["printed"])
            rows.append([a["ability"], a["channel"], fmt(a["stated"]), a["stated_note"], r["logger"], r["stats"]["n"], printed,
                         fmt(r["stats"]["median"]), fmt(r["ratio"]), ", ".join(r["filed"]),
                         ", ".join("%s %d" % (k, r["logs"][k]) for k in r["logs"])])
    out += table(["Ability", "Channel", "Stated", "Field", "Logger", "n", "Printed", "Median", "Ratio", "Filed", "Logs"], rows)
    out += ["", "**Opponents** are a gap to the same person's next attack. It is never a cost: a clock gives the earliest "
            "action, not when. **p10 is not a floor.** By definition about 10% of gaps come sooner, and min is a real gap and "
            "not a straggler: the prompts on both sides of `azbErKcK` rows 315 and 350 put that DSTAB gap at 1.539-1.557 s. "
            "Gaps under 0.3 s are one packet's bundle, so the next attack is the first past that. Gaps of 10 s or more are the "
            "attacker roaming. Only stamps of 0.01 s or better count.", ""]
    rows = []
    for a in data["stated"]["opponents"]:
        st = a["stats"]
        rows.append([a["ability"], fmt(a["stated"]), a["stated_note"], "all"] + stat_cells(st) + [
            "-" if a["within_025_pct"] is None else "%.0f%%" % a["within_025_pct"], fmt(a["ratio_to_stated"]),
            ", ".join("%s %d" % (k, a["dropped"][k]) for k in a["dropped"]) or "-"])
        for p in a["by_person"]:
            rows.append([a["ability"], fmt(a["stated"]), "", p["person"]] + stat_cells(p["stats"]) + [
                "-", "-", ", ".join("%s %d" % (k, p["logs"][k]) for k in p["logs"])])
    out += table(["Ability", "Stated", "Field", "Person", "n", "min", "p10", "median", "p90", "max",
                  "Within 0.25 of median", "Median / stated", "Dropped, or logs"], rows)
    census = data["stated"]["cooldown_field"]
    shapes = collections.Counter(re.sub(r"\d+(?:\.\d+)?", "N", u["cooldown"]) for u in census["unreadable"])
    out += ["", "### The `cooldown` field", "",
            "`kb/classes/abilities.json` has %d rows: %d read as one number on one balance, %d blank, %d it cannot read. "
            "They are not guessed. `clocks.json` lists every one. Their shapes:" % (
                census["rows"], census["clean"], census["blank"], len(census["unreadable"])), ""]
    out += table(["Shape", "Rows"], [[k, shapes[k]] for k in sorted(shapes, key=lambda x: (-shapes[x], x))])
    out += ["", "## Logs read", ""]
    out += table(["Family", "Logs", "Prompts", "Wrapped", ".00 stamps fixed", "Stamps held"],
                 [[k, v["logs"], v["prompts"], v["wrapped"], v["fixed"], v["held"]] for k, v in data["families"].items()])
    out += ["", "A wrapped prompt ran onto a second row. Mystor's stamp row is not a wrap. `o6UKnyyy` has prompts with no time "
            "in them, so it is skipped.", ""]
    out += table(["Id", "File", "Family", "Logger", "Filed", "Version", "Prompts", "Wrapped", ".00 fixed", "Note"],
                 [[r["id"], r["file"], r["family"] or "none", r["logger"] or "-", r["filed"] or "-", r["version"] or "-",
                   r["prompts"], r["wrapped"], r["fixed_stamps"],
                   ("skipped: %d prompts with no time in them" % r["unstamped_prompts"]) if not r["family"]
                   else ("" if r["in_pools"] else "same fight as ours/2026-10-27_112717, out of the pools")]
                  for r in data["logs"]])
    out += [""]
    return "\n".join(out)


def render_scoreboard(logs):
    parts = []
    for log in logs:
        if log.family == "ours":
            parts.extend(score_log(log))
    out = [
        "---",
        "topic: scoreboard",
        "confidence: MEASURED (counted from our recorder's rows)",
        "generated: true  # GENERATED by `python tools/kb_timing.py`. Do not hand-edit. CI runs --check.",
        "sources:",
        "  - kb/raw/logs/ours/",
        "code:",
        "  - tools/kb_timing.py",
        "  - src_new/scripts/levi_ataxia/levi/ataxia/ataxia/003_Queueing_Related.lua",
        "---",
        "",
        "# Round delivery scoreboard",
        "",
        "**GENERATED by `python tools/kb_timing.py`. Do not hand-edit.** This scores our own recordings on the step 3 "
        "bars of the timing plan. After a fight: `python tools/fightlog_import.py --score`.",
        "",
        "A log splits at its first sent `setalias lv...` row, because `aconfig rounds alias` can come mid-fight. Only an "
        "alias part is judged against the bars. A raw part is the baseline.",
        "",
        "**Why these counts.** Mudlet splits `;` on our side, so a raw chain queues only its first command. "
        "See [balance-and-queueing.md](balance-and-queueing.md).",
        "",
        "**Rows on this page are 0-based.** Add 1 for `grep -n`.",
        "",
    ]
    out += table(["Log", "Mode", "Class", "Version", "Seconds", "Refusals / recovery (bar <= 0.1)", "`was added` (<= 2)",
                  "Setup before spender (every round)", "Superseded (<= 5%)", "Rewrites, new text (>= 5)", "Complaints (none)",
                  "Wrong target (none)", "Rounds / min"], [
        [p["id"], p["mode"], p["class"], p["version"], "%.1f" % p["seconds"],
         ("%.2f" % (p["refusals"] / float(p["recoveries"]))) if p["recoveries"] else "-",
         p["was_added"], "%d of %d" % (p["setup_ok"], p["setup_flushes"]),
         ("%.1f%%" % (100.0 * p["superseded"] / p["fired"])) if p["fired"] else "-",
         p["rewrites_new"], p["complaints"], p["wrong_target"] if p["target_checked"] else "-",
         ("%.1f" % (p["active_recoveries"] * 60.0 / p["active_s"])) if p["active_s"] else "-"]
        for p in parts])
    out += ["", "## How each number is counted", "",
            "- **Refusals per recovery.** `You must regain balance|equilibrium first` rows, over recoveries. A Monk combo "
            "prints three limb lines and no `all limbs`, and those count as one recovery.",
            "- **Setup before spender.** A flush is the run lines before one prompt. On a raw round: did the queue entry, "
            "the first piece of the press, run ahead of the attack? On an alias round: is every setup piece of the text "
            "ahead of the spender, with none of them auto-queued in that flush? `assess` is not setup. An alias part judges "
            "only its alias rounds. A raw attack there (held by the auto-queue across the toggle, or a one-piece finisher, "
            "which the shim leaves raw) is listed in a note and does not count toward the bar.",
            "- **Superseded.** A `Running queued` attack that differs from the newest attack we had sent. On the alias path "
            "the fired text is the last one the game echoed, so a rewrite that lost the race counts here. All the spenders "
            "in the text are compared, so a rewrite of only the rider in `srd` counts too.",
            "- **Echoed rewrites whose new text fired.** The alias text changed while an entry waited, and the run line "
            "fired. The words only the new text holds, or only the old, are looked for in the first-person rows of that "
            "flush. `not shown` means those rows could not tell the two apart, and it is not a pass.",
            "- **Alias complaints.** Any line that names an alias or a round alias and is not one of its normal replies. "
            "No log shows the wording of a refused `setalias`, so this is a catch-all.",
            "- **Wrong target.** A fired attack that names someone other than the last `st` or `settarget` we sent. The "
            "target carries from the raw part into the alias part. An attack with no target known is not compared, and a part "
            "with none compared prints `-` and no verdict.",
            "- **Rounds per minute.** Recoveries while an attack was sent in the last 6 s, over that active time.",
            "", "## Each part", ""]
    for p in parts:
        out += ["### %s, %s rounds" % (p["log"], p["mode"]), "",
                "%s, v%s, %s. Rows %s-%s, %.1f s." % (p["class"], p["version"], p["date"], p["first_row"], p["last_row"], p["seconds"]), ""]
        rows = []
        for measure, value, key in part_measures(p):
            rows.append([measure, value, BARS.get(key, "-"), mark(p["bars"].get(key), p["mode"]).strip() or "-"])
        out += table(["Measure", "Value", "Bar", "Verdict"], rows)
        notes = part_notes(p)
        if notes:
            out += [""] + ["- " + n for n in notes]
        out += [""]
    return "\n".join(out)


def generate():
    """The three files, as {path: text}. Nothing here reads the clock or the machine."""
    logs = load_all()
    data = build_data(logs)
    return {
        OUT_MD: render_clocks(data),
        OUT_JSON: json.dumps(data, indent=1, sort_keys=True, ensure_ascii=False) + "\n",
        OUT_SCORE: render_scoreboard(logs),
    }


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
        print("Run: python tools/kb_timing.py")
    return bad


def print_counts(logs):
    totals = family_totals(logs)
    for family, t in totals.items():
        print("%-12s logs %2d  prompts %6d  wrapped %5d  .00 fixed %2d  held %d" % (
            family, t["logs"], t["prompts"], t["wrapped"], t["fixed"], t["held"]))
    print("%-12s logs %2d  prompts %6d  wrapped %5d" % (
        "all", sum(t["logs"] for t in totals.values()), sum(t["prompts"] for t in totals.values()),
        sum(t["wrapped"] for t in totals.values())))
    for log in logs:
        if log.family is None:
            print("skipped: %s (%d prompts with no time in them)" % (log.name, log.unstamped))


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--check", action="store_true", help="regenerate in memory, diff, exit 1 on any difference")
    ap.add_argument("--counts", action="store_true", help="print prompts and wrapped prompts per family")
    ap.add_argument("--score", nargs="+", metavar="LOG", help="print the scoreboard of these recordings")
    args = ap.parse_args()
    if args.score:
        for path in args.score:
            print(score_text(path))
        return
    if args.counts:
        print_counts(load_all())
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
