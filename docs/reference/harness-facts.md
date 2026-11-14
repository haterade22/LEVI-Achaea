# Harness facts: what loads, what runs, what binds whom

This page records how Claude Code treats this repository **as the maintainer uses it**. Every row
has a source and a date. Rules and designs for the agent harness (hooks, skills, rules, agents,
CLAUDE.md) must rest on a row here, not on memory.

**Kinds of source.** `EMPIRICAL`: seen in a session transcript or in a test, with where and when.
`DOC`: stated by the Claude Code documentation (code.claude.com/docs/en), with the page.
`UNVERIFIED`: not yet seen and not stated. A design must not depend on an `UNVERIFIED` row; run
the probe first and change the row.

**The layout that causes most rows.** Every session starts in the PARENT folder `Achaea/`, which
is not a git repository. The repository is the subfolder `Achaea/LEVI-Achaea/`. Worktrees are
sibling subfolders `Achaea/lv-*/`. All 36 session transcripts read on 2026-11-13 start in the parent.

## 1. What binds whom

| Gate | Binds | When | Source |
|---|---|---|---|
| CI `validate` job (`.github/workflows/build.yml`) | Every push to `main`, every `v*` tag | AFTER the push. `main` has no branch protection. A `v*` tag builds a release only if `validate` passes. | EMPIRICAL, the workflow file, 2026-11-13 |
| `tools/ci_local.py` | Whoever runs it | Before the push, by rule (CLAUDE.md, merge step 2). Nothing forces the run. It says `Ready to push: YES` only for a full run, every step PASS, on a tree equal to `HEAD`. | EMPIRICAL, 2026-11-13 |
| Git hooks | Nobody today | `core.hooksPath` is not set and `.git/hooks` has no active hook. A git hook would bind every `git push` from every folder and every client. | EMPIRICAL, `git config core.hooksPath` exits 1, 2026-11-13 |
| Claude Code hooks in `.claude/settings.local.json` | Nobody | Never loaded (section 2), and three could not block if they were (section 3). | EMPIRICAL + DOC, 2026-11-13 |

## 2. What loads in a session that starts in the parent folder

| Item | Loads? | Detail | Source |
|---|---|---|---|
| `LEVI-Achaea/.claude/settings.local.json` (hooks, status line, `env`) | **Never** | Settings load only from the folder the session started in, with no subfolder discovery. No transcript holds a SessionStart, PreToolUse, Stop or UserPromptSubmit record from a LEVI script. | DOC permissions.md "Where output styles, hooks and local settings load from"; EMPIRICAL 36 transcripts, 2026-11-13 |
| `LEVI-Achaea/CLAUDE.md` | **After the first file access below `LEVI-Achaea/`, truncated** | Each load carried 131,000 to 143,000 characters and ended "Only the start of this file is shown"; the cut was at line 1,105 to 1,185 of 3,901. The documented limit for an on-demand file is 40,000 characters on a 200K window and 150,000 to 200,000 on a 1M window. A worktree's own `CLAUDE.md` loads the same way. | EMPIRICAL 25 loads, 2026-11-13; DOC memory.md "Claude ignores the end of my subdirectory CLAUDE.md" |
| The same file after compaction | Summarised away | It returns on the next file access below `LEVI-Achaea/`. | DOC context-window.md "What survives compaction" |
| A `CLAUDE.md` in the parent folder, and its `@` imports | At launch, whole (up to 4 MiB) | An import resolves relative to the importing file, four hops deep. None exists today. That a parent file importing `LEVI-Achaea/CLAUDE.md` loads it at launch is inferred from the import rules. | DOC memory.md "Import additional files"; the inference is UNVERIFIED |
| `LEVI-Achaea/.claude/skills/` | After the first file access below `LEVI-Achaea/` | Absent from the first skill list in 36 of 36 sessions; listed later in 22. A name that collides with a built-in is listed as `LEVI-Achaea:verify`. A worktree's copies are listed as `lv-<name>:<skill>`. | EMPIRICAL 2026-11-13; DOC skills.md "Load skills in monorepos and subdirectories" |
| `LEVI-Achaea/.claude/agents/` | **Never** | Project agents are found by walking UP from the start folder. No transcript lists or spawns one. Every subagent spawned was a built-in type. | EMPIRICAL 2026-11-13; DOC sub-agents.md "Choose the subagent scope" |
| `LEVI-Achaea/.claude/rules/*.md` with `paths:` | UNVERIFIED | The docs say a nested rules folder loads on demand, and a `paths:` rule loads when Read, Write or Edit touches a matching file; globs are relative to the folder that holds `.claude`. No rules folder existed before 2026-11-13. First look, same day: in the session that wrote the rule file, a Read of a file under `src_new/tests/` in a worktree brought no rule text; that session had touched the folder before the file existed, so this proves nothing. Probe in a NEW session: `.claude/rules/tests.md` (its marker line). | DOC memory.md "Path-specific rules"; not seen |
| Auto memory | At launch: `MEMORY.md`, first 200 lines or 25 KB | The folder is keyed by the START folder (`~/.claude/projects/<parent path>/memory`), is outside git, and is not passed to subagents. | EMPIRICAL 2026-11-13; DOC memory.md "Storage location" |
| `autoMemoryDirectory: ".claude/memory"` in the parent `settings.json` | Ignored | The key needs an absolute path or `~/`. `Achaea/.claude/memory` is a stale copy from 2026-03. | DOC memory.md; EMPIRICAL file dates |
| Subagents: Explore and Plan | No CLAUDE.md, no rules | Other subagent types get the CLAUDE.md files that loaded at LAUNCH. Whether they get an on-demand nested `CLAUDE.md` is UNVERIFIED. A spawn prompt must carry the rules the agent needs. | DOC sub-agents.md "What loads at startup" |

Ways to load more, from the docs (none is in use; each needs a probe before a design uses it):
`/cd LEVI-Achaea` applies that folder's settings and hooks; `/add-dir LEVI-Achaea` loads its skills
and agents at once, but not its hooks; a skill can declare hooks in its frontmatter, active after
the skill is invoked.

## 3. Hook mechanics (for the day the hooks are repaired)

| Fact | Source |
|---|---|
| A command hook gets its input as JSON on **stdin** (`tool_name`, `tool_input`, `cwd`, `session_id`). No `TOOL_INPUT` environment variable is documented. `block-git-bypass.sh`, `lint-before-commit.sh` and `protect-config.sh` read `$TOOL_INPUT`. Test: `git push --force origin main` on stdin gave exit 0 (allowed); the same text in `TOOL_INPUT` gave exit 2. | DOC hooks.md "Common input fields"; EMPIRICAL test 2026-11-13 |
| Only exit 2 blocks a PreToolUse call. Exit 1 is a non-blocking error. | DOC hooks.md |
| stderr from a hook that exits 0 does not reach the model. `check-changelog.sh` and `pre-compact.sh` print to stderr and exit 0. | DOC hooks.md |
| There is a `PreCompact` event. A `Notification` hook with matcher `compact` matches nothing, so `pre-compact.sh` never ran. | DOC hooks.md "PreCompact", "Notification" |
| The matcher `Bash` does not match the PowerShell tool, which is this machine's first shell. | DOC hooks.md; the settings file |
| `CLAUDE_PROJECT_DIR` is the folder the session STARTED in (here the parent), also after `/cd`. A hook must take the repository from the payload (`cwd`, the file path), never from the process folder. | DOC hooks.md "Reference scripts by path" |
| `check-changelog.sh`: `grep -c ... \|\| echo "0"` gives two lines when nothing matches (grep prints 0 and exits 1), so its arithmetic fails and the reminder can never print. | EMPIRICAL, reproduced in bash 5.3, 2026-11-13 |

## 4. This machine (Windows 11, Git Bash)

| Fact | Source |
|---|---|
| `jq`, `pgrep`, `lua5.1` and `luac5.1` are not installed. `lua` and `luac` on PATH are Lua 5.4.6; Mudlet runs 5.1, so they give false results. | EMPIRICAL `command -v`, 2026-11-13 |
| `/c/Python314/python` has `lupa` (Lua 5.1) and `pyyaml`. `python3` on PATH is the Microsoft Store Python and has neither: under it `tools/ci_local.py` reports 10 steps NOT RUN and exits 2. | EMPIRICAL 2026-11-13 |
| A stale `Achaea/version.txt` (4.7.134) sits in the parent folder. A command that reads `version.txt` from the session's start folder reads the wrong one; use the worktree's absolute path or `git -C`. | EMPIRICAL 2026-11-13 |
| The Mudlet profile and the KB inbox file are inside OneDrive: conflict copies can hide the real save. | Memory `onedrive-save-conflicts`; CLAUDE.md |

## 5. How to change this page

- Add a row only with its source and date. Change `UNVERIFIED` only after a probe, and say where the probe was seen.
- When a row changes, grep for documents that state the old fact (`CLAUDE.md`, `GETTING_STARTED.md`, `.claude/agents/`, `.claude/skills/`) and correct them in the same change.
- Origin: the adoption review of the TAOM repository, `docs/reviews/adopt-taom-2026-11-13.md`.
- The `DOC` rows were read from the documentation by a research agent on 2026-11-13 and were not each re-read by a person. Where a `DOC` row and an `EMPIRICAL` row disagree, the `EMPIRICAL` row is what happens here.
