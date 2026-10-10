---
name: kb-ingest
description: File new Achaea material from the knowledge-base inbox file into kb/ (raw + curated), cross-check it against the code, and report conflicts
user_invocable: true
---

# KB Ingest

Turn whatever the user pasted into the inbox file into knowledge-base entries. Read
`kb/README.md` first. It defines the layout, the confidence tags and the rules this skill
follows.

**Afflictions and cures are the core of the KB** (user, 2026-10-10). For any material that
touches an affliction, record both sides: how the affliction is given and cured, how the
TARGET responds (class cures, lines we can see), and how WE respond (SSC priority, our code).

## Arguments
- Optional: a path to ingest instead of the default inbox file (`--src`).

## Steps

1. **Find what is new.**
   `python -I tools/kb_inbox.py status [--src <path>]`
   It prints numbered chunks of new text. If it says "Nothing new", stop and say so. If it
   reports changed or removed lines, tell the user which earlier material changed.

2. **Classify each chunk.** Decide what kind of source it is:
   - `help`: starts with a HELP number or title, or reads as an in-game help file
   - `ab`: `AB <skill>` output (syntax / works on / balance lines, AB numbers)
   - `live`: `WHATCURES`, `AFFLICTION SHOW`, `CURING PRIORITY LIST`, `DEF`, `SCORE` and similar
   - `announcements`: a game news post or announcement
   - `logs`: combat or death output with prompts
   - `guides`: a community write-up (player names in examples, opinions, "rough scribbles")
   If a chunk is ambiguous, ask the user rather than guessing.

   **`WHATCURES` lines are special:** append each one, verbatim, to `kb/raw/live/whatcures.txt`
   (keep the date comment) instead of making a new file. `tools/kb_catalog.py` reads that file
   and puts the answer in the catalog's Live column. A later line for the same affliction wins.

3. **Save the raw text verbatim** to `kb/raw/<kind>/<descriptive-slug>.txt` (use
   `<skill>_<YYYY-MM-DD>` for AB output, the HELP number for HELP files). Change only line
   endings. Never edit a raw file that already exists. If the text is a newer version of a
   raw file, save it under a new dated name.

4. **Update or create curated pages.** Follow `kb/_template.md`. Put content where it
   belongs:
   - affliction, cure, curative, lock or class-cure facts -> `kb/afflictions/` or `kb/curing/`
   - class abilities -> `kb/classes/<class>/<skill>.md`, linked from `.claude/classes/<class>.md`
   - anything else -> a new topic folder, listed in `kb/README.md` and `kb/INDEX.md`
   Add each raw file to the page's `sources:`. Tag every claim's confidence. Live output beats
   HELP, and HELP beats a guide. **Write the "why"** (what it means for offense and for curing),
   not just the fact.

5. **Cross-check against the code.** This is the step that makes the KB useful. For each
   fact the code depends on, grep for it and compare:
   - cures: `curingTable` (`curing/002_Wide_Groups.lua`), `curingTableV3`, `smokeCureTableV3`,
     `salveCureTableV3` (`affliction_tracking_core/007`)
   - our cure order: `ataxia_defaultCuringPrios()` (`ataxia/001`), `ataxia_bashCuringPrios()` (`ataxia/008`)
   - opponent cure lines: `src_new/triggers/.../passive_active/` (check the class gate in the body)
   - abilities, cooldowns, costs: the class's offense or basher code (`grep` the command)
   - fire lines: `grep -rF "<distinctive phrase>" src_new/triggers`
   Every mismatch goes into `kb/CONFLICTS.md` (what each side says, the impact, how to settle
   it). **Do not change Lua code in this skill.** Report the mismatch and let the user decide.
   Doc-only errors (CLAUDE.md, `.claude/databases`, `.claude/classes`) that a stronger source
   disproves should be corrected, and the correction logged under Resolved.

6. **Regenerate generated pages.** If the affliction cure table, `curingTable` or the
   priority tables were involved: `python -I tools/kb_catalog.py`.

7. **Update the index.** Add new pages and raw files to `kb/INDEX.md`.

8. **Mark ingested** only after everything above is filed:
   `python -I tools/kb_inbox.py mark [--src <path>]`

9. **Report** to the user, briefly:
   - what was filed, and where (links)
   - the conflicts found, most important first, especially any that affect tracking or curing
   - the pastes that would fill the biggest gaps next (for example `WHATCURES <aff>` for an
     affliction with no source)

Do not commit unless the user asks. The KB is docs and tooling only, with no package version
bump.
