"""Tests for tools/ci_local.py, tools/ci_steps.json and tools/run_lua_tests.py.

    python -B tools/test_ci_local.py

Three jobs. (1) Every step of build.yml's validate job is accounted for: a tool step is a row of the
table (matched by TOOL FILE and flags, never by a step's display name), an inline step holds a row's
marker text, or it is one of the two install steps. (2) Every test, check and --check tool under
tools/ is a row or has a written reason in not_in_ci. (3) The runner's verdicts: a step that cannot
run is NOT RUN, never PASS. Needs lupa (Lua 5.1) and pyyaml; without them the affected tests FAIL,
they do not skip.
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
from unittest import mock

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ci_local as ci  # noqa: E402

ROOT = ci.ROOT
TABLE = ci.load_table()
STEPS = TABLE["steps"]
WORKFLOW = os.path.join(ROOT, ".github", "workflows", "build.yml")
TOOL_RE = re.compile(r"python3?(?:[ \t]+-B)?[ \t]+tools/([\w.]+\.py)((?:[ \t]+--[\w-]+)*)")
CHECK_LITERAL_RE = re.compile(r"[\"']--check[\"']")
INSTALLS = ("apt-get install -y lua5.1", "pip install lupa")   # run text of a step that only installs


def markers(step):
    found = step.get("ci_marker", [])
    return [found] if isinstance(found, str) else list(found)


def validate_steps():
    """The steps of the validate job, parsed as YAML: a commented-out step is not a step."""
    import yaml
    with open(WORKFLOW, encoding="utf-8") as fh:
        return yaml.safe_load(fh)["jobs"]["validate"]["steps"]


def classify(step):
    """('uses', None), ('tool', (file, flags)), ('marker', row id), ('install', None) or ('unknown', run text)."""
    run = step.get("run")
    if run is None:
        return "uses", None
    rows = [row.strip() for row in run.splitlines() if row.strip() and not row.strip().startswith("#")]
    if len(rows) == 1:
        tool = TOOL_RE.fullmatch(rows[0])
        if tool:
            return "tool", ("tools/" + tool.group(1), tuple(tool.group(2).split()))
    for row in STEPS:
        if markers(row) and all(text in run for text in markers(row)):
            return "marker", row["id"]
    if any(text in run for text in INSTALLS):
        return "install", None
    return "unknown", run


def row_tool(step):
    return step["argv"][0], tuple(step["argv"][1:])


def fake(code, **more):
    return dict({"id": "fake%d" % code, "what": "", "argv": ["-c", "import sys; print('said'); sys.exit(%d)" % code]}, **more)


def silent(*_):
    pass


def write(root, rel, text, binary=False):
    path = os.path.join(root, *rel.split("/"))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if binary:
        with open(path, "wb") as fh:
            fh.write(text)
    else:
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(text)


class Table(unittest.TestCase):
    def test_every_row_is_well_formed(self):
        ids = [step["id"] for step in STEPS]
        self.assertEqual(len(ids), len(set(ids)), "a step id repeats")
        for step in STEPS:
            self.assertTrue(step.get("what"), step["id"])
            self.assertEqual(("argv" in step) + ("builtin" in step), 1, step["id"])
            if "builtin" in step:
                self.assertIn(step["builtin"], ci.BUILTINS)
                self.assertTrue(markers(step), "a built-in step names the command text build.yml runs it by")
            else:
                self.assertTrue(os.path.isfile(os.path.join(ROOT, step["argv"][0])), step["argv"][0])
            for need in step.get("needs", []):
                self.assertIn(need, ("lupa", "yaml"))

    def test_the_quick_steps_are_a_real_subset(self):
        quick = [step["id"] for step in STEPS if step.get("quick")]
        self.assertTrue(0 < len(quick) < len(STEPS))


class Parity(unittest.TestCase):
    """build.yml and the table name the same checks. A hand-kept copy of the list fell three steps behind CI."""

    def kinds(self):
        return [(classify(step), step) for step in validate_steps()]

    def test_build_yml_was_read(self):
        tools = [what for (kind, what), _ in self.kinds() if kind == "tool"]
        self.assertGreaterEqual(len(tools), 15, "the validate job no longer parses into tool steps")

    def test_every_step_of_the_validate_job_is_accounted_for(self):
        # A new inline step (a shell check, a tool run in another form) must get a row, or it has no local counterpart.
        for (kind, what), step in self.kinds():
            self.assertNotEqual(kind, "unknown", "build.yml step %r is not a tool row, holds no row's ci_marker, and is "
                                "not an install step. Add a row to tools/ci_steps.json." % step.get("name"))

    def test_every_ci_tool_step_is_a_row_and_every_row_is_in_ci(self):
        rows = {row_tool(step) for step in STEPS if "argv" in step and not markers(step)}
        in_ci = {what for (kind, what), _ in self.kinds() if kind == "tool"}
        self.assertEqual(sorted(in_ci - rows), [], "build.yml runs these, tools/ci_steps.json has no row")
        self.assertEqual(sorted(rows - in_ci), [], "tools/ci_steps.json has these rows, build.yml does not run them")

    def test_a_step_ci_runs_in_another_form_is_one_step_of_build_yml(self):
        seen = [what for (kind, what), _ in self.kinds() if kind == "marker"]
        marked = [step["id"] for step in STEPS if markers(step)]
        self.assertTrue(marked)
        self.assertEqual(sorted(seen), sorted(marked), "each row with a ci_marker matches exactly one build.yml step")

    def test_no_checked_step_is_switched_off(self):
        for (kind, what), step in self.kinds():
            if kind in ("tool", "marker"):
                self.assertNotIn("if", step, step.get("name"))
                self.assertNotIn("continue-on-error", step, step.get("name"))

    def test_classify_refuses_the_forms_that_hide_a_failure(self):
        self.assertEqual(classify({"run": "python3 -B tools/check_wrap.py"})[0], "tool")
        self.assertEqual(classify({"run": "python3 -B tools/kb_sim.py --check"}), ("tool", ("tools/kb_sim.py", ("--check",))))
        self.assertEqual(classify({"run": "python3 -B tools/check_wrap.py || true"})[0], "unknown")
        self.assertEqual(classify({"run": "# python3 -B tools/check_wrap.py\necho skipped"})[0], "unknown")
        self.assertEqual(classify({"run": "python3 tools/check_wrap.py src_new/triggers"})[0], "unknown")
        self.assertEqual(classify({"run": "cd tools && python3 -B check_wrap.py"})[0], "unknown")
        self.assertEqual(classify({"uses": "actions/checkout@v4"})[0], "uses")

    def test_the_changelog_heading_check_escapes_the_dots(self):
        # ${V_TXT//./\.} inside double quotes loses its backslash in bash; a bracket class does not.
        with open(WORKFLOW, encoding="utf-8") as fh:
            text = fh.read()
        self.assertIn("v${V_TXT//./[.]}[: ]", text)


class Inventory(unittest.TestCase):
    """A check that nothing runs prevents nothing: each one is a row, or says why it is not."""

    def candidates(self):
        rel = lambda path: os.path.relpath(path, ROOT).replace(os.sep, "/")  # noqa: E731
        plain = set(glob.glob(os.path.join(glob.escape(ROOT), "tools", "test_*.py")))
        plain |= set(glob.glob(os.path.join(glob.escape(ROOT), "tools", "check_*.py")))
        checkers = set()
        for path in glob.glob(os.path.join(glob.escape(ROOT), "tools", "*.py")):
            if os.path.basename(path).startswith("test_"):
                continue   # a test passes "--check" TO a tool; it does not have the mode
            with open(path, encoding="utf-8") as fh:
                if CHECK_LITERAL_RE.search(fh.read()):
                    checkers.add(path)
        return {rel(p) for p in plain}, {rel(p) for p in checkers}

    def test_the_scan_found_the_tools(self):
        plain, checkers = self.candidates()
        self.assertIn("tools/test_ci_local.py", plain)
        self.assertIn("tools/check_orphans.py", plain)
        self.assertIn("tools/kb_sim.py", checkers)
        self.assertIn("tools/kb_log_import.py", checkers)

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
        verdict, line, _ = ci.run_step(fake(0, needs=["lupa"]), importable=lambda name: False)
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

    def test_only_a_full_clean_run_is_ready(self):
        self.assertTrue(ci.ready(ci.run_all(ci.select([fake(0), fake(0)]), out=silent)))
        self.assertFalse(ci.ready(ci.run_all(ci.select([fake(0), fake(2)]), out=silent)))
        self.assertFalse(ci.ready(ci.run_all(ci.select([fake(0), fake(1)]), out=silent)))
        quick = ci.run_all(ci.select([fake(0, quick=True), fake(0)], quick=True), out=silent)
        self.assertEqual(ci.exit_status(quick), 0)
        self.assertFalse(ci.ready(quick), "a quick run leaves steps out")
        self.assertFalse(ci.ready([]))

    def test_select(self):
        steps = [fake(0, id="a", quick=True), fake(0, id="b")]
        self.assertEqual([why for _, why in ci.select(steps)], [None, None])
        self.assertEqual([bool(why) for _, why in ci.select(steps, quick=True)], [False, True])
        self.assertEqual([bool(why) for _, why in ci.select(steps, only={"b"})], [True, False])


class Main(unittest.TestCase):
    """What a person and an `&&` chain see: the exit status and the "Ready to push" row of a whole run."""

    def run_main(self, steps, flags=(), dirty=()):
        state = None if dirty is None else list(dirty)
        with mock.patch.object(ci, "load_table", lambda: {"steps": steps, "not_in_ci": {}}), \
                mock.patch.object(ci, "tree_state", lambda root: state), \
                contextlib.redirect_stdout(io.StringIO()) as out:
            status = ci.main(["--no-remote"] + list(flags))
        said = out.getvalue()
        return status, [row for row in said.splitlines() if row.startswith("Ready to push")], said

    def test_a_full_clean_run_on_a_clean_tree_is_ready(self):
        status, verdict, _ = self.run_main([fake(0, id="a"), fake(0, id="b")])
        self.assertEqual(status, 0)
        self.assertEqual(verdict, ["Ready to push: YES"])

    def test_a_failure_is_exit_1_and_not_ready(self):
        status, verdict, said = self.run_main([fake(0, id="a"), fake(1, id="b")])
        self.assertEqual(status, 1)
        self.assertEqual(verdict, ["Ready to push: NO (a step failed)"])
        self.assertIn("1 PASS, 1 FAIL, 0 NOT RUN", said)

    def test_a_step_that_could_not_run_is_exit_2_and_not_ready(self):
        status, verdict, _ = self.run_main([fake(0, id="a"), fake(2, id="b")])
        self.assertEqual(status, 2)
        self.assertEqual(verdict, ["Ready to push: NO (a step could not run)"])

    def test_uncommitted_or_untracked_files_are_not_yet_ready(self):
        # The run reads the files on disk; the push carries the commit. A new file left untracked passed here and failed on main.
        status, verdict, said = self.run_main([fake(0, id="a")], dirty=[" M src_new/x.lua", "?? tools/test_new.py"])
        self.assertEqual(status, 0, "the steps passed: a chain that commits next must go on")
        self.assertEqual(len(verdict), 1)
        self.assertTrue(verdict[0].startswith("Ready to push: NOT YET"), verdict)
        self.assertIn("2 differ from HEAD", verdict[0])
        self.assertIn("?? tools/test_new.py", said)

    def test_an_unreadable_git_state_is_not_ready(self):
        status, verdict, _ = self.run_main([fake(0, id="a")], dirty=None)
        self.assertEqual(status, 0)
        self.assertTrue(verdict[0].startswith("Ready to push: NO (every step passed, but git"), verdict)

    def test_quick_runs_the_quick_steps_only_and_is_never_ready(self):
        status, verdict, said = self.run_main([fake(0, id="fast", quick=True), fake(1, id="slow")], flags=["--quick"])
        self.assertEqual(status, 0)
        self.assertEqual(verdict, ["Ready to push: NO (this was not a full run)"])
        self.assertIn("Left out: slow", said)
        self.assertNotIn("FAIL     slow", said)

    def test_only_runs_the_named_steps(self):
        status, verdict, said = self.run_main([fake(1, id="a"), fake(0, id="b")], flags=["--only", "b"])
        self.assertEqual(status, 0)
        self.assertIn("PASS     b", said)
        self.assertIn("Left out: a", said)
        self.assertEqual(verdict, ["Ready to push: NO (this was not a full run)"])

    def test_an_unknown_step_name_is_refused(self):
        with contextlib.redirect_stdout(io.StringIO()) as out:
            status = ci.main(["--only", "no-such-step"])
        self.assertEqual(status, 2)
        self.assertIn("no step named", out.getvalue())

    def test_a_broken_table_is_not_run_not_a_traceback(self):
        def broken():
            raise ValueError("bad json")
        with mock.patch.object(ci, "load_table", broken), contextlib.redirect_stdout(io.StringIO()) as out:
            self.assertEqual(ci.main(["--no-remote"]), 2)
        self.assertIn("NOT RUN", out.getvalue())

    def test_list_names_every_step(self):
        with contextlib.redirect_stdout(io.StringIO()) as out:
            self.assertEqual(ci.main(["--list"]), 0)
        for step in STEPS:
            self.assertIn(step["id"], out.getvalue())


class Builtins(unittest.TestCase):
    def version_tree(self, root, txt="1.2.3", mfile="1.2.3", yaml_v=("1.2.3",), heading="## 2026-01-01 - v1.2.3: a title"):
        write(root, "version.txt", txt + "\n")
        write(root, "muddler_project/mfile", '{"version": "%s"}' % mfile)
        write(root, "src_new/scripts/_groups.yaml", "".join('script: "ataxiaVersion = \\"%s\\"\\t--x"\n' % v for v in yaml_v))
        write(root, "CHANGELOG.md", "# Changelog\n\n%s\n\n- text\n" % heading)

    def test_version(self):
        with tempfile.TemporaryDirectory() as root:
            self.version_tree(root)
            self.assertEqual(ci.version(root)[0], ci.PASS)
            self.version_tree(root, mfile="1.2.2")
            self.assertEqual(ci.version(root)[0], ci.FAIL)
            self.version_tree(root, yaml_v=("1.2.4",))
            self.assertEqual(ci.version(root)[0], ci.FAIL)
            self.version_tree(root, yaml_v=("1.2.3", "1.2.3"))
            self.assertEqual(ci.version(root)[0], ci.FAIL, "two assignments fail CI's comparison, so they fail here")
            self.version_tree(root, yaml_v=("1.2.3", "9.9.9"))
            self.assertEqual(ci.version(root)[0], ci.FAIL)
            self.version_tree(root, heading="## 2026-01-01 - v1.2.2: the release before")
            verdict, line = ci.version(root)
            self.assertEqual(verdict, ci.FAIL)
            self.assertIn("CHANGELOG.md has no heading", line)
            self.version_tree(root, heading="## 2026-01-01 - v1.2.30: a longer number is another version")
            self.assertEqual(ci.version(root)[0], ci.FAIL)
            self.version_tree(root, heading="## 2026-01-01 - v1x2x3: a dot is a dot")
            self.assertEqual(ci.version(root)[0], ci.FAIL)

    def test_the_real_tree_has_one_version_and_its_heading(self):
        verdict, line = ci.version(ROOT)
        self.assertEqual(verdict, ci.PASS, line)

    def test_lua_syntax(self):
        self.assertTrue(ci.can_import("lupa"), "lupa with Lua 5.1 is missing for %s" % sys.executable)
        with tempfile.TemporaryDirectory(prefix="ci [x] ") as root:   # a '[' in the path must not hide the files
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
            # A file in a dot-folder: CI's `find` reads it, so this does.
            write(root, "src_new/.hid/003_Bad.lua", "local = 1\n")
            self.assertEqual(ci.lua_syntax(root)[0], ci.FAIL)

    def test_lua_syntax_reads_bytes_as_luac_does(self):
        # luac5.1 runs in the C locale: a byte above 127 is never a letter. In the user's locale 0xE9 would be one.
        with tempfile.TemporaryDirectory() as root:
            write(root, "src_new/a/001_Latin.lua", b"local x = \xe9\n", binary=True)
            verdict, line = ci.lua_syntax(root)
            self.assertEqual(verdict, ci.FAIL, line)
            self.assertIn("src_new/a/001_Latin.lua:1", line)
        with tempfile.TemporaryDirectory() as root:
            write(root, "src_new/a/001_Bom.lua", b"\xef\xbb\xbflocal x = 1\n", binary=True)
            write(root, "src_new/a/002_Quote.lua", "local x = \u201chi\u201d\n")
            verdict, line = ci.lua_syntax(root)
            self.assertEqual(verdict, ci.FAIL, line)
            self.assertIn("2 of 2 files", line, "the scan goes on after a message with a raw byte")
            self.assertIn("001_Bom.lua:1", line)
            self.assertIn("002_Quote.lua:1", line)

    def test_yaml(self):
        self.assertTrue(ci.can_import("yaml"), "pyyaml is missing for %s" % sys.executable)
        with tempfile.TemporaryDirectory(prefix="ci [x] ") as root:
            self.assertEqual(ci.yaml_files(root)[0], ci.NOT_RUN, "no file is not a pass")
            write(root, "src_new/scripts/_groups.yaml", "groups:\n- name: a\n")
            self.assertEqual(ci.yaml_files(root)[0], ci.PASS)
            write(root, "src_new/triggers/_groups.yaml", "groups:\n- name: [unclosed\n")
            self.assertEqual(ci.yaml_files(root)[0], ci.FAIL)


class Header(unittest.TestCase):
    LISTING = "\n".join(["aaa\trefs/tags/v4.7.99", "bbb\trefs/tags/v4.7.500", "ccc\trefs/tags/v4.7.500^{}",
                         "ddd\trefs/tags/dmap-v9.9.9", "eee\trefs/tags/v4.7.100"])

    def test_version_key(self):
        self.assertEqual(ci.version_key("v4.7.500"), (4, 7, 500))
        self.assertEqual(ci.version_key("4.7.99\n"), (4, 7, 99))
        self.assertLess(ci.version_key("4.7.99"), ci.version_key("4.7.100"))
        self.assertIsNone(ci.version_key("dmap-v1.0"))
        self.assertIsNone(ci.version_key(""))

    def test_top_tag_reads_ls_remote(self):
        self.assertEqual(ci.top_tag(self.LISTING), "v4.7.500")
        self.assertIsNone(ci.top_tag(""))
        self.assertIsNone(ci.top_tag(None))

    def test_tag_commit_prefers_the_peeled_row(self):
        self.assertEqual(ci.tag_commit(self.LISTING, "v4.7.500"), "ccc", "an annotated tag names its commit on the ^{} row")
        self.assertEqual(ci.tag_commit(self.LISTING, "v4.7.99"), "aaa")
        self.assertIsNone(ci.tag_commit(self.LISTING, "v9.9.9"))

    def test_version_notes(self):
        self.assertEqual(ci.version_notes("4.7.500", "v4.7.500", "4.7.500", True, True), [])
        self.assertEqual(ci.version_notes("4.7.500", None, None), [], "an unread remote is not a warning")
        self.assertEqual(ci.version_notes("4.7.500", "v4.7.500", "4.7.500"), [], "nothing known about the commits: no warning")
        self.assertEqual(len(ci.version_notes("4.7.499", "v4.7.500", "4.7.500")), 2)
        self.assertIn("tag v4.7.500", ci.version_notes("4.7.499", "v4.7.500", None)[0])
        self.assertEqual(len(ci.version_notes("", "v1.0", None)), 1)

    def test_the_same_number_on_another_commit_is_a_warning(self):
        # Two sessions bumped to the same number; the other one tagged first.
        notes = ci.version_notes("4.7.501", "v4.7.501", "4.7.500", tag_in_tree=False, main_in_tree=True)
        self.assertEqual(len(notes), 1)
        self.assertIn("that number is taken", notes[0])
        self.assertEqual(ci.version_notes("4.7.501", "v4.7.501", "4.7.501", tag_in_tree=True, main_in_tree=True), [])

    def test_a_main_that_moved_is_a_note(self):
        notes = ci.version_notes("4.7.500", "v4.7.500", "4.7.500", tag_in_tree=True, main_in_tree=False)
        self.assertEqual(len(notes), 1)
        self.assertTrue(notes[0].startswith("NOTE: origin/main"))

    def test_tree_state_and_the_ready_row(self):
        with mock.patch.object(ci, "git", lambda root, *args, **kw: " M a.lua\n?? b.py"):
            self.assertEqual(ci.tree_state("x"), [" M a.lua", "?? b.py"])
        with mock.patch.object(ci, "git", lambda root, *args, **kw: ""):
            self.assertEqual(ci.tree_state("x"), [])
        with mock.patch.object(ci, "git", lambda root, *args, **kw: None):
            self.assertIsNone(ci.tree_state("x"))

    def test_git_run_keeps_its_time_limit(self):
        status, text = ci.git_run(ROOT, "rev-parse", "--git-dir")
        self.assertEqual(status, 0)
        self.assertTrue(text.strip())
        self.assertEqual(ci.git_run(ROOT, "no-such-git-command")[0] in (0, None), False)
        self.assertEqual(ci.git_run(os.path.join(ROOT, "no-such-folder"), "status")[0] in (0,), False)


class LuaRunner(unittest.TestCase):
    """src_new/tests/test_runner.lua: zero test files is exit 2, never "All tests passed!" (2026-11-13)."""

    GOOD = 'describe("x", function() it("holds", function() expect(1).toBe(1) end) end)\n'
    BAD = 'describe("x", function() it("breaks", function() expect(1).toBe(2) end) end)\n'

    def run_in(self, files, force_shim=False):
        with tempfile.TemporaryDirectory() as root:
            tests = os.path.join(root, "src_new", "tests")
            os.makedirs(tests)
            for name in ("test_runner.lua", "mock_mudlet.lua"):   # the runner requires the mock before it lists files
                shutil.copy(os.path.join(ROOT, "src_new", "tests", name), tests)
            for name, text in files.items():
                write(root, "src_new/tests/" + name, text)
            lua51 = shutil.which("lua5.1")
            if lua51 and not force_shim:
                command = [lua51, "src_new/tests/test_runner.lua"]     # what CI's unit step runs
            else:
                self.assertTrue(ci.can_import("lupa"), "lupa with Lua 5.1 is missing for %s" % sys.executable)
                code = ("import sys; sys.path.insert(0, %r); import run_lua_tests as r; "
                        "r.make_runtime(force_shim=%r).execute('dofile(\"src_new/tests/test_runner.lua\")')" % (HERE, force_shim))
                command = [sys.executable, "-B", "-c", code]
            done = subprocess.run(command, cwd=root, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
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

    def test_the_python_backed_popen_lists_the_files(self):
        # The lupa wheels for Linux and macOS have no io.popen; run_lua_tests.py then supplies this one.
        status, said = self.run_in({"test_one.lua": self.GOOD, "test_two.lua": self.GOOD}, force_shim=True)
        self.assertEqual(status, 0, said)
        self.assertIn("Passed: 2  Failed: 0", said)
        status, said = self.run_in({}, force_shim=True)
        self.assertEqual(status, 2, said)

    def test_the_python_backed_popen_reads_a_command(self):
        import run_lua_tests
        lua = run_lua_tests.make_runtime(force_shim=True)
        read = lua.eval('function() local h = io.popen("echo shim-works") local s = h:read("*a") h:close() return s end')
        self.assertIn("shim-works", read())


if __name__ == "__main__":
    unittest.main(verbosity=1)
