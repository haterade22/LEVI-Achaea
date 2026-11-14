---
name: build-fix
description: Incrementally fix build errors with minimal diffs, one error at a time
argument-hint: "[optional: specific error or file]"
---

# Incremental Build Fix

Fix build/lint errors one at a time with minimal changes.

## Step 1: Identify the Error

Run the build and capture output:
```bash
./build.sh 2>&1
```

If the build succeeds, run the syntax step and the Lua suite (Lua 5.1 through `lupa`; this machine has no `lua5.1`):
```bash
/c/Python314/python -B tools/ci_local.py --only syntax unit
```

A step that prints NOT RUN did not run: correct the cause (the interpreter must have `lupa`), do not report a pass.

## Step 2: Parse Error

Common error types and fixes:

| Error | Cause | Fix |
|-------|-------|-----|
| `unexpected symbol near '...'` | Lua syntax error | Check for missing `end`, `)`, `then` |
| `'end' expected` | Unclosed block | Find matching `if`/`for`/`function` |
| `attempt to index a nil value` | Missing require or global | Add local reference or nil check |
| `YAML parse error` | Bad frontmatter | Fix YAML header syntax |
| `Version mismatch` | 3-point sync broken | Update all 3: version.txt, mfile, _groups.yaml |
| `Muddler error` | XML generation failed | Check _groups.yaml hierarchy |
| `module '...' not found` | Missing dependency | Check module path in _groups.yaml |

## Step 3: Fix ONE Error

- Read the file containing the error
- Make the **minimal** change to fix just this one error
- Do NOT refactor surrounding code
- Do NOT add features

## Step 4: Verify

```bash
./build.sh
```

If more errors remain, return to Step 1. Fix one error per iteration.

## Step 5: Report

```
BUILD FIX REPORT
=================
Errors fixed: N
Files modified: [list]
Build status: PASS/FAIL (N remaining errors)
```

## Important

- ONE error at a time — do not batch fixes
- Minimal diffs — don't touch code that isn't broken
- If an error is architectural (wrong module structure), flag it instead of hacking around it
- Always re-run build after each fix to verify it's resolved and didn't introduce new errors