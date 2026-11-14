---
name: verify
description: Run CI's validate job locally with tools/ci_local.py and report PASS, FAIL or NOT RUN for each step. Use before every push to main and before you say a change is done.
argument-hint: "[quick|full]"
---

# Verification Report

Mode: `$ARGUMENTS` (default: `full`)

One command runs every step of the `validate` job in `.github/workflows/build.yml`. The step list is
`tools/ci_steps.json`; `tools/test_ci_local.py` fails when that list and `build.yml` disagree, so this
skill holds no copy of it.

## Run

Use the interpreter that has `lupa` (Lua 5.1) and `pyyaml`. On the maintainer's Windows machine that
is `/c/Python314/python`. The `python3` on PATH has neither.

```bash
/c/Python314/python -B tools/ci_local.py            # full: every step, about 60-80 s
/c/Python314/python -B tools/ci_local.py --quick    # quick: syntax, orphans, wrap, version, Lua suite, yaml, converter
/c/Python314/python -B tools/ci_local.py --only rules unit
/c/Python314/python -B tools/ci_local.py --list     # what each step proves
```

Run it from the worktree you will push. The first lines print the tree, the branch, whether the
files on disk equal the commit, and the version against origin: a higher tag on origin, or the
same number on a commit that this tree does not have, prints a warning.

## Read the result

- **PASS**: the step ran and exited 0.
- **FAIL**: the step ran and found a problem. The last rows of its output are printed below it.
- **NOT RUN**: a selected step could not run (no `lupa`, no `yaml`, an exit 2).
  NOT RUN is never a pass. Correct the cause and run again.
- **Left out**: `--quick` and `--only` leave steps out. The run names them on its `Left out` row.
  They do not change the exit status, and such a run is never ready to push.
- Exit status: 1 if a selected step FAILED, else 2 if a selected step could NOT RUN, else 0.
- `Ready to push: YES` needs a full run, every step PASS, and a working tree equal to HEAD.
- `Ready to push: NOT YET` means every step passed on the files on disk, but some differ from HEAD
  or are untracked. A push carries only the commit: commit them, check that no new file is left
  untracked, then push. (The exit status is 0, so a chain that commits next goes on.)

If a `kb_*.py --check` step prints STALE, run that tool without `--check` and read the diff
(`kb_sim.py` takes about 12 minutes). Generated pages change only through their generator.

## What the run does not cover

Say these in the report; do not imply them:

- Linux path behaviour (CI runs on Linux; a test that makes a folder passed here and failed there, v4.7.477).
- CI's own Python and Lua binaries (CI: the runner's `python3` and apt's `lua5.1`; here: your Python and `lupa`).
- The live game. No agent can test against Achaea.
- The `Build & Validate` run on `main`. Watch it after the push, selected by workflow name.
- `./build.sh` (the Muddler package). CI builds the package only for a `v*` tag. Run `./build.sh`
  when you need a local package; it rewrites `muddler_project/mfile`.

## Report format

Quote the runner's own lines. Do not retype a verdict that you did not see this turn.

```
VERIFICATION REPORT
Mode: [quick|full]   Tree: <path>   Commit: <sha>

<the PASS / FAIL / NOT RUN rows from tools/ci_local.py>
<its summary row and its "Ready to push" row>

Not covered: Linux paths, CI's own Python and Lua, the live game, the main CI run
VERDICT: READY TO PUSH / NOT READY (<reason>)
```
