"""Tests for .githooks/pre-push: the pushes it must refuse and the pushes it must let go.

    python -B tools/test_githooks.py

Each test builds a scratch repository with a local bare remote in a temp folder, points
core.hooksPath at THIS tree's .githooks, and runs real `git push` commands. Nothing touches the
real remote. A refusal counts only when the hook's own text ("pre-push: REFUSED") is in the output,
so a push that git itself rejects cannot pass for the hook.
"""
import os
import subprocess
import sys
import tempfile
import unittest

sys.dont_write_bytecode = True
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HOOKS = os.path.join(ROOT, ".githooks")
HOOK = os.path.join(HOOKS, "pre-push")


class Repo:
    """A work clone and its bare remote. commit() writes version.txt; push() returns (exit status, output)."""

    def __init__(self, base):
        self.remote = os.path.join(base, "remote.git")
        self.work = os.path.join(base, "work")
        self.git_in(base, "init", "--quiet", "--bare", "remote.git")
        self.git_in(base, "-c", "init.defaultBranch=main", "init", "--quiet", "work")
        for key, value in (("user.name", "Hook Test"), ("user.email", "hook-test@example.invalid"),
                           ("commit.gpgsign", "false"), ("tag.gpgsign", "false"), ("core.autocrlf", "false"),
                           ("core.hooksPath", HOOKS.replace(os.sep, "/"))):
            self.git("config", key, value)
        self.git("remote", "add", "origin", self.remote.replace(os.sep, "/"))
        self.git("checkout", "--quiet", "-B", "main")

    @staticmethod
    def git_in(folder, *args):
        done = subprocess.run(["git"] + list(args), cwd=folder, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT, encoding="utf-8", errors="replace")
        return done.returncode, done.stdout

    def git(self, *args):
        status, out = self.git_in(self.work, *args)
        if status != 0:
            raise AssertionError("git %s failed in the scratch repository:\n%s" % (" ".join(args), out))
        return out.strip()

    def commit(self, version, note="change"):
        with open(os.path.join(self.work, "version.txt"), "w", encoding="utf-8", newline="\n") as fh:
            fh.write(version + "\n")
        with open(os.path.join(self.work, "notes.txt"), "a", encoding="utf-8", newline="\n") as fh:
            fh.write("%s %s\n" % (version, note))
        self.git("add", "version.txt", "notes.txt")
        self.git("commit", "--quiet", "-m", "v%s: %s" % (version, note))
        return self.git("rev-parse", "HEAD")

    def push(self, *args):
        return self.git_in(self.work, "push", *args)

    def remote_has(self, ref):
        status, _ = self.git_in(self.remote, "rev-parse", "--verify", "--quiet", ref)
        return status == 0


class PrePush(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Repo(self.temp.name)
        self.repo.commit("1.0.0", "first")
        status, out = self.repo.push("origin", "main")
        self.assertEqual(status, 0, out)   # the first push of main, to an empty remote: allowed

    def refused(self, status, out, words):
        self.assertNotEqual(status, 0, out)
        self.assertIn("pre-push: REFUSED", out, "git refused the push, not the hook:\n" + out)
        self.assertIn(words, out)

    def allowed(self, status, out):
        self.assertEqual(status, 0, out)
        self.assertNotIn("REFUSED", out)

    # ---- the hook itself

    def test_the_hook_file_can_run_everywhere(self):
        with open(HOOK, "rb") as fh:
            body = fh.read()
        self.assertTrue(body.startswith(b"#!/bin/sh\n"), "POSIX sh, so it runs under Git for Windows and on Linux")
        self.assertNotIn(b"\r", body, "a CR in a hook breaks it on Linux")
        done = subprocess.run(["git", "-C", ROOT, "ls-files", "-s", ".githooks/pre-push"], stdout=subprocess.PIPE,
                              stderr=subprocess.DEVNULL, encoding="utf-8")
        if done.returncode == 0 and done.stdout.strip():   # tracked: git on Linux runs a hook only with the executable bit
            self.assertTrue(done.stdout.startswith("100755 "), "git update-index --chmod=+x .githooks/pre-push\n" + done.stdout)

    # ---- must let go

    def test_a_fast_forward_of_main_and_a_branch_push_pass(self):
        self.repo.commit("1.0.0", "docs")
        self.allowed(*self.repo.push("origin", "main"))
        self.repo.git("checkout", "--quiet", "-b", "feature")
        self.repo.commit("1.0.0", "work")
        self.allowed(*self.repo.push("origin", "feature"))
        self.allowed(*self.repo.push("origin", "HEAD:main"))   # the form the release flow uses

    def test_one_tag_that_names_the_version_on_main_passes(self):
        self.repo.commit("1.0.1", "release")
        self.allowed(*self.repo.push("origin", "main"))
        self.repo.git("tag", "v1.0.1")
        status, out = self.repo.push("origin", "v1.0.1")
        self.allowed(status, out)
        self.assertNotIn("WARNING", out)
        self.assertNotIn("NOT checked", out)
        self.assertTrue(self.repo.remote_has("refs/tags/v1.0.1"))

    def test_an_annotated_tag_passes(self):
        self.repo.commit("1.0.1", "release")
        self.allowed(*self.repo.push("origin", "main"))
        self.repo.git("tag", "-a", "v1.0.1", "-m", "release 1.0.1")
        self.allowed(*self.repo.push("origin", "v1.0.1"))

    def test_a_tag_on_a_later_commit_with_the_same_version_passes(self):
        self.repo.commit("1.0.1", "release")
        self.repo.commit("1.0.1", "docs after the bump")
        self.allowed(*self.repo.push("origin", "main"))
        self.repo.git("tag", "v1.0.1")
        self.allowed(*self.repo.push("origin", "v1.0.1"))

    def test_a_tag_delete_passes(self):
        self.repo.commit("1.0.1", "release")
        self.repo.push("origin", "main")
        self.repo.git("tag", "v1.0.1")
        self.repo.push("origin", "v1.0.1")
        status, out = self.repo.push("origin", ":refs/tags/v1.0.1")   # the recovery for a bad tag
        self.allowed(status, out)
        self.assertFalse(self.repo.remote_has("refs/tags/v1.0.1"))

    def test_a_mapper_tag_is_not_judged(self):
        self.repo.git("checkout", "--quiet", "-b", "side")
        self.repo.commit("1.0.0", "mapper work, not on main")
        self.repo.git("tag", "dmap-v1.2")
        status, out = self.repo.push("origin", "dmap-v1.2")
        self.allowed(status, out)
        self.assertNotIn("pre-push:", out)

    def test_a_lower_tag_is_a_warning_not_a_refusal(self):
        first = self.repo.commit("1.0.1", "release")
        self.repo.commit("1.0.2", "release")
        self.repo.push("origin", "main")
        self.repo.git("tag", "v1.0.2")
        self.repo.push("origin", "v1.0.2")
        self.repo.git("tag", "v1.0.1", first)      # the recovery case: an older tag pushed again while a newer one exists
        status, out = self.repo.push("origin", "v1.0.1")
        self.allowed(status, out)
        self.assertIn("pre-push: WARNING: v1.0.1 is below the highest local tag v1.0.2", out)

    def test_no_verify_is_the_stated_way_round(self):
        self.repo.git("tag", "v9.9.9")
        self.allowed(*self.repo.push("--no-verify", "origin", "v9.9.9"))

    # ---- must refuse

    def test_two_version_tags_in_one_push_are_refused(self):
        first = self.repo.commit("1.0.1", "release")
        self.repo.commit("1.0.2", "release")
        self.repo.push("origin", "main")
        self.repo.git("tag", "v1.0.1", first)
        self.repo.git("tag", "v1.0.2")
        self.refused(*self.repo.push("origin", "v1.0.1", "v1.0.2"), "carries 2 version tags")
        self.refused(*self.repo.push("--tags", "origin"), "Never git push --tags")
        self.assertFalse(self.repo.remote_has("refs/tags/v1.0.1"))
        self.assertFalse(self.repo.remote_has("refs/tags/v1.0.2"))

    def test_a_tag_that_is_not_the_version_is_refused(self):
        # v4.7.313: the tag went on the commit BEFORE the bump.
        self.repo.git("tag", "v1.0.1")              # HEAD still says 1.0.0
        self.refused(*self.repo.push("origin", "v1.0.1"), "version.txt says 1.0.0")
        self.assertFalse(self.repo.remote_has("refs/tags/v1.0.1"))

    def test_a_tag_on_a_commit_that_is_not_on_main_is_refused(self):
        # v4.7.448: released from an unmerged branch, so the next release from main dropped its fix.
        self.repo.git("checkout", "--quiet", "-b", "fix")
        self.repo.commit("1.0.1", "release from a branch")
        self.repo.push("origin", "fix")
        self.repo.git("tag", "v1.0.1")
        self.refused(*self.repo.push("origin", "v1.0.1"), "is not on origin/main")
        self.assertFalse(self.repo.remote_has("refs/tags/v1.0.1"))

    def test_a_rewrite_of_main_is_refused(self):
        self.repo.commit("1.0.0", "second")
        self.repo.push("origin", "main")
        self.repo.git("reset", "--quiet", "--hard", "HEAD~1")
        self.repo.commit("1.0.0", "another second")
        self.refused(*self.repo.push("--force", "origin", "main"), "would rewrite main")

    def test_a_refused_tag_does_not_stop_a_later_good_one(self):
        self.repo.git("tag", "v1.0.1")
        self.refused(*self.repo.push("origin", "v1.0.1"), "version.txt says 1.0.0")
        self.repo.git("tag", "-d", "v1.0.1")
        self.repo.commit("1.0.1", "the bump")
        self.repo.push("origin", "main")
        self.repo.git("tag", "v1.0.1")
        self.allowed(*self.repo.push("origin", "v1.0.1"))


if __name__ == "__main__":
    unittest.main(verbosity=1)
