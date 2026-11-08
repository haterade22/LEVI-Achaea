"""Tests for tools/theorycraft.py and the engine under it (tools/sim/fight.lua, victim.lua, attackers.lua).

The gate of plan step 7.2, stage 1: the golden text of the user's example, the same seed giving the same stream in two
processes, and the engine's true label equal to kb_replay.is_true at every prompt of the four Serpent logs.

    python -B tools/test_theorycraft.py
"""
import contextlib
import io
import json
import math
import os
import re
import subprocess
import sys
import tempfile
import types
import unittest

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kb_events as ke  # noqa: E402
import kb_replay as rp  # noqa: E402
import theorycraft as tc  # noqa: E402

EXAMPLE = ["--victim", "runewarden", "--gap", "1.83", "--median", "--script", "dstab curare kalmia", "dstab curare kalmia",
           "dstab gecko slike"]

# The user's example (2026-11-07), as the engine prints it today. The first line holds the hashes and is left out. If a
# rule in kb/sim/rules.json moves, this text moves: read the new text before you paste it here.
# Since the SSC delay split (ssc.delay.gain 0.104, ssc.delay.return 0.145): the eat after a strike on an open eat comes at
# +0.10, and the tree after the eat took the paralysis that shut it comes at +0.145 after that eat (2.08).
GOLDEN = """\
ILLUSTRATIVE: clocks.json medians, no noise, top-priority picks.
GAP   1.83 from --gap = other Serpents' median DSTAB gap (n=195).
OURS  from the 2026-11-07 spar: raw 1.965 land to land as played (attack.gap.own, n=37); queue floor 1.634 from the cost line or 1.750 from the round's first reply (our DSTAB cost, n=24; an impulse round 1.563 or 1.676). Where the 0.09 s step falls is open. --gap raw, queue, queue-late or others picks one.
VICTIM Runewarden: eat clock 1.530 (logger Claes), SSC delay 0.104 on a gain, 0.145 on a return.
      t who action                         change                            A | V eat  smk    slv    foc    tree   FIT    DGZ     PHASE
   0.00 A   dstab curare kalmia            +paralysis +asthma             1.83 | up     x:ast  up     up     x:par  up     7.55        -
   0.10 V   eat bloodroot                  -paralysis                     1.83 | 1.63   x:ast  up     up     up     up     7.55
   0.10 V   FITNESS                        -asthma                        1.83 | 1.63   up     up     up     up     9.91   7.55
   1.83 A   dstab curare kalmia            +paralysis +asthma             3.66 | up     x:ast  up     up     x:par  9.91   7.55    -0.20
   1.93 V   eat bloodroot                  -paralysis                     3.66 | 3.46   x:ast  up     up     up     9.91   7.55
   2.08 V   touch tree                     -asthma                        3.66 | 3.46   up     up     up     16.04  9.91   7.55
   3.66 A   dstab gecko slike              +slickness +anorexia           5.49 | x:ano  up     x:slk  up     16.04  9.91   7.55    -0.20
   3.76 V   smoke valerian                 -slickness                        - | x:ano  5.25   up     up     16.04  9.91   7.55
   3.76 V   focus                          -anorexia                         - | up     5.25   up     6.19   16.04  9.91   7.55
RACE 1->2  herb back 1.63 < strike 1.83: herb first by 0.20 (no PHASE: no eat clock known at the strike).
RACE 2->3  herb back 3.46 < strike 3.66: herb first by 0.20 (PHASE -0.20 at the strike).
RACE 3->-  unpaired: no attack after it within 10 s (PHASE -0.20 at the strike).
MARGIN  2 of 2 paired races are decided by under 0.5 s: UNSETTLED for any verdict (the plan's small-margin rule). A MODEL P line says how often the winner holds over drawn runs.
LOGS  strike first 165 of 194 paired DSTABs (85%) in the four Serpent logs: THEIR curing, not ours (kb/sim/events.md).
      Anchor Z5 row 196: PHASE +0.602 at the strike, strike first by 0.567 s.
TREE  down 2.08-16.04: 7 strikes at 1.830 s, 9 strikes at 1.545 s. A window is not a cause (foundations.md:189-190).
FIT   lockout 9.81 is n=5, not usable: swept 9.06-9.97. Weariness shuts it. It spends 2.80 s of balance.
DGZ   Dagaz ticks every 15.10 s (not usable: swept); voyria first. Its first tick is at half a period (--median).
ASSUMED used: class.cure.policy, class.dagaz.phase, random_cure.pool, ssc.order, tree.pick, tree.policy, venom.curare, venom.gecko, venom.kalmia, venom.slike.
WIKI    used: attack.dstab.venoms.
PLAYER  used: none.
SWEEP   (MEASURED, not usable; the median ran): clock.dagaz, clock.fitness, clock.focus.
ALT     (the rule's alternative ran): class.dagaz.phase = half a period (--median); ssc.phi = 1.0, the top affliction always (--median); tree.pick = priority (--median).
LABELS soft never, true never (kb_replay.is_true).
"""


def run(argv):
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        code = tc.main(argv)
    return code, buf.getvalue()


class Golden(unittest.TestCase):
    def test_example(self):
        code, text = run(EXAMPLE)
        self.assertEqual(code, 0)
        lines = text.splitlines()
        self.assertTrue(lines[0].startswith("MODEL, NOT A LOG."))
        self.assertEqual("\n".join(lines[1:]) + "\n", GOLDEN)

    def test_no_gap_no_run(self):
        # Our two measured gaps differ by 0.33 s (raw 1.965, queue floor 1.634), and which one a fight runs is a choice:
        # the CLI refuses to pick one, and names both.
        with self.assertRaises(SystemExit) as ctx:
            run([a for a in EXAMPLE if a not in ("--gap", "1.83")])
        for word in ("--gap", "raw", "1.965", "queue", "1.634", "queue-late", "1.750", "others"):
            self.assertIn(word, str(ctx.exception))

    def test_unknown_venom(self):
        with self.assertRaises(SystemExit) as ctx:
            run(["--victim", "runewarden", "--gap", "1.83", "--script", "dstab curare nothing"])
        self.assertIn("unknown venom", str(ctx.exception))

    def test_race_probability_is_printed(self):
        code, text = run(EXAMPLE + ["--seeds", "40"])
        self.assertIn("MODEL P(strike first) =", text)
        self.assertIn("of 40 paired seeds", text)

    def test_shield_after_a_flay(self):
        # Review ENG-1: the shield came back at the FLAY's own moment, so every DSTAB after a FLAY was blocked. It now comes
        # back after defence.shield.reraise (median 5.83 s), and the DSTAB one gap later lands.
        code, text = run(["--victim", "runewarden", "--gap", "1.83", "--median", "--defences", "shield", "--script",
                          "flay shield", "dstab curare kalmia"])
        rows = [line for line in text.splitlines() if " A   dstab curare kalmia" in line]
        self.assertEqual(len(rows), 1)
        self.assertNotIn("[shield]", rows[0])
        self.assertIn("+paralysis", rows[0])
        self.assertIn("defence.shield.reraise", text)

    def test_dagaz_phase_is_drawn(self):
        # Review TC-08: without --median the first tick is drawn over one period (rule class.dagaz.phase).
        firsts = set()
        for seed in ("7", "99"):
            code, text = run([a for a in EXAMPLE if a != "--median"] + ["--seed", seed])
            row = [line for line in text.splitlines() if line.startswith("   0.00 A")][0]
            firsts.add(row.split("|")[1].split()[6])
        self.assertEqual(len(firsts), 2, firsts)


class SameSeed(unittest.TestCase):
    def test_two_processes_one_stream(self):
        # gates_whole.json stage1 same_seed_same_stream: one seed gives the same JSON Lines in two processes.
        argv = [a for a in EXAMPLE if a != "--median"] + ["--seed", "5"]
        outs = []
        with tempfile.TemporaryDirectory() as tmp:
            for k in range(2):
                path = os.path.join(tmp, "run%d.jsonl" % k)
                subprocess.run([sys.executable, "-B", os.path.join(HERE, "theorycraft.py")] + argv + ["--jsonl", path],
                               check=True, stdout=subprocess.DEVNULL)
                with open(path, "rb") as fh:
                    outs.append(fh.read())
        self.assertTrue(outs[0])
        self.assertEqual(outs[0], outs[1])

    def test_another_seed_another_stream(self):
        argv = [a for a in EXAMPLE if a != "--median"]
        with tempfile.TemporaryDirectory() as tmp:
            texts = []
            for seed in ("5", "6"):
                path = os.path.join(tmp, "s%s.jsonl" % seed)
                run(argv + ["--seed", seed, "--jsonl", path])
                with open(path, encoding="utf-8") as fh:
                    texts.append(fh.read())
        self.assertNotEqual(texts[0], texts[1])


def engine_run(script, victim="runewarden", defences=(), seed=1, median=True, start_extra=None, snap=False, engine=None):
    rules = tc.load_rules()
    model, _ = tc.build_model(rules, tc.profile(victim))
    engine = engine or tc.Engine()
    m = engine.table(model)
    start = {"t0": 0.0, "affs": [], "firstAt": 0.0, "defs": {d: True for d in defences}}
    start.update(start_extra or {})
    env = {"median": median, "gap": 1.83, "gapSd": 0 if median else 0.09, "defences": {d: True for d in defences},
           "tree": "now", "treePick": "random", "tail": 2.5, "horizon": 60, "snap": snap}
    return engine.run(start, engine.script(script, m), m, env, seed)


def pearson(xs, ys):
    n = len(xs)
    mx, my = sum(xs) / n, sum(ys) / n
    sxy = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
    sxx = sum((x - mx) ** 2 for x in xs)
    syy = sum((y - my) ** 2 for y in ys)
    return sxy / math.sqrt(sxx * syy)


class EngineStream(unittest.TestCase):
    """The engine writes kb_events' stream (review ENG-2), so kb_events' own race() and census() read a sim fight, and
    fight.lua's F.races() gives the same winners as kb_events.race() (review ENG-3)."""

    @classmethod
    def setUpClass(cls):
        cls.engine = tc.Engine()

    def test_kb_events_reads_a_sim_fight(self):
        res = engine_run(["dstab curare kalmia"] * 3, engine=self.engine)
        eats = [ev for ev in res["events"] if ke.is_eat(ev)]
        self.assertGreater(len(eats), 0)
        counts, gains, loses = ke.census(res["events"])
        self.assertEqual(counts["dstab"], 3)
        self.assertEqual(counts["eat.eat"], len(eats))
        self.assertEqual(counts["fitness"], 1)
        self.assertGreater(gains["paralysis"], 0)
        rows = ke.race(types.SimpleNamespace(id="sim"), res["events"])
        self.assertEqual([r["winner"] for r in rows], [r.get("winner") for r in res["races"]])

    def test_race_parity(self):
        scenarios = [
            (["dstab curare kalmia"] * 4, (), {}),
            (["dstab curare kalmia", "wait 12", "dstab curare kalmia"], (), {}),
            (["dstab slike gecko", "dstab curare kalmia"], (), {"affs": ["impatience", "asthma"], "ready": {"tree": 30}}),
            (["flay shield", "dstab curare kalmia", "dstab curare kalmia"], ("shield",), {}),
            (["dstab curare kalmia", "dstab curare kalmia"], ("shield",), {}),
            (["dstab gecko slike", "flay rebounding curare", "dstab curare kalmia"], ("rebounding",), {}),
            # The impulse is an attack named "bite" in the stream (attackers.lua A.lines), so the race pairs it.
            (["dstab curare kalmia", "impulse stupidity curare", "dstab curare kalmia"], (), {}),
            (["impulse stupidity monkshood", "dstab curare kalmia", "bite loki"], (),
             {"affs": ["asthma", "masochism", "weariness", "confusion", "recklessness"]}),
            (["dstab curare kalmia", "impulse vertigo curare"], ("shield",), {}),
        ]
        for script, defences, extra in scenarios:
            for seed in (1, 2, 3):
                res = engine_run(script, defences=defences, seed=seed, median=False, start_extra=extra, engine=self.engine)
                lua = [(r.get("winner"), None if r.get("by") is None else round(r["by"], 3),
                        None if r.get("phase") is None else round(r["phase"], 3)) for r in res["races"]]
                rows = ke.race(types.SimpleNamespace(id="sim"), res["events"])
                py = [(r["winner"], r["by"], r["phase"]) for r in rows]
                self.assertEqual(lua, py, (script, seed))

    def test_a_start_clock_is_known_to_the_engine_only(self):
        # A fork starts with the eat down (start.ready). F.races knows when it comes back; the stream holds no eat line, so
        # kb_events.race() gives no PHASE. This is why a fork reads its races through kb_events.race() over the LOG PREFIX
        # plus the engine's events (theorycraft.fork), where the log's eat line is present.
        res = engine_run(["dstab curare kalmia", "dstab curare kalmia"], start_extra={"ready": {"eat": 0.6}},
                         engine=self.engine)
        self.assertAlmostEqual(res["races"][0]["phase"], 0.6, places=3)
        self.assertIsNone(ke.race(types.SimpleNamespace(id="sim"), res["events"])[0]["phase"])


class Streams(unittest.TestCase):
    def test_gap_and_eat_draws_do_not_correlate(self):
        # Review TC-02: the old seeds made every stream a shifted copy of the others, and the eat clock moved with the gap
        # (corr 0.78 over 400 seeds), which halved P(strike first).
        engine = tc.Engine()
        gaps, eats = [], []
        for seed in range(1, 401):
            res = engine_run(["dstab curare kalmia", "dstab curare kalmia"], seed=seed, median=False, engine=engine)
            strikes = [ev for ev in res["events"] if ev["kind"] == "attack"]
            eat = next(ev for ev in res["events"] if ke.is_eat(ev))
            back = next(ev for ev in res["events"] if ev["kind"] == "recover" and ev["name"] == "eat")
            gaps.append(strikes[1]["t"] - strikes[0]["t"])
            eats.append(back["t"] - eat["t"])
        self.assertLess(abs(pearson(gaps, eats)), 0.15)


class LabelParity(unittest.TestCase):
    """The engine's true label is kb_replay.is_true, at every prompt of the four Serpent logs (through walk())."""

    def test_every_prompt(self):
        engine = tc.Engine()
        labels = engine.V.labels
        checked = trues = softs = 0
        for key in ke.KEYS:
            log = ke.load(key)
            cls = rp.logger_class(log)
            self.assertNotEqual(cls, "Earth Lord")  # its reversed row is not in the engine (CONFLICTS #54)
            blocker = rp.BLOCKERS.get(cls)
            for s in rp.walk(log):
                if s.terms is None:
                    continue
                start = s.clock.get("classcure")
                class_down = start is not None and s.t - start < rp.CHANNEL_MAX["classcure"]
                soft, tru = labels(engine.table(dict.fromkeys(s.terms, True)), blocker, class_down)
                self.assertEqual(bool(soft), rp.is_softlock(s.terms), (key, s.row))
                self.assertEqual(bool(tru), rp.is_true(s, cls), (key, s.row))
                checked += 1
                trues += bool(tru)
                softs += bool(soft)
        # Every prompt of the four logs, and both labels seen at least once, or the test proves little.
        self.assertGreater(checked, 3000)
        self.assertGreater(softs, 0)
        self.assertGreater(trues, 0)


class Model(unittest.TestCase):
    def setUp(self):
        self.rules = tc.load_rules()

    def model(self, name):
        return tc.build_model(self.rules, tc.profile(name))[0]

    def test_class_cures(self):
        rw = self.model("runewarden")
        self.assertEqual(rw["classcure"]["kind"], "fitness")
        self.assertEqual(rw["classcure"]["cures"], ["asthma"])
        self.assertEqual(rw["dagaz"]["first"], "voyria")
        self.assertEqual(rw["labelBlocker"], "weariness")
        self.assertEqual(self.model("alchemist")["classcure"]["kind"], "salt")
        self.assertEqual(self.model("depthswalker")["classcure"]["kind"], "accelerate")
        self.assertEqual(self.model("depthswalker")["labelBlocker"], "recklessness")

    def test_eat_clock_is_the_loggers(self):
        self.assertEqual(self.model("runewarden")["clocks"]["eat"]["median"],
                         self.rules["rules"]["clock.eat.Claes"]["value"]["median"])
        self.assertEqual(self.model("alchemist")["clocks"]["eat"]["median"],
                         self.rules["rules"]["clock.eat.Elmer"]["value"]["median"])

    def test_class_cures_spend_what_the_logs_show(self):
        # Review RUL-1: Salt and Accelerate need and spend equilibrium (Z5 'Equilibrium used: 2.55s.' 7 of 7; X 2096).
        salt = self.model("alchemist")["classcure"]
        self.assertTrue(salt["needs_eq"])
        self.assertEqual(salt["spends_eq"], 2.55)
        acc = self.model("depthswalker")["classcure"]
        self.assertTrue(acc["needs_eq"])
        self.assertEqual(acc["spends_eq"], 2.12)
        self.assertEqual(acc["lockout"]["median"], 19.45)
        self.assertEqual(acc["count"], 1)

    def test_shield_cost_is_the_loggers(self):
        # Review RUL-2: Claes paid 4.00 s for each of his 13 shields; Elmer and Nikita 3.40.
        self.assertEqual(self.model("runewarden")["shield"]["cost"], 4.0)
        self.assertEqual(self.model("alchemist")["shield"]["cost"], 3.4)
        self.assertEqual(self.model("depthswalker")["shield"]["cost"], 3.4)

    def test_random_pool_alternative(self):
        # Review RUL-6: the pool is ASSUMED; --random-pool package runs its alternative, the package's tree pool. The
        # package's pool grew from 27 to 77 after the 2026-11-07 spar (treeCurableAffsV3 took in recklessness and
        # fratricide), so the two pools now differ in a few afflictions, not in fratricide.
        base = self.model("runewarden")["lists"]["random"]
        package = tc.build_model(self.rules, tc.profile("runewarden"), {"random_pool": "package"})[0]["lists"]["random"]
        pool = set(self.rules["rules"]["random_cure.pool"]["alt"][0])
        self.assertEqual(set(package), {a for a in pool if "cure." + a in self.rules["rules"]})
        self.assertIn("fratricide", base)
        self.assertIn("recklessness", package)
        self.assertNotEqual(set(base), set(package))

    def test_lungs_and_elixir_are_not_smoke_or_salve(self):
        # Review RUL-5: pear and calcite are not smoked, and APPLY HEALTH is not a salve.
        m = self.model("runewarden")
        self.assertNotIn("pressure", m["lists"]["smoke"])
        self.assertNotIn("crackedribs", m["lists"]["salve"])

    def test_lists(self):
        m = self.model("runewarden")
        self.assertIn("paralysis", m["lists"]["eat"])
        self.assertIn("slickness", m["lists"]["smoke"])
        self.assertIn("anorexia", m["lists"]["salve"])
        self.assertIn("anorexia", m["lists"]["focus"])
        self.assertEqual(m["blocked"]["tree"], "paralysis")


class LogModes(unittest.TestCase):
    def test_log_view_first_row(self):
        code, text = run(["--log", "Z5", "--from", "196", "--rows", "3"])
        rows = [line for line in text.splitlines() if line.strip().startswith("196 ")]
        self.assertEqual(len(rows), 1)
        self.assertIn("+paralysis +weariness", rows[0])
        self.assertIn("+0.602", rows[0])

    def test_fork_reads_the_row(self):
        code, text = run(["--log", "Z5", "--at", "204", "--then", "dstab curare vernalius", "--median"])
        self.assertIn("shield down (row 196)", text)
        self.assertIn("eat down since row 154", text)
        self.assertIn("asthma, paralysis, weariness", text)
        self.assertIn("LOG   what happened instead: row 248 dstab", text)

    def test_to_is_the_last_row(self):
        # Review TC-11: --to printed one row past its bound.
        code, text = run(["--log", "Z5", "--from", "196", "--to", "250"])
        rows = [int(line.split()[0]) for line in text.splitlines()[3:] if line.strip()]
        self.assertTrue(rows)
        self.assertLessEqual(max(rows), 250)


class Fork(unittest.TestCase):
    def fork(self, key, at, *then, extra=()):
        code, text = run(["--log", key, "--at", str(at), "--then"] + list(then) + ["--median"] + list(extra))
        self.assertEqual(code, 0)
        return text

    def test_the_whole_board(self):
        # Review TC-03: the lock table alone dropped hypochondria and the other non-lock tokens.
        self.assertIn("plus the lines after it: hypochondria.", self.fork("az", 2072, "dstab curare kalmia"))
        text = self.fork("az", 3767, "dstab curare kalmia")
        for aff in ("darkshade", "disloyalty", "hypochondria", "lethargy", "masochism", "nausea", "paralysis"):
            self.assertIn(aff, text.splitlines()[1])

    def test_a_class_cure_locked_in_the_log_stays_locked(self):
        # Review TC-04: X 2088 Accelerate, 2409 'ACCELERATE BACK' (19.45 s). At row 2300 it is locked until +9.30.
        text = self.fork("X", 2300, "dstab curare kalmia")
        self.assertIn("class down since row 2088 (-10.15): back at +9.30 by the model", text)
        early = [line for line in text.splitlines() if " V   accelerate" in line and float(line.split()[0]) < 9.3]
        self.assertEqual(early, [])

    def test_dagaz_rolls_forward(self):
        # Review TC-05: a tick with nothing to cure prints nothing, so the phase rolls on from the last printed tick.
        self.assertIn("Its phase comes from row 717, the last printed tick, 3 period(s) on.",
                      self.fork("az", 1508, "dstab curare kalmia"))

    def test_the_logged_dstab_races_the_first_forked_action(self):
        # Review TC-06: --seeds counts in a fork, and the LOGS line is printed.
        text = self.fork("Z5", 204, "dstab curare vernalius", extra=["--seeds", "20"])
        self.assertIn("RACE row 196->#1  strike", text)
        self.assertIn("MODEL P(strike first)", text)
        self.assertIn("LOGS  strike first", text)

    def test_an_unpaired_log_dstab_is_shown(self):
        # The last log DSTAB stays when no forked attack comes within 10 s; an earlier log DSTAB is the log's own race.
        # Its next attack is the forked DSTAB 13.83 s later: disengaged, and named (review R3-engine-4).
        text = self.fork("Z5", 204, "wait 12", "dstab curare kalmia")
        races = [line for line in text.splitlines() if line.startswith("RACE")]
        self.assertTrue(races[0].startswith("RACE row 196->#2  unpaired: the next attack came 13.83 s later (disengaged)"),
                        races)
        # Row 78 is the logger's own action dropping its shield, not a FLAY, so no shield comes back and the forked DSTAB
        # lands (review R3-fork-2).
        self.assertNotIn("[shield]", text)
        self.assertEqual(len(races), 2, races)

    def test_phase_counts_from_the_last_recovery(self):
        # Review TC-09: the log's eat came back at row 2339, 1.45 s before the prompt at row 2358.
        text = self.fork("X", 2358, "dstab curare kalmia", "dstab gecko slike")
        self.assertIn("RACE #1->#2  herb back -1.45 < strike 1.83: herb first by 3.28 (PHASE -1.45 at the strike).", text)

    def test_a_row_with_no_event_is_in_the_next_packet(self):
        # Review TC-12 residual: row 2360 has no event. Its stamp is the next prompt's (row 2370), so the fork starts
        # there, with the FLAY at 2363 and its paralysis on the board.
        text = self.fork("X", 2360, "dstab curare kalmia")
        self.assertIn("Row 2360 is inside a packet: the fork starts at its end, prompt row 2370.", text)
        self.assertIn("plus the lines after it: paralysis.", text)

    def test_a_row_inside_a_packet(self):
        # Review TC-12: the afflictions of the DSTAB at row 196 sit on rows 197-201, in the same packet.
        text = self.fork("Z5", 196, "dstab curare vernalius")
        self.assertIn("Row 196 is inside a packet: the fork starts at its end, prompt row 204.", text)
        self.assertIn("asthma, paralysis, weariness", text)

    def test_sileris_from_the_log(self):
        # Review TC-10: az 1466 hardens the coating, and it holds at row 1500, so a BITE is blocked.
        text = self.fork("az", 1500, "dstab curare kalmia", "bite kalmia")
        self.assertIn("sileris up (row 1466)", text)
        self.assertIn("bite kalmia [sileris]", text)

    def test_the_rules_a_fork_used(self):
        # Review TC-07: each action kind names its rule, and only a DSTAB names the DSTAB venom count.
        text = self.fork("Z5", 204, "flay curare", "bite kalmia", "give hypochondria")
        lines = {line.split(" used:")[0].strip(): line for line in text.splitlines() if " used:" in line}
        self.assertIn("attack.flay", lines["WIKI"])
        self.assertIn("attack.bite", lines["WIKI"])
        self.assertNotIn("attack.dstab.venoms", lines["WIKI"])
        self.assertIn("attack.give", lines["ASSUMED"])
        self.assertIn("attack.flay.order", lines["ASSUMED"])
        self.assertIn("timed.hypochondria", [line for line in text.splitlines() if line.startswith("SWEEP")][0])



def fork_text(key, at, then, extra=(), median=True):
    code, text = run(["--log", key, "--at", str(at), "--then"] + list(then) + (["--median"] if median else []) + list(extra))
    assert code == 0
    return text


def rows_of(text, who_action):
    """The timeline rows whose action column starts with who_action, as (t, line)."""
    out = []
    for line in text.splitlines():
        parts = line.split()
        if len(parts) > 2 and " ".join(parts[1:]).startswith(who_action):
            try:
                out.append((float(parts[0]), line))
            except ValueError:
                pass
    return out


def lines_starting(text, head):
    return [line for line in text.splitlines() if line.startswith(head)]


class ForkState(unittest.TestCase):
    """The fork starts from the row's own clocks and defences (round 2 of the review)."""

    def test_equilibrium_from_the_cost_line(self):
        # Reviews RUL-1, LUA-N2-4: Z5 1386 shield, 1387 'Equilibrium used: 3.40s.', prompt 1389 '-x-'. Salt needs eq.
        text = fork_text("Z5", 1389, ["dstab curare kalmia"])
        self.assertIn("equilibrium spent 3.40 s at row 1387 (the game's cost line): back at +3.40", text)
        self.assertEqual([t for t, _ in rows_of(text, "V salt") if t < 3.40], [])
        # Review N2-3: X 4366 'Equilibrium used: 3.40s.', prompts 'xT'. Accelerate needs eq.
        text = fork_text("X", 4367, ["dstab curare kalmia"])
        self.assertEqual([t for t, _ in rows_of(text, "V accelerate") if t < 3.40], [])
        # az prints no prompt flags: the cost line of row 1259's shield (4.00 s) holds FITNESS until +3.82.
        text = fork_text("az", 1270, ["flay shield", "wait 10"])
        self.assertIn("equilibrium spent 4.00 s at row 1259 (the game's cost line): back at +3.82", text)
        self.assertEqual([t for t, _ in rows_of(text, "V FITNESS") if t < 3.82], [])

    def test_quicksilver_holds_the_bite(self):
        # Review N2-1: X 764 hardens the quicksilver coating; it lasts until the FLAY at 817.
        text = fork_text("X", 765, ["bite kalmia"])
        self.assertIn("sileris up (row 764)", text)
        self.assertIn("bite kalmia [sileris]", text)

    def test_the_aura_line_proves_rebounding(self):
        # Review N2-7: X 716 'The attack rebounds off your aura of protection!' after the DSTAB at 713.
        text = fork_text("X", 717, ["dstab curare kalmia"])
        self.assertIn("rebounding up (row 716)", text)
        self.assertIn("dstab curare kalmia [rebounded", text)

    def test_a_kept_shield_comes_back(self):
        # Review LUA-N2-5: az FLAYs the shield at 2055; the logger raised it again at 2196. A fork at 2100 raises it.
        text = fork_text("az", 2100, ["dstab curare kalmia"] * 4)
        self.assertIn("The logger keeps shield and rebounding", text)
        self.assertIn("the shield comes back one re-raise delay after the FLAY at row 2055", text)
        up = rows_of(text, "V shield.up")
        self.assertTrue(up)
        blocked = [t for t, line in rows_of(text, "A dstab") if "[shield]" in line]
        self.assertTrue(blocked and min(blocked) > up[0][0])

    def test_a_pending_shield_is_drawn_past_the_time_run(self):
        # az 1500 is 7.36 s after the FLAY at 1287, with no shield yet: the re-raise is drawn above 7.36 s, so the BITE at
        # +1.83 still meets the coating (the max(t0, draw) form raised the shield at once).
        text = fork_text("az", 1500, ["dstab curare kalmia", "bite kalmia"])
        up = rows_of(text, "V shield.up")
        self.assertTrue(all(t > 1.83 for t, _ in up), up)
        self.assertIn("bite kalmia [sileris]", text)

    def test_a_smoke_brings_rebounding(self):
        # az 1178 smokes skullcap; rebounding comes up 8.59 s later in the log (az 1270 fork: +3.55 by the model).
        text = fork_text("az", 1270, ["flay shield", "wait 10"])
        self.assertIn("rebounding comes up one clock.rebounding after the skullcap smoke at row 1178", text)
        self.assertEqual([round(t, 2) for t, _ in rows_of(text, "V rebounding.up")], [3.55])
        # A mineral user smokes malachite (rule defence.rebounding.smoke).
        self.assertTrue(rows_of(fork_text("X", 4367, ["dstab curare kalmia"]), "V smoke malachite"))

    def test_a_spent_eat_comes_back_with_its_line(self):
        # Review LUA-N2-6: Z5 864, eat spent at 806. The race has its PHASE (the log's is +0.007).
        text = fork_text("Z5", 864, ["dstab curare kalmia", "dstab curare kalmia"])
        race = lines_starting(text, "RACE row 864->#1")[0]
        self.assertNotIn("no PHASE", race)
        self.assertRegex(race, r"PHASE \+0\.\d\d at the strike")

    def test_the_flay_is_the_next_attack(self):
        # Review N2-5, N2-13: g 1143's DSTAB pairs with the forked FLAY at +0.00, and the first action is at once.
        text = fork_text("g", 1210, ["flay curare", "dstab curare kalmia"])
        self.assertTrue(lines_starting(text, "RACE row 1143->#1  herb"), text)
        self.assertIn("First action at +0.00: one gap after the log's last attack (row 1143, -2.40) is at or before the row.",
                      text)

    def test_a_tie_takes_its_sign_from_the_rows(self):
        # Review LUA-N2-10: a PHASE of 0 with the eat up is -0.00. The eat after it waits the gain delay (0.104).
        text = fork_text("az", 400, ["dstab curare kalmia"] * 3)
        self.assertIn("RACE #1->#2  herb back 1.63 < strike 1.83: herb first by 0.20 (PHASE -0.00 at the strike).", text)

    def test_the_gap_rule_is_named(self):
        # Review N2-10: a fork names the gap it rests on. A numeric --gap is the run's own input and rests on no rule (it
        # listed attack.gap.own as ASSUMED, and after the spar as SWEEP, though the run never read that rule).
        text = fork_text("Z5", 204, ["dstab curare vernalius"], extra=["--gap", "1.6"])
        self.assertIn("Gap 1.600 from --gap: the run's own input, not a rule.", text)
        for head in ("ASSUMED", "SWEEP"):
            self.assertNotIn("attack.gap.own", lines_starting(text, head)[0])
        self.assertEqual(lines_starting(text, "GAP"), [])
        text = fork_text("Z5", 204, ["dstab curare vernalius"])
        self.assertIn("attack.gap.others.dstab", lines_starting(text, "GAP")[0])
        self.assertNotIn("attack.gap.others.dstab", lines_starting(text, "SWEEP")[0])
        # --gap raw rests on our measured gap, and names it as other Serpents' gap is named.
        text = fork_text("Z5", 204, ["dstab curare vernalius"], extra=["--gap", "raw"])
        self.assertIn("attack.gap.own (MEASURED, not usable): its median 1.97 only", lines_starting(text, "GAP")[0])
        self.assertIn("First action at +1.97: one gap (1.97 s) after the log's last attack", text)
        self.assertIn("Gap raw: 1.965 before every action", text)

    def test_the_first_gap_is_drawn(self):
        # Review LUA-N2-14: the first forked DSTAB moved with the seed only after it, not itself.
        firsts = set()
        for seed in ("2", "3", "4"):
            text = fork_text("Z5", 204, ["dstab curare vernalius", "dstab curare kalmia"], extra=["--seed", seed],
                             median=False)
            firsts.add(rows_of(text, "A dstab")[0][0])
        self.assertGreater(len(firsts), 1)

    def test_a_printed_tick_is_not_the_phase_rule(self):
        # Review TC-05: the phase comes from row 717, so class.dagaz.phase is not used.
        text = fork_text("az", 1508, ["dstab curare kalmia"])
        self.assertNotIn("class.dagaz.phase", lines_starting(text, "ASSUMED")[0])
        self.assertNotIn("class.dagaz.phase", lines_starting(text, "ALT")[0])


class RunNotes(unittest.TestCase):
    """The lines under a run (round 2 of the review)."""

    def scripted(self, *script, extra=(), median=True):
        code, text = run(["--victim", "runewarden", "--gap", "1.83"] + (["--median"] if median else []) + list(extra) +
                         ["--script"] + list(script))
        self.assertEqual(code, 0)
        return text

    def test_race_odds_are_keyed_by_the_race(self):
        # Reviews N2-4, LUA-N2-2: a shield blocks a different DSTAB in another seed, so the list position mixed races.
        script = ["flay shield"] + ["dstab curare kalmia"] * 2 + ["flay shield"] + ["dstab curare kalmia"] * 3
        text = self.scripted(*script, extra=["--defences", "shield", "--seeds", "40"], median=False)
        lines = text.splitlines()
        for k, line in enumerate(lines):
            if not line.startswith("RACE"):
                continue
            label = line.split()[1]
            nxt = lines[k + 1].strip()
            self.assertIn("the race %s is in" % label, nxt)
            if label.endswith("->-"):
                self.assertTrue(nxt.startswith("MODEL: the race"), nxt)

    def test_no_shield_rules_without_a_shield(self):
        # Review N2-11.
        code, text = run(["--victim", "paladin", "--gap", "1.83", "--median", "--defences", "rebounding", "--script",
                          "dstab curare kalmia", "dstab curare kalmia"])
        self.assertNotIn("defence.shield.cost", text)
        self.assertNotIn("defence.shield.reraise", text)

    def test_sweep_says_what_ran(self):
        # Review LUA-N2-8.
        self.assertTrue(lines_starting(self.scripted("dstab curare kalmia", median=False),
                                       "SWEEP   (MEASURED, not usable; drawn over the measured spread)"))
        self.assertTrue(lines_starting(self.scripted("dstab curare kalmia"), "SWEEP   (MEASURED, not usable; the median ran)"))

    def test_the_horizon_is_named(self):
        # Review LUA-N2-3: 34 DSTABs at 1.83 s; the 34th is due at 60.39.
        text = self.scripted(*(["dstab curare kalmia"] * 34))
        self.assertIn("HORIZON 1 of the 34 actions did not run", text)
        self.assertTrue(lines_starting(text, "RACE 33->-  unpaired: the horizon cut the script"))

    def test_a_give_shows_the_next_action(self):
        # Review LUA-N2-11: the give row's A column showed its own time.
        text = self.scripted("dstab curare kalmia", "give stupidity", "dstab gecko slike")
        give = rows_of(text, "W give stupidity")[0][1]
        self.assertEqual(give.split("|")[0].split()[-1], "3.66")

    def test_no_channel_is_named(self):
        # Review RUL-5: the engine runs no lungs or elixir channel.
        text = self.scripted("dstab curare kalmia", extra=["--affs", "pressure", "crackedribs"])
        self.assertIn("so only a random cure (the tree, a class cure) can take them.",
                      lines_starting(text, "NO CHANNEL crackedribs (elixir):")[0])
        # Review R3-fork-10: pressure has no_random_cure and is in no random pool, so nothing in the engine cures it.
        self.assertIn("nothing in the engine cures them", lines_starting(text, "NO CHANNEL pressure (lungs):")[0])

    def test_the_alternatives_that_ran(self):
        # Review RUL-6.
        text = self.scripted("dstab curare kalmia", extra=["--random-pool", "package", "--flay-order", "auto"],
                             median=False)
        alt = lines_starting(text, "ALT")[0]
        self.assertIn("random_cure.pool = the package's tree pool", alt)
        # Review RUL-6 residual: no FLAY ran, so the FLAY order's alternative ran nothing.
        self.assertNotIn("attack.flay.order", alt)
        self.assertIn("draw.shape", lines_starting(text, "ASSUMED")[0])
        text = self.scripted("flay curare", extra=["--flay-order", "auto"], median=False)
        self.assertIn("attack.flay.order = auto", lines_starting(text, "ALT")[0])
        text = self.scripted("dstab curare kalmia", extra=["--clock-draw", "normal"], median=False)
        self.assertIn("draw.shape = normal", lines_starting(text, "ALT")[0])

    def test_both_arms_count_for_the_true_label(self):
        # Review LUA-N2-1: the engine's arm names (brokenleftarm) count, as kb_replay's leftarm1 does.
        code, text = run(["--victim", "alchemist", "--gap", "1.83", "--median", "--affs", "asthma", "slickness", "anorexia",
                          "impatience", "paralysis", "--script", "dstab epteth epteth"])
        self.assertIn("LABELS soft at 0.00, true at 0.00", text)

    def test_drawn_clocks_stay_in_their_range(self):
        # Review LUA-N2-7: seed 4 drew a FITNESS lockout of 10.07 against a measured max of 9.969.
        rules = tc.load_rules()
        model, _ = tc.build_model(rules, tc.profile("runewarden"))
        engine = tc.Engine()
        m = engine.table(model)
        # Only FITNESS can take the asthma: anorexia shuts the eat, slickness shuts the salve and impatience shuts the
        # focus, so nothing cures the anorexia and the eat stays shut. With anorexia alone, a fast drawn salve
        # (ssc.delay.gain runs down to 0.006 s) let the eat take the asthma first in some seeds.
        script = engine.script(["give asthma anorexia slickness impatience", "wait 12"], m)
        env = {"median": False, "gap": 1.83, "gapSd": 0.09, "defences": {}, "tree": "now", "tail": 1, "horizon": 30,
               "snap": False}
        fit = rules["rules"]["clock.fitness"]["value"]
        for seed in range(1, 41):
            out = engine.run({"t0": 0.0, "affs": [], "firstAt": 0.0, "ready": {"tree": 60.0}}, script, m, env, seed)
            fired = [e["t"] for e in out["events"] if e["kind"] == "classcure" and e["name"] == "fitness"]
            back = [e["t"] for e in out["events"] if e["kind"] == "recover" and e["name"] == "fitness"]
            self.assertTrue(fired and back, seed)
            self.assertTrue(fit["min"] - 1e-9 <= back[0] - fired[0] <= fit["max"] + 1e-9, (seed, back[0] - fired[0]))

    def test_the_log_marks_a_late_row(self):
        # Review EV-3: Z5 5626-5631 come after the last prompt; their time is a floor.
        code, text = run(["--log", "Z5", "--from", "5580", "--to", "5640"])
        late = [line for line in text.splitlines() if line.strip()[:4] in ("5626", "5628", "5631")]
        self.assertTrue(late)
        self.assertTrue(all(line.split()[1].startswith(">=") for line in late), late)
        self.assertIn("A time with >= is a floor", text)


class RoundThree(unittest.TestCase):
    """Round 3 of the review: the fork's defences and clocks, the rule lines, and the run's edges."""

    def test_no_flay_no_shield(self):
        # R3-fork-1: X 1012, shield down (row 952) with no FLAY on its way. The log shows no shield for 43.9 s.
        text = fork_text("X", 1012, ["dstab curare kalmia"] * 4)
        self.assertEqual(rows_of(text, "V shield.up"), [])
        self.assertNotIn("re-raise delay", text)

    def test_the_logger_dropping_its_shield_is_not_a_flay(self):
        # R3-fork-2: Z5 78 'Your action causes the nearly invisible magical shield around you to fade away.' The log's
        # DSTAB at row 328 (+3.65) landed, and so does the forked one at +3.66.
        text = fork_text("Z5", 204, ["dstab curare vernalius", "dstab curare kalmia"])
        self.assertNotIn("after the FLAY at row 78", text)
        self.assertEqual(rows_of(text, "V shield.up"), [])
        self.assertTrue(lines_starting(text, "RACE #1->#2  strike 3.66"), text)

    def test_an_impulse_cost_adds_to_the_open_one(self):
        # R3-fork-5, RUL-2, R4-fork-1: X 529 'Equilibrium used: 3.40s.' and X 575 '0.85s.', after 'Your equilibrium is
        # thrown off by an awakened mental impulse' (X 574), came back together at X 638, +1.30 after row 606.
        # Accelerate needs equilibrium.
        text = fork_text("X", 606, ["dstab curare kalmia"])
        self.assertIn("equilibrium spent 3.40 s at row 529 and 0.85 s at row 575 after an impulse, added (the game's cost"
                      " lines): back at +1.25", text)
        self.assertEqual([t for t, _ in rows_of(text, "V accelerate") if t < 1.25], [])

    def test_a_down_flag_with_no_return_keeps_it_down(self):
        # RUL-1 residual: Z5 5468-5590 show equilibrium down (disrupted), and the logger dies before it comes back.
        text = fork_text("Z5", 5500, ["dstab curare kalmia"] * 2)
        self.assertIn("equilibrium down at prompt row 5500 with no cost line, and no later line gives its return: the fork"
                      " keeps it down", text)
        self.assertEqual(rows_of(text, "V salt"), [])

    def test_no_fork_after_the_last_prompt(self):
        # R3-fork-7: Z5 5631 is the death line, after the last prompt (5590).
        with self.assertRaises(SystemExit) as cm:
            tc.main(["--log", "Z5", "--at", "5626", "--then", "dstab curare kalmia", "--median"])
        self.assertIn("after the log's last prompt (row 5590)", str(cm.exception))

    def test_a_coating_on_its_way(self):
        # R3-fork-8: Z5 2310 applies quicksilver; it hardens at 2677, +3.02 after row 2600. The third BITE meets it.
        text = fork_text("Z5", 2600, ["bite kalmia", "bite slike", "bite kalmia"])
        self.assertIn("the coating hardens one defence.sileris.harden after the apply at row 2310 (-7.01)", text)
        self.assertEqual([round(t, 2) for t, _ in rows_of(text, "V sileris.up")], [2.99])
        self.assertIn("bite kalmia [sileris]", text)
        self.assertIn("defence.sileris.harden", text)

    def test_a_blocked_pet_bite_proves_the_coating(self):
        # R3-fork-9: X 38-39, the rattlesnake's fangs sink into the waxy coating.
        text = fork_text("X", 60, ["bite kalmia"])
        self.assertIn("sileris up (row 38)", text)
        self.assertIn("bite kalmia [sileris]", text)

    def test_a_median_fork_rests_on_the_shape(self):
        # R3-engine-2: az 1500 has a FLAY 7.36 s old; --median takes the median of the part above that, which the shape
        # sets. Both shapes keep the shield past the BITE (R3-engine-1: the normal shape raised it at +0.00).
        text = fork_text("az", 1500, ["dstab curare kalmia", "bite kalmia"])
        self.assertIn("draw.shape", lines_starting(text, "ASSUMED")[0])
        self.assertEqual([round(t, 2) for t, _ in rows_of(text, "V shield.up")], [4.23])
        text = fork_text("az", 1500, ["dstab curare kalmia", "bite kalmia"], extra=["--clock-draw", "normal"])
        self.assertIn("draw.shape = normal", lines_starting(text, "ALT")[0])
        self.assertTrue(all(t > 1.83 for t, _ in rows_of(text, "V shield.up")))
        self.assertIn("bite kalmia [sileris]", text)
        for seed in ("1", "2", "3"):
            text = fork_text("Z5", 864, ["dstab curare kalmia"], extra=["--clock-draw", "normal", "--seed", seed],
                             median=False)
            self.assertNotIn("longest draw has run out", text)

    def test_the_seeds_of_a_median_page(self):
        # R3-fork-3: the P lines come from drawn runs.
        text = fork_text("Z5", 204, ["dstab curare vernalius", "dstab curare kalmia"], extra=["--seeds", "10"])
        self.assertTrue(lines_starting(text, "SEEDS The MODEL P lines come from 10 drawn runs"))
        self.assertIn("draw.shape", lines_starting(text, "ASSUMED")[0])
        self.assertTrue(lines_starting(text, "SWEEP   (MEASURED, not usable; the median ran; the P lines drew them"))
        text = fork_text("Z5", 204, ["dstab curare vernalius"], extra=["--seeds", "5", "--clock-draw", "normal"])
        self.assertIn("draw.shape = normal", lines_starting(text, "ALT")[0])

    def test_the_gap_line_says_what_is_drawn(self):
        # R3-fork-4: the fork's gap is 1.83 +/- 3 x 0.09, not other Serpents' p10-p90 spread.
        text = fork_text("Z5", 204, ["dstab curare vernalius"], median=False)
        self.assertIn("its median 1.83 only, not its p10-p90 spread; a draw adds +/- 3 x 0.09 s",
                      lines_starting(text, "GAP")[0])

    def test_the_hold_passes_the_horizon(self):
        # R3-engine-3: the eat down at #2 comes back after a 3.7 s horizon; the race stays paired. Both eats before it
        # wait the return delay (0.145): the eat came back with an affliction waiting.
        text = fork_text("Z5", 204, ["dstab curare vernalius", "dstab curare kalmia"], extra=["--horizon", "3.7"])
        self.assertTrue(lines_starting(text, "RACE #1->#2  strike 3.66 < herb back 3.88: strike first by 0.22"), text)

    def test_the_horizon_text_is_for_the_last_race(self):
        # R3-engine-4: #1's next attack ran 16.83 s later; only #3's was cut.
        text = fork_text("Z5", 204, ["dstab curare kalmia", "wait 15", "dstab curare kalmia", "wait 50",
                                     "dstab curare kalmia"])
        self.assertTrue(lines_starting(text, "RACE #1->#3  unpaired: the next attack came 16.83 s later (disengaged)"))
        self.assertTrue(lines_starting(text, "RACE #3->-  unpaired: the horizon cut the script"))

    def test_the_gap_floor(self):
        # LUA-N2-12, R3-engine-5: a gap under the floor ran at the floor (or never) while the page printed the gap.
        for argv in (["--gap", "0"], ["--gap", "-1"], ["--gap", "0.2"], ["--gap", "1.83", "--gap-floor", "0"],
                     ["--gap", "1.83", "--gap-floor", "-5"]):
            with self.assertRaises(SystemExit, msg=argv):
                tc.main(["--victim", "runewarden", "--median"] + argv + ["--script", "flay", "flay"])
        code, text = run(["--victim", "runewarden", "--median", "--gap", "0.2", "--gap-floor", "0.05", "--script", "flay",
                          "flay"])
        self.assertEqual([round(t, 2) for t, _ in rows_of(text, "A flay")], [0.0, 0.2])

    def test_hypochondria_through_a_scripted_run(self):
        # ENG-4: the chain runs from --affs through scripted(). Weariness shuts FITNESS, so nothing cures in time.
        code, text = run(["--victim", "runewarden", "--gap", "1.83", "--median", "--affs", "hypochondria", "anorexia",
                          "slickness", "asthma", "paralysis", "impatience", "weariness", "--script", "wait 8"])
        steps = [(round(t, 2), line.split()[4]) for t, line in rows_of(text, "W hypochondria chain")]
        self.assertEqual(steps[:2], [(3.12, "+nausea"), (6.2, "+lethargy")])
        self.assertIn("timed.hypochondria", lines_starting(text, "SWEEP")[0])

    def test_the_chain_counts_from_the_log(self):
        # TC-03: az 2072 gains hypochondria; at row 2085 the chain's nausea is due at +2.11.
        text = fork_text("az", 2085, ["dstab curare kalmia"])
        self.assertEqual([round(t, 2) for t, _ in rows_of(text, "W hypochondria chain")][:1], [2.11])

    def test_the_dagaz_column(self):
        # TC-05: the next tick, rolled on from row 717, is at +11.09.
        text = fork_text("az", 1508, ["dstab curare kalmia"])
        first = rows_of(text, "A dstab")[0][1]
        self.assertEqual(first.split("|")[1].split()[6], "11.09")

    def test_a_give_names_no_venom(self):
        # TC-07: voyria is a venom and an affliction; a give of it rests on attack.give, not venom.voyria.
        text = fork_text("Z5", 204, ["give voyria"])
        self.assertNotIn("venom.voyria", text)
        self.assertIn("attack.give", lines_starting(text, "ASSUMED")[0])


def log_back(key, at, name):
    """The log's return of bal or eq after the fork's row, as (row, seconds after the fork's start): the first "You have
    recovered" line of it, at its packet's stamp. The stream does not read the Shikudo's per-limb balance lines (g
    889-891), and in g 889-897 the balance comes back and is spent again in one packet, so no prompt shows it up."""
    log = ke.load(key)
    events = ke.stream(log)
    word = "balance" if name == "bal" else "equilibrium"
    t0 = next(ev["t"] for ev in events if ev["row"] >= at and ev["kind"] == "prompt")
    row = next(r.n + 1 for r in log if r.n + 1 > at and r.text.startswith("You have recovered " + word))
    stamp = next(ev["t"] for ev in events if ev["row"] >= row and ev["kind"] == "prompt")
    return row, stamp - t0


class RoundFour(unittest.TestCase):
    """Round 4 of the review: the cost lines, slickness and the coating, and the CLI's own lines."""

    def test_a_second_cost_line_ends_the_open_one(self):
        # R4-fork-1: a CONCENTRATE after disrupted (az 2995, Z5 4970) and the Shikudo's unread per-limb recoveries
        # (g 811). Summing the costs put az 3000 at +4.05, Z5 4980 at +1.16 and g 850 at +1.80.
        for key, at, name, want, words in (
                ("az", 3000, "eq", 1.91, "equilibrium spent 2.00 s at row 2995, which ends the open cost of row 2960"),
                ("Z5", 4980, "eq", 0.39, "equilibrium spent 1.70 s at row 4970, which ends the open cost of row 4920"),
                ("g", 850, "bal", 1.52, "balance spent 2.10 s at row 811, which ends the open cost of row 726")):
            text = fork_text(key, at, ["dstab curare kalmia"])
            self.assertIn("%s (the game's cost line): back at %+.2f." % (words, want), text)
            row, back = log_back(key, at, name)
            self.assertLess(abs(back - want), 0.12, (key, row, back))

    def test_slickness_strips_the_coating_in_a_fork(self):
        # R4-engine-1: X 60 has the coating up (row 38). The gecko DSTAB's slickness strips it, so the BITE lands. In
        # the logs, 8 of 8 slickness gains with the coating up sloughed it (X 144-146).
        bite = rows_of(fork_text("X", 60, ["dstab curare gecko", "bite kalmia"]), "A bite kalmia")
        self.assertEqual(len(bite), 1)
        self.assertNotIn("[sileris]", bite[0][1])
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "x60.jsonl")
            fork_text("X", 60, ["dstab curare gecko", "bite kalmia"], extra=["--jsonl", path])
            with open(path, encoding="utf-8") as fh:
                names = [json.loads(line)["name"] for line in fh if line.strip()]
        self.assertIn("sileris.down", names)

    def test_the_fork_gap_meets_the_floor(self):
        # R4-cli-1, R4-docs-1: a fork with no --gap runs 1.83; a --gap-floor above it ran every gap at the floor while
        # the page printed 1.83.
        with self.assertRaises(SystemExit) as cm:
            tc.main(["--log", "Z5", "--at", "204", "--then", "dstab curare kalmia", "--median", "--gap-floor", "2.5"])
        self.assertIn("the fork's gap 1.83 (other Serpents' median; no --gap) is under --gap-floor 2.50",
                      str(cm.exception))
        # R4-docs-5: a floor from --gap-floor is named as such, not as BUNDLED.
        with self.assertRaises(SystemExit) as cm:
            tc.main(["--victim", "runewarden", "--gap", "0.4", "--gap-floor", "0.5", "--median", "--script",
                     "dstab curare kalmia"])
        self.assertIn("--gap 0.4 is under --gap-floor 0.50", str(cm.exception))
        self.assertNotIn("BUNDLED", str(cm.exception))

    def test_no_fork_without_a_prompt_after_the_row(self):
        # R4-fork-2: X rows 6614-6631 come after X's last prompt (6613) and make no event; 6620 is 'You have slain
        # Archaeon.'
        for at in (6625, 99999):
            with self.assertRaises(SystemExit) as cm:
                tc.main(["--log", "X", "--at", str(at), "--then", "dstab curare kalmia", "--median"])
            self.assertIn("after the log's last prompt (row 6613)", str(cm.exception))
        self.assertIn("START at the stamp of row 6613.", fork_text("X", 6613, ["dstab curare kalmia"]))

    def test_the_seeds_line_takes_the_arguments(self):
        # R4-cli-2, R4-docs-3: the drawn runs take --tree-pick and --gap-sd, and draw the first Dagaz tick.
        code, text = run(["--victim", "runewarden", "--gap", "1.83", "--median", "--seeds", "5", "--tree-pick",
                          "priority", "--gap-sd", "0", "--script", "dstab curare kalmia", "dstab curare kalmia"])
        seeds = lines_starting(text, "SEEDS")[0]
        self.assertIn("the tree's pick by priority (--tree-pick priority)", seeds)
        self.assertIn("the gap fixed at 1.83 s (--gap-sd 0)", seeds)
        self.assertIn("the first Dagaz tick drawn over one period (class.dagaz.phase)", seeds)
        self.assertIn("tree.pick = priority.", lines_starting(text, "ALT")[0])
        self.assertIn("gap fixed)", text)
        # A fork whose Dagaz phase comes from the log draws no tick.
        seeds = lines_starting(fork_text("az", 1508, ["dstab curare kalmia"], extra=["--seeds", "5"]), "SEEDS")[0]
        self.assertNotIn("Dagaz", seeds)
        self.assertIn("the tree's pick random (rule tree.pick)", seeds)

    def test_the_horizon_line(self):
        # R4-docs-7: '%.0f' printed 2.5 as '2 s'. The run holds past the horizon only for an eat down at the last action
        # that ran (round 5: the hold clause printed on every cut). Here the eat came back at 1.67, before that action.
        code, text = run(["--victim", "runewarden", "--gap", "1.83", "--median", "--horizon", "2.5", "--script",
                          "dstab curare kalmia", "dstab curare kalmia", "dstab curare kalmia"])
        self.assertEqual(lines_starting(text, "HORIZON"), [
            "HORIZON 1 of the 3 actions did not run: the script stops at the horizon, 2.50 s after its start (--horizon)."
            " No eat that was down at its last action is still down at the horizon, so the run stops there."])
        # Z5 204: the eat is down at the DSTAB at +3.66 and comes back at +3.88, after the 3.7 s horizon.
        text = fork_text("Z5", 204, ["dstab curare vernalius", "dstab curare kalmia", "dstab curare kalmia"],
                         extra=["--horizon", "3.7"])
        self.assertIn("The run then holds to +3.88, when the eat that was down at its last action comes back.",
                      lines_starting(text, "HORIZON")[0])

    def test_a_cut_give_is_not_why_a_race_is_unpaired(self):
        # R5-cli-3: the horizon cut only a give, so the race is unpaired for its own reason.
        code, text = run(["--victim", "runewarden", "--gap", "1.83", "--median", "--horizon", "1.5", "--script",
                          "dstab curare kalmia", "give paralysis"])
        self.assertTrue(lines_starting(text, "RACE 1->-  unpaired: no attack after it within 10 s"), text)
        code, text = run(["--victim", "runewarden", "--gap", "1.83", "--median", "--horizon", "1.5", "--script",
                          "dstab curare kalmia", "dstab curare kalmia"])
        self.assertTrue(lines_starting(text, "RACE 1->-  unpaired: the horizon cut the script before another attack"),
                        text)

    def test_a_later_row_of_a_wrapped_prompt(self):
        # R5-fork-1: X 590 is the board row of prompt 589 (span 2); az 3896 is the second row of the last prompt, 3895.
        text = fork_text("X", 590, ["dstab curare kalmia"])
        self.assertIn("START at the stamp of row 589. Row 590 is a later row of prompt row 589.", text)
        self.assertIn("START at the stamp of row 3895. Row 3896 is a later row of prompt row 3895.",
                      fork_text("az", 3896, ["dstab curare kalmia"]))

    def test_a_pending_coating_under_slickness(self):
        # R5-fork-1b: az 3779 has slickness on the board and the az 3616 apply pending; it never hardened in the log.
        text = fork_text("az", 3779, ["dstab curare kalmia", "bite kalmia"])
        self.assertIn("after the apply at row 3616 (-9.78), unless slickness is on at that mark (rule"
                      " defence.sileris.slickness_harden; slickness is on the board)", text)
        self.assertEqual(rows_of(text, "V sileris.up"), [])
        self.assertEqual([round(t, 2) for t, _ in rows_of(text, "W sileris.unhardened")], [0.22])
        self.assertNotIn("[sileris]", rows_of(text, "A bite kalmia")[0][1])
        # Round 6: the fork's own script lands the slickness. az 1191's apply is due at +10.00; the whip's slickness
        # lands at +9.93 and is cured at +10.07, so the coating never comes, and the timeline says why.
        text = fork_text("az", 1211, ["wait 8.1", "flay rebounding gecko", "bite kalmia"])
        self.assertIn("after the apply at row 1191 (+0.00), unless slickness is on at that mark (rule"
                      " defence.sileris.slickness_harden)", text)
        self.assertEqual([round(t, 2) for t, _ in rows_of(text, "W sileris.unhardened")], [10.0])
        self.assertNotIn("[sileris]", rows_of(text, "A bite kalmia")[0][1])

    def test_fratricide_comes_from_the_pet(self):
        # serpent.md once said how fratricide is given is unknown. All 46 fratricide gains in the four logs come within
        # three rows after the pet snake's bite line (Z5 900-901; some loggers print their tag in between).
        found = []
        for key in ke.KEYS:
            log = ke.load(key)
            texts = {r.n + 1 + k: line for r in log for k, line in enumerate(r.text.splitlines())}
            for ev in ke.stream(log):
                if ev["kind"] == "gain" and ev["name"] == "fratricide":
                    back = [texts.get(ev["row"] - j, "") for j in (1, 2, 3)]
                    found.append(any("sinks its fangs into your neck" in b or "potent dose of toxin." in b for b in back))
        self.assertEqual(found, [True] * 46)

    def test_no_action_before_the_horizon(self):
        # Round 6: the horizon cut every action, so no action ran.
        text = fork_text("X", 5340, ["dstab curare kalmia", "bite kalmia"], extra=["--horizon", "1.0"])
        self.assertIn("No action ran before the horizon, so the run stops there.", lines_starting(text, "HORIZON")[0])

    def test_a_flay_whip_of_slickness_strips_the_coating(self):
        # R5-engine-1: X 5340, coating up (row 5286), shield and rebounding down. A named FLAY whose defence is gone
        # strips nothing, but its gecko lands slickness, and that strips the coating, so the BITE lands.
        text = fork_text("X", 5340, ["flay shield gecko", "bite kalmia"])
        self.assertNotIn("[sileris]", rows_of(text, "A bite kalmia")[0][1])

    def test_the_gap_sd(self):
        # R5-cli-2: a negative sd still drew the gap while the page said it was fixed.
        with self.assertRaises(SystemExit) as cm:
            tc.main(["--victim", "runewarden", "--gap", "1.83", "--gap-sd=-0.3", "--script", "dstab curare kalmia"])
        self.assertIn("--gap-sd must be a finite 0 or more", str(cm.exception))
        for bad in ("--gap-sd=inf", "--gap-sd=nan"):
            with self.assertRaises(SystemExit):
                tc.main(["--victim", "runewarden", "--gap", "1.83", bad, "--script", "dstab curare kalmia"])
        with self.assertRaises(SystemExit) as cm:
            tc.main(["--victim", "runewarden", "--gap", "inf", "--script", "dstab curare kalmia"])
        self.assertIn("--gap must be a finite number", str(cm.exception))
        # R5-cli-1: with --gap-sd 0 no line says the gap is drawn.
        code, text = run(["--victim", "runewarden", "--gap", "1.83", "--gap-sd", "0", "--script", "dstab curare kalmia"])
        self.assertIn("the gap is fixed at 1.83 s (--gap-sd 0)", text.splitlines()[1])
        text = fork_text("Z5", 204, ["dstab curare kalmia"], extra=["--gap-sd", "0"], median=False)
        self.assertIn("one gap (1.83 s) after the log's last attack", text)

    def test_a_gain_line_of_a_held_affliction(self):
        # EV-6 (c): the reverse direction. 67 gain lines name an affliction already on the board a fork reads there (the
        # prompt, plus the gain and cure lines after it), and no logger tag is within two rows of any of them. The 17
        # fratricide lines come right after the pet's bite (Z5 900-901). The stream keeps them as gains: the board
        # already holds them, so a fork's start does not change. g 320 and 1479 are darkshade lines under DARK.
        tag = re.compile(r"^(?:\[AFF\]: (.+?)|You have been afflicted with (.+?)\.)\s*$")
        held, tagged, frat = {}, [], []
        for key in ke.KEYS:
            log = ke.load(key)
            texts = {r.n + 1 + k: line for r in log for k, line in enumerate(r.text.splitlines())}
            terms, rows = set(), []
            for ev in ke.stream(log):
                if ev["kind"] == "prompt":
                    terms = set(tc.board(log.family, ev["args"])[0])
                elif ev["kind"] == "gain":
                    if ev["name"] in terms and "burn" not in ev["args"]:
                        rows.append((ev["row"], ev["name"]))
                        near = [tag.match(texts.get(r, "")) for r in range(ev["row"] - 2, ev["row"] + 3)]
                        if any(m and (m.group(1) or m.group(2)).lower() == ev["name"] for m in near):
                            tagged.append((key, ev["row"]))
                        if ev["name"] == "fratricide":
                            frat.append("sinks its fangs into your neck" in texts.get(ev["row"] - 1, "")
                                        or "potent dose of toxin." in texts.get(ev["row"] - 1, ""))
                    terms.add(ev["name"])
                elif ev["kind"] == "lose":
                    terms.discard(ev["name"])
            held[key] = rows
        self.assertEqual({k: len(v) for k, v in held.items()}, {"az": 14, "Z5": 26, "g": 10, "X": 17})
        self.assertEqual(tagged, [])
        self.assertEqual(frat, [True] * 17)
        self.assertIn((320, "darkshade"), held["g"])
        self.assertIn((1479, "darkshade"), held["g"])
        # az 1207 is a new gain: the eat at az 1188 cured paralysis in that packet, and az 1206 is its tag.
        self.assertNotIn((1207, "paralysis"), held["az"])


def scripted_text(script, gap="1.83", extra=()):
    code, text = run(["--victim", "runewarden", "--gap", gap, "--median"] + list(extra) + ["--script"] + list(script))
    assert code == 0
    return text


class SparRules(unittest.TestCase):
    """The rules from the 2026-11-07 spar on the page: the --gap presets (lenses TC1, TC3), the IMPULSE and the Ekanelia
    reactions, the two SSC delay cases with Saibel's alternative, and the small-margin rule."""

    @classmethod
    def setUpClass(cls):
        cls.rules = tc.load_rules()

    def test_each_preset_runs_its_gap(self):
        r = self.rules["rules"]
        want = {"raw": r["attack.gap.own"]["value"]["median"], "queue": r["attack.cost.own.dstab"]["value"]["median"],
                "queue-late": r["attack.cost.own.dstab"]["first_reply"],
                "others": r["attack.gap.others.dstab"]["value"]["median"]}
        self.assertEqual(want, {"raw": 1.965, "queue": 1.634, "queue-late": 1.75, "others": 1.83})
        for name, gap in want.items():
            text = scripted_text(["dstab curare kalmia", "dstab curare kalmia"], gap=name)
            self.assertEqual([t for t, _ in rows_of(text, "A dstab")], [0.0, round(gap, 2)], name)
            self.assertTrue(lines_starting(text, "GAP   %s:" % name), name)
            self.assertTrue(lines_starting(text, "OURS  from the 2026-11-07 spar: raw 1.965"), name)
        # queue: each kind at our cost; an impulse takes the impulse's bite, as no plain BITE is measured.
        gap, gaps = tc.preset_gap(self.rules, "queue")
        self.assertEqual((gap, gaps), (1.634, {"dstab": 1.634, "bite": 1.563, "impulse": 1.563, "flay": 1.53,
                                               "give": 1.634}))
        self.assertEqual(tc.preset_gap(self.rules, "raw"), (1.965, {}))

    def test_queue_late_runs_the_first_reply_costs(self):
        # Review KE-3: the queue floor is 1.634 from the cost line and 1.750 from the round's first reply, and where the
        # 0.09 s step falls is open. queue-late runs the other side, and the page names both.
        gap, gaps = tc.preset_gap(self.rules, "queue-late")
        self.assertEqual((gap, gaps), (1.75, {"dstab": 1.75, "bite": 1.676, "impulse": 1.676, "flay": 1.65,
                                              "give": 1.75}))
        # Each value is the rule's own alternative.
        for key in ("attack.cost.own.dstab", "attack.cost.own.bite", "attack.cost.own.flay"):
            rule = self.rules["rules"][key]
            self.assertIn(rule["first_reply"], rule["alt"], key)
        ours = lines_starting(scripted_text(["dstab curare kalmia"], gap="queue"), "OURS")[0]
        self.assertIn("queue floor 1.634 from the cost line or 1.750 from the round's first reply", ours)
        self.assertIn("an impulse round 1.563 or 1.676", ours)
        # The verdict flips across the step: strike first at the queue floor, herb first from the first reply.
        script = ["dstab curare kalmia"] * 3
        early = run(["--victim", "depthswalker", "--gap", "queue", "--median", "--script"] + script)[1]
        late = run(["--victim", "depthswalker", "--gap", "queue-late", "--median", "--script"] + script)[1]
        self.assertIn("strike first", lines_starting(early, "RACE 1->2")[0])
        self.assertIn("herb first", lines_starting(late, "RACE 1->2")[0])
        self.assertTrue(lines_starting(early, "MARGIN"))
        self.assertTrue(lines_starting(late, "MARGIN"))
        # The ALT line says the first-reply value ran, and each GAP line names the other side.
        text = scripted_text(["flay", "dstab curare kalmia", "impulse masochism monkshood"], gap="queue-late")
        alt = lines_starting(text, "ALT")[0]
        for key, v in (("attack.cost.own.dstab", "1.750"), ("attack.cost.own.bite", "1.676"),
                       ("attack.cost.own.flay", "1.650")):
            self.assertIn("%s = %s, timed from the round's first reply (--gap queue-late)" % (key, v), alt)
        self.assertIn("--gap queue times them from the cost line", lines_starting(text, "GAP")[0])
        queue = scripted_text(["dstab curare kalmia"], gap="queue")
        self.assertIn("--gap queue-late times them", lines_starting(queue, "GAP")[0])
        self.assertNotIn("first reply (--gap queue-late)", lines_starting(queue, "ALT")[0])

    def test_others_gives_each_kind_its_gap(self):
        # Review KE-6: other Serpents' FLAY and BITE gaps are measured too (attack.gap.others.flay, .bite).
        r = self.rules["rules"]
        gap, gaps = tc.preset_gap(self.rules, "others")
        bite, flay = r["attack.gap.others.bite"]["value"]["median"], r["attack.gap.others.flay"]["value"]["median"]
        self.assertEqual((bite, flay), (1.69, 1.642))
        self.assertEqual((gap, gaps), (1.83, {"dstab": 1.83, "bite": bite, "impulse": bite, "flay": flay, "give": 1.83}))
        text = scripted_text(["flay", "dstab curare kalmia", "impulse masochism monkshood", "dstab curare kalmia"],
                             gap="others")
        self.assertEqual([t for t, _ in rows_of(text, "A dstab")], [1.64, 5.16])
        self.assertEqual([t for t, _ in rows_of(text, "A impulse")], [3.47])
        line = lines_starting(text, "GAP   others:")[0]
        # Review F52: every BITE of theirs came with an IMPULSE, so the BITE gap is an impulse-round gap.
        self.assertIn("BITE or IMPULSE 1.690 (n=21; each of their BITEs came with an IMPULSE, gaze.command in its packet,"
                      " so this is an impulse-round gap; no plain BITE of theirs is measured)", line)
        self.assertNotIn("no impulse of theirs is measured", line)
        self.assertIn("FLAY 1.642 (n=64)", line)
        named = {row.split()[1] for row in lines_starting(text, "GAP     ")}
        self.assertEqual(named, {"attack.gap.others.dstab", "attack.gap.others.bite", "attack.gap.others.flay"})

    def test_every_bite_of_theirs_came_with_an_impulse(self):
        # Review F52: each of the 22 BITEs in the four victim-seat logs has the same Serpent's gaze.command line in its
        # packet (az 1238-1242, Z5 534-537, X 293-296), so attack.gap.others.bite is an impulse-round gap.
        total, with_gaze = 0, 0
        for key in ke.KEYS:
            events = ke.stream(ke.load(key))
            for i, ev in enumerate(events):
                if ev["name"] != "bite":
                    continue
                total += 1
                packet = []
                for back in reversed(events[:i]):
                    if back["kind"] == "prompt":
                        break
                    packet.append(back)
                with_gaze += any(b["name"] == "gaze.command" and b.get("who") == ev.get("who") for b in packet)
        self.assertEqual((total, with_gaze), (22, 22))
        # The engine names the impulse's part as a log names that line, so the census of a run counts it the same way.
        counts, _, _ = ke.census(engine_run(["impulse masochism monkshood"])["events"])
        self.assertEqual((counts["bite"], counts["gaze.command"]), (1, 1))
        self.assertNotIn("impulse", counts)

    def test_a_fork_takes_the_gap_of_the_logs_last_attack(self):
        # Review F49: X 545 is a FLAY of the shield, the log's last attack before X 552. Under --gap others the first
        # action comes one FLAY gap (1.642) after it, not the DSTAB's 1.83 (the log's own next attack came at +1.53).
        text = fork_text("X", 552, ["dstab curare kalmia"], extra=["--gap", "others"])
        self.assertIn("First action at +1.64: one gap (1.64 s) after the log's last attack (row 545, +0.00).", text)
        self.assertEqual([t for t, _ in rows_of(text, "A dstab")], [1.64])
        named = {row.split()[1] for row in lines_starting(text, "GAP     ")}
        self.assertEqual(named, {"attack.gap.others.flay", "attack.gap.others.dstab"})
        # Z5 196 is a DSTAB: a forked FLAY comes one DSTAB gap after it, and the page names that gap's rule.
        text = fork_text("Z5", 204, ["flay"], extra=["--gap", "others"])
        self.assertIn("First action at +1.83", text)
        self.assertIn("attack.gap.others.dstab", {row.split()[1] for row in lines_starting(text, "GAP     ")})
        # queue-late: the first action runs at the DSTAB's first-reply cost, and the ALT line says that value ran.
        text = fork_text("Z5", 204, ["impulse masochism monkshood"], extra=["--gap", "queue-late"])
        self.assertIn("First action at +1.75", text)
        self.assertIn("attack.cost.own.dstab = 1.750, timed from the round's first reply", lines_starting(text, "ALT")[0])
        # A numeric --gap and no --gap give one gap for every kind.
        self.assertIn("First action at +1.60", fork_text("X", 552, ["dstab curare kalmia"], extra=["--gap", "1.6"]))
        self.assertIn("First action at +1.83", fork_text("X", 552, ["dstab curare kalmia"]))
        # The floor holds for that first gap too: queue's FLAY gap 1.530 is under a floor of 1.6.
        with self.assertRaises(SystemExit) as cm:
            fork_text("X", 552, ["dstab curare kalmia"], extra=["--gap", "queue", "--gap-floor", "1.6"])
        self.assertIn("a FLAY at row 545) is 1.530, under the gap floor 1.60", str(cm.exception))

    def test_a_first_gap_that_cannot_reach_the_row_decides_nothing(self):
        # az 558 is a FLAY 3.33 s before az 654: one gap after it, even at its longest draw (median + 3 sd, F.gapDraw),
        # lands at or before the row, so neither the floor nor the gap's rules decide anything (deep review, round 7).
        first = "First action at +0.00: one gap after the log's last attack (row 558, -3.33) is at or before the row."
        # queue's FLAY gap 1.530 is under a floor of 1.6, but the floor cannot move the first action: the fork runs.
        text = fork_text("az", 654, ["dstab curare kalmia"], extra=["--gap", "queue", "--gap-floor", "1.6"])
        self.assertIn(first, text)
        # Where it can (X 552, a FLAY at +0.00), the FLAY's cost is a SWEEP rule of the page; here it decides nothing.
        self.assertNotIn("attack.cost.own.flay", text)
        self.assertIn("attack.cost.own.flay", lines_starting(fork_text("X", 552, ["dstab curare kalmia"],
                                                                       extra=["--gap", "queue"]), "SWEEP")[0])
        # A drawn run of waits under --gap others: no FLAY gap rule and no gap noise.
        text = fork_text("az", 654, ["wait 1"], extra=["--gap", "others"], median=False)
        self.assertIn(first, text)
        self.assertNotIn("attack.gap.own.sd", lines_starting(text, "ASSUMED")[0])
        self.assertEqual(lines_starting(text, "GAP     "), [])
        # A wide enough noise can reach the row (1.642 + 3 x 0.6 > 3.33), so then the gap and its noise are listed.
        text = fork_text("az", 654, ["wait 1"], extra=["--gap", "others", "--gap-sd", "0.6"], median=False)
        self.assertIn("attack.gap.own.sd", lines_starting(text, "ASSUMED")[0])
        self.assertEqual({row.split()[1] for row in lines_starting(text, "GAP     ")}, {"attack.gap.others.flay"})

    def test_the_gap_noise_rule_only_when_a_gap_is_drawn_with_noise(self):
        # Review F51: attack.gap.own.sd was listed at --gap-sd 0 and for a script with no gap at all.
        def assumed(argv):
            return lines_starting(run(argv)[1], "ASSUMED")[0]
        base = ["--victim", "runewarden", "--gap", "1.83", "--script", "dstab curare kalmia"]
        self.assertIn("attack.gap.own.sd", assumed(base))
        self.assertNotIn("attack.gap.own.sd", assumed(base + ["--gap-sd", "0"]))
        self.assertNotIn("attack.gap.own.sd", assumed(["--victim", "runewarden", "--gap", "others", "--script", "wait 1"]))
        self.assertNotIn("attack.gap.own.sd", assumed(base + ["--median"]))
        self.assertIn("attack.gap.own.sd", assumed(base + ["--median", "--seeds", "3"]))
        # A fork draws its first gap after the log's last attack, even when only waits follow.
        self.assertIn("attack.gap.own.sd", lines_starting(fork_text("Z5", 204, ["wait 1"], median=False), "ASSUMED")[0])
        self.assertNotIn("attack.gap.own.sd", lines_starting(
            fork_text("Z5", 204, ["wait 1"], extra=["--gap-sd", "0"], median=False), "ASSUMED")[0])

    def test_a_preset_names_its_rules(self):
        script = ["dstab curare kalmia", "impulse stupidity curare", "flay shield", "wait 2"]
        queue = {"attack.cost.own.dstab", "attack.cost.own.bite", "attack.cost.own.flay"}
        for preset, keys in (("raw", {"attack.gap.own"}),
                             ("others", {"attack.gap.others.dstab", "attack.gap.others.bite", "attack.gap.others.flay"}),
                             ("queue", queue), ("queue-late", queue), (None, set())):
            used = set()
            tc.rules_for_actions(self.rules, script, [], used, preset)
            gap_rules = {k for k in used if k.startswith(("attack.gap.", "attack.cost.own.")) and not
                         k.endswith("impulse_eq")}
            self.assertEqual(gap_rules, keys, preset)
        # The FLAY's cost is n=1: a queue run with a FLAY sweeps it, and a numeric --gap rests on no gap rule.
        text = scripted_text(["flay", "dstab curare kalmia"], gap="queue")
        self.assertIn("attack.cost.own.flay", lines_starting(text, "SWEEP")[0])
        text = scripted_text(["dstab curare kalmia", "dstab curare kalmia"], gap="1.6")
        self.assertNotIn("attack.gap.", "".join(lines_starting(text, "ASSUMED") + lines_starting(text, "SWEEP")))
        self.assertEqual(lines_starting(text, "GAP   1.600 from --gap: the run's own input, not a rule."), [
            "GAP   1.600 from --gap: the run's own input, not a rule."])

    def test_a_bad_gap_word_is_refused(self):
        with self.assertRaises(SystemExit), contextlib.redirect_stderr(io.StringIO()) as err:
            tc.main(["--victim", "runewarden", "--gap", "fast", "--script", "dstab curare kalmia"])
        self.assertIn("give a number of seconds, or one of others, queue, queue-late, raw", err.getvalue())

    def test_the_floor_reads_the_gaps_the_script_runs(self):
        # queue: the DSTAB's 1.634 meets a floor of 1.6; the impulse round 1.563 does not.
        text = scripted_text(["dstab curare kalmia", "dstab curare kalmia"], gap="queue", extra=["--gap-floor", "1.6"])
        self.assertEqual([t for t, _ in rows_of(text, "A dstab")], [0.0, 1.63])
        with self.assertRaises(SystemExit) as cm:
            tc.main(["--victim", "runewarden", "--gap", "queue", "--gap-floor", "1.6", "--median", "--script",
                     "dstab curare kalmia", "impulse stupidity curare"])
        self.assertIn("--gap queue (its shortest gap in this script, 1.563) is under --gap-floor 1.60", str(cm.exception))

    def test_an_impulse_lands_its_suggestion_and_its_bite(self):
        text = scripted_text(["dstab curare kalmia", "impulse amnesia monkshood", "dstab gecko slike"], gap="queue")
        (t, row), = rows_of(text, "A impulse amnesia monkshood")
        self.assertEqual(t, 1.63)
        self.assertIn("+amnesia +disloyalty", row)
        # The next action comes one impulse round (1.563) after it.
        self.assertEqual([t for t, _ in rows_of(text, "A dstab")], [0.0, 3.2])
        assumed = lines_starting(text, "ASSUMED")[0]
        for key in ("attack.impulse", "reaction.monkshood", "venom.monkshood"):
            self.assertIn(key, assumed)
        used = set()
        tc.rules_for_actions(self.rules, ["impulse stupidity curare"], [], used)
        self.assertTrue({"attack.impulse", "attack.impulse.venom", "attack.impulse.suggestions",
                         "attack.cost.own.impulse_eq", "venom.curare"} <= used)
        self.assertNotIn("venom.stupidity", used)
        self.assertNotIn("timed.hypochondria", used)

    def test_an_impulse_gives_a_trivial_suggestion_only(self):
        # Review KE-5: 'impulse masochsim monkshood' ran and landed '+masochsim', which no channel cures.
        r = self.rules["rules"]["attack.impulse.suggestions"]
        self.assertEqual(r["tag"], "READ")
        self.assertEqual(len(r["value"]), 15)
        model, _ = tc.build_model(self.rules, tc.profile("runewarden"))
        self.assertEqual(model["suggestions"], r["value"])
        for word in ("masochsim", "paralysis", "hypochondria", "clumsiness"):
            with self.assertRaises(SystemExit) as cm:
                scripted_text(["impulse %s monkshood" % word])
            self.assertIn("unknown suggestion '%s'" % word, str(cm.exception))

    def test_an_impulse_waits_for_equilibrium(self):
        # Our equilibrium comes back 1.242 s after an impulse (attack.cost.own.impulse_eq): a 1.0 s gap cannot hold it.
        self.assertEqual(self.rules["rules"]["attack.cost.own.impulse_eq"]["value"]["median"], 1.242)
        text = scripted_text(["impulse stupidity curare", "impulse confusion curare", "dstab curare kalmia"], gap="1.0",
                             extra=["--gap-floor", "0.5"])
        self.assertEqual([t for t, _ in rows_of(text, "A impulse")], [0.0, 1.24])
        # A DSTAB needs no equilibrium: it comes one gap after the second impulse.
        self.assertEqual([t for t, _ in rows_of(text, "A dstab")], [2.24])

    def test_the_reactions_on_the_page(self):
        # Loki: with confusion and recklessness on the victim, the bite gives nausea and paralysis (reaction.loki).
        text = scripted_text(["bite loki"], extra=["--affs", "confusion", "recklessness"])
        self.assertIn("+nausea +paralysis", rows_of(text, "A bite loki")[0][1])
        self.assertIn("reaction.loki", lines_starting(text, "ASSUMED")[0])
        self.assertEqual(lines_starting(text, "RANDOM"), [
            "RANDOM  loki gives a random affliction, which the engine does not model: only its reaction (rule"
            " reaction.loki) can land."])
        # Without them, the bite lands nothing: the random affliction is not modelled.
        text = scripted_text(["bite loki", "dstab curare kalmia"])
        self.assertNotIn("+", rows_of(text, "A bite loki")[0][1].split("|")[0][40:])
        # Monkshood: asthma, masochism and weariness give impatience (reaction.monkshood).
        # The change column cuts the third name; the focus column shows the impatience that shuts it.
        text = scripted_text(["impulse stupidity monkshood"], extra=["--affs", "asthma", "masochism", "weariness"])
        row = rows_of(text, "A impulse")[0][1]
        self.assertIn("+stupidity +disloyalty +impa", row)
        self.assertEqual(row.split("|")[1].split()[3], "x:imp")
        # No reaction, no RANDOM line and no reaction rule for a DSTAB.
        text = scripted_text(["dstab curare kalmia"])
        self.assertEqual(lines_starting(text, "RANDOM"), [])
        self.assertNotIn("reaction.", text)
        # A random venom is refused where no reaction can fire: a DSTAB is not a bite.
        with self.assertRaises(SystemExit) as cm:
            scripted_text(["dstab loki curare"])
        self.assertIn("venom 'loki' gives a random affliction: not modelled", str(cm.exception))

    def test_the_ssc_delay_has_two_cases(self):
        model, used = tc.build_model(self.rules, tc.profile("runewarden"))
        self.assertEqual((model["ssc"]["gain"]["median"], model["ssc"]["return"]["median"]), (0.104, 0.145))
        self.assertTrue({"ssc.delay.gain", "ssc.delay.return"} <= used)
        self.assertNotIn("ssc.delay", self.rules["rules"])
        saibel, used = tc.build_model(self.rules, tc.profile("runewarden"), {"ssc_gain": "saibel"})
        # All nine of her open-eat landings, 0.005-0.216 (review KE-2: the one slow case is kept).
        self.assertEqual((saibel["ssc"]["gain"]["median"], saibel["ssc"]["return"]["median"]), (0.055, 0.145))
        self.assertEqual((saibel["ssc"]["gain"]["min"], saibel["ssc"]["gain"]["max"]), (0.005, 0.216))
        self.assertIn("ssc.delay.gain.Saibel", used)
        # Saibel's is an alternative, never the value: the rule names it as one.
        self.assertEqual(self.rules["rules"]["ssc.delay.gain"]["alt"], ["ssc.delay.gain.Saibel"])

    def test_saibel_on_the_page(self):
        text = scripted_text(["dstab curare kalmia"], gap="raw", extra=["--ssc-gain", "saibel"])
        self.assertIn("SSC delay 0.055 on a gain (Saibel's, --ssc-gain saibel), 0.145 on a return.",
                      lines_starting(text, "VICTIM")[0])
        self.assertIn("ssc.delay.gain = ssc.delay.gain.Saibel, one opponent's from our seat (--ssc-gain saibel)",
                      lines_starting(text, "ALT")[0])
        self.assertIn("ssc.delay.gain.Saibel", lines_starting(text, "SWEEP")[0])
        self.assertEqual([t for t, _ in rows_of(text, "V eat")], [0.06])
        text = scripted_text(["dstab curare kalmia"], gap="raw")
        self.assertNotIn("Saibel", text)
        self.assertEqual([t for t, _ in rows_of(text, "V eat")], [0.1])

    def test_a_flay_on_a_missing_defence_takes_the_coating(self):
        # Review KE-1: the spar's opener. 'flay Saibel rebounding curare' found no rebounding (FL 305), ripped the coating
        # (FL 308) and whipped (FL 315). The impulse's bite after it then lands.
        rule = self.rules["rules"]["attack.flay.missing"]
        self.assertEqual((rule["tag"], rule["n"]), ("MEASURED", 1))
        self.assertTrue(rule["value"].startswith("coating"))
        self.assertTrue(rule["alt"][0].startswith("nothing"))
        script = ["flay rebounding curare", "impulse masochism monkshood"]
        res = engine_run(script, start_extra={"defs": {"sileris": True}})
        flay = next(ev for ev in res["events"] if ev["kind"] == "attack")
        self.assertEqual((flay["name"], flay["result"]), ("flay.whip", "flay.missing"))
        self.assertTrue(any(ev["name"] == "sileris.down" for ev in res["events"]))
        bite = next(ev for ev in res["events"] if ev["kind"] == "attack" and ev["name"] == "bite")
        self.assertEqual(bite["result"], "hit")
        # The alternative: the coating stays, and the bite meets it.
        rules = tc.load_rules()
        engine = tc.Engine()
        model, _ = tc.build_model(rules, tc.profile("runewarden"), {"flay_missing": "nothing"})
        self.assertEqual(model["flayMissing"], "nothing")
        m = engine.table(model)
        env = {"median": True, "gap": 1.83, "gapSd": 0, "defences": {}, "tree": "now", "treePick": "random",
               "tail": 2.5, "horizon": 60, "snap": False}
        res = engine.run({"t0": 0.0, "affs": [], "firstAt": 0.0, "defs": {"sileris": True}}, engine.script(script, m), m,
                         env, 1)
        self.assertFalse(any(ev["name"] == "sileris.down" for ev in res["events"]))
        bite = next(ev for ev in res["events"] if ev["kind"] == "attack" and ev["name"] == "bite")
        self.assertEqual(bite["result"], "sileris")

    def test_the_flay_line_on_a_fork(self):
        # X 5320: the coating hardened at X 5286, the shield went at X 5310 and rebounding at X 5313-5317. A forked FLAY of
        # rebounding meets the case, and the page names the rule and its conflict.
        text = fork_text("X", 5320, ["flay rebounding curare", "impulse masochism monkshood"])
        self.assertEqual(lines_starting(text, "FLAY"), [
            "FLAY  1 FLAY(s) at +0.00 named a defence the victim did not have; 1 took the coating (rule"
            " attack.flay.missing: n=1 from our seat, FL 305-308; X 5328 reads the other way, --flay-missing nothing"
            " runs it)."])
        self.assertIn("+masochism +disloyalty", rows_of(text, "A impulse")[0][1])
        text = fork_text("X", 5320, ["flay rebounding curare", "impulse masochism monkshood"],
                         extra=["--flay-missing", "nothing"])
        self.assertIn("0 took the coating", lines_starting(text, "FLAY")[0])
        self.assertIn("attack.flay.missing = nothing (--flay-missing nothing)", lines_starting(text, "ALT")[0])
        self.assertNotIn("disloyalty", rows_of(text, "A impulse")[0][1])
        # No FLAY line, and no rule, when every FLAY found its defence or named none.
        text = fork_text("X", 5320, ["flay curare", "dstab curare kalmia"])
        self.assertEqual(lines_starting(text, "FLAY"), [])
        self.assertNotIn("attack.flay.missing", text)

    def test_a_flay_that_met_no_coating_rests_on_no_flay_rule(self):
        # Review F50: a scripted victim never has the coating, so --flay-missing nothing changed nothing, yet the ALT line
        # said its alternative ran.
        def elsewhere(text):
            return [line for line in text.splitlines() if "attack.flay.missing" in line and not line.startswith("FLAY")]
        text = scripted_text(["flay rebounding curare", "impulse masochism monkshood"], extra=["--flay-missing", "nothing"])
        flay = lines_starting(text, "FLAY")[0]
        self.assertIn("0 took the coating (no coating was up at any of them", flay)
        self.assertNotIn("--flay-missing nothing runs it", flay)
        self.assertEqual(elsewhere(text), [])
        # A bare FLAY strips the coating first, so the named FLAY after it meets none.
        text = fork_text("X", 5320, ["flay curare", "flay rebounding curare", "impulse masochism monkshood"],
                         extra=["--flay-missing", "nothing"])
        self.assertEqual(elsewhere(text), [])

    def test_the_fork_names_our_gaps(self):
        # The review's missing item: the fork's page names our two measured gaps, as the scripted page does.
        text = fork_text("Z5", 204, ["dstab curare vernalius"])
        self.assertEqual(len(lines_starting(text, "OURS  from the 2026-11-07 spar: raw 1.965")), 1)

    def test_the_margin_line(self):
        # Every paired race of the golden example is decided by 0.20 s: UNSETTLED.
        code, text = run(EXAMPLE)
        self.assertTrue(lines_starting(text, "MARGIN  2 of 2 paired races are decided by under 0.5 s: UNSETTLED"))
        # At a 3 s gap the herb is back 1.37 s before the strike: no MARGIN line.
        text = scripted_text(["dstab curare kalmia", "dstab curare kalmia"], gap="3")
        self.assertTrue(lines_starting(text, "RACE 1->2  herb back 1.63 < strike 3.00: herb first by 1.37"))
        self.assertEqual(lines_starting(text, "MARGIN"), [])

if __name__ == "__main__":
    unittest.main()
