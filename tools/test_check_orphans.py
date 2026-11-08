"""Tests for tools/check_orphans.py, check 1c: a global that NO file defines (2026-11-08).

    python -B tools/test_check_orphans.py
"""
import contextlib
import io
import os
import sys
import tempfile
import unittest
import warnings

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import check_orphans as co  # noqa: E402


def setUpModule():
    # Checks 1 to 2b read files with open().read(); unittest would print a ResourceWarning for each.
    warnings.simplefilter("ignore", ResourceWarning)


HEADER = """--[[mudlet
type: %s
name: x
attributes:
  isActive: '%s'
]]--
"""


@contextlib.contextmanager
def tree(files):
    """A throwaway src_new with these {relative path: text} files; check_orphans reads it."""
    saved = co.ROOT, co.SRC
    with tempfile.TemporaryDirectory() as root:
        for rel, text in files.items():
            path = os.path.join(root, "src_new", *rel.split("/"))
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w", encoding="utf-8", newline="\n") as fh:
                fh.write(text)
        co.ROOT, co.SRC = root, os.path.join(root, "src_new")
        try:
            yield
        finally:
            co.ROOT, co.SRC = saved


class BlankCode(unittest.TestCase):
    def test_strings_and_comments_hide_each_other_no_longer(self):
        # mnemosyne/004_Parsers.lua:1239 holds "... TAINTED (Splinterbark) ... -- on our own" in a
        # string; strip_comments() cut it at the `--` and the rest read as a call to TAINTED.
        code = co.blank_code('M.echo("a TAINTED (x) -- on our own")\n-- don\'t call(this)\nf(1)\n')
        self.assertNotIn("TAINTED", code)
        self.assertNotIn("call", code)
        self.assertIn("f(1)", code)
        self.assertEqual(code.count("\n"), 3)

    def test_long_strings_and_comments_keep_their_line_breaks(self):
        code = co.blank_code("a = [[x(\ny(]]\n--[[ z(\n]] g()\n")
        self.assertNotIn("x(", code)
        self.assertNotIn("z(", code)
        self.assertEqual(code.splitlines()[3].strip(), "g()")


class UnfoldYaml(unittest.TestCase):
    def test_a_definition_folded_across_two_rows_reads_whole(self):
        # scripts/_groups.yaml, the genRunning script: `function\` / `\ bashConsoleEcho(type, msg)`.
        raw = 'script: "x = 1\\n\\nfunction\\\n          \\ bashConsoleEcho(type, msg)\\n\\tend"\n'
        self.assertIn("function bashConsoleEcho(", co.unfold_yaml(raw))


class UndefinedGlobals(unittest.TestCase):
    FILES = {
        "scripts/_groups.yaml": 'groups:\n- name: g\n  script: "function\\\n    \\ fromYaml(a)\\nend"\n',
        "scripts/a/001_Helpers.lua": HEADER % ("script", "yes") + "function helper() end\nlate = nil\n",
        "scripts/a/002_Off.lua": HEADER % ("script", "no") + "function offOnly() end\n",
        "triggers/t/001_Line.lua": HEADER % ("trigger", "yes") + "\n".join([
            'expandALias("bp")',                       # a typo: reported
            'expandAlias("bp")',                       # Mudlet API
            'helper(); fromYaml(1); offOnly()',        # defined: by a script, a group script, a switched-off one
            'if maybe then maybe() end',               # guarded
            'send("goto(x)") -- later(y)',             # a string and a comment
            'local function mine() end mine()',        # bound by the file
            'ataxia.field()',                          # a field: check 2's business
            'goto(target)',                            # not a keyword in Lua 5.1: reported
        ]) + "\n",
        "aliases/a/001_Off.lua": HEADER % ("alias", "no") + "neverDefined()\n",
    }

    def test_reports_only_the_undefined_names_in_active_code(self):
        with tree(self.FILES):
            found = co.undefined_global_calls()
        self.assertEqual(sorted((n, ln) for _, ln, n in found), [("expandALias", 7), ("goto", 14)])
        self.assertTrue(all(f == "src_new/triggers/t/001_Line.lua" for f, _, _ in found))

    def test_report_only_leaves_the_exit_status_alone(self):
        self.assertFalse(co.STRICT_UNDEFINED_GLOBALS)
        with tree(self.FILES), contextlib.redirect_stdout(io.StringIO()) as out:
            status = co.report_undefined_globals()
        self.assertEqual(status, 0)
        self.assertIn("expandALias()", out.getvalue())
        self.assertIn("(report-only)", out.getvalue())

    def test_the_fixed_callers_are_clean_in_the_real_tree(self):
        # 2026-11-08: these active items each called a global no file defined (see test_dead_callee_lines.lua).
        names = {n for _, _, n in co.undefined_global_calls()}
        for fixed in ("sylvan_propagateAff", "bard_tremvib", "earth_powderiseHit", "priest_selftLimbHit",
                      "expandALias", "osend", "goto", "showColours", "bashConsoleEcho"):
            self.assertNotIn(fixed, names)


if __name__ == "__main__":
    unittest.main()
