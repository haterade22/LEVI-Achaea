"""Run CI's validate job on this machine: one verdict for each step, PASS, FAIL or NOT RUN.

    python -B tools/ci_local.py            # every step (about 80 s). The check before a push to main.
    python -B tools/ci_local.py --quick    # the fast steps only (about 15 s)
    python -B tools/ci_local.py --only rules unit
    python -B tools/ci_local.py --list     # the steps and what each one proves

Since 2026-11-11 work goes straight to main with no pull request, so this run is the ONLY check
before main. Two releases failed on main after a partial local run (v4.7.477, v4.7.484). The step
list lives in tools/ci_steps.json; tools/test_ci_local.py fails when it and build.yml disagree.

Verdicts. PASS: the step ran and exited 0. FAIL: it ran and found a problem. NOT RUN: it could not
run (this interpreter lacks lupa or yaml, the step exited 2, or --quick/--only left it out). A step
that did not run is never counted as a pass.

Exit status: 1 if a selected step FAILED, else 2 if a selected step could NOT RUN, else 0.
"Ready to push: YES" needs a full run (no --quick, no --only) with every step PASS.

Use the interpreter that has lupa (Lua 5.1) and pyyaml. Every step runs with that same interpreter.
This run does not cover: Linux path behaviour, the live game, and the CI run on main itself.
"""
import argparse
import glob
import json
import os
import re
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STEPS_FILE = os.path.join(ROOT, "tools", "ci_steps.json")
PASS, FAIL, NOT_RUN = "PASS", "FAIL", "NOT RUN"
TAIL = 25          # rows of a step's output shown when it did not pass
REMOTE_WAIT = 20   # seconds for the one network read (the tags on origin)


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
# Built-in steps. Each returns (verdict, one line).
# ---------------------------------------------------------------------------------------------


def lua_syntax(root):
    """CI runs `luac5.1 -p` on each file. loadstring in lupa's Lua 5.1 compiles the same chunk without running it."""
    import lupa.lua51 as lupa
    files = sorted(glob.glob(os.path.join(root, "src_new", "**", "*.lua"), recursive=True))
    if not files:
        return NOT_RUN, "no .lua file under src_new"
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    compile_only = lua.eval("function(source, name) local fn, err = loadstring(source, name) return err end")
    bad = []
    for path in files:
        with open(path, "rb") as fh:
            err = compile_only(fh.read(), "@" + os.path.relpath(path, root).replace(os.sep, "/"))
        if err:
            bad.append(err if isinstance(err, str) else err.decode("utf-8", "replace"))
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
        found = re.search(r'ataxiaVersion = \\"([0-9][0-9.]*)', fh.read())
    with open(os.path.join(root, "CHANGELOG.md"), encoding="utf-8") as fh:
        heading = re.search(r"^## \d{4}-\d{2}-\d{2} - v%s[: ]" % re.escape(v_txt), fh.read(), re.M)
    return v_txt, v_mfile, found.group(1) if found else "", bool(heading)


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
    files = sorted(glob.glob(os.path.join(root, "src_new", "**", "_groups.yaml"), recursive=True))
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
        except Exception as exc:  # a missing file, a bad JSON: report it against this step
            return FAIL, "%s: %s" % (type(exc).__name__, exc), ""
        first, _, rest = line.partition("\n")
        return verdict, first, rest
    env = dict(os.environ, PYTHONIOENCODING="utf-8")
    try:
        done = subprocess.run([python, "-B"] + list(step["argv"]), cwd=root, env=env, stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT, encoding="utf-8", errors="replace")
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
    """A push needs every step of the table to have run and passed."""
    return bool(results) and all(verdict == PASS and not left_out for _, verdict, _, left_out in results)


# ---------------------------------------------------------------------------------------------
# The header: where this run is, and whether the version is behind the remote
# ---------------------------------------------------------------------------------------------


def git(root, *args, wait=None):
    try:
        done = subprocess.run(["git", "-C", root] + list(args), stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                              encoding="utf-8", errors="replace", timeout=wait)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return done.stdout.strip() if done.returncode == 0 else None


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


def version_notes(local, tag, main):
    """Warnings for the header. Three releases lost their number to another session (2026-10-23, 11-03, 11-13)."""
    notes = []
    here = version_key(local)
    if here is None:
        return ["WARNING: version.txt does not hold a version"]
    if tag and version_key(tag) > here:
        notes.append("WARNING: origin has tag %s, above this tree's version.txt (%s). Rebase before a release." % (tag, local))
    if main and version_key(main) and version_key(main) > here:
        notes.append("WARNING: origin/main (as last fetched) is at %s, above this tree (%s). Fetch and rebase." % (main, local))
    return notes


def header(root, python, remote=True, out=print):
    out("tree        %s" % root)
    out("branch      %s @ %s" % (git(root, "rev-parse", "--abbrev-ref", "HEAD") or "?",
                                 git(root, "rev-parse", "--short", "HEAD") or "?"))
    out("python      %s (lupa/Lua 5.1: %s, yaml: %s)" % (python, "yes" if can_import("lupa") else "NO",
                                                         "yes" if can_import("yaml") else "NO"))
    try:
        with open(os.path.join(root, "version.txt"), encoding="utf-8") as fh:
            local = fh.read().strip()
    except OSError:
        local = ""
    tag = top_tag(git(root, "ls-remote", "--tags", "origin", "refs/tags/v*", wait=REMOTE_WAIT)) if remote else None
    main = git(root, "show", "origin/main:version.txt")
    out("version     this tree %s | top tag on origin %s | origin/main as last fetched %s" % (
        local or "?", tag or ("NOT checked" if remote else "not asked"), main or "NOT checked"))
    for note in version_notes(local, tag, main):
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
    table = load_table()
    if args.list:
        list_steps(table)
        return 0
    ids = [step["id"] for step in table["steps"]]
    if args.only:
        unknown = [name for name in args.only if name not in ids]
        if unknown:
            print("ci_local: no step named %s. Steps: %s" % (", ".join(unknown), ", ".join(ids)))
            return 2
    header(ROOT, sys.executable, remote=not args.no_remote)
    began = time.time()
    results = run_all(select(table["steps"], args.quick, set(args.only) if args.only else None))
    left = [step["id"] for step, _, _, left_out in results if left_out]
    count = {verdict: sum(1 for _, v, _, left_out in results if v == verdict and not left_out) for verdict in (PASS, FAIL, NOT_RUN)}
    print("\n%d PASS, %d FAIL, %d NOT RUN in %.0f s" % (count[PASS], count[FAIL], count[NOT_RUN], time.time() - began))
    if left:
        print("Left out (NOT RUN): %s" % ", ".join(left))
    if ready(results):
        print("Ready to push: YES")
    else:
        why = "a step failed" if count[FAIL] else "a step could not run" if count[NOT_RUN] else "this was not a full run"
        print("Ready to push: NO (%s)" % why)
    print("Not covered by this run: Linux path behaviour, the live game, the CI run on main.")
    return exit_status(results)


if __name__ == "__main__":
    sys.exit(main())
