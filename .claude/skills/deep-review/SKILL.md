---
name: deep-review
description: Launch parallel deep-dive agents to review completed work for quality, standards, and completeness
argument-hint: "[system-name or class-name]"
---

# Deep Review

Launch 4 parallel review agents to audit the specified system or class: `$ARGUMENTS`

## Step 0: Identify Target Files

Find all files related to `$ARGUMENTS`:
- `src_new/scripts/` — core logic and class offenses
- `src_new/triggers/` — game text pattern matching
- `src_new/aliases/` — user command shortcuts
- `src_new/tests/` — unit tests
- `.claude/classes/` — class documentation

List all relevant files and their line counts.

## Step 1: Launch 4 Parallel Review Agents (Sonnet)

### Agent 1 — Lua Standards & Quality

Review all target files for:
- **Lua 5.1 compatibility** — no Lua 5.2+ features (goto, bitwise ops, string.format %a)
- **Variable scoping** — `local` declarations, no accidental globals (check luacheck would pass)
- **Naming conventions** — camelCase for locals, UPPER_CASE for constants, dot.notation for modules
- **Dead code** — unreachable branches, unused locals, commented-out blocks
- **Error handling** — pcall/xpcall around GMCP parsing, nil checks on table lookups
- **Performance** — avoid string concatenation in hot loops, prefer table.concat
- **YAML header correctness** — valid frontmatter, matching group hierarchy

Rate each finding: CRITICAL / HIGH / MEDIUM / LOW

### Agent 2 — Combat System Correctness

Review target files for combat logic errors:
- **Affliction IDs** — verify all affliction names match Achaea's canonical set
- **Balance/equilibrium gating** — commands sent only when on balance
- **Lock progression** — affliction combinations follow valid lock routes (reference `.claude/classes/lock_types.md`)
- **Illusion detection** — proper GMCP cross-referencing to reject fake afflictions
- **Curing priority** — affliction priorities don't conflict with server-side curing
- **State machine correctness** — state transitions are complete (no missing cases)
- **GMCP data trust** — using `gmcp.Char.Vitals`, `gmcp.Char.Afflictions` correctly
- **Class-specific mechanics** — verify ability names, skill costs, cooldowns match game data

### Agent 3 — Trigger & Pattern Correctness

Review trigger files for:
- **Regex correctness** — patterns match intended game text, no catastrophic backtracking
- **Trigger ordering** — numbered prefixes maintain correct fire order
- **False positive risk** — patterns too broad that match unintended text
- **Capture group usage** — captured values used correctly in trigger scripts
- **Multi-line trigger coverage** — multi-line game output handled properly
- **Duplicate patterns** — two triggers matching the same text
- **Missing patterns** — known game output not covered by any trigger

### Agent 4 — Completeness & Documentation

Check that the work is complete:
- **Test coverage** — do unit tests exist for new/modified logic?
- **CHANGELOG updated** — does CHANGELOG.md reflect the changes?
- **Class doc updated** — if class offense changed, is `.claude/classes/<class>.md` current?
- **AGENTS.md updated** — if new patterns/conventions introduced, is AGENTS.md current?
- **Build passes** — `./build.sh` succeeds
- **Version consistency** — 3-point version sync intact
- **Missing files** — any triggers referenced in code but not created?

## Step 2: Compile Report

Merge findings from all 4 agents:

```
DEEP REVIEW: [target]
=====================

CRITICAL: N findings
HIGH: N findings
MEDIUM: N findings
LOW: N findings

[Grouped findings by agent, with file:line references]

VERDICT: CLEAN / NEEDS FIXES / BLOCKED
```

## Step 3: Fix Issues (if requested)

For each CRITICAL or HIGH finding:
1. Make the fix
2. Run `lua5.1 src_new/tests/test_runner.lua`
3. Run `./build.sh`