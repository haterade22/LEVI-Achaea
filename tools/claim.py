"""Claim shared work, so that two parallel sessions do not fix the same thing (CLAUDE.md, Rule A).

    C take <claim> --as <you> [--work "<text>"]    # before a fix or a feature
    C take <claim> --over <generation> --as <you>  # the owner is not in ListAgents (TAKEN prints this command)
    C ci-fail <step id> --as <you>                 # a CI step failed: main or yours? Run it before you diagnose
    C pushed --as <you> [--sha <commit>]           # right after a push to main
    C release <claim> --as <you>                   # the work is on main, or you stop
    C list [--as <you>]                            # every claim, or yours (after a compaction)

C is `C:/Python314/python.exe -B tools/claim.py`, the same text in Git Bash and in PowerShell. <you> is your
name as ListAgents shows it. <claim> is a short name of the outcome: letters, digits, - and _; the script
makes it lower case, so Fix-X and fix-x are one claim.

Shared work is one problem or one outcome that another session can also start: a red main, a feature,
a bug fix. Two sessions that edit the same file do not do shared work; the rebase handles that. Only a
top-level session claims. A subagent never claims work; it reports a red main to its parent.

Each result ends with a NEXT: line. Do what it says.

The claims are rows in one SQLite file, claims.db, in C:\\Users\\mikew\\source\\repos\\Achaea\\.claims (the
environment variable LEVI_CLAIMS_DIR overrides the folder). The folder is outside every worktree and outside
git, so every session sees the same claims. Each command is one transaction: two commands never interleave,
and a command that fails changes nothing. Each change of owner gives the claim a new generation number.

take: makes the claim, then lists every other claim. Read that list. If another claim is the same outcome
under another name, yours is the later one: release it and treat the other claim as TAKEN.

TAKEN (exit 1): another session owns the work. The script puts you on the waiter list of the claim. Look for
the owner in ListAgents (the script cannot: ListAgents is a Claude tool). An idle owner is live: message it,
then do work that does not depend on the claim, or end your turn; its reply wakes you. Never take the claim
of a listed owner. If the owner is not listed, the claim is dead: run the takeover command that TAKEN printed.

take --over <generation>: takes a dead claim, but only if its generation is still the one you saw. If
another session took the claim first, the generation changed and you get TAKEN. Of two takers, one wins.

The owner's duties: when a session asks about your claim, reply at once: you work on it, or you release it
and say so. release prints the waiter list: message each waiter that the claim is free.

ci-fail: fetches origin and reads the latest build.yml run on main (gh run list --workflow build.yml
--branch main --limit 1). It waits while that run is in progress or is for an older commit than origin/main,
30 s between tries and 240 s in all. Main green: YOURS, the failure is on your branch, no claim. Main red:
a session that already holds a main-<step> claim fixes it; if there is none, the first main-pushed-* claim
owns it; if there is none, the script claims main-<step id> for you. Give the step id exactly as
tools/ci_local.py prints it. NOT RUN or UNKNOWN (exit 2) means that main was not read: git or gh is missing,
gh is not logged in, the network is down, or the run was cancelled. Then do not diagnose the step: do work
that does not depend on it, or stop and report.

pushed: claims main-pushed-<first 10 characters of the commit>, from HEAD or from --sha. Each push is its
own claim. Release a push claim only when the build.yml run of that commit, or of your fix for it, is green.

release: removes only a claim that you own, and says RELEASED only after the store confirms it.

After a compaction: run list --as <you>. Keep each claim that you still work on and each push that is not
green. Release the others, one by one.

Exit status: 0 = yours / done, 1 = TAKEN or owned by another session, 2 = refused, NOT RUN or UNKNOWN.
"""
import argparse
import contextlib
import functools
import json
import os
import re
import sqlite3
import subprocess
import sys
import time
from datetime import datetime, timezone

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_ROOT = r"C:\Users\mikew\source\repos\Achaea\.claims"
ENV = "LEVI_CLAIMS_DIR"
DB = "claims.db"
COMMAND = "C:/Python314/python.exe -B tools/claim.py"
KEY = re.compile(r"[a-z0-9_-]+")
SESSION = re.compile(r"[A-Za-z0-9_-]+")
SHA = re.compile(r"[0-9a-f]{10,40}")
AUTH = re.compile(r"auth|401|credential|log ?in", re.I)
MAIN, PUSHED = "main-", "main-pushed-"
WAIT, LIMIT, CALL = 30, 240, 20   # seconds: between tries, for all tries of ci-fail, for one git or gh call
BUSY = 10                         # seconds that a command waits for another command's transaction
MISSING = "the program is not installed or not on PATH"


def run(args, cwd=ROOT, wait=CALL):
    """(exit status, stdout, first line of stderr). Status None: the program did not run; the text says why."""
    try:
        done = subprocess.run(args, cwd=cwd, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              timeout=wait, env=dict(os.environ, GIT_TERMINAL_PROMPT="0", LC_ALL="C"))
    except FileNotFoundError:
        return None, "", MISSING
    except (OSError, subprocess.TimeoutExpired) as err:
        return None, "", type(err).__name__
    err = done.stderr.decode("utf-8", "replace").strip().splitlines()
    return done.returncode, done.stdout.decode("utf-8", "replace"), (err[0][:200] if err else "")


def why(status, err):
    return err or "exit %s" % status


def stamp():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def claims_root():
    return os.environ.get(ENV) or DEFAULT_ROOT


def root_problem(root, run=run):
    """A reason to refuse the claims folder, or None. A folder inside a git tree hides claims from other trees."""
    if not os.path.isabs(root):
        return "%s is not an absolute path; every session must see the same claims folder" % root
    at = os.path.abspath(root)
    while not os.path.isdir(at) and os.path.dirname(at) != at:
        at = os.path.dirname(at)   # git is asked at the nearest folder that exists; the check makes nothing
    status, text, err = run(["git", "-C", at, "rev-parse", "--is-inside-work-tree"])
    if status == 0 and text.strip() == "true":
        return "%s is inside a git work tree; the claims folder must be outside every tree" % root
    if status is not None and status != 0 and "not a git repository" in err:
        return None
    return "git could not say if %s is outside every work tree (%s)" % (root, why(status, err))


# ---------------------------------------------------------------------------------------------
# the store
# ---------------------------------------------------------------------------------------------


@contextlib.contextmanager
def store(root):
    """One transaction on <root>/claims.db. An exception inside it changes nothing."""
    os.makedirs(root, exist_ok=True)
    db = sqlite3.connect(os.path.join(root, DB), timeout=BUSY, isolation_level=None)
    db.row_factory = sqlite3.Row
    try:
        db.execute("BEGIN IMMEDIATE")
        db.execute("CREATE TABLE IF NOT EXISTS claims (key TEXT PRIMARY KEY, gen INTEGER NOT NULL, owner TEXT NOT NULL,"
                   " work TEXT NOT NULL, time TEXT NOT NULL, waiters TEXT NOT NULL)")
        db.execute("CREATE TABLE IF NOT EXISTS counter (id INTEGER PRIMARY KEY CHECK (id = 1), gen INTEGER NOT NULL)")
        db.execute("INSERT OR IGNORE INTO counter (id, gen) VALUES (1, 0)")
        yield db
        db.execute("COMMIT")
    except BaseException:
        if db.in_transaction:
            db.execute("ROLLBACK")
        raise
    finally:
        db.close()


def guarded(command):
    """A store that does not answer is exit 2, never a success and never an empty list."""
    @functools.wraps(command)
    def safe(*args, **kwargs):
        try:
            return command(*args, **kwargs)
        except (sqlite3.Error, OSError) as err:
            out = kwargs.get("out", print)
            out("claim: REFUSED -- the claims store in %s did not answer (%s: %s). This command changed nothing."
                % (kwargs.get("root") or claims_root(), type(err).__name__, err))
            out("NEXT: run the command again. If it fails again, stop and report. Do not start the work.")
            return 2
    return safe


def row(db, key):
    return db.execute("SELECT * FROM claims WHERE key = ?", (key,)).fetchone()


def rows(db):
    """Every claim, the first one made first. A takeover keeps the place of the claim."""
    return db.execute("SELECT * FROM claims ORDER BY rowid").fetchall()


def next_gen(db):
    db.execute("UPDATE counter SET gen = gen + 1 WHERE id = 1")
    return db.execute("SELECT gen FROM counter WHERE id = 1").fetchone()[0]


def claims_now(root):
    with store(root) as db:
        return [dict(r) for r in rows(db)]


def claim_in(db, key, me, work, over, now):
    """Take, or take over, inside one transaction: ('new' | 'mine' | 'over' | 'taken', the claim as it was)."""
    held = row(db, key)
    if held is None:
        db.execute("INSERT INTO claims (key, gen, owner, work, time, waiters) VALUES (?, ?, ?, ?, ?, '')",
                   (key, next_gen(db), me, work, now()))
        return "new", None
    if held["owner"] == me:
        return "mine", held
    if over is not None and over == held["gen"]:
        waiters = " ".join(w for w in held["waiters"].split() if w != me)
        db.execute("UPDATE claims SET gen = ?, owner = ?, work = ?, time = ?, waiters = ? WHERE key = ?",
                   (next_gen(db), me, work or held["work"], now(), waiters, key))
        return "over", held
    if me not in held["waiters"].split():
        db.execute("UPDATE claims SET waiters = ? WHERE key = ?", ((held["waiters"] + " " + me).strip(), key))
    return "taken", held


def describe(claim):
    return "%s  %s  %s  generation %d  %s" % (claim["key"], claim["owner"], claim["time"], claim["gen"], claim["work"])


def say_taken(held, me, out):
    out("claim: TAKEN -- " + describe(held))
    out("  You are on its waiter list: its owner messages you when it releases the claim.")
    out("NEXT: look for %s in ListAgents. If it is listed (an idle owner is live), message it, then do work that does not "
        "depend on this claim, or end your turn. If it is not listed, the claim is dead: run `%s take %s --over %d --as %s`"
        % (held["owner"], COMMAND, held["key"], held["gen"], me))


def bad_names(out, me, *keys):
    for key in keys:
        if not KEY.fullmatch(key or ""):
            out("claim: REFUSED -- %r is not a claim name (letters, digits, - and _ only)" % key)
            break
    else:
        if SESSION.fullmatch(me or ""):
            return False
        out("claim: REFUSED -- %r is not a session name (letters, digits, - and _ only)" % me)
    out("NEXT: run the command again with a valid name.")
    return True


# ---------------------------------------------------------------------------------------------
# the commands
# ---------------------------------------------------------------------------------------------


@guarded
def take(key, me, work="", over=None, root=None, out=print, now=stamp, then=None):
    root = root or claims_root()
    key = (key or "").lower()
    if bad_names(out, me, key):
        return 2
    with store(root) as db:
        how, held = claim_in(db, key, me, " ".join((work or "").split()), over, now)
        others = [r for r in rows(db) if r["key"] != key]
    if how == "taken":
        if over is not None:
            out("claim: %s changed after you looked: it is generation %d now, not %d." % (key, held["gen"], over))
        say_taken(held, me, out)
        return 1
    if how == "over":
        out("claim: took over the dead claim of %s" % held["owner"])
    if how == "mine":
        out("claim: %s is already yours (since %s)" % (key, held["time"]))
    else:
        out("claim: CLAIMED %s for %s" % (key, me))
    if then:
        out(then)
    elif others:
        out("claim: the other claims:")
        for other in others:
            out("  " + describe(other))
        out("NEXT: read the other claims. If one of them is the same outcome as yours, run `%s release %s --as %s` and "
            "treat that claim as TAKEN. If none is, do the work." % (COMMAND, key, me))
    else:
        out("NEXT: no other claims. Do the work. Release the claim when the work is on main, or when you stop.")
    return 0


@guarded
def release(key, me, root=None, out=print):
    root = root or claims_root()
    key = (key or "").lower()
    if bad_names(out, me, key):
        return 2
    with store(root) as db:
        held = row(db, key)
        if held is not None and held["owner"] == me:
            done = db.execute("DELETE FROM claims WHERE key = ? AND owner = ?", (key, me)).rowcount
            if done != 1:
                raise sqlite3.Error("the delete of %s removed %d rows" % (key, done))
    if held is None:
        out("claim: nothing to release: no claim %s" % key)
    elif held["owner"] != me:
        out("claim: REFUSED -- not yours: " + describe(held))
        out("NEXT: leave it. Only its owner releases it.")
        return 1
    else:
        out("claim: RELEASED " + key)   # after the commit: the store confirmed the removal
        if held["waiters"]:
            out("NEXT: message each waiter that %s is free: %s" % (key, ", ".join(held["waiters"].split())))
            return 0
    out("NEXT: nothing more for this claim.")
    return 0


@guarded
def pushed(me, sha=None, root=None, out=print, run=run, now=stamp):
    root = root or claims_root()
    if bad_names(out, me):
        return 2
    seen = ""
    if not sha:
        status, text, err = run(["git", "-C", ROOT, "rev-parse", "HEAD"])
        sha, seen = (text.strip(), "") if status == 0 else ("", " (git rev-parse HEAD: %s)" % why(status, err))
    sha = sha.lower()
    if not SHA.fullmatch(sha):
        out("claim: REFUSED -- no commit to claim: %r is not a commit id%s" % (sha, seen))
        out("NEXT: run pushed again with --sha <the full id of the commit that you pushed>.")
        return 2
    key = PUSHED + sha[:10]
    return take(key, me, work="a push to main, commit %s: a red build.yml run of it is mine" % sha, root=root, out=out,
                now=now, then="NEXT: watch the build.yml run of %s. Only when it is green, run `%s release %s --as %s`. "
                              "If it is red, run ci-fail." % (sha[:10], COMMAND, key, me))


def latest_main_run(run):
    """('green' | 'red', short sha), ('wait', why) or ('stop', the NOT RUN or UNKNOWN line)."""
    status, _, err = run(["git", "-C", ROOT, "fetch", "--quiet", "origin", "main"])
    if status != 0:
        return "stop", "NOT RUN -- git fetch origin main failed (%s). Nothing was checked." % why(status, err)
    status, head, err = run(["git", "-C", ROOT, "rev-parse", "refs/remotes/origin/main"])
    head = head.strip()
    if status != 0 or not head:
        return "stop", "NOT RUN -- git rev-parse origin/main failed (%s). Nothing was checked." % why(status, err)
    status, text, err = run(["gh", "run", "list", "--workflow", "build.yml", "--branch", "main", "--limit", "1",
                             "--json", "headSha,status,conclusion"])
    if status is None and err == MISSING:
        return "stop", "UNKNOWN -- gh did not run: %s. The state of main was not read." % err
    if status != 0:
        if status is not None and AUTH.search(err):
            return "stop", "UNKNOWN -- gh is not logged in (%s). The state of main was not read." % err
        return "wait", "gh failed (%s)" % why(status, err)
    try:
        runs = json.loads(text)
    except ValueError:
        runs = None
    if not runs:
        return "wait", "gh gave no build.yml run on main"
    latest = runs[0]
    if latest.get("headSha") != head:
        return "wait", "the latest build.yml run is for %s, origin/main is %s" % (str(latest.get("headSha"))[:10], head[:10])
    if latest.get("status") != "completed":
        return "wait", "the build.yml run of %s is %s" % (head[:10], latest.get("status"))
    if latest.get("conclusion") == "success":
        return "green", head[:10]
    if latest.get("conclusion") in ("failure", "timed_out"):
        return "red", head[:10]
    return "stop", ("UNKNOWN -- the build.yml run of %s ended as %r: that is not a pass and not a failure of the code."
                    % (head[:10], latest.get("conclusion")))


@guarded
def ci_fail(step, me, root=None, out=print, run=run, sleep=time.sleep, clock=time.monotonic, wait=WAIT, limit=LIMIT,
            now=stamp):
    root = root or claims_root()
    step = (step or "").lower()
    if bad_names(out, me, step):
        return 2
    end = clock() + limit
    while True:
        verdict, note = latest_main_run(run)
        if verdict != "wait":
            break
        if clock() + wait > end:
            verdict, note = "stop", "UNKNOWN -- %s, after %d s of tries." % (note, limit)
            break
        sleep(wait)
    if verdict == "stop":
        out("claim: " + note)
        out("NEXT: do not diagnose step %s yet. Do work that does not depend on it, or stop and report. "
            "Run ci-fail again when git and gh answer." % step)
        return 2
    if verdict == "green":
        out("claim: main is green at %s. YOURS - fix it on your branch, no claim." % note)
        out("NEXT: fix step %s on your branch." % step)
        return 0
    with store(root) as db:
        claims = rows(db)
        own = next((r for r in claims if r["key"] == MAIN + step and r["owner"] == me), None)
        fixer = next((r for r in claims if not r["key"].startswith(PUSHED) and r["key"].startswith(MAIN)
                      and r["owner"] != me), None)
        pusher = next((r for r in claims if r["key"].startswith(PUSHED)), None)
        key = (own or fixer or pusher or {"key": MAIN + step})["key"]
        how, held = claim_in(db, key, me, "red main: CI step %s" % step, None, now)
    out("claim: main is RED at %s." % note)
    if how == "taken":
        out("claim: %s" % ("the session that pushed owns the red main." if key.startswith(PUSHED)
                           else "another session already fixes the red main."))
        say_taken(held, me, out)
        return 1
    if key.startswith(PUSHED):
        out("claim: it follows your push (%s). It is yours to fix." % key)
        out("NEXT: fix main. Release %s only when the build.yml run of your fix is green." % key)
        return 0
    out("claim: %s" % ("%s is already yours" % key if how == "mine" else "CLAIMED %s for %s" % (key, me)))
    out("NEXT: diagnose and fix step %s on main. Release %s when main is green." % (step, key))
    return 0


@guarded
def list_claims(me=None, root=None, out=print):
    root = root or claims_root()
    claims = [c for c in claims_now(root) if me is None or c["owner"] == me]
    if not claims:
        out("claim: %s" % ("%s holds no claims" % me if me else "no claims in %s" % root))
    for found in claims:
        out(describe(found) + ("  waiters: " + found["waiters"] if found["waiters"] else ""))
    return 0


def main(argv=None):
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="command", required=True)
    p_take = sub.add_parser("take", help="claim a fix or a feature")
    p_take.add_argument("claim")
    p_take.add_argument("--work", default="", help="one line: what the work is")
    p_take.add_argument("--over", type=int, metavar="GENERATION",
                        help="the owner is not in ListAgents: take the dead claim, if it still has this generation")
    p_ci = sub.add_parser("ci-fail", help="a CI step failed: is it main or your branch?")
    p_ci.add_argument("step")
    p_push = sub.add_parser("pushed", help="right after a push to main")
    p_push.add_argument("--sha", help="the commit that you pushed (default: HEAD of this tree)")
    p_rel = sub.add_parser("release", help="remove your claim")
    p_rel.add_argument("claim")
    p_list = sub.add_parser("list", help="every claim, or with --as only yours")
    for p in (p_take, p_ci, p_push, p_rel, p_list):
        p.add_argument("--as", dest="me", required=p is not p_list, help="your name as ListAgents shows it")
    args = ap.parse_args(argv)
    root = claims_root()
    problem = root_problem(root)
    if problem:
        print("claim: REFUSED -- " + problem)
        print("NEXT: stop and report. Do not start the work.")
        return 2
    if args.command == "take":
        return take(args.claim, args.me, work=args.work, over=args.over, root=root)
    if args.command == "ci-fail":
        return ci_fail(args.step, args.me, root=root)
    if args.command == "pushed":
        return pushed(args.me, sha=args.sha, root=root)
    if args.command == "release":
        return release(args.claim, args.me, root=root)
    return list_claims(me=args.me, root=root)


if __name__ == "__main__":
    sys.exit(main())
