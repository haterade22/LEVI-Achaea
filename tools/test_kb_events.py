"""Tests for tools/kb_events.py: the census of the four Serpent logs, the race table and its golden row.

The census counts are the grep counts frozen in tools/sim/gates_whole.json ("seen_before_freeze") and in the plan's stage 1a.

    python -B tools/test_kb_events.py
"""
import json
import os
import sys
import unittest

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kb_events as E  # noqa: E402

DATA = None


def data():
    global DATA
    if DATA is None:
        DATA = E.build()
    return DATA


def counts(name, field="lines"):
    return [data()["census"][k][field].get(name, 0) for k in E.KEYS]


class Census(unittest.TestCase):
    def test_frozen_grep_counts(self):
        # gates_whole.json, seen_before_freeze: pricks 45/49/24/86, fangs 7/8/0/7, tree 12/7/2/22, eats 97/85/49/178.
        self.assertEqual(counts("dstab"), [45, 49, 24, 86])
        self.assertEqual(counts("bite"), [7, 8, 0, 7])
        self.assertEqual(counts("tree"), [12, 7, 2, 22])
        self.assertEqual(counts("eat"), [97, 85, 49, 178])

    def test_stage_1a_counts(self):
        # The plan's stage 1a: FITNESS 0, Dagaz 11 (az), Salt 7 (Z5), Accelerate 1 (X), SNAP in front of you 7/5/2/4 plus
        # one bare SNAP in g, unease 7/4/2/4, flays that strip 25/5/7/19, pet lines az 11, Z5 21, g 9, X 29. Z5's pet is a
        # saw-scaled viper, not a snake (rows 101, 378; the throat form at 2744).
        self.assertEqual(counts("fitness"), [0, 0, 0, 0])
        self.assertEqual(counts("dagaz"), [11, 0, 0, 0])
        self.assertEqual(counts("salt"), [0, 7, 0, 0])
        self.assertEqual(counts("accelerate"), [0, 0, 0, 1])
        self.assertEqual(counts("snap"), [7, 5, 2, 4])
        self.assertEqual(counts("snap.bare"), [0, 0, 1, 0])
        self.assertEqual(counts("hypochondria", "gains"), [7, 4, 2, 4])
        strips = [a + b for a, b in zip(counts("flay.shield"), counts("flay.rebounding"))]
        self.assertEqual(strips, [25, 5, 7, 19])
        snakes = [a + b for a, b in zip(counts("snake.hit"), counts("snake.blocked"))]
        self.assertEqual(snakes, [11, 21, 9, 29])

    def test_refusals_by_kind(self):
        # grep: "You are paralysed and cannot do that." az 6, Z5 28, g 2; "... unable to do that." az 6, X 2; "... are
        # unable to drop anything." X 1; "Paralysed as you are, your body is not able to ..." X 1 (row 3781);
        # "Your state of paralysis prevents you from doing that." Z5 2.
        self.assertEqual(counts("refused.paralysis"), [12, 30, 2, 4])
        # X 656-657 and 1667-1668: a salve on slick skin. No salve clock is spent, so it is not a salve.
        self.assertEqual(counts("refused.slickness"), [0, 0, 0, 2])
        self.assertEqual(counts("salve.refused"), [0, 0, 0, 2])
        self.assertEqual(counts("salve"), [5, 1, 0, 2])
        self.assertEqual(counts("refused.salt"), [0, 3, 0, 0])
        self.assertEqual(counts("refused.accelerate"), [0, 0, 0, 1])
        self.assertEqual(counts("refused.study"), [0, 1, 0, 0])

    def test_rows_after_the_last_prompt(self):
        # Both losses end after the last prompt: az 3913 (vomit) and 3916 (death); Z5 5628 (agony) and 5631 (death).
        self.assertEqual(counts("death"), [1, 1, 0, 0])
        self.assertEqual(counts("vomit")[0], 3)
        self.assertEqual(counts("agony")[1], 5)
        death = [ev for ev in E.stream(E.load("Z5")) if ev["name"] == "death"][0]
        self.assertEqual(death["row"], 5631)
        self.assertTrue(death["late"])
        self.assertEqual(death["t"], 259.132)  # the last prompt's stamp, row 5590: a floor on the true time

    def test_class_cure_recovery(self):
        # X row 2409: "ACCELERATE BACK. You may accelerate time to cleanse your afflictions once again." (a client prefix).
        self.assertEqual(counts("recover.accelerate"), [0, 0, 0, 1])
        self.assertEqual(counts("recover.salt"), [0, 7, 0, 0])

    def test_sileris_lines(self):
        # Claes applies the herb; Elmer and Nikita the mineral, quicksilver ("The quicksilver hardens into a supple metallic
        # shell.": Z5 9, g 7, X 15). Review TC-10: the herb alone left the coating down in three logs.
        self.assertEqual(counts("sileris.apply"), [13, 14, 7, 15])
        self.assertEqual(counts("sileris.up"), [12, 9, 7, 15])
        self.assertEqual(counts("sileris.down"), [13, 10, 7, 16])

    def test_balance_and_equilibrium_lines(self):
        # CONFIG SEEBALANCES: Claes prints only equilibrium. A fork reads these to start the victim's own clocks.
        self.assertEqual(counts("eq.used"), [24, 22, 9, 96])
        self.assertEqual(counts("bal.used"), [0, 8, 21, 78])
        self.assertEqual(counts("recover.eq"), [23, 21, 10, 96])
        self.assertEqual(counts("recover.bal"), [41, 55, 11, 79])
        used = [ev for ev in E.stream(E.load("Z5")) if ev["row"] == 1387][0]
        self.assertEqual((used["name"], used["args"]), ("eq.used", ["3.40"]))

    def test_smoke_items(self):
        # The rebounding smoke is skullcap (az) or malachite (g, X).
        smokes = [ev["args"][0] for ev in E.stream(E.load("X")) if ev["name"] == "smoke" and ev["kind"] == "cure"]
        self.assertEqual(smokes.count("malachite"), 24)

    def test_second_venom_follows_hit_and_miss(self):
        second, hit, miss = counts("dstab.second"), counts("dstab"), counts("dstab.miss")
        self.assertEqual(second, [h + m for h, m in zip(hit, miss)])

    def test_no_census_line_is_an_affliction_message(self):
        # The anorexia gain line was first read as a refusal, and the unease line is the hypochondria gain line. A pattern
        # that matches a gain or cure message hides that event from the stream.
        with open(E.AFFLICTIONS, encoding="utf-8") as fh:
            affs = json.load(fh)
        msgs = [(v.get(f) or "").strip() for v in affs.values() for f in ("afflicted_msg", "cured_msg")]
        msgs += [m for m, _, _ in E.EXTRA_GAINS]
        for name, _, _, regex in E.LINES:
            for msg in msgs:
                if msg:
                    self.assertIsNone(regex.search(msg), "%s matches %r" % (name, msg))

    def test_suggested_anorexia_line(self):
        # az rows 529-530: "[AFF]: Anorexia" then the line. Every SNAP of Thato set one off 9-11 s later.
        delays = data()["census"]["az"]["suppliers"]["snap.anorexia"]
        self.assertEqual(len(delays), 7)
        self.assertTrue(all(9.0 <= d <= 11.0 for d in delays), delays)
        # Z5's SNAP at row 5189 is followed by a venom anorexia at 5221 (a DSTAB). That is not the SNAP's.
        self.assertEqual(data()["census"]["Z5"]["suppliers"]["snap.anorexia"], [])


class Messages(unittest.TestCase):
    def test_shared_message_names_one_affliction(self):
        # afflictions.json gives disfigurement and disloyalty one message. The loggers tag disloyalty (Z5 332, X 344).
        self.assertEqual(counts("disfigurement", "gains"), [0, 0, 0, 0])
        self.assertEqual(counts("disloyalty", "gains")[1], 11)
        self.assertEqual(counts("disfigurement", "loses"), [0, 0, 0, 0])

    def test_template_cure_line(self):
        # "Thank $(creator$)! Your clumsiness has been cured." The game prints "Thank Maya, the Great Mother! ..." (az 141).
        self.assertEqual(counts("clumsiness", "loses"), [10, 6, 9, 20])

    def test_a_wrapped_template_head(self):
        # Review EV-5 residual: a wrap leaves the head of a template line on its row, as for a plain message. A head must
        # end in its own words: "Thank Maya, the" ends inside the placeholder and names nothing.
        gains, cures = E.messages()
        self.assertEqual(E.match_message("Thank Maya, the Great Mother! Your clumsiness", cures), [("clumsiness", [])])
        self.assertEqual(E.match_message("Thank Maya, the Great Mother! Your clumsiness has been", cures),
                         [("clumsiness", [])])
        self.assertEqual(E.match_message("Thank Maya, the Great Mother and all the gods", cures), [])
        # The head must hold a letter of its own words: "Thank .+?!" took any "Thank ...!" row (review EV-5 nit).
        self.assertEqual(E.match_message("Thank you for the duel, Seurimas!", cures), [])
        # The lovers template, whole and wrapped.
        self.assertEqual(E.match_message("You shake your head, wondering what you ever saw in Seurimas.", cures),
                         [("lovers", [])])
        self.assertEqual(E.match_message("You shake your head, wondering what you ever saw", cures), [("lovers", [])])
        self.assertEqual(E.match_message("A diminutive homunculus resembling Elmer claws into your", gains),
                         [("homunculusmercury", [])])

    def test_pinshot_gain_line(self):
        # Review EV-6 residual: afflictions.json has no pinshot message, so its 7 cures had no gain. The tag follows the
        # line (az 13-14, X 3290-3291).
        self.assertEqual(counts("pinshot", "gains"), [2, 2, 1, 2])
        rows = [ev["row"] for ev in E.stream(E.load("az")) if ev["name"] == "pinshot" and ev["kind"] == "gain"]
        self.assertEqual(rows, [13, 1620])

    def test_the_firefly_pipe_is_a_smoke(self):
        # Review R3-docs-2: az 573 prints the pipe's own line after "[Curing]: SMOKE SKULLCAP" (572), and the aura came
        # up at 743, 8.475 s later. The item comes from the [Curing] line.
        smoke = [ev for ev in E.stream(E.load("az")) if ev["row"] == 573]
        self.assertEqual([(ev["kind"], ev["name"], ev["args"]) for ev in smoke], [("cure", "smoke", ["skullcap"])])

    def test_extra_gain_lines(self):
        self.assertEqual(counts("stupidity", "gains")[1], 6)  # Z5 536: "Your mind feels somewhat slower ..."
        self.assertEqual(counts("recklessness", "gains")[3], 9)  # X 418, wrapped onto two rows
        self.assertEqual(counts("vertigo", "gains")[3], 8)  # X 295
        self.assertEqual(counts("homunculusmercury", "gains")[1], 3)  # Z5 1291
        # Our homunculus attacking the Serpent is not a gain (Z5 392: "... stares menacingly at Seurimas").
        rows = [ev["row"] for ev in E.stream(E.load("Z5")) if ev["name"] == "homunculusmercury" and ev["kind"] == "gain"]
        self.assertNotIn(392, rows)

    def test_every_tag_has_a_line(self):
        # The loggers' own tags: "[AFF]: X" (az, Z5, g: for a gain or a cure) and "You have been afflicted with X." (X: a
        # gain). Every tag in a packet with a game line has a gain or a lose of X in that packet, before or after the tag
        # (X 1520-1521 prints the line first). Left out, because the game prints no line of its own: disrupted with the
        # confusion of a BITE (az 3802, Z5 4941, 5467). Pinshot has its line since review EV-6 (EXTRA_GAINS).
        import re
        tags = (re.compile(r"^\[AFF\]: (\w+)\s*$"), re.compile(r"^You have been afflicted with (\w+)\.\s*$"))
        missed = {}
        for key in E.KEYS:
            log = E.load(key)
            by_row = {}
            for ev in E.stream(log):
                if ev["kind"] in ("gain", "lose"):
                    by_row.setdefault(ev["row"], set()).update(ev["name"].split("|"))
            packet = []
            for r in list(log) + [None]:
                if r is not None and r.kind != "prompt":
                    packet.append(r)
                    continue
                names = set().union(*[by_row.get(x.n + 1, set()) for x in packet]) if packet else set()
                texts = [(x.n + 1, (x.text or "").strip()) for x in packet if x.kind == "line" and x.text]
                has_line = any(not any(t.match(text) for t in tags) for _, text in texts)
                for row, text in texts:
                    for t in tags:
                        m = t.match(text)
                        if m and has_line and m.group(1).lower() not in names:
                            missed.setdefault(m.group(1).lower(), []).append("%s %d" % (key, row))
                packet = []
        self.assertEqual(set(missed), {"disrupted"}, missed)
        self.assertEqual(missed["disrupted"], ["az 3802", "Z5 4941", "Z5 5467"])

    def test_darkshade_burn(self):
        # "Your skin prickles and burns." is a gain only when the board lacks darkshade: X 796, 1032, 2820 are gains, and
        # 2268, 3866, 5199 are ticks of a darkshade already up. X then has 8 gains, as many as Nikita's 8 tags.
        events = E.stream(E.load("X"))
        burns = [ev["row"] for ev in events if ev["name"] == "darkshade.burn"]
        gains = [ev["row"] for ev in events if ev["name"] == "darkshade" and ev["kind"] == "gain" and "burn" in ev["args"]]
        self.assertEqual(burns, [797, 1033, 2268, 2821, 3866, 5199])
        self.assertEqual(gains, [797, 1033, 2821])
        self.assertEqual(counts("darkshade", "gains")[3], 8)

    def test_disrupted_and_the_sun(self):
        self.assertEqual(counts("disrupted", "gains"), [7, 0, 2, 0])  # az 331: "Your mental equilibrium scatters ..."
        sun = [ev["row"] for ev in E.stream(E.load("X")) if ev["kind"] == "gain" and "sun" in ev["args"]]
        self.assertEqual(sun, [1520, 6555])  # "The sun has rendered you too weak to move a muscle."


class Race(unittest.TestCase):
    def test_golden_row(self):
        spec = E.gates()["stage1"]["golden_race_row"]
        ok, row = E.golden(data()["race"], spec)
        self.assertTrue(ok, row)
        self.assertEqual(row["eats"], 1)
        self.assertEqual(row["first_eat"], "magnesium chip")
        self.assertTrue(row["down"])

    def test_one_row_per_prick(self):
        self.assertEqual(len(data()["race"]), sum(counts("dstab")))

    def test_tie_goes_by_row_order(self):
        # az row 1113: the next DSTAB and the eat's return share the stamp 19:15:30:957, and "You may eat" (row 1121) prints
        # after the prick. The eat was still down when the prick landed.
        row = [r for r in data()["race"] if r["src"] == "az" and r["row"] == 1092][0]
        self.assertEqual(row["next_row"], 1113)
        self.assertEqual(row["by"], 0.0)
        self.assertEqual(row["winner"], "strike")

    def test_eats_between_stop_at_the_next_attack(self):
        # az row 746: the next DSTAB (row 982) is 11.8 s later, too late to pair. The eat at row 992 is after it, so it is
        # not this strike's first eat.
        row = [r for r in data()["race"] if r["src"] == "az" and r["row"] == 746][0]
        self.assertIsNone(row["winner"])
        self.assertIsNone(row["first_eat"])
        self.assertIsNone(row["delay"])

    def test_phase_sign(self):
        rows = [{"t": 10.0, "row": 5}, {"t": 10.0, "row": 7}]
        self.assertEqual(E.phase_at({"t": 10.0, "row": 7}, rows[0]), (0.0, True))
        self.assertEqual(E.phase_at({"t": 10.0, "row": 5}, rows[1]), (0.0, False))
        self.assertEqual(E.phase_at({"t": 10.6, "row": 3}, rows[0]), (0.6, False))


class Stream(unittest.TestCase):
    def test_event_shape(self):
        events = E.stream(E.load("Z5"))
        for ev in events[:200]:
            self.assertEqual(ev["v"], E.STREAM_VERSION)
            self.assertIn(ev["side"], ("A", "V", "W"))
            self.assertEqual(ev["view"], "lines")
        prick = [ev for ev in events if ev["row"] == 196 and ev["name"] == "dstab"]
        self.assertEqual(len(prick), 1)
        self.assertEqual(prick[0]["who"], "Seurimas")

    def test_class_cure_names_its_cures(self):
        # Z5 1786 "Directing the energy of salt ..." then 1787 the cure line. The eat at 1769 is in an earlier packet.
        lose = [ev for ev in E.stream(E.load("Z5")) if ev["row"] == 1787 and ev["kind"] == "lose"]
        self.assertTrue(lose)
        self.assertEqual({ev["by"] for ev in lose}, {"salt"})

    def test_dagaz_and_accelerate_name_their_cures(self):
        # Review EV-9 residual: the rune's flare and the Accelerate line name the cure lines after them.
        def by(key):
            return [(ev["row"], ev["by"]) for ev in E.stream(E.load(key)) if ev["kind"] == "lose" and ev.get("by") in
                    ("dagaz", "accelerate")]
        self.assertEqual([row for row, _ in by("az")], [360, 718, 1727, 2050, 2416, 2698, 3041, 3680, 3857])
        self.assertEqual({who for _, who in by("az")}, {"dagaz"})
        self.assertEqual(by("X"), [(2090, "accelerate"), (2092, "accelerate")])

    def test_check_matches_files(self):
        with open(E.OUT_JSON, encoding="utf-8") as fh:
            have = fh.read().replace("\r\n", "\n")
        self.assertEqual(E.dump(data()), have)


if __name__ == "__main__":
    unittest.main()
