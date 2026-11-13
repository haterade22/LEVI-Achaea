"""Tests for tools/kb_capture_import.py: the ABADMIN SHOW and ARTEFACT POWER routes (v4.7.494, v4.7.496).

The record text is the game's, from the first live run (2026-11-13, kb/raw/live/captures/).

    python -B tools/test_kb_capture_import.py
"""
import os
import sys
import tempfile
import unittest

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kb_capture_import as ki  # noqa: E402

OBLIVIATE = """Ability: Obliviate (Record #2115)
Associated skill: Attainment
Skillpoints required: 38999
Blurb: Induce forgetfulness in your target.
Syntax: OBLIVIATE <target>
Extra info: Gives denizen affliction: Amnesia
Abfile:
Use a minor hypnosis technique to cause your target to forget what it was doing, giving it amnesia for a few seconds.
Useable on: denizens
Pre checks:
Ability range: none
Aggression type: non-aggressive
Requires arms: 0
Requires legs: 0
Useable entangled: No
Useable paralysed: No
Cooldown: 41.00 seconds
Resource: 28 rage
Skill specialisation: br_serpent"""

FISTSIGIL = """Ability: Fistsigil (Record #46)
Associated skill: Conjuration
Maps to record 785 (FIST)."""

ROOM = "The seethe and churn of magma writes an ashen end for Kalys, Ashtan's molten embrace marking his smouldering epitaph."

LIST = """Item ID       Item Name                           Power                Level
-------------------------------------------------------------------------------
385702        an Aldar Diadem                     faster_eq              2
-------------------------------------------------------------------------------"""

FASTER_EQ = """The faster_eq artefact power:
--------------------------------------------------------------------------------
Levels:                  2
Owner only:              No
Must be worn:            Yes
Owned:                   an Aldar Diadem (385702), level 2
--------------------------------------------------------------------------------"""


def capture(*blocks):
    """A kb_capture.txt text from (cmd, body, timeout) triples."""
    out = []
    for cmd, body, *rest in blocks:
        tail = " | TIMEOUT" if rest and rest[0] else ""
        out += [f"##### KBCAPTURE 2026-11-13T12:00:00Z | {cmd}{tail}", body, "##### END"]
    return "\n".join(out) + "\n"


def ab_path(name):
    return os.path.join("kb", "raw", "abadmin", name)


class AbadminRoute(unittest.TestCase):
    def test_a_record_is_filed_by_skill_ability_and_id(self):
        blocks = ki.parse(capture(("abadmin show 2115", OBLIVIATE)))
        files, stale, free, unanswered = ki.route_abadmin(blocks, {})
        path = ab_path("attainment_obliviate_2115.txt")
        self.assertEqual(list(files), [path])
        self.assertEqual(files[path], OBLIVIATE + "\n")
        self.assertEqual((stale, free, unanswered), ([], [], []))

    def test_the_ab_commands_header_is_not_a_record(self):
        # v4.7.494 looked for this line, which ABADMIN SHOW never prints.
        blocks = ki.parse(capture(("abadmin show 2115", "Obliviate (Attainment)  ABADMIN ID: 2115      Known: Yes")))
        files, _, free, unanswered = ki.route_abadmin(blocks, {})
        self.assertEqual((files, free), ({}, []))
        self.assertEqual([c for c, _ in unanswered], ["abadmin show 2115"])

    def test_a_pointer_record_is_a_record(self):
        files, *_ = ki.route_abadmin(ki.parse(capture(("abadmin show 46", FISTSIGIL))), {})
        self.assertEqual(files, {ab_path("conjuration_fistsigil_46.txt"): FISTSIGIL + "\n"})

    def test_a_room_line_before_the_record_is_not_part_of_it(self):
        files, *_ = ki.route_abadmin(ki.parse(capture(("abadmin show 46", ROOM + "\n" + FISTSIGIL))), {})
        self.assertEqual(files[ab_path("conjuration_fistsigil_46.txt")], FISTSIGIL + "\n")

    def test_a_late_answer_is_filed_by_its_own_first_line(self):
        # 2115 timed out empty and its record landed in the block of 2116.
        blocks = ki.parse(capture(("abadmin show 2115", "", True), ("abadmin show 2116", OBLIVIATE)))
        files, _, _, unanswered = ki.route_abadmin(blocks, {})
        self.assertEqual(list(files), [ab_path("attainment_obliviate_2115.txt")])
        self.assertEqual([c for c, _ in unanswered], ["abadmin show 2116"])

    def test_no_such_record_is_a_free_id_and_a_room_line_alone_is_no_answer(self):
        # Id 73 of the first run: a room line and its prompt closed the block before the game answered.
        blocks = ki.parse(capture(("abadmin show 44", "No such record."), ("abadmin show 73", ROOM)))
        files, _, free, unanswered = ki.route_abadmin(blocks, {})
        self.assertEqual((files, free), ({}, [44]))
        self.assertEqual(unanswered, [("abadmin show 73", ROOM)])

    def test_a_renamed_ability_leaves_no_second_file(self):
        blocks = ki.parse(capture(("abadmin show 2115", OBLIVIATE)))
        _, stale, _, _ = ki.route_abadmin(blocks, {2115: "serpent_obliviate_2115.txt"})
        self.assertEqual(stale, [ab_path("serpent_obliviate_2115.txt")])
        _, stale, _, _ = ki.route_abadmin(blocks, {2115: "attainment_obliviate_2115.txt"})
        self.assertEqual(stale, [])

    def test_ab_ids_reads_the_first_line_of_each_file(self):
        with tempfile.TemporaryDirectory() as d:
            with open(os.path.join(d, "attainment_obliviate_2115.txt"), "w", encoding="utf-8") as fh:
                fh.write(OBLIVIATE + "\n")
            with open(os.path.join(d, "notes.txt"), "w", encoding="utf-8") as fh:
                fh.write("Obliviate (Attainment)  ABADMIN ID: 2115      Known: Yes\n")
            self.assertEqual(ki.ab_ids(d), {2115: "attainment_obliviate_2115.txt"})

    def test_every_repo_file_is_named_by_its_own_id(self):
        have = ki.ab_ids(os.path.join(ki.ROOT, ki.AB_DIR))
        for ab_id, name in have.items():
            self.assertTrue(name.endswith(f"_{ab_id}.txt"), name)


class ArtefactRoute(unittest.TestCase):
    def test_the_list_and_each_power(self):
        blocks = ki.parse(capture(("artefact power list owned", LIST),
                                  ("artefact power show faster_eq", FASTER_EQ),
                                  ("artefact power show tuning", "")))
        files, silent = ki.route_artefacts(blocks)
        lst = os.path.join("kb", "raw", "live", "artefact_power_list_owned.txt")
        show = os.path.join("kb", "raw", "artefacts", "faster_eq.txt")
        self.assertEqual(sorted(files), sorted([lst, show]))
        self.assertIn("385702        an Aldar Diadem", files[lst])
        self.assertTrue(files[show].startswith("# artefact power show faster_eq  (2026-11-13T12:00:00Z)\n"))
        self.assertIn("Must be worn:            Yes", files[show])
        self.assertEqual(silent, ["artefact power show tuning"])

    def test_routed_commands_do_not_also_go_to_other(self):
        for cmd in ("abadmin show 12", "artefact power list owned", "artefact power show tuning"):
            self.assertTrue(ki.is_routed(cmd), cmd)
        for cmd in ("help cures", "abadmin", "artefact list"):
            self.assertFalse(ki.is_routed(cmd), cmd)


if __name__ == "__main__":
    unittest.main()
