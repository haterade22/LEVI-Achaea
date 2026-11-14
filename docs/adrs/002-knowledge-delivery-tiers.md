# ADR-002: One home for each fact, and a size budget for `CLAUDE.md`

**Status:** Accepted
**Date:** 2026-11-13
**Decision by:** the maintainer ("Yes, one home per fact", 2026-11-13)

## Context

`CLAUDE.md` was 72,024 bytes on 2026-06-01 and 450,746 bytes on 2026-11-13. In the 13 days before
that date it grew 54,089 bytes, and 39 of 77 commits touched it.

The cause was the documentation rule itself. It said that a completed task updates every document
it touches, and it named `CLAUDE.md` as a home for "new systems, architecture, conventions". So each
task added a paragraph. The largest section, Mnemosyne, was 180,468 bytes (40% of the file), and the
same system had two more copies: eight files in `.claude/projects/mnemosyne/` and a memory file.

The size defeats the purpose. Claude Code loads this file only after the first file access below the
repository, and it cuts the file: about 131,000 to 143,000 characters arrive in the maintainer's
sessions, and 40,000 on a 200K context window (`docs/reference/harness-facts.md`, section 2). Until
2026-11-13 the rules that every task needs were at lines 2,954 to 3,901, after the cut. They were
written, and they were not delivered.

A trim alone does not hold. The TAOM repository cut its `CLAUDE.md` from 91 KB to 28 KB, and it grew
back to 49 KB in six weeks, because the process that added a row for each feature was unchanged
(TAOM `docs/adrs/011-knowledge-delivery-tiers.md`). This ADR takes that repository's cure.

## Decision

### 1. Each fact has one home

Other documents point to the home. They do not copy it.

| What you learned or changed | Its one home |
|---|---|
| Something a machine can check | A gate in `tools/` with a row in `tools/ci_steps.json`, and one line of prose that names the gate |
| A rule that every task needs | `CLAUDE.md` |
| A game fact: a cure, a blocker, a fire line, an ability, a timing | Its `kb/` page, with source and confidence tag. Raw game text goes into `kb/raw/`, unedited |
| How one class is played or fought: kill routes, rotations, syntax | `.claude/classes/<class>.md` |
| How one of our systems works: architecture, state, commands, design reasons | `.claude/projects/<system>/`. Never a section of `CLAUDE.md` |
| A lesson or pitfall, with its incident | One titled entry in `.claude/AGENTS.md`. If a machine can check it, write the gate and name it in the entry |
| What a release changed, and why | `CHANGELOG.md` only |
| The maintainer's own rules and preferences; the state of one machine | Memory (outside git). A fact about the code or the game never lives only there |

"Every completed task updates every document it touches" stays true. What changes is where a new
fact goes: to its one home, and no longer also to `CLAUDE.md`.

### 2. `CLAUDE.md` has a byte budget, enforced as a ratchet

`tools/check_context_budget.py` reads `tools/context_budget.json`. `CLAUDE.md` may not be larger than
its committed ceiling. The ceiling only goes down: each commit that moves text out lowers it. The
check is a step of `tools/ci_local.py` and of CI.

- Until the large moves are done, the ceiling is the current size plus 2,048 bytes.
- Target 1: 120,000 bytes, so that the whole file arrives in the maintainer's sessions.
- Target 2: 40,000 bytes, so that it arrives whole on a 200K window. Then the ceiling is fixed.

The check started report-only (`"strict": false`), as every new gate here does, and became strict
when target 1 was reached (2026-11-13).

### 3. Text that leaves `CLAUDE.md` is moved, not rewritten, and the move is proven

`tools/check_context_budget.py --moves --base <commit>` compares `CLAUDE.md` at the base commit with
the file on disk. Every line that left must be found verbatim in a destination file, or belong to a
section declared as deleted; for a deleted section, every backticked identifier must still exist in
a tracked file. Until the core was written, a move left a one-line pointer under the old heading. The core replaced
the headings and pointers with the "Where Things Are" table in `CLAUDE.md`, whose left column keeps the old section
titles. A sub-section title is found with `git grep`, because the text moved verbatim. Deduplication of a moved block against its destination is later work, done by
the owner of that system doc.

### 4. What stays in `CLAUDE.md`

Identity and source layout; this ladder; the evidence rules; build, test and release commands and
the release rules; naming; the model and effort table; a pointer index to the doc sets; a short trap
sheet (one line for each invariant, the full text in its home).

## Consequences

- A session gets the rules. Detail is read when a task needs it, from a file that names its system.
- New system detail has an obvious home, and a growing `CLAUDE.md` fails a check.
- The moved blocks carry stale text and version history into the system docs. They are no more
  wrong there than they were, but the owner docs grow until someone reconciles them.
- A pointer is not a delivery: an agent must open the system doc. `docs/ai-includes/agent-brief.md`
  (phase 6 of the adoption plan) and the pointer index are the mitigation. Path-scoped rules would be
  a better one; whether they load here is not yet verified (`docs/reference/harness-facts.md`).
- Shipped Lua comments that cite a `CLAUDE.md` section by title (17 files) resolve through the "Where Things Are"
  table, or through `git grep` of the title for a sub-section. They are corrected when their file next ships in a version.

## Alternatives rejected

- **Trim and ask people to keep it short.** It failed in TAOM within six weeks, and here the rule
  itself asked for growth.
- **Split `CLAUDE.md` into imported files.** An import loads with the file that imports it and does
  not reduce what is loaded.
- **A root `AGENTS.md` beside `CLAUDE.md`** (TAOM's three-file split). A third entry file and about
  25 renamed references, for a second AI client used for two reviews in seven months.
- **A new `docs/systems/` folder.** `.claude/projects/<system>/` exists and is tracked. A second home
  is the duplication this ADR removes.

## References

- `docs/reference/harness-facts.md`: what loads, with sources.
- `docs/reviews/adopt-taom-2026-11-13.md`: the review this decision came from.
- TAOM `docs/adrs/011-knowledge-delivery-tiers.md`: the source method.

## Migration record

Sizes are bytes of `CLAUDE.md` after each step. `python -B tools/check_context_budget.py` prints the
current size and ceiling.

| Date | Step | Size |
|---|---|---|
| 2026-11-13 | Before | 450,746 |
| 2026-11-13 | Sections reordered (every-task rules first); false hook and agent claims removed | 450,440 |
| 2026-11-13 | The one-home ladder replaces the "update every document" list and the Documentation Requirements section | 450,313 |
| 2026-11-13 | Gear Audit (pilot) to `.claude/projects/gear-audit/README.md` | 446,967 |
| 2026-11-13 | Mnemosyne to `.claude/projects/mnemosyne/00-reference-from-claude-md.md` | 266,815 |
| 2026-11-13 | Basher, `bashStats`, mob damage to `.claude/projects/basher/00-reference-from-claude-md.md` | 223,187 |
| 2026-11-13 | V3 tracking to `.claude/projects/affliction-tracking-v3/00-reference-from-claude-md.md` | 209,337 |
| 2026-11-13 | Defense Systems and SLC to `.claude/projects/defense/README.md` | 175,997 |
| 2026-11-13 | Afflictions, locks and SSC to `.claude/projects/curing/README.md` | 149,624 |
| 2026-11-13 | Serpent to `.claude/classes/serpent.md` | 139,039 |
| 2026-11-13 | Achaea Classes Reference to `.claude/classes/README.md` | 130,735 |
| 2026-11-13 | Combat core, persistence, armour to `.claude/projects/{ataxia-core,persistence,armour}/README.md` | 105,763 |
| 2026-11-13 | Repository Structure and Build System to `docs/reference/repository-and-build.md` | 75,577 |
| 2026-11-13 | Lessons Learned and Common Pitfalls to `.claude/AGENTS.md` | 62,250 |
| 2026-11-13 | Six small system references to `.claude/projects/` | 49,951 |
| 2026-11-13 | Versioning and release to `docs/ai-includes/git-and-release.md` | 42,414 |
| 2026-11-13 | Six class notes to `.claude/classes/`; Agent Teams to `docs/ai-includes/agent-teams.md` | 35,212 |
| 2026-11-13 | General development notes to `docs/reference/development-notes.md` | 22,111 |
| 2026-11-14 | The core: new summary sections; headings and pointers replaced by the "Where Things Are" table; corrected after a review | see the check |

Target 1 (120,000 bytes) was reached on 2026-11-13, and the check is strict from that commit. Every move above was
proven with `tools/check_context_budget.py --moves`: 0 rows lost. The proof line is in each commit message.

Target 2 (40,000 bytes) was reached on 2026-11-13, and the ceiling is fixed at 40,000.
