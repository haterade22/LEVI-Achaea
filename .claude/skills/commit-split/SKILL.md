---
name: commit-split
description: Inspect all changed files, group by logical concern, and guide atomic per-concern commits
---

# Commit Split

Analyze all changed files and propose atomic commits grouped by logical concern.

## Step 1: Gather Changes

```bash
git status --short
git diff --name-only
git diff --staged --name-only
git ls-files --others --exclude-standard
```

## Step 2: Classify Files

Group each changed file by category:

| Type | Pattern | Example |
|------|---------|---------|
| **class-offense** | `scripts/levi_scripts/*` | New/modified class offense module |
| **combat-core** | `scripts/levi_ataxia/levi/ataxia/*` | Affliction tracking, curing, defense |
| **triggers** | `triggers/**` | Game text pattern matching |
| **aliases** | `aliases/**` | User command shortcuts |
| **timers** | `timers/**` | Delayed actions |
| **gui** | `*gui*`, `*container*`, `*gauge*` | UI components |
| **mapper** | `*mapper*`, `*mmp*` | Navigation/pathfinding |
| **database** | `*ndb*`, `*database*` | Player database |
| **config** | `_groups.yaml`, `mfile`, `version.txt` | Build/version config |
| **test** | `tests/**` | Unit tests |
| **docs** | `*.md`, `docs/**` | Documentation |
| **build** | `build.sh`, `tools/*`, `.github/*` | Build system |
| **chore** | `.claude/*`, `.vscode/*`, `.editorconfig` | Tooling config |

## Step 3: Propose Commit Groups

For each group with changes, propose a commit:
- **Type prefix**: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`, `build:`
- **Scope**: class name, system area, or file category
- **Message**: 50/72 rule, imperative mood

Example:
```
feat(serpent): add doublestab lock route for serpent offense
fix(curing): handle missing GMCP affliction data gracefully
test: add affliction priority unit tests
docs: update shaman class guide with new lock types
```

## Step 4: Execute (with user approval)

For each proposed group:
1. `git add <files in group>`
2. `git commit -m "<message>"`
3. Show the result

## Important

- Ask the user to confirm the grouping before committing
- If a file could belong to multiple groups, prefer the more specific one
- Never batch unrelated changes into one commit