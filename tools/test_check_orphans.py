"""Tests for tools/check_orphans.py, check 1c: a global that NO file defines (2026-11-08).

    python -B tools/test_check_orphans.py
"""
import contextlib
import io
import os
import re
import sys
import tempfile
import unittest
import warnings
from unittest import mock

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
        with mock.patch.object(co, "STRICT_UNDEFINED_GLOBALS", False), tree(self.FILES), \
                contextlib.redirect_stdout(io.StringIO()) as out:
            status = co.report_undefined_globals()
        self.assertEqual(status, 0)
        self.assertIn("expandALias()", out.getvalue())
        self.assertIn("(report-only)", out.getvalue())

    def test_strict_fails_ci_on_a_finding_and_passes_a_clean_tree(self):
        self.assertTrue(co.STRICT_UNDEFINED_GLOBALS)
        with tree(self.FILES), contextlib.redirect_stdout(io.StringIO()) as out:
            status = co.report_undefined_globals()
        self.assertEqual(status, 1)
        self.assertNotIn("(report-only)", out.getvalue())
        with tree({"triggers/t/001_Line.lua": HEADER % ("trigger", "yes") + 'send("x")\n'}), \
                contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(co.report_undefined_globals(), 0)

    def test_the_fixed_callers_are_clean_in_the_real_tree(self):
        # 2026-11-08: these active items each called a global no file defined (see test_dead_callee_lines.lua).
        names = {n for _, _, n in co.undefined_global_calls()}
        for fixed in ("sylvan_propagateAff", "bard_tremvib", "earth_powderiseHit", "priest_selftLimbHit",
                      "expandALias", "osend", "goto", "showColours", "bashConsoleEcho", "limbCounter_promptAddon",
                      "OppGainedAff", "addToCommand", "apostate_viviprio", "infernalpriosprep", "infernalpriosbasic",
                      "infernalpriosdamage", "infernalpriosimpale", "infernalpriosblackout", "infernalpriosdarkshade",
                      "infernalpriostrample", "infernalpriosweariness", "rightside", "leftside", "noDisplay",
                      "svo_init_system", "bardlimbattack"):
            self.assertNotIn(fixed, names)

    def test_the_real_tree_is_clean(self):
        self.assertEqual(co.undefined_global_calls(), [])

    def test_a_never_run_row_covers_its_own_names_only(self):
        # Keyed by file and name: a new undefined call in a listed file is still reported.
        files = {"aliases/a/001_Off.lua": HEADER % ("alias", "yes") + "goneOld()\ngoneNew()\n"}
        with mock.patch.object(co, "NEVER_RUN", {"src_new/aliases/a/001_Off.lua": ("goneOld",)}), tree(files):
            found = co.undefined_global_calls()
        self.assertEqual([n for _, _, n in found], ["goneNew"])


class EmptyWalk(unittest.TestCase):
    """A walk that finds no file is NOT RUN (exit 2), never "OK": every check would pass over nothing."""

    def run_main(self, files):
        with tree(files), contextlib.redirect_stdout(io.StringIO()) as out:
            return co.main(), out.getvalue()

    def test_an_empty_tree_is_not_run(self):
        status, said = self.run_main({})
        self.assertEqual(status, 2)
        self.assertIn("NOT RUN", said)
        self.assertNotIn("OK", said)

    def test_scripts_with_no_caller_files_is_not_run(self):
        status, said = self.run_main({"scripts/a/001_Helpers.lua": HEADER % ("script", "yes") + "function helper() end\n"})
        self.assertEqual(status, 2)
        self.assertIn("0 trigger/alias/timer/key file(s)", said)

    def test_a_small_clean_tree_still_passes(self):
        status, said = self.run_main({
            "scripts/a/001_Helpers.lua": HEADER % ("script", "yes") + "function helper() end\n",
            "triggers/t/001_Line.lua": HEADER % ("trigger", "yes") + "helper()\n",
        })
        self.assertEqual(status, 0)
        self.assertNotIn("NOT RUN", said)

    def test_the_real_tree_is_checked(self):
        self.assertIsNone(co.unchecked())


class NeverRun(unittest.TestCase):
    """Every NEVER_RUN row must stay true: the alias sits in a switched-off group folder, and the call is there."""

    @staticmethod
    def off_groups():
        """The group paths whose own flag is off in aliases/_groups.yaml. Read by indentation: this file's shape is
        `- name: X` at some depth with `isActive: false` two columns in, and CI runs this before pyyaml is installed."""
        with open(os.path.join(co.SRC, "aliases", "_groups.yaml"), encoding="utf-8") as fh:
            lines = fh.read().splitlines()
        stack, off = [], set()
        for line in lines:
            named = re.match(r"(\s*)- name: (.+?)\s*$", line)
            if named:
                depth = len(named.group(1))
                while stack and stack[-1][0] >= depth:
                    stack.pop()
                stack.append((depth, named.group(2).strip("'\"")))
                continue
            flag = re.match(r"(\s*)isActive: false\s*$", line)
            if flag and stack and len(flag.group(1)) == stack[-1][0] + 2:
                off.add(tuple(name for _, name in stack))
        return off

    def test_the_folders_read_as_expected(self):
        off = self.off_groups()
        self.assertIn(("Levi_Ataxia", "Classes", "Monk", "TEKURA"), off)
        self.assertIn(("Levi_Ataxia", "Classes", "Knight", "Infernal", "SNB"), off)
        self.assertNotIn(("Levi_Ataxia", "Classes", "Knight", "RUNIE", "SNB"), off)

    def test_every_row_sits_in_a_switched_off_folder(self):
        off = self.off_groups()
        self.assertTrue(co.NEVER_RUN)
        for caller in co.NEVER_RUN:
            text = co.read_text(os.path.join(co.ROOT, *caller.split("/")))
            hierarchy = re.search(r"^hierarchy:\n((?:- .*\n)+)", co.HEADER_RE.search(text).group(1), re.M)
            chain = tuple(row[2:].strip() for row in hierarchy.group(1).splitlines())
            self.assertTrue(any(chain[:i] in off for i in range(1, len(chain) + 1)), (caller, chain))

    def test_nothing_enables_those_folders_at_runtime(self):
        # enableAlias on a folder name would make these rows false; today only the mapper uses it.
        called = set()
        for path in co.walk("scripts", "triggers", "aliases", "timers", "keys"):
            called.update(re.findall(r"enableAlias\(\s*[\"']([^\"']+)", co.read_text(path)))
        self.assertEqual(called, {"mm Mapping"})

    def test_every_row_is_still_a_call_the_scan_finds(self):
        with mock.patch.object(co, "NEVER_RUN", {}):
            raw = {(caller, name) for caller, _, name in co.undefined_global_calls()}
        for caller, names in co.NEVER_RUN.items():
            for name in names:
                self.assertIn((caller, name), raw)


if __name__ == "__main__":
    unittest.main()
