"""Tests for tools/claim.py: the claims, with a temporary claims folder and no network.

    python -B tools/test_claim.py
"""
import json
import ntpath
import os
import re
import shlex
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import unittest

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import claim  # noqa: E402

SCRIPT = os.path.join(HERE, "claim.py")
HEAD = "a" * 40
OLD = "b" * 40
SHA1 = "1" * 40
SHA2 = "2" * 40
NOT_A_REPO = "fatal: not a git repository (or any of the parent directories): .git"


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

    def release(self, name, me):
        return claim.release(name, me, root=self.root, out=self.out)

    def claims(self):
        """{key: row} of the store."""
        return {row["key"]: row for row in claim.claims_now(self.root)}

    def keys(self):
        return sorted(self.claims())

    def gen(self, key):
        return self.claims()[key]["gen"]

    def run_cli(self, *words, root=None):
        env = dict(os.environ)
        env[claim.ENV] = root or self.root
        done = subprocess.run([sys.executable, "-B", SCRIPT] + list(words), env=env, stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT, timeout=120)
        return done.returncode, done.stdout.decode("utf-8", "replace")

    def printed_command(self):
        """The words of the takeover command that the last result printed, after 'claim.py'."""
        found = re.search(r"`[^`]*claim\.py ([^`]+)`", self.text())
        self.assertIsNotNone(found, self.text())
        return shlex.split(found.group(1))


class Take(Folder):
    def test_the_first_take_wins_and_stores_the_owner(self):
        self.assertEqual(self.take("fix-x", "s1", work="the  X\nbug", now=lambda: "2026-11-14T10:00:00Z"), 0)
        row = self.claims()["fix-x"]
        self.assertEqual((row["owner"], row["work"], row["time"]), ("s1", "the X bug", "2026-11-14T10:00:00Z"))
        self.assertIn("NEXT:", self.lines[-1])

    def test_a_second_take_is_taken_and_names_the_owner(self):
        self.take("fix-x", "s1")
        self.lines = []
        self.assertEqual(self.take("fix-x", "s2"), 1)
        self.assertIn("TAKEN", self.text())
        self.assertIn("s1", self.text())
        self.assertIn("NEXT:", self.lines[-1])
        self.assertEqual(self.printed_command(), ["take", "fix-x", "--over", str(self.gen("fix-x")), "--as", "s2"])
        self.assertEqual(self.claims()["fix-x"]["owner"], "s1")

    def test_the_loser_is_put_on_the_waiter_list_once(self):
        self.take("fix-x", "s1")
        self.take("fix-x", "s2")
        self.take("fix-x", "s2")
        self.take("fix-x", "s3")
        self.assertEqual(self.claims()["fix-x"]["waiters"], "s2 s3")

    def test_a_waiter_does_not_change_the_generation(self):
        self.take("fix-x", "s1")
        before = self.gen("fix-x")
        self.take("fix-x", "s2")
        self.assertEqual(self.gen("fix-x"), before, "the printed takeover command of an earlier waiter stays valid")

    def test_my_own_claim_again_is_still_mine(self):
        self.take("fix-x", "s1")
        self.lines = []
        self.assertEqual(self.take("fix-x", "s1"), 0)
        self.assertIn("already yours", self.text())

    def test_the_root_is_made_when_it_is_missing(self):
        self.assertFalse(os.path.exists(self.root))
        self.assertEqual(self.take("fix-x", "s1"), 0)
        self.assertTrue(os.path.isdir(self.root))

    def test_a_take_lists_the_other_claims_and_says_who_yields(self):
        self.take("ci-red-unit", "s1", work="unit tests red")
        self.lines = []
        self.take("fix-unit-tests", "s2")
        self.assertIn("ci-red-unit", self.text(), "a duplicate under another name is shown")
        self.assertIn("s1", self.text())
        self.assertIn("release fix-unit-tests --as s2", self.lines[-1], "the later claim is the one that yields")

    def test_bad_names_are_refused(self):
        for name in ("", "../x", "a/b", "a.b", "a b"):
            self.assertEqual(self.take(name, "s1"), 2, name)
        self.assertEqual(self.take("fix-x", "s.1"), 2)
        self.assertEqual(self.take("fix-x", ""), 2)
        self.assertFalse(os.path.exists(self.root) and self.keys())

    def test_a_case_variant_is_the_same_claim(self):
        self.assertEqual(self.take("Fix-X", "s1"), 0)
        self.assertEqual(self.take("fix-x", "s2"), 1)
        self.assertEqual(self.take("FIX-X", "s3", over=self.gen("fix-x") + 99), 1)
        self.assertEqual(self.keys(), ["fix-x"])
        self.assertEqual(self.claims()["fix-x"]["owner"], "s1")

    def test_a_failure_inside_the_transaction_leaves_no_claim(self):
        def broken():
            raise RuntimeError("the session died here")

        with self.assertRaises(RuntimeError):
            self.take("fix-x", "s1", now=broken)
        self.assertEqual(self.keys(), [])
        self.assertEqual(self.take("fix-x", "s2"), 0, "a half-made claim must not block the next session")


class Race(Folder):
    def test_two_processes_one_winner_fifty_times(self):
        env = dict(os.environ)
        for round_no in range(50):
            env[claim.ENV] = os.path.join(self.tmp, "r%d" % round_no)
            procs = [subprocess.Popen([sys.executable, "-B", SCRIPT, "take", "same-name", "--as", "p%d" % n],
                                      env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) for n in (1, 2)]
            codes = sorted(p.wait(60) for p in procs)
            self.assertEqual(codes, [0, 1], "round %d" % round_no)
            self.assertEqual(len(claim.claims_now(env[claim.ENV])), 1, "round %d" % round_no)

    def test_two_takeovers_of_one_dead_claim_one_winner_twenty_times(self):
        env = dict(os.environ)
        for round_no in range(20):
            root = env[claim.ENV] = os.path.join(self.tmp, "t%d" % round_no)
            claim.take("fix-x", "dead", root=root, out=self.out)
            gen = str(claim.claims_now(root)[0]["gen"])
            procs = [(n, subprocess.Popen([sys.executable, "-B", SCRIPT, "take", "fix-x", "--over", gen, "--as", "p%d" % n],
                                          env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)) for n in (1, 2)]
            codes = {"p%d" % n: p.wait(60) for n, p in procs}
            self.assertEqual(sorted(codes.values()), [0, 1], "round %d" % round_no)
            rows = claim.claims_now(root)
            self.assertEqual(len(rows), 1, "round %d: the work is never unclaimed and never claimed twice" % round_no)
            self.assertEqual(codes[rows[0]["owner"]], 0, "round %d: the owner is the one that got exit 0" % round_no)
            self.assertEqual(claim.take("fix-x", "p4", root=root, out=self.out), 1, "round %d: a later take is TAKEN" % round_no)


class Takeover(Folder):
    def test_a_takeover_needs_the_generation_that_the_taker_saw(self):
        self.take("fix-x", "dead", work="the X bug")
        seen = self.gen("fix-x")
        self.assertEqual(self.take("fix-x", "s2", over=seen), 0)
        self.lines = []
        self.assertEqual(self.take("fix-x", "s3", over=seen), 1, "s3 looked before s2 took the claim")
        self.assertIn("s2", self.text())
        row = self.claims()["fix-x"]
        self.assertEqual((row["owner"], row["work"]), ("s2", "the X bug"))
        self.assertEqual(self.keys(), ["fix-x"])

    def test_the_printed_takeover_command_runs_after_an_earlier_takeover(self):
        self.take("main-pushed-0123456789", "dead")
        self.take("main-pushed-0123456789", "s2", over=self.gen("main-pushed-0123456789"))
        self.lines = []
        self.assertEqual(self.take("main-pushed-0123456789", "s3"), 1)
        status, text = self.run_cli(*self.printed_command())
        self.assertEqual(status, 0, text)
        self.assertEqual(self.claims()["main-pushed-0123456789"]["owner"], "s3")

    def test_a_takeover_of_nothing_is_a_plain_take(self):
        self.assertEqual(self.take("fix-x", "s2", over=7), 0)
        self.assertEqual(self.claims()["fix-x"]["owner"], "s2")

    def test_a_takeover_keeps_the_other_waiters(self):
        self.take("fix-x", "dead")
        self.take("fix-x", "s2")
        self.take("fix-x", "s3")
        self.take("fix-x", "s2", over=self.gen("fix-x"))
        self.assertEqual(self.claims()["fix-x"]["waiters"], "s3")

    def test_a_plain_take_after_a_takeover_is_taken(self):
        self.take("fix-x", "dead")
        self.take("fix-x", "s2", over=self.gen("fix-x"))
        self.lines = []
        self.assertEqual(self.take("fix-x", "s3"), 1)
        self.assertIn("s2", self.text())


class Release(Folder):
    def test_release_removes_my_claim(self):
        self.take("fix-x", "s1")
        self.lines = []
        self.assertEqual(self.release("fix-x", "s1"), 0)
        self.assertEqual(self.keys(), [])
        self.assertIn("RELEASED fix-x", self.text())
        self.assertIn("NEXT:", self.lines[-1])

    def test_release_refuses_another_owners_claim(self):
        self.take("fix-x", "s1")
        self.assertEqual(self.release("fix-x", "s2"), 1)
        self.assertIn("s1", self.text())
        self.assertEqual(self.keys(), ["fix-x"])

    def test_release_of_nothing_is_not_an_error(self):
        self.assertEqual(self.release("fix-x", "s1"), 0)

    def test_release_names_the_waiters_to_message(self):
        self.take("fix-x", "s1")
        self.take("fix-x", "s2")
        self.take("fix-x", "s3")
        self.lines = []
        self.assertEqual(self.release("Fix-X", "s1"), 0)
        self.assertIn("s2", self.lines[-1])
        self.assertIn("s3", self.lines[-1])
        self.assertIn("NEXT: message", self.lines[-1])

    def test_a_store_that_cannot_be_written_is_exit_2_and_not_released(self):
        self.take("fix-x", "s1")
        other = sqlite3.connect(os.path.join(self.root, claim.DB), isolation_level=None)
        old, claim.BUSY = claim.BUSY, 0.2
        try:
            other.execute("BEGIN IMMEDIATE")
            self.lines = []
            self.assertEqual(self.release("fix-x", "s1"), 2)
            self.assertNotIn("RELEASED", self.text())
            self.assertIn(self.root, self.text(), "the message names the store")
            self.assertIn("NEXT:", self.lines[-1])
            self.lines = []
            self.assertEqual(self.take("fix-y", "s2"), 2, "a take that cannot read the claims does not win")
            self.assertEqual(claim.list_claims(root=self.root, out=self.out), 2, "a list that cannot read says so")
        finally:
            other.execute("ROLLBACK")
            other.close()
            claim.BUSY = old
        self.assertEqual(self.keys(), ["fix-x"])

    def test_there_is_no_release_of_every_claim(self):
        self.assertNotIn("--all-mine", claim.__doc__)
        status, _ = self.run_cli("release", "--all-mine", "--as", "s1")
        self.assertEqual(status, 2)

    def test_list_as_shows_only_mine(self):
        self.take("fix-x", "s1")
        self.take("fix-y", "s2")
        self.lines = []
        self.assertEqual(claim.list_claims(me="s1", root=self.root, out=self.out), 0)
        self.assertIn("fix-x", self.text())
        self.assertNotIn("fix-y", self.text())


class FakeRun:
    """Answers git and gh like the real programs. runs: the gh answers in turn (the last repeats).

    A gh answer is a list (the JSON), or a (status, stderr) pair for a gh that fails."""

    def __init__(self, runs, head=HEAD, fetch=(0, "")):
        self.runs, self.head, self.fetch, self.calls = list(runs), head, fetch, []

    def __call__(self, args, **_):
        self.calls.append(args)
        if args[0] == "git" and "fetch" in args:
            return self.fetch[0], "", self.fetch[1]
        if args[0] == "git" and "rev-parse" in args:
            return 0, self.head + "\n", ""
        if args[0] == "gh":
            answer = self.runs.pop(0) if len(self.runs) > 1 else self.runs[0]
            if isinstance(answer, tuple):
                return answer[0], "", answer[1]
            return 0, json.dumps(answer), ""
        raise AssertionError(args)

    def gh_calls(self):
        return [c for c in self.calls if c[0] == "gh"]


def gh_run(sha=HEAD, status="completed", conclusion="success"):
    return [{"headSha": sha, "status": status, "conclusion": conclusion}]


class CiFail(Folder):
    def ci_fail(self, fake, me="s1", step="unit"):
        self.sleeps, self.clock = [], 0

        def sleep(seconds):
            self.sleeps.append(seconds)
            self.clock += seconds

        self.lines = []
        return claim.ci_fail(step, me, root=self.root, out=self.out, run=fake, sleep=sleep,
                             clock=lambda: self.clock, wait=30, limit=90)

    def pushed(self, me, sha):
        return claim.pushed(me, sha=sha, root=self.root, out=self.out, now=lambda: "2026-11-14T10:00:00Z")

    def assert_stopped(self, word):
        self.assertIn(word, self.text())
        self.assertIn("NEXT:", self.lines[-1])
        self.assertIn("stop and report", self.lines[-1])
        self.assertFalse(os.path.exists(self.root) and self.keys(), "no claim when main was not read")

    def test_main_green_is_yours_and_claims_nothing(self):
        self.assertEqual(self.ci_fail(FakeRun([gh_run()])), 0)
        self.assertIn("YOURS - fix it on your branch, no claim", self.text())
        self.assertFalse(os.path.exists(self.root) and self.keys())

    def test_main_red_claims_the_step(self):
        self.assertEqual(self.ci_fail(FakeRun([gh_run(conclusion="failure")])), 0)
        self.assertEqual(self.keys(), ["main-unit"])
        self.assertEqual(self.claims()["main-unit"]["owner"], "s1")
        self.assertIn("NEXT:", self.lines[-1])

    def test_main_red_claimed_by_another_is_taken(self):
        self.take("main-unit", "s2")
        self.assertEqual(self.ci_fail(FakeRun([gh_run(conclusion="failure")])), 1)
        self.assertIn("TAKEN", self.text())
        self.assertIn("s2", self.text())

    def test_main_red_after_a_push_goes_to_the_first_pusher_not_to_the_clock_or_the_name(self):
        self.pushed("z-first", SHA2)
        self.pushed("a-second", SHA1)
        self.assertEqual(self.ci_fail(FakeRun([gh_run(conclusion="failure")])), 1)
        self.assertIn("z-first", self.text())
        self.assertNotIn("main-unit", self.keys(), "no claim when a pusher owns the red main")
        self.assertEqual(self.printed_command()[:2], ["take", "main-pushed-" + SHA2[:10]])

    def test_main_red_after_my_own_push_is_mine(self):
        self.pushed("s1", SHA1)
        self.assertEqual(self.ci_fail(FakeRun([gh_run(conclusion="failure")])), 0)
        self.assertNotIn("main-unit", self.keys())
        self.assertIn("yours to fix", self.text())

    def test_a_session_that_fixes_the_red_main_is_not_overridden_by_a_push(self):
        self.take("main-claim-test", "s1")
        self.pushed("s2", SHA1)
        self.assertEqual(self.ci_fail(FakeRun([gh_run(conclusion="failure")]), me="s2"), 1)
        self.assertIn("s1", self.text())
        self.assertIn("main-claim-test", self.text())
        self.assertNotIn("main-unit", self.keys())

    def test_a_run_in_progress_is_waited_for(self):
        fake = FakeRun([gh_run(status="in_progress", conclusion=""), gh_run(conclusion="failure")])
        self.assertEqual(self.ci_fail(fake), 0)
        self.assertEqual(self.sleeps, [30])
        self.assertEqual(self.keys(), ["main-unit"])

    def test_an_old_head_sha_is_waited_for(self):
        fake = FakeRun([gh_run(sha=OLD, conclusion="failure"), gh_run()])
        self.assertEqual(self.ci_fail(fake), 0)
        self.assertIn("YOURS", self.text())
        self.assertEqual(self.sleeps, [30])

    def test_the_wait_is_bounded_by_the_clock_and_ends_unknown(self):
        fake = FakeRun([gh_run(status="in_progress", conclusion="")])
        self.assertEqual(self.ci_fail(fake), 2)
        self.assert_stopped("UNKNOWN")
        self.assertEqual(self.sleeps, [30, 30, 30], "90 s in all")
        self.assertEqual(len(fake.gh_calls()), 4)

    def test_gh_asks_for_build_yml_on_main_only(self):
        fake = FakeRun([gh_run()])
        self.ci_fail(fake)
        for word in ("--workflow", "build.yml", "--branch", "main", "--limit", "1"):
            self.assertIn(word, fake.gh_calls()[0])

    def test_a_failed_fetch_is_not_run(self):
        fake = FakeRun([gh_run()], fetch=(1, "fatal: unable to access the remote"))
        self.assertEqual(self.ci_fail(fake), 2)
        self.assert_stopped("NOT RUN")
        self.assertIn("unable to access", self.text())
        self.assertEqual(self.sleeps, [])

    def test_a_missing_git_is_not_run(self):
        self.assertEqual(self.ci_fail(FakeRun([gh_run()], fetch=(None, claim.MISSING))), 2)
        self.assert_stopped("NOT RUN")

    def test_a_missing_gh_is_not_retried(self):
        fake = FakeRun([(None, claim.MISSING)])
        self.assertEqual(self.ci_fail(fake), 2)
        self.assert_stopped("UNKNOWN")
        self.assertEqual((len(fake.gh_calls()), self.sleeps), (1, []))

    def test_a_gh_that_is_not_logged_in_is_not_retried(self):
        fake = FakeRun([(4, "To get started with GitHub CLI, please run:  gh auth login")])
        self.assertEqual(self.ci_fail(fake), 2)
        self.assert_stopped("UNKNOWN")
        self.assertEqual((len(fake.gh_calls()), self.sleeps), (1, []))

    def test_a_rate_limit_is_retried_inside_the_limit_and_then_unknown(self):
        fake = FakeRun([(1, "HTTP 403: API rate limit exceeded")])
        self.assertEqual(self.ci_fail(fake), 2)
        self.assert_stopped("UNKNOWN")
        self.assertIn("rate limit", self.text())
        self.assertEqual(len(fake.gh_calls()), 4)

    def test_a_rate_limit_that_names_authenticated_requests_is_not_a_login_failure(self):
        fake = FakeRun([(1, "API rate limit exceeded for 1.2.3.4. (Authenticated requests get a higher rate limit.)")])
        self.assertEqual(self.ci_fail(fake), 2)
        self.assertNotIn("not logged in", self.text())
        self.assertEqual(len(fake.gh_calls()), 4, "a rate limit ends, so it is retried")

    def test_a_rate_limit_that_ends_is_answered(self):
        fake = FakeRun([(1, "HTTP 403: API rate limit exceeded"), gh_run()])
        self.assertEqual(self.ci_fail(fake), 0)
        self.assertIn("YOURS", self.text())

    def test_a_cancelled_run_is_not_a_red_main(self):
        fake = FakeRun([gh_run(conclusion="cancelled")])
        self.assertEqual(self.ci_fail(fake), 2)
        self.assert_stopped("UNKNOWN")
        self.assertIn("cancelled", self.text())
        self.assertEqual(self.sleeps, [], "a completed run does not change: no wait")

    def test_no_run_at_all_ends_unknown(self):
        self.assertEqual(self.ci_fail(FakeRun([[]])), 2)
        self.assert_stopped("UNKNOWN")


class Pushed(Folder):
    def pushed(self, me, **more):
        return claim.pushed(me, root=self.root, out=self.out, **more)

    def test_pushed_claims_the_commit(self):
        fake = FakeRun([], head=SHA1)
        self.assertEqual(self.pushed("s1", run=fake), 0)
        self.assertEqual(self.keys(), ["main-pushed-" + SHA1[:10]])
        self.assertIn(SHA1, self.claims()["main-pushed-" + SHA1[:10]]["work"])
        self.assertIn("release main-pushed-%s --as s1" % SHA1[:10], self.lines[-1])

    def test_a_second_push_is_a_second_claim_and_outlives_the_first(self):
        self.pushed("s1", sha=SHA1)
        self.pushed("s1", sha=SHA2)
        self.assertEqual(self.keys(), ["main-pushed-" + SHA1[:10], "main-pushed-" + SHA2[:10]])
        self.assertEqual(self.release("main-pushed-" + SHA1[:10], "s1"), 0, "the run of the first push is green")
        self.assertEqual(self.keys(), ["main-pushed-" + SHA2[:10]], "the second push still has its owner")

    def test_pushed_twice_for_one_commit_is_one_claim(self):
        self.pushed("s1", sha=SHA1)
        self.assertEqual(self.pushed("s1", sha=SHA1.upper().lower()), 0)
        self.assertEqual(len(self.keys()), 1)

    def test_pushed_without_a_commit_is_refused(self):
        def no_git(args, **_):
            return None, "", claim.MISSING

        self.assertEqual(self.pushed("s1", run=no_git), 2)
        self.assertIn("NEXT:", self.lines[-1])
        self.assertEqual(self.pushed("s1", sha="not-a-sha"), 2)
        self.assertFalse(os.path.exists(self.root) and self.keys())


class Root(unittest.TestCase):
    def test_the_default_folder_is_outside_the_repository(self):
        # DEFAULT_ROOT is a Windows path; ntpath splits it the same way on the Linux CI runner.
        self.assertEqual(ntpath.basename(claim.DEFAULT_ROOT), ".claims")
        repo = ntpath.normcase(os.path.dirname(HERE))
        self.assertFalse(ntpath.normcase(claim.DEFAULT_ROOT).startswith(repo + ntpath.sep))

    def test_a_folder_inside_a_git_tree_is_refused(self):
        root = os.path.join(tempfile.gettempdir(), ".claims")
        self.assertIsNotNone(claim.root_problem(root, run=lambda args, **_: (0, "true\n", "")))
        self.assertIsNone(claim.root_problem(root, run=lambda args, **_: (128, "", NOT_A_REPO)))

    def test_a_check_that_did_not_run_is_refused(self):
        root = os.path.join(tempfile.gettempdir(), ".claims")
        self.assertIsNotNone(claim.root_problem(root, run=lambda args, **_: (None, "", claim.MISSING)))
        self.assertIsNotNone(claim.root_problem(root, run=lambda args, **_: (128, "", "fatal: detected dubious ownership")))

    def test_a_relative_folder_is_refused(self):
        self.assertIsNotNone(claim.root_problem(".claims", run=lambda args, **_: (128, "", NOT_A_REPO)))

    def test_a_missing_parent_inside_a_git_tree_is_refused(self):
        tmp = tempfile.mkdtemp(prefix="claims-root-")
        try:
            subprocess.run(["git", "init", "--quiet", tmp], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            root = os.path.join(tmp, "new-directory", ".claims")
            self.assertIsNotNone(claim.root_problem(root), "git is asked at the nearest folder that exists")
            self.assertFalse(os.path.exists(os.path.join(tmp, "new-directory")), "the check makes nothing")
        finally:
            shutil.rmtree(tmp, ignore_errors=True)

    def test_help_holds_the_protocol(self):
        for word in ("take", "ci-fail", "pushed", "release", "--over", "ListAgents", "subagent", "NEXT:", "waiter",
                     "compaction", "same outcome", "main- is for a red main"):
            self.assertIn(word, claim.__doc__)


if __name__ == "__main__":
    unittest.main(verbosity=1)
