# Achaea Knowledge Base

A reference to Achaea that is checked against the code, for people and for the AI working on
this package. **Afflictions and cures are the core**, because Achaean combat comes down to
giving afflictions and curing them. Start at [afflictions/README.md](afflictions/README.md).

Every page is listed in [INDEX.md](INDEX.md). Disagreements still to settle are in
[CONFLICTS.md](CONFLICTS.md).

## Layout

```
kb/
├── README.md          this file: how the KB works
├── INDEX.md           one line per page
├── CONFLICTS.md       open disagreements: game text vs game text, and game text vs code
├── _template.md       shape of a new entry
├── inbox/             ingest state (snapshot of the source file at the last ingest)
├── raw/               VERBATIM source text. Never edited. The evidence for every claim.
│   ├── help/          HELP files (in-game)
│   ├── live/          live command output: whatcures.txt (one WHATCURES line per capture), ...
│   ├── guides/        community guides (lower confidence than HELP)
│   ├── ab/            AB <skill> output        (add as pasted)
│   ├── announcements/ game announcements       (add as pasted)
│   └── logs/          combat or death logs worth keeping
├── afflictions/       THE CORE: the model, catalog, channels, class cures, locks, limb damage
├── curing/            curatives, server-side curing (incl. your live state)
├── defences/          defence names and upkeep
└── mechanics/         balance, equilibrium, the server queue
```

New top-level topics (`classes/`, `mechanics/`, `mnemosyne/`, `items/`, ...) get created the
first time material for them arrives.

## Rules

1. **Raw is evidence and is never edited.** Each curated page lists its `sources:` in
   frontmatter. When a source turns out to be wrong, say so in the curated page and leave the
   raw file alone.
2. **Tag confidence.** The levels, strongest first:
   - **CONFIRMED (live)**: game output we captured (`WHATCURES`, `AB`, a combat log line)
   - **CONFIRMED (HELP)**: an in-game HELP file. Can be stale. Live output wins.
   - **CONFIRMED-in-code**: the code does it and a test or changelog shows why
   - **guide**: a community write-up
   - **ASSUMED**: inferred and not checked. Never promote it silently.
3. **Join to the code.** If a fact is something the code depends on (a cure, a priority, a
   fire line, a cooldown), name the file and say whether the code agrees. A disagreement goes
   into [CONFLICTS.md](CONFLICTS.md).
4. **The affliction database** (`afflictions/database.md` + `afflictions.json`) is GENERATED from
   `raw/live/affliction_show/` by `python tools/kb_affliction_db.py` (the importer runs it).
5. **Compare live state with the code.** `python tools/kb_prio_diff.py <captured CURING PRIORITY LIST>`
   shows where the server's priorities differ from `ataxia_defaultCuringPrios()`.
6. **Generated pages are not hand-edited.** [afflictions/catalog.md](afflictions/catalog.md)
   comes from `python tools/kb_catalog.py`. Re-run it after changing the raw cure table or
   the code's cure/priority tables.
7. **Pure ASCII in anything that becomes an echo string.** KB prose can use markdown freely.

## Adding material

1. Paste anything into `C:\Users\mikew\OneDrive\Desktop\Achaea Knowledge Base.txt`. Append
   to the end. A line of `=====` between pastes helps, but is optional.
2. In Claude Code, run **`/kb-ingest`**. It runs `python tools/kb_inbox.py status` to find
   what is new since the last ingest, files the raw text, updates or creates the curated
   pages, checks them against the code, reports conflicts, and then marks the file ingested.

### Capturing straight from the game (`kbcapture`)

For anything the game will answer on request, let the package ask and record it instead of
copying by hand:

1. In Mudlet, somewhere quiet, with the basher off: **`kbcapture afflictions`**. It sends
   `AFFLICTION LIST`, then `AFFLICTION SHOW <aff>` and `WHATCURES <aff>` for every affliction our
   code knows (about 5 minutes, output hidden). `kbcapture help cures;help heal` captures any
   commands you list. `kbcapture stop` ends early, and `kbcapture` shows progress.
2. In the repo: **`python tools/kb_capture_import.py`**. It finds `kb_capture.txt` in your Mudlet
   profile, files every answer into `kb/raw/live/` (a full copy in `captures/`, one file per
   affliction in `affliction_show/`, new lines appended to `whatcures.txt`), renames the source
   file so the next run starts clean, regenerates the catalog, and lists any command that got no
   answer. Those are usually names the game spells differently from our code.

The capture records raw text only and the importer does the understanding, so a parser can be
improved and re-run without going back into the game.

The pastes that teach the most, best first:
- `WHATCURES <affliction>` and `AFFLICTION SHOW <affliction>` (live, beats HELP)
- `AB <skill>` for any class we fight or play
- `HELP <topic>` files
- Death logs and combat logs (they show what killed us and which cures fired)
- Game announcements that change mechanics
