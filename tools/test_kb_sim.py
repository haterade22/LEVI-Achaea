"""Tests for tools/kb_sim.py: the boards, the inputs, the verdict rule and the data it hands to the engine.
The rules of the engine itself are in src_new/tests/test_sim_forward.lua.

    python -B tools/test_kb_sim.py
"""
import os
import re
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kb_sim as K


def fake_cells(boards, close_by_policy):
    """Every cell at the same closure rate per policy, by a function of the policy."""
    cells = {}
    for b in range(len(boards)):
        for e in range(len(K.SWEEP)):
            for a in range(len(K.ATTACKERS)):
                for p, policy in enumerate(K.POLICIES):
                    cells["%d|%d|%d|%d" % (b, e, a, p)] = {"close": round(close_by_policy(policy, e) * K.RUNS), "soft": 0,
                                                            "softTime": 0.0, "asthmaOff5": 0, "fitness": 0}
    return cells


BOARDS = [{"id": "x", "fitness": True, "seen": {"soft": None, "true": None, "imp": None, "off": None}}]


class TestBoards(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.boards, cls.unknown, cls.costs = K.extract_boards()

    def test_counts_per_log(self):
        per = {}
        for b in self.boards:
            per[b["log"]] = per.get(b["log"], 0) + 1
        self.assertEqual(per, {"az": 8, "X": 16, "Z5": 9, "g": 2})

    def test_fitness_boards_come_from_az_and_g(self):
        self.assertEqual({b["log"] for b in self.boards if b["fitness"]}, {"az", "g"})
        self.assertEqual(sum(b["fitness"] for b in self.boards), 10)

    def test_every_board_holds_the_two(self):
        for b in self.boards:
            self.assertIn("asthma", b["affs"])
            self.assertIn("weariness", b["affs"])

    def test_two_fitness_boards_closed_in_their_logs(self):
        closed = [b["id"] for b in self.boards if b["fitness"] and b["seen"]["true"] is not None]
        self.assertEqual(closed, ["az:3552", "az:3669"])

    def test_no_token_lacks_an_entry(self):
        self.assertEqual(self.unknown, {})

    def test_shield_cost_is_what_each_character_paid(self):
        self.assertEqual(self.costs, {"az": 4.0, "X": 3.4, "Z5": 3.4, "g": 3.4})

    def test_a_clock_left_is_never_negative(self):
        for b in self.boards:
            for value in b["ready"].values():
                self.assertGreater(value, 0)

    def test_hypochondria_on_a_board_has_an_age(self):
        for b in self.boards:
            if "hypochondria" in b["affs"]:
                self.assertIn("hchonAge", b)
                self.assertGreaterEqual(b["hchonAge"], 0)


class TestInputs(unittest.TestCase):
    def test_gap_inputs_match_the_clocks_page(self):
        """The gap inputs are copied from clocks.md, so a new log that moves them must fail here."""
        with open(os.path.join(K.ROOT, "kb", "mechanics", "clocks.md"), encoding="utf-8") as fh:
            row = next(line for line in fh if line.startswith("| DSTAB | 2.80 | Subterfuge/Doublestab") and "| all |" in line)
        cols = [c.strip() for c in row.strip().strip("|").split("|")]
        low, p10, median, p90 = (float(cols[i]) for i in (5, 6, 7, 8))
        self.assertAlmostEqual(low, K.GAP_MIN, delta=0.01)
        self.assertAlmostEqual(p10, K.GAP_P10, delta=0.01)
        self.assertAlmostEqual(median, K.GAP_MEDIAN, delta=0.01)
        self.assertAlmostEqual(p90, K.GAP_P90, delta=0.01)

    def test_the_strongest_row_is_where_the_index_says(self):
        self.assertTrue(K.SWEEP[K.STRONGEST_ROW][0].startswith("strongest"))
        self.assertEqual(K.SWEEP[K.BASE_ROW][0], "base")

    def test_logged_impatience_comes_from_the_board(self):
        board = {"eqCost": 3.4, "seen": {"imp": 4.8}}
        self.assertEqual(K.env_for(board, {}, "lock")["impFirst"], 4.8)
        self.assertIsNone(K.env_for({"eqCost": 3.4, "seen": {"imp": None}}, {}, "lock")["impFirst"])
        self.assertEqual(K.env_for(board, {"impFirst": 2.0}, "lock")["impFirst"], 2.0)

    def test_a_board_shield_cost_is_used_unless_a_row_moves_it(self):
        board = {"eqCost": 4.0, "seen": {"imp": None}}
        self.assertEqual(K.env_for(board, {}, "lock")["eqCost"], 4.0)
        self.assertEqual(K.env_for(board, {"eqCost": 2.89}, "lock")["eqCost"], 2.89)

    def test_seeds_differ_by_board_row_and_attacker_but_not_by_policy(self):
        seeds = {K.cell_seed(b, e, a) for b in range(35) for e in range(16) for a in range(3)}
        self.assertEqual(len(seeds), 35 * 16 * 3)

    def test_lua_text_skips_nil_and_keeps_order(self):
        self.assertEqual(K.to_lua({"b": 1, "a": None, "c": [True, "x"]}), '{["b"]=1,["c"]={true,"x"}}')


class TestVerdict(unittest.TestCase):
    def verdict(self, close_by_policy, axis="herb", a="asthma", b="default"):
        return K.compare(BOARDS, fake_cells(BOARDS, close_by_policy), axis, a, b, K.p_close, K.EFFECT_CLOSE, True)

    def test_first_choice_better_everywhere_is_robust(self):
        r = self.verdict(lambda p, e: 0.2 if p["herb"] == "asthma" else 0.5)
        self.assertEqual((r["label"], r["winner"]), ("ROBUST", "first"))

    def test_second_choice_better_everywhere_is_robust_the_other_way(self):
        r = self.verdict(lambda p, e: 0.5 if p["herb"] == "asthma" else 0.2)
        self.assertEqual((r["label"], r["winner"]), ("ROBUST", "second"))

    def test_a_flip_is_conditional_and_names_the_row(self):
        r = self.verdict(lambda p, e: (0.6 if e == 1 else 0.2) if p["herb"] == "asthma" else 0.5)
        self.assertEqual(r["label"], "CONDITIONAL")
        self.assertEqual(r["worse_inputs"], [K.SWEEP[1][0]])

    def test_no_difference_is_unsettled(self):
        self.assertEqual(self.verdict(lambda p, e: 0.5)["label"], "UNSETTLED")

    def test_a_small_difference_does_not_count(self):
        self.assertEqual(self.verdict(lambda p, e: 0.49 if p["herb"] == "asthma" else 0.5)["label"], "UNSETTLED")

    def test_a_saturated_row_is_not_live(self):
        r = self.verdict(lambda p, e: 1.0)
        self.assertEqual(r["total"], 0)
        self.assertEqual(r["label"], "UNSETTLED")

    def test_few_better_rows_are_unsettled(self):
        r = self.verdict(lambda p, e: (0.2 if e == 1 else 0.5) if p["herb"] == "asthma" else 0.5)
        self.assertEqual(r["label"], "UNSETTLED")
        self.assertGreater(r["better"], 0)


class TestRuntime(unittest.TestCase):
    def test_the_sim_runs_on_lua_51(self):
        if K.lupa is None:
            self.skipTest("lupa is not installed")
        self.assertEqual(K.lua_runtime().lua_version, (5, 1))


class TestSanity(unittest.TestCase):
    def test_a_weak_model_fails(self):
        boards = [{"id": "a", "fitness": True, "seen": {"soft": 1.0, "true": 2.0, "imp": None, "off": None}}]
        result = K.sanity(boards, fake_cells(boards, lambda p, e: 0.0))
        self.assertFalse(result["ok"])
        self.assertFalse(result["s1_ok"])

    def test_a_strong_model_passes_s1_and_s2(self):
        boards = [{"id": "a", "fitness": True, "seen": {"soft": None, "true": 2.0, "imp": None, "off": None}}]
        result = K.sanity(boards, fake_cells(boards, lambda p, e: 1.0))
        self.assertTrue(result["s1_ok"])
        self.assertTrue(result["s2_ok"])


if __name__ == "__main__":
    unittest.main(verbosity=1)
