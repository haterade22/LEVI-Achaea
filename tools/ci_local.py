"""Run CI's validate job on this machine: one verdict for each step, PASS, FAIL or NOT RUN.

    python -B tools/ci_local.py            # every step (about 80 s). The check before a push to main.
    python -B tools/ci_local.py --quick    # the fast steps only (about 15 s)
    python -B tools/ci_local.py --only rules unit
    python -B tools/ci_local.py --list     # the steps and what each one proves

Since 2026-11-11 work goes straight to main with no pull request, so this run is the ONLY check
before main. v4.7.484 was stopped on its pull request by a stale generated page after a partial
local run; with no pull request that failure lands on main and holds the release tag. The step
list lives in tools/ci_steps.json; tools/test_ci_local.py fails when a step of build.yml's
validate job has no row there, or a row has no step.

Verdicts. PASS: the step ran and exited 0. FAIL: it ran and found a problem. NOT RUN: a selected
step could not run (this interpreter lacks lupa or yaml, or the step exited 2). A step that did
not run is never counted as a pass. --quick and --only leave steps out; the run names them.

Exit status: 1 if a selected step FAILED, else 2 if a selected step could NOT RUN, else 0.
"Ready to push: YES" needs a full run (no --quick, no --only), every step PASS, and a working
tree equal to HEAD: the run tests the files on disk, and a push carries only what is committed.

Use the interpreter that has lupa (Lua 5.1) and pyyaml. Every step runs with that same interpreter.
This run does not cover: Linux path behaviour, CI's own Python and Lua binaries, the live game,
and the CI run on main itself.
"""
import argparse
import glob
import json
import locale
import os
import re
import subprocess
import sys
import tempfile
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STEPS_FILE = os.path.join(ROOT, "tools", "ci_steps.json")
PASS, FAIL, NOT_RUN = "PASS", "FAIL", "NOT RUN"
TAIL = 25          # rows of a step's output shown when it did not pass
REMOTE_WAIT = 20   # seconds for the one network read (the tags on origin)
CI_PYTHON = (3, 12)   # ubuntu-latest's python3 when this was written; a newer local Python gets a note


def load_table(path=STEPS_FILE):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def can_import(name):
    """Whether THIS interpreter has the module. lupa means lupa with Lua 5.1, which is what Mudlet runs."""
    try:
        if name == "lupa":
            import lupa.lua51  # noqa: F401
        else:
            __import__(name)
        return True
    except ImportError:
        return False


# ---------------------------------------------------------------------------------------------
# Built-in steps. Each returns (verdict, one line; more rows may follow after a newline).
# ---------------------------------------------------------------------------------------------


def lua_files(root):
    """What CI's `find src_new -name '*.lua' -type f` lists. A walk, so a '[' in the tree's path cannot hide files."""
    return sorted(os.path.join(folder, name) for folder, _, names in os.walk(os.path.join(root, "src_new"))
                  for name in names if name.endswith(".lua"))


def lua_syntax(root):
    """CI runs `luac5.1 -p` on each file. loadstring in lupa's Lua 5.1 compiles the same chunk without running it.

    Lua 5.1's lexer asks the C library which bytes are letters. luac5.1 runs in the C locale; Python starts in the
    user's, where a byte such as 0xE9 is a letter and would compile as part of a name. So the scan runs in the C locale.
    """
    import lupa.lua51 as lupa
    files = lua_files(root)
    if not files:
        return NOT_RUN, "no .lua file under src_new"
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    # The message can hold a raw byte of the file (a BOM, a smart quote); make it ASCII in Lua, or lupa cannot hand it over.
    compile_only = lua.eval(r"function(source, name) local fn, err = loadstring(source, name) "
                            r"return err and (err:gsub('[\128-\255]', '?')) end")
    bad = []
    before = locale.setlocale(locale.LC_CTYPE)
    locale.setlocale(locale.LC_CTYPE, "C")
    try:
        for path in files:
            with open(path, "rb") as fh:
                err = compile_only(fh.read(), "@" + os.path.relpath(path, root).replace(os.sep, "/"))
            if err:
                bad.append(err if isinstance(err, str) else err.decode("ascii", "replace"))
    finally:
        locale.setlocale(locale.LC_CTYPE, before)
    if bad:
        return FAIL, "%d of %d files have a syntax error:\n%s" % (len(bad), len(files), "\n".join(bad[:TAIL]))
    return PASS, "%d files" % len(files)


def read_versions(root):
    """The three places the version lives, and whether CHANGELOG.md has a heading for it."""
    with open(os.path.join(root, "version.txt"), encoding="utf-8") as fh:
        v_txt = fh.read().strip()
    with open(os.path.join(root, "muddler_project", "mfile"), encoding="utf-8") as fh:
        v_mfile = str(json.load(fh).get("version", "")).strip()
    with open(os.path.join(root, "src_new", "scripts", "_groups.yaml"), encoding="utf-8") as fh:
        # Every match, as CI's grep takes them: two assignments are a mismatch there, so they are one here.
        v_yaml = " and ".join(re.findall(r'ataxiaVersion = \\"([0-9][0-9.]*)', fh.read()))
    with open(os.path.join(root, "CHANGELOG.md"), encoding="utf-8") as fh:
        heading = re.search(r"^## \d{4}-\d{2}-\d{2} - v%s[: ]" % re.escape(v_txt), fh.read(), re.M)
    return v_txt, v_mfile, v_yaml, bool(heading)


def version(root):
    v_txt, v_mfile, v_yaml, heading = read_versions(root)
    line = "version.txt %s, mfile %s, _groups.yaml %s" % (v_txt or "?", v_mfile or "?", v_yaml or "?")
    if not v_txt or v_txt != v_mfile or v_txt != v_yaml:
        return FAIL, line + ": the three must match"
    if not heading:
        return FAIL, line + "; CHANGELOG.md has no heading '## <date> - v%s: <title>'" % v_txt
    return PASS, line + ", CHANGELOG heading present"


def yaml_files(root):
    import yaml
    files = sorted(glob.glob(os.path.join(glob.escape(root), "src_new", "**", "_groups.yaml"), recursive=True))
    if not files:
        return NOT_RUN, "no _groups.yaml under src_new"
    bad = []
    for path in files:
        try:
            with open(path, encoding="utf-8") as fh:
                yaml.safe_load(fh)
        except yaml.YAMLError as exc:
            bad.append("%s: %s" % (os.path.relpath(path, root), exc))
    if bad:
        return FAIL, "\n".join(bad)
    return PASS, "%d files" % len(files)


BUILTINS = {"lua_syntax": lua_syntax, "version": version, "yaml": yaml_files}


# ---------------------------------------------------------------------------------------------
# One step
# ---------------------------------------------------------------------------------------------


def last_line(text):
    rows = [row for row in text.splitlines() if row.strip()]
    return rows[-1].strip() if rows else ""


def run_step(step, root=ROOT, python=sys.executable, importable=can_import):
    """(verdict, one line, full output). Never raises: a step that blows up here is a FAIL of that step."""
    lacking = [name for name in step.get("needs", []) if not importable(name)]
    if lacking:
        return NOT_RUN, "needs %s, which %s cannot import" % (" and ".join(lacking), python), ""
    if "builtin" in step:
        try:
            verdict, line = BUILTINS[step["builtin"]](root)
        except Exception as exc:  # a missing file, a bad JSON, a wrong encoding: report it against this step
            return FAIL, "%s: %s" % (type(exc).__name__, exc), ""
        first, _, rest = line.partition("\n")
        return verdict, first, rest
    env = dict(os.environ, PYTHONIOENCODING="utf-8")
    try:
        done = subprocess.run([python, "-B"] + list(step["argv"]), cwd=root, env=env, stdin=subprocess.DEVNULL,
                              stdout=subprocess.PIPE, stderr=subprocess.STDOUT, encoding="utf-8", errors="replace")
    except OSError as exc:
        return NOT_RUN, "could not start: %s" % exc, ""
    if done.returncode == 0:
        return PASS, last_line(done.stdout), done.stdout
    if done.returncode == 2:   # the tools' contract: 2 = could not run (no lupa, nothing to check)
        return NOT_RUN, "exit 2: " + last_line(done.stdout), done.stdout
    return FAIL, "exit %d: %s" % (done.returncode, last_line(done.stdout)), done.stdout


def select(steps, quick=False, only=None):
    """[(step, reason it is left out or None)] in table order."""
    chosen = []
    for step in steps:
        if only is not None:
            chosen.append((step, None if step["id"] in only else "not named by --only"))
        elif quick and not step.get("quick"):
            chosen.append((step, "not part of --quick"))
        else:
            chosen.append((step, None))
    return chosen


def run_all(chosen, root=ROOT, python=sys.executable, importable=can_import, out=print):
    """Run every selected step; never stop at the first failure. Returns [(step, verdict, line, left_out)]."""
    results = []
    for step, left_out in chosen:
        if left_out:
            results.append((step, NOT_RUN, left_out, True))
            continue
        began = time.time()
        verdict, line, output = run_step(step, root, python, importable)
        out("%-8s %-17s %5.1fs  %s" % (verdict, step["id"], time.time() - began, line[:150]))
        if verdict != PASS and output.strip():
            for row in output.rstrip().splitlines()[-TAIL:]:
                out("         | " + row)
        results.append((step, verdict, line, False))
    return results


def exit_status(results):
    """1 if a selected step failed, else 2 if a selected step could not run, else 0. Left-out steps do not count."""
    ran = [verdict for _, verdict, _, left_out in results if not left_out]
    if FAIL in ran:
        return 1
    if NOT_RUN in ran or not ran:
        return 2
    return 0


def ready(results):
    """Every step of the table ran and passed. (main() also wants the working tree to equal HEAD.)"""
    return bool(results) and all(verdict == PASS and not left_out for _, verdict, _, left_out in results)


def ready_line(results, dirty):
    """The last verdict row. dirty: the rows of `git status --porcelain`, or None when git could not say."""
    if not ready(results):
        ran = [verdict for _, verdict, _, left_out in results if not left_out]
        why = "a step failed" if FAIL in ran else "a step could not run" if NOT_RUN in ran else "this was not a full run"
        return "Ready to push: NO (%s)" % why
    if dirty is None:
        return "Ready to push: NO (every step passed, but git could not say whether the tree equals HEAD)"
    if dirty:
        return ("Ready to push: NOT YET (every step passed on the files on disk, but %d differ from HEAD or are untracked. "
                "A push carries only what is committed: commit them, then check that no new file is left out)" % len(dirty))
    return "Ready to push: YES"


# ---------------------------------------------------------------------------------------------
# The header: where this run is, and whether the version is behind the remote
# ---------------------------------------------------------------------------------------------


def git_run(root, *args, wait=None):
    """(exit status, stdout) of a git command, or (None, "") when it could not run or ran out of time.

    stdout goes to a file, not a pipe: Git for Windows' `cmd\\git.exe` is a wrapper, and a pipe held open by the
    real git under it would make the time limit wait for the whole command.
    """
    env = dict(os.environ, GIT_TERMINAL_PROMPT="0")
    try:
        with tempfile.TemporaryFile() as out:
            proc = subprocess.Popen(["git", "-C", root] + list(args), stdin=subprocess.DEVNULL, stdout=out,
                                    stderr=subprocess.DEVNULL, env=env)
            try:
                status = proc.wait(timeout=wait)
            except subprocess.TimeoutExpired:
                proc.kill()
                return None, ""
            out.seek(0)
            return status, out.read().decode("utf-8", "replace")
    except OSError:
        return None, ""


def git(root, *args, wait=None):
    """The command's output, stripped at the right, or None when it failed."""
    status, text = git_run(root, *args, wait=wait)
    return text.rstrip() if status == 0 else None


def tree_state(root):
    """The rows of `git status --porcelain` (untracked files included, ignored ones not), or None when git cannot say."""
    text = git(root, "status", "--porcelain")
    return None if text is None else [row for row in text.splitlines() if row.strip()]


def version_key(text):
    """'v4.7.500' or '4.7.500' -> (4, 7, 500); None when it is not a version."""
    found = re.fullmatch(r"v?(\d+(?:\.\d+)*)", (text or "").strip())
    return tuple(int(part) for part in found.group(1).split(".")) if found else None


def top_tag(ls_remote_text):
    """The highest v tag in `git ls-remote --tags` output, as text, or None."""
    best = None
    for row in (ls_remote_text or "").splitlines():
        found = re.search(r"refs/tags/(v\d+(?:\.\d+)*)(?:\^\{\})?$", row.strip())
        if found and (best is None or version_key(found.group(1)) > version_key(best)):
            best = found.group(1)
    return best


def tag_commit(ls_remote_text, tag):
    """The commit a tag names in `git ls-remote --tags` output: the peeled ^{} row of an annotated tag when there is one."""
    plain = peeled = None
    for row in (ls_remote_text or "").splitlines():
        parts = row.split()
        if len(parts) == 2 and parts[1] == "refs/tags/%s^{}" % tag:
            peeled = parts[0]
        elif len(parts) == 2 and parts[1] == "refs/tags/" + tag:
            plain = parts[0]
    return peeled or plain


def version_notes(local, tag, main, tag_in_tree=None, main_in_tree=None):
    """Warnings for the header. Releases have lost their number to another session (2026-10-23, 11-03, 11-11, 11-13).

    tag_in_tree / main_in_tree: whether the top tag's commit / origin/main is an ancestor of HEAD (None = not known).
    """
    notes = []
    here = version_key(local)
    if here is None:
        return ["WARNING: version.txt does not hold a version"]
    if tag and version_key(tag) > here:
        notes.append("WARNING: origin has tag %s, above this tree's version.txt (%s). Rebase before a release." % (tag, local))
    elif tag and version_key(tag) == here and tag_in_tree is False:
        notes.append("WARNING: origin has tag %s on a commit that is not in this tree. If this tree bumped to %s, "
                     "that number is taken: rebase and take the next one." % (tag, local))
    if main and version_key(main) and version_key(main) > here:
        notes.append("WARNING: origin/main (as last fetched) is at %s, above this tree (%s). Fetch and rebase." % (main, local))
    elif main and main_in_tree is False:
        notes.append("NOTE: origin/main (as last fetched) has commits this tree does not have. Rebase before the push; "
                     "if this tree bumps the version, check that the number is still free.")
    return notes


def is_ancestor(root, commit):
    """True / False, or None when there is nothing to compare. An unknown commit is not in this tree: False."""
    if not commit:
        return None
    status, _ = git_run(root, "merge-base", "--is-ancestor", commit, "HEAD")
    if status is None:
        return None
    return status == 0


def header(root, python, remote=True, dirty=None, out=print):
    out("tree        %s" % root)
    out("branch      %s @ %s" % (git(root, "rev-parse", "--abbrev-ref", "HEAD") or "?",
                                 git(root, "rev-parse", "--short", "HEAD") or "?"))
    if dirty is None:
        out("git         NOT checked (git could not report the state of this tree)")
    elif dirty:
        out("git         %d files differ from HEAD or are untracked; the steps test the files on disk" % len(dirty))
    else:
        out("git         clean: the files on disk are the commit")
    out("python      %s %d.%d (lupa/Lua 5.1: %s, yaml: %s)" % (python, sys.version_info[0], sys.version_info[1],
                                                               "yes" if can_import("lupa") else "NO",
                                                               "yes" if can_import("yaml") else "NO"))
    if sys.version_info[:2] > CI_PYTHON:
        out("            NOTE: CI runs python3 %d.%d. A feature newer than that in tools/*.py passes here and fails there."
            % CI_PYTHON)
    try:
        with open(os.path.join(root, "version.txt"), encoding="utf-8") as fh:
            local = fh.read().strip()
    except (OSError, UnicodeError):
        local = ""
    listing = git(root, "ls-remote", "--tags", "origin", "refs/tags/v*", wait=REMOTE_WAIT) if remote else None
    tag = top_tag(listing)
    main = git(root, "show", "origin/main:version.txt")
    main = main.strip() if main else main
    out("version     this tree %s | top tag on origin %s | origin/main as last fetched %s" % (
        local or "?", tag or ("NOT checked" if remote else "not asked"), main or "NOT checked"))
    tag_in_tree = is_ancestor(root, tag_commit(listing, tag)) if tag else None
    main_in_tree = is_ancestor(root, "refs/remotes/origin/main") if main else None
    for note in version_notes(local, tag, main, tag_in_tree, main_in_tree):
        out(note)
    out("")


# ---------------------------------------------------------------------------------------------


def list_steps(table, out=print):
    for step in table["steps"]:
        how = " ".join(step["argv"]) if "argv" in step else "(built in: %s)" % step["builtin"]
        needs = ", needs " + " and ".join(step["needs"]) if step.get("needs") else ""
        out("%-17s %s%s\n%19s%s%s" % (step["id"], "quick  " if step.get("quick") else "       ", step["what"], "", how, needs))
    out("\nNot in CI, by decision:")
    for path, why in sorted(table.get("not_in_ci", {}).items()):
        out("  %s: %s" % (path, why))


def main(argv=None):
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--quick", action="store_true", help="the fast steps only")
    ap.add_argument("--only", nargs="+", metavar="ID", help="these steps only")
    ap.add_argument("--list", action="store_true", help="print the steps and stop")
    ap.add_argument("--no-remote", action="store_true", help="do not read the tags on origin")
    args = ap.parse_args(argv)
    try:
        table = load_table()
    except (OSError, ValueError) as exc:
        print("ci_local: NOT RUN -- cannot read tools/ci_steps.json: %s" % exc)
        return 2
    if args.list:
        list_steps(table)
        return 0
    ids = [step["id"] for step in table["steps"]]
    if args.only:
        unknown = [name for name in args.only if name not in ids]
        if unknown:
            print("ci_local: no step named %s. Steps: %s" % (", ".join(unknown), ", ".join(ids)))
            return 2
    dirty = tree_state(ROOT)
    header(ROOT, sys.executable, remote=not args.no_remote, dirty=dirty)
    began = time.time()
    results = run_all(select(table["steps"], args.quick, set(args.only) if args.only else None))
    left = [step["id"] for step, _, _, left_out in results if left_out]
    count = {verdict: sum(1 for _, v, _, left_out in results if v == verdict and not left_out) for verdict in (PASS, FAIL, NOT_RUN)}
    print("\n%d PASS, %d FAIL, %d NOT RUN in %.0f s" % (count[PASS], count[FAIL], count[NOT_RUN], time.time() - began))
    if left:
        print("Left out: %s" % ", ".join(left))
    print(ready_line(results, dirty))
    if dirty and ready(results):
        for row in dirty[:12]:
            print("    " + row)
        if len(dirty) > 12:
            print("    ... and %d more" % (len(dirty) - 12))
    print("Not covered by this run: Linux path behaviour, CI's own Python and Lua binaries, the live game, the CI run on main.")
    return exit_status(results)


if __name__ == "__main__":
    sys.exit(main())
