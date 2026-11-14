"""Tests for tools/kb_abadmin.py: ABADMIN SHOW records -> abadmin.json + abadmin-vs-wiki.md (v4.7.494, v4.7.496).

The record text is the game's, from the first live run (2026-11-13, kb/raw/live/captures/).

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
Skill specialisation: br_serpent
"""

# Several syntax lines with no label, and a "Note:" line in the text that is not a field.
ROBES = """Ability: Robes (Record #3)
Associated skill: Alchemy
Skillpoints required: 699
Blurb: The mystic garb of the Alchemist.
Syntax: ROBES SUMMON
ROBES CALL
ROBES CLEAR
Abfile:
Robes are the traditional garb of the alchemist.

Note: a symbol may only appear once on a pair of robes.
Useable on: self
Pre checks:
Ability range: none
Aggression type: non-aggressive
Requires arms: 1
Requires legs: 0
Useable entangled: No
Useable paralysed: No
Cooldown: 2.00 seconds of equilibrium
Resource: 100 mana
The ability name ROBESUMMON is mapped to this ability.
"""

FISTSIGIL = """Ability: Fistsigil (Record #46)
Associated skill: Conjuration
Maps to record 785 (FIST).
"""


# An empty slot, from the full run (2026-11-13): no name, no skill.
EMPTY = """Ability:  (Record #3293)
Associated skill:
Skillpoints required: 0
Blurb:
Syntax:
Abfile:

Useable on: none
Pre checks:
Ability range: none
Aggression type: non-aggressive
Requires arms: 0
Requires legs: 0
Useable entangled: No
Useable paralysed: No
"""


class Parse(unittest.TestCase):
    def test_a_record_and_its_fields(self):
        r = ka.parse_record(OBLIVIATE)
        self.assertEqual((r["id"], r["ability"], r["skill"], r["skillpoints"]), (2115, "Obliviate", "Attainment", 38999))
        self.assertEqual(r["target"], "denizens")
        self.assertEqual(r["resource"], "28 rage")
        self.assertEqual(r["extra"], ["Gives denizen affliction: Amnesia"])
        self.assertEqual(r["syntax"], ["OBLIVIATE <target>"])
        self.assertEqual((r["arms"], r["legs"], r["entangled"], r["paralysed"]), (0, 0, "No", "No"))
        self.assertEqual(r["specialisation"], "br_serpent")
        self.assertEqual((r["seconds"], r["clock"]), (41.0, "cooldown"))
        self.assertTrue(r["abfile"].startswith("Use a minor hypnosis"))
        self.assertEqual(r["prechecks"], [])

    def test_syntax_lines_with_no_label_and_a_note_in_the_text(self):
        r = ka.parse_record(ROBES)
        self.assertEqual(r["syntax"], ["ROBES SUMMON", "ROBES CALL", "ROBES CLEAR"])
        self.assertIn("Note: a symbol may only appear once", r["abfile"])
        self.assertEqual(r["target"], "self")
        self.assertEqual(r["aliases"], ["ROBESUMMON"])
        self.assertEqual((r["seconds"], r["clock"]), (2.0, "equilibrium"))
        self.assertNotIn("other", r)

    def test_a_pointer_record(self):
        r = ka.parse_record(FISTSIGIL)
        self.assertEqual((r["id"], r["skill"], r["maps_to"], r["maps_name"]), (46, "Conjuration", 785, "FIST"))

    def test_an_empty_slot(self):
        r = ka.parse_record(EMPTY)
        self.assertEqual((r["id"], r["ability"], r["skill"], r["target"]), (3293, "", "", "none"))
        self.assertEqual((r["seconds"], r["clock"], r["abfile"]), (None, None, ""))
        self.assertNotIn("other", r)

    def test_the_clock_of_a_cost(self):
        self.assertEqual(ka.clock("1.00 seconds of equilibrium"), (1.0, "equilibrium"))
        self.assertEqual(ka.clock("2.50 seconds of balance"), (2.5, "balance"))
        self.assertEqual(ka.clock("1.70 seconds of humour balance"), (1.7, "humour balance"))
        self.assertEqual(ka.clock("Equilibrium"), (None, "equilibrium"))
        # A wiki cost that runs on into other text (Alchemy Iron).
        self.assertEqual(ka.clock("4.00 seconds of equilibrium symbol=Two isosceles triangles"), (4.0, "equilibrium"))

    def test_a_clock_of_three_words(self):
        self.assertEqual(ka.clock("3.00 seconds of hydra head balance"), (3.0, "hydra head balance"))
        self.assertEqual(ka.clocks("TRACK: 4.50 seconds of equilibrium PURSUE: 1.00 seconds of equilibrium"),
                         [(4.5, "equilibrium"), (1.0, "equilibrium")])

    def test_a_cost_differs_only_where_both_sides_state_it(self):
        self.assertTrue(ka.cost_differs("4.50 seconds of balance", "4.00 seconds of balance. (Deposit and Release)"))
        self.assertTrue(ka.cost_differs("3.00 seconds of balance", "3.00 seconds of equilibrium"))
        # One of the wiki's sub-command costs is the game's.
        self.assertFalse(ka.cost_differs("4.50 seconds of equilibrium",
                                         "TRACK: 4.50 seconds of equilibrium PURSUE: 1.00 seconds of equilibrium"))
        # A gap on one side.
        self.assertFalse(ka.cost_differs("3.00 seconds of balance", ""))
        self.assertFalse(ka.cost_differs("", "3.00 seconds of balance"))
        self.assertFalse(ka.cost_differs("Equilibrium", "3.00 seconds of equilibrium"))
        # No number, and another clock.
        self.assertTrue(ka.cost_differs("Equilibrium", "3.00 seconds of balance"))
        # Text with no number that is not a clock (Devotion Illuminate) is a gap.
        self.assertFalse(ka.cost_differs("Equilibrium", "Illuminate: 1000 mana, and 1500 devotion"))
        # Two costs: each must be among the wiki's, in any order (Sagas Descent, Woe Condemned).
        self.assertFalse(ka.cost_differs("2.80 seconds of equilibrium and 25.00 seconds of voice balance",
                                         "25.00 seconds of voice balance and 2.80 seconds of equilibrium"))
        self.assertTrue(ka.cost_differs("15.00 seconds of voice balance and 3.00 seconds of equilibrium",
                                        "15.00 seconds of voice balance and 2.00 seconds of equilibrium"))

    def test_a_name_with_a_space_maps_to_the_record(self):
        r = ka.parse_record(FISTSIGIL.replace("Maps to record 785 (FIST).\n", "")
                            + "The ability name CONCUSSION BOMB is mapped to this ability.\n")
        self.assertEqual(r["aliases"], ["CONCUSSION BOMB"])
        self.assertNotIn("other", r)

    def test_none_is_no_target(self):
        self.assertEqual(ka.norm_target("Self unique=Yes"), "self")
        self.assertEqual(ka.norm_target("none"), ka.norm_target(""))
        self.assertEqual(ka.norm_target("Adventurers and denizens."), "adventurers and denizens")
        self.assertEqual(ka.clock(""), (None, None))

    def test_no_record_line_is_no_record(self):
        self.assertIsNone(ka.parse_record("No such record."))
        # The AB command's header is not an ABADMIN SHOW record.
        self.assertIsNone(ka.parse_record("Obliviate (Attainment)  ABADMIN ID: 2115      Known: Yes"))


class Compare(unittest.TestCase):
    def build(self, files, wiki):
        with tempfile.TemporaryDirectory() as d:
            ab = os.path.join(d, "abadmin")
            os.makedirs(ab)
            for name, text in files.items():
                with open(os.path.join(ab, name), "w", encoding="utf-8") as fh:
                    fh.write(text)
            wp = os.path.join(d, "abilities.json")
            with open(wp, "w", encoding="utf-8") as fh:
                json.dump(wiki, fh)
            return ka.build(ab, wp)[:2]  # the battlerage page: class Battlerage

    def test_a_cost_that_differs_is_listed_and_an_uncovered_skill_too(self):
        wiki = {"Alchemy": {"abilities": [{"skill": "Robes", "cooldown": "3.00 seconds of equilibrium",
                                           "target": "Self"}]}}
        js, md = self.build({"alchemy_robes_3.txt": ROBES, "attainment_obliviate_2115.txt": OBLIVIATE,
                             "conjuration_fistsigil_46.txt": FISTSIGIL}, wiki)
        data = json.loads(js)
        self.assertEqual(data["count"], 3)
        self.assertNotIn("abfile", data["abilities"][0])
        self.assertIn("| 3 | Alchemy | Robes | 2.00 seconds of equilibrium | 3.00 seconds of equilibrium | self | Self | cost |", md)
        self.assertIn("| Attainment | 1 | 2115-2115 |", md)
        self.assertNotIn("| Conjuration |", md)  # a pointer record is not compared
        self.assertIn("Differ from the wiki: 1. Not listed on the wiki page of their skill: 0.", md)

    def test_a_record_whose_extra_info_gives_the_wikis_cost(self):
        freeze = ROBES.replace("Ability: Robes (Record #3)", "Ability: Freeze (Record #710)").replace(
            "Syntax: ROBES SUMMON", "Syntax: CAST FREEZE AT GROUND/<target>\nExtra info: Targetted cooldown: "
            "3.00 seconds of equilibrium and 100 mana")
        wiki = {"Alchemy": {"abilities": [{"skill": "Freeze", "cooldown": "3.00 seconds of equilibrium", "target": ""}]}}
        _, md = self.build({"alchemy_freeze_710.txt": freeze}, wiki)
        self.assertIn("| 710 | Alchemy | Freeze | 2.00 seconds of equilibrium | 3.00 seconds of equilibrium | self | -- "
                      "| cost, but its Extra info gives the wiki's |", md)

    def test_an_empty_slot_is_counted_and_not_compared(self):
        wiki = {"Alchemy": {"abilities": [{"skill": "Symbology", "cooldown": "", "target": ""}]}}
        js, md = self.build({"unknown_unnamed_3293.txt": EMPTY, "alchemy_robes_3.txt": ROBES}, wiki)
        self.assertEqual(json.loads(js)["count"], 2)
        self.assertIn("Records: 2 (0 of them pointers to another record; 1 empty slots with no name or skill, ids 3293).", md)
        self.assertNotIn("| unknown |", md)
        self.assertIn("Not listed on the wiki page of their skill: 1.", md)

    def test_the_same_cost_is_not_listed_and_an_unlisted_ability_is(self):
        wiki = {"Alchemy": {"abilities": [{"skill": "Symbology", "cooldown": "", "target": "Adventurers and denizens."}]}}
        _, md = self.build({"alchemy_robes_3.txt": ROBES}, wiki)
        self.assertIn("Differ from the wiki: 0. Not listed on the wiki page of their skill: 1.", md)
        self.assertIn("| 3 | Alchemy | Robes | 2.00 seconds of equilibrium | self | `kb/raw/abadmin/alchemy_robes_3.txt` |", md)

    def test_the_repo_pages_are_current(self):
        js, md, br = ka.build()
        with open(ka.OUT_JSON, encoding="utf-8") as fh:
            self.assertEqual(fh.read(), js)
        with open(ka.OUT_MD, encoding="utf-8") as fh:
            self.assertEqual(fh.read(), md)
        with open(ka.OUT_BR, encoding="utf-8") as fh:
            self.assertEqual(fh.read(), br)


# Runewarden ETCH, the record as filed (kb/raw/abadmin/attainment_etch_2278.txt): it USES an affliction for more
# damage; it does not need one.
ETCH = """Ability: Etch (Record #2278)
Associated skill: Attainment
Skillpoints required: 29999
Blurb: A fiery rune will strike your opponent.
Syntax: ETCH RUNE AT <target>
Extra info: Uses denizen afflictions: Aeon or Stun
Abfile:
Draw the outline of a rune in the air with your weapon, sending the rune crashing into your opponent, doing extra damage if the target is unable to dodge the attack because of aeon or stun.
Useable on: denizens
Pre checks:
Ability range: none
Aggression type: non-aggressive
Requires arms: 0
Requires legs: 0
Useable entangled: No
Useable paralysed: No
Cooldown: 23.00 seconds
Resource: 25 rage
Skill specialisation: br_runewarden
"""


class Flags(unittest.TestCase):
    def test_the_flags_section_counts_defaults_by_pre_checks(self):
        # OBLIVIATE and ROBES have no Pre checks value; a copy of ROBES with one says Useable paralysed: Yes.
        filled = (ROBES.replace("Ability: Robes (Record #3)", "Ability: Shrugging (Record #1277)")
                  .replace("Pre checks:\n", "Pre checks: equilibrium\n")
                  .replace("Useable paralysed: No", "Useable paralysed: Yes"))
        recs = [ka.parse_record(t) for t in (OBLIVIATE, ROBES, filled, FISTSIGIL)]
        text = " ".join(" ".join(ka.render_flags(recs)).split())
        self.assertIn("Of the 3 named records that are not pointers, 1 have a `Pre checks:` line", text)
        self.assertIn("and 2 do not. Of those 2, 1 show the same flags", text)  # ROBES needs one arm
        self.assertIn("and 0 say `Useable paralysed: Yes`. Of the 1 with a value, 0 show that set and 1 say", text)


class Battlerage(unittest.TestCase):
    def page(self, files):
        with tempfile.TemporaryDirectory() as d:
            ab = os.path.join(d, "abadmin")
            os.makedirs(ab)
            for name, text in files.items():
                with open(os.path.join(ab, name), "w", encoding="utf-8") as fh:
                    fh.write(text)
            return ka.build(ab, os.path.join(d, "none.json"))[2]

    def test_gives_uses_and_rage_come_from_the_record(self):
        by = ka.battlerage([ka.parse_record(OBLIVIATE), ka.parse_record(ETCH), ka.parse_record(ROBES)])
        self.assertEqual(sorted(by), ["br_runewarden", "br_serpent"])  # Robes has no br_ line
        ob, = by["br_serpent"]
        self.assertEqual((ob["gives"], ob["uses"], ob["rage"]), ("Amnesia", "", 28))
        et, = by["br_runewarden"]
        self.assertEqual((et["gives"], et["uses"], et["rage"]), ("", "Aeon or Stun", 25))

    def test_a_class_section_sorted_by_rage(self):
        page = self.page({"attainment_etch_2278.txt": ETCH, "attainment_obliviate_2115.txt": OBLIVIATE,
                          "alchemy_robes_3.txt": ROBES})
        self.assertIn("2 records, 2 classes. 1 give a", page)
        self.assertIn("## Runewarden (`br_runewarden`)", page)
        self.assertIn("| 2278 | Etch | ETCH RUNE AT <target> | 25 | 23.00 seconds | denizens | -- | Aeon or Stun | "
                      "Draw the outline of a rune in the air with your weapon, sending the rune crashing into your "
                      "opponent, doing extra damage if the target is unable to dodge the attack because of aeon or stun. |", page)
        self.assertIn("| 2115 | Obliviate | OBLIVIATE <target> | 28 | 41.00 seconds | denizens | Amnesia | -- |", page)
        self.assertLess(page.index("## Runewarden"), page.index("## Serpent"))
        self.assertNotIn("Robes", page)


if __name__ == "__main__":
    unittest.main()
