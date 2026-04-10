---
name: codex-verify
description: Dispatch an independent Codex verification job for the current changes
argument-hint: "[system-name or class-name]"
---

# Codex Independent Verification

Dispatch an independent Codex review via the codex-plugin-cc. Codex reviews with no shared Claude context.

Target: `$ARGUMENTS` (if empty, verify all uncommitted changes).

## Step 1: Identify Files to Review

- If `$ARGUMENTS` provided: find files matching that system/class in `src_new/`
- Otherwise: `git diff --name-only` and `git ls-files --others --exclude-standard`
- Filter to `.lua` files only

## Step 2: Dispatch Codex Review

```
/codex:rescue Review these Lua files for the LEVI-Achaea combat system:

FILES: [file list]

This is a Mudlet Lua 5.1 combat system for Achaea (text MUD). Focus on:
1. Lua 5.1 compatibility -- no 5.2+ features (goto, bitwise, string.format %a)
2. Variable scoping -- missing local declarations creating accidental globals
3. Balance/equilibrium gating -- commands sent without checking bal/eq state
4. Affliction ID correctness -- verify against canonical Achaea affliction set
5. GMCP data handling -- nil checks on gmcp table lookups, pcall around parsing
6. Trigger pattern correctness -- regex matches intended text, no catastrophic backtracking
7. State machine gaps -- missing state transitions or unreachable states
8. Dead code -- unreachable branches, unused locals, commented-out blocks

Rate each finding: CRITICAL / HIGH / MEDIUM / LOW
Format: [SEVERITY] file.lua:line -- description -- remediation
```

## Step 3: Monitor Background Job

Use the Monitor tool to stream Codex progress. When complete, proceed to Step 4.

Alternatively, check manually: `/codex:status`

## Step 4: Retrieve Results

```
/codex:result
```

## Step 5: Display Report

```
CODEX VERIFICATION REPORT
==========================
Target: [system or files]

[Findings grouped by severity]

CRITICAL: N
HIGH: N
MEDIUM: N
LOW: N

VERDICT: CLEAN / ISSUES FOUND
```

## Important

- Codex has no Mudlet/Achaea domain knowledge beyond what's in AGENTS.md
- If Codex flags valid Mudlet API usage as errors, those are false positives
- Codex does NOT run builds or tests -- static analysis only