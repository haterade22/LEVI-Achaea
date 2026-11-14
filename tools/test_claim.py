"""Tests for tools/claim.py: the claims, with a temporary claims folder and no network.

    python -B tools/test_claim.py
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import claim  # noqa: E402

HEAD = "a" * 40
OLD = "b" * 40


def clock(*stamps):
    """A now() that gives each stamp in turn, then repeats the last."""
    left = list(stamps)
    return lambda: left.pop(0) if len(left) > 1 else left[0]


class Folder(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="claims-test-")
        self.root = os.path.join(self.tmp, ".claims")
        self.lines = []

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def out(self, line):
        self.lines.append(line)

    def text(self):
        return "\n".join(self.lines)

    def take(self, name, me, **more):
        return claim.take(name, me, root=self.root, out=self.out, **more)

    def folders(self):
        return sorted(os.listdir(self.root))


class Take(Folder):
    def test_the_first_take_wins_and_makes_the_folder(self):
        self.assertEqual(self.take("fix-x", "s1", work="the X bug", now=lambda: "2026-11-14T10:00:00Z"), 0)
        self.assertEqual(self.folders(), ["fix-x"])
        owner = claim.read_owner(os.path.join(self.root, "fix-x"))
        self.assertEqual((owner["owner"], owner["work"], owner["time"]), ("s1", "the X bug", "2026-11-14T10:00:00Z"))

    def test_a_second_take_is_taken_and_names_the_owner(self):
        self.take("fix-x", "s1")
        self.lines = []
        self.assertEqual(self.take("fix-x", "s2"), 1)
        self.assertIn("TAKEN by s1", self.text())
        self.assertIn("--over", self.text(), "the message says how to take a dead claim")
        self.assertEqual(self.folders(), ["fix-x"])

    def test_the_root_is_made_when_it_is_missing(self):
        self.assertFalse(os.path.exists(self.root))
        self.assertEqual(self.take("fix-x", "s1"), 0)
        self.assertTrue(os.path.isdir(self.root))

    def test_a_take_lists_the_other_claims(self):
        self.take("ci-red-unit", "s1", work="unit tests red")
        self.lines = []
        self.take("fix-unit-tests", "s2")
        self.assertIn("ci-red-unit", self.text(), "a duplicate under another name is shown")
        self.assertIn("s1", self.text())

    def test_bad_names_are_refused(self):
        for name in ("", "../x", "a/b", "a.b", "a b"):
            self.assertEqual(self.take(name, "s1"), 2, name)
        self.assertEqual(self.take("fix-x", "s.1"), 2, "an owner name with a dot breaks the takeover folder name")
        self.assertFalse(os.path.exists(self.root) and os.listdir(self.root))

    def test_a_takeover_folder_blocks_a_plain_take(self):
        self.take("fix-x", "dead")
        self.take("fix-x", "s2", over=True)
        self.lines = []
        self.assertEqual(self.take("fix-x", "s3"), 1)
        self.assertIn("TAKEN by s2", self.text())
        self.assertEqual(self.folders(), ["fix-x.s2"])

    def test_a_take_with_no_owner_file_yet_still_is_taken(self):
        os.makedirs(os.path.join(self.root, "fix-x"))
        self.assertEqual(self.take("fix-x", "s2"), 1)
        self.assertIn("TAKEN", self.text())


class Race(Folder):
    def test_two_processes_one_winner_fifty_times(self):
        env = dict(os.environ)
        script = os.path.join(HERE, "claim.py")
        for round_no in range(50):
            env[claim.ENV] = os.path.join(self.tmp, "r%d" % round_no)
            procs = [subprocess.Popen([sys.executable, "-B", script, "take", "same-name", "--as", "p%d" % n],
                                      env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) for n in (1, 2)]
            codes = sorted(p.wait(60) for p in procs)
            self.assertEqual(codes, [0, 1], "round %d" % round_no)
            self.assertEqual(len(os.listdir(env[claim.ENV])), 1, "round %d" % round_no)


class Takeover(Folder):
    def test_the_new_claim_exists_before_the_dead_one_is_removed(self):
        self.take("fix-x", "dead")
        seen = []
        real = shutil.rmtree

        def watch(path, *a, **k):
            seen.append((os.path.basename(path), sorted(os.listdir(self.root))))
            real(path, *a, **k)

        old, claim.shutil.rmtree = claim.shutil.rmtree, watch
        try:
            self.assertEqual(self.take("fix-x", "s2", over=True), 0)
        finally:
            claim.shutil.rmtree = old
        self.assertEqual(seen, [("fix-x", ["fix-x", "fix-x.s2"])])
        self.assertEqual(self.folders(), ["fix-x.s2"])
        self.assertEqual(claim.read_owner(os.path.join(self.root, "fix-x.s2"))["owner"], "s2")

    def test_a_takeover_of_a_takeover(self):
        self.take("fix-x", "dead")
        self.take("fix-x", "s2", over=True)
        self.assertEqual(self.take("fix-x", "s3", over=True), 0)
        self.assertEqual(self.folders(), ["fix-x.s3"])

    def test_a_takeover_of_nothing_is_a_plain_take(self):
        self.assertEqual(self.take("fix-x", "s2", over=True), 0)
        self.assertEqual(self.folders(), ["fix-x.s2"])


class Release(Folder):
    def release(self, name, me, **more):
        return claim.release(name, me, root=self.root, out=self.out, **more)

    def test_release_removes_my_claim(self):
        self.take("fix-x", "s1")
        self.assertEqual(self.release("fix-x", "s1"), 0)
        self.assertEqual(self.folders(), [])

    def test_release_refuses_another_owners_claim(self):
        self.take("fix-x", "s1")
        self.assertEqual(self.release("fix-x", "s2"), 1)
        self.assertIn("s1", self.text())
        self.assertEqual(self.folders(), ["fix-x"])

    def test_release_finds_my_takeover_folder(self):
        self.take("fix-x", "dead")
        self.take("fix-x", "s2", over=True)
        self.assertEqual(self.release("fix-x", "s2"), 0)
        self.assertEqual(self.folders(), [])

    def test_release_of_nothing_is_not_an_error(self):
        self.assertEqual(self.release("fix-x", "s1"), 0)

    def test_all_mine_removes_only_mine(self):
        self.take("fix-x", "s1")
        self.take("fix-y", "s2")
        self.take("main-pushed-s1", "s1")
        self.assertEqual(claim.release_all_mine("s1", root=self.root, out=self.out), 0)
        self.assertEqual(self.folders(), ["fix-y"])


class FakeRun:
    """Answers git and gh like the real programs. runs: the gh answers in turn (the last repeats)."""

    def __init__(self, runs, head=HEAD, fetch=0):
        self.runs, self.head, self.fetch, self.calls = list(runs), head, fetch, []

    def __call__(self, args, **_):
        self.calls.append(args)
        if args[0] == "git" and "fetch" in args:
            return self.fetch, ""
        if args[0] == "git" and "rev-parse" in args:
            return 0, self.head + "\n"
        if args[0] == "gh":
            answer = self.runs.pop(0) if len(self.runs) > 1 else self.runs[0]
            return (0, json.dumps(answer)) if answer is not None else (1, "")
        raise AssertionError(args)


def gh_run(sha=HEAD, status="completed", conclusion="success"):
    return [{"headSha": sha, "status": status, "conclusion": conclusion}]


class CiFail(Folder):
    def ci_fail(self, fake, me="s1", step="unit"):
        self.sleeps = []
        return claim.ci_fail(step, me, root=self.root, out=self.out, run=fake, sleep=self.sleeps.append,
                             tries=4, wait=30)

    def test_main_green_is_yours_and_claims_nothing(self):
        self.assertEqual(self.ci_fail(FakeRun([gh_run()])), 0)
        self.assertIn("YOURS - fix it on your branch, no claim", self.text())
        self.assertFalse(os.path.exists(self.root) and os.listdir(self.root))

    def test_main_red_claims_the_step(self):
        self.assertEqual(self.ci_fail(FakeRun([gh_run(conclusion="failure")])), 0)
        self.assertEqual(self.folders(), ["main-unit"])
        self.assertEqual(claim.read_owner(os.path.join(self.root, "main-unit"))["owner"], "s1")

    def test_main_red_claimed_by_another_is_taken(self):
        self.take("main-unit", "s2")
        self.lines = []
        self.assertEqual(self.ci_fail(FakeRun([gh_run(conclusion="failure")])), 1)
        self.assertIn("TAKEN by s2", self.text())

    def test_main_red_after_a_push_goes_to_the_oldest_pusher(self):
        self.take("main-pushed-s3", "s3", now=lambda: "2026-11-14T10:05:00Z")
        self.take("main-pushed-s2", "s2", now=lambda: "2026-11-14T10:00:00Z")
        self.lines = []
        self.assertEqual(self.ci_fail(FakeRun([gh_run(conclusion="failure")])), 1)
        self.assertIn("s2", self.text())
        self.assertNotIn("main-unit", self.folders(), "no claim when a pusher owns the red main")

    def test_main_red_after_my_own_push_is_mine(self):
        self.take("main-pushed-s1", "s1")
        self.lines = []
        self.assertEqual(self.ci_fail(FakeRun([gh_run(conclusion="failure")])), 0)
        self.assertNotIn("main-unit", self.folders())

    def test_a_run_in_progress_is_waited_for(self):
        fake = FakeRun([gh_run(status="in_progress", conclusion=""), gh_run(conclusion="failure")])
        self.assertEqual(self.ci_fail(fake), 0)
        self.assertEqual(self.sleeps, [30])
        self.assertEqual(self.folders(), ["main-unit"])

    def test_an_old_head_sha_is_waited_for(self):
        fake = FakeRun([gh_run(sha=OLD, conclusion="failure"), gh_run()])
        self.assertEqual(self.ci_fail(fake), 0)
        self.assertIn("YOURS", self.text())
        self.assertEqual(self.sleeps, [30])

    def test_the_wait_is_bounded_and_ends_unknown(self):
        fake = FakeRun([gh_run(status="in_progress", conclusion="")])
        self.assertEqual(self.ci_fail(fake), 2)
        self.assertIn("UNKNOWN", self.text())
        self.assertEqual(len(self.sleeps), 3, "4 tries, 3 waits between them")
        self.assertEqual(len([c for c in fake.calls if c[0] == "gh"]), 4)

    def test_gh_asks_for_build_yml_on_main_only(self):
        fake = FakeRun([gh_run()])
        self.ci_fail(fake)
        gh = [c for c in fake.calls if c[0] == "gh"][0]
        for word in ("--workflow", "build.yml", "--branch", "main", "--limit", "1"):
            self.assertIn(word, gh)

    def test_a_failed_fetch_is_not_run(self):
        self.assertEqual(self.ci_fail(FakeRun([gh_run()], fetch=1)), 2)
        self.assertIn("NOT RUN", self.text())

    def test_gh_that_cannot_answer_ends_unknown(self):
        self.assertEqual(self.ci_fail(FakeRun([None])), 2)
        self.assertIn("UNKNOWN", self.text())

    def test_no_run_at_all_ends_unknown(self):
        self.assertEqual(self.ci_fail(FakeRun([[]])), 2)


class Pushed(Folder):
    def test_pushed_claims_main_pushed_me(self):
        self.assertEqual(claim.pushed("s1", root=self.root, out=self.out), 0)
        self.assertEqual(self.folders(), ["main-pushed-s1"])

    def test_a_second_push_keeps_the_claim(self):
        claim.pushed("s1", root=self.root, out=self.out)
        self.assertEqual(claim.pushed("s1", root=self.root, out=self.out), 0)
        self.assertEqual(self.folders(), ["main-pushed-s1"])


class Root(unittest.TestCase):
    def test_the_default_folder_is_outside_the_repository(self):
        self.assertEqual(os.path.basename(claim.DEFAULT_ROOT), ".claims")
        repo = os.path.dirname(HERE)
        self.assertFalse(os.path.abspath(claim.DEFAULT_ROOT).startswith(os.path.abspath(repo) + os.sep))

    def test_a_folder_inside_a_git_tree_is_refused(self):
        fake = lambda args, **_: (0, "true\n")  # noqa: E731
        self.assertIsNotNone(claim.root_problem(os.path.join(tempfile.gettempdir(), ".claims"), run=fake))
        fake = lambda args, **_: (128, "")  # noqa: E731
        self.assertIsNone(claim.root_problem(os.path.join(tempfile.gettempdir(), ".claims"), run=fake))

    def test_help_holds_the_protocol(self):
        for word in ("take", "ci-fail", "pushed", "release", "--over", "ListAgents", "subagent"):
            self.assertIn(word, claim.__doc__)


if __name__ == "__main__":
    unittest.main(verbosity=1)
