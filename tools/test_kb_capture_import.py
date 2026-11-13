"""Tests for tools/kb_capture_import.py: the ABADMIN and ARTEFACT POWER routes (v4.7.494).

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

PULSE = """Pulse (Psionics)  ABADMIN ID: 3292            Known: No (2974 lessons required)
-------------------------------------------------------------------------------
Syntax:            PSI PULSE <target>
Works on/against:  Adventurers
Cooldown:          1.00 seconds of equilibrium
Details:
Attune your gifts to the pulse of your target to sense exactly how
heavily they are bleeding.

-------------------------------------------------------------------------------"""

DIAG = """Diagnose (Survival)  ABADMIN ID: 1380         Known: Yes
-------------------------------------------------------------------------------
Syntax:            DIAGNOSE/DIAG [ME]
Works on/against:  Self
Cooldown:          1.00 seconds of equilibrium
Details:
With this ability, you may check and see a list of what ails you.
-------------------------------------------------------------------------------"""

LIST = """Item ID       Item Name                           Power                Level
-------------------------------------------------------------------------------
385702        an Aldar Diadem                     faster_eq              2
-------------------------------------------------------------------------------"""


def capture(*blocks):
    """A kb_capture.txt text from (cmd, body, timeout) triples."""
    out = []
    for cmd, body, *rest in blocks:
        tail = " | TIMEOUT" if rest and rest[0] else ""
        out += [f"##### KBCAPTURE 2026-11-13T12:00:00Z | {cmd}{tail}", body, "##### END"]
    return "\n".join(out) + "\n"


class AbadminRoute(unittest.TestCase):
    def test_a_record_is_filed_by_skill_ability_and_id(self):
        blocks = ki.parse(capture(("abadmin show 3292", PULSE)))
        files, refused, kept = ki.route_abadmin(blocks, {})
        path = os.path.join("kb", "raw", "ab", "psionics_pulse_3292.txt")
        self.assertEqual(list(files), [path])
        self.assertTrue(files[path].startswith("Pulse (Psionics)  ABADMIN ID: 3292"))
        self.assertIn("heavily they are bleeding.", files[path])
        self.assertTrue(files[path].endswith("-" * 79 + "\n"))
        self.assertEqual((refused, kept), ([], []))

    def test_an_id_already_filed_is_kept_not_written(self):
        blocks = ki.parse(capture(("abadmin show 1380", DIAG)))
        files, refused, kept = ki.route_abadmin(blocks, {1380: "survival_diagnose_1380.txt"})
        self.assertEqual((files, refused, kept), ({}, [], [1380]))

    def test_a_late_answer_is_filed_by_its_own_header(self):
        # 3292 timed out empty and its record landed in the block of 3293.
        blocks = ki.parse(capture(("abadmin show 3292", "", True), ("abadmin show 3293", PULSE)))
        files, refused, kept = ki.route_abadmin(blocks, {})
        self.assertEqual(list(files), [os.path.join("kb", "raw", "ab", "psionics_pulse_3292.txt")])
        self.assertEqual([c for c, _ in refused], ["abadmin show 3293"])

    def test_an_id_with_no_record_is_reported(self):
        blocks = ki.parse(capture(("abadmin show 999999", "There is no such ability.")))
        files, refused, _ = ki.route_abadmin(blocks, {})
        self.assertEqual(files, {})
        self.assertEqual(refused, [("abadmin show 999999", "There is no such ability.")])

    def test_ab_ids_reads_the_header_of_each_file(self):
        with tempfile.TemporaryDirectory() as d:
            with open(os.path.join(d, "serpent_obliviate_2115.txt"), "w", encoding="utf-8") as fh:
                fh.write("Obliviate (Attainment)  ABADMIN ID: 2115      Known: Yes\n")
            with open(os.path.join(d, "notes.txt"), "w", encoding="utf-8") as fh:
                fh.write("no header here\n")
            self.assertEqual(ki.ab_ids(d), {2115: "serpent_obliviate_2115.txt"})

    def test_the_repo_files_keep_their_ids(self):
        have = ki.ab_ids(os.path.join(ki.ROOT, ki.AB_DIR))
        self.assertEqual(have.get(2115), "serpent_obliviate_2115.txt")
        self.assertEqual(have.get(3292), "psionics_pulse_2026-10-23.txt")


class ArtefactRoute(unittest.TestCase):
    def test_the_list_and_each_power(self):
        blocks = ki.parse(capture(("artefact power list owned", LIST),
                                  ("artefact power show faster_eq", "Faster equilibrium recovery."),
                                  ("artefact power show tuning", "")))
        files, silent = ki.route_artefacts(blocks)
        lst = os.path.join("kb", "raw", "live", "artefact_power_list_owned.txt")
        show = os.path.join("kb", "raw", "artefacts", "faster_eq.txt")
        self.assertEqual(sorted(files), sorted([lst, show]))
        self.assertIn("385702        an Aldar Diadem", files[lst])
        self.assertTrue(files[show].startswith("# artefact power show faster_eq  (2026-11-13T12:00:00Z)\n"))
        self.assertEqual(silent, ["artefact power show tuning"])

    def test_routed_commands_do_not_also_go_to_other(self):
        for cmd in ("abadmin show 12", "artefact power list owned", "artefact power show tuning"):
            self.assertTrue(ki.is_routed(cmd), cmd)
        for cmd in ("help cures", "abadmin", "artefact list"):
            self.assertFalse(ki.is_routed(cmd), cmd)


if __name__ == "__main__":
    unittest.main()
