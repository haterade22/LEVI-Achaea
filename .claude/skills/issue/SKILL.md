---
name: issue
description: Create a GitHub issue for a feature, bug fix, or crash with structured sections
argument-hint: "[bug|feature|crash] [brief description]"
---

# GitHub Issue Creator

Create a GitHub issue with structured sections for: `$ARGUMENTS`

## Step 1: Parse Arguments

- First word: issue type (`bug`, `feature`, `crash`)
- Remaining words: brief description

## Step 2: Gather Context

- `git log --oneline -5` — recent work
- `git diff --name-only` — files currently changed
- Read CHANGELOG.md last section for context

## Step 3: Create Issue

### For Bug/Crash Issues:

```bash
gh issue create --title "<type>: <description>" --label "<type>" --body "$(cat <<'EOF'
## Problem

[Exact error, symptoms, reproduction steps]
[For crashes: stack trace or error output from Mudlet]

## Analysis

[Root cause investigation]
[Which Lua module/trigger/alias is affected]
[GMCP data state when bug occurs]

## Solution

[What was changed and WHY]
[Which files were modified]

## Testing

[How the fix was verified]
[Manual testing in Mudlet or unit test coverage]

## Files Changed

- `path/to/file.lua` — one-line description
EOF
)"
```

### For Feature Issues:

```bash
gh issue create --title "feat: <description>" --label "feature" --body "$(cat <<'EOF'
## Motivation

[Why this feature exists, what problem it solves]
[Which class/system benefits]

## Design

[Architecture: triggers, aliases, scripts, events involved]
[GMCP data sources used]
[Integration with existing systems (curing, offense, defense)]

## Implementation

[Key files, patterns used]
[New triggers/aliases/scripts added]

## Testing

[Test coverage, how to verify in Mudlet]
EOF
)"
```

## Step 4: Report

Output the issue URL when created.

## Important

- Label issues: `bug`, `feature`, `crash`, `enhancement`, `class-offense`
- Reference class name in title when applicable (e.g., `fix(serpent): ...`)
- Close issues with `gh issue close <number>` when work is complete