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
        want = {"ssc.delay": ["SSC acts with no delay"], "ssc.phi": ["aurum"], "attack.gap.own.sd": ["time to recovery"],
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
        self.assertEqual(len(pool["alt"][0]), 27)
        self.assertIn("paralysis", pool["alt"][0])
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


if __name__ == "__main__":
    unittest.main()
