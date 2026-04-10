---
name: deslop
description: Regression-safe cleanup of AI-generated bloat in Lua code. Deletion-first, requires passing tests before starting
argument-hint: "[path or system to clean up]"
---

# Lua Code Cleanup (Deslop)

Regression-safe removal of AI-generated bloat in: `$ARGUMENTS`

## Precondition: Tests Must Pass

Before any deletions, verify baseline:
```bash
lua5.1 src_new/tests/test_runner.lua
./build.sh
```

If tests fail or build fails, STOP. Fix those first.

## Step 1: Identify Bloat Patterns

Scan target files for these patterns:

### HIGH — Definitely Remove
| Pattern | Example |
|---------|---------|
| **Unused locals** | `local foo = bar` where `foo` is never referenced |
| **Commented-out code blocks** | `-- old_function()` spanning 5+ lines |
| **Redundant nil checks on guaranteed values** | `if self ~= nil then` inside method |
| **Duplicate condition branches** | Same code in if/else branches |
| **Empty functions** | `function foo() end` with no callers |
| **Dead elseif branches** | Conditions that can never be true |
| **Verbose logging left from debugging** | `cecho("\n<yellow>DEBUG: " .. ...)` |

### MEDIUM — Usually Remove
| Pattern | Example |
|---------|---------|
| **Over-defensive nil guards** | `(x or {}).y or ""` when x is always a table |
| **Unnecessary string concatenation** | Building strings that are never used |
| **Redundant variable assignments** | `local x = y; return x` instead of `return y` |
| **Wrapper functions that just call one thing** | `function doFoo() foo() end` |
| **Excessive comments on obvious code** | `-- increment counter` above `i = i + 1` |

### LOW — Consider Removing
| Pattern | Example |
|---------|---------|
| **Overly verbose variable names** | `currentActiveTargetName` vs `target` |
| **Unnecessary local copies** | `local tbl = self.data; tbl[1] = ...` |

## Step 2: Delete (One Pattern at a Time)

For each identified instance:
1. Delete the bloat
2. Run tests: `lua5.1 src_new/tests/test_runner.lua`
3. If tests pass: keep deletion, move to next
4. If tests fail: revert, mark as "load-bearing" and skip

## Step 3: Build Verification

After all deletions:
```bash
./build.sh
```

## Step 4: Report

```
DESLOP REPORT: [target]
========================
Removed: N instances
Skipped (load-bearing): N instances
Lines removed: N
Tests: PASS
Build: PASS
```

## Important

- NEVER delete code that changes behavior without test coverage
- Deletion-first: remove before refactoring
- If no tests exist for a module, note it but still remove obviously dead code
- Do NOT add new abstractions — this is cleanup only