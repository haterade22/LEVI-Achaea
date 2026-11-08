"""Tests for tools/convert_to_muddler.py: filenames must not collide by case (2026-11-08).

    python -B tools/test_convert_to_muddler.py
"""
import contextlib
import io
import os
import sys
import unittest
from pathlib import Path

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import convert_to_muddler as ctm  # noqa: E402


def items(*rows):
    """(name, hierarchy) rows in the shape _build_name_map reads."""
    return [(Path(f"/src/{i}.lua"), {"name": name, "hierarchy": list(hierarchy)}, "x()")
            for i, (name, hierarchy) in enumerate(rows)]


def name_map(rows):
    converter = ctm.MuddlerConverter("src", "out")
    with contextlib.redirect_stdout(io.StringIO()):
        return converter._build_name_map("aliases", rows)


class BuildNameMap(unittest.TestCase):
    def test_a_case_only_pair_gets_parent_prefixed_names(self):
        # The pair that broke: alias DARKSHADE (^dar$) took the body of the Serpent alias Darkshade.
        rows = items(("DARKSHADE", ("Levi_Ataxia", "RUNIE")), ("Darkshade", ("Levi_Ataxia", "Serpent")))
        self.assertEqual(sorted(name_map(rows).values()), ["RUNIE_DARKSHADE", "Serpent_Darkshade"])

    def test_a_case_only_pair_in_one_folder_stays_apart_on_ntfs(self):
        rows = items(("CULL", ("Root", "Trig")), ("Cull", ("Root", "Trig")))
        safe = list(name_map(rows).values())
        self.assertEqual(len({s.lower() for s in safe}), 2, safe)

    def test_three_spellings_all_lose_the_plain_name(self):
        # None keeps the name Muddler would look a file up by, so all three go inline (below).
        rows = items(("Hew", ("Root",)), ("HEW", ("Root",)), ("hew", ("Root",)))
        self.assertTrue(set(name_map(rows).values()).isdisjoint({"Hew", "HEW", "hew"}))

    def test_names_that_differ_only_after_sanitising_stay_apart(self):
        # The counter guard is case-blind too: "A b" and "a_b" are different names but one file.
        rows = items(("A b", ("Root",)), ("a_b", ("Root",)))
        safe = list(name_map(rows).values())
        self.assertEqual(len({s.lower() for s in safe}), 2, safe)

    def test_a_name_with_no_twin_keeps_its_plain_filename(self):
        rows = items(("Smoked", ("Root", "Groups")), ("Rebounding", ("Root", "Groups")))
        self.assertEqual(sorted(name_map(rows).values()), ["Rebounding", "Smoked"])


class ExtractLuaFiles(unittest.TestCase):
    def extract(self, nodes):
        converter = ctm.MuddlerConverter("src", "out")
        lua_files = {}
        return converter._extract_lua_files(nodes, lua_files), lua_files

    def test_a_prefixed_item_is_inlined_with_its_own_body(self):
        # Muddler finds a script file by the item's own name, so a prefixed name has to go inline.
        safe = sorted(name_map(items(("DARKSHADE", ("L", "RUNIE")), ("Darkshade", ("L", "Serpent")))).values())
        nodes = [
            {"name": "DARKSHADE", "_safe_name": safe[0], "_lua_code": "infernal()"},
            {"name": "Darkshade", "_safe_name": safe[1], "_lua_code": "serpent()"},
        ]
        clean, lua_files = self.extract(nodes)
        self.assertEqual([n["script"] for n in clean], ["infernal()", "serpent()"])
        self.assertEqual(lua_files, {})

    def test_a_plain_item_still_gets_its_own_file(self):
        clean, lua_files = self.extract([{"name": "Smoked", "_safe_name": "Smoked", "_lua_code": "smoke()"}])
        self.assertNotIn("script", clean[0])
        self.assertEqual(lua_files, {"Smoked": "smoke()"})


if __name__ == "__main__":
    unittest.main()
