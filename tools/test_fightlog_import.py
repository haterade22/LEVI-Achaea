"""Tests for tools/fightlog_import.py. The Lua suite cannot reach this Python reader.

    python -B tools/test_fightlog_import.py
"""
import importlib.util
import os
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("fightlog_import", os.path.join(HERE, "fightlog_import.py"))
fightlog_import = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fightlog_import)
commands = fightlog_import.commands


class Commands(unittest.TestCase):
    def test_a_raw_chain_counts_each_command(self):
        self.assertEqual(commands("queue addclear free stand;combo Sadey a"), ["stand", "combo"])

    def test_a_plain_line_counts_itself(self):
        self.assertEqual(commands("touch shield"), ["touch"])

    def test_an_alias_rewrite_counts_the_commands_in_its_text(self):
        self.assertEqual(commands("setalias lvfree stand/g body/combo Sadey a"), ["stand", "g", "combo"])

    def test_the_queue_line_that_names_the_alias_counts_nothing(self):
        self.assertEqual(commands("queue addclear free lvfree"), [])
        self.assertEqual(commands("queue addclearfull freestand LVFREESTAND"), [])

    def test_a_test_alias_is_not_a_round(self):
        self.assertEqual(commands("setalias lvprobe say one/say two"), ["setalias"])
        self.assertEqual(commands("queue addclear free lvprobe"), ["lvprobe"])


if __name__ == "__main__":
    unittest.main()
