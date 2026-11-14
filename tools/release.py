"""Two release steps that only memory held: when a tag may go on, and whether the local package is the release.

    python -B tools/release.py tag-ready 4.7.501     # may v4.7.501 be tagged, and on which commit?
    python -B tools/release.py post [4.7.501]        # after the release build: is muddler_project/build/ that release?

Both commands only read (git refs, the GitHub API through `gh`, two local files). Neither tags,
pushes or downloads: each prints the commands for you to run.

tag-ready. A tag starts the release build, and the updater installs "Latest". A tag has gone on the
commit before the bump (v4.7.313), on a run that had not finished (v4.7.477), and on the wrong
workflow's result (a push starts two workflows; v4.7.484). This command finds the newest commit on
origin/main whose version.txt is the version, takes the `Build & Validate` run of THAT commit by
workflow name, and prints the tag command with the commit spelled out only when that run passed.

post. The maintainer imports the package from muddler_project/build/ in the main checkout. A release
made from a worktree leaves that folder at the old version (skipped 2026-11-03, 11-05, 11-12). This
command reads the version inside Levi_Ataxia.mpackage and inside the loose Levi_Ataxia.xml, and
compares both with the release.

Exit status: 0 = ready / up to date, 1 = not ready / stale, 2 = NOT RUN (git or gh could not answer).
"""
import argparse
import json
import os
import re
import subprocess
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORKFLOW = "Build & Validate"
WALK = 40   # commits of origin/main to look through for the version
VERSION_IN_PACKAGE = re.compile(r"ataxiaVersion = (?:&quot;|\")([0-9][0-9.]*)")


def run(args, cwd=ROOT, wait=60):
    """(exit status, stdout) or (None, "") when the program could not run or ran out of time."""
    try:
        done = subprocess.run(args, cwd=cwd, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                              timeout=wait, env=dict(os.environ, GIT_TERMINAL_PROMPT="0"))
    except (OSError, subprocess.TimeoutExpired):
        return None, ""
    return done.returncode, done.stdout.decode("utf-8", "replace")


def version_key(text):
    found = re.fullmatch(r"v?(\d+(?:\.\d+)*)", (text or "").strip())
    return tuple(int(part) for part in found.group(1).split(".")) if found else None


# ---------------------------------------------------------------------------------------------
# tag-ready
# ---------------------------------------------------------------------------------------------


def commits_at_version(history, version):
    """history: [(sha, version.txt at that commit)] newest first. The leading run whose version is `version`."""
    found = []
    for sha, at in history:
        if at != version:
            break
        found.append(sha)
    return found


def judge_runs(runs):
    """One word for the `Build & Validate` runs of ONE commit: passed, running, failed or none.

    runs: the list `gh run list --json status,conclusion,event` gives. A push starts a run; a re-run after an
    outage adds another. One passed run is enough; otherwise a run still going is "running"; otherwise "failed".
    """
    pushes = [r for r in runs if r.get("event") == "push"]
    if not pushes:
        return "none"
    if any(r.get("status") == "completed" and r.get("conclusion") == "success" for r in pushes):
        return "passed"
    if any(r.get("status") != "completed" for r in pushes):
        return "running"
    return "failed"


def pick_commit(candidates, state_of):
    """(sha or None, [(sha, state)]): the newest candidate whose run passed. state_of(sha) -> judge_runs word or None."""
    seen = []
    for sha in candidates:
        state = state_of(sha)
        seen.append((sha, state))
        if state == "passed":
            return sha, seen
    return None, seen


def tag_ready(version, out=print, root=ROOT):
    if version_key(version) is None:
        out("release: NOT RUN -- %r is not a version (give it as 4.7.501)" % version)
        return 2
    version = version.lstrip("v")
    tag = "v" + version
    status, _ = run(["git", "-C", root, "fetch", "--quiet", "origin", "main"])
    if status != 0:
        out("release: NOT RUN -- git fetch origin main failed (offline?). Nothing was checked.")
        return 2
    status, listing = run(["git", "-C", root, "ls-remote", "--tags", "origin", "refs/tags/v*"])
    if status != 0:
        out("release: NOT RUN -- cannot read the tags on origin.")
        return 2
    remote_tags = set(re.findall(r"refs/tags/(v\d+(?:\.\d+)*)(?:\^\{\})?$", listing, re.M))
    if tag in remote_tags:
        out("release: NOT READY -- %s is already on origin. A tag is never moved: a new release takes the next number." % tag)
        return 1
    higher = sorted((t for t in remote_tags if version_key(t) > version_key(tag)), key=version_key)
    status, log = run(["git", "-C", root, "log", "-%d" % WALK, "--format=%H", "refs/remotes/origin/main"])
    if status != 0 or not log.strip():
        out("release: NOT RUN -- cannot read origin/main.")
        return 2
    history = []
    for sha in log.split():
        status, text = run(["git", "-C", root, "show", "%s:version.txt" % sha])
        history.append((sha, text.strip() if status == 0 else None))
    candidates = commits_at_version(history, version)
    if not candidates:
        out("release: NOT READY -- origin/main is at version %s, not %s. Push the commit that bumps the version first." % (history[0][1], version))
        return 1

    def state_of(sha):
        status, text = run(["gh", "run", "list", "--workflow", WORKFLOW, "--commit", sha, "--json", "status,conclusion,event,databaseId"])
        if status != 0:
            return None
        try:
            return judge_runs(json.loads(text or "[]"))
        except ValueError:
            return None

    sha, seen = pick_commit(candidates, state_of)
    for commit, state in seen:
        out("  %s  %s: %s" % (commit[:10], WORKFLOW, state if state else "NOT checked (gh could not answer)"))
    if sha is None:
        states = {state for _, state in seen}
        if None in states:
            out("release: NOT RUN -- gh could not read the runs. Check `gh auth status` and githubstatus.com, then run this again.")
            return 2
        if "running" in states:
            out("release: NOT READY -- the %s run has not finished. Wait for it; do not tag yet." % WORKFLOW)
        elif states == {"none"}:
            out("release: NOT READY -- no %s run exists yet for a commit at %s. Wait a moment and run this again." % (WORKFLOW, version))
        else:
            out("release: NOT READY -- the %s run FAILED. Do not tag. Correct main, or release the next number." % WORKFLOW)
        return 1
    if higher:
        out("release: WARNING -- origin has a higher tag (%s). A release of %s becomes \"Latest\" with an older version." % (higher[-1], tag))
    out("release: READY -- %s passed for %s, which is on origin/main at version %s. Run:" % (WORKFLOW, sha[:10], version))
    out("  git -C %s tag %s %s && git -C %s push origin %s" % (root, tag, sha, root, tag))
    out("Then watch the tag's own run (it builds the package), and run: python -B tools/release.py post %s" % version)
    return 0


# ---------------------------------------------------------------------------------------------
# post
# ---------------------------------------------------------------------------------------------


def version_in_xml(text):
    found = VERSION_IN_PACKAGE.search(text)
    return found.group(1) if found else None


def version_in_package(path):
    """The ataxiaVersion inside a .mpackage (a zip that holds Levi_Ataxia.xml), or None."""
    try:
        with zipfile.ZipFile(path) as package:
            return version_in_xml(package.read("Levi_Ataxia.xml").decode("utf-8", "replace"))
    except (OSError, KeyError, zipfile.BadZipFile):
        return None


def version_in_loose_xml(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            return version_in_xml(fh.read())
    except OSError:
        return None


def main_checkout(root=ROOT):
    """The first worktree git lists is the main checkout, where the maintainer imports from."""
    status, text = run(["git", "-C", root, "worktree", "list", "--porcelain"])
    found = re.search(r"^worktree (.+)$", text, re.M) if status == 0 else None
    return found.group(1).strip() if found else None


def judge_build_folder(wanted, in_package, in_xml):
    """[problem rows]; empty when both files hold the wanted version."""
    problems = []
    if in_package != wanted:
        problems.append("Levi_Ataxia.mpackage holds %s" % (in_package or "no readable version"))
    if in_xml != wanted:
        problems.append("the loose Levi_Ataxia.xml holds %s" % (in_xml or "no readable version"))
    return problems


def post(version, out=print, root=ROOT):
    if version:
        wanted = version.lstrip("v")
    else:
        status, text = run(["gh", "release", "view", "--json", "tagName"])
        try:
            wanted = json.loads(text)["tagName"].lstrip("v") if status == 0 else None
        except (ValueError, KeyError):
            wanted = None
        if not wanted:
            out("release: NOT RUN -- gh could not name the latest release. Give the version: release.py post 4.7.501")
            return 2
    main = main_checkout(root)
    if not main:
        out("release: NOT RUN -- cannot find the main checkout.")
        return 2
    folder = os.path.join(main, "muddler_project", "build")
    in_package = version_in_package(os.path.join(folder, "Levi_Ataxia.mpackage"))
    in_xml = version_in_loose_xml(os.path.join(folder, "Levi_Ataxia.xml"))
    problems = judge_build_folder(wanted, in_package, in_xml)
    if not problems:
        out("release: UP TO DATE -- %s holds %s in the package and in the loose XML." % (folder, wanted))
        return 0
    out("release: STALE -- the release is %s, but in %s:" % (wanted, folder))
    for row in problems:
        out("  " + row)
    out("The maintainer imports from that folder. Refresh it from the release asset:")
    out("  gh release download v%s --pattern Levi_Ataxia.mpackage --dir \"%s\" --clobber" % (wanted, folder))
    out("  cd \"%s\" && unzip -o Levi_Ataxia.mpackage Levi_Ataxia.xml" % folder)
    out("Then run this again.")
    return 1


def main(argv=None):
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="command", required=True)
    ready = sub.add_parser("tag-ready", help="may this version be tagged, and on which commit?")
    ready.add_argument("version")
    after = sub.add_parser("post", help="is muddler_project/build/ in the main checkout the release?")
    after.add_argument("version", nargs="?")
    args = ap.parse_args(argv)
    if args.command == "tag-ready":
        return tag_ready(args.version)
    return post(args.version)


if __name__ == "__main__":
    sys.exit(main())
