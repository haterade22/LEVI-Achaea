# Adoption review: the TAOM repository (2026-11-13)

**Source:** `github.com/haterade22/TAOM`, the maintainer's Bannerlord total-conversion mod. Its value
here is its agent harness and its engineering process, not its game content. `HEAD` was `d7aa64a62`
when this record was written; the readers ran earlier the same day.

**Question asked:** which knowledge, skills, processes and concepts of TAOM can LEVI-Achaea use?
A one-to-one port is not the goal. The method behind each item is.

**Rule of this review (taken from TAOM's own adoption method):** read first, port the idea in this
repository's words, copy no file, record every deferral and every cut with its reason.

## Coverage

| Stage | Agents | What they did |
|---|---|---|
| Read TAOM | 14 readers, 1 completeness critic | 15 lanes: knowledge tiers, rules, hooks, multi-AI policy, review skills, delivery, investigation, improve/audit, retro and adoption, lessons, agents and tools, testing gates, docs system, analysis and simulation, and what the lanes missed. 270 practices, each with its evidence path. |
| Map LEVI-Achaea | 3 readers | The harness, the tooling and CI, the knowledge base. |
| Map and refute | 15 mappers, 15 skeptics | Each practice checked against this repository's files; each recommendation attacked (already exists, breaks a constraint, the source does not support it, costs more than it gives, the proposed form is wrong). |
| Facts | 6 fact checkers | What loads in a real session (36 transcripts), the Claude Code documentation, the sections of `CLAUDE.md`, the lesson stores, the path areas, the CI and release chain. |
| Design | 3 architects, 2 critics | Three roadmaps (foundation first, loop first, smallest viable). Both critics chose "smallest viable", with corrections taken from the other two. |

Not read in full: TAOM files over about 150 KB (structure and samples only), and its game-content
tools. `CLAUDE.md` sections "Current System Components", "Key Concepts" and "Defense Systems" here
were measured and sampled, not read line by line.

The row data (270 practices with the mapper's verdict, the skeptic's outcome and the final
verdict) is `adopt-taom-2026-11-13-rows.json` beside this file.

## Result in numbers

| Final verdict | Count | Meaning |
|---|---|---|
| ADOPT_NOW | 74 | Cheap, clear benefit, form known |
| ADOPT_PLANNED | 73 | Worth it, needs design or more than half a day |
| LATER | 82 | Useful only after other items, or benefit unclear today |
| REJECT | 41 | Game-specific, already present here, or costs more than it gives |

The skeptics upheld 121 recommendations as written, corrected the form of 124, moved 22 one step
later and 3 one step earlier. 20 practices already exist here in an equal or stricter form (most
of the simulator and evidence rules: frozen gates, provenance tags, `kb/CONFLICTS.md`).

## Baseline (2026-11-13, before any change)

| Measure | Value |
|---|---|
| `CLAUDE.md` | 450,746 bytes, 3,901 lines; 72,024 bytes on 2026-06-01 |
| `CLAUDE.md` delivered to a session | About 131,000 to 143,000 characters (to about line 1,140); the rest never loads |
| Largest section | Mnemosyne, 180,468 bytes (40%) |
| Claude Code hooks that ran in 36 sessions | 0 of 8 |
| Custom agents offered in 36 sessions | 0 of 6 |
| Local check before `main` | A list of commands in 3 documents, 3 steps behind `build.yml` |
| Release-chain steps with no enforcement but memory | 9 of 14; 10 dated failures on record |

The facts behind these rows are in `docs/reference/harness-facts.md`.

## What TAOM does that this repository did not

1. **One home per fact, at the narrowest trigger** (TAOM ADR-011). A machine check replaces prose
   where a machine can check. An always-loaded file holds only what every task needs. TAOM learned
   this after a trim regrew: 91 KB cut to 28 KB, back to 49 KB in six weeks. Its cure was a byte
   budget enforced as a ratchet, plus a rule that names the home of each kind of fact.
2. **No evidence is not a pass.** Each checker has three results: pass, finding, NOT RUN. Empty
   input, a missing tool or a skipped step can never read as green.
3. **A gate is done when it has refused one real bad input** where it runs. Nearly every TAOM
   hook rule exists because a gate was once silently dead while its tests stayed green.
4. **Gates that bind every committer.** Git hooks, not only AI-client hooks.
5. **A sourced, dated record of how the AI client behaves** (what loads when, what a subagent
   receives), so that rules are placed where they are delivered.
6. **A finding is a hypothesis.** A reviewer's or a subagent's claim is re-read at the source
   before a fix. A verifier that returns nothing is UNVERIFIED, never REFUTED.
7. **Lessons live in a grep-first ledger; one line is promoted** into the rule that loads with the
   files it concerns, or into a gate.

## Adopted: the seven phases

Each phase ships alone. No phase changes shipped Lua, so none has a version bump.

| Phase | What | Evidence of need | What triggers it without a person remembering |
|---|---|---|---|
| 1 | Exit 2 = NOT RUN in `kb_sim.py`, `kb_rules.py`, `theorycraft.py`, `run_lua_tests.py`, `test_runner.lua`, `check_orphans.py`. One runner, `tools/ci_local.py`, over one list, `tools/ci_steps.json`. | `kb_sim.py --check` exited 0 with "skip" under the `python3` on PATH. v4.7.477 and v4.7.484 failed on `main` after a partial local run. | `tools/test_ci_local.py` is a CI step: it fails when a step of the `validate` job has no row, a row has no step, or a test or check has no row. Done 2026-11-13; an adversarial review before the push confirmed 28 defects, among them a CI step that would have failed on Linux. |
| 2 | `docs/reference/harness-facts.md`. `CLAUDE.md` reordered so the every-task rules load; false "the hooks block" claims removed; `lua5.1` commands corrected; this record. A canary path rule, `.claude/rules/tests.md`. Issue #177 for the profile-backup restore defect. | Two thirds of `CLAUDE.md` never loads. Five skills named a tool this machine lacks. A known defect was recorded only past the load cut. | The reorder puts the rules inside the delivered part. The canary answers whether path rules load here. |
| 3 | `.githooks/pre-push`: refuses two `v*` tags in one push, a tag that differs from `version.txt` at its commit, a tag whose commit is not on `origin/main`, a forced update of `main`. | v4.7.208 (`push --tags`), v4.7.313 (tag on the wrong commit), v4.7.448 (tag on an unmerged branch). | Git runs it on every push, from any folder and any client. |
| 4 | `docs/adrs/002-knowledge-delivery-tiers.md` (the one-home ladder). `tools/check_context_budget.py`: a grow-only ceiling on `CLAUDE.md`, and a moves check that proves no line was lost. Large blocks move to `.claude/projects/<system>/` and `.claude/classes/`. Target: 120,000 bytes. | `CLAUDE.md` grew 54,089 bytes in 13 days. | The budget check is a step of `ci_local.py` and CI. |
| 5 | The core under 40,000 characters, written last. A two-line `CLAUDE.md` in the parent folder imports it, so it loads at launch. | The documented limit for an on-demand file on a 200K window is 40,000 characters. A nested file is lost at each compaction. | The budget becomes an absolute cap. |
| 6 | `docs/ai-includes/agent-brief.md`: the one file a spawn prompt names. Area rules, one at a time, if the canary passed. | Every subagent in 36 sessions was a built-in type; Explore and Plan get no `CLAUDE.md`. | One core line; workflow scripts stop when the brief is empty. |
| 7 | Report-only gates for shipped defects: a global-leak report in `test_runner.lua`; timer ids on saved namespaces and banned calls in `check_orphans.py`. `tools/release.py tag-ready` and `post`. | "One shared Lua state" is recorded in six places. The build-folder refresh was skipped three times. | Each report is a CI step; it turns strict when clean. |

## Deferred, each with the condition that reopens it

| Item | Rows | Reopen when |
|---|---|---|
| Repair of the Claude Code hooks (stdin input, `Bash\|PowerShell` matcher, registration in the parent folder from a tracked manifest, a hook test file) | hooks#2, #4, #8, #12, #13, #14, #15 | A second incident that a git hook cannot stop. First probe a hook declared in the `version-bump` skill's frontmatter. |
| `build.yml` calls `tools/ci_local.py` as its only step list | ci-chain design | 20 runs on `main` where the local verdict matched CI. |
| Investigation skill (ranked hypotheses with predictions, "name the one check that goes red", three-strike stop) | investigate#3 to #8, #15 | The next defect that takes two releases to correct. |
| Codex dispatch contract, prompt skeleton, "known suspects", reviewer track record | multi-ai#3, #5, #13; review-skills#1, #2, #3, #16 | The next Codex review request (two in seven months). |
| Review lens files and the verify-table protocol | review-skills#5, #6, #7, #10, #11, #15 | The next deep review of a system. |
| Merge of the lesson stores (`.claude/AGENTS.md`, memory `bug-patterns.md`) into one ledger with four-part entries | knowledge-tiers#9, lessons#2, #6 | After phase 5. `.claude/AGENTS.md` stays the ledger until then. |
| The other 12 proposed path rules and full trap sheets | rules#1, lessons#1, knowledge-tiers#5 | The phase 2 canary passes; then one rule when a task touches its area. |
| Citation check for `file:line` references in docs; ledger check for `kb/CONFLICTS.md` numbering | knowledge-tiers#15, docs-system#14 | After phase 5 (the first report on a 450 KB file is too long to act on). |
| `--check` modes for `kb_catalog.py`, `kb_affliction_db.py`, `kb_wiki_skills.py` | docs-system#16 | One of those pages is next found stale; a clean regeneration comes first. |
| Fight-log version on the importer's summary row; a shared fixture for the log format | investigate#2, #14; analysis-sim#7, #11 | The next log import. |
| Transcript miner run as a retro of these phases | retro-adopt#0, #16 | 30 days after phase 2. Keep the miner's output outside the repository; commit counts only. |
| Plan template with a cold review; plans kept in git | improve-audit#0, #8 | The user approves publishing the two plans that `tools/sim/gates_whole.json` cites. |
| Game-update response skill (confirm, preserve, diff, re-verify) | critic#0, #1 | The next game announcement that changes a class. |

## Cut, each with its reason

| Item | Reason |
|---|---|
| A root `AGENTS.md` beside `CLAUDE.md` (three-file entry split) | A third entry file and about 25 renamed references, for a second client used for two reviews in seven months. Shipped Lua comments name `.claude/AGENTS.md`; a rename is a code change. |
| Pre-commit and commit-msg git hooks | Paid on every commit; they judge an index that other sessions stage into; they repeat `ci_local.py --quick`. |
| A rule "a tag must be above every existing tag" in the push hook | It refuses the documented recovery (delete a tag, push it again) whenever a newer tag exists, which is normal at six tags a day. A warning only. |
| Owed-check ledgers (`live-checks.md`, a "waiting on you" file) | A hand-kept file appended six times a day. `kb/CONFLICTS.md` and the "Open" bullets in `CHANGELOG.md` already hold owed checks. |
| A changelog generated from commit bodies; one file for each version | The standing rule is that `CHANGELOG.md` gets the entry. Only the heading check is kept. |
| A total floor on the Lua test count | A hand-kept number inside a blocking step. "Zero files is NOT RUN" covers the collapse case. |
| A `docs/systems/` folder | `.claude/projects/<system>/` exists and is tracked. A second home is the duplication this work removes. |
| Separate hooks catalog, hook-authoring rule and shell-traps documents | Three documents for eight scripts that do not run. One page: `docs/reference/harness-facts.md`. |
| A byte ceiling on `.claude/AGENTS.md` | Nothing auto-loads it, and it is the home of new lessons. A cap would block lesson capture. |

## Rejected at the mapping stage (41)

The reason for each is in the rows file. The groups:

- **Already present here, often stricter (20):** frozen simulator gates, a baseline and placebo
  block, provenance tags on every rule, sample admission rules, raw evidence that is never edited,
  the open-questions register (`kb/CONFLICTS.md`), break-back of every fix, worktree isolation.
- **Needs a thing this repository does not have (12):** an unattended run of the game with an arm
  file and a done file (the live game cannot run unattended), marker regions inside generated
  pages, validator codes for a commit hook, a review-packet tool for two providers, skill routing
  evals for skills that are almost never invoked.
- **Costs more than it gives for one maintainer who ships six versions a day (9):** a 30 KB context
  scan script, a run-control tool, an issue for every change, a doc link-graph tool.

## Open probes (a person must start the session)

| Probe | Why | Record the result in |
|---|---|---|
| Start a session in the parent folder, read one file under `src_new/tests/`: does `.claude/rules/tests.md` load? Repeat in an `lv-*` worktree. | Decides whether area knowledge can live in path rules. | `docs/reference/harness-facts.md`, section 2 |
| After phase 5: does a two-line parent `CLAUDE.md` that imports the core load it at launch? | Launch loading survives compaction and reaches non-Explore subagents. | The same section |
| `/add-dir LEVI-Achaea`: are the six agents offered? | Decides whether the custom agents can be used at all. | The same section |

## Follow-up

A second look 30 days after phase 2: compare the baseline rows above with the values then, and
give each phase one of TAOM's five verdicts (helped, hurt, no observed effect, confounded, too
early). "No change" is a valid result.
