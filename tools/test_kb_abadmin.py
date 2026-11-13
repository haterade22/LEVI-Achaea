"""Tests for tools/kb_abadmin.py: ABADMIN records -> abadmin.json + abadmin-vs-wiki.md (v4.7.494).

    python -B tools/test_kb_abadmin.py
"""
import json
import os
import sys
import tempfile
import unittest

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kb_abadmin as ka  # noqa: E402

OBLIVIATE = """Obliviate (Attainment)  ABADMIN ID: 2115      Known: Yes
-------------------------------------------------------------------------------
Syntax:            OBLIVIATE <target>
Extra Information: Gives denizen affliction: Amnesia

Works on/against:  Denizens
Cooldown:          41.00 seconds
Resource:          28 rage
Details:
Use a minor hypnosis technique to cause your target to forget what it was doing, giving it amnesia for a few seconds.
-------------------------------------------------------------------------------
"""

CRUSH = """Crush (Telepathy)  ABADMIN ID: 900      Known: Yes
-------------------------------------------------------------------------------
Syntax:            MIND CRUSH <target>
Works on/against:  Adventurers and denizens
Cooldown:          3.40 seconds of equilibrium
Details:
Crush the mind.
-------------------------------------------------------------------------------
"""


class Parse(unittest.TestCase):
    def test_a_record_and_its_fields(self):
        r = ka.parse_record(OBLIVIATE)
        self.assertEqual((r["id"], r["ability"], r["skill"], r["known"]), (2115, "Obliviate", "Attainment", "Yes"))
        self.assertEqual(r["target"], "Denizens")
        self.assertEqual(r["resource"], "28 rage")
        self.assertEqual(r["extra"], "Gives denizen affliction: Amnesia")
        self.assertEqual((r["seconds"], r["clock"]), (41.0, "cooldown"))
        self.assertTrue(r["details"].startswith("Use a minor hypnosis"))

    def test_the_clock_of_a_cost(self):
        self.assertEqual(ka.clock("1.00 seconds of equilibrium"), (1.0, "equilibrium"))
        self.assertEqual(ka.clock("2.50 seconds of balance"), (2.5, "balance"))
        self.assertEqual(ka.clock(""), (None, None))

    def test_no_header_is_no_record(self):
        self.assertIsNone(ka.parse_record("There is no such ability."))


class Compare(unittest.TestCase):
    def build(self, files, wiki):
        with tempfile.TemporaryDirectory() as d:
            ab = os.path.join(d, "ab")
            os.makedirs(ab)
            for name, text in files.items():
                with open(os.path.join(ab, name), "w", encoding="utf-8") as fh:
                    fh.write(text)
            wp = os.path.join(d, "abilities.json")
            with open(wp, "w", encoding="utf-8") as fh:
                json.dump(wiki, fh)
            return ka.build(ab, wp)

    def test_a_cost_that_differs_is_listed_and_a_missing_one_too(self):
        wiki = {"Telepathy": {"abilities": [{"skill": "Crush", "cooldown": "4.00 seconds of equilibrium",
                                             "target": "Adventurers and denizens"}]}}
        js, md = self.build({"telepathy_crush_900.txt": CRUSH, "attainment_obliviate_2115.txt": OBLIVIATE}, wiki)
        self.assertEqual(json.loads(js)["count"], 2)
        self.assertIn("| 900 | Telepathy | Crush | 3.40 seconds of equilibrium | 4.00 seconds of equilibrium |", md)
        self.assertIn("| cost |", md)
        self.assertIn("| 2115 | Attainment | Obliviate |", md)
        self.assertIn("Differ from the wiki: 1. Not on the wiki: 1.", md)

    def test_the_same_cost_is_not_listed(self):
        wiki = {"Telepathy": {"abilities": [{"skill": "Crush", "cooldown": "3.40 seconds of equilibrium",
                                             "target": "Adventurers and denizens"}]}}
        _, md = self.build({"telepathy_crush_900.txt": CRUSH}, wiki)
        self.assertIn("Differ from the wiki: 0. Not on the wiki: 0.", md)

    def test_the_repo_pages_are_current(self):
        js, md = ka.build()
        with open(ka.OUT_JSON, encoding="utf-8") as fh:
            self.assertEqual(fh.read(), js)
        with open(ka.OUT_MD, encoding="utf-8") as fh:
            self.assertEqual(fh.read(), md)


if __name__ == "__main__":
    unittest.main()
