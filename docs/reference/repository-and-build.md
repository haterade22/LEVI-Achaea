# Repository structure, build system and IDE setup: the reference that was in CLAUDE.md

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

## Repository Structure

```
LEVI-Achaea/
├── .claude/
│   ├── AGENTS.md              # Agent instructions for AI development
│   ├── classes/               # 26 class files + lock_types.md
│   ├── agents/                # Custom Claude Code subagents
│   │   ├── offense-system.md  # Class offense development agent
│   │   ├── build-and-version.md # Build + version management agent
│   │   ├── team-class-offense.md # Parallel team development agent
│   │   ├── fast-reader.md     # Tier 1: Haiku/low -- search, read, run tests/builds
│   │   ├── implementer.md     # Tier 2: Sonnet/medium -- everyday coding from a plan
│   │   └── architect.md       # Tier 3: Opus/high -- design, hard debugging, review
│   ├── skills/                # Claude Code skills (slash commands)
│   │   ├── build/SKILL.md     # /build — full build pipeline
│   │   └── version-bump/SKILL.md # /version-bump — sync 3 version files
│   └── settings.local.json   # Project permissions + hooks
├── .github/
│   └── workflows/build.yml   # CI/CD: syntax check, version check, tests, release builds
├── .vscode/
│   ├── settings.json          # Lua 5.1 config, Mudlet globals, diagnostics
│   ├── extensions.json        # Recommended: sumneko.lua + mudlet-scripts-sdk
│   └── tasks.json             # Build, convert, test, clean tasks (Ctrl+Shift+B)
├── kb/                        # Achaea knowledge base: raw game text + curated, code-checked pages (start: kb/INDEX.md)
├── docs/
│   ├── plans/                 # Project plans and reviews
│   ├── legend-deck.md         # Legend Deck card reference
│   └── artefacts-reference.md
├── src_new/                   # Canonical source (YAML-header Lua files)
│   ├── aliases/               # Alias definitions
│   ├── keys/                  # Key bindings
│   ├── scripts/               # Lua script modules (combat, basher, GUI, NDB, etc.)
│   ├── timers/                # Timer definitions
│   ├── triggers/              # Trigger definitions
│   └── tests/                 # Unit tests (not included in Muddler build)
│       ├── mock_mudlet.lua    # Mudlet API mock (200+ function stubs)
│       ├── test_runner.lua    # Minimal test framework (describe/it/expect)
│       └── test_*.lua         # Test files
├── muddler_project/           # Muddler build project for Levi_Ataxia
│   └── mfile                  # Package metadata JSON (version must match version.txt)
├── tools/
│   ├── convert_to_muddler.py  # Convert src_new → muddler project (multi-package)
│   ├── compare_builds.py      # Compare old XML vs Muddler output
│   ├── mudlet_extract.py      # Extract XML package to src_new
│   ├── flatten_groups.py      # Flatten intermediate wrapper groups in _groups.yaml
│   ├── kb_inbox.py            # KB: what is new in the inbox file since the last /kb-ingest
│   ├── kb_catalog.py          # KB: regenerate kb/afflictions/catalog.md from HELP + code tables
│   ├── kb_capture_import.py   # KB: file in-game `kbcapture` output (Mudlet profile) into kb/raw/live/, kb/raw/abadmin/ (ABADMIN SHOW) and kb/raw/artefacts/
│   ├── test_kb_capture_import.py # its tests (the ABADMIN SHOW and artefact routes): `python -B tools/test_kb_capture_import.py` (in CI)
│   ├── kb_abadmin.py          # KB: kb/raw/abadmin/*.txt -> kb/classes/abadmin.json + abadmin-vs-wiki.md (the game's ABADMIN SHOW record against the wiki) + battlerage.md (every class's battlerage records: rage, cooldown, the affliction each gives or uses) + shield.md (per class, the records that say a shield blocks them or that they go through); `--check` in CI
│   ├── test_kb_abadmin.py     # its tests (in CI)
│   ├── fightlog_import.py     # copy in-game `fightlog` recordings into kb/raw/logs/ours/, summarise them; `--score` prints the round delivery pass bars
│   ├── test_fightlog_import.py # its tests: `python -B tools/test_fightlog_import.py` (in CI)
│   ├── kb_log_import.py       # KB: convert Mudlet HTML log exports in kb/raw/logs/ to text, skip fights already filed
│   ├── kb_timing.py           # KB: parse every log (one stamp rule, importable), generate kb/mechanics/clocks.md, clocks.json, scoreboard.md; a stated cost comes from kb/classes/abadmin.json (the game's record) before abilities.json; `--check` in CI, so re-run it after filing a log or an ABADMIN capture
│   ├── test_kb_timing.py      # its tests: `python -B tools/test_kb_timing.py` (in CI)
│   ├── kb_replay.py           # KB: replay every log through what the victim could see, test lock labels and route rules against the deaths, generate kb/mechanics/replay.md; `--check` in CI, `--gate` prints the bars
│   ├── test_kb_replay.py      # its tests: `python -B tools/test_kb_replay.py` (in CI)
│   ├── kb_sim.py              # KB: simulator, first stage. Run logged boards 20 s forward under a strong attacker, write kb/sim/forward.md + .json; `--check` in CI
│   ├── test_kb_sim.py         # its tests: `python -B tools/test_kb_sim.py` (in CI)
│   ├── sim/forward.lua        # the simulator engine: pure Lua 5.1, no Mudlet calls; rule tests in src_new/tests/test_sim_forward.lua. NEVER edit it: its bytes feed kb_sim.py's input hash
│   ├── kb_rules.py            # KB: the whole-fight engine's rules (clocks.json, afflictions.json, venoms.yaml, curing prios, kb/sim/rules_hand.json, tools/sim/gates_whole.json, and the Lua files 001_Miscellaneous_Aff_Tracking_Methods, 008_V3_Integration and 003_Lock_breakers) -> kb/sim/rules.json + rules.md, each rule tagged MEASURED/READ/WIKI/PLAYER/ASSUMED; `--check` in CI compares a hash of each input, so re-run it after an edit to any of them, a Lua file included
│   ├── kb_events.py           # KB: the four Serpent logs as one event stream (JSON Lines v1), the census, the DSTAB-vs-eat race table with its frozen golden row -> kb/sim/events.md + .json; `--check` and `--dump KEY`
│   ├── theorycraft.py         # CLI: a scripted Serpent vs a victim (--victim --gap --script [--median] [--seeds N] [--clock-draw normal]), a log in the engine's columns (--log Z5 --from ROW), a fork (--log Z5 --at ROW --then ...) that starts from the row's board, clocks, balance/equilibrium, kept defences and the ones on their way (a FLAY of the shield, a rebounding smoke, a coating apply; the logger's own shield drop is not a FLAY). A gap under the floor (a fork's default 1.83 too) and a row after the last prompt are refused. A second cost line ends the open one (an impulse's adds); slickness strips the sileris coating and, if still on at the 10 s mark, stops a pending one from hardening. Output is MODEL, not a log; an ALT line names each rule whose alternative ran, GAP says what the gap draw is, SEEDS says the P lines of a --median page are drawn. v4.7.479: `impulse SUGGESTION VENOM` action (it bites and spends balance too), `--gap raw|queue|queue-late|others` (our measured gaps and costs from the 2026-11-07 Serpent spar, or other Serpents'; the CLI never picks one), an OURS line, `--flay-missing coating|nothing`, `--ssc-gain saibel` (one opponent's open-channel delay, an alternative only); the SSC delay is two cases, `ssc.delay.gain` and `ssc.delay.return`
│   ├── sim/fight.lua          # the whole-fight engine (event loop, labels, race); sim/victim.lua (cure channels, class cures, defences); sim/attackers.lua (script parser, attack effects). Pure Lua 5.1; wired with forward.lua's RNG; tests in src_new/tests/test_sim_fight.lua
│   ├── sim/gates_whole.json   # FROZEN 2026-11-07: the bars of the whole-fight plan (stages 1-4). A change after a gate ran is a failed round and needs the user's word
│   ├── test_kb_rules.py, test_kb_events.py, test_theorycraft.py  # their tests (in CI); test_theorycraft pins the golden text of the user's example and the label parity with kb_replay.is_true
│   ├── test_check_orphans.py, test_convert_to_muddler.py  # tests of check_orphans (the NEVER_RUN rows, strict check 1c) and of the converter's case-blind filename collisions (in CI)
│   ├── find_dupes.py          # Find Lua files with the same name and group path in their YAML headers; `--delete` removes exact duplicates
│   ├── flatten_alias_hierarchy.py  # Migration script: flatten the nested alias folders in _groups.yaml and the .lua headers
│   └── legacy/                # Retired build tools
├── build.sh                   # Build script: ./build.sh [--dry-run] [--convert-only]
├── .gitignore                 # Excludes build artifacts, IDE state, caches
├── .gitattributes             # Enforces LF line endings, marks binaries
├── .editorconfig              # 2-space indent, UTF-8, LF for Lua/YAML/JSON/MD
├── .luacheckrc                # Lua 5.1 linter config with Mudlet globals
├── stylua.toml                # Lua formatter config (2-space, 120 col, Unix)
├── .claudeignore              # Excludes build output from Claude context
├── .mcp.json                  # Serena MCP server config
├── version.txt                # Package version (fetched by auto-updater)
├── CLAUDE.md                  # This file
├── GETTING_STARTED.md         # Setup and usage guide
├── README.md                  # Project overview
└── CHANGELOG.md               # Version history
```

**Note**: Build artifacts (`muddler_project/build/`, `muddler_project/src/`, `levi_test_project/`, `packages/`, `.vs/`) are gitignored and not tracked.

### Build System (Muddler)

The project uses [Muddler](https://github.com/demonnic/muddler) to build Mudlet packages.

**Quick build** (recommended):
```bash
./build.sh                 # Full convert + Muddler build
./build.sh --convert-only  # Convert only, skip Muddler
./build.sh --dry-run       # Preview without writing
```

**VS Code**: Press `Ctrl+Shift+B` to run the default build task. See `.vscode/tasks.json` for all tasks.

**Claude Code**: Use `/build` skill or invoke the `build-and-version` subagent.

**CI/CD**: GitHub Actions (`.github/workflows/build.yml`) runs the `validate` job on every push to `main`, every `v*` tag and every pull request to `main`. Its steps are the rows of `tools/ci_steps.json`; `python -B tools/ci_local.py --list` prints each one and what it proves. Tagged releases (`v*`) trigger a full build and upload to GitHub Releases.

**`tools/check_orphans.py` — a script switched off must take its callers with it (v4.7.261).**
`isActive: 'no'` on a script does NOT disable the triggers that call into it. They stay live, call
a nil global, and throw once per matching line — and where the pattern is `^.*$`, that is *every
line of game output*. **108 such call sites existed across four superseded scripts** (the old SLC,
the pre-V3 affliction core, a retired Shaman `ATTACK`), producing dozens of errors a second in the
user's client. Every gate in the pipeline was blind to it by construction: the syntax check passes
(the code is valid, the callee merely does not exist), the tests never load triggers, and the build
succeeds because a disabled script still ships. The only symptom was an error window nobody reads.

The fix has **two shapes, and choosing between them is the point** — a trigger that does *nothing
but* call dead code is disabled to match its script; a trigger that does live work and merely
contains one dead call has that **call guarded** (`if NAME then NAME(...) end`, the idiom those
files already use for their V3 calls), never disabled, or real logic goes with it. 27 of 62 were
the second kind.

**CHECK 2 -- a namespace FIELD called but never defined (v4.7.281).** `attempt to call field 'echo' (a nil value)`: **`ataxia.echo` exists nowhere in the tree** -- the helper is the global `ataxiaEcho`, built in a `_groups.yaml` inline script -- so **17 call sites across 4 files were dead**, including every echoing branch of `bash shinprobe` and **all nine echoes in `ataxiabars`**. The same sweep found `shaman.help()`, called unguarded by `sp help` and defined nowhere. Check 1 cannot see either: it reasons about GLOBALS defined by INACTIVE scripts, and these are table FIELDS defined by nothing (as was the v4.7.264 `zgui` family, an INDEX rather than a call). `check_missing_fields()` scans `.lua` AND `_groups.yaml` for `NS.field(...)` whose `NS.field` is assigned nowhere. Kept quiet enough to survive: **`mmp` is excluded** (a separate package, ~220 functions outside `src_new`, hundreds of false positives), **comments are stripped** (`-- Set ataxiaBasher.fleeTimeout (seconds)` otherwise reads as a call), and **the guard window is TWO LINES** rather than one, because the idiom here puts the test on its own line (`if ataxia and ataxia.decho then` / call / `end`) and per-line strictness flagged six safe sites. Findings report the REAL file line -- `split()` drops the header, and a finding you cannot jump to is one you will not act on. **A gate that cries wolf gets switched off, which is how a guard becomes decoration.** It only sees the namespaces listed in `NAMESPACES`, which is why 14 Shikudo triggers calling `monk.shikudo.limb_hit` (defined by no script we ship) threw unseen: since v4.7.414 `monk` is listed (and since v4.7.419 `shikudo` and `shikudoLock`), so every call into it must stay guarded, and `--[[ ]]` block comments are stripped as well (a header naming "monk.md (class mechanics)" read as a call).

**CHECKS 1b and 2b (v4.7.419).** 1b reads active SCRIPTS as callers too (check 1 read only triggers,
aliases, timers and keys); its first run found `queue_Scan` calling `shikudo_findCombo`, defined only by
the switched-off `shikudo/008`, on every queued monk combo. 2b reports a field called from active code
that only switched-off files assign: check 2 counts those as defined, so `vv` shipped calling
`shikudo.setMode`. Both were built report-only and made strict once clean (`STRICT_SCRIPT_CALLERS`,
`STRICT_INACTIVE_FIELDS`); land a new check the same way.

**CHECK 1c (2026-11-08).** Active code calling a global that NO file defines: checks 1 and 1b need an
inactive definer, so such a call passed everything. Its first run listed 41 names at 59 call sites.
Every call that could run is now guarded, or points at the function that replaced it (`viv` at
`apostate_vivisect`). What sits in a switched-off group folder cannot fire, so it is listed in
`NEVER_RUN`, by file and name, and `tools/test_check_orphans.py` pins each row to its folder flag.
The check was then made strict (`STRICT_UNDEFINED_GLOBALS`), so all five checks fail CI. A real Mudlet
function that shows up in its report goes in `MUDLET_API` (checked against Mudlet 5.1.1). It reads
calls to a NAME, not an index of a nil table: `ak.defs.shield` (trigger 130, line 38) and
`ak.prompt.scoreup()` (trigger 018, line 42) still throw, as do active aliases that read `svo.bals` or
`wsys`. Strings and comments are blanked first, and folded `_groups.yaml` scalars are joined, so an
inline group script is read. `tools/test_check_orphans.py` and `tools/test_convert_to_muddler.py` run in CI.

**`tools/check_colours.py` -- a colour name is only valid in OUR palette (v4.7.287).**
`007_Custom_Colour_Table.lua` WHOLESALE REPLACES Mudlet's, so a name that is perfectly good in stock
Mudlet is absent here and makes the render throw (v4.7.136: `silver`). The script asserts every
colour name a named file chooses exists in that table, and that none is in the **reserved orange
family**. **It scans two things and the second is the point:** the `<tag>` / `fg("name")` forms a
RENDERER writes, AND the `colour = "name"` fields plus `*_COLOUR` table values an AGGREGATOR
chooses. A colour name travels as a plain STRING whenever the module that picks it is separate from
the one that draws it (`mnemosyne/011` -> `012`), so scanning tags alone audits the renderer and
misses every name the picker chose -- exactly where `silver` would have got in. Run against named
files only, never tree-wide: ~50 existing orange sites are grandfathered. **It is NOT wired into CI**, unlike `check_orphans.py` -- usage strings put placeholder syntax inside real echo calls (`M.echo("Usage: mnem token <token>")`) and no regex separates a placeholder from a colour name, since the only difference is palette membership, which is the thing under test. A tree-wide gate would fail on correct files, and a gate that cries wolf gets switched off. Run it by hand against the files you add or change.

**Verify which interpreter before blaming the syntax.** Local `luac` may be 5.4, which rejects
unknown escapes like `[\[`; **Mudlet runs Lua 5.1, which silently maps them to the bare
character**, and CI's own `luac5.1 -p` passes over them. When a tool reports an error the runtime
does not, check the tool's version against the runtime's before acting on it.

**Manual pipeline**:
1. **Edit** source files in `src_new/` (YAML-header Lua format)
2. **Convert** to Muddler format: `python tools/convert_to_muddler.py --src ./src_new --output ./muddler_project`
3. **Build** with Muddler (from `muddler_project/` directory):
   ```bash
   set JAVA_HOME=C:\Program Files\Java\jre1.8.0_503
   cd muddler_project
   E:\muddle-shadow-1.1.0\muddle-shadow-1.1.0\bin\muddle.bat
   ```
4. **Output**: `muddler_project/build/Levi_Ataxia.mpackage` and `.xml`

**Requirements**: Java 8+, Muddler 1.1.0, Python 3. `build.sh` / `dmap_build.sh` resolve both
from candidate lists, so neither path is pinned: a valid pre-set `JAVA_HOME` / `MUDDLE_BAT` wins,
else Java is globbed from `E:/Java`, `C:/Program Files/Java`, `Eclipse Adoptium` and `Microsoft`
JDK dirs, and Muddler from `C:/Tools/muddle-shadow-1.1.0/...` then `E:/muddle-shadow-1.1.0/...`.
Current dev machine (2026-11-13): `C:\Tools` is gone. `build.sh` takes the JRE 8 at
`C:\Program Files\Java\jre1.8.0_503` (the `jre*` candidate; `Java/latest` holds only a `jre-1.8`
folder, so it does not match) and Muddler at `E:\muddle-shadow-1.1.0` (the second candidate). A full
build passed with them on 2026-11-13. To get Muddler again:
`gh release download 1.1.0 -R demonnic/muddler -p muddle-shadow-1.1.0.zip`.

**Testing**: Run `/c/Python314/python -B tools/ci_local.py` before every push: it runs each step of CI's `validate` job and prints PASS, FAIL or NOT RUN for each (`--quick` for the fast steps, `--list` for what each step proves). For the Lua suite alone, or one file: `/c/Python314/python tools/run_lua_tests.py [one_test_file.lua]`. Tests use `mock_mudlet.lua` to stub the Mudlet API.
**Local Lua on this Windows machine (2026-11-13).** No native Lua 5.1 is installed. `C:\Tools\lua51`
is gone (since at least 2026-11-04), and the `luac.exe` on PATH (`AppData\Local\Programs\Lua\bin`) is
Lua 5.4. Mudlet runs 5.1, and a 5.4 `luac` rejects escapes that 5.1 accepts. The lint hook script
would fall back to that `luac` (`.claude/hooks/lint-before-commit.sh`:15-20; it does not run today), and the VS Code "Run Tests"
task falls back from `lua5.1` to the 5.4 `lua` (`.vscode/tasks.json`:42), which gives false failures
(`global 'unpack'`). `lupa` embeds Lua 5.1, so `tools/ci_local.py` runs the syntax step and the suite through it,
with the interpreter that started it. A step that cannot run (no `lupa`, no `yaml`, nothing to check) is NOT RUN
and the run exits 2: it is never a pass (2026-11-13; before that `kb_sim.py --check` printed "skip" and exited 0
under the `python3` on PATH). The step list is `tools/ci_steps.json`, and `tools/test_ci_local.py` fails when it
and the `validate` job of `build.yml` disagree. A generated KB page fails CI when one of its inputs changes, and a Lua file can be an
input (`kb_rules.py` stopped PR #169 that way), so run the full list, not only the suite.
**Never use a bare `os.tmpname()` in a test**: under `lua5.1.exe`'s old C runtime it returns a name
in the drive root (`\s1hk.`), which is not writable (`test_kb_capture.lua` failed 13 tests this
way while Linux and lupa passed); move such a name into `%TEMP%`, as that test does.

### VS Code (Primary IDE)

Open the `LEVI-Achaea/` folder in VS Code. Recommended extensions are in `.vscode/extensions.json` (sumneko Lua + Mudlet Scripts SDK).

**Build tasks** (`.vscode/tasks.json` — press `Ctrl+Shift+B`):
- **Build Levi_Ataxia** (default) — Full convert + Muddler pipeline
- **Convert Only** — Just the conversion step, no Muddler
- **Convert Dry Run** — Preview without writing
- **Clean Build Output** — Remove `muddler_project/build/`
- **Run Tests** (default test task) — Execute unit tests
- **Build Levi_Test** — Build the test/distribution package

**Hooks.** Eight hook scripts live in `.claude/hooks/` and are registered in `.claude/settings.local.json`. **None of them runs today.** Claude Code reads settings only from the folder a session starts in, and sessions start in the parent folder. Three of them (`block-git-bypass.sh`, `lint-before-commit.sh`, `protect-config.sh`) also read `$TOOL_INPUT`, while hook input arrives on stdin, so they could not block. The facts and their sources are in `docs/reference/harness-facts.md`. Do not rely on a hook. The gates that work are `tools/ci_local.py` before a push and CI after it.

**Claude Code skills** (listed in a session only after the first file access below this repository; a name that collides with a built-in appears as `LEVI-Achaea:verify`):

| Command | Purpose |
|---------|---------|
| `/build` | Run the full build pipeline |
| `/version-bump <version>` | Sync version across all 3 tracked locations |
| `/verify [quick\|full]` | Run CI's `validate` job locally (`tools/ci_local.py`): PASS / FAIL / NOT RUN for each step; no package build (`/build` does that) |
| `/build-fix` | Fix build/lint errors one at a time, minimal diffs |
| `/deep-review [system]` | Launch 4 parallel agents: Lua quality, combat correctness, triggers, completeness |
| `/codex-verify [system]` | Dispatch independent Codex verification in background |
| `/review-codex` | Auto-detect changes, write Codex prompt, dispatch, verify results |
| `/deslop [path]` | Regression-safe Lua bloat cleanup: deletion-first, tests-first |
| `/scope-check [change]` | Assess whether a proposed change fits current work context |
| `/commit-split` | Group changed files by concern and commit each group atomically |
| `/issue [bug\|feature\|crash] [desc]` | Create GitHub issue with structured sections |
| `/new-adr [name]` | Scaffold a new Architecture Decision Record |
| `/kb-ingest` | File new Achaea text from the inbox file into `kb/`, cross-check it against the code, report conflicts |
| `/tooling-review` | Review last 2 weeks of Claude Code + VS Code updates for improvements |

Use `/reload-plugins` to pick up new or modified skills without restarting Claude Code.

**Custom subagents** (`.claude/agents/`; not offered in a session that starts in the parent folder, see *Model & Effort Selection*):
- `offense-system` — Enforces project patterns when creating class offense systems
- `build-and-version` — Handles version bumps and builds with validation
- `team-class-offense` — Team agent for parallel class development
- `fast-reader` — Tier 1 (Haiku/low): search, read, summarize, run tests/builds, fully specified small edits
- `implementer` — Tier 2 (Sonnet/medium): everyday coding from a clear plan, tests, docs, small reviews
- `architect` — Tier 3 (Opus/high, read-only): design, cross-cutting changes, hard debugging, plan/diff review (see *Model & Effort Selection*)

### Visual Studio 2022 (Legacy)

Build tasks are in `.vs/tasks.vs.json` — right-click the root folder in Solution Explorer to run them.

### Source Code Organization

Files are organized in `src_new/` by Mudlet item type (aliases, keys, scripts, timers, triggers). Each `.lua` file has a YAML metadata header and uses numbered prefixes (001_, 002_, etc.) for ordering:
- **scripts/levi_ataxia/levi/ataxia/** - Combat system (afflictions, defense, basher, curing)
- **scripts/levi_ataxia/levi/levi_scripts/** - Class-specific offenses (shikudo, dwc, blademaster, etc.)
- **triggers/levi_ataxia/** - Game text pattern matching
- **aliases/levi_ataxia/** - User command shortcuts
- **timers/levi_ataxia/** - Delayed action definitions
- **keys/levi_ataxia/** - Key bindings

### Combat Systems Index

All combat systems in `src_new/scripts/levi_ataxia/levi/levi_scripts/`:

| System | Files | Status | Kill Route | Location |
|--------|-------|--------|------------|----------|
| **apostate** | 1 (015) | **Documented** | Lock, corrupt, vivisect, sleep, mental | `apostate/` |
| **bard** | 10 | **Documented** | Voyria lock; Composition/Bladedance affliction; PvE footwork bashing | `bard/` |
| **blademaster** | ~10 | **Documented** | Lightning/Ice, Brokenstar | `blademaster/` |
| **depthswalker** | 1 | **Documented** | Shadow/time; PvE = owned battlerage (all 6 abilities denizen-legal) + Terminus word-balance keepers; PvP capstones are PER INSTILL (`capstoneReady(instill)`, v4.7.365 -- never a global DW-aff count), `impatience` is not an instill, there is NO `shadow claim` command (the leach capstone strike claims), and Dictate counts only depression/madness/retribution/parasite (v4.7.366); impatience comes from HYPOCHONDRIA's delayed symptom, which LOCK guards, and Dictate maintains its four amplifiers (v4.7.372) | `depthswalker/` |

**DEPTHSWALKER AEONIC CASH-IN (v4.7.265, NOT boon-gated).** `CHRONO DETERIORATE <t>` (AB 2425,
**300 age**) deals significant magical damage to a MIND-ADDLED denizen -- recklessness, charm,
fear, aeon, amnesia -- and `CHRONO DEGENERATE <t>` (AB 2423, **700 age**) to a PHYSICALLY-PLAGUED
one -- inhibit, weakness, sensitivity, clumsiness. Herald of Infirmity only adds 25% on top, so the
coordination is worth doing without it. **All nine were already modelled** by
`basher/008_Denizen_State.lua` (`ataxiaBasher_BR_AFFS`), and the loop FEEDS ITSELF: DW battlerage
applies two of the five mental triggers (`chrono curse` -> aeon, `intone boinad` -> charm), so the
rotation plants and `ataxiaBasher_dwAeonicCashIn` collects a round later -- the Blademaster
Headstrike shape. **Never boosted** (both ABs say denizens cannot be). **REPLACES the swing**: the
balance type is unstated in both ABs, and if they are balance abilities an appended swing would be
REJECTED after the age was already spent, whereas if they are equilibrium we merely lose one
`shadow reap` -- the recoverable error. Deteriorate is preferred (300 vs 700 age); **amnesia sorts
LAST** because `chrono erasure` consumes weakness/amnesia and the two cash-ins would otherwise
fight over the same affliction. Age-capped on `dwAgeCap` like chrono blur and
PvE-only (`type(target) == "number"`). **The v4.7.265 cut ANNOUNCED without CASTING** (fixed
v4.7.267): it used a 4s in-flight HOLD, and since `queue addclearfull` wipes the whole server queue
every round, the command was deleted by the next rebuild while the hold stopped it being re-added --
so it is a REPLAY (`ataxiaTemp.dwAeonicPending`, re-emitted verbatim until a fire line releases it),
the shape the owned battlerage rotations already use. Its test was pinning the bug by asserting the
echo. Disabling it is the config field `ataxiaBasher.dwAeonic = false`; **there is no alias** --
v4.7.265 documented `bash dwaeonic off`, which was never a real command.
| **dwb** | 1 | Undocumented | Breakpoint/rift | `dwb/` |
| **dwb_runie** | 1 | Undocumented | DWB + runelore | `dwb_runie/` |
| **dwc** | 3 | **Documented** | Vivisect, damage kill | `dwc/` |
| **dwc_runie** | 1 | Undocumented | DWC + runelore | `dwc_runie/` |
| **earth_lord** | 5 | Undocumented | Limb targeting | `earth_lord/` |
| **i_snb** | 1 | Undocumented | Infernal SnB | `i_snb/` |
| **mage** | 5 | **Documented** | Elementalism: a priority tree every mode runs first (destroy, meteorite shield strip, glaciate on a frozen target once hypothermia is laid, stormhammer, mudslide at asthma + water 2), then fire burns and freeze (xx; vv's water mode has no branch and runs the same tree), salve (zz), lock (cc), group (sr). Tabethys's rotation (opener, mudslide bonk, joint focus lock, emanate water + freeze until frozen + glaciate) is `ww` (mode `waterroute`, v4.7.421, `selectWaterRouteSpell`, branched after P1/P2 and before P3-P8; `mm glaciate N|off`). v4.7.429-430 (Tabethys's log of a kill): game lines own the burn count -- the fan line adds (a weary dehydrate is one burn; other sources are `kb/CONFLICTS.md` #37), the fires-diminish line removes; stormhammer puts our target in slot 1 when gmcp lists it, or alone when nobody else qualifies; `pickSpell` is `selectSpell`'s side-effect-free half, and `mm echo` shows `You: <Spell> -> X`, `<Plane>: <Stage> -> X` and a prompt stage word named from that pick | `mage/` |
| **pariah** | 1 | Undocumented | Plague/swarm | `pariah/` |
| **psion** | 1 | **Documented** | Mana kill, deconstruct, flurry burst | `psion/` |
| **s_n_b** | 1 | Undocumented | Sword and Board | `s_n_b/` |
| **serpent** | 1 (002) | **Documented** | Ekanelia lock, darkshade, scytherus | `serpent/` |
| **shaman** | 1 (028) | **Documented** | Tzantza, locks, bleed | `shaman/` |
| **snipe** | 1 | **Documented** | Class-agnostic snipe system | `snipe/` |
| **shikudo** | 006, 007, 010, 011 live | **Documented** | Dispatch (006: zz/xx/sk), lock (007: sr; Mystor's route, KAI CHOKE kill), strike ledger (010), vv dispatch + Telepathy (011); 009 GodMode switched off (v4.7.419; why and what to salvage are in its header; to be deleted with 001/002/004/005/008); offense rework in progress (wave 1: v4.7.419, wave 2: v4.7.420) | `shikudo/` |
| **tekura** | ~3 | **Documented** | 6-limb backbreaker (TK6), 3-limb legacy (TKD) | `tekura/` |
| **two_handed** | 1 | Undocumented | 2H knight | `two_handed/` |
| **wildwalker** | 8 | Undocumented | Navigation/utility | `wildwalker/` |

**Project Folders** for undocumented systems: `.claude/projects/<system>/README.md`

---
