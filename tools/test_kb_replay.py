"""Tests for tools/kb_replay.py. The fixtures are rows copied from real logs, one set per family. The row cited above a
fixture is where it came from. A few values in them are moved so that a removed rule changes the answer, and a comment
says so where it matters.

    python -B tools/test_kb_replay.py
"""
import os
import sys
import tempfile
import types
import unittest

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kb_replay as R  # noqa: E402
import kb_timing as kb  # noqa: E402

CLAES = "2026-11-01_claes_runewarden-vs-pariah_loss_Vr.NkCGD.txt"
ELMER = "2026-11-01_elmer_shikudo-vs-airlord_win_3ys7NuHA.txt"
EARTH = "2026-11-01_unknown_earthlord-vs-blademaster_loss_OwkA-G99.txt"
JD = "2026-11-01_unknown_earthlord-vs-sentinel_loss_JDvzR7j7.txt"
MYSTOR = "2026-10-11_mystor_shikudo-vs-infernal-dwc_win_FceAmb0o.txt"
NIKITA = "2026-11-01_nikita_depthswalker-vs-bard_win_kAQnlFAW.txt"
BLADE = "2026-11-01_unknown_blademaster-vs-monk_win_KtdftABt.txt"
LEVI = "2026-08-19_leviticus_blademaster-vs-sentinel_loss_Sentinel.txt"
OURS = "2026-10-28_073547_Tabethys.log"
OURS_HEADER = ("# LEVI fight log | version 4.7.462 | started 2026-10-28 07:35:47 | opponent Tabethys | our class Runewarden "
               "| our attack")


def claes(stamp, board, target="Talo"):
    """A Claes prompt, in the shape of Vr.NkCGD row 557."""
    return "H:4517|78%% M:5113|96%%  18:42:%s  [ %s ][0|35.5|0|0|0|0][%s] " % (stamp, target, board)


def replay(name, rows):
    return R.run_log(kb.parse_rows(name, rows))


def fired(rep, rule):
    return [c["start_row"] for c in rep.rules[rule]]


# Vr.NkCGD rows 3-5 and 557-578: two plagues, then Sting gives a third.
LOGOGRAPH = "Talo sweeps a bone and willow handled knife in a circle above his head, the point of the blade"
THIRD_PLAGUE = [
    LOGOGRAPH,
    claes("04:000", "AST haem"),
    claes("06:580", "AST haem fls"),
    "[AFF]: Mycalium",
    claes("06:951", "myc AST haem fls"),
    "[AFF]: Rebbies",
    claes("07:851", "myc AST reb PAR haem fls"),
]
INFEST = "You feel something shifting and undulating beneath your skin, before a black cloud struggles"


class Pariah(unittest.TestCase):
    def test_a_third_plague_fires_latency_on_that_prompt(self):
        rep = replay(CLAES, THIRD_PLAGUE)
        self.assertEqual(fired(rep, "pariah.latency"), [6])

    def test_infest_with_two_plagues_fires_it_one_plague_earlier(self):
        rows = THIRD_PLAGUE[:5] + [INFEST, claes("07:000", "myc AST haem fls")] + THIRD_PLAGUE[5:]
        rep = replay(CLAES, rows)
        self.assertEqual(fired(rep, "pariah.latency"), [6])
        self.assertEqual(rep.rules["pariah.latency"][0]["seen"]["clause"], "2 or more plagues, then Infest (\"undulating\")")

    def test_infest_before_the_two_plagues_does_not_arm_it(self):
        # "then" is an order: the Infest must come while the two plagues are up (kill-paths.md:133).
        rows = [LOGOGRAPH, INFEST, claes("04:000", "AST haem fls"), claes("05:000", "myc AST haem fls")]
        self.assertEqual(fired(replay(CLAES, rows), "pariah.latency"), [])

    def test_scourge_reads_the_bleed_on_the_prompt_with_haemophilia(self):
        # 4c_SeyaA rows 2895-2900. The reading is 205 with haem up, and 149 does not reach the bar of 150.
        rows = [LOGOGRAPH, "H:4908|89% M:3785|76%  18:45:30:607  [ Reyl ][0|33.1|0|0|0|0] ( +996h 18% ) (149B)[myc clum reb haem SCYT] ",
                "H:4908|89% M:3785|76%  18:45:30:771  [ Reyl ][0|33.1|0|0|0|0] ( +996h 18% ) (205B)[myc clum reb haem SCYT] "]
        rep = replay(CLAES, rows)
        self.assertEqual(fired(rep, "pariah.scourge"), [2])

    def test_a_decisive_snap_without_haemophilia_does_not_fire(self):
        # 4c_SeyaA row 791 is a failed snap.
        snap = "Reyl raises his left hand, and decisively snaps his fingers."
        rep = replay(CLAES, [LOGOGRAPH, snap, claes("04:000", "clum")])
        self.assertEqual(fired(rep, "pariah.scourge"), [])
        rep = replay(CLAES, [LOGOGRAPH, snap, claes("04:000", "haem clum")])
        self.assertEqual(fired(rep, "pariah.scourge"), [2])

    def test_a_bleed_tick_goes_stale_after_one_tick(self):
        # Ticks came 5.5 s apart. This haemophilia comes 7 s after the line, so the reading has gone.
        rows = [LOGOGRAPH, "You bleed 205 health.", claes("04:000", "clum"), claes("11:000", "haem")]
        self.assertEqual(fired(replay(CLAES, rows), "pariah.scourge"), [])


class NoLookAhead(unittest.TestCase):
    def test_a_rule_cannot_see_a_later_row(self):
        # The Infest row comes after prompt row 2. The rule must fire at the prompt that closes its packet, and never before.
        rows = [LOGOGRAPH, claes("04:000", "myc haem fls"), claes("05:000", "myc haem fls"), INFEST, claes("06:000", "myc haem fls")]
        self.assertEqual(fired(replay(CLAES, rows), "pariah.latency"), [4])

    def test_a_later_row_cannot_change_what_fired_earlier(self):
        before = THIRD_PLAGUE + [claes("08:000", "myc AST reb PAR haem fls")]
        changed = before + ["You have been slain by Talo.", INFEST, claes("20:000", "AST")]
        a, b = replay(CLAES, before), replay(CLAES, changed)
        self.assertEqual(fired(a, "pariah.latency"), fired(b, "pariah.latency"))

    def test_the_real_log_fires_the_same_when_cut_short(self):
        # Replay a real fight cut at many rows. Whatever fired before the cut must fire the same with the rest removed.
        path = os.path.join(kb.LOGS, "2026-11-01_claes_runewarden-vs-pariah_loss_WKuEakBZ.txt")
        rows = kb.read_rows(path)
        name = os.path.basename(path)
        whole = R.run_log(kb.parse_rows(name, rows))
        for cut in range(100, len(rows), 137):
            part = R.run_log(kb.parse_rows(name, rows[:cut]))
            for rule in R.RULES:
                rid = rule["id"]
                seen = [c["start_row"] for c in part.rules[rid] if c["start_row"] < cut - 3]
                full = [c["start_row"] for c in whole.rules[rid] if c["start_row"] < cut - 3]
                self.assertEqual(seen, full, "%s at cut %d" % (rid, cut))

    def test_the_class_gate_reads_only_what_has_printed(self):
        # The plagues come first, and the Pariah line after. A later class line cannot fire an earlier prompt.
        rows = [claes("04:000", "myc reb fls"), claes("05:000", "myc reb fls"), LOGOGRAPH, claes("06:000", "myc reb fls")]
        self.assertEqual(fired(replay(CLAES, rows), "pariah.latency"), [3])


class Metric(unittest.TestCase):
    SOFT = "AST SLCK ANO"

    def test_a_chain_ending_under_15_s_before_death_is_fatal(self):
        rows = [claes("00:000", self.SOFT), claes("01:000", "clum"), claes("14:900", "clum"), "You have been slain by Talo."]
        rep = replay(CLAES, rows)
        self.assertEqual(R.judge(rep.labels["softlock"][0], rep.death_t, rep.last_prompt), "fatal")

    def test_a_chain_ending_over_15_s_before_death_is_a_false_alarm(self):
        rows = [claes("00:000", self.SOFT), claes("01:000", "clum"), claes("15:100", "clum"), "You have been slain by Talo."]
        rep = replay(CLAES, rows)
        self.assertEqual(R.judge(rep.labels["softlock"][0], rep.death_t, rep.last_prompt), "false")

    def test_with_no_death_a_finished_chain_is_a_false_alarm(self):
        rows = [claes("00:000", self.SOFT), claes("01:000", "clum"), claes("02:000", "clum")]
        rep = replay(CLAES, rows)
        self.assertEqual(R.judge(rep.labels["softlock"][0], rep.death_t, rep.last_prompt), "false")

    def test_a_chain_still_running_at_a_cut_log_is_open_and_not_a_false_alarm(self):
        # uW_VbgR rows 554-556 stop with the logger truelocked.
        rows = [claes("00:000", self.SOFT), claes("01:000", self.SOFT)]
        rep = replay(CLAES, rows)
        self.assertEqual(R.judge(rep.labels["softlock"][0], rep.death_t, rep.last_prompt), "open")

    def test_episodes_under_10_s_apart_are_one_chain(self):
        rows = [claes("00:000", self.SOFT), claes("01:000", "clum"), claes("09:900", self.SOFT)]
        rep = replay(CLAES, rows)
        self.assertEqual(len(rep.labels["softlock"]), 1)
        self.assertEqual(rep.labels["softlock"][0]["episodes"], 2)

    def test_episodes_10_s_apart_are_two_chains(self):
        rows = [claes("00:000", self.SOFT), claes("01:000", "clum"), claes("10:000", self.SOFT)]
        self.assertEqual(len(replay(CLAES, rows).labels["softlock"]), 2)

    def test_merge_measures_from_the_end_of_the_chain(self):
        chains = R.merge_chains([[0.0, 1, 5.0, 2, None], [14.0, 3, 15.0, 4, None], [25.1, 5, 26.0, 6, None]])
        self.assertEqual([c["start_row"] for c in chains], [1, 5])

    def test_the_warning_runs_from_the_chain_start_to_the_last_prompt_before_death(self):
        # Every client log ends in its death packet, with no prompt after it (azbErKcK rows 3894-3915).
        rows = [claes("00:000", self.SOFT), claes("03:000", self.SOFT), "Health lost: 2700 (unblockable).", "You have been slain by Talo."]
        rep = replay(CLAES, rows)
        self.assertEqual(rep.killer, "Talo")
        self.assertAlmostEqual(rep.death_t - rep.labels["softlock"][0]["start"], 3.0, places=3)

    def test_a_guard_kill_is_out_of_scope_and_so_is_our_group_death(self):
        rep = replay(JD, [claes("00:000", "PR"), "You have been slain by a patrolling Arcadian royal guard."])
        self.assertIn("denizen", R.death_scope(rep))
        rep = replay(OURS, [OURS_HEADER, "07:36:18.107 P H: Full, M: Full, E: High, W: Full cexkdb-",
                            "07:36:18.200 | You have been slain by Crixos."])
        self.assertIn("group", R.death_scope(rep))

    def test_a_lock_alert_needs_softlock_inside_60_s(self):
        rows = [claes("00:000", self.SOFT), "H:4517|78% M:5113|96%  18:43:01:000  [ Talo ][0|35.5|0|0|0|0][clum] ", "You have been slain by Talo."]
        self.assertFalse(R.lock_alert(replay(CLAES, rows)))
        rows = [claes("00:000", self.SOFT), "H:4517|78% M:5113|96%  18:42:59:000  [ Talo ][0|35.5|0|0|0|0][clum] ", "You have been slain by Talo."]
        self.assertTrue(R.lock_alert(replay(CLAES, rows)))


class LabelsFromCode(unittest.TestCase):
    def s_for(self, name, rows):
        seen = None
        log = kb.parse_rows(name, rows)
        for s in R.walk(log):
            seen = s
        return seen

    def test_true_needs_the_class_cure_blocked(self):
        # Claes is a Runewarden, so weariness blocks FITNESS (003_Lock_breakers.lua:225).
        s = self.s_for("x_claes_runewarden-vs-serpent_loss.txt", [claes("00:000", "AST SLCK ANO IMP PAR")])
        self.assertFalse(R.is_true(s, "Runewarden"))
        s = self.s_for("x_claes_runewarden-vs-serpent_loss.txt", [claes("00:000", "AST SLCK ANO IMP PAR wear")])
        self.assertTrue(R.is_true(s, "Runewarden"))

    def test_fitness_on_its_clock_counts_as_blocked(self):
        rows = ["You inhale deeply, purging yourself of your asthmatic condition.", claes("00:000", "AST SLCK ANO IMP PAR")]
        self.assertTrue(R.is_true(self.s_for("x_claes_x.txt", rows), "Runewarden"))
        rows += ["You may purge your lungs once again.", claes("01:000", "AST SLCK ANO IMP PAR")]
        self.assertFalse(R.is_true(self.s_for("x_claes_x.txt", rows), "Runewarden"))

    def test_the_code_reads_an_earth_lords_cure_the_wrong_way_round(self):
        # Before v4.7.484 the code read this against class-cures.md:52 (kb/CONFLICTS.md #54). The label replays the code those logs ran.
        self.assertNotIn("Earth Lord", R.BLOCKERS)
        s = self.s_for(JD, [claes("00:000", "AST SLCK ANO IMP PAR")])
        self.assertTrue(R.is_true(s, "Earth Lord"))
        self.assertFalse(R.is_true(s, "Earth Lord", game=True))
        s = self.s_for(JD, [claes("00:000", "AST SLCK ANO IMP PAR wear")])
        self.assertFalse(R.is_true(s, "Earth Lord"))
        self.assertTrue(R.is_true(s, "Earth Lord", game=True))

    def test_the_table_is_read_from_the_code(self):
        self.assertEqual(R.BLOCKERS["Monk"], "weariness")
        self.assertEqual(R.BLOCKERS["Alchemist"], "stupidity")
        self.assertEqual(R.BLOCKERS["Depthswalker"], "recklessness")

    def test_two_of_three_counts_bloodfire_as_slickness(self):
        self.assertEqual(R.lock_count({"asthma", "bloodfire"}), 2)
        self.assertTrue(R.is_softlock({"asthma", "bloodfire", "anorexia"}))


class Families(unittest.TestCase):
    """One rule per family, each from that family's own rows."""

    def test_claes_board_pressure_fires_air_lord(self):
        # s98kPGv6 rows 567-572.
        rows = ["Talo studies you intently, the howling winds that surround him stilling for a moment.",
                claes("04:618", "mleech ddn disl"),
                "As the dark intent of Talo falls upon you, you feel the air surrounding you begin to thrum with",
                "tension.", claes("04:905", "pressure(3) ddn disl mleech")]
        self.assertEqual(fired(replay(CLAES, rows), "airlord.pressure"), [4])

    def test_elmer_board_pressure_fires_air_lord(self):
        # 3ys7NuHA rows 573-579, with its wrapped board.
        stamp = "H:6118|87%% M:3101|90%% E:99%% W:100%% [S|N] Rage:0 %s -ex*- Stance: None Form: X Kata: 0 Kai: 28%%[0|0|30.4|7.6|30.4|22.8][%s "
        rows = ["Astarod studies you intently, the howling winds that surround him stilling for a moment.",
                stamp % ("17:426", "pressure(2) ddn mleech"), "tens] ",
                stamp % ("17:455", "pressure(5) ddn mleech"), "tens] "]
        rep = replay(ELMER, rows)
        self.assertEqual(fired(rep, "airlord.pressure"), [3])

    def test_our_recorder_counts_pressure_by_the_line(self):
        # Our board does not print pressure(n). The gain line itself is 3ys7NuHA row 438, in our recorder's row shape.
        gain = "07:36:%02d.000 | As the dark intent of Talo falls upon you, you feel the air surrounding you begin to thrum with tension."
        prompt = "07:36:%02d.100 P H: Full, M: Full, E: High, W: Full cexkdb-"
        rows = [OURS_HEADER]
        for sec in (10, 11, 12):
            rows += [gain % sec, prompt % sec]
        rep = replay(OURS, rows)
        self.assertEqual(fired(rep, "airlord.pressure"), [6])
        self.assertEqual(rep.rules["airlord.pressure"][0]["seen"]["clause"], "3 or more pressure gains by the line, less the losses")

    def test_a_pear_takes_one_off_the_line_count(self):
        gain = "07:36:%02d.000 | As the dark intent of Talo falls upon you, you feel the air surrounding you begin to thrum with tension."
        prompt = "07:36:%02d.100 P H: Full, M: Full, E: High, W: Full cexkdb-"
        rows = [OURS_HEADER, gain % 10, prompt % 10, gain % 11, prompt % 11,
                "07:36:12.000 | As the pressure around you normalises somewhat, your breath is torn from your lungs.", prompt % 12,
                gain % 13, prompt % 13]
        self.assertEqual(fired(replay(OURS, rows), "airlord.pressure"), [])

    def test_claes_prone_with_a_leg_at_level_2_fires_the_2h_rule(self):
        # CxxKSMq rows 1533-1538. Row 755 is the rune line that shows the class, with the name on the next row.
        rows = ["The sleizak rune flashes bright upon a bastard sword rough-hewn from a sapling in the hands of", "Blonk.",
                claes("41:000", "la1 clum", "Blonk"), claes("42:924", "la1 RL2 LL2 sfrac(2) VOYR PR", "Blonk")]
        self.assertEqual(fired(replay(CLAES, rows), "runewarden.2h"), [3])

    def test_an_impale_needs_the_two_hander_in_the_last_30_s(self):
        impale = "Blonk draws his blade back and plunges it deep into your helpless body impaling it to the hilt."
        wield = "Blonk starts to wield a bastard sword rough-hewn from a sapling in his hands."
        sketch = "Blonk finishes sketching a dagaz rune with a flourish."
        rows = [sketch, wield, claes("00:000", "clum", "Blonk"), impale, claes("29:000", "clum", "Blonk")]
        self.assertEqual(fired(replay(CLAES, rows), "runewarden.2h"), [4])
        rows = [sketch, wield, claes("00:000", "clum", "Blonk"), impale, claes("31:000", "clum", "Blonk")]
        self.assertEqual(fired(replay(CLAES, rows), "runewarden.2h"), [])

    def earth_prompt(self, stamp, board):
        return "H:4468|52%% M:5612|80%% E:93%% W:83%% [NE|SE] R:0 48:%s-exc- Shaping : 4[84|42|0|0|63|63] [%s] " % (stamp, board)

    def test_earth_lord_limb_rows_fire_the_blademaster_rule(self):
        # OwkA-G99 rows 2926-2934. The prompt's own block is the TARGET, so it must not count.
        rows = ["Planting his foot between yours, Alyzar draws Saosh's Vow and unleashes a forceful slash that drives you back.",
                self.earth_prompt("40.00", "shiv"),
                "As Alyzar carves into you, you perceive that he has dealt 19.8% damage to your left leg.",
                " LIMB DAMAGE: left leg (72.6%)", "[59.4|0|0|0|72.6|46.2]",
                self.earth_prompt("41.00", "shiv"),
                "As Alyzar carves into you, you perceive that he has dealt 13.2% damage to your right leg.",
                " LIMB DAMAGE: right leg (59.4%)", "[59.4|0|0|0|72.6|59.4]",
                self.earth_prompt("42.00", "shiv")]
        rep = replay(EARTH, rows)
        self.assertEqual(fired(rep, "blademaster.legs"), [9])

    def test_planting_needs_a_broken_leg(self):
        planting = "Planting his foot between yours, Alyzar draws Saosh's Vow and unleashes a forceful slash that drives you back."
        self.assertEqual(fired(replay(EARTH, [planting, self.earth_prompt("50.00", "shiv PR")]), "blademaster.legs"), [])
        self.assertEqual(fired(replay(EARTH, [planting, self.earth_prompt("50.00", "RL2 ll1 shiv PR")]), "blademaster.legs"), [1])

    def test_a_restoration_line_resets_a_limb(self):
        rows = ["Planting his foot between yours, Alyzar draws Saosh's Vow and unleashes a forceful slash that drives you back.",
                self.earth_prompt("40.00", "shiv"),
                "[59.4|0|0|0|72.6|59.4]", "[SLC]: Reset left leg counts.", "Your left leg feels stronger and healthier.",
                self.earth_prompt("41.00", "shiv")]
        self.assertEqual(fired(replay(EARTH, rows), "blademaster.legs"), [])

    def test_earth_lord_trip_fires_the_sentinel_rule(self):
        # JDvzR7j7 rows 1745-1754.
        trip = "Vothaec swiftly sweeps your feet out from beneath you with an ironwood spear before driving the point of the weapon into your right leg."
        rows = [trip, self.earth_prompt("43.34", "RL2 RA2 PAR ADD haem naus PR")]
        rep = replay(JD, rows)
        self.assertEqual(fired(rep, "sentinel.tripimpale"), [1])
        self.assertEqual(rep.rules["sentinel.tripimpale"][0]["seen"]["clause"], "TRIP's prone with a leg broken")

    def test_a_trip_stops_counting_once_the_victim_has_stood(self):
        trip = "Vothaec swiftly sweeps your feet out from beneath you with an ironwood spear before driving the point of the weapon into your right leg."
        rows = [trip, self.earth_prompt("43.00", "PR"), self.earth_prompt("44.00", "clum"), self.earth_prompt("45.00", "RL2 PR")]
        self.assertEqual(fired(replay(JD, rows), "sentinel.tripimpale"), [])

    def test_sentinel_family_trip_with_its_own_tokens(self):
        # Sentinel rows 2583-2591. Its lower-case par is paranoia, and Rl2 is the leg.
        trip = "Grulk swiftly sweeps your feet out from beneath you with a Stormspear before driving the point of the weapon into your"
        rows = [trip, "right leg.", "09:59:58:324 [10795] [70] |(Grulk)|[ [ sen prone ANO Rl2 clu SLI WEA nau hal IMP PAR AST add (Locks: soft, venom, hard, true) ]]  "]
        rep = replay(LEVI, rows)
        self.assertEqual(fired(rep, "sentinel.tripimpale"), [2])
        self.assertEqual(R.read_terms("sentinel", ["par"])[0], set())
        self.assertEqual(R.read_terms("sentinel", ["PAR"])[0], {"paralysis"})

    def mystor_prompt(self, stamp, board):
        return ["[B|E] [CDBK] H:5816|92% M:5154|85% [6.83] [Rain]:10 K:86% [" + board + "] ",
                "20:24:%s (118) [Agathon]: conf(0%%), IMP(100%%)" % stamp]

    def test_the_sentinel_familys_six_number_row_is_the_target_and_not_the_logger(self):
        # Sentinel rows 3 and 843: the row follows the logger's OWN attack on Grulk. The numbers are moved up, and the "dealt" line
        # makes the limb clause evaluable. Read as the logger's limbs, the row would fire the generic rule.
        rows = ["As Grulk carves into you, you perceive that he has dealt 14.7% damage to your right leg.",
                " [0|0|30.2|30.2|90.0|90.0]",
                "09:59:14:665 [14906] [89] |(Grulk)|[ [ par ]]  [0|0|30.2|30.2|90.0|90.0]"]
        self.assertEqual(fired(replay(LEVI, rows), "generic.limb"), [])

    def test_mystor_limb_lines_fire_the_generic_rule_on_an_unknown_attacker(self):
        # FceAmb0o rows 392-398. Agathon's lines are the client's own, so no class shows. The percentages are moved up.
        rows = ["Agathon: Dsl left leg -> You", "My Left leg: 89.0% [+6.9%]", "Agathon: Dsl right leg -> You", "My Right leg: 90.0% [+6.9%]"]
        rows += self.mystor_prompt("12", "hsomn")
        rows += ["My Left leg: 90.0% [+1.0%]"] + self.mystor_prompt("13", "hsomn")
        rep = replay(MYSTOR, rows)
        self.assertEqual(fired(rep, "generic.limb"), [7])

    def test_the_generic_rule_stays_quiet_once_a_class_shows(self):
        rows = ["Target set to: Agathon (Level 120 Infernal)", "My Left leg: 90.0% [+6.9%]", "My Right leg: 90.0% [+6.9%]"]
        rows += self.mystor_prompt("12", "hsomn")
        self.assertEqual(fired(replay(MYSTOR, rows), "generic.limb"), [])

    def test_nikita_prone_with_his_level_2_token_fires_the_2h_rule(self):
        # kAQnlFAW prompt shape. His long tag can take the next row (540 of his prompts), so the fixture wraps one.
        rows = ["Torvald finishes sketching a dagaz rune with a flourish.",
                "5102(83%|88%) 99e 99w exT ckdb 0 04:21:45.39  0 -- (cresc1|PR|LEFTLEG2)",
                "5102(83%|88%) 99e 99w exT ckdb 0 04:21:46.39  0 --", " (cresc1|PR|LEFTLEG2)"]
        rep = replay(NIKITA, rows)
        self.assertEqual(fired(rep, "runewarden.2h"), [1])
        self.assertEqual(R.read_terms("nikita", ["w", "r", "SLI"])[0], {"weariness", "recklessness", "slickness"})

    def test_blademaster_family_has_no_board_and_still_reads_limb_lines(self):
        # KtdftABt rows 6-13. The percentages are moved up. No board means the head + prone clause is not evaluable.
        prompt = "H:7409|106%% M:4922|99%% W:22045|100%%  22:50:%02d -exckbd- Sh: 0 St: Thyr [ Kuririn ]"
        rows = ["As Kuririn's blow crunches into you, you perceive that he has dealt 90.0% damage to your left leg.",
                "As Kuririn's blow crunches into you, you perceive that he has dealt 90.0% damage to your right leg.",
                prompt % 13]
        rep = replay(BLADE, rows)
        self.assertEqual(fired(rep, "generic.limb"), [2])
        self.assertIn(1, rep.missing["generic.limb"])
        self.assertEqual(rep.labels["softlock"], [])


class NotEvaluable(unittest.TestCase):
    STAMP = "H:6118|87%% M:3101|90%% E:99%% W:100%% [S|N] Rage:0 %s -ex*- Stance: None Form: X Kata: 0 Kai: 28%%[0|0|30.4|7.6|30.4|22.8][%s] "

    def test_elmer_cannot_show_prone_so_that_clause_is_recorded_and_not_guessed(self):
        rows = ["Torvald finishes sketching a dagaz rune with a flourish.", self.STAMP % ("17:426", "PR RL2")]
        rep = replay(ELMER, rows)
        self.assertEqual(fired(rep, "runewarden.2h"), [])
        self.assertEqual(sorted(rep.missing["runewarden.2h"]), [0])
        self.assertTrue(rep.evaluable["runewarden.2h"])

    def test_a_rule_with_every_clause_missing_is_not_evaluable_and_tests_nothing(self):
        rep = replay(ELMER, [self.STAMP % ("17:426", "PR RL2")])
        self.assertFalse(rep.evaluable["generic.limb"])
        res = R.rule_results([rep])
        self.assertTrue(res["generic.limb"]["untested"])
        self.assertTrue(res["generic.limb"]["not_evaluable"])

    def test_the_log_with_no_stamped_prompt_gives_nothing(self):
        log = kb.parse(os.path.join(kb.LOGS, "2026-10-19_tabethys_magi-group_kalys_o6UKnyyy.txt"))
        self.assertIsNone(log.family)
        rep = R.run_log(log)
        self.assertEqual(rep.labels, {})
        self.assertIsNone(rep.death_t)

    def test_no_elmer_log_has_ever_printed_prone_or_a_limb(self):
        # CAPS says so. If a new Elmer log prints one, the capability table has to change.
        banned = {"PR", "ll1", "rl1", "la1", "ra1", "LL2", "RL2", "LA2", "RA2"}
        for name in sorted(os.listdir(kb.LOGS)):
            if "_elmer_" in name and name.endswith(".txt"):
                log = kb.parse(os.path.join(kb.LOGS, name))
                for row in log:
                    if row.kind == "prompt":
                        self.assertFalse(banned & set(row.board or []), "%s row %d" % (name, row.n))


class ExitsAndClocks(unittest.TestCase):
    def final(self, name, rows):
        seen = None
        for s in R.walk(kb.parse_rows(name, rows)):
            seen = s
        return seen

    def test_a_channel_is_down_from_its_start_line_to_its_recovery_line(self):
        ex = {"name": "x", "channel": "eat", "blocked_by": ["anorexia"]}
        rows = ["You eat a piece of kelp.", claes("00:000", "clum")]
        self.assertEqual(R.exit_state(ex, self.final(CLAES, rows), None), "clock down")
        rows += ["You may eat another plant or mineral. Eat (1.53)", claes("01:000", "clum")]
        self.assertEqual(R.exit_state(ex, self.final(CLAES, rows), None), "open")

    def test_a_lost_recovery_line_cannot_hold_a_channel_down_for_ever(self):
        ex = {"name": "x", "channel": "eat", "blocked_by": []}
        rows = ["You eat a piece of kelp.", claes("00:000", "clum"), claes("02:900", "clum")]
        self.assertEqual(R.exit_state(ex, self.final(CLAES, rows), None), "clock down")
        rows += [claes("03:100", "clum")]
        self.assertEqual(R.exit_state(ex, self.final(CLAES, rows), None), "open")

    def test_a_blocker_on_the_board_shuts_an_exit(self):
        ex = {"name": "x", "channel": "salve", "blocked_by": ["slickness"]}
        self.assertEqual(R.exit_state(ex, self.final(CLAES, [claes("00:000", "SLCK")]), None), "shut by slickness")

    def test_pear_spends_the_lungs_and_not_the_eat_clock(self):
        rows = ["You eat a calcite mote.", claes("00:000", "clum")]
        s = self.final(CLAES, rows)
        self.assertEqual(R.exit_state({"name": "x", "channel": "lungs", "blocked_by": []}, s, None), "clock down")
        self.assertEqual(R.exit_state({"name": "x", "channel": "eat", "blocked_by": []}, s, None), "open")

    def test_a_format_with_no_flags_reads_unknown_and_that_is_not_open(self):
        # Claes's prompt prints neither balance nor equilibrium.
        ex = {"name": "x", "channel": "move", "blocked_by": []}
        self.assertEqual(R.exit_state(ex, self.final(CLAES, [claes("00:000", "clum")]), None), "unknown")

    def test_each_format_reads_its_own_flags(self):
        self.assertEqual(R.prompt_balances("earth", "R:0 48:49.16-exc- Shaping"), (True, True))
        self.assertEqual(R.prompt_balances("earth", "R:0 48:51.07-ec- Shaping"), (False, True))
        self.assertEqual(R.prompt_balances("elmer", "Rage:0 08:482 -x-[0|0"), (True, False))
        self.assertEqual(R.prompt_balances("nikita", "5102(83%|88%) 99e 99w eT ckdb 0 04:21"), (False, True))
        self.assertEqual(R.prompt_balances("nikita", "5102(83%|88%) 99e 99w exT ckdb 0 04:21"), (True, True))
        self.assertEqual(R.prompt_balances("mystor", "[B|-] [CDBK] H:5816|92%"), (True, False))
        self.assertEqual(R.prompt_balances("ours", "H: Healthy, M: High, E: Full, W: High cxkb-62-"), (True, False))
        self.assertEqual(R.prompt_balances("ours", "H: Full, M: Full, E: High, W: Full cexkdb-"), (True, True))
        self.assertEqual(R.prompt_balances("claes", "H:1|1% M:1|1%  18:42:06:580"), (None, None))

    def test_the_class_cure_uses_the_game_blocker_for_an_earth_lord(self):
        ex = R.LOCK_EXITS[2]
        s = self.final(JD, ["H:4468|52% M:5612|80% E:93% W:83% [NE|SE] R:0 48:50.59-exc- Shaping : 3[84|42|0|0|63|63] [wear] "])
        self.assertEqual(R.exit_state(ex, s, "Earth Lord"), "shut by weariness")


class ClassEvidence(unittest.TestCase):
    def test_a_knight_line_shared_with_a_blademaster_is_not_evidence(self):
        # OwkA-G99 row 46: a Blademaster prints the DWC knight line. Row 47 is the real signature.
        self.assertIsNone(R.line_class("Alyzar whips Saosh's Vow through the air in front of you, to no effect."))
        self.assertEqual(R.line_class("Ducking behind you, Alyzar strikes at your hamstring with a rigid grip."), ("Alyzar", "Blademaster"))

    def test_the_folded_air_lord_pattern_reads_as_one_regex(self):
        line = "A howling wind sweeps over you, its terrible power scouring flesh from bone and leaving your face a bloody ruin by the will of Talo."
        self.assertEqual(R.line_class(line), ("Talo", "Airlord"))

    def test_the_logger_echoes_count_and_a_knight_echo_does_not(self):
        self.assertEqual(R.line_class("[Legacy]: Curing against Pariah (Talo)."), ("Talo", "Pariah"))
        self.assertIsNone(R.line_class("[Legacy]: Curing against 2H (Blonk)."))
        self.assertEqual(R.line_class("       Target set to: Sjeng (Level 100 Runewarden)       "), ("Sjeng", "Runewarden"))

    def test_a_denizen_is_not_a_person(self):
        self.assertIsNone(R.line_class("A wild bandit hurls a bronze axe at you."))

    def test_later_evidence_replaces_earlier(self):
        # LcJC-rJ5 row 8 says Monk, a stale value. Row 40 shows the Apostate.
        rows = ["Target set to: Pharaus (Level 131 Monk)", claes("00:000", "clum", "Pharaus"),
                "Pharaus stares at you, giving you the evil eye.", claes("01:000", "clum", "Pharaus")]
        seen = None
        for s in R.walk(kb.parse_rows(CLAES, rows)):
            seen = s
        self.assertEqual(seen.classes["Pharaus"], "Apostate")


class BoardCheck(unittest.TestCase):
    STAMP = "H:6649|100%% M:5530|96%% E:99%% W:91%% [] Rage:0 %s -ex-[0|0|0|0|0|0][%s] "

    def check(self, name, rows, client):
        log = kb.parse_rows(name, rows)
        log.logger = client
        return R.board_check([log])[client]

    def test_a_gain_line_then_a_board_with_the_term_agrees(self):
        c = self.check(CLAES, ["The idea of eating or drinking is repulsive to you.", claes("00:000", "ANO"),
                               "You notice that your sweat glands have begun to rapidly secrete a foul, oily substance.", claes("01:000", "ANO")], "Claes")
        self.assertEqual((c["gain_ok"], c["gain_n"]), (1, 2))
        self.assertEqual(c["gain_miss"][0].split()[-1], "slickness")

    def test_a_cure_line_then_a_board_without_the_term_agrees(self):
        c = self.check(CLAES, ["Food is no longer repulsive to you.", claes("00:000", "clum"),
                               "You have cured the paralysis affliction.", claes("01:000", "PAR")], "Claes")
        self.assertEqual((c["cure_ok"], c["cure_n"]), (1, 2))

    def test_a_packet_with_a_gain_and_a_cure_of_one_term_is_left_out(self):
        c = self.check(CLAES, ["A prickly stinging overcomes your body, fading away into numbness.",
                               "Your muscles unlock; you are no longer paralysed.", claes("00:000", "clum")], "Claes")
        self.assertEqual((c["gain_n"], c["cure_n"]), (0, 0))

    def test_elmer_softlocked_means_softlock_with_impatience(self):
        # Z5cyffxx rows 4976 and 5404. The first has no IMP and no echo, the second has both.
        rows = [self.STAMP % ("52:765", "hchon SLCK ANO AST"), self.STAMP % ("53:765", "IMP SLCK ANO AST SOFTLOCKED")]
        c = self.check(ELMER, rows, "Elmer")
        self.assertEqual((c["soft_both"], c["soft_echo"], c["soft_board"]), (1, 0, 0))
        self.assertEqual((c["literal_both"], c["literal_board"]), (1, 1))

    def test_vlock_is_counted_and_never_read_as_the_loggers_own(self):
        # Vr.NkCGD rows 654-656: VLOCK above an unlocked board of his own.
        c = self.check(CLAES, ["[VLOCK, diz, clum[75], sen, weari, naus, deaf, frzn[200]]", claes("10:330", "myc AST haem SCYT fls")], "Claes")
        self.assertEqual((c["vlock_rows"], c["vlock_soft"]), (1, 0))
        self.assertFalse(c["has_echo"])

    def test_the_lowest_measure_with_enough_samples_decides(self):
        c = {"has_board": True, "has_echo": False, "gain_ok": 90, "gain_n": 100, "cure_ok": 50, "cure_n": 100}
        self.assertEqual(R.client_agreement(c), 50.0)
        c = {"has_board": True, "has_echo": False, "gain_ok": 90, "gain_n": 100, "cure_ok": 1, "cure_n": 9}
        self.assertEqual(R.client_agreement(c), 90.0)

    def test_a_client_under_the_bar_leaves_every_bar(self):
        rows = THIRD_PLAGUE + ["You have been slain by Talo."]
        rep = replay(CLAES, rows)
        self.assertEqual(len(R.rule_results([rep])["pariah.latency"]["warned"]), 1)
        rep.client = "Claes"
        self.assertEqual(R.rule_results([rep], R.RULES, {"Claes"})["pariah.latency"]["warned"], [])


class Gate(unittest.TestCase):
    def rule(self, rid):
        for rule in R.RULES:
            if rule["id"] == rid:
                return rule
        self.fail(rid)

    def test_the_frozen_thresholds_have_not_moved(self):
        # Changing one of these after the first run makes the rule POST-HOC. See the page's first-run record.
        self.assertEqual(self.rule("pariah.latency")["clauses"][0]["terms"], (("count_min", R.PLAGUES, 3),))
        self.assertEqual(self.rule("pariah.latency")["clauses"][1]["terms"][0], ("count_min", R.PLAGUES, 2))
        self.assertEqual(self.rule("pariah.scourge")["clauses"][0]["terms"][0], ("bleed_min", 150))
        self.assertEqual(self.rule("airlord.pressure")["clauses"][0]["terms"], (("pressure_board_min", 3),))
        self.assertEqual(self.rule("airlord.pressure")["clauses"][1]["terms"], (("pressure_line_min", 3),))
        self.assertEqual(self.rule("runewarden.2h")["clauses"][1]["terms"][1], ("event_within", "twohand", 30.0))
        self.assertEqual(self.rule("blademaster.legs")["clauses"][0]["terms"], (("legs_pct", 60.0, 50.0),))
        self.assertEqual(self.rule("generic.limb")["clauses"][0]["terms"], (("legs_pct", 90.0, 90.0),))
        self.assertEqual(self.rule("generic.limb")["clauses"][1]["terms"][0], ("head_pct", 90.0))
        self.assertEqual((R.CHAIN_GAP, R.FALSE_WINDOW, R.LOCK_LOOKBACK, R.WARN_BAR, R.AGREEMENT_BAR), (10.0, 15.0, 60.0, 5.0, 90.0))

    def test_every_rule_names_exits_with_a_channel_and_a_citation(self):
        for rule in R.RULES:
            self.assertIn("docs/kill-paths.md", rule["cite"])
            self.assertTrue(rule["exits"])
            for ex in rule["exits"]:
                self.assertTrue(ex["channel"] in R.CHANNEL_MAX or ex["channel"] in ("balance", "move"), ex["name"])

    def test_a_recording_of_ours_tests_no_rule(self):
        # ours/081532_Tabethys: the Pariah is Harkon, a member of our party, and that took G1 and G2 to PASS.
        rows = [OURS_HEADER, "08:15:32.100 | " + LOGOGRAPH, "08:15:32.200 P H: Full, M: Full cexkdb-"]
        rep = replay("2026-11-03_081532_Tabethys.log", rows)
        res = R.rule_results([rep])
        self.assertEqual(res["pariah.latency"]["fought_survived"], [rep.log.id])
        self.assertTrue(res["pariah.latency"]["untested"])

    def test_a_client_log_still_tests_a_rule(self):
        res = R.rule_results([replay(CLAES, THIRD_PLAGUE)])
        self.assertFalse(res["pariah.latency"]["untested"])

    def test_an_untested_rule_does_not_count_toward_g1(self):
        rep = replay(CLAES, THIRD_PLAGUE + [claes("20:000", "myc AST reb haem fls"), "You have been slain by Talo."])
        res = R.rule_results([rep])
        self.assertTrue(res["pariah.latency"]["untested"])
        deaths = R.build_deaths([rep], res, set())
        gate = R.build_gate(deaths, res, R.label_results([rep]))
        self.assertEqual(deaths[0]["rules"][0]["rule"], "pariah.latency")
        self.assertGreater(deaths[0]["rules"][0]["seconds"], 5.0)
        self.assertEqual(gate["counted"], [])
        self.assertFalse(gate["g1"])

    def test_the_page_says_the_honest_labels_in_its_first_lines_and_holds_the_bars_word_for_word(self):
        text = R.generate()[R.OUT_MD]
        body = text.split("---\n", 2)[2]
        self.assertIn("in-sample", body[:300])
        self.assertIn("false-alarm count is the stronger evidence", body[:400])
        self.assertIn("next kill in a new log", body[:500])
        self.assertIn("not independent", body[:600])
        for _, bar in R.BAR_TEXT:
            self.assertIn(bar, text)
        self.assertIn(R.RESULT_TEXT, text)
        for item, value in R.FIRST_RUN:
            self.assertIn(value.replace("|", "\\|"), text)

    def test_the_page_says_where_the_rules_and_the_bars_came_from(self):
        text = R.generate()[R.OUT_MD]
        self.assertNotIn("written before any of them ran against a death", text)
        self.assertIn("written from the tells in `docs/kill-paths.md`, which came from these deaths", text)
        self.assertNotIn("These bars were frozen before this run", text)
        self.assertIn("repository cannot show the order", text)
        self.assertIn("The rune flash line is seen only in `CxxKSMq`", text)
        self.assertIn("latest_filed:", text)

    def test_two_runs_give_the_same_bytes(self):
        self.assertEqual(R.generate(), R.generate())

    def test_the_page_has_lf_line_ends_and_a_final_newline(self):
        text = R.generate()[R.OUT_MD]
        self.assertNotIn("\r", text)
        self.assertTrue(text.endswith("\n"))


def warning(rule, seconds, opened=True, tested=True, off_before=0.0):
    state = "open" if opened else "shut by slickness"
    return {"rule": rule, "seconds": seconds, "row": 1, "clause": "c", "tested": tested, "class_row": 1, "off_before": off_before,
            "exits": [("touch tree", "tree", state, None)]}


def death(log, killer, rules=(), lock=False, scope=None, excluded=False, labels=None):
    return {"log": log, "killer": killer, "rules": list(rules), "lock": lock, "scope": scope, "excluded": excluded, "labels": labels or {},
            "row": 9, "file": log, "t": 100.0, "soft_before": None, "classes": {}, "class_rows": {}, "client": "Claes", "family": "claes"}


def rule_row(untested=False, fraction=0.0, false=0, warned=1):
    return {"untested": untested, "fraction": fraction, "false_survived": [("x", 1)] * false, "false_lost": [], "warned": [{}] * warned, "open": []}


class GateBars(unittest.TestCase):
    """build_gate at its boundaries. Only the page protected these before, and running the tool clears a page diff."""

    SOFT = {"softlock": {"false": [("x", 1)] * 11, "n": 6}}

    def gate(self, deaths, rules=None):
        res = {rule["id"]: rule_row() for rule in R.RULES}
        res.update(rules or {})
        return R.build_gate(deaths, res, self.SOFT)

    def counted(self, killers):
        return [death("log%d" % i, name, [warning("runewarden.2h", 6.0)]) for i, name in enumerate(killers)]

    def test_g1_needs_four_counted_deaths(self):
        self.assertFalse(self.gate(self.counted(["A", "B", "C"]))["g1"])
        self.assertTrue(self.gate(self.counted(["A", "B", "C", "A"]))["g1"])

    def test_g1_needs_a_warning_of_five_seconds_from_a_tested_rule(self):
        short = [death("a", "A", [warning("runewarden.2h", 4.99)])]
        self.assertEqual(self.gate(short)["counted"], [])
        at_bar = [death("a", "A", [warning("runewarden.2h", 5.0)])]
        self.assertEqual(len(self.gate(at_bar)["counted"]), 1)
        untested = [death("a", "A", [warning("pariah.latency", 50.0, tested=False)])]
        self.assertEqual(self.gate(untested)["counted"], [])

    def test_g1_leaves_out_lock_deaths_and_out_of_scope_and_excluded_deaths(self):
        deaths = [death("a", "A", [warning("runewarden.2h", 9.0)], lock=True), death("b", "B", [warning("runewarden.2h", 9.0)], scope="guards"),
                  death("c", "C", [warning("runewarden.2h", 9.0)], excluded=True)]
        self.assertEqual(self.gate(deaths)["counted"], [])

    def test_g2_needs_three_attackers_and_a_repeat_counts_once(self):
        self.assertEqual(self.gate(self.counted(["A", "B", "A", "B"]))["attackers"], ["A", "B"])
        self.assertFalse(self.gate(self.counted(["A", "B", "A", "B"]))["g2"])
        self.assertTrue(self.gate(self.counted(["A", "B", "C"]))["g2"])

    def test_g3_needs_an_open_exit_at_every_counted_warning(self):
        deaths = self.counted(["A", "B"])
        self.assertTrue(self.gate(deaths)["g3"])
        deaths[1]["rules"] = [warning("runewarden.2h", 6.0, opened=False)]
        self.assertFalse(self.gate(deaths)["g3"])
        self.assertFalse(self.gate([])["g3"])

    def test_g4_compares_each_tested_rule_with_the_softlock_baseline(self):
        baseline = 11 / 17.0
        self.assertTrue(self.gate([], {"airlord.pressure": rule_row(fraction=baseline)})["g4"])
        self.assertFalse(self.gate([], {"airlord.pressure": rule_row(fraction=baseline + 0.001)})["g4"])
        self.assertTrue(self.gate([], {"airlord.pressure": rule_row(fraction=None, warned=0)})["g4"])
        # An untested rule is not judged, whatever its fraction.
        self.assertTrue(self.gate([], {"airlord.pressure": rule_row(untested=True, fraction=0.99)})["g4"])

    def test_g5_needs_four_lock_deaths_that_name_an_open_exit(self):
        def lock_death(name, state):
            seen = {"exits": [("focus", "focus", state)], "bal": None, "eq": None}
            return death(name, "A", lock=True, labels={"softlock": {"seen": seen, "seconds": 5.0, "row": 1, "checks": []}})
        three = [lock_death(n, "open") for n in "abc"] + [lock_death("d", "shut by impatience")]
        self.assertEqual(self.gate(three)["n_g5"], 3)
        self.assertFalse(self.gate(three)["g5"])
        four = [lock_death(n, "open") for n in "abcd"]
        self.assertTrue(self.gate(four)["g5"])

    def test_the_result_needs_g1_to_g4_and_not_g5(self):
        good = self.counted(["A", "B", "C", "A"])
        self.assertTrue(self.gate(good)["result"])
        self.assertFalse(self.gate(good)["g5"])
        self.assertFalse(self.gate(self.counted(["A", "B", "C"]))["result"])
        self.assertFalse(self.gate(self.counted(["A", "B", "A", "B"]))["result"])
        failing = self.gate(good, {"airlord.pressure": rule_row(fraction=0.99)})
        self.assertFalse(failing["result"])
        no_exit = self.counted(["A", "B", "C", "A"])
        no_exit[0]["rules"] = [warning("runewarden.2h", 6.0, opened=False)]
        self.assertFalse(self.gate(no_exit)["result"])

    def test_the_bar_text_is_word_for_word(self):
        self.assertEqual([k for k, _ in R.BAR_TEXT], ["G1", "G2", "G3", "G4", "G5"])
        self.assertIn("warn at least 5 s before death on at least 4", R.BAR_TEXT[0][1])
        self.assertIn("at least 3 different attackers", R.BAR_TEXT[1][1])
        self.assertIn("at least one named exit is open", R.BAR_TEXT[2][1])
        self.assertIn("no worse than the softlock baseline", R.BAR_TEXT[3][1])
        self.assertIn("on at least 4 of those deaths", R.BAR_TEXT[4][1])


class Readings(unittest.TestCase):
    def analysis(self, deaths):
        gate = {"in_scope": deaths}
        return {"gate": gate}

    def test_the_plans_sentence_counts_any_rule_of_five_seconds_or_more(self):
        deaths = [death("s98kPGv6", "Talo", [warning("airlord.pressure", 53.8)]),
                  death("4c_SeyaA", "Reyl", [warning("pariah.latency", 6.78, tested=False, off_before=1.0), warning("pariah.scourge", 2.95, tested=False)]),
                  death("Vr.NkCGD", "Talo", [warning("pariah.latency", 13.38, tested=False, off_before=11.42)]),
                  death("new", "Q", [warning("pariah.latency", 4.99, tested=False)])]
        r = R.plan_reading(self.analysis(deaths))
        self.assertEqual((r["alone"]["n"], r["alone"]["total"]), (3, 4))
        self.assertEqual(r["alone"]["attackers"], ["Reyl", "Talo"])
        self.assertFalse(r["passes"])
        # The rule that warned must match the kill: 4c_SeyaA's warning is Latency, and the kill was Scourge.
        self.assertEqual(r["matched"]["logs"], ["s98kPGv6", "Vr.NkCGD"])
        self.assertEqual(r["mismatch"][0]["log"], "4c_SeyaA")
        self.assertEqual(r["mismatch"][0]["own"], 2.95)
        # The chain must also still be on within 5 s of death: Vr.NkCGD went off 11.42 s before it.
        self.assertEqual(r["still_on"]["logs"], ["s98kPGv6"])

    def test_four_deaths_pass_the_plans_sentence_and_the_page_gives_the_user_the_choice(self):
        deaths = [death("a%d" % i, "A", [warning("pariah.latency", 9.0, tested=False)]) for i in range(4)]
        r = R.plan_reading(self.analysis(deaths))
        self.assertTrue(r["passes"])
        text = R.plan_sentence(r)
        self.assertIn("has no UNTESTED, G3 or G4 term", text)
        self.assertIn("Read alone it gives 4 of 4 from 1 attackers", text)
        self.assertIn("The user decided on 2026-11-01 that these bars stand", text)

    def test_a_sentence_that_fails_alone_does_not_blame_the_stricter_bars(self):
        r = R.plan_reading(self.analysis([death("a", "A", [warning("pariah.latency", 9.0, tested=False)])]))
        text = R.plan_sentence(r)
        self.assertIn("That reading fails too", text)
        self.assertNotIn("The user decided", text)

    def test_the_chance_of_a_warning(self):
        # A 10 s chain in a 100 s fight can start from 75 s to 90 s of the 90 s it has.
        self.assertAlmostEqual(R.chance_of_warning(100.0, [10.0]), 15.0 / 90.0)
        # A 2 s chain must start at least 5 s before death: 83 s to 95 s of 98 s.
        self.assertAlmostEqual(R.chance_of_warning(100.0, [2.0]), 12.0 / 98.0)
        # Two chains: at least one.
        self.assertAlmostEqual(R.chance_of_warning(100.0, [10.0, 10.0]), 1 - (75.0 / 90.0) ** 2)
        self.assertEqual(R.chance_of_warning(100.0, []), 0.0)
        # A chain that fills the fight cannot miss.
        self.assertEqual(R.chance_of_warning(20.0, [20.0]), 1.0)

    def small_analysis(self):
        hit = "Health lost: 100."
        fatal = [LOGOGRAPH, claes("00:000", "clum"), hit, claes("10:000", "myc reb fls"), claes("20:000", "myc reb fls"), "You have been slain by Talo."]
        survived = [LOGOGRAPH, claes("00:000", "AST SLCK ANO"), hit, claes("10:000", "clum"), claes("11:000", "clum")]
        logs = [kb.parse_rows("2026-11-01_claes_runewarden-vs-pariah_loss_aaa.txt", fatal),
                kb.parse_rows("2026-11-01_claes_runewarden-vs-pariah_win_bbb.txt", survived),
                kb.parse_rows("2026-11-01_claes_runewarden-vs-pariah_win_ccc.txt", survived)]
        for log in logs:
            log.id = log.name.rsplit("_", 1)[-1][:-4]
        return R.analyse(logs)

    def test_a_rule_with_no_skill_counts_one_false_alarm_per_survived_log(self):
        null = R.null_rule(self.small_analysis())
        self.assertEqual((null["logs"], null["deaths"]), (3, 1))
        self.assertAlmostEqual(null["fraction"], 2 / 3.0)
        self.assertEqual(len(null["rows"]), 1)
        self.assertAlmostEqual(null["rows"][0]["lead"], 10.0)

    def test_like_against_like_puts_both_sides_on_one_count(self):
        reps = [types.SimpleNamespace(log=types.SimpleNamespace(id="fatal"), death_t=1.0), types.SimpleNamespace(log=types.SimpleNamespace(id="lived"), death_t=None)]
        rules = {rule["id"]: {"false_survived": [], "false_lost": [], "warned": []} for rule in R.RULES}
        rules["airlord.pressure"] = {"false_survived": [("lived", 1)], "false_lost": [("fatal", 2)], "warned": [{}]}
        a = {"reps": reps, "rules": rules, "labels": {"softlock": {"false": [("fatal", 1), ("lived", 2), ("lived", 3)], "n": 2}}}
        fair = R.like_against_like(a)
        self.assertEqual(fair["in_fatal"], [("fatal", 1)])
        self.assertEqual(fair["baseline"], 0.5)
        self.assertEqual(dict((r[0], r[1:]) for r in fair["rows"])["airlord.pressure"], (2, 3, 2 / 3.0))

    def test_the_real_page_carries_every_figure_beside_the_verdict(self):
        logs = kb.load_all()
        a = R.analyse(logs, force_excluded=("Elmer",))
        text = R.render_page(a, logs)
        reading = R.plan_reading(a)
        self.assertIn(R.plan_sentence(reading), text.split("## The gate")[0])
        self.assertIn("If the rule that warned must match the kill: %d of %d" % (reading["matched"]["n"], reading["matched"]["total"]), text)
        self.assertIn("still be on within 5 s of death: %d of %d" % (reading["still_on"]["n"], reading["still_on"]["total"]), text)
        fair = R.like_against_like(a)
        self.assertIn("the baseline over survived logs is %d / (%d + %d)" % (fair["survived"], fair["survived"], fair["warned"]), text)
        self.assertIn("first `Health lost` row", text)
        self.assertIn("Chance of 5 s or more", text)
        for line in R.runewarden_2h_note(a):
            self.assertIn(line, text)
        if a["rules"]["sentinel.tripimpale"]["fought_survived"] == ["uW_VbgR"]:
            self.assertIn("`sentinel.tripimpale` was tested only on `uW_VbgR`", text)

    def test_the_gate_on_the_reviewed_chain_rows(self):
        # 3ys7NuHA rows 4160-4161 print pressure(3) on a prompt that wraps before its limb block.
        path = os.path.join(kb.LOGS, ELMER)
        rep = R.run_log(kb.parse(path))
        self.assertEqual(fired(rep, "airlord.pressure"), [577, 3120, 4160])


class Note2H(unittest.TestCase):
    def analysis(self, reps, counted=("airlord.pressure", "runewarden.2h"), g4=None):
        rules = {"runewarden.2h": {"fought_survived": [rep.log.id for rep in reps]}}
        rows = g4 or [("airlord.pressure", "FAIL", 0.75), ("runewarden.2h", "PASS", 0.0)]
        gate = {"g4_rows": rows, "counted": [{"warning": {"rule": rid}} for rid in counted]}
        return {"reps": reps, "rules": rules, "gate": gate}

    def rep(self, name, **terms):
        rep = types.SimpleNamespace(log=types.SimpleNamespace(id=name), last_t=100.0, first_t=0.0, allowed_from={"runewarden.2h": 40.0},
                                    terms_2h=dict(dict.fromkeys(("prone", "leg2", "both", "impaled", "twohand"), 0), **terms))
        return rep

    def test_the_note_stands_while_no_survived_fight_met_the_rules_terms(self):
        text = R.runewarden_2h_note(self.analysis([self.rep("x"), self.rep("y")]))[0]
        self.assertIn("its 2 survived fights show 0 prompts with prone or a level 2 leg and no two-handed weapon", text)
        self.assertIn("`x` 60.0 of 100.0 s", text)
        self.assertIn("no rule both warned on a no-lock death and passed a real false-alarm test", text)

    def test_a_later_log_can_clear_the_note(self):
        for term in ("prone", "leg2", "impaled", "twohand"):
            self.assertEqual(R.runewarden_2h_note(self.analysis([self.rep("x"), self.rep("y", **{term: 1})])), [], term)

    def test_the_terms_are_counted_from_the_walk(self):
        rows = ["The sleizak rune flashes bright upon a bastard sword rough-hewn from a sapling in the hands of", "Blonk.",
                claes("41:000", "la1 clum", "Blonk"), claes("42:924", "la1 RL2 sfrac(2) PR", "Blonk"), claes("43:000", "PR", "Blonk")]
        rep = replay(CLAES, rows)
        self.assertEqual(rep.terms_2h["both"], 1)
        self.assertEqual(rep.terms_2h["prone"], 2)
        self.assertEqual(rep.terms_2h["leg2"], 1)
        self.assertEqual(rep.terms_2h["twohand"], 1)

    def test_a_real_page_keeps_the_note_until_a_log_clears_it(self):
        logs = kb.load_all()
        a = R.analyse(logs)
        reps = [rep for rep in a["reps"] if rep.log.id in a["rules"]["runewarden.2h"]["fought_survived"]]
        clear = any(rep.terms_2h["prone"] or rep.terms_2h["leg2"] or rep.terms_2h["impaled"] or rep.terms_2h["twohand"] for rep in reps)
        self.assertEqual(bool(R.runewarden_2h_note(a)), not clear)


class Check(unittest.TestCase):
    def test_check_finds_a_difference_and_passes_a_match(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "page.md")
            with open(path, "w", encoding="utf-8", newline="\n") as fh:
                fh.write("one\n")
            R.ROOT, root = tmp, R.ROOT
            try:
                self.assertEqual(R.check({path: "one\n"}), 0)
                self.assertEqual(R.check({path: "two\n"}), 1)
                self.assertEqual(R.check({os.path.join(tmp, "missing.md"): "one\n"}), 1)
            finally:
                R.ROOT = root

    def test_check_ignores_a_crlf_checkout(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "page.md")
            with open(path, "wb") as fh:
                fh.write(b"one\r\ntwo\r\n")
            R.ROOT, root = tmp, R.ROOT
            try:
                self.assertEqual(R.check({path: "one\ntwo\n"}), 0)
            finally:
                R.ROOT = root


if __name__ == "__main__":
    unittest.main()
