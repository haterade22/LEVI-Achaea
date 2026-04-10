---
name: review-codex
description: Auto-detect what was built, write a Codex adversarial prompt, dispatch, then verify results
argument-hint: "[optional: system-name or path-to-review.md]"
---

# Codex Adversarial Review Pipeline

Full Codex review lifecycle. Detects what needs reviewing from context.

**Argument handling:**
- No argument: auto-detect from git what changed, write prompt, dispatch
- System/class name: write prompt for that target, dispatch
- Path to `.md` file: verify existing Codex review, implement fixes
- If a `codex-adversarial-*.md` exists in `docs/reviews/` from the last hour, ask to verify it

## Phase 1: Detect What to Review

### If no argument:
1. `git diff --name-only HEAD` and `git diff --name-only HEAD~3..HEAD` for recently changed `.lua` files
2. Group by system area (scripts/triggers/aliases/class-offense)
3. Check `docs/reviews/` for recent `codex-adversarial-*.md`
   - Found: go to Phase 3
   - Not found: go to Phase 2

## Phase 2: Write Codex Prompt

### 2a: Gather files
- `src_new/scripts/` files for the target system
- `src_new/triggers/` files for matching triggers
- `src_new/tests/` test files
- `.claude/classes/<class>.md` if class offense

### 2b: Identify Known Suspects
Run quick analysis for likely issues:
- Missing `local` declarations (accidental globals)
- Balance checks before send() calls
- GMCP nil guards on table traversals
- Affliction name typos (common: `paresis` vs `paralysis`, `sensitivity` vs `sensitivity`)
- Stale state after death/logout (variables not reset)
- Trigger patterns that could false-positive on illusions

List 3-6 Known Suspects with specific hypotheses.

### 2c: Write the prompt

Include:
1. System description (1-2 lines)
2. ACHAEA REFERENCE:
   Balance types: balance, equilibrium, class-specific (e.g., shin, kai, venom)
   Lock types: soft lock (3 affs), hard lock (4 affs), true lock (5 affs)
   Common affliction IDs: paralysis, asthma, slickness, anorexia, clumsiness, stupidity, etc.
3. Known Suspects section
4. File lists
5. Required analysis sections
6. Output to: `docs/reviews/codex-adversarial-{system}-{date}.md`

### 2d: Dispatch to Codex

```
/codex:rescue [full prompt]
```

Use Monitor tool to stream progress.

## Phase 3: Verify Codex Review

### 3a: Read the review file

### 3b: Verify each finding
- **Read the Lua source.** Does it do what Codex claims?
- **Verify "missing" claims.** Grep the codebase.
- **Check Mudlet API validity.** Codex may not know Mudlet-specific functions.
- **Cross-reference affliction IDs** against `.claude/classes/lock_types.md`

### 3c: Produce assessment

| # | Codex Severity | Your Severity | Agree? | Reason |
|---|---------------|--------------|--------|--------|

Categorize:
- **Confirmed bugs** — file, line, what to change
- **False positives** — why Codex was wrong (often: doesn't know Mudlet API)
- **Design questions** — need user input

### 3d: Implement confirmed fixes

1. Make code changes
2. Run `lua5.1 src_new/tests/test_runner.lua`
3. Run `./build.sh`

## Rules

- NEVER implement a fix without reading the source first
- NEVER agree with a Codex finding just because it sounds plausible -- verify
- Codex does NOT know Mudlet APIs (send, tempTimer, killTimer, etc.) -- these are valid
- Build and test after every batch of fixes