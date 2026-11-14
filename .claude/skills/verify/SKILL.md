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

Run it from the worktree you will push. The first lines print the tree, the branch and whether
`version.txt` is behind the top tag on origin.

## Read the result

- **PASS**: the step ran and exited 0.
- **FAIL**: the step ran and found a problem. The last rows of its output are printed below it.
- **NOT RUN**: the step could not run (no `lupa`, no `yaml`, an exit 2, or left out by `--quick`).
  NOT RUN is never a pass. Correct the cause and run again.
- Exit status: 1 for a FAIL, 2 for a NOT RUN, 0 for neither.
- `Ready to push: YES` appears only after a full run with every step PASS.

If a `kb_*.py --check` step prints STALE, run that tool without `--check` and read the diff
(`kb_sim.py` takes about 12 minutes). Generated pages change only through their generator.

## What the run does not cover

Say these in the report; do not imply them:

- Linux path behaviour (CI runs on Linux; a test that makes a folder passed here and failed there, v4.7.477).
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

Git: <git status --short, or "clean">
Not covered: Linux paths, the live game, the main CI run
VERDICT: READY TO PUSH / NOT READY (<reason>)
```
