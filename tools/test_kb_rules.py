"""Tests for tools/kb_rules.py: the rules of the whole-fight engine, as kb/sim/rules.json holds them.

    python -B tools/test_kb_rules.py
"""
import json
import os
import re
import sys
import unittest

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kb_rules as R  # noqa: E402
import kb_replay as rp  # noqa: E402
import kb_events as ke  # noqa: E402
import kb_timing as kb  # noqa: E402

DATA = None


def data():
    global DATA
    if DATA is None:
        DATA = R.build()
    return DATA


def rule(key):
    return data()["rules"][key]


class Table(unittest.TestCase):
    def test_foundations_citations_point_at_their_rows(self):
        # Review R4-docs-2: a row added to foundations.md moved three citations, and --check does not hash that file.
        # Each line cited by a rule or by tools/theorycraft.py must hold the row it names.
        with open(os.path.join(HERE, "..", "kb", "mechanics", "foundations.md"), encoding="utf-8") as fh:
            lines = fh.read().splitlines()
        want = {"ssc.phi": ["aurum"], "attack.gap.own.sd": ["time to recovery"],
                "attack.give": ["Hypochondria chain", "Fratricide relapse", "Anorexia after SNAP"],
                "timed.fratricide": ["Fratricide relapse"], "defence.rebounding.delay": ["Rebounding after the smoke"]}
        cites = [(key, r["source"]) for key, r in data()["rules"].items() if "foundations.md:" in r.get("source", "")]
        with open(os.path.join(HERE, "theorycraft.py"), encoding="utf-8") as fh:
            cites.append(("theorycraft.py TREE", fh.read()))
        want["theorycraft.py TREE"] = ["Locks land while", "Winners strike just after"]
        for key, text in cites:
            self.assertIn(key, want, "a new foundations.md citation: add its row text here")
            for m in re.finditer(r"foundations\.md:(\d+)(?:-(\d+))?", text):
                lo, hi = int(m.group(1)), int(m.group(2) or m.group(1))
                rows = "\n".join(lines[lo - 1:hi])
                for phrase in want[key]:
                    self.assertIn(phrase, rows, "%s cites %s" % (key, m.group(0)))

    def test_files_match(self):
        with open(R.OUT_JSON, encoding="utf-8") as fh:
            self.assertEqual(R.dump(data()), fh.read().replace("\r\n", "\n"))

    def test_no_problems(self):
        self.assertEqual(R.problems(data()), [])

    def test_problems_finds_a_soft_rule_with_no_alternatives(self):
        bad = {"rules": {"x": {"tag": "ASSUMED", "source": "here", "value": 1}, "y": {"tag": "GUESS", "source": "here"},
                         "z": {"tag": "READ", "value": 2}}}
        found = R.problems(bad)
        self.assertEqual(len(found), 3, found)

    def test_problems_finds_a_measured_rule_with_no_n(self):
        bad = {"rules": {"m": {"tag": "MEASURED", "source": "here", "value": 1},
                         "u": {"tag": "MEASURED", "source": "here", "value": 1, "n": 3, "usable": False}}}
        self.assertEqual(len(R.problems(bad)), 2)

    def test_every_rule_has_a_row(self):
        # Review RUL-3: 13 rules had no row on rules.md, which says every rule is there.
        with open(R.OUT_MD, encoding="utf-8") as fh:
            md = fh.read()
        missing = []
        for k in data()["rules"]:
            if k.startswith("cure.") and k != "cure.options_join":
                ok = re.search(r"^\| %s \|" % re.escape(k[5:]), md, re.M)
            elif k.startswith("venom."):
                ok = re.search(r"^\| %s \|" % re.escape(k[6:]), md, re.M)
            elif k.startswith("classcure.blocker."):
                ok = re.search(r"^\| %s \|" % re.escape(k.split(".", 2)[2]), md, re.M)
            elif k.startswith("prio.") and "cure." + k[5:] in data()["rules"]:
                ok = True
            else:
                ok = ("`%s`" % k) in md
            if not ok:
                missing.append(k)
        self.assertEqual(missing, [])

    def test_options_join_and_priorities_have_their_rows(self):
        # Review RUL-3 residual: the test above passed the options_join row and a prio.* with a cure partner unchecked.
        with open(R.OUT_MD, encoding="utf-8") as fh:
            md = fh.read()
        self.assertRegex(md, r"(?m)^\| `cure\.options_join` \| or \|")
        rows = {}
        for line in md.splitlines():
            cells = [c.strip() for c in re.split(r"(?<!\\)\|", line)[1:-1]]
            if len(cells) == 5 and cells[0] not in ("Affliction", "---"):
                rows[cells[0]] = cells
        checked = 0
        for k, r in data()["rules"].items():
            if k.startswith("prio.") and "cure." + k[5:] in data()["rules"]:
                self.assertIn(k[5:], rows, k)
                self.assertEqual(rows[k[5:]][4], str(r["value"]), k)
                checked += 1
        self.assertGreater(checked, 50)

    def test_every_table_row_has_its_header_cells(self):
        # Review RUL-4: an unescaped '|' in a cell (brokenleftleg|brokenrightleg) made a row of 7 cells under 6.
        with open(R.OUT_MD, encoding="utf-8") as fh:
            lines = fh.read().splitlines()
        width, bad = None, []
        for n, line in enumerate(lines, 1):
            if not line.startswith("|"):
                width = None
                continue
            cells = len(re.findall(r"(?<!\\)\|", line))
            if width is None:
                width = cells
            elif cells != width:
                bad.append(n)
        self.assertEqual(bad, [])

    def test_freeze_hash_is_printed(self):
        self.assertEqual(data()["freeze_sha256"], R.sha(R.GATES))
        with open(R.OUT_MD, encoding="utf-8") as fh:
            self.assertIn(data()["freeze_sha256"], fh.read())


class Measured(unittest.TestCase):
    def test_clocks_within_tolerance(self):
        # gates_whole.json stage1: a MEASURED value is within 0.01 s of clocks.json.
        with open(R.GATES, encoding="utf-8") as fh:
            tol = json.load(fh)["stage1"]["measured_rule_tolerance_s"]
        with open(R.CLOCKS, encoding="utf-8") as fh:
            clocks = json.load(fh)
        checked = 0
        for name, c in clocks["clocks"].items():
            key = "clock." + name
            if key not in data()["rules"]:
                continue
            for field in ("median", "p10", "p90"):
                self.assertLessEqual(abs(rule(key)["value"][field] - c["stats"][field]), tol, (key, field))
            checked += 1
        self.assertGreaterEqual(checked, 10)

    def test_unusable_clocks_are_ranges(self):
        # The pooled eat clock is not usable, so it is swept; FITNESS (n=5) is swept min..max.
        self.assertFalse(rule("clock.eat")["usable"])
        self.assertEqual(len(rule("clock.eat")["alt"]), 3)
        fit = rule("clock.fitness")
        self.assertFalse(fit["usable"])
        self.assertEqual(fit["alt"][0], fit["value"]["min"])
        self.assertEqual(fit["alt"][-1], fit["value"]["max"])

    def test_eat_clock_per_logger(self):
        for who in ("Claes", "Elmer", "Nikita"):
            eat = rule("clock.eat." + who)
            self.assertEqual(eat["tag"], "MEASURED")
            self.assertTrue(1.4 < eat["value"]["median"] < 1.6, (who, eat["value"]))

    def test_dstab_gap_of_others(self):
        gap = rule("attack.gap.others.dstab")
        self.assertEqual(gap["n"], 195)
        self.assertAlmostEqual(gap["value"]["median"], 1.83, places=2)

    def test_gaps_are_not_usable(self):
        # Review RUL-7: every gap fails clocks.md's rule (p90-p10 <= 0.2), so each one is a range to sweep.
        for key in [k for k in data()["rules"] if k.startswith("attack.gap.others.")]:
            self.assertFalse(rule(key)["usable"], key)
            self.assertEqual(len(rule(key)["alt"]), 3, key)

    def test_gap_rules_compute_usable(self):
        # Review RUL-7 residual: the computation, not today's data. A narrow gap with n >= 10 is usable and has no alt; a
        # wide one is swept p10..p90; a gap with no n is left out.
        def row(ability, n, p10, median, p90):
            return {"ability": ability, "stated": 2.0,
                    "stats": {"n": n, "min": p10 - 0.1, "p10": p10, "median": median, "p90": p90}}
        out = R.gap_rules({"stated": {"opponents": [row("NARROW", 20, 1.70, 1.75, 1.85), row("WIDE", 20, 1.5, 1.8, 3.0),
                                                     row("FEW", 5, 1.70, 1.75, 1.80), row("NONE", 0, 0, 0, 0)]}})
        self.assertEqual(sorted(out), ["attack.gap.others.few", "attack.gap.others.narrow", "attack.gap.others.wide"])
        self.assertTrue(out["attack.gap.others.narrow"]["usable"])
        self.assertNotIn("alt", out["attack.gap.others.narrow"])
        self.assertFalse(out["attack.gap.others.wide"]["usable"])
        self.assertEqual(out["attack.gap.others.wide"]["alt"], [1.5, 1.8, 3.0])
        self.assertFalse(out["attack.gap.others.few"]["usable"])
        self.assertAlmostEqual(out["attack.gap.others.wide"]["value"]["sd"], round(1.5 / R.SPREAD_TO_SD, 3))

    def test_shield_cost_per_logger(self):
        # Review RUL-2: 'Equilibrium used' after each shield line.
        self.assertEqual((rule("defence.shield.cost.Claes")["value"], rule("defence.shield.cost.Claes")["n"]), (4.0, 13))
        self.assertEqual((rule("defence.shield.cost.Elmer")["value"], rule("defence.shield.cost.Elmer")["n"]), (3.4, 12))
        self.assertEqual((rule("defence.shield.cost.Nikita")["value"], rule("defence.shield.cost.Nikita")["n"]), (3.4, 10))

    def test_shield_reraise_is_the_logs(self):
        # The rule's numbers are the four logs' FLAY of the shield to the next shield line within 20 s.
        values = []
        for key in ke.KEYS:
            events = ke.stream(ke.load(key))
            for k, ev in enumerate(events):
                if ev["name"] != "flay.shield":
                    continue
                up = next((x for x in events[k + 1:] if x["name"] == "shield.up" and x["t"] - ev["t"] < 20), None)
                if up:
                    values.append(round(up["t"] - ev["t"], 3))
        st = kb.stats(values)
        v = rule("defence.shield.reraise")
        self.assertEqual(v["n"], st["n"])
        for field in ("median", "min", "p10", "p90", "max"):
            self.assertAlmostEqual(v["value"][field], st[field], places=3)

    def test_every_measured_rule_has_n(self):
        for key, r in data()["rules"].items():
            if r["tag"] == "MEASURED":
                self.assertTrue(r.get("n"), key)

    def test_hypochondria_chain_is_the_pooled_median(self):
        # Review N2-9: the values were Z5's single samples. They are the median of every sample in the four logs, and n
        # is the smallest step's.
        with open(ke.OUT_JSON, encoding="utf-8") as fh:
            census = json.load(fh)["census"]
        r = rule("timed.hypochondria")
        ns = []
        for step in ke.CHAIN:
            values = [v for key in ke.KEYS for v in census[key]["suppliers"]["hypochondria." + step]]
            self.assertAlmostEqual(r["value"][step], round(ke.median(values), 2), places=6, msg=step)
            ns.append(len(values))
        self.assertEqual(ns, [8, 7, 5])
        self.assertEqual(r["n"], min(ns))

    def test_a_flay_takes_the_coating(self):
        # Rule attack.flay.coating: a FLAY of the shield or rebounding made with the coating up ripped it in the same
        # packet 23 times of 23; none of the 33 made with it down printed the strip line.
        tally = {}
        for key in ke.KEYS:
            coat, packet = False, []
            for ev in ke.stream(ke.load(key)):
                packet.append(ev)
                if ev["kind"] != "prompt":
                    continue
                names = [e["name"] for e in packet]
                if "flay.shield" in names or "flay.rebounding" in names:
                    k = (coat, "sileris.down" in names)
                    tally[k] = tally.get(k, 0) + 1
                for e in packet:
                    if e["name"] == "sileris.up":
                        coat = True
                    elif e["name"] == "sileris.down":
                        coat = False
                packet = []
        self.assertEqual(tally, {(True, True): 23, (False, False): 33})
        self.assertEqual(rule("attack.flay.coating")["n"], 23)
        self.assertNotIn("alt", rule("attack.flay.coating"))

    def test_rebounding_smoke_items(self):
        # Rule defence.rebounding.smoke: 48 of the 49 smokes of skullcap or malachite saw rebounding 7.5-8.6 s later,
        # before the next such smoke (g 2887 did not: the log ends). az 573 is the firefly pipe's line (review R3-docs-2).
        items = rule("defence.rebounding.smoke")["value"]
        self.assertEqual(items, ["skullcap", "malachite"])
        smokes, ups, per_log = 0, 0, {}
        for key in ke.KEYS:
            events = ke.stream(ke.load(key))
            sm = [e for e in events if e["kind"] == "cure" and e["name"] == "smoke" and e["args"] and e["args"][0] in items]
            per_log[key] = len(sm)
            up_rows = [e for e in events if e["name"] == "rebounding.up"]
            for k, ev in enumerate(sm):
                stop = sm[k + 1]["row"] if k + 1 < len(sm) else None
                up = next((u for u in up_rows if u["row"] > ev["row"] and (stop is None or u["row"] < stop)), None)
                smokes += 1
                ups += up is not None and 7.5 <= up["t"] - ev["t"] <= 8.6
        self.assertEqual((ups, smokes), (48, 49))
        # The rule's source names az's 16 skullcap smokes, the firefly pipe's az 573 among them (review R4 nit).
        self.assertEqual(per_log, {"az": 16, "Z5": 0, "g": 9, "X": 24})
        self.assertEqual(rule("defence.rebounding.smoke")["n"], 49)

    def test_the_coating_hardens_ten_seconds_after_the_apply(self):
        # Rule defence.sileris.harden: sileris.apply to the next sileris.up, before the next apply (review R3-fork-8).
        values, lost = [], []
        for key in ke.KEYS:
            events = ke.stream(ke.load(key))
            for k, ev in enumerate(events):
                if ev["name"] != "sileris.apply":
                    continue
                up = None
                for x in events[k + 1:]:
                    if x["name"] == "sileris.apply":
                        break
                    if x["name"] == "sileris.up":
                        up = x
                        break
                if up is not None and up["t"] - ev["t"] < 20:
                    values.append(round(up["t"] - ev["t"], 3))
                else:
                    lost.append("%s %d" % (key, ev["row"]))
        st = kb.stats(values)
        r = rule("defence.sileris.harden")
        self.assertEqual(r["n"], st["n"])
        self.assertTrue(r["usable"])
        for field in ("median", "min", "p10", "p90", "max"):
            self.assertAlmostEqual(r["value"][field], st[field], places=3)
        self.assertAlmostEqual(r["value"]["sd"], round(st["spread"] / R.SPREAD_TO_SD, 3), places=3)
        self.assertEqual(lost, ["az 3616", "Z5 1891", "Z5 4096", "Z5 4712", "Z5 4951", "Z5 5284"])

    def test_slickness_strips_the_coating(self):
        # Rule defence.sileris.slickness (review R4-engine-1): each slickness gain in a packet that starts with the
        # coating up has the slough line (sileris.down) in the same packet, 8 of 8. The coating's proof lines are the
        # fork's (theorycraft.SILERIS_UP and SILERIS_DOWN): a blocked snake proves it up (X 38, before X 146).
        up_names, down_names = ("sileris.up", "snake.blocked"), ("sileris.down", "snake.hit", "bite")
        tally, rows = {}, []
        for key in ke.KEYS:
            coat, packet = False, []
            for ev in ke.stream(ke.load(key)):
                packet.append(ev)
                if ev["kind"] != "prompt":
                    continue
                gains = [e for e in packet if e["kind"] == "gain" and e["name"] == "slickness"]
                if gains and coat:
                    k = "sileris.down" in [e["name"] for e in packet]
                    tally[k] = tally.get(k, 0) + 1
                    rows.append("%s %d" % (key, gains[0]["row"]))
                for e in packet:
                    if e["name"] in up_names:
                        coat = True
                    elif e["name"] in down_names:
                        coat = False
                packet = []
        self.assertEqual(tally, {True: 8})
        self.assertEqual(rows, ["Z5 452", "Z5 870", "Z5 1263", "Z5 1488", "Z5 1862", "Z5 4076", "g 1650", "X 147"])
        self.assertEqual(rule("defence.sileris.slickness")["n"], 8)

    def test_slickness_at_the_mark_stops_the_hardening(self):
        # Rule defence.sileris.slickness_harden: slickness on or off at the apply + 10 s, against a hardening line.
        tally = {}
        for key in ke.KEYS:
            events = ke.stream(ke.load(key))
            for k, ev in enumerate(events):
                if ev["name"] != "sileris.apply":
                    continue
                up = None
                for x in events[k + 1:]:
                    if x["name"] == "sileris.apply":
                        break
                    if x["name"] == "sileris.up":
                        up = x
                        break
                hardened = up is not None and up["t"] - ev["t"] < 20
                on = False
                for x in events:
                    if x["t"] > ev["t"] + 10.0:
                        break
                    if x["name"] == "slickness" and x["kind"] in ("gain", "lose"):
                        on = x["kind"] == "gain"
                tally.setdefault((hardened, on), []).append("%s %d" % (key, ev["row"]))
        self.assertEqual(len(tally[(True, False)]), 43)
        self.assertNotIn((True, True), tally)
        self.assertEqual(tally[(False, True)], ["az 3616", "Z5 4096", "Z5 4712", "Z5 4951", "Z5 5284"])
        self.assertEqual(tally[(False, False)], ["Z5 1891"])
        self.assertEqual(rule("defence.sileris.slickness_harden")["n"], 49)


SPAR = os.path.join(kb.OURS, "2026-11-07_164635_Saibel.log")
# kb_timing's own cost rows, and the rule that holds each one.
SEAT_RULES = {"DSTAB": "attack.cost.own.dstab", "BITE": "attack.cost.own.bite", "IMPULSE": "attack.cost.own.impulse_eq",
              "FLAY": "attack.cost.own.flay", "PINSHOT": "attack.cost.own.pinshot"}
SEAT_RECOVERED = {"balance": kb.RECOVERED_ALL, "equilibrium": kb.RECOVERED_EQ}
# Each raw round starts with `queue addclear freestand ...`, and this is the game's first reply to it.
SEAT_REPLY = "[System]: Queued freestand commands cleared."


def spar_seat():
    """Our Serpent seat in the filed spar, counted from its rows.

    cost:   the cost line in the ability's packet to the next recovery line on its channel.
    first:  the round's first reply (the last SEAT_REPLY before the cost line) to the same recovery line.
    strike: the first line in each packet that names one of the abilities, as (time, ability, 1-based line).
    Each cost and first value is (seconds, cost line, recovery line), with 1-based lines."""
    rows = list(kb.parse(SPAR))
    abilities = {name: (channel, regex) for name, _, _, channel, regex in kb.OWN_COSTS if name in SEAT_RULES}
    cost = {name: [] for name in SEAT_RULES}
    first = {name: [] for name in SEAT_RULES}
    strikes, packet, reply = [], [], None
    for row in rows:
        if row.kind == "line" and row.text.startswith(SEAT_REPLY):
            reply = row
        if row.kind == "line":
            packet.append(row)
            continue
        if row.kind != "prompt":
            continue
        named = {}
        for line in packet:
            for name, (channel, regex) in abilities.items():
                if regex.match(line.text):
                    named.setdefault(channel, set()).add(name)
                    if not strikes or strikes[-1][2] < packet[0].n + 1:
                        strikes.append((line.own, name, line.n + 1))
        for line in packet:
            m = kb.USED.match(line.text)
            if not m or len(named.get(m.group(1).lower(), ())) != 1:
                continue
            channel = m.group(1).lower()
            name = next(iter(named[channel]))
            back = next(r for r in rows[line.n + 1:] if r.kind == "line" and SEAT_RECOVERED[channel].match(r.text))
            cost[name].append((round(back.own - line.own, 3), line.n + 1, back.n + 1))
            first[name].append((round(back.own - reply.own, 3), reply.n + 1, back.n + 1))
        packet = []
    return cost, first, strikes


def pstdev(values):
    mean = sum(values) / len(values)
    return (sum((v - mean) ** 2 for v in values) / len(values)) ** 0.5


class OurSeat(unittest.TestCase):
    """The MEASURED rules about our own Serpent seat, re-counted from the filed spar (2026-11-07, against Saibel)."""

    @classmethod
    def setUpClass(cls):
        cls.cost, cls.first, cls.strikes = spar_seat()

    def assert_stats(self, value, samples, fields=("median", "min", "p10", "p90", "max")):
        ordered = sorted(s for s, _, _ in samples)
        exact = {"median": kb.percentile(ordered, 0.5), "p10": kb.percentile(ordered, 0.1),
                 "p90": kb.percentile(ordered, 0.9), "min": ordered[0], "max": ordered[-1]}
        for field in fields:
            # A median of two samples can end in half a millisecond (DSTAB: 1.626 and 1.641 give 1.6335), and the rule
            # rounds it to 3 places. So the rule may differ from the exact value by half a millisecond.
            self.assertAlmostEqual(value[field], exact[field], delta=0.0006, msg=field)
        return kb.stats(ordered)

    def test_every_cost_line_pairs_with_a_recovery(self):
        # 24 DSTAB, 13 impulses each with a bite, 1 FLAY and 1 PINSHOT: 52 cost lines, none left out.
        self.assertEqual({name: len(v) for name, v in self.cost.items()},
                         {"DSTAB": 24, "BITE": 13, "IMPULSE": 13, "FLAY": 1, "PINSHOT": 1})
        self.assertEqual(sum(len(v) for v in self.cost.values()), 52)

    def test_the_usable_costs(self):
        for name in ("DSTAB", "BITE", "IMPULSE"):
            r = rule(SEAT_RULES[name])
            self.assertEqual((r["tag"], r["n"], r["usable"]), ("MEASURED", len(self.cost[name]), True), name)
            st = self.assert_stats(r["value"], self.cost[name])
            self.assertEqual(kb.usable(st), (True, ""), name)
            self.assertAlmostEqual(r["value"]["sd"], round(st["spread"] / R.SPREAD_TO_SD, 3), places=3, msg=name)
            self.assertIn(os.path.basename(SPAR), r["source"], name)

    def test_the_numbers_the_plan_quotes(self):
        self.assertAlmostEqual(rule("attack.cost.own.dstab")["value"]["median"], 1.634, places=3)
        self.assertEqual(rule("attack.cost.own.bite")["value"]["median"], 1.563)
        self.assertEqual(rule("attack.cost.own.impulse_eq")["value"]["median"], 1.242)

    def test_each_cost_has_the_first_reply_alternative(self):
        # Every cost line came after the round's first reply. Timed from that reply, each cost is about 0.12 s longer.
        # The rule holds it in first_reply too, which theorycraft --gap queue-late runs (review KE-3).
        for name in SEAT_RULES:
            r = rule(SEAT_RULES[name])
            want = kb.stats([s for s, _, _ in self.first[name]])["median"]
            self.assertTrue(any(abs(a - want) <= 0.0006 for a in r["alt"]), (name, want, r["alt"]))
            self.assertAlmostEqual(r["first_reply"], want, delta=0.0006, msg=name)
            self.assertIn(r["first_reply"], r["alt"], name)
            self.assertTrue(0.08 < want - kb.stats([s for s, _, _ in self.cost[name]])["median"] < 0.14, name)

    def test_one_sample_costs_are_swept(self):
        flay = rule("attack.cost.own.flay")
        self.assertEqual((flay["n"], flay["usable"]), (1, False))
        self.assertEqual(flay["value"], self.cost["FLAY"][0][0])
        # The sweep keeps the plan's 1.48-2.00: others' shortest FLAY gap, and the stated cost.
        self.assertEqual((flay["alt"][0], flay["alt"][-1]), (rule("attack.gap.others.flay")["value"]["min"], 2.0))
        pin = rule("attack.cost.own.pinshot")
        self.assertEqual((pin["n"], pin["usable"], pin["value"]), (1, False, self.cost["PINSHOT"][0][0]))
        self.assertEqual(pin["alt"], [self.cost["PINSHOT"][0][0], self.first["PINSHOT"][0][0]])

    def test_the_impulse_and_its_bite_run_side_by_side(self):
        # The two cost lines come in one packet, and equilibrium comes back first every time, so the bite gates the round.
        for (eq, eq_line, eq_back), (bal, bal_line, bal_back) in zip(self.cost["IMPULSE"], self.cost["BITE"]):
            self.assertLessEqual(abs(eq_line - bal_line), 10)
            self.assertLess(eq_back, bal_back)
        self.assertLess(max(s for s, _, _ in self.cost["IMPULSE"]), min(s for s, _, _ in self.cost["BITE"]))

    def test_the_gap_is_land_to_land(self):
        # The strike line of each attack to the next one. The pinshot opener is left out.
        self.assertEqual(len(self.strikes), 39)
        gaps = [(round(b[0] - a[0], 3), a[2], b[2]) for a, b in zip(self.strikes, self.strikes[1:]) if a[1] != "PINSHOT"]
        r = rule("attack.gap.own")
        self.assertEqual((r["tag"], r["n"], r["usable"]), ("MEASURED", len(gaps), False))
        st = self.assert_stats(r["value"], gaps)
        self.assertEqual(kb.usable(st)[0], False)
        self.assertEqual(max(gaps)[1:], (1040, 1091))
        # The alternatives: the server-queue floor (our DSTAB cost) and other Serpents' median gap.
        self.assertEqual(r["alt"], [rule("attack.cost.own.dstab")["value"]["median"],
                                    rule("attack.gap.others.dstab")["value"]["median"]])
        self.assertAlmostEqual(pstdev([g for g, _, _ in gaps]), 0.189, places=3)
        # The CLI reads it under --gap raw (review KE-4: the note said it did not).
        self.assertIn("theorycraft --gap raw runs its median", r["note"])
        self.assertNotIn("does not read this value", r["note"])

    def test_the_gap_sd_is_not_our_measure(self):
        # 0.09 is a printed cost against its recovery, not our gap's noise. Our DSTAB cost's own sd is the alternative.
        r = rule("attack.gap.own.sd")
        self.assertEqual((r["tag"], r["value"]), ("ASSUMED", 0.09))
        self.assertAlmostEqual(pstdev([s for s, _, _ in self.cost["DSTAB"]]), 0.061, places=3)
        self.assertIn(0.061, r["alt"])


class Read(unittest.TestCase):
    def test_blockers(self):
        self.assertEqual(rule("channel.eat.blocked_by")["value"], ["anorexia"])
        self.assertEqual(rule("channel.salve.blocked_by")["value"], ["slickness"])
        self.assertEqual(rule("channel.smoke.blocked_by")["value"], ["asthma"])
        self.assertEqual(rule("channel.focus.blocked_by")["value"], ["impatience"])
        self.assertEqual(rule("channel.tree.blocked_by")["value"], ["paralysis"])

    def test_class_cure_blockers_are_kb_replay(self):
        for cls, aff in rp.BLOCKERS.items():
            self.assertEqual(rule("classcure.blocker." + cls)["value"], aff)

    def test_cure_options_are_alternatives(self):
        # cure-channels.md:23: focus alone cures anorexia. The groups of cure_options are joined by "or".
        self.assertEqual(rule("cure.options_join")["value"], "or")
        channels = {o["channel"] for o in rule("cure.anorexia")["value"]["options"]}
        self.assertEqual(channels, {"salve", "focus"})
        items = {o["item"] for o in rule("cure.paralysis")["value"]["options"]}
        self.assertEqual(items, {"bloodroot", "magnesium"})

    def test_lungs_items(self):
        # Pear and calcite are eaten, but they spend the lungs clock.
        self.assertEqual(rule("channel.eat.lungs_items")["value"], ["pear", "calcite"])

    def test_salt_and_accelerate_spend_equilibrium(self):
        # Review RUL-1: Z5 prints 'Equilibrium used: 2.55s.' before each of the 7 salt lines; X 2096 'Equilibrium used:
        # 2.12s.' after the one Accelerate, whose lockout was 19.45 s (X 2088 to 2409).
        salt = rule("class.salt")["value"]
        self.assertEqual(salt["needs"], ["eq"])
        self.assertEqual(salt["spends"], {"eq": "class.salt.eq"})
        self.assertEqual((rule("class.salt.eq")["value"], rule("class.salt.eq")["n"]), (2.55, 7))
        acc = rule("class.accelerate")["value"]
        self.assertEqual(acc["needs"], ["eq"])
        self.assertEqual(rule("class.accelerate.eq")["value"], 2.12)
        lock = rule("class.accelerate.lockout")
        self.assertEqual((lock["value"], lock["tag"], lock["n"], lock["usable"]), (19.45, "MEASURED", 1, False))
        self.assertEqual(rule("class.accelerate.cures")["alt"], [2])

    def test_cure_channels_for_lungs_and_elixir(self):
        # Review RUL-5: pear and calcite spend the lungs, shut by anorexia (cure-channels.md:19, 33); APPLY HEALTH is the
        # health elixir, not a salve (cure-channels.md:45-47).
        self.assertEqual({o["channel"] for o in rule("cure.pressure")["value"]["options"]}, {"lungs"})
        self.assertEqual({o["channel"] for o in rule("cure.crackedribs")["value"]["options"]}, {"elixir"})

    def test_random_pool_is_assumed(self):
        # Review RUL-6: the flag is READ, its meaning for the tree is ASSUMED, with the package's tree pool as alternative.
        pool = rule("random_cure.pool")
        self.assertEqual(pool["tag"], "ASSUMED")
        # The package's pool grew from 27 to 77 after the 2026-11-07 spar: Saibel's tree took recklessness
        # (ours/2026-11-07_164635_Saibel line 422), and the pool did not hold it.
        self.assertEqual(len(pool["alt"][0]), 77)
        self.assertIn("paralysis", pool["alt"][0])
        self.assertIn("recklessness", pool["alt"][0])
        self.assertIn("no_random_cure", rule("cure.paralysis")["value"])
        self.assertNotIn("random_cure", rule("cure.paralysis")["value"])

    def test_flay_and_bite_rules(self):
        # Review RUL-8: the attacker names what a FLAY strips (Subterfuge.wiki:76); the order is ASSUMED.
        self.assertIn("Subterfuge.wiki:76", rule("attack.flay")["source"])
        self.assertEqual(rule("attack.flay.order")["tag"], "ASSUMED")
        self.assertIn("Venom.wiki:23", rule("attack.bite")["source"])

    def test_the_draw_shape_is_assumed(self):
        # The tails of a drawn clock are the engine's choice (victim.lua V.tails), with the normal draw as alternative.
        r = rule("draw.shape")
        self.assertEqual(r["tag"], "ASSUMED")
        self.assertTrue(r["alt"][0].startswith("normal"))

    def test_fitness(self):
        fit = rule("class.fitness")["value"]
        self.assertEqual(fit["cures"], ["asthma"])
        self.assertEqual(fit["blocked_by"], ["weariness"])
        self.assertIn("Runewarden", fit["classes"])
        self.assertTrue(fit["while_paralysed"])


class Venoms(unittest.TestCase):
    def test_lock_venoms(self):
        self.assertEqual(rule("venom.curare")["value"]["affs"], ["paralysis"])
        self.assertEqual(rule("venom.kalmia")["value"]["affs"], ["asthma"])
        self.assertEqual(rule("venom.curare")["tag"], "ASSUMED")
        self.assertTrue(rule("venom.curare")["alt"])

    def test_venom_affs_forms(self):
        self.assertEqual(R.venom_affs("none"), [])
        self.assertEqual(R.venom_affs("paralysis"), ["paralysis"])

    def test_limb_venoms_break_a_limb(self):
        # Review RUL-4: the package maps epseth to a leg break and epteth to an arm break, left first.
        self.assertEqual(rule("venom.epseth")["value"]["affs"], ["brokenleftleg|brokenrightleg"])
        self.assertEqual(rule("venom.epteth")["value"]["affs"], ["brokenleftarm|brokenrightarm"])

    def test_venom_alternative_is_runnable(self):
        # The wiki's prose is a reference; the runnable alternative is "off".
        self.assertEqual(rule("venom.curare")["alt"], ["off"])
        self.assertTrue(rule("venom.curare")["wiki"])


def race_delays(down, src=None):
    """The SSC delay of each race row of kb/sim/events.json whose 'down' flag is the one given (None: all logs)."""
    with open(ke.OUT_JSON, encoding="utf-8") as fh:
        race = json.load(fh)["race"]
    return [r["delay"] for r in race if r.get("down") is down and r.get("delay") is not None
            and (src is None or r["src"] == src)]


class SscDelay(unittest.TestCase):
    """The two cases of the SSC delay (victim.lua V.delay), re-derived from the race rows of kb/sim/events.json by their
    'down' flag: a gain on an open eat, and an eat that comes back with an affliction waiting."""

    def test_the_two_cases(self):
        for key, down, n in (("ssc.delay.gain", False, 23), ("ssc.delay.return", True, 163)):
            r = rule(key)
            delays = race_delays(down)
            st = kb.stats(delays)
            self.assertEqual((r["tag"], r["n"], r["usable"]), ("MEASURED", n, True), key)
            self.assertEqual(len(delays), n, key)
            self.assertEqual(r["value"], R.clock_value(st), key)
            self.assertEqual(r["value"]["sd"], round(st["spread"] / R.SPREAD_TO_SD, 3), key)
            self.assertEqual(kb.usable(st), (True, ""), key)
            self.assertIn("events.json race[]", r["source"], key)
        self.assertEqual((rule("ssc.delay.gain")["value"]["median"], rule("ssc.delay.return")["value"]["median"]),
                         (0.104, 0.145))
        # The one-case rule is gone: it was 0.10-0.18 uniform for both cases.
        self.assertNotIn("ssc.delay", data()["rules"])

    def test_the_per_log_medians_in_the_notes(self):
        for key, down in (("ssc.delay.gain", False), ("ssc.delay.return", True)):
            note = rule(key)["note"]
            for src in ke.KEYS:
                delays = race_delays(down, src)
                text = "%s %.3f" % (src, kb.stats(delays)["median"])
                if not down:
                    text += " (n=%d)" % len(delays)
                self.assertIn(text, note, (key, src))

    def test_a_row_with_no_down_flag_is_in_neither_case(self):
        with open(ke.OUT_JSON, encoding="utf-8") as fh:
            race = json.load(fh)["race"]
        rows = [(r["src"], r["row"], r["delay"]) for r in race if r.get("down") is None and r.get("delay") is not None]
        self.assertEqual(rows, [("g", 126, 0.018)])
        self.assertIn("g 126, down null, 0.018", rule("ssc.delay.gain")["note"])


# Saibel's lines and ours in the spar (SPAR).
SPAR_PARALYSIS = "Horror overcomes Saibel's face"
SPAR_EAT = re.compile(r"^Saibel eats (?:a|an|some) (\w+) \w+\.$")
SPAR_IMPULSE = re.compile(r"^You craft the impulse of (\w+) in the mind of Saibel\.$")
SPAR_BITE = re.compile(r"^You sink your fangs into Saibel, injecting just the proper amount of (\w+)\.$")
SPAR_HOLD = re.compile(r"^You sense the weakness in Saibel as your (\w+) takes hold\.$")
SPAR_BOREDOM = "Saibel shuffles her feet in boredom."


def spar_lines():
    return [r for r in kb.parse(SPAR) if r.kind == "line"]


class SparVictim(unittest.TestCase):
    """The spar's rules about Saibel and about our impulses, re-counted from its rows (2026-11-07)."""

    @classmethod
    def setUpClass(cls):
        cls.lines = spar_lines()

    def test_saibel_open_channel_reaction(self):
        # Each paralysis landing to her next herb eat. Potash is moss, on its own clock, so it is not a herb eat here.
        # A landing counts when her last herb eat came 1.506 s or more before it (her shortest herb eat-to-eat), or when
        # she had not eaten yet. That cut is the only selection: no landing is left out for its delay (review KE-2).
        herbs = [r for r in self.lines if SPAR_EAT.match(r.text) and SPAR_EAT.match(r.text).group(1) != "potash"]
        landings, since = [], {}
        for hit in (r for r in self.lines if r.text.startswith(SPAR_PARALYSIS)):
            before = [e for e in herbs if e.n < hit.n]
            if before and hit.own - before[-1].own < 1.506:
                continue
            if before:
                since[hit.n + 1] = round(hit.own - before[-1].own, 3)
            eat = next(e for e in herbs if e.n > hit.n)
            landings.append((round(eat.own - hit.own, 3), hit.n + 1, eat.n + 1))
        self.assertEqual(len(landings), 9)
        r = rule("ssc.delay.gain.Saibel")
        st = kb.stats([d for d, _, _ in landings])
        self.assertEqual((r["tag"], r["n"], r["usable"]), ("MEASURED", 9, False))
        self.assertEqual(r["value"], R.clock_value(st))
        self.assertEqual(r["alt"], [st["min"], st["median"], st["max"]])
        self.assertEqual(r["source"], "kb/raw/logs/ours/%s:%s" % (
            os.path.basename(SPAR), ",".join("%d-%d" % (a, b) for _, a, b in landings)))
        # The slow one is kept: FL 1098, she ate 0.216 s later. The other eight are within 0.064 s.
        self.assertEqual(max(landings), (0.216, 1098, 1105))
        self.assertLessEqual(sorted(landings)[-2][0], 0.064)
        # Five landings came inside her forced herb eat-to-eat (1.506-1.759), FL 1098 the latest of them, so the reason
        # once given for leaving FL 1098 out held for four of the kept ones too. The note names all five.
        inside = sorted((t, row) for row, t in since.items() if t <= 1.759)
        self.assertEqual(inside, [(1.514, 1462), (1.53, 999), (1.566, 1141), (1.6, 771), (1.61, 1098)])
        for t, row in inside:
            self.assertIn("FL %d at %.3f" % (row, t), r["note"])
        # It is the gain rule's alternative, never its value.
        self.assertEqual(rule("ssc.delay.gain")["alt"], ["ssc.delay.gain.Saibel"])

    def test_a_flay_on_a_missing_defence_takes_the_coating(self):
        # Rule attack.flay.missing (review KE-1). We sent 'flay Saibel rebounding curare' (FL 283). In one packet the game
        # said the rebounding was not there (FL 305), ripped the coating (FL 308), whipped (FL 315) and paralysed (FL 318).
        rows = list(kb.parse(SPAR))
        self.assertIn((283, "flay Saibel rebounding curare"), [(r.n + 1, r.text) for r in rows if r.kind == "sent"])
        tries = [r for r in rows if r.kind == "line" and r.text.startswith("You try to flay a non-existent ")]
        self.assertEqual([(r.n + 1, r.text) for r in tries],
                         [(305, "You try to flay a non-existent aura of rebounding from Saibel.")])
        packet = []
        for r in rows[rows.index(tries[0]):]:
            if r.kind == "prompt":
                break
            if r.kind == "line":
                packet.append((r.n + 1, r.text))
        self.assertIn((308, "The protective coating covering the skin of Saibel is ripped away with their protections."),
                      packet)
        self.assertTrue(any(n == 315 and t.startswith("With your victim exposed, you crack ") for n, t in packet))
        self.assertTrue(any(n == 318 and t.startswith(SPAR_PARALYSIS) for n, t in packet))
        # The only coating line of the spar, and every bite after it reached her.
        self.assertEqual([r.n + 1 for r in rows if r.kind == "line" and "coating" in r.text], [308])
        self.assertTrue(all(r.n + 1 > 308 for r in rows if r.kind == "line" and SPAR_BITE.match(r.text)))
        # The victim-seat row against it: X 5328's whip with no strip line, and the coating met at X 5385.
        x = ke.log_path("X")
        with open(x, encoding="utf-8") as fh:
            lines = fh.read().split("\n")
        self.assertTrue(lines[5327].startswith("With fluid grace, Archaeon snaps his wrist"))
        self.assertFalse(any("ripped away" in line for line in lines[5300:5340]))
        self.assertIn("the waxy coating that protects you.", lines[5384])
        r = rule("attack.flay.missing")
        self.assertEqual((r["tag"], r["n"]), ("MEASURED", 1))
        self.assertTrue(r["value"].startswith("coating"))
        self.assertTrue(r["alt"][0].startswith("nothing") and "X 5328" in r["alt"][0])
        self.assertIn("2026-11-07_164635_Saibel.log:283,305-319", r["source"])
        self.assertIn("X8pRorzR.txt:5301-5317,5328-5330,5384-5386", r["source"])
        # The coating rule no longer reads X 5328 as its own case.
        self.assertNotIn("X 5328", rule("attack.flay.coating")["note"])

    def test_the_trivial_suggestions(self):
        # Rule attack.impulse.suggestions (review KE-5): the wiki's trivial list and the package's TRIVIAL_SUGGESTIONS.
        with open(os.path.join(R.ROOT, "kb", "raw", "wiki", "Hypnosis.wiki"), encoding="utf-8") as fh:
            wiki = fh.read()
        trivial = wiki[wiki.index("<b>Trivial suggestions</b>"):wiki.index("<b>Complex Suggestions</b>")]
        names = [n.lower() for n in re.findall(r"\|skill=\[\[(\w+)\]\]", trivial)]
        lua = os.path.join(R.ROOT, "src_new", "scripts", "levi_ataxia", "levi", "levi_scripts", "serpent",
                           "002_Serpent_Offense.lua")
        with open(lua, encoding="utf-8") as fh:
            block = re.search(r"TRIVIAL_SUGGESTIONS = \{(.*?)\}", fh.read(), re.S).group(1)
        package = re.findall(r'"(\w+)"', block)
        r = rule("attack.impulse.suggestions")
        self.assertEqual(r["tag"], "READ")
        self.assertEqual(r["value"], names)
        self.assertEqual(r["value"], package)
        self.assertNotIn("clumsiness", r["value"])
        # Every suggestion the spar used is one of them.
        used = {SPAR_IMPULSE.match(row.text).group(1) for row in self.lines if SPAR_IMPULSE.match(row.text)}
        self.assertEqual(used, {"masochism", "confusion", "stupidity", "recklessness"})
        self.assertTrue(used <= set(r["value"]))

    def impulses(self):
        """Each impulse line with the bite after it, as (impulse row, bite row, suggestion, venom, seconds between)."""
        out = []
        for k, row in enumerate(self.lines):
            m = SPAR_IMPULSE.match(row.text)
            if not m:
                continue
            bite = next(r for r in self.lines[k + 1:] if SPAR_BITE.match(r.text))
            out.append((row, bite, m.group(1), SPAR_BITE.match(bite.text).group(1), round(bite.own - row.own, 3)))
        return out

    def test_an_impulse_delivers_its_venom(self):
        imps = self.impulses()
        self.assertEqual(len(imps), 13)
        # Each bite is in the impulse's own packet: 0.007 s or less after it, far under BUNDLED.
        self.assertLessEqual(max(dt for _, _, _, _, dt in imps), 0.007)
        self.assertLess(max(dt for _, _, _, _, dt in imps), kb.BUNDLED)
        # Every bite of the spar came with an impulse.
        self.assertEqual(sum(1 for r in self.lines if SPAR_BITE.match(r.text)), 13)
        r = rule("attack.impulse.venom")
        self.assertEqual((r["tag"], r["n"]), ("MEASURED", 13))
        self.assertEqual(r["source"], "kb/raw/logs/ours/%s:%s" % (
            os.path.basename(SPAR), ",".join("%d-%d" % (i.n + 1, b.n + 1) for i, b, _, _, _ in imps)))

    def reactions(self, venom):
        """Each bite of the venom, as (impulse, bite, suggestion, the 'takes hold' row or None, the boredom row or None)."""
        out = []
        for imp, bite, sugg, v, _ in self.impulses():
            if v != venom:
                continue
            k = self.lines.index(bite)
            near = [r for r in self.lines[k + 1:k + 6] if r.own - bite.own < kb.BUNDLED]
            hold = next((r for r in near if SPAR_HOLD.match(r.text)), None)
            bored = next((r for r in near if r.text == SPAR_BOREDOM), None)
            out.append((imp, bite, sugg, hold, bored))
        return out

    def test_the_monkshood_reaction_seen(self):
        seen = self.reactions("monkshood")
        self.assertEqual(len(seen), 10)
        fired = [x for x in seen if x[3]]
        self.assertEqual(len(fired), 8)
        # The impatience line comes after each one, and never without one.
        self.assertTrue(all(x[4] for x in fired))
        self.assertFalse(any(x[4] for x in seen if not x[3]))
        # All 7 masochism impulses fired it; one of 2 confusion impulses did; the stupidity impulse did not.
        by = {}
        for imp, _, sugg, hold, _ in seen:
            by.setdefault(sugg, []).append(bool(hold))
        self.assertEqual(by, {"masochism": [True] * 7, "confusion": [False, True], "stupidity": [False]})
        r = rule("reaction.monkshood.seen")
        self.assertEqual((r["tag"], r["n"]), ("MEASURED", 10))
        self.assertTrue(r["value"].startswith("8 of 10 monkshood bites fired the reaction"))
        ranges = ",".join("%d-%d" % (imp.n + 1, (bored or bite).n + 1) for imp, bite, _, _, bored in seen)
        self.assertTrue(r["source"].startswith("kb/raw/logs/ours/%s:%s;" % (os.path.basename(SPAR), ranges)))
        # The engine's rule: the three conditions give impatience. They stay ASSUMED: our seat cannot see her afflictions.
        self.assertEqual(rule("reaction.monkshood")["tag"], "ASSUMED")
        self.assertEqual(rule("reaction.monkshood")["value"], {"conditionals": ["asthma", "masochism", "weariness"],
                                                               "gives": ["impatience"]})

    def test_the_loki_reaction_seen(self):
        seen = self.reactions("loki")
        self.assertEqual([(sugg, hold is not None) for _, _, sugg, hold, _ in seen],
                         [("stupidity", False), ("recklessness", True)])
        self.assertEqual(seen[1][3].n + 1, 1411)
        self.assertIn("1 of 2 loki bites printed 'takes hold'", rule("reaction.loki")["note"])
        self.assertEqual(rule("reaction.loki")["tag"], "ASSUMED")
        self.assertEqual(rule("reaction.loki")["value"], {"conditionals": ["confusion", "recklessness"],
                                                          "gives": ["nausea", "paralysis"]})


if __name__ == "__main__":
    unittest.main()
