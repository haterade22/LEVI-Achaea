"""Tests for tools/ci_local.py and tools/ci_steps.json.

    python -B tools/test_ci_local.py

Three jobs. (1) The step table equals the validate job of build.yml, matched by TOOL FILE and flags,
never by a step's display name. (2) Every test, check and --check tool under tools/ is a row or has a
written reason in not_in_ci. (3) The runner's verdicts: a step that cannot run is NOT RUN, never PASS.
Needs lupa (Lua 5.1) and pyyaml; without them the affected tests FAIL, they do not skip.
"""
import contextlib
import glob
import io
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ci_local as ci  # noqa: E402

ROOT = ci.ROOT
TABLE = ci.load_table()
STEPS = TABLE["steps"]
WORKFLOW = os.path.join(ROOT, ".github", "workflows", "build.yml")
TOOL_RE = re.compile(r"\bpython3?(?:[ \t]+-B)?[ \t]+tools/([\w.]+\.py)((?:[ \t]+--[\w-]+)*)")
CHECK_FLAG_RE = re.compile(r"add_argument\(\s*[\"']--check[\"']")


def validate_job():
    """The text of the validate job only: the build job runs the converter for real, which is not a check."""
    with open(WORKFLOW, encoding="utf-8") as fh:
        text = fh.read()
    return text[text.index("\n  validate:"):text.index("\n  build:")]


def ci_tools():
    return {("tools/" + name, tuple(flags.split())) for name, flags in TOOL_RE.findall(validate_job())}


def row_tool(step):
    return step["argv"][0], tuple(step["argv"][1:])


def fake(code):
    return {"id": "fake%d" % code, "what": "", "argv": ["-c", "import sys; print('said'); sys.exit(%d)" % code]}


def silent(*_):
    pass


class Table(unittest.TestCase):
    def test_every_row_is_well_formed(self):
        ids = [step["id"] for step in STEPS]
        self.assertEqual(len(ids), len(set(ids)), "a step id repeats")
        for step in STEPS:
            self.assertTrue(step.get("what"), step["id"])
            self.assertEqual(("argv" in step) + ("builtin" in step), 1, step["id"])
            if "builtin" in step:
                self.assertIn(step["builtin"], ci.BUILTINS)
                self.assertTrue(step.get("ci_marker"), "a built-in step names the text build.yml runs it by")
            else:
                self.assertTrue(os.path.isfile(os.path.join(ROOT, step["argv"][0])), step["argv"][0])
            for need in step.get("needs", []):
                self.assertIn(need, ("lupa", "yaml"))

    def test_the_quick_steps_are_a_real_subset(self):
        quick = [step["id"] for step in STEPS if step.get("quick")]
        self.assertTrue(0 < len(quick) < len(STEPS))


class Parity(unittest.TestCase):
    """build.yml and the table name the same tools. A mismatch is how /verify fell three steps behind CI."""

    def test_build_yml_was_read(self):
        # Zero steps parsed would make the comparison below vacuous in one direction.
        self.assertGreaterEqual(len(ci_tools()), 15, "the regex no longer reads the validate job")

    def test_every_ci_tool_step_is_a_row_and_every_row_is_in_ci(self):
        rows = {row_tool(step) for step in STEPS if "argv" in step and "ci_marker" not in step}
        in_ci = ci_tools()
        self.assertEqual(sorted(in_ci - rows), [], "build.yml runs these, tools/ci_steps.json has no row")
        self.assertEqual(sorted(rows - in_ci), [], "tools/ci_steps.json has these rows, build.yml does not run them")

    def test_a_step_ci_runs_in_another_form_is_still_in_build_yml(self):
        job = validate_job()
        marked = [step for step in STEPS if "ci_marker" in step]
        self.assertTrue(marked)
        for step in marked:
            self.assertIn(step["ci_marker"], job, step["id"])


class Inventory(unittest.TestCase):
    """A check that nothing runs prevents nothing: each one is a row, or says why it is not."""

    def candidates(self):
        found = set(glob.glob(os.path.join(ROOT, "tools", "test_*.py"))) | set(glob.glob(os.path.join(ROOT, "tools", "check_*.py")))
        checkers = set()
        for path in glob.glob(os.path.join(ROOT, "tools", "*.py")):
            with open(path, encoding="utf-8") as fh:
                if CHECK_FLAG_RE.search(fh.read()):
                    checkers.add(path)
        rel = lambda path: os.path.relpath(path, ROOT).replace(os.sep, "/")  # noqa: E731
        return {rel(p) for p in found}, {rel(p) for p in checkers}

    def test_the_scan_found_the_tools(self):
        plain, checkers = self.candidates()
        self.assertIn("tools/test_ci_local.py", plain)
        self.assertIn("tools/check_orphans.py", plain)
        self.assertIn("tools/kb_sim.py", checkers)

    def test_every_test_and_check_is_a_row_or_has_a_reason(self):
        plain, checkers = self.candidates()
        rows = {step["argv"][0] for step in STEPS if "argv" in step}
        with_check = {step["argv"][0] for step in STEPS if "argv" in step and "--check" in step["argv"]}
        excused = TABLE["not_in_ci"]
        for path in sorted(plain):
            self.assertTrue(path in rows or path in excused, "%s is not a step and has no not_in_ci reason" % path)
        for path in sorted(checkers):
            self.assertTrue(path in with_check or path in excused, "%s has --check, but no step runs it" % path)

    def test_no_reason_is_stale_or_empty(self):
        rows = {step["argv"][0] for step in STEPS if "argv" in step}
        for path, why in TABLE["not_in_ci"].items():
            self.assertTrue(os.path.isfile(os.path.join(ROOT, path)), "%s is gone: remove its not_in_ci row" % path)
            self.assertNotIn(path, rows, "%s is a step now: remove its not_in_ci row" % path)
            self.assertGreater(len(why), 30, path)


class Verdicts(unittest.TestCase):
    def test_exit_codes_map_to_three_verdicts(self):
        self.assertEqual(ci.run_step(fake(0))[0], ci.PASS)
        self.assertEqual(ci.run_step(fake(1))[0], ci.FAIL)
        self.assertEqual(ci.run_step(fake(2))[0], ci.NOT_RUN)
        self.assertEqual(ci.run_step(fake(3))[0], ci.FAIL)

    def test_the_output_of_a_step_is_kept(self):
        verdict, line, output = ci.run_step(fake(1))
        self.assertIn("said", output)
        self.assertIn("exit 1", line)

    def test_a_missing_module_is_not_run_and_the_step_never_starts(self):
        step = dict(fake(0), needs=["lupa"])
        verdict, line, _ = ci.run_step(step, importable=lambda name: False)
        self.assertEqual(verdict, ci.NOT_RUN)
        self.assertIn("lupa", line)

    def test_a_builtin_that_raises_is_a_fail_of_that_step(self):
        with tempfile.TemporaryDirectory() as empty:
            verdict, line, _ = ci.run_step({"id": "version", "what": "", "builtin": "version"}, root=empty)
        self.assertEqual(verdict, ci.FAIL)

    def test_a_program_that_cannot_start_is_not_run(self):
        verdict, _, _ = ci.run_step(fake(0), python=os.path.join(ROOT, "no-such-python"))
        self.assertEqual(verdict, ci.NOT_RUN)

    def test_a_failure_does_not_stop_the_run(self):
        results = ci.run_all([(fake(1), None), (fake(0), None)], out=silent)
        self.assertEqual([verdict for _, verdict, _, _ in results], [ci.FAIL, ci.PASS])

    def test_exit_status(self):
        def results(*verdicts, left_out=()):
            return [({"id": str(i)}, v, "", i in left_out) for i, v in enumerate(verdicts)]
        self.assertEqual(ci.exit_status(results(ci.PASS, ci.PASS)), 0)
        self.assertEqual(ci.exit_status(results(ci.PASS, ci.NOT_RUN)), 2)
        self.assertEqual(ci.exit_status(results(ci.NOT_RUN, ci.FAIL, ci.PASS)), 1)
        self.assertEqual(ci.exit_status(results(ci.PASS, ci.NOT_RUN, left_out={1})), 0, "a left-out step is not a fault")
        self.assertEqual(ci.exit_status(results(ci.NOT_RUN, left_out={0})), 2, "nothing ran")
        self.assertEqual(ci.exit_status([]), 2, "nothing ran")

    def test_only_a_full_clean_run_is_ready_to_push(self):
        full = ci.run_all(ci.select([fake(0), fake(0)]), out=silent)
        self.assertTrue(ci.ready(full))
        self.assertFalse(ci.ready(ci.run_all(ci.select([fake(0), fake(2)]), out=silent)))
        self.assertFalse(ci.ready(ci.run_all(ci.select([fake(0), fake(1)]), out=silent)))
        quick = ci.run_all(ci.select([dict(fake(0), quick=True), fake(0)], quick=True), out=silent)
        self.assertEqual(ci.exit_status(quick), 0)
        self.assertFalse(ci.ready(quick), "a quick run leaves steps out")
        self.assertFalse(ci.ready([]))

    def test_select(self):
        steps = [dict(fake(0), id="a", quick=True), dict(fake(0), id="b")]
        self.assertEqual([why for _, why in ci.select(steps)], [None, None])
        self.assertEqual([bool(why) for _, why in ci.select(steps, quick=True)], [False, True])
        self.assertEqual([bool(why) for _, why in ci.select(steps, only={"b"})], [True, False])

    def test_an_unknown_step_name_is_refused(self):
        with contextlib.redirect_stdout(io.StringIO()) as out:
            status = ci.main(["--only", "no-such-step"])
        self.assertEqual(status, 2)
        self.assertIn("no step named", out.getvalue())

    def test_list_names_every_step(self):
        with contextlib.redirect_stdout(io.StringIO()) as out:
            self.assertEqual(ci.main(["--list"]), 0)
        for step in STEPS:
            self.assertIn(step["id"], out.getvalue())


def write(root, rel, text):
    path = os.path.join(root, *rel.split("/"))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)


class Builtins(unittest.TestCase):
    def version_tree(self, root, txt="1.2.3", mfile="1.2.3", yaml_v="1.2.3", heading="## 2026-01-01 - v1.2.3: a title"):
        write(root, "version.txt", txt + "\n")
        write(root, "muddler_project/mfile", '{"version": "%s"}' % mfile)
        write(root, "src_new/scripts/_groups.yaml", 'script: "ataxiaVersion = \\"%s\\"\\t--x"\n' % yaml_v)
        write(root, "CHANGELOG.md", "# Changelog\n\n%s\n\n- text\n" % heading)

    def test_version(self):
        with tempfile.TemporaryDirectory() as root:
            self.version_tree(root)
            self.assertEqual(ci.version(root)[0], ci.PASS)
            self.version_tree(root, mfile="1.2.2")
            self.assertEqual(ci.version(root)[0], ci.FAIL)
            self.version_tree(root, yaml_v="1.2.4")
            self.assertEqual(ci.version(root)[0], ci.FAIL)
            self.version_tree(root, heading="## 2026-01-01 - v1.2.2: the release before")
            verdict, line = ci.version(root)
            self.assertEqual(verdict, ci.FAIL)
            self.assertIn("CHANGELOG.md has no heading", line)
            self.version_tree(root, heading="## 2026-01-01 - v1.2.30: a longer number is another version")
            self.assertEqual(ci.version(root)[0], ci.FAIL)

    def test_the_real_tree_has_one_version_and_its_heading(self):
        verdict, line = ci.version(ROOT)
        self.assertEqual(verdict, ci.PASS, line)

    def test_lua_syntax(self):
        self.assertTrue(ci.can_import("lupa"), "lupa with Lua 5.1 is missing for %s" % sys.executable)
        with tempfile.TemporaryDirectory() as root:
            self.assertEqual(ci.lua_syntax(root)[0], ci.NOT_RUN, "no file is not a pass")
            write(root, "src_new/a/001_Good.lua", "--[[mudlet\ntype: script\n]]--\nlocal x = 1\nreturn x\n")
            self.assertEqual(ci.lua_syntax(root), (ci.PASS, "1 files"))
            write(root, "src_new/a/002_Bad.lua", "local x = = 1\n")
            verdict, line = ci.lua_syntax(root)
            self.assertEqual(verdict, ci.FAIL)
            self.assertIn("src_new/a/002_Bad.lua:1", line)
            # goto is a keyword from Lua 5.2 on; in 5.1 it is a plain name. This proves which Lua compiled it.
            write(root, "src_new/a/002_Bad.lua", "local goto = 1\nreturn goto\n")
            self.assertEqual(ci.lua_syntax(root)[0], ci.PASS)

    def test_yaml(self):
        self.assertTrue(ci.can_import("yaml"), "pyyaml is missing for %s" % sys.executable)
        with tempfile.TemporaryDirectory() as root:
            self.assertEqual(ci.yaml_files(root)[0], ci.NOT_RUN, "no file is not a pass")
            write(root, "src_new/scripts/_groups.yaml", "groups:\n- name: a\n")
            self.assertEqual(ci.yaml_files(root)[0], ci.PASS)
            write(root, "src_new/triggers/_groups.yaml", "groups:\n- name: [unclosed\n")
            self.assertEqual(ci.yaml_files(root)[0], ci.FAIL)


class Header(unittest.TestCase):
    def test_version_key(self):
        self.assertEqual(ci.version_key("v4.7.500"), (4, 7, 500))
        self.assertEqual(ci.version_key("4.7.99\n"), (4, 7, 99))
        self.assertLess(ci.version_key("4.7.99"), ci.version_key("4.7.100"))
        self.assertIsNone(ci.version_key("dmap-v1.0"))
        self.assertIsNone(ci.version_key(""))

    def test_top_tag_reads_ls_remote(self):
        text = "\n".join(["aaa\trefs/tags/v4.7.99", "bbb\trefs/tags/v4.7.500", "ccc\trefs/tags/v4.7.500^{}",
                          "ddd\trefs/tags/dmap-v9.9.9", "eee\trefs/tags/v4.7.100"])
        self.assertEqual(ci.top_tag(text), "v4.7.500")
        self.assertIsNone(ci.top_tag(""))
        self.assertIsNone(ci.top_tag(None))

    def test_version_notes(self):
        self.assertEqual(ci.version_notes("4.7.500", "v4.7.500", "4.7.500"), [])
        self.assertEqual(ci.version_notes("4.7.500", None, None), [], "an unread remote is not a warning")
        self.assertEqual(len(ci.version_notes("4.7.499", "v4.7.500", "4.7.500")), 2)
        self.assertIn("tag v4.7.500", ci.version_notes("4.7.499", "v4.7.500", None)[0])
        self.assertEqual(len(ci.version_notes("", "v1.0", None)), 1)


class LuaRunner(unittest.TestCase):
    """src_new/tests/test_runner.lua: zero test files is exit 2, never "All tests passed!" (2026-11-13)."""

    GOOD = 'describe("x", function() it("holds", function() expect(1).toBe(1) end) end)\n'
    BAD = 'describe("x", function() it("breaks", function() expect(1).toBe(2) end) end)\n'

    def run_in(self, files):
        self.assertTrue(ci.can_import("lupa"), "lupa with Lua 5.1 is missing for %s" % sys.executable)
        with tempfile.TemporaryDirectory() as root:
            tests = os.path.join(root, "src_new", "tests")
            os.makedirs(tests)
            for name in ("test_runner.lua", "mock_mudlet.lua"):   # the runner requires the mock before it lists files
                shutil.copy(os.path.join(ROOT, "src_new", "tests", name), tests)
            for name, text in files.items():
                write(root, "src_new/tests/" + name, text)
            code = "import lupa.lua51 as l; l.LuaRuntime().execute('dofile(\"src_new/tests/test_runner.lua\")')"
            done = subprocess.run([sys.executable, "-B", "-c", code], cwd=root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                  encoding="utf-8", errors="replace")
        return done.returncode, done.stdout

    def test_zero_test_files_is_not_run(self):
        status, said = self.run_in({})
        self.assertEqual(status, 2, said)
        self.assertIn("NO TESTS FOUND", said)
        self.assertNotIn("All tests passed", said)

    def test_one_passing_file_passes(self):
        status, said = self.run_in({"test_one.lua": self.GOOD})
        self.assertEqual(status, 0, said)
        self.assertIn("All tests passed!", said)
        self.assertIn("Passed: 1  Failed: 0", said)

    def test_one_failing_file_fails(self):
        status, said = self.run_in({"test_one.lua": self.GOOD, "test_two.lua": self.BAD})
        self.assertEqual(status, 1, said)
        self.assertNotIn("All tests passed", said)


if __name__ == "__main__":
    unittest.main(verbosity=1)
