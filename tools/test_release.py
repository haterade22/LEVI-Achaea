"""Tests for tools/release.py: the decisions, with no network and no git.

    python -B tools/test_release.py
"""
import os
import sys
import tempfile
import unittest
import zipfile

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import release as rel  # noqa: E402

PASSED = {"event": "push", "status": "completed", "conclusion": "success"}
FAILED = {"event": "push", "status": "completed", "conclusion": "failure"}
RUNNING = {"event": "push", "status": "in_progress", "conclusion": ""}
OTHER = {"event": "pull_request", "status": "completed", "conclusion": "success"}


class TagReady(unittest.TestCase):
    def test_commits_at_version_is_the_leading_run_only(self):
        history = [("c3", "4.7.501"), ("c2", "4.7.501"), ("c1", "4.7.500"), ("c0", "4.7.501")]
        self.assertEqual(rel.commits_at_version(history, "4.7.501"), ["c3", "c2"])
        self.assertEqual(rel.commits_at_version(history, "4.7.500"), [], "main is past that version")
        self.assertEqual(rel.commits_at_version([("c1", None)], "4.7.501"), [])

    def test_judge_runs(self):
        self.assertEqual(rel.judge_runs([]), "none")
        self.assertEqual(rel.judge_runs([OTHER]), "none", "only the push run of the commit counts")
        self.assertEqual(rel.judge_runs([PASSED]), "passed")
        self.assertEqual(rel.judge_runs([RUNNING]), "running")
        self.assertEqual(rel.judge_runs([FAILED]), "failed")
        self.assertEqual(rel.judge_runs([FAILED, PASSED]), "passed", "a re-run after an outage that passed")
        self.assertEqual(rel.judge_runs([FAILED, RUNNING]), "running", "a re-run that has not finished is not a failure yet")

    def test_pick_commit_takes_the_newest_commit_whose_run_passed(self):
        states = {"c3": "running", "c2": "passed", "c1": "passed"}
        sha, seen = rel.pick_commit(["c3", "c2", "c1"], states.get)
        self.assertEqual(sha, "c2")
        self.assertEqual(seen, [("c3", "running"), ("c2", "passed")], "it stops at the first passed commit")

    def test_pick_commit_finds_nothing_when_no_run_passed(self):
        sha, seen = rel.pick_commit(["c3", "c2"], {"c3": "failed", "c2": None}.get)
        self.assertIsNone(sha)
        self.assertEqual(seen, [("c3", "failed"), ("c2", None)])

    def test_a_word_that_is_not_a_version_is_not_run(self):
        rows = []
        self.assertEqual(rel.tag_ready("latest", out=rows.append), 2)
        self.assertIn("NOT RUN", rows[0])

    def test_version_key(self):
        self.assertLess(rel.version_key("v4.7.99"), rel.version_key("4.7.100"))
        self.assertIsNone(rel.version_key("dmap-v1.0"))


class Post(unittest.TestCase):
    XML = '<Script><script>ataxiagui = ataxiagui or {}\nataxiaVersion = &quot;%s&quot;\t--last was 4.3</script></Script>'

    def test_version_in_xml_reads_both_quote_forms(self):
        self.assertEqual(rel.version_in_xml(self.XML % "4.7.500"), "4.7.500")
        self.assertEqual(rel.version_in_xml('ataxiaVersion = "4.7.9"'), "4.7.9")
        self.assertIsNone(rel.version_in_xml("no version here"))

    def test_version_in_package_and_in_the_loose_file(self):
        with tempfile.TemporaryDirectory() as folder:
            package = os.path.join(folder, "Levi_Ataxia.mpackage")
            with zipfile.ZipFile(package, "w") as z:
                z.writestr("Levi_Ataxia.xml", self.XML % "4.7.501")
                z.writestr("config.lua", "mpackage = [[Levi_Ataxia]]")
            loose = os.path.join(folder, "Levi_Ataxia.xml")
            with open(loose, "w", encoding="utf-8") as fh:
                fh.write(self.XML % "4.7.496")
            self.assertEqual(rel.version_in_package(package), "4.7.501")
            self.assertEqual(rel.version_in_loose_xml(loose), "4.7.496")
            self.assertIsNone(rel.version_in_package(os.path.join(folder, "missing.mpackage")))
            self.assertIsNone(rel.version_in_package(loose), "a file that is not a zip has no readable version")
            self.assertIsNone(rel.version_in_loose_xml(os.path.join(folder, "missing.xml")))

    def test_judge_build_folder(self):
        self.assertEqual(rel.judge_build_folder("4.7.501", "4.7.501", "4.7.501"), [])
        # The state found on 2026-11-13: the package was refreshed, the loose XML was three versions old.
        problems = rel.judge_build_folder("4.7.499", "4.7.499", "4.7.496")
        self.assertEqual(problems, ["the loose Levi_Ataxia.xml holds 4.7.496"])
        self.assertEqual(len(rel.judge_build_folder("4.7.501", None, None)), 2)
        self.assertIn("no readable version", rel.judge_build_folder("4.7.501", None, "4.7.501")[0])


if __name__ == "__main__":
    unittest.main(verbosity=1)
