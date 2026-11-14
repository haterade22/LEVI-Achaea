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
│   ├── wiki/          Achaea wiki pages, raw wikitext (`tools/kb_wiki_skills.py`)
│   ├── live/          live command output: whatcures.txt (one WHATCURES line per capture), ...
│   ├── guides/        community guides (lower confidence than HELP)
│   ├── ab/            AB <skill> output        (add as pasted)
│   ├── announcements/ game announcements       (add as pasted)
│   └── logs/          combat or death logs worth keeping
├── classes/           every class's skills and abilities (from the wiki, generated)
├── changes/           game announcements: one page per post, each change with its fight impact and code join
├── combat/            classes as they look in real fights: every line, both sides (from logs)
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

   Pages built from the logs ([mechanics/foundations.md](mechanics/foundations.md) and the generated pages beside it) use three more:
   - **MEASURED**: counted from log rows. Boards are the loggers' beliefs, so this is a count and not a proof.
   - **READ**: stated in a file, and not tested here.
   - **INFERRED**: a reasoned reading of the rows, not proven.
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

### Adding combat logs

1. Put the Mudlet HTML export in `kb/raw/logs/`. Add as many as you like.
2. In the repo: **`python tools/kb_log_import.py`**. It writes one `.txt` per new fight beside the
   export and prints a manifest. It skips a copy of a fight that is already filed, and it never moves
   or edits the export. `--check` compares each export with its text, row by row.
3. Rename the new file when a read of the log shows the classes, and add it to the table in
   [raw/logs/README.md](raw/logs/README.md). The tool cannot tell classes.
4. Run **`python tools/kb_timing.py`**. It regenerates [mechanics/clocks.md](mechanics/clocks.md) and
   [mechanics/scoreboard.md](mechanics/scoreboard.md) from every filed log. CI runs it with `--check`, so a new log
   without this step fails the build. A log with a new prompt shape shows up as no family in `--counts`.
5. Run **`python tools/kb_replay.py`**. It regenerates [mechanics/replay.md](mechanics/replay.md), the test of the lock labels and
   the route rules against every death. CI runs it with `--check` too. Never change a rule in `RULES` to pass it: a rule
   changed after its result is POST-HOC and counts toward no bar. The next kill in a new log is the real test, so read this page after filing one.
6. Run **`python tools/kb_sim.py --check`**. If it prints STALE, run `python tools/kb_sim.py` (about 12 minutes). It regenerates
   [sim/forward.md](sim/forward.md). It goes stale when a Serpent log adds a board, or when a clock median moves by 0.01 s. CI runs the check. It
   needs `lupa`, and it runs on the Lua 5.1 inside it. If `test_kb_sim.py` fails on the gap inputs, copy the new DSTAB numbers from `clocks.md` into `kb_sim.py` and run it again.
7. Run **`python tools/kb_rules.py --check`**. If it prints STALE, run `python tools/kb_rules.py`: a new log moved a clock in
   `clocks.json`, or a file the rules read changed (`rules_hand.json`, `afflictions.json`, `venoms.yaml`, the default priorities,
   `001_Miscellaneous_Aff_Tracking_Methods.lua`, `008_V3_Integration.lua`, `003_Lock_breakers.lua`), so [sim/rules.md](sim/rules.md) changes. Then run `python -B tools/test_theorycraft.py`. If its golden text
   fails because a clock moved, read the new text of the example, then paste it into the test. Never change
   `tools/sim/gates_whole.json` to pass. `python tools/kb_events.py --check` reads only the four frozen Serpent logs, so a new
   log does not make it STALE. The next Serpent log from a VICTIM's seat is scored once against the frozen bars before any refit
   (see "A log from our own seat" below).

The HTML exports are git-ignored. The text files are the evidence. Our own recordings use a separate
tool: `python tools/fightlog_import.py` copies `<profile>/fightlogs/` into `kb/raw/logs/ours/`. In an `aconfig rounds alias` fight its
"commands we sent" row counts alias rewrites, and in a raw fight it counts presses. Add `--score` to print the round
delivery pass bars beside each log's numbers. Run steps 4 and 5 after this too.

**A log from our own seat is not the holdout.** The 2026-11-07 Serpent spar is one fight in two files:
`raw/logs/ours/2026-11-07_164635_Saibel.log` (the recording) and `raw/logs/2026-11-07_serpent-spar-saibel.txt` (the screen
log, with the echoes the recording leaves out; `kb_timing.SAME_FIGHT` keeps it out of every count). We attacked and Saibel
only cured, so it gives inputs about OUR seat: our own costs and round ([sim/rules.md](sim/rules.md), `attack.cost.own.*`,
`attack.gap.own`), the IMPULSE bite, and what her third-person lines show (potash on its own clock, CONFLICTS Resolved
2026-11-07). The user decided that no Saibel number becomes a victim default (`ssc.delay.gain.Saibel` is an alternative
only), and that the gates' holdout waits for the next log from a victim's seat. `tools/sim/gates_whole.json` is unchanged:
its note still says "the spar included", and this decision overrides it. The gate rows G1-G5 in
[mechanics/replay.md](mechanics/replay.md) did not change.

### Capturing straight from the game (`kbcapture`)

For anything the game will answer on request, let the package ask and record it instead of
copying by hand:

1. In Mudlet, somewhere quiet, with the basher off: **`kbcapture afflictions`**. It sends
   `AFFLICTION LIST`, then `AFFLICTION SHOW <aff>` and `WHATCURES <aff>` for every affliction our
   code knows (about 5 minutes, output hidden). `kbcapture help cures | help heal` captures any
   commands you list, separated by `|` (not `;`: Mudlet splits `;` before the alias sees it). `kbcapture stop` ends early, and `kbcapture` shows progress.
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

## Capture tools

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). The routes above say when to use each tool; this says what each one does.

**`kbcapture afflictions`** (in Mudlet, `misc_scripts/025_KB_Capture.lua`) asks the game `AFFLICTION LIST`, then `AFFLICTION SHOW` + `WHATCURES` for every affliction our code knows AND every one the game lists (203 on 2026-10-10; separate ad-hoc commands with `|`, never `;`) and writes the raw answers to `<profile>/kb_capture.txt`; `python tools/kb_capture_import.py` files them into `kb/raw/live/`. Capture records, the repo parses. **`kbcapture abilities [from[-to]]`** (v4.7.494, record shape fixed v4.7.496) asks `ABADMIN SHOW <n>` for every id (default 1-4000, about 0.7 s each; it stops after 300 ids in a row with no record, and the done line gives the id to resume from). A record starts `Ability: <name> (Record #<n>)` then `Associated skill: <skill>`; a pointer record adds only `Maps to record <n> (<NAME>).`; an id with no ability answers `No such record.`, and both first lines are its EXPECT shape. **v4.7.494 looked for `ABADMIN ID: <n>`, the header of the `AB` command**, so its first run counted all 287 records as misses and stopped at id 300: never take an answer's layout from a sibling command; capture one answer first. The importer files each record as `kb/raw/abadmin/<skill>_<ability>_<id>.txt` by the id in its own first line (the newest capture wins; `kb/raw/ab/` holds `AB` answers, a different layout, and is not touched), and `tools/kb_abadmin.py` turns `kb/raw/abadmin/` into `kb/classes/abadmin.json` + `abadmin-vs-wiki.md` + `battlerage.md` + `shield.md` (`--check` in CI; `abilities.json` is not changed). Since 2026-11-13 `kb_timing.py` takes a stated cost from `abadmin.json` first and from `abilities.json` only where no record states a number, so a new capture changes `clocks.md`. **The full run (2026-11-13) filed 3079 records, ids 1-3296** (ids 3293-3296 are empty slots, `Ability:  (Record #3293)`; id 73, asked again, has no record). The page compares only a value that both sides state. The game corrects Serpent BITE to 1.90 s (the wiki: 4.00), and a record can contradict itself (FREEZE: Cooldown 2.20 s, Extra info 3.00 s targeted). **A record with no `Pre checks` value shows the DEFAULT flags** (arms 0, legs 0, entangled No, paralysed No: 2456 of 2576 such records, and none says paralysed Yes), so a `Useable paralysed: No` there is no evidence; check a flag against a log before code reads it (`abadmin-vs-wiki.md`, "Pre checks and the flags"; `kb/CONFLICTS.md` #82). **`Aggression type: non-aggressive` is a default too** (2457 of those 2576; DSTAB says it), so only the two `aggressive` values are statements: Hypnosis IMPULSE says it bypasses a shield, which the simulator does not follow (`kb/CONFLICTS.md` #83); the shield breakers say `bypasses` too, and `shield.md` lists every class's values. `Requires arms: 0` is a default as well (no Monk, Serpent or Blademaster record states an arm); a stated `1` means the attacker needs at least one unbroken arm (the user, 2026-11-13), so two broken arms stop Psion Weaving and Emulation and most Pariah attacks. With both of OUR arms out (`ataxia_selfArmsOut`, `self_limb_tracking/002`: broken, damaged or mangled), the Psion offence sends Psionics only (v4.7.499, `psion.armsOut`) and the Pariah offence sends VIRULENCE only, or nothing (v4.7.500). `ataxia_selfLimbBroken` (the SLC both-arms flee) reads only damaged and mangled, not the game's level-1 `brokenleftarm`, and that stays (the user, 2026-11-13: one apply cures a broken arm at once, so two broken arms are very low priority). **`kbcapture artefacts`** asks `ARTEFACT POWER LIST OWNED`, saves our powers (the same as `aconfig artefact scan`), then `ARTEFACT POWER SHOW <p>` for each; they go to `kb/raw/live/artefact_power_list_owned.txt` and `kb/raw/artefacts/<p>.txt`. A power record gives the levels, "Owner only", "Must be worn", the owned item and the price, and **no effect size** (`docs/my-artefacts.md`, "The game's power records").

**`fightlog`** (v4.7.418, `misc_scripts/026_Fight_Log.lua`) records our PvP fights to `<profile>/fightlogs/`: every game
line as the game sent it (gagged or not), prompts, every command we sent (echoed or not), our GMCP afflictions and
defences, and our tracker's changes to the target, each with a millisecond timestamp. It starts on its own (a player
attacks us, or we queue a command, or send a raw attack, naming our target while the target is a player in the room:
a Serpent round queues only its first piece and sends the attack raw, `F.isAttack`, `026_Fight_Log.lua`:172-183) and
stops after a kill, a death, an arena verdict or 60 s with nothing naming the opponent. Its header ends with
` | rounds raw|alias`; on a Serpent (v4.7.479) ` | serpent attackfirst on|off` comes just before it, so a log says
which round order it holds (`026_Fight_Log.lua`:272-284). `python tools/fightlog_import.py` copies the logs
into `kb/raw/logs/ours/` and summarises them; it reads the Mudlet profiles on this machine, so run it before
analysing one of the user's fights. Row format: `kb/raw/logs/README.md`.
