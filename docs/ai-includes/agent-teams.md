# Agent Teams Guide -- LEVI-Achaea Combat System

## What Are Agent Teams?

Claude Code agent teams allow a **lead agent** to spawn **teammate agents** that work in parallel on different parts of the codebase. Each teammate runs as a separate Claude instance with access to the full project, coordinating through a shared task list and messaging system.

**Architecture**:
- **Team Lead**: Orchestrates work, assigns tasks, reviews output, runs the build
- **Teammates**: Work on assigned files/directories, report back to the lead
- **Task List**: Shared progress tracking at `~/.claude/tasks/{team-name}/`
- **Messaging**: Direct messages and broadcasts between agents

**Prerequisites**: Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in the `env` block of `~/.claude/settings.json` (already configured for this project).

---

## LEVI-Achaea Team Compositions

### Recommended Team Roles

| Role | Scope | Key Directories |
|------|-------|-----------------|
| **Combat System Dev** | Per-class offense systems | `src_new/scripts/.../levi_scripts/{class}/` |
| **Core/Tracking Dev** | Affliction tracking, curing, balance | `src_new/scripts/.../ataxia/affliction_tracking_core/`, `ataxia/curing/`, `ataxia/update_stuff/` |
| **Trigger Dev** | Game text pattern matching | `src_new/triggers/levi_ataxia/for_levi/leviticus/` |
| **Build/Tools Dev** | Python toolchain, Muddler config | `tools/`, `muddler_project/mfile` |
| **Researcher** | Read-only analysis, documentation | `.claude/classes/`, `docs/`, `CLAUDE.md` |

### Example: Parallel Class Development (3 teammates)

**Use case**: Build two class combat systems simultaneously while a researcher analyzes a third.

- **Teammate 1 -- Shaman Dev**: Owns `levi_scripts/shaman/`, reads `.claude/classes/shaman.md`
- **Teammate 2 -- Blademaster Dev**: Owns `levi_scripts/blademaster/`, reads `.claude/classes/blademaster.md`
- **Teammate 3 -- Researcher**: Read-only analysis of psion mechanics from `.claude/classes/psion.md`

### Example: V3 Tracking Rollout (2 teammates + lead)

**Use case**: Adding V3 probability tracking to multiple class systems simultaneously.

- **Lead**: Coordinates, modifies shared `affliction_tracking_core/008_V3_Integration.lua` if needed
- **Teammate A**: Adds V3 `hasAff()` routing to apostate system (`levi_scripts/apostate/`)
- **Teammate B**: Adds V3 `hasAff()` routing to bard system (`levi_scripts/bard/`)

The V3 pattern to follow exists in:
- `levi_scripts/dwc/001_Infernal_DWC_Vivisect.lua` (DWC uses `infernalDWC.hasAff()`)
- `levi_scripts/blademaster/005_CC_BM_Ice.lua` (Blademaster uses `blademaster.hasAff()`)

---

## File Ownership Rules

### Isolated Directories (Safe for Parallel Work)

Each per-class combat system directory is fully independent and uses its own namespace:

| Directory | Namespace | Safe for Solo Teammate |
|-----------|-----------|----------------------|
| `levi_scripts/dwc/` | `infernalDWC` | Yes |
| `levi_scripts/blademaster/` | `blademaster` | Yes |
| `levi_scripts/shikudo/` | `shikudo`, `shikudov2`, `shikudoLock` | Yes |
| `levi_scripts/shaman/` | shaman tables | Yes |
| `levi_scripts/apostate/` | apostate tables | Yes |
| `levi_scripts/bard/` | bard tables | Yes |
| `levi_scripts/serpent/` | serpent tables | Yes |
| `levi_scripts/earth_lord/` | earth lord tables | Yes |
| `levi_scripts/tekura/` | tekura tables | Yes |
| `levi_scripts/depthswalker/` | depthswalker tables | Yes |
| `levi_scripts/psion/` | psion tables | Yes |
| All other class dirs | Respective namespaces | Yes |

### Shared/Contended Files (Coordinate Through Lead)

These files are used by ALL combat systems and must NOT be modified by teammates without lead approval:

| File/Directory | Why Shared |
|----------------|------------|
| `ataxia/affliction_tracking_core/` | V1/V2/V3 tracking used by all class systems |
| `ataxia/017_Affliction_Management.lua` | `tarAffed()`, `erAff()`, `haveAff()` -- global functions |
| `ataxia/015_Affliction_Management.lua` | Companion affliction management file |
| `ataxia/update_stuff/005_Balance_Tracking.lua` | Balance tracking shared by all dispatchers |
| `ataxia/curing/` | Cure priorities affect all combat |
| `ataxia/limb_management/` | Limb tracking shared across knight/monk systems |
| `ataxia/fracture_management/` | Two-handed fracture tracking |
| `tools/convert_to_muddler.py` | Build pipeline -- one writer at a time |
| `CLAUDE.md` | Project documentation -- lead only |
| `.claude/AGENTS.md` | Agent instructions -- lead only |

### Trigger Ownership

Triggers in `src_new/triggers/levi_ataxia/for_levi/leviticus/` are a flat directory with 400+ files. Triggers are often class-specific by content but NOT by file name. A teammate working on a class system should:

1. Search for triggers related to their class using grep
2. Claim specific trigger files in the task list
3. Not modify trigger files outside their claimed set

```bash
# Find triggers related to a specific class
grep -rl "shaman\|tzantza\|curseward" src_new/triggers/levi_ataxia/for_levi/leviticus/
```

---

## Best Use Cases

### 1. Parallel Class System Development

**When**: Building or overhauling 2+ class systems simultaneously.
**Team size**: 2-4 teammates + lead.
**Example**: "Build apostate vivisect system AND blademaster ice dispatch in parallel."

### 2. Cross-System Feature Rollout

**When**: Same pattern needs to be applied across multiple class systems.
**Team size**: 2-3 teammates + lead.
**Example**: "Add V3 `hasAff()` routing to all class systems that still use raw `tAffs` checks."

### 3. Parallel Code Review

**When**: Reviewing multiple independent systems for bugs or anti-patterns.
**Team size**: 2-3 researcher teammates + lead.
**Example**: "Review all combat systems for stale V1 fallback bugs (`hasAff(x) or tAffs.x`)."

### 4. Documentation Sprint

**When**: Multiple class systems need `.claude/classes/` documentation updates.
**Team size**: 2-3 researcher teammates + lead.
**Example**: "Document kill routes for all undocumented class systems."

### 5. System + Triggers in Parallel

**When**: New class system needs both scripts and triggers built.
**Team size**: 1 combat dev + 1 trigger dev + lead.
**Example**: "Build psion offense scripts while writing psion-specific hit triggers."

---

## Spawn Prompt Template

When spawning a teammate, always include:

1. Role assignment and scope restriction
2. Required reading (AGENTS.md + relevant class file)
3. Specific files they own
4. Files they must NOT modify
5. How to report back

### Combat System Developer

```
You are a Combat System Developer working on the {class} system for LEVI-Achaea.

**Required reading**: `.claude/AGENTS.md`, `.claude/classes/{class}.md`, `.claude/classes/lock_types.md`

**Your files**: `src_new/scripts/levi_ataxia/levi/levi_scripts/{class}/`

**Do NOT modify**: Any file in `ataxia/`, `tools/`, `CLAUDE.md`, or other class directories.
If you need changes to shared files, message the team lead.

**Namespace pattern**: `{className} = {className} or {}`

**Task**: {description}
```

### Trigger Developer

```
You are a Trigger Developer working on {class}-specific triggers for LEVI-Achaea.

**Required reading**: `.claude/AGENTS.md`, `.claude/classes/{class}.md`

**Your files**: Only trigger files in `src_new/triggers/levi_ataxia/for_levi/leviticus/` that match
patterns for {class}. Search with grep first to identify your files.

**Do NOT modify**: Script files, alias files, or triggers for other classes.

**Task**: {description}
```

### Researcher (Read-Only)

```
You are a read-only Researcher for LEVI-Achaea. You may read any file but must not modify anything.

**Required reading**: `CLAUDE.md`, `.claude/AGENTS.md`

**Task**: {description}

Write your findings as a message back to the team lead.
```

---

## When NOT to Use Agent Teams

### Too Small

- Single trigger fix (1 file edit)
- Adding one venom to an existing priority list
- Fixing a typo in a combat echo
- Adjusting a single threshold value

**Rule of thumb**: If the task touches fewer than 3 files or takes under 10 minutes, do it directly.

### Sequential by Nature

- Debugging a combat system interaction (need to trace cause-and-effect)
- Modifying affliction tracking core (V1/V2/V3 changes cascade to all systems)
- Build pipeline changes (`convert_to_muddler.py` changes affect everything)
- Investigating a specific bug where you need to read output, modify, test, iterate

### High Contention

- Multiple systems need changes to the same shared file (e.g., `017_Affliction_Management.lua`)
- Changes that require modifying the curing priority order
- Anything requiring iterative live testing in Mudlet (only one Mudlet instance connects at a time)

---

## Integration with Existing Instructions

All teammates MUST follow the instructions in `.claude/AGENTS.md`. Key points that apply to every teammate:

1. **Before coding offensive systems**: Read `classes/lock_types.md` and the target class file
2. **Namespace pattern**: Use `className = className or {}` (never pollute globals)
3. **Affliction tracking hierarchy**: V3 (probability) -> V2 (certainty) -> V1 (boolean/tAffs)
4. **`hasAff()` rules**: Never use `hasAff(x) or (tAffs and tAffs.x)` except for rebounding/shield
5. **`erAff()` is V1 only**: Use `erAffWrapper()` or add `removeAffV3()` separately when V3 is enabled
6. **`tarAffed()` sets V1**: Hit triggers also call `applyAffV3()` -- both get set

The team lead should verify that each teammate's spawn prompt references AGENTS.md.

---

## Task Sizing Guide

| Size | Example | Good for Teams? |
|------|---------|-----------------|
| **XL** | Build a new class system from scratch (5-10 files) | Yes -- 1 teammate per class |
| **L** | Add V3 tracking to an existing class system (3-5 files) | Yes -- 1 per class |
| **M** | Overhaul priority tables for a class (2-3 files) | Borderline -- solo is fine |
| **S** | Fix a single bug in one combat system | No -- just do it directly |
| **XS** | Change a threshold, fix a typo | No |

**Ideal team task**: Each teammate gets an L or XL task in an isolated directory. Target 5-6 tasks per teammate. The lead handles any shared-file coordination.

---

## Build System Contention

### The Problem

The build pipeline is strictly single-writer:

1. `python tools/convert_to_muddler.py` reads ALL of `src_new/` and writes to `muddler_project/`
2. `muddle.bat` reads all of `muddler_project/` and produces `.mpackage`

If two agents run the build simultaneously, file corruption or partial builds will result.

### The Rule

**Only the team lead runs the build.** Teammates must:

1. Complete their file edits
2. Mark their task as completed
3. Message the team lead that they are ready for build
4. The lead runs a single consolidated build after all teammates finish (or at checkpoints)

### Build Command Reference

```bash
# Step 1: Convert (from LEVI-Achaea/ root)
python tools/convert_to_muddler.py --src ./src_new --output ./muddler_project

# Step 2: Build (from muddler_project/)
# Requires JAVA_HOME set (e.g., E:\Java)
cd muddler_project && muddle.bat
```

Output: `muddler_project/build/Levi_Ataxia.mpackage`

---

## Windows-Specific Notes

### In-Process Mode

On Windows, teammates run as in-process agents (tmux/iTerm2 split panes are not available). This means:

- Teammates run within the same process as the lead agent
- Memory usage scales with number of active teammates
- Recommended maximum: 3-4 concurrent teammates

### Path Format

All paths in this project use Windows backslash notation in the filesystem but forward slashes work in most tools. When specifying paths in spawn prompts, use forward slashes for compatibility:

- Use: `src_new/scripts/levi_ataxia/levi/levi_scripts/shaman/`
- Avoid: `src_new\scripts\levi_ataxia\levi\levi_scripts\shaman\`

### Keyboard Shortcuts

- **Shift+Up/Down**: Scroll between teammate panels
- **Ctrl+T**: Open teammate selector
- **Shift+Tab**: Cycle focus between teammates

---

## Troubleshooting

### Namespace Conflicts

**Symptom**: Two teammates modify files that initialize the same global table.

**Prevention**: Each class system uses its own namespace (`infernalDWC`, `blademaster`, `shikudo`, etc.). Never assign two teammates to the same class.

**Resolution**: If both teammates need the same namespace, serialize their work -- one finishes before the other starts.

### Shared Affliction Tracking Conflicts

**Symptom**: Teammate needs to add a new function to `affliction_tracking_core/` or `017_Affliction_Management.lua`.

**Prevention**: Always route these changes through the team lead. The lead makes the shared change first, then teammates build on it.

**Common scenario**: Adding a new class-specific `hasAff()` wrapper. The wrapper itself goes in the CLASS file (safe), but if it needs a new V3 integration point, that change goes through the lead.

### Build Contention

**Symptom**: Corrupt `.mpackage` or missing files in the build output.

**Prevention**: Only the lead runs `convert_to_muddler.py` and `muddle.bat`. Period.

### Trigger File Collisions

**Symptom**: Two teammates edit the same trigger file in `leviticus/`.

**Prevention**: Claim trigger files by number in the task list. Use grep to identify which triggers relate to your class before claiming:

```bash
grep -rl "shaman\|tzantza\|curseward" src_new/triggers/levi_ataxia/for_levi/leviticus/
```

### Teammate Cannot Find Class Documentation

**Solution**: Ensure spawn prompt includes the path: `.claude/classes/{class}.md`. All 26 classes plus `lock_types.md` and `README.md` are in `.claude/classes/`.

---

## Limitations

1. **No live testing**: Only one Mudlet instance connects to Achaea at a time. Teammates cannot verify their changes against the live game. The lead must consolidate and test.

2. **No parallel builds**: The Muddler build pipeline is single-threaded and single-writer.

3. **Shared state at runtime**: All Lua files load into the same Mudlet global namespace at runtime. Namespace isolation in source does NOT mean runtime isolation. A bug in one system can crash another.

4. **Trigger flat directory**: The 400+ trigger files in `leviticus/` are not organized into subdirectories by class. Ownership claims require grep-and-claim.

5. **No incremental build**: Every build reprocesses all source files. There is no way to build just one class system's changes.

6. **Experimental feature**: Agent teams are behind `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`. Behavior may change in future Claude Code releases.

---

**Related files**:
- `CLAUDE.md` -- Main project documentation (Agent Teams quick reference section)
- `.claude/AGENTS.md` -- Coding instructions for combat systems
- `.claude/classes/` -- Per-class mechanics documentation (26 classes)
