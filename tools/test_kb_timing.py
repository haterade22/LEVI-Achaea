"""Tests for tools/kb_timing.py. The fixtures are rows copied from real logs, one set per family. The row cited above a
fixture is where it came from. A few times in the fight fixtures are moved so that a removed rule changes the answer.

    python -B tools/test_kb_timing.py
"""
import importlib.util
import contextlib
import io
import json
import os
import re
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("kb_timing", os.path.join(HERE, "kb_timing.py"))
kb = importlib.util.module_from_spec(spec)
spec.loader.exec_module(kb)

CLAES = "2026-11-01_claes_runewarden-vs-serpent_loss_azbErKcK.txt"
HEADER = ("# LEVI fight log | version 4.7.470 | started 2026-11-01 15:00:00 | opponent Sadey | our class Monk "
          "| started by hand | rounds raw")


def prompts(log):
    return [r for r in log if r.kind == "prompt"]


def lines_with_time(log):
    return [(r.text, r.time) for r in log if r.kind == "line"]


class ClaesPrompts(unittest.TestCase):
    # azbErKcK rows 3735-3738.
    ROWS = [
        "H:5378|93% M:4938|92%  19:17:45:272  [ Thato ][0|94.4|0|0|59|0][AST hchon wear PAR SLCK DARK ",
        "naus ANO disl] ",
        "[Prio]: Darkshade (1)",
        "Thato takes a long drag off her pipe.",
        "H:5378|93% M:4938|92%  19:17:45:641  [ Thato ][0|94.4|0|0|59|0][AST hchon wear PAR SLCK DARK ",
        "naus ANO disl] ",
    ]

    def test_a_wrapped_prompt_keeps_the_board_from_its_second_row(self):
        log = kb.parse_rows(CLAES, self.ROWS)
        first = prompts(log)[0]
        self.assertEqual(first.board, ["AST", "hchon", "wear", "PAR", "SLCK", "DARK", "naus", "ANO", "disl"])
        self.assertEqual(first.span, 2)
        self.assertEqual(log.wrapped, 2)
        self.assertEqual(log.prompts, 2)

    def test_the_wrapped_row_is_not_left_behind_as_a_line(self):
        log = kb.parse_rows(CLAES, self.ROWS)
        self.assertNotIn("naus ANO disl] ", [r.text for r in log if r.kind == "line"])

    def test_an_open_bracket_at_the_end_of_a_cut_log_still_gives_the_board(self):
        # uW_VbgR rows 556-557: the file stops inside the board, and the next row closes nothing.
        rows = ["H:17258|203% M:6949|99% E:99% W:98% [NE|D|SE] R:0 09:36.45-ebd- Shaping : 4[43|0|0|0|0|0] "
                "[IMP PAR SLCK hall ANO AST SENS hlch ADD naus TRUELOCKED", " "]
        log = kb.parse_rows("2026-11-01_unknown_earthlord-vs-sentinel_noresult_uW_VbgR.txt", rows)
        self.assertIn("TRUELOCKED", prompts(log)[0].board)
        self.assertEqual(log.wrapped, 0)
        self.assertEqual(log[-1].text, " ")

    def test_the_real_azb_board_around_row_3736_parses_across_the_wrap(self):
        path = os.path.join(kb.LOGS, CLAES)
        log = kb.parse(path)
        hit = [r for r in prompts(log) if r.n <= 3736 < r.n + r.span]
        self.assertEqual(len(hit), 1)
        self.assertEqual(hit[0].n, 3735)
        self.assertIn("ANO", hit[0].board)
        self.assertAlmostEqual(hit[0].time % 60, 45.272, places=3)


class NextPromptStamp(unittest.TestCase):
    ROWS = [
        "H:5378|93% M:4938|92%  19:17:45:272  [ Thato ][0|94.4|0|0|59|0][PAR] ",
        "Thato takes a long drag off her pipe.",
        "You may eat another plant or mineral. Eat (1.641)",
        "H:5378|93% M:5013|94%  19:17:46:407  [ Thato ][0|94.4|0|0|59|0][PAR] ",
        "You have been slain by Thato.",
    ]

    def test_a_row_takes_the_next_prompts_stamp_not_the_previous_one(self):
        log = kb.parse_rows(CLAES, self.ROWS)
        expected = 19 * 3600 + 17 * 60 + 46.407
        self.assertAlmostEqual(lines_with_time(log)[0][1], expected, places=3)
        self.assertAlmostEqual(lines_with_time(log)[1][1], expected, places=3)

    def test_a_row_after_the_last_prompt_has_no_time(self):
        log = kb.parse_rows(CLAES, self.ROWS)
        self.assertIsNone(log[-1].time)

    def test_our_recorder_keeps_each_rows_own_stamp_beside_the_rule(self):
        rows = [HEADER, "15:00:00.100 > stand", "15:00:00.200 | You stand up.", "15:00:00.300 P H: Full cexkdb-"]
        log = kb.parse_rows("2026-11-01_150000_Sadey.log", rows)
        sent = [r for r in log if r.kind == "sent"][0]
        self.assertAlmostEqual(sent.own, 15 * 3600 + 0.1, places=3)
        self.assertAlmostEqual(sent.time, 15 * 3600 + 0.3, places=3)


class Stamps(unittest.TestCase):
    def test_elmer_ss_mmm_rolls_over_at_60(self):
        # Z5cyffxx rows 7, 14, 16.
        rows = ["H:6649|100% M:5760|100% E:100% W:100% [NW|SW] Rage:0 59:408 -ex-",
                "H:6649|100% M:5760|100% E:100% W:100% [NW|SW] Rage:0 59:529 -e-",
                "H:6649|100% M:5741|99% E:100% W:100% [NW|SW] Rage:0 01:144 -ex-"]
        log = kb.parse_rows("2026-11-01_elmer_alchemist-vs-serpent_loss_Z5cyffxx.txt", rows)
        self.assertEqual(log.family, "elmer")
        self.assertAlmostEqual(prompts(log)[2].time - prompts(log)[1].time, 1.615, places=3)

    def test_elmer_any_step_back_is_the_wrap_even_a_short_one(self):
        # 40 s, then 15 s, is a 35 s gap across the minute. The step back is under half the period.
        rows = ["H:6649|100% M:5760|100% E:100% W:100% [NW|SW] Rage:0 40:000 -ex-",
                "H:6649|100% M:5760|100% E:100% W:100% [NW|SW] Rage:0 15:000 -e-"]
        log = kb.parse_rows("2026-11-01_elmer_alchemist-vs-serpent_loss_Z5cyffxx.txt", rows)
        self.assertAlmostEqual(prompts(log)[1].time - prompts(log)[0].time, 35.0, places=3)
        self.assertEqual(log.held_stamps, 0)

    def test_earth_lord_min_sec_rolls_over_at_the_hour(self):
        rows = ["H:8470|100% M:6964|100% E:100% W:100% [W] R:0 59:58.24-e- Shaping : 0[0|0|0|0|0|0] ",
                "H:8470|100% M:6964|100% E:100% W:100% [W] R:0 00:01.34-e- Shaping : 0[0|0|0|0|0|0] "]
        log = kb.parse_rows("2026-11-01_unknown_earthlord-vs-blademaster_loss_OwkA-G99.txt", rows)
        self.assertAlmostEqual(prompts(log)[1].time - prompts(log)[0].time, 3.10, places=2)

    def test_a_bad_dot_00_stamp_that_goes_back_moves_forward_one_second(self):
        # kAQnlFAW rows around 736: 04:00:30.99, then 04:00:30.00, then 04:00:31.23.
        rows = ["4422(72%|92%) 99e 99w eT ckdb 200 04:00:30.99  0 --",
                "4422(72%|92%) 99e 99w eT ckdb 200 04:00:30.00  0 --",
                "4422(72%|92%) 99e 99w eT ckdb 200 04:00:31.23  0 --"]
        log = kb.parse_rows("2026-11-01_nikita_depthswalker-vs-bard_win_kAQnlFAW.txt", rows)
        times = [r.time % 60 for r in prompts(log)]
        self.assertAlmostEqual(times[1], 31.00, places=2)
        self.assertEqual(log.fixed_stamps, 1)
        self.assertEqual(sorted(times), times)

    def test_a_dot_00_stamp_that_goes_forward_stays(self):
        # L8LSw7xD rows 813-817: 04:22:02.79, 04:22:03.00, 04:22:03.20. One second on would pass the next prompt.
        rows = ["6113(100%|92%) 100e 98w T ckdb 125 04:22:02.79  0 -- ()",
                "6113(100%|92%) 100e 98w T ckdb 125 04:22:03.00  0 -- ()",
                "6113(100%|92%) 100e 98w eT ckdb 125 04:22:03.20  0 -- ()"]
        log = kb.parse_rows("2026-11-01_nikita_depthswalker-vs-bard_win_L8LSw7xD.txt", rows)
        self.assertAlmostEqual(prompts(log)[1].time % 60, 3.00, places=2)
        self.assertEqual(log.fixed_stamps, 0)

    def test_an_earth_lord_bad_dot_00_stamp_is_fixed_too(self):
        # uW_VbgR: 09:18.53, then row 109 at 09:18.00.
        rows = ["H:24612|290% M:6741|96% E:99% W:100% [NE|D|SE] R:0 09:18.53-ed- Shaping : 1[0|0|0|0|0|0] [PAR] ",
                "H:24061|284% M:6741|96% E:99% W:100% [NE|D|SE] R:0 09:18.00-ed- Shaping : 1[0|0|0|0|0|0]  ( -551h 6% ) (144B)[PAR clum ADD] "]
        log = kb.parse_rows("2026-11-01_unknown_earthlord-vs-sentinel_noresult_uW_VbgR.txt", rows)
        self.assertAlmostEqual(prompts(log)[1].time, 9 * 60 + 19.00, places=2)
        self.assertEqual(prompts(log)[1].board, ["PAR", "clum", "ADD"])

    def test_midnight_does_not_go_back(self):
        rows = ["H:5406|93% M:5113|96%  23:59:59:697  [ Thato ][0|0|0|0|0|0]",
                "H:5406|93% M:5113|96%  00:00:01:120  [ Thato ][0|0|0|0|0|0]"]
        log = kb.parse_rows(CLAES, rows)
        self.assertAlmostEqual(prompts(log)[1].time - prompts(log)[0].time, 1.423, places=3)

    def test_our_recorder_crosses_midnight(self):
        rows = [HEADER, "23:59:59.900 P H: Full cexkdb-", "00:00:00.100 P H: Full cexkdb-"]
        log = kb.parse_rows("2026-11-01_235959_Sadey.log", rows)
        self.assertAlmostEqual(prompts(log)[1].time - prompts(log)[0].time, 0.2, places=3)

    def test_a_small_step_back_is_held_and_not_taken_for_midnight(self):
        rows = ["H:5406|93% M:5113|96%  19:14:41:697  [ Thato ][0|0|0|0|0|0]",
                "H:5406|93% M:5113|96%  19:14:41:600  [ Thato ][0|0|0|0|0|0]"]
        log = kb.parse_rows(CLAES, rows)
        self.assertEqual(log.held_stamps, 1)
        self.assertEqual(prompts(log)[1].time, prompts(log)[0].time)


class Boards(unittest.TestCase):
    def test_the_limb_block_and_the_target_are_not_a_board(self):
        # s98kPGv6 row 14, and the same prompt before the limb block prints.
        rows = ["H:5775|100% M:5313|100%  18:57:40:206  [ Talo ][0|0|0|0|0|0] ( +755h 13% )",
                "H:5775|100% M:5313|100%  18:57:41:226  [ Talo ]"]
        log = kb.parse_rows(CLAES, rows)
        self.assertEqual([p.board for p in prompts(log)], [[], []])

    def test_mystor_h_and_true_are_decoys_not_boards(self):
        # t54WWU6b row 354, and EveP2TVe rows 997-999.
        rows = ["[B|E] [CDBK] H:6205|99% M:5662|99% [3] [Rain]:0 K:34% [h] [haem, SLCK, ANO, IMP, wear, AST] Bl:393 ",
                "10:29:20 (0) [Agathon]: ",
                "[B|E] [CDBK] H:6265|100% M:6012|100% [6.83] [Oak]:9 K:64% [true] [mleech, SLCK, ANO, IMP, ",
                "naus, AST] +2823h +2509m ",
                "20:17:53 (1) [Belaziel]: "]
        log = kb.parse_rows("2026-10-11_mystor_shikudo-vs-shaman_loss_t54WWU6b.txt", rows)
        first, second = prompts(log)
        self.assertEqual(first.board, ["haem", "SLCK", "ANO", "IMP", "wear", "AST"])
        self.assertEqual(first.lock, "h")
        self.assertEqual(second.board, ["mleech", "SLCK", "ANO", "IMP", "naus", "AST"])
        self.assertEqual(second.lock, "true")
        self.assertEqual(log.wrapped, 1)

    def test_a_lone_mystor_decoy_is_an_empty_board(self):
        rows = ["[B|E] [CDBK] H:6265|100% M:6012|100% [6.83] [Oak]:9 K:64% [true] ", "20:17:53 (1) [Belaziel]: "]
        log = kb.parse_rows("2026-10-11_mystor_shikudo-vs-depthswalker_loss_EveP2TVe.txt", rows)
        self.assertEqual(prompts(log)[0].board, [])
        self.assertEqual(prompts(log)[0].lock, "true")

    def test_mystor_stamp_has_its_own_row_and_is_not_a_wrap(self):
        rows = ["[B|E] [CDBK] H:6265|100% M:5278|93% [3] [Rain]:0 K:12% [PAR] ", "10:29:07 (0) [Agathon]: "]
        log = kb.parse_rows("2026-10-11_mystor_shikudo-vs-shaman_loss_t54WWU6b.txt", rows)
        self.assertEqual(log.prompts, 1)
        self.assertEqual(log.wrapped, 0)
        self.assertEqual(prompts(log)[0].time, 10 * 3600 + 29 * 60 + 7)

    def test_nikita_tag_on_the_next_row(self):
        # X8pRorzR rows 1-2.
        rows = ["5401(88%|84%) 99e 93w T ckdb 0 14:54:16.91  0 --", " (hyper|HYPOCHONDRIA|dark|frat|clu|AST)"]
        log = kb.parse_rows("2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt", rows)
        self.assertEqual(prompts(log)[0].board, ["hyper", "HYPOCHONDRIA", "dark", "frat", "clu", "AST"])
        self.assertEqual(log.wrapped, 1)

    def test_nikita_lock_label_is_not_the_board(self):
        # X8pRorzR rows 363-364: the label's own parenthesis on the prompt, and the board on the next row.
        rows = ["5401(93%|79%) 99e 92w eT ckdb 100 14:54:31.93  0 --TR/Hardlock(touch tree)",
                " (w|hyper|maso|ANO|nau|frat|IMP|SLI|AST|VERT|disl)"]
        log = kb.parse_rows("2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt", rows)
        self.assertEqual(prompts(log)[0].board[:4], ["w", "hyper", "maso", "ANO"])
        self.assertEqual(prompts(log)[0].span, 2)
        self.assertEqual(log.wrapped, 1)

    def test_a_nikita_board_on_its_own_row_still_reads_after_a_label(self):
        rows = ["5401(93%|79%) 99e 92w eT ckdb 100 14:54:31.93  0 --TR/Hardlock(touch tree) (w|ANO)"]
        log = kb.parse_rows("2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt", rows)
        self.assertEqual(prompts(log)[0].board, ["w", "ANO"])
        self.assertEqual(log.wrapped, 0)

    def test_nikita_mapper_counter_is_not_the_board(self):
        # kAQnlFAW row 19.
        rows = ["6113(100%|100%) 99e 99w exT ckdb 0 03:59:57.49  0 -- ()(9 - nw)"]
        log = kb.parse_rows("2026-11-01_nikita_depthswalker-vs-bard_win_kAQnlFAW.txt", rows)
        self.assertEqual(prompts(log)[0].board, [])

    def test_sentinel_board_across_a_wrap_keeps_locks_out(self):
        # Sentinel rows 2591-2592.
        rows = ["09:59:58:324 [10795] [70] |(Grulk)|[ [ sen prone ANO Rl2 clu SLI WEA nau hal IMP PAR AST add (Locks: soft, venom, hard,",
                " true) ]]  "]
        log = kb.parse_rows("2026-08-19_leviticus_blademaster-vs-sentinel_loss_Sentinel.txt", rows)
        p = prompts(log)[0]
        self.assertEqual(p.board[:3], ["sen", "prone", "ANO"])
        self.assertNotIn("true)", p.board)
        self.assertEqual(p.lock, "soft, venom, hard, true")
        self.assertEqual(log.wrapped, 1)

    def test_a_client_log_of_a_recorded_fight_stays_out_of_the_pools(self):
        rows = ["08:09:44:001 [13357] [99] |(Lauryyn)|[]  "]
        log = kb.parse_rows("2026-11-03_shikudo-group-alias.txt", rows)
        self.assertEqual(log.logger, "Ours, client log")
        self.assertEqual(log.family, "sentinel")
        self.assertIn(log.name, kb.SAME_FIGHT)

    def test_group_log_empty_boards(self):
        rows = ["11:26:23:777 [13357] [99] |(659477)|[]  ", "11:26:49:440 [13357] [99] |(Sadey)|[ [ ]]  "]
        log = kb.parse_rows("2026-10-27_shikudo-group-mhaldor.txt", rows)
        self.assertEqual([p.board for p in prompts(log)], [[], []])

    def test_elmer_wrap_inside_the_damage_group_and_limbs_are_not_the_board(self):
        # 3ys7NuHA rows 2662-2663.
        rows = ["H:5768|82% M:3152|91% E:99% W:99% [S|SE|SW|NW|N] Rage:0 02:197 -e*- Stance: None Form: X Kata: 3 Kai: 52%[41|52.4|68.4|38|60.8|53.2] ( +1114h 15% ",
                ")[ddn mleech] "]
        log = kb.parse_rows("2026-11-01_elmer_shikudo-vs-airlord_win_3ys7NuHA.txt", rows)
        self.assertEqual(prompts(log)[0].board, ["ddn", "mleech"])
        self.assertEqual(log.wrapped, 1)

    def test_elmer_prompt_that_wraps_before_its_limb_block_keeps_its_board(self):
        # 3ys7NuHA rows 4160-4161. The first row ends "Kai: " with every bracket closed.
        rows = ["H:4874|69% M:3352|97% E:100% W:99% [S|SE|SW|NW|N] Rage:0 44:523 -e*- Stance: None Form: X Kata: 3 Kai: ",
                "90%[96.5|125|98.8|53.2|98.8|98.8][pressure(3) mleech] ",
                "You pant heavily."]
        log = kb.parse_rows("2026-11-01_elmer_shikudo-vs-airlord_win_3ys7NuHA.txt", rows)
        self.assertEqual(prompts(log)[0].board, ["pressure(3)", "mleech"])
        self.assertEqual(prompts(log)[0].span, 2)
        self.assertEqual(log.wrapped, 1)
        self.assertEqual([r.text for r in log if r.kind == "line"], ["You pant heavily."])

    def test_that_wrap_can_run_onto_a_third_row(self):
        rows = ["H:4874|69% M:3352|97% E:100% W:99% [S|SE] Rage:0 44:523 -e*- Stance: None Form: X Kata: 3 Kai: ",
                "90%[96.5|125|98.8|53.2|98.8|98.8][pressure(3) ", "mleech] "]
        log = kb.parse_rows("2026-11-01_elmer_shikudo-vs-airlord_win_3ys7NuHA.txt", rows)
        self.assertEqual(prompts(log)[0].board, ["pressure(3)", "mleech"])
        self.assertEqual(prompts(log)[0].span, 3)

    def test_a_prompt_that_has_its_limb_block_takes_no_such_row(self):
        rows = ["H:1|1% M:1|1% E:100% W:99% [S] Rage:0 44:523 -e*- Kai: 90%[96.5|125|98.8|53.2|98.8|98.8][PAR] ",
                "90%[96.5|125|98.8|53.2|98.8|98.8] is a line here"]
        log = kb.parse_rows("2026-11-01_elmer_shikudo-vs-airlord_win_3ys7NuHA.txt", rows)
        self.assertEqual(prompts(log)[0].board, ["PAR"])
        self.assertEqual(prompts(log)[0].span, 1)

    def test_blademaster_prints_no_board(self):
        # KtdftABt row 101.
        rows = ["H:6518|93% M:4932|100% W:21962|99%  22:50:19 -exckbd- Sh: 14 St: Thyr [ Kuririn ]"]
        log = kb.parse_rows("2026-11-01_unknown_blademaster-vs-monk_win_KtdftABt.txt", rows)
        self.assertEqual(log.resolution, 1.0)
        self.assertIsNone(prompts(log)[0].board)

    def test_our_recorder_board_is_the_gmcp_set(self):
        rows = [HEADER, "15:00:00.100 +aff asthma", "15:00:00.200 +aff weariness", "15:00:00.300 -aff asthma",
                "15:00:00.400 P H: Full cexkdb-"]
        log = kb.parse_rows("2026-11-01_150000_Sadey.log", rows)
        self.assertEqual(prompts(log)[0].board, ["weariness"])

    def test_a_log_with_no_stamped_prompt_has_no_family(self):
        # o6UKnyyy rows 101-102.
        rows = ["9227h, 10560m cekdb-   (||-) (||-) (||-)", "You must regain equilibrium first."]
        log = kb.parse_rows("2026-10-19_tabethys_magi-group_kalys_o6UKnyyy.txt", rows)
        self.assertIsNone(log.family)
        self.assertEqual(log.unstamped, 1)
        self.assertEqual(log.prompts, 0)

    def test_crlf_and_lf_read_the_same(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "a.log")
            with open(path, "wb") as fh:
                fh.write(b"a\r\nb\r\n")
            self.assertEqual(kb.read_rows(path), ["a", "b"])


def clock(rows, channel, name=CLAES):
    log = kb.parse_rows(name, rows)
    return [s for s in kb.clock_samples(log)[0] if s[0] == channel]


class Clocks(unittest.TestCase):
    def test_a_printed_timer_is_read(self):
        rows = ["You may utilise the tree tattoo again. Tree (13.945)", "H:1|1% M:1|1%  19:17:48:677  [ T ][0|0|0|0|0|0]"]
        self.assertEqual(clock(rows, "tree")[0][1], 13.945)

    def test_mystors_recov_row_is_a_printed_timer(self):
        # t54WWU6b rows 106-109.
        rows = ["You may eat another plant or mineral.", "[Eat Recov: 1.59s]",
                "[B|E] [CDBK] H:6265|100% M:5278|93% [3] [Rain]:0 K:12% [PAR] ", "10:29:07 (0) [Agathon]: "]
        self.assertEqual(clock(rows, "eat", "2026-10-11_mystor_shikudo-vs-shaman_loss_t54WWU6b.txt")[0][1], 1.59)

    def test_line_to_line_pairs_the_start_with_the_recovery(self):
        rows = [HEADER, "15:00:00.000 | You eat a magnesium chip.", "15:00:00.002 P H: Full cexkdb-",
                "15:00:01.500 | You may eat another plant or mineral.", "15:00:01.502 P H: Full cexkdb-"]
        sample = clock(rows, "eat", "2026-11-01_150000_Sadey.log")[0]
        self.assertIsNone(sample[1])
        self.assertAlmostEqual(sample[2], 1.5, places=3)

    def test_quartz_does_not_restart_the_eat_clock(self):
        # ours/2026-10-27_112717 rows 7487-7494 hold the lines. The quartz time is moved so that a restart would show.
        rows = [HEADER, "15:00:00.000 | You eat a magnesium chip.", "15:00:00.002 P H: Full cexkdb-",
                "15:00:01.000 | You eat a quartz grain.", "15:00:01.002 P H: Full cexkdb-",
                "15:00:01.500 | You may eat another plant or mineral.", "15:00:01.502 P H: Full cexkdb-"]
        self.assertAlmostEqual(clock(rows, "eat", "2026-11-01_150000_Sadey.log")[0][2], 1.5, places=3)

    def test_moss_does_not_restart_the_eat_clock(self):
        rows = [HEADER, "15:00:00.000 | You eat a magnesium chip.", "15:00:00.002 P H: Full cexkdb-",
                "15:00:01.000 | You eat a potash crystal.", "15:00:01.002 P H: Full cexkdb-",
                "15:00:01.500 | You may eat another plant or mineral.", "15:00:01.502 P H: Full cexkdb-",
                "15:00:06.900 | You may eat another bit of irid moss or potash.", "15:00:06.902 P H: Full cexkdb-"]
        name = "2026-11-01_150000_Sadey.log"
        self.assertAlmostEqual(clock(rows, "eat", name)[0][2], 1.5, places=3)
        self.assertAlmostEqual(clock(rows, "moss", name)[0][2], 5.9, places=3)

    def test_pear_is_on_the_smoke_clock_not_the_eat_clock(self):
        # s98kPGv6 rows 211-215 hold the eat, and the lungs line follows with no smoke between.
        rows = ["[Curing]: EAT PEAR", "You eat a prickly pear.", "The oppressive pressure weighing down on you lifts.",
                "H:4934|85% M:4888|92%  18:57:50:871  [ Talo ][0|0|0|0|0|0]",
                "Your lungs have recovered enough to smoke another mineral or plant.",
                "H:4934|85% M:4888|92%  18:57:52:371  [ Talo ][0|0|0|0|0|0]",
                "You may eat another plant or mineral.",
                "H:4934|85% M:4888|92%  18:57:52:500  [ Talo ][0|0|0|0|0|0]"]
        name = "2026-11-01_claes_runewarden-vs-airlord_loss_s98kPGv6.txt"
        self.assertAlmostEqual(clock(rows, "smoke", name)[0][2], 1.5, places=3)
        log = kb.parse_rows(name, rows)
        samples, unpaired = kb.clock_samples(log)
        self.assertEqual([s for s in samples if s[0] == "eat"], [])
        self.assertEqual(unpaired["eat"], 1)

    def test_calcite_is_on_the_smoke_clock_too(self):
        rows = ["You eat a calcite mote.", "H:1|1% M:1|1%  18:57:50:871  [ T ][0|0|0|0|0|0]",
                "Your lungs have recovered enough to smoke another mineral or plant.",
                "H:1|1% M:1|1%  18:57:52:371  [ T ][0|0|0|0|0|0]"]
        self.assertAlmostEqual(clock(rows, "smoke")[0][2], 1.5, places=3)

    def test_a_salve_sorts_by_its_curing_row_and_not_by_its_length(self):
        # CxxKSMq rows 1540-1541 and 1700-1701.
        rows = ["[Curing]: APPLY RESTORATION TO LEGS", "You take out some salve and quickly rub it on your legs.",
                "H:1|1% M:1|1%  22:28:44:000  [ B ][0|0|0|0|0|0]", "You may apply another salve to yourself. Legs (0.905)",
                "H:1|1% M:1|1%  22:28:44:905  [ B ][0|0|0|0|0|0]"]
        self.assertEqual(clock(rows, "restoration")[0][1], 0.905)

    def test_a_limb_line_proves_restoration(self):
        # CxxKSMq rows 891-893.
        rows = ["You take out some salve and quickly rub it on your legs.", "H:1|1% M:1|1%  22:28:19:210  [ B ][0|0|0|0|0|0]",
                "Your left leg feels stronger and healthier.", "You may apply another salve to yourself. Legs (3.984)",
                "H:1|1% M:1|1%  22:28:23:194  [ B ][0|0|0|0|0|0]"]
        self.assertEqual(clock(rows, "restoration")[0][1], 3.984)

    def test_a_salve_with_no_evidence_stays_unknown(self):
        rows = ["You take out some salve and quickly rub it on your legs.", "H:1|1% M:1|1%  22:28:19:210  [ B ][0|0|0|0|0|0]",
                "You may apply another salve to yourself. Legs (0.9)", "H:1|1% M:1|1%  22:28:20:110  [ B ][0|0|0|0|0|0]"]
        self.assertEqual(len(clock(rows, "salve_unknown")), 1)
        self.assertEqual(clock(rows, "salve_short"), [])

    def test_an_immunity_sip_does_not_start_the_health_clock(self):
        rows = ["[Curing]: SIP IMMUNITY", "You take a drink from an oaken vial.", "H:1|1% M:1|1%  22:28:19:000  [ B ][0|0|0|0|0|0]",
                "Your system is able to absorb antidotes once again.", "H:1|1% M:1|1%  22:28:26:500  [ B ][0|0|0|0|0|0]"]
        self.assertAlmostEqual(clock(rows, "immunity")[0][2], 7.5, places=3)
        self.assertEqual(clock(rows, "sip"), [])

    def test_a_pool_uses_the_printed_value_and_never_a_1s_stamp(self):
        self.assertEqual(kb.preferred(("eat", 1.59, 2.0, 0, 0), 1.0), 1.59)
        self.assertEqual(kb.preferred(("eat", None, 1.5, 0, 0), 0.001), 1.5)
        self.assertIsNone(kb.preferred(("eat", None, 2.0, 0, 0), 1.0))

    def test_the_usable_rule(self):
        self.assertEqual(kb.usable(kb.stats([1.5] * 9))[0], False)
        self.assertIn("under 10", kb.usable(kb.stats([1.5] * 9))[1])
        self.assertEqual(kb.usable(kb.stats([1.5] * 10))[0], True)
        wide = kb.stats([1.0] * 5 + [2.0] * 5)
        self.assertEqual(kb.usable(wide)[0], False)
        self.assertIn("over 0.2", kb.usable(wide)[1])

    def test_a_1_s_row_is_never_usable_and_the_pooled_rule_is_untouched(self):
        # Mystor's Moss reads 6.00 on 1 s stamps against his printed 5.91, with a width of 0 only because of the stamps.
        rows = []
        for sec in range(0, 120, 6):
            rows += ["You eat a piece of kelp.", "[B|E] [CDBK] H:1|1% M:1|1% [3] [Rain]:0 K:12% [PAR] ", "10:%02d:%02d (0) [A]: " % (29 + sec // 60, sec % 60),
                     "You may eat another plant or mineral.", "[B|E] [CDBK] H:1|1% M:1|1% [3] [Rain]:0 K:12% [PAR] ", "10:%02d:%02d (0) [A]: " % (29 + sec // 60, sec % 60 + 2)]
        log = kb.parse_rows("2026-10-11_mystor_shikudo-vs-shaman_loss_t54WWU6b.txt", rows)
        row = [r for r in kb.build_clocks([log])["eat"]["by_logger"] if r["method"] == "line_1s"][0]
        self.assertGreaterEqual(row["stats"]["n"], 10)
        self.assertEqual(row["stats"]["spread"], 0.0)
        self.assertFalse(row["usable"])
        self.assertEqual(row["why_not"], "1 s stamps cannot resolve this clock")
        self.assertTrue(kb.usable(row["stats"])[0])

    def test_the_width_sentence_is_read_from_the_numbers(self):
        def channel(title, usable, spread, without, rows=()):
            return {"title": title, "usable": usable, "stats": {"n": 50, "spread": spread}, "spread_without": without, "by_logger": list(rows)}
        printed = {"logger": "Nikita", "method": "printed", "stats": {"spread": 0.331}}
        line = {"logger": "Nikita", "method": "line", "stats": {"spread": 0.14}}
        clocks = {name: channel(name, True, 0.1, {}) for name, _ in kb.CHANNEL_NAMES}
        clocks["eat"] = channel("Eat", False, 0.23, {"Nikita": 0.189, "Claes": 0.239}, [printed, line])
        clocks["moss"] = channel("Moss", False, 0.21, {"Claes": 0.25})
        clocks["salve_unknown"] = channel("Mixed", False, 2.25, {"Nikita": 0.18})
        text = kb.pool_width_text({"clocks": clocks})
        self.assertIn("Eat 0.230: without Nikita 0.189 (their printed timer 0.331, their own stamps 0.140).", text)
        self.assertNotIn("Claes 0.239", text)
        self.assertIn("Moss 0.210: no single logger's removal passes it.", text)
        self.assertNotIn("Mixed", text)

    def test_percentiles(self):
        st = kb.stats([1.0, 2.0, 3.0, 4.0, 5.0])
        self.assertEqual(st["median"], 3.0)
        self.assertEqual(st["p10"], 1.4)
        self.assertEqual(st["p90"], 4.6)


class Stated(unittest.TestCase):
    def test_the_cooldown_field(self):
        self.assertEqual(kb.parse_cooldown("2.80 seconds of balance"), (2.8, "balance"))
        self.assertEqual(kb.parse_cooldown("4.00 seconds of balance symbol=Shield"), (4.0, "balance"))
        self.assertEqual(kb.parse_cooldown("1.60 seconds of prayer balance"), (1.6, "prayer balance"))

    def test_what_the_field_cannot_say_is_refused(self):
        for text in ("", "Balance cost varies based on weapon speed", "Equilibrium", "3.00 seconds of voice balance and 2.00 seconds of equilibrium"):
            self.assertIsNone(kb.parse_cooldown(text))

    def test_a_missing_stated_value_says_so(self):
        table = {("Shadowmancy", "Reap"): "", ("Weaponmastery", "Slice"): "Balance cost varies based on weapon speed"}
        self.assertEqual(kb.stated_value(table, None, None), (None, "no row in abilities.json"))
        self.assertIn("blank", kb.stated_value(table, "Shadowmancy", "Reap")[1])
        self.assertIn("cannot read", kb.stated_value(table, "Weaponmastery", "Slice")[1])

    def test_a_printed_cost_goes_to_the_ability_in_its_packet(self):
        rows = ["You touch the tattoo and a nearly invisible magical shield forms around you.", "Equilibrium used: 3.40s.",
                "H:1|1% M:1|1%  22:28:19:000  [ B ][0|0|0|0|0|0]"]
        log = kb.parse_rows(CLAES, rows)
        found = kb.own_costs([log])[0]
        self.assertEqual(found["Shield tattoo"]["Claes"], [3.4])

    def test_mystors_spent_row_is_the_same_cost(self):
        rows = ["You inhale deeply, purging yourself of your asthmatic condition.", "[Bal Spent: 2.8s]",
                "[B|E] [CDBK] H:6265|100% M:5278|93% [3] [Rain]:0 K:12% ", "10:29:07 (0) [Agathon]: "]
        log = kb.parse_rows("2026-10-11_mystor_shikudo-vs-shaman_loss_t54WWU6b.txt", rows)
        self.assertEqual(kb.own_costs([log])[0]["FITNESS"]["Mystor"], [2.8])

    def test_the_stated_rows_come_from_the_loggers_own_class(self):
        # Elmer and Mystor are Monks, so Kaido, not Discipline. Claes is a Runewarden, so Discipline, not Valour.
        rows = {name: (skill, ability) for name, skill, ability, _, _ in kb.OWN_COSTS}
        self.assertEqual(rows["FITNESS"], ("Kaido", "Fitness"))
        self.assertEqual(rows["Engage"], ("Discipline", "Engage"))

    def test_the_cost_rows_are_counted_whether_or_not_they_match_an_ability(self):
        # 2N1HTSWZ rows 269-273: a Shikudo combo prints its 2.1 s, and no curated ability names it.
        rows = ["You lash out with a straight kick at the left shoulder of Torvald.", "Balance used: 2.1s.",
                "You touch the tattoo and a nearly invisible magical shield forms around you.", "Equilibrium used: 3.40s.",
                "H:1|1% M:1|1%  22:28:19:000  [ B ][0|0|0|0|0|0]"]
        log = kb.parse_rows(CLAES, rows)
        self.assertEqual(kb.printed_cost_rows([log]), 2)
        self.assertEqual(sum(len(v) for by in kb.own_costs([log])[0].values() for v in by.values()), 1)

    def test_two_candidates_in_a_packet_are_not_guessed(self):
        rows = ["You touch the tattoo and a nearly invisible magical shield forms around you.",
                "You bring a curseward into being to protect you from harm.", "Equilibrium used: 3.40s.",
                "H:1|1% M:1|1%  22:28:19:000  [ B ][0|0|0|0|0|0]"]
        found, _, _, ambiguous = kb.own_costs([kb.parse_rows(CLAES, rows)])
        self.assertEqual(dict(found), {})
        self.assertEqual(ambiguous["equilibrium"], 1)

    def _gaps(self, rows):
        log = kb.parse_rows(CLAES, rows)
        log.id = "x"
        table = {("Subterfuge", "Doublestab"): "2.80 seconds of balance", ("Subterfuge", "Flay"): "2.00 seconds of balance"}
        return {r["ability"]: r for r in kb.build_opponents([log], table)}

    def test_the_gap_to_the_same_persons_next_attack(self):
        rows = ["Thato quickly pricks you with her dirk.", "H:1|1% M:1|1%  19:00:00:000  [ T ][0|0|0|0|0|0]",
                "Elmer quickly pricks you with his dirk.", "H:1|1% M:1|1%  19:00:01:000  [ T ][0|0|0|0|0|0]",
                "Thato sinks her fangs into your body and you wince in pain.", "H:1|1% M:1|1%  19:00:01:830  [ T ][0|0|0|0|0|0]"]
        r = self._gaps(rows)["DSTAB"]
        self.assertEqual([p["person"] for p in r["by_person"]], ["Thato"])
        self.assertEqual(r["stats"]["median"], 1.83)
        self.assertEqual(r["ratio_to_stated"], round(1.83 / 2.8, 3))

    def test_a_bundled_line_is_not_the_next_attack_and_a_long_gap_is_dropped(self):
        rows = ["Thato quickly pricks you with her dirk.", "Thato misses you with her dirk by a hair.",
                "H:1|1% M:1|1%  19:00:00:000  [ T ][0|0|0|0|0|0]",
                "Thato quickly pricks you with her dirk.", "H:1|1% M:1|1%  19:00:01:800  [ T ][0|0|0|0|0|0]",
                "Thato quickly pricks you with her dirk.", "H:1|1% M:1|1%  19:00:12:800  [ T ][0|0|0|0|0|0]"]
        r = self._gaps(rows)["DSTAB"]
        self.assertEqual(r["stats"]["n"], 1)
        self.assertEqual(r["stats"]["median"], 1.8)
        self.assertEqual(r["dropped"], {"10 s or more": 1, "no next attack": 1})

    def test_the_two_lines_of_one_flay_are_one_sample(self):
        # azbErKcK rows 3628-3629.
        rows = ["Thato flays away your shield defence.", "With fluid grace, Thato snaps her wrist, bringing a Razor Whip back to crack viciously into",
                "H:1|1% M:1|1%  19:00:00:000  [ T ][0|0|0|0|0|0]",
                "Thato quickly pricks you with her dirk.", "H:1|1% M:1|1%  19:00:01:640  [ T ][0|0|0|0|0|0]"]
        self.assertEqual(self._gaps(rows)["FLAY"]["stats"]["n"], 1)


ALIAS_FIGHT = [
    HEADER,
    # Raw: rows of the shape in ours/2026-10-27_112717, rows 111-125 and 216-231.
    "15:00:00.000 > queue addclear free g body",
    "15:00:00.000 > stand",
    "15:00:00.000 > mind impatience Sadey",
    "15:00:00.060 | [System]: Queued free commands cleared.",
    "15:00:00.062 | [System]: Added G BODY to your free queue.",
    "15:00:00.064 P H: Full cxkdb-",
    "15:00:00.080 | You must regain equilibrium first.",
    "15:00:00.082 | stand was added to your equilibrium queue.",
    "15:00:00.090 P H: Full cxkdb-",
    "15:00:02.000 | You have recovered equilibrium.",
    "15:00:02.002 | [System]: Running queued free command: MIND IMPATIENCE SADEY",
    "15:00:02.004 | You fill the mind of Sadey with an impatient feeling.",
    "15:00:02.006 | [System]: Running queued free command: G BODY",
    "15:00:02.008 P H: Full cxkdb-",
    # aconfig rounds alias: the first setalias row is the split.
    "15:00:03.000 > setalias lvfree stand/g body/combo Sadey frontkick right kuro right ruku right",
    "15:00:03.000 > queue addclear free lvfree",
    "15:00:03.060 | Alias \"lvfree\" will now execute: \"stand/g body/combo Sadey frontkick right kuro right ruku right\"",
    "15:00:03.062 P H: Full cxkdb-",
    "15:00:03.064 | [System]: Added LVFREE to your free queue.",
    "15:00:03.066 P H: Full cxkdb-",
    # A rewrite while the entry waits.
    "15:00:03.300 > setalias lvfree stand/g body/combo Sadey frontkick left kuro left ruku left",
    "15:00:03.300 > queue addclear free lvfree",
    "15:00:03.360 | Alias \"lvfree\" will now execute: \"stand/g body/combo Sadey frontkick left kuro left ruku left\"",
    "15:00:03.362 | [System]: Queued free commands cleared.",
    "15:00:03.364 | [System]: Added LVFREE to your free queue.",
    "15:00:03.366 P H: Full cxkdb-",
    "15:00:05.000 | You have recovered balance on your legs.",
    "15:00:05.001 | You have recovered balance on your left arm.",
    "15:00:05.002 | You have recovered balance on your right arm.",
    "15:00:05.004 | [System]: Running queued free command: LVFREE",
    "15:00:05.006 | You lash out with a straight kick at the left shoulder of Sadey.",
    "15:00:05.008 P H: Full cexkdb-",
]


class Scoreboard(unittest.TestCase):
    def parts(self, rows=None):
        return kb.score_log(kb.parse_rows("2026-11-01_150000_Sadey.log", rows or ALIAS_FIGHT))

    def test_one_log_splits_at_the_first_sent_setalias(self):
        parts = self.parts()
        self.assertEqual([p["mode"] for p in parts], ["raw", "alias"])
        self.assertEqual(parts[0]["refusals"], 1)
        self.assertEqual(parts[0]["was_added"], 1)
        self.assertEqual(parts[1]["refusals"], 0)
        self.assertEqual(parts[1]["was_added"], 0)
        self.assertEqual(parts[1]["first_row"], 15)

    def test_a_test_alias_does_not_split(self):
        rows = [HEADER, "15:00:00.000 > setalias lvprobe say one", "15:00:00.100 P H: Full cxkdb-"]
        self.assertEqual([p["mode"] for p in self.parts(rows)], ["raw"])

    def test_a_header_that_says_alias_is_all_alias(self):
        rows = [HEADER.replace("rounds raw", "rounds alias"), "15:00:00.100 P H: Full cxkdb-"]
        self.assertEqual([p["mode"] for p in self.parts(rows)], ["alias"])

    def test_refusals_per_recovery_counts_three_limb_lines_as_one(self):
        alias = self.parts()[1]
        self.assertEqual(alias["recoveries"], 1)

    def test_setup_before_spender(self):
        raw, alias = self.parts()
        self.assertEqual((raw["setup_ok"], raw["setup_flushes"]), (0, 1))
        self.assertEqual((alias["setup_ok"], alias["setup_flushes"]), (1, 1))

    def test_the_raw_queue_entry_ahead_of_the_attack_passes(self):
        rows = [HEADER, "15:00:00.000 > queue addclear free g body", "15:00:00.000 > combo Sadey a",
                "15:00:00.060 | [System]: Added G BODY to your free queue.",
                "15:00:02.000 | [System]: Running queued free command: G BODY",
                "15:00:02.002 | [System]: Running queued free command: COMBO SADEY A",
                "15:00:02.004 P H: Full cxkdb-"]
        p = self.parts(rows)[0]
        self.assertEqual((p["setup_ok"], p["setup_flushes"]), (1, 1))

    def test_a_setup_piece_after_the_spender_fails_on_the_alias_path(self):
        rows = [HEADER, "15:00:00.000 > setalias lvfree combo Sadey a/wield staff", "15:00:00.000 > queue addclear free lvfree",
                "15:00:00.060 | Alias \"lvfree\" will now execute: \"combo Sadey a/wield staff\"",
                "15:00:02.000 | [System]: Running queued free command: LVFREE", "15:00:02.004 P H: Full cxkdb-"]
        p = self.parts(rows)[1]
        self.assertEqual((p["setup_ok"], p["setup_flushes"]), (0, 1))

    def test_an_auto_queued_setup_piece_fails_on_the_alias_path(self):
        rows = [HEADER, "15:00:00.000 > setalias lvfree g body/combo Sadey a", "15:00:00.000 > queue addclear free lvfree",
                "15:00:00.060 | Alias \"lvfree\" will now execute: \"g body/combo Sadey a\"",
                "15:00:02.000 | [System]: Running queued free command: LVFREE",
                "15:00:02.001 | g body was added to your equilibrium queue.", "15:00:02.004 P H: Full cxkdb-"]
        p = self.parts(rows)[1]
        self.assertEqual((p["setup_ok"], p["setup_flushes"]), (0, 1))

    def test_a_rider_after_the_spender_is_not_setup(self):
        # srd's shape: `combo; kai choke`. Its second spender does not fail the round.
        rows = [HEADER, "15:00:00.000 > setalias lvfree stand/combo Sadey a/kai choke Sadey/assess Sadey",
                "15:00:00.000 > queue addclear free lvfree",
                "15:00:00.060 | Alias \"lvfree\" will now execute: \"stand/combo Sadey a/kai choke Sadey/assess Sadey\"",
                "15:00:02.000 | [System]: Running queued free command: LVFREE", "15:00:02.004 P H: Full cxkdb-"]
        p = self.parts(rows)[1]
        self.assertEqual((p["setup_ok"], p["setup_flushes"]), (1, 1))

    def test_a_superseded_raw_attack(self):
        rows = [HEADER, "15:00:00.000 > mind impatience Sadey", "15:00:00.200 > combo Sadey a",
                "15:00:02.000 | [System]: Running queued free command: MIND IMPATIENCE SADEY", "15:00:02.004 P H: Full cxkdb-"]
        p = self.parts(rows)[0]
        self.assertEqual((p["superseded"], p["fired"]), (1, 1))

    def test_a_queue_add_supersedes_nothing(self):
        # ours/2026-10-28_073547 rows 3-4.
        rows = [HEADER, "15:00:00.000 > queue addclear free sketch jera on Sadey", "15:00:00.000 > queue add free sketch algiz on Sadey",
                "15:00:02.000 | [System]: Running queued free command: SKETCH JERA ON SADEY", "15:00:02.004 P H: Full cxkdb-"]
        p = self.parts(rows)[0]
        self.assertEqual((p["superseded"], p["fired"]), (0, 1))

    def alias_part(self, rows):
        """Score rows in the recorder's own format, as one alias part."""
        head = HEADER.replace("rounds raw", "rounds alias")
        return kb.score_log(kb.parse_rows("2026-11-02_131934_Titonus.log", [head] + rows))[-1]

    def test_a_round_that_runs_as_it_is_added_never_waited_so_nothing_replaced_it(self):
        # `sr;zz` with balance up: sr's round runs at once, and zz's rewrite arrives after it.
        p = self.alias_part([
            "13:19:39.153 > setalias lvfree combo Titonus frontkick right ruku right kuro right",
            "13:19:39.153 > queue addclear free lvfree",
            "13:19:39.153 > setalias lvfree combo Titonus frontkick right kuro right kuro left",
            "13:19:39.153 > queue addclear free lvfree",
            '13:19:39.211 | Alias "lvfree" will now execute: "combo Titonus frontkick right ruku right kuro right"',
            "13:19:39.301 | [System]: Queued free commands cleared.",
            "13:19:39.301 | [System]: Added LVFREE to your free queue.",
            "13:19:39.302 | [System]: Running queued free command: LVFREE",
            "13:19:39.310 P H: Full, M: High, E: Full, W: Full ekdb-",
        ])
        self.assertEqual((p["superseded"], p["fired"]), (0, 1))

    def test_a_recordings_first_round_has_nothing_to_compare_with(self):
        # The setalias went out before the recording began, so only its echo shows.
        p = self.alias_part([
            "13:19:34.606 > queue addclear free lvfree",
            '13:19:34.655 | Alias "lvfree" will now execute: "mind impatience Titonus"',
            "13:19:34.744 | [System]: Added LVFREE to your free queue.",
            "13:19:35.001 P H: Full, M: High, E: Full, W: Full ekdb-",
            "13:19:36.000 | You have recovered equilibrium.",
            "13:19:36.001 | [System]: Running queued free command: LVFREE",
            "13:19:36.010 P H: Full, M: High, E: Full, W: Full kdb-",
        ])
        self.assertEqual((p["superseded"], p["fired"]), (0, 1))

    def test_a_round_that_waited_and_then_fired_old_text_still_counts(self):
        p = self.alias_part([
            "13:19:40.000 > setalias lvfree combo Titonus frontkick right ruku right kuro right",
            "13:19:40.000 > queue addclear free lvfree",
            '13:19:40.050 | Alias "lvfree" will now execute: "combo Titonus frontkick right ruku right kuro right"',
            "13:19:40.060 | [System]: Added LVFREE to your free queue.",
            "13:19:40.070 P H: Full, M: High, E: Full, W: Full kdb-",
            "13:19:41.000 > setalias lvfree mind impatience Titonus",
            "13:19:41.000 > queue addclear free lvfree",
            "13:19:41.010 | You have recovered balance on all limbs.",
            "13:19:41.011 | [System]: Running queued free command: LVFREE",
            "13:19:41.020 P H: Full, M: High, E: Full, W: Full kdb-",
        ])
        self.assertEqual((p["superseded"], p["fired"]), (1, 1))

    def test_a_rewrite_that_lost_the_race_is_superseded_on_the_alias_path(self):
        # The shape of 3ys7NuHA rows 2666-2677: the rewrite was sent, no echo came, and the old text fired.
        rows = [HEADER, "15:00:00.000 > setalias lvfree stand/combo Sadey right", "15:00:00.000 > queue addclear free lvfree",
                "15:00:00.060 | Alias \"lvfree\" will now execute: \"stand/combo Sadey right\"",
                "15:00:00.062 | [System]: Added LVFREE to your free queue.",
                "15:00:02.000 > setalias lvfree stand/combo Sadey left",
                "15:00:02.001 | [System]: Running queued free command: LVFREE",
                "15:00:02.002 | You lash out with a straight kick at the right shoulder of Sadey.",
                "15:00:02.004 P H: Full cxkdb-"]
        p = self.parts(rows)[1]
        self.assertEqual((p["superseded"], p["fired"]), (1, 1))

    def test_an_echoed_rewrite_whose_new_text_fired(self):
        alias = self.parts()[1]
        self.assertEqual(alias["rewrites_sent"], 2)
        self.assertEqual(alias["rewrites_echoed"], 2)
        self.assertEqual(alias["rewrites_new"], 1)
        self.assertEqual(alias["rewrites_old"], 0)
        self.assertEqual(alias["superseded"], 0)

    def test_which_text_fired_can_answer_old_or_not_shown(self):
        new, old = "stand/combo Sadey left", "stand/combo Sadey right"
        self.assertEqual(kb.which_text_fired(new, old, ["You lash out at the right shoulder of Sadey."]), "old")
        self.assertEqual(kb.which_text_fired(new, old, ["You lash out at Sadey."]), "unknown")
        self.assertEqual(kb.which_text_fired(new, old, ["Akri kicks the left shoulder of Sadey."]), "unknown")

    def test_a_complaint_is_any_other_line_naming_an_alias(self):
        rows = list(ALIAS_FIGHT) + ["15:00:06.000 | You may not have more than 50 aliases.",
                                    "15:00:06.001 | I'm sorry, I don't know what \"lvfree\" does.",
                                    "15:00:06.002 | You have cleared alias \"lvprobe\".",
                                    "15:00:06.004 P H: Full cexkdb-"]
        alias = self.parts(rows)[1]
        self.assertEqual(alias["complaints"], 2)
        self.assertEqual(alias["bars"]["complaints"], False)

    def test_wrong_target(self):
        rows = [HEADER, "15:00:00.000 > st Crixos", "15:00:00.000 > combo Akri a",
                "15:00:02.000 | [System]: Running queued free command: COMBO AKRI A", "15:00:02.004 P H: Full cxkdb-"]
        p = self.parts(rows)[0]
        self.assertEqual(p["wrong_target"], 1)
        self.assertEqual(p["wrong_target_rows"], [3])

    def test_mind_crush_names_its_target_in_the_third_word(self):
        self.assertEqual(kb.fired_target("mind crush Akri"), "akri")
        self.assertEqual(kb.fired_target("combo Akri frontkick left"), "akri")
        self.assertIsNone(kb.fired_target("mind crush"))

    def test_mind_lock_is_setup_and_not_a_spender(self):
        self.assertEqual(kb.first_spender(["stand", "mind lock Astarod", "combo Astarod a"]), "combo Astarod a")

    def test_rounds_per_minute_counts_recoveries_while_attacks_were_sent(self):
        rows = [HEADER, "15:00:00.000 > combo Sadey a", "15:00:02.000 | You have recovered balance on all limbs.",
                "15:00:02.004 P H: Full cxkdb-", "15:01:00.000 | You have recovered equilibrium.", "15:01:00.004 P H: Full cxkdb-"]
        p = self.parts(rows)[0]
        self.assertEqual(p["active_s"], 6.0)
        self.assertEqual(p["active_recoveries"], 1)
        self.assertEqual(p["recoveries"], 2)

    def test_a_raw_part_is_baseline_and_an_alias_part_is_judged(self):
        self.assertEqual(kb.mark(False, "raw"), "")
        self.assertEqual(kb.mark(False, "alias"), " FAIL")
        self.assertEqual(kb.mark(True, "alias"), " PASS")
        self.assertEqual(kb.mark(None, "alias"), "")

    def test_the_bars_are_the_plans(self):
        parts = self.parts()
        bars = parts[1]["bars"]
        self.assertEqual(bars["refusals"], True)
        self.assertEqual(bars["was_added"], True)
        self.assertEqual(bars["setup"], True)
        self.assertEqual(bars["superseded"], True)
        # One rewrite is not enough: the bar is five.
        self.assertEqual(bars["rewrites"], False)
        self.assertEqual(bars["complaints"], True)

    def test_the_output_notes_the_unproven_run_line(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "2026-11-01_150000_Sadey.log")
            with open(path, "w", encoding="utf-8", newline="\n") as fh:
                fh.write("\n".join(ALIAS_FIGHT) + "\n")
            text = kb.score_text(path)
        self.assertIn("LVFREE", text)
        self.assertIn("have not proved", text)
        self.assertIn("<= 0.1 per recovery", text)
        self.assertIn("alias rounds", text)
        self.assertIn("raw rounds", text)

    def test_an_alias_part_with_no_run_line_says_so(self):
        rows = [HEADER, "15:00:00.000 > setalias lvfree stand/combo Sadey a", "15:00:00.100 P H: Full cxkdb-"]
        notes = kb.part_notes(self.parts(rows)[1])
        self.assertTrue(any("No run line names a round alias" in n for n in notes))

    def test_fightlog_import_score_prints_it(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "2026-11-01_150000_Sadey.log")
            with open(path, "w", encoding="utf-8", newline="\n") as fh:
                fh.write("\n".join(ALIAS_FIGHT) + "\n")
            out = subprocess.run([sys.executable, "-B", os.path.join(HERE, "fightlog_import.py"), "--dry-run", "--score", path],
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding="utf-8", check=True).stdout
        self.assertIn("Refusals per recovery", out)
        self.assertIn("have not proved", out)


def alias_round(stamp, side):
    """One alias round: the rewrite, the press, the echo, the run line, the prompt. Row shapes as in ALIAS_FIGHT."""
    text = "stand/g body/combo Sadey frontkick %s kuro %s ruku %s" % (side, side, side)
    return ["15:00:%s.000 > setalias lvfree %s" % (stamp, text), "15:00:%s.000 > queue addclear free lvfree" % stamp,
            "15:00:%s.060 | Alias \"lvfree\" will now execute: \"%s\"" % (stamp, text),
            "15:00:%s.062 | [System]: Added LVFREE to your free queue." % stamp,
            "15:00:%s.500 | [System]: Running queued free command: LVFREE" % stamp,
            "15:00:%s.502 | You lash out with a straight kick at the %s shoulder of Sadey." % (stamp, side),
            "15:00:%s.504 P H: Full cexkdb-" % stamp]


class ScoreboardFindings(unittest.TestCase):
    def parts(self, rows):
        return kb.score_log(kb.parse_rows("2026-11-01_150000_Sadey.log", rows))

    def test_a_raw_attack_held_across_the_toggle_does_not_decide_the_setup_bar(self):
        # ours/2026-10-27_112717 has 46 such run rows in 230 s. `aconfig rounds alias` sends no clear.
        rows = [HEADER] + alias_round("01", "left") + ["15:00:02.000 | [System]: Running queued equilibrium command: MIND IMPATIENCE SADEY",
                                                       "15:00:02.004 P H: Full cexkdb-"] + alias_round("03", "right")
        alias = self.parts(rows)[1]
        self.assertEqual((alias["setup_ok"], alias["setup_flushes"]), (2, 2))
        self.assertTrue(alias["bars"]["setup"])
        self.assertEqual(len(alias["raw_attack_rows"]), 1)
        self.assertTrue(any("Raw attack rows" in n and str(alias["raw_attack_rows"][0]) in n for n in kb.part_notes(alias)))

    def test_a_one_piece_finisher_is_listed_and_not_judged(self):
        # 003_Queueing_Related.lua returns nil for fewer than 2 pieces, so this goes raw.
        rows = [HEADER] + alias_round("01", "left") + ["15:00:02.000 > queue addclear free kai choke Sadey",
                                                       "15:00:02.500 | [System]: Running queued free command: KAI CHOKE SADEY",
                                                       "15:00:02.504 P H: Full cexkdb-"]
        alias = self.parts(rows)[1]
        self.assertEqual((alias["setup_ok"], alias["setup_flushes"]), (1, 1))
        self.assertEqual(alias["raw_presses"], 1)
        self.assertTrue(any("did not name an alias" in n for n in kb.part_notes(alias)))

    def test_a_raw_part_still_judges_its_raw_rows(self):
        rows = [HEADER, "15:00:00.000 > combo Sadey a", "15:00:02.000 | [System]: Running queued free command: COMBO SADEY A", "15:00:02.004 P H: Full cxkdb-"]
        raw = self.parts(rows)[0]
        self.assertEqual((raw["setup_ok"], raw["setup_flushes"]), (0, 1))
        self.assertEqual(raw["raw_attack_rows"], [])
        self.assertEqual(raw["setup_rows"], [2])

    def test_a_setup_fail_prints_its_rows(self):
        rows = [HEADER, "15:00:00.000 > setalias lvfree combo Sadey a/wield staff", "15:00:00.000 > queue addclear free lvfree",
                "15:00:02.000 | [System]: Running queued free command: LVFREE", "15:00:02.004 P H: Full cxkdb-"]
        alias = self.parts(rows)[1]
        self.assertEqual(alias["setup_rows"], [3])
        self.assertIn("Setup rows: 3.", kb.part_notes(alias))

    def test_the_scoreboard_page_states_its_row_base(self):
        self.assertIn("Rows on this page are 0-based", kb.render_scoreboard([]))

    def test_the_target_set_in_the_raw_half_reaches_the_alias_half(self):
        rows = [HEADER, "15:00:00.000 > st Akri", "15:00:00.100 P H: Full cxkdb-"] + alias_round("01", "left")
        alias = self.parts(rows)[1]
        self.assertEqual((alias["wrong_target"], alias["target_checked"]), (1, 1))
        self.assertFalse(alias["bars"]["wrong_target"])

    def test_a_target_switch_with_the_old_target_firing_fails(self):
        rows = [HEADER, "15:00:00.000 > st Sadey", "15:00:00.100 P H: Full cxkdb-"] + alias_round("01", "left") + ["15:00:02.000 > st Crixos"] + alias_round("03", "left")
        alias = self.parts(rows)[1]
        self.assertEqual((alias["wrong_target"], alias["target_checked"]), (1, 2))

    def test_no_known_target_measures_nothing_and_prints_no_verdict(self):
        alias = self.parts([HEADER] + alias_round("01", "left"))[1]
        self.assertEqual(alias["fired"], 1)
        self.assertEqual(alias["target_checked"], 0)
        self.assertIsNone(alias["bars"]["wrong_target"])
        self.assertEqual(kb.mark(alias["bars"]["wrong_target"], "alias"), "")
        self.assertIn("not measured", dict((m, v) for m, v, _ in kb.part_measures(alias))["Attacks naming a target other than the last set"])

    def test_a_part_with_no_run_line_does_not_pass_the_target_bar(self):
        rows = [HEADER, "15:00:00.000 > st Sadey", "15:00:00.000 > setalias lvfree stand/combo Sadey a", "15:00:00.100 P H: Full cxkdb-"]
        self.assertIsNone(self.parts(rows)[0]["bars"]["wrong_target"])
        self.assertIsNone(self.parts(rows)[1]["bars"]["wrong_target"])

    def test_a_rewrite_of_only_the_rider_that_lost_the_race_is_superseded(self):
        # srd's shape. The combo is the same, so a check of the first spender alone cannot see this.
        rows = [HEADER, "15:00:00.000 > setalias lvfree stand/combo Sadey a/kai choke Sadey", "15:00:00.000 > queue addclear free lvfree",
                "15:00:00.060 | Alias \"lvfree\" will now execute: \"stand/combo Sadey a/kai choke Sadey\"",
                "15:00:00.062 | [System]: Added LVFREE to your free queue.",
                "15:00:02.000 > setalias lvfree stand/combo Sadey a/mind crush Sadey",
                "15:00:02.001 | [System]: Running queued free command: LVFREE", "15:00:02.004 P H: Full cxkdb-"]
        alias = self.parts(rows)[1]
        self.assertEqual((alias["superseded"], alias["fired"]), (1, 1))

    def test_which_text_fired_sees_a_rider(self):
        new, old = "stand/combo Sadey a/mind crush Sadey", "stand/combo Sadey a/kai choke Sadey"
        self.assertEqual(kb.which_text_fired(new, old, ["You crush the mind of Sadey."]), "new")
        self.assertEqual(kb.which_text_fired(new, old, ["You choke Sadey with your kai."]), "old")

    def test_a_rider_on_the_old_target_is_a_wrong_target(self):
        rows = [HEADER, "15:00:00.000 > st Sadey", "15:00:00.000 > setalias lvfree stand/combo Sadey a/kai choke Akri",
                "15:00:00.000 > queue addclear free lvfree", "15:00:02.001 | [System]: Running queued free command: LVFREE", "15:00:02.004 P H: Full cxkdb-"]
        self.assertEqual(self.parts(rows)[1]["wrong_target"], 1)

    def test_a_queue_line_naming_the_alias_splits_when_no_setalias_came(self):
        # The shim skips setalias when the text has not changed, and `aconfig rounds raw` keeps it (003_Queueing_Related.lua).
        rows = [HEADER, "# alias lvfree holds: stand/g body/combo Sadey a", "15:00:00.000 > combo Sadey b", "15:00:00.004 P H: Full cxkdb-",
                "15:00:01.000 > queue addclear free lvfree", "15:00:01.060 | [System]: Added LVFREE to your free queue.",
                "15:00:02.000 | [System]: Running queued free command: LVFREE",
                "15:00:02.002 | You lash out at Sadey.", "15:00:02.004 P H: Full cexkdb-"]
        parts = self.parts(rows)
        self.assertEqual([p["mode"] for p in parts], ["raw", "alias"])
        self.assertEqual(parts[1]["first_row"], 4)
        # The note row is in the raw part. Its text still gives the alias round its setup and its spender.
        self.assertEqual((parts[1]["setup_ok"], parts[1]["setup_flushes"]), (1, 1))
        self.assertEqual(parts[1]["fired"], 1)

    def test_a_test_alias_on_a_queue_line_does_not_split(self):
        rows = [HEADER, "15:00:00.000 > queue addclear free lvprobe", "15:00:00.100 P H: Full cxkdb-"]
        self.assertEqual([p["mode"] for p in self.parts(rows)], ["raw"])

    def test_an_alias_header_with_a_note_row_and_one_run_line(self):
        rows = [HEADER.replace("rounds raw", "rounds alias"), "# alias lvfree holds: stand/g body/combo Sadey a",
                "15:00:01.000 > queue addclear free lvfree", "15:00:02.000 | [System]: Running queued free command: LVFREE", "15:00:02.004 P H: Full cexkdb-"]
        p = self.parts(rows)[0]
        self.assertEqual(p["mode"], "alias")
        self.assertEqual((p["alias_run_rows"], p["fired"], p["setup_ok"], p["setup_flushes"]), (1, 1, 1, 1))
        self.assertTrue(any("LVFREE" in n for n in kb.part_notes(p)))

    def test_a_sent_rewrite_with_no_echo_falls_back_to_the_sent_text(self):
        rows = [HEADER, "15:00:00.000 > setalias lvfree stand/combo Sadey a", "15:00:00.000 > queue addclear free lvfree",
                "15:00:02.000 | [System]: Running queued free command: LVFREE", "15:00:02.004 P H: Full cexkdb-"]
        alias = self.parts(rows)[1]
        self.assertEqual((alias["rewrites_sent"], alias["rewrites_echoed"]), (1, 0))
        self.assertEqual((alias["fired"], alias["superseded"], alias["setup_ok"]), (1, 0, 1))

    def test_a_log_that_ends_after_a_run_line_still_scores_that_flush(self):
        rows = [HEADER, "15:00:00.000 > setalias lvfree stand/combo Sadey left", "15:00:00.000 > queue addclear free lvfree",
                "15:00:00.060 | Alias \"lvfree\" will now execute: \"stand/combo Sadey left\"",
                "15:00:00.062 | [System]: Added LVFREE to your free queue.",
                "15:00:01.000 > setalias lvfree stand/combo Sadey right",
                "15:00:01.060 | Alias \"lvfree\" will now execute: \"stand/combo Sadey right\"",
                "15:00:02.000 | [System]: Running queued free command: LVFREE",
                "15:00:02.002 | You lash out with a kick at the right shoulder of Sadey."]
        alias = self.parts(rows)[1]
        self.assertEqual((alias["setup_ok"], alias["setup_flushes"]), (1, 1))
        self.assertEqual(alias["rewrites_new"], 1)
        self.assertEqual(alias["rewrite_rows"], [7])

    def test_raw_queue_lines_in_an_alias_part_are_counted_and_noted(self):
        rows = [HEADER] + alias_round("01", "left") + ["15:00:02.000 > queue addclear free stand"]
        alias = self.parts(rows)[1]
        self.assertEqual(alias["raw_presses"], 1)
        self.assertTrue(any(n.startswith("1 queue lines") for n in kb.part_notes(alias)))


class FrozenBars(unittest.TestCase):
    """The step 3 bars. Raw parts print no verdict and no alias log exists yet, so no page protects these."""

    def s(self, **kw):
        base = {"refusals": 0, "recoveries": 10, "was_added": 0, "setup_ok": 1, "setup_flushes": 1, "superseded": 0, "fired": 100,
                "rewrites_new": 5, "complaints": 0, "wrong_target": 0, "target_checked": 1}
        base.update(kw)
        return kb.bar_verdicts(base)

    def test_each_bar_at_its_boundary(self):
        cases = (
            ("refusals", {"refusals": 1, "recoveries": 10}, True), ("refusals", {"refusals": 11, "recoveries": 100}, False),
            ("refusals", {"recoveries": 0}, None),
            ("was_added", {"was_added": 2}, True), ("was_added", {"was_added": 3}, False),
            ("setup", {"setup_ok": 2, "setup_flushes": 2}, True), ("setup", {"setup_ok": 1, "setup_flushes": 2}, False),
            ("setup", {"setup_ok": 0, "setup_flushes": 0}, None),
            ("superseded", {"superseded": 50, "fired": 1000}, True), ("superseded", {"superseded": 51, "fired": 1000}, False),
            ("superseded", {"fired": 0}, None),
            ("rewrites", {"rewrites_new": 5}, True), ("rewrites", {"rewrites_new": 4}, False),
            ("complaints", {"complaints": 0}, True), ("complaints", {"complaints": 1}, False),
            ("wrong_target", {"wrong_target": 0}, True), ("wrong_target", {"wrong_target": 1}, False),
            ("wrong_target", {"target_checked": 0}, None),
        )
        for bar, kw, want in cases:
            self.assertIs(self.s(**kw)[bar], want, "%s %r" % (bar, kw))

    def test_the_bars_are_word_for_word(self):
        self.assertEqual(kb.BARS, {
            "refusals": "<= 0.1 per recovery", "was_added": "<= 2", "setup": "every round", "superseded": "<= 5%",
            "rewrites": ">= 5 fire new text", "complaints": "none", "wrong_target": "none"})


class RealLogs(unittest.TestCase):
    """The acceptance numbers. A clock can move with new logs, so these hold a margin, and the page holds the digits."""
    @classmethod
    def setUpClass(cls):
        cls.logs = kb.load_all()
        cls.data = kb.build_data(cls.logs)

    def test_every_log_parses_except_the_one_with_no_stamps(self):
        skipped = [log.name for log in self.logs if log.family is None]
        self.assertEqual(skipped, ["2026-10-19_tabethys_magi-group_kalys_o6UKnyyy.txt"])

    def test_the_stamps_never_go_back(self):
        for log in self.logs:
            times = [r.time for r in log if r.kind == "prompt"]
            self.assertEqual(times, sorted(times), log.name)

    def test_the_882_prompts_with_an_open_bracket_keep_their_boards(self):
        # At least 882: a new log can add more, and the rule that matters is that every one keeps its board.
        opened = closed = 0
        for log in self.logs:
            if log.family not in ("claes", "elmer", "earth"):
                continue
            raw = kb.read_rows(os.path.join(kb.LOGS, log.name))
            for r in log:
                if r.kind == "prompt" and raw[r.n].count("[") > raw[r.n].count("]"):
                    opened += 1
                    closed += 1 if r.board else 0
        self.assertGreaterEqual(opened, 882)
        self.assertEqual(closed, opened)

    def test_every_family_keeps_the_last_board_token_of_a_wrapped_prompt(self):
        # The word a later row closes the board with must be on the board. A later row with no such word is a damage group
        # or a lock word: ")" (defender row 73), "6% )" (3ys7NuHA row 894), " true) ]]" (Sentinel row 2591).
        closer = re.compile(r"([^\s\[\](),|]+)[\])]")
        checked = {}
        for log in self.logs:
            if log.family in (None, "ours", "blademaster"):
                continue
            raw = kb.read_rows(os.path.join(kb.LOGS, log.name))
            for r in log:
                extra = (r.span - 2 if log.family == "mystor" else r.span - 1) if r.kind == "prompt" else 0
                if extra <= 0:
                    continue
                words = [w for w in closer.findall(raw[r.n + extra]) if not w.replace(".", "").isdigit()]
                if words:
                    checked[log.family] = checked.get(log.family, 0) + 1
                    # Sentinel's board can end in its lock word, which the parser keeps out of the board on purpose.
                    self.assertTrue(any(words[-1] in tok for tok in (r.board or []) + [r.lock or ""]), "%s row %d: %r in %r" % (log.name, r.n, words[-1], r.board))
        for family in ("claes", "earth", "elmer", "mystor", "nikita"):
            self.assertGreater(checked.get(family, 0), 0, family)

    def test_no_board_row_is_left_behind_as_a_line(self):
        # These row shapes follow a prompt only when it wrapped. A plain line that keeps one has lost a board.
        for log in self.logs:
            if log.family == "elmer":
                self.assertEqual([r.n for r in log if r.kind == "line" and kb.LIMB_ROW_START.match(r.text)], [], log.name)
            if log.family == "nikita":
                self.assertEqual([r.n for r in log if r.kind == "line" and re.match(r"^ \((?:\w+\|)+\w+\)", r.text)], [], log.name)

    def test_the_rows_the_reviews_named(self):
        def board(frag, row):
            log = [x for x in self.logs if frag in x.name][0]
            return [r for r in log if r.kind == "prompt" and r.n == row][0]
        self.assertEqual(board("3ys7NuHA", 4160).board, ["pressure(3)", "mleech"])
        self.assertEqual(board("kAQnlFAW", 1249).board[:3], ["w", "cresc2", "STU"])
        self.assertIn("ANO", board("X8pRorzR", 363).board)

    def test_short_ids_match_the_log_readme(self):
        ids = {log.id for log in self.logs}
        self.assertTrue({"4c_SeyaA", "J7Xnr_Jg", "uW_VbgR", "g-lD00-h", "c.iJVmpL"} <= ids, sorted(ids))
        self.assertFalse({"SeyaA", "Jg", "VbgR"} & ids)

    def test_the_1_s_rows_on_the_real_page_are_not_usable(self):
        rows = [r for c in self.data["clocks"].values() for r in c["by_logger"] if r["method"] == "line_1s"]
        self.assertTrue(rows)
        self.assertEqual([r["logger"] for r in rows if r["usable"]], [])

    def test_the_stated_notes_name_the_loggers_own_skill(self):
        notes = {a["ability"]: a["stated_note"] for a in self.data["stated"]["own"]}
        self.assertTrue(notes["FITNESS"].startswith("Kaido/Fitness: "))
        self.assertTrue(notes["Engage"].startswith("Discipline/Engage: "))

    def test_the_page_says_filed_and_not_date(self):
        text = kb.generate()[kb.OUT_MD]
        self.assertIn("latest_filed:", text)
        self.assertIn("| Filed |", text)
        self.assertNotIn("| Dates |", text)
        self.assertNotIn("| Date |", text)
        self.assertNotIn("latest_log", text)
        self.assertIn("Only our recorder's header gives a fight's date", text)

    def test_the_page_does_not_call_p10_a_floor(self):
        text = kb.generate()[kb.OUT_MD]
        self.assertNotIn("FLOOR", text)
        self.assertNotIn("floor p10", text)
        self.assertNotIn("stragglers", text)
        self.assertIn("p10 is not a floor", text)

    def test_the_page_reads_the_pool_width_from_the_samples(self):
        text = kb.generate()[kb.OUT_MD]
        self.assertIn("without Nikita %.3f" % self.data["clocks"]["eat"]["spread_without"]["Nikita"], text)
        self.assertNotIn("by mixing loggers", text)

    def test_the_page_says_how_much_of_the_printed_costs_it_covers(self):
        text = kb.generate()[kb.OUT_MD]
        m = re.search(r"(\d+) of (\d+) printed cost rows match a curated ability\.", text)
        self.assertTrue(m)
        self.assertLess(int(m.group(1)), int(m.group(2)))
        self.assertEqual(int(m.group(2)), self.data["stated"]["own_printed_rows"])

    def test_eat_tree_and_dstab(self):
        self.assertAlmostEqual(self.data["clocks"]["eat"]["stats"]["median"], 1.50, delta=0.05)
        self.assertAlmostEqual(self.data["clocks"]["tree"]["stats"]["median"], 13.95, delta=0.05)
        dstab = [a for a in self.data["stated"]["opponents"] if a["ability"] == "DSTAB"][0]
        self.assertAlmostEqual(dstab["stats"]["median"], 1.83, delta=0.05)

    def test_our_monk_baseline(self):
        monk = [log for log in self.logs if log.name == "2026-10-27_112717_Tabethys.log"][0]
        p = kb.score_log(monk)[0]
        self.assertEqual(p["was_added"], 294)
        self.assertEqual((p["refusals"], p["recoveries"]), (1466, 66))

    def test_the_monk_baseline_has_a_target_and_lists_its_setup_rows(self):
        monk = [log for log in self.logs if log.name == "2026-10-27_112717_Tabethys.log"][0]
        p = kb.score_log(monk)[0]
        self.assertGreater(p["target_checked"], 0)
        self.assertTrue(any(n.startswith("Setup rows: ") for n in kb.part_notes(p)))

    def test_two_runs_are_byte_identical(self):
        self.assertEqual(kb.generate(), kb.generate())

    def test_the_json_is_valid_and_sorted(self):
        text = kb.generate()[kb.OUT_JSON]
        self.assertEqual(json.dumps(json.loads(text), indent=1, sort_keys=True, ensure_ascii=False) + "\n", text)

    def test_check_finds_a_difference_and_passes_a_match(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "page.md")
            with open(path, "w", encoding="utf-8", newline="\n") as fh:
                fh.write("one\n")
            kb.ROOT, root = tmp, kb.ROOT
            try:
                self.assertEqual(kb.check({path: "one\n"}), 0)
                self.assertEqual(kb.check({path: "two\n"}), 1)
            finally:
                kb.ROOT = root


class Docs(unittest.TestCase):
    """fightlog_import and the KB rules must name every generator, or following them leaves CI red."""

    def test_a_copied_log_names_both_generators(self):
        spec2 = importlib.util.spec_from_file_location("fightlog_import", os.path.join(HERE, "fightlog_import.py"))
        tool = importlib.util.module_from_spec(spec2)
        spec2.loader.exec_module(tool)
        with tempfile.TemporaryDirectory() as tmp:
            src = os.path.join(tmp, "2026-11-01_150000_Sadey.log")
            with open(src, "w", encoding="utf-8", newline="\n") as fh:
                fh.write(HEADER + "\n")
            tool.DEST, tool.ROOT = os.path.join(tmp, "dest"), tmp
            out, argv = io.StringIO(), sys.argv
            sys.argv = ["fightlog_import.py", src]
            try:
                with contextlib.redirect_stdout(out):
                    tool.main()
            finally:
                sys.argv = argv
        self.assertIn("tools/kb_timing.py", out.getvalue())
        self.assertIn("tools/kb_replay.py", out.getvalue())

    def test_foundations_holds_the_reviewed_figures(self):
        with open(os.path.join(kb.ROOT, "kb", "mechanics", "foundations.md"), encoding="utf-8") as fh:
            text = fh.read()
        for stale in ("31-48%", "1,196", "8 pairs", "It adds the floor"):
            self.assertNotIn(stale, text)
        self.assertIn("10 pairs", text)
        self.assertIn("cannot exclude it", text)
        self.assertIn("| Engage (Claes) |", text)
        # Lines wrap, and a checkout can hold CRLF, so read the prose with its white space folded.
        prose = " ".join(text.split())
        self.assertIn("p10 is not a floor", prose)
        self.assertIn("The user decided on 2026-11-01 that these bars stand", prose)

    def test_engage_is_filed_as_a_conflict(self):
        with open(os.path.join(kb.ROOT, "kb", "CONFLICTS.md"), encoding="utf-8") as fh:
            self.assertRegex(fh.read(), r"\| \d+ \| Engage's cost \|")

    def test_the_readme_names_both_steps_and_the_confidence_tags(self):
        with open(os.path.join(kb.ROOT, "kb", "README.md"), encoding="utf-8") as fh:
            readme = fh.read()
        self.assertIn("Run steps 4 and 5 after this too", readme)
        with open(os.path.join(kb.ROOT, "kb", "_template.md"), encoding="utf-8") as fh:
            template = fh.read()
        for tag in ("MEASURED", "READ", "INFERRED"):
            self.assertIn(tag, readme)
            self.assertIn(tag, template)


if __name__ == "__main__":
    unittest.main()
