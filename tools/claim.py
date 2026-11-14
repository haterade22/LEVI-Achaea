"""Claim shared work, so that two parallel sessions do not fix the same thing (CLAUDE.md, Rule A).

    python -B tools/claim.py take <name> --as <you> [--work "<text>"]   # before a fix or a feature
    python -B tools/claim.py take <name> --as <you> --over              # the owner is not in ListAgents
    python -B tools/claim.py ci-fail <step id> --as <you>               # a CI step failed: main or yours?
    python -B tools/claim.py pushed --as <you>                          # right after a push to main
    python -B tools/claim.py release <name> --as <you>                  # the work is on main, or you stop
    python -B tools/claim.py release --all-mine --as <you>              # after a compaction
    python -B tools/claim.py list

Shared work is one problem or one outcome that another session can also start: a red main, a feature,
a bug fix. Two sessions that edit the same file do not do shared work; the rebase handles that. Only a
top-level session claims. A subagent never claims work; it reports a red main to its parent. <you> is
your name as ListAgents shows it.

The claims folder is C:\\Users\\mikew\\source\\repos\\Achaea\\.claims (environment variable LEVI_CLAIMS_DIR
overrides it). It is outside every worktree and outside git, so every session sees the same claims. One
claim is one sub-folder, made with one atomic mkdir: of two sessions that take the same name at the same
time, exactly one wins. The folder holds owner.txt (owner, work, time in UTC).

take: makes the claim, then lists every other claim. Read that list: another session can hold the same
work under another name. TAKEN (exit 1) means that another session owns the work. Then do work that
does not depend on it, or stop and report.

take --over: this script cannot call ListAgents (that is a Claude tool). Check the owner there. An idle
owner is live: leave the claim. If the owner is not in ListAgents, the claim is dead. --over makes your
claim <name>.<you> first, and only then removes the dead folder, so the work is never unclaimed.

ci-fail: fetches origin and reads the latest build.yml run on main (gh run list --workflow build.yml
--branch main --limit 1). It waits while that run is in progress or is for an older commit than
origin/main, at most 6 tries 30 s apart, then says UNKNOWN (exit 2). Main green: the failure is on your
branch: YOURS, no claim. Main red after a push (a main-pushed-* claim exists): the oldest pusher owns it,
no claim. Main red otherwise: it claims main-<step id>. Give the step id exactly as tools/ci_local.py
prints it.

pushed: claims main-pushed-<you>. Release it when the build.yml run of that push is green.

release: removes only a claim whose owner.txt names you.

Exit status: 0 = yours / done, 1 = TAKEN or owned by another session, 2 = refused, NOT RUN or UNKNOWN.
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_ROOT = r"C:\Users\mikew\source\repos\Achaea\.claims"
ENV = "LEVI_CLAIMS_DIR"
NAME = re.compile(r"[A-Za-z0-9_-]+")   # no dot: <name>.<you> is the takeover folder
PUSHED = "main-pushed-"
TRIES, WAIT = 6, 30


def run(args, cwd=ROOT, wait=60):
    """(exit status, stdout) or (None, "") when the program could not run or ran out of time."""
    try:
        done = subprocess.run(args, cwd=cwd, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                              timeout=wait, env=dict(os.environ, GIT_TERMINAL_PROMPT="0"))
    except (OSError, subprocess.TimeoutExpired):
        return None, ""
    return done.returncode, done.stdout.decode("utf-8", "replace")


def stamp():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def claims_root():
    return os.environ.get(ENV) or DEFAULT_ROOT


def root_problem(root, run=run):
    """A reason to refuse the claims folder, or None. A folder inside a git tree hides claims from other trees."""
    parent = os.path.dirname(os.path.abspath(root))
    status, text = run(["git", "-C", parent, "rev-parse", "--is-inside-work-tree"])
    if status == 0 and text.strip() == "true":
        return "%s is inside a git work tree; the claims folder must be outside every tree" % root
    return None


# ---------------------------------------------------------------------------------------------
# the folder
# ---------------------------------------------------------------------------------------------


def write_owner(path, me, work, now):
    tmp = os.path.join(path, "owner.txt.tmp")
    with open(tmp, "w", encoding="utf-8") as fh:
        fh.write("owner: %s\nwork: %s\ntime: %s\n" % (me, " ".join((work or "").split()), now()))
    os.replace(tmp, os.path.join(path, "owner.txt"))


def read_owner(path):
    found = {"owner": "(unknown: no owner.txt yet)", "work": "", "time": ""}
    try:
        with open(os.path.join(path, "owner.txt"), encoding="utf-8") as fh:
            for line in fh:
                key, _, value = line.partition(":")
                if key.strip() in found:
                    found[key.strip()] = value.strip()
    except OSError:
        pass
    return found


def all_folders(root):
    try:
        return sorted(f for f in os.listdir(root) if os.path.isdir(os.path.join(root, f)))
    except OSError:
        return []


def folders_of(root, name):
    """The claim folders of one name: <name>, and <name>.<owner> after a takeover."""
    return [f for f in all_folders(root) if f == name or f.startswith(name + ".")]


def describe(root, folder):
    owner = read_owner(os.path.join(root, folder))
    return "%s  %s  %s  %s" % (folder, owner["owner"], owner["time"] or "?", owner["work"])


def show_others(root, mine, out):
    others = [f for f in all_folders(root) if f != mine]
    if not others:
        out("claim: no other claims.")
        return
    out("claim: the other claims (is one of them the same work?):")
    for folder in others:
        out("  " + describe(root, folder))


def report_taken(root, name, folder, out):
    owner = read_owner(os.path.join(root, folder))
    out("claim: TAKEN by %s since %s: %s" % (owner["owner"], owner["time"] or "?", owner["work"] or folder))
    out("  Do work that does not depend on it, or stop and report.")
    out("  If %s is not in ListAgents, the claim is dead: claim.py take %s --over --as <you>" % (owner["owner"], name))


def bad_names(out, me, *names):
    for name in names:
        if not NAME.fullmatch(name or ""):
            out("claim: REFUSED -- %r is not a claim name (letters, digits, - and _ only)" % name)
            return True
    if not NAME.fullmatch(me or ""):
        out("claim: REFUSED -- %r is not a session name (letters, digits, - and _ only)" % me)
        return True
    return False


# ---------------------------------------------------------------------------------------------
# the commands
# ---------------------------------------------------------------------------------------------


def take(name, me, work="", over=False, root=None, out=print, now=stamp):
    root = root or claims_root()
    if bad_names(out, me, name):
        return 2
    os.makedirs(root, exist_ok=True)
    if over:
        mine = name + "." + me
        try:
            os.mkdir(os.path.join(root, mine))
        except FileExistsError:
            pass
        write_owner(os.path.join(root, mine), me, work, now)
        for folder in folders_of(root, name):
            if folder != mine:
                out("claim: removed the dead claim " + describe(root, folder))
                shutil.rmtree(os.path.join(root, folder), ignore_errors=True)
        out("claim: CLAIMED %s for %s" % (mine, me))
        show_others(root, mine, out)
        return 0
    path = os.path.join(root, name)
    try:
        os.mkdir(path)
    except FileExistsError:
        report_taken(root, name, name, out)
        return 1
    taken_over = [f for f in folders_of(root, name) if f != name]
    if taken_over:
        try:
            os.rmdir(path)
        except OSError:
            pass
        report_taken(root, name, taken_over[0], out)
        return 1
    write_owner(path, me, work, now)
    out("claim: CLAIMED %s for %s" % (name, me))
    show_others(root, name, out)
    return 0


def release(name, me, root=None, out=print):
    root = root or claims_root()
    if bad_names(out, me, name):
        return 2
    found = folders_of(root, name)
    mine = [f for f in found if read_owner(os.path.join(root, f))["owner"] == me]
    for folder in mine:
        shutil.rmtree(os.path.join(root, folder), ignore_errors=True)
        out("claim: RELEASED " + folder)
    if not mine and found:
        out("claim: REFUSED -- not yours: " + describe(root, found[0]))
        return 1
    if not found:
        out("claim: nothing to release: no claim %s" % name)
    return 0


def release_all_mine(me, root=None, out=print):
    root = root or claims_root()
    if bad_names(out, me):
        return 2
    mine = [f for f in all_folders(root) if read_owner(os.path.join(root, f))["owner"] == me]
    for folder in mine:
        shutil.rmtree(os.path.join(root, folder), ignore_errors=True)
        out("claim: RELEASED " + folder)
    if not mine:
        out("claim: %s holds no claims" % me)
    return 0


def pushed(me, root=None, out=print, now=stamp):
    root = root or claims_root()
    if bad_names(out, me):
        return 2
    name = PUSHED + me
    if os.path.isdir(os.path.join(root, name)) and read_owner(os.path.join(root, name))["owner"] == me:
        out("claim: %s is already yours. Release it when the build.yml run of your push is green." % name)
        return 0
    status = take(name, me, work="a push to main: a red build.yml run on main is mine", root=root, out=out, now=now)
    if status == 0:
        out("claim: release it when the build.yml run of your push is green: claim.py release %s --as %s" % (name, me))
    return status


def latest_main_run(run):
    """('green' | 'red' | 'wait', note) for the newest build.yml run on main, or (None, why)."""
    status, _ = run(["git", "-C", ROOT, "fetch", "--quiet", "origin", "main"])
    if status != 0:
        return None, "fetch"
    status, head = run(["git", "-C", ROOT, "rev-parse", "refs/remotes/origin/main"])
    head = head.strip() if status == 0 else ""
    status, text = run(["gh", "run", "list", "--workflow", "build.yml", "--branch", "main", "--limit", "1",
                        "--json", "headSha,status,conclusion"])
    try:
        runs = json.loads(text) if status == 0 else None
    except ValueError:
        runs = None
    if not runs or not head:
        return "wait", "gh gave no build.yml run on main"
    latest = runs[0]
    if latest.get("headSha") != head:
        return "wait", "the latest build.yml run is for %s, origin/main is %s" % (str(latest.get("headSha"))[:10], head[:10])
    if latest.get("status") != "completed":
        return "wait", "the build.yml run of %s is %s" % (head[:10], latest.get("status"))
    return ("green" if latest.get("conclusion") == "success" else "red"), head[:10]


def ci_fail(step, me, root=None, out=print, run=run, sleep=time.sleep, tries=TRIES, wait=WAIT, now=stamp):
    root = root or claims_root()
    if bad_names(out, me, step):
        return 2
    note = ""
    for attempt in range(tries):
        if attempt:
            sleep(wait)
        verdict, note = latest_main_run(run)
        if verdict is None:
            out("claim: NOT RUN -- git fetch origin main failed (offline?). Nothing was checked.")
            return 2
        if verdict != "wait":
            break
    else:
        out("claim: UNKNOWN -- %s after %d tries. Run ci-fail again later; claim nothing yet." % (note, tries))
        return 2
    if verdict == "green":
        out("claim: main is green at %s. YOURS - fix it on your branch, no claim." % note)
        return 0
    pushers = [f for f in all_folders(root) if f.startswith(PUSHED)]
    if pushers:
        oldest = min(pushers, key=lambda f: (read_owner(os.path.join(root, f))["time"] or "~", f))
        owner = read_owner(os.path.join(root, oldest))["owner"]
        if owner == me:
            out("claim: main is RED at %s after your push. It is yours to fix." % note)
            return 0
        out("claim: main is RED at %s after a push by %s (%s). That push owns it: do not fix it." % (note, owner, oldest))
        out("  If %s is not in ListAgents, the claim is dead: claim.py take %s --over --as <you>" % (owner, oldest))
        return 1
    out("claim: main is RED at %s." % note)
    return take("main-" + step, me, work="red main: CI step %s" % step, root=root, out=out, now=now)


def list_claims(root=None, out=print):
    root = root or claims_root()
    folders = all_folders(root)
    if not folders:
        out("claim: no claims in %s" % root)
    for folder in folders:
        out(describe(root, folder))
    return 0


def main(argv=None):
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="command", required=True)
    p_take = sub.add_parser("take", help="claim a fix or a feature")
    p_take.add_argument("name")
    p_take.add_argument("--work", default="", help="one line: what the work is")
    p_take.add_argument("--over", action="store_true", help="the owner is not in ListAgents: take the dead claim")
    p_ci = sub.add_parser("ci-fail", help="a CI step failed: is it main or your branch?")
    p_ci.add_argument("step")
    sub.add_parser("pushed", help="right after a push to main")
    p_rel = sub.add_parser("release", help="remove your claim")
    p_rel.add_argument("name", nargs="?")
    p_rel.add_argument("--all-mine", action="store_true")
    sub.add_parser("list", help="every claim")
    for p in (p_take, p_ci, sub.choices["pushed"], p_rel):
        p.add_argument("--as", dest="me", required=True, help="your name as ListAgents shows it")
    args = ap.parse_args(argv)
    root = claims_root()
    problem = root_problem(root)
    if problem:
        print("claim: REFUSED -- " + problem)
        return 2
    if args.command == "take":
        return take(args.name, args.me, work=args.work, over=args.over, root=root)
    if args.command == "ci-fail":
        return ci_fail(args.step, args.me, root=root)
    if args.command == "pushed":
        return pushed(args.me, root=root)
    if args.command == "release":
        if args.all_mine:
            return release_all_mine(args.me, root=root)
        if not args.name:
            ap.error("release needs a name, or --all-mine")
        return release(args.name, args.me, root=root)
    return list_claims(root=root)


if __name__ == "__main__":
    sys.exit(main())
