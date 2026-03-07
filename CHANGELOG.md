# LEVI-Achaea Changelog

---

## 2026-03-07 — Fix: Nil-guard 7 startup/runtime Lua errors

**Files modified**:
- `src_new/scripts/.../016_Targeting_Functions.lua` — `isTargeted()`: added nil guard for `target` global
- `src_new/scripts/.../deffing/003_Defence_Reporting.lua` — `ataxia_reportDefences()`: early return when `ataxia.settings.defences` uninitialized
- `src_new/scripts/.../basher/001_Bashing_Functions.lua` — guarded two `ataxiaBasher.fleeThreshold` comparisons against nil
- `src_new/scripts/.../039_EDIT_ME__Startup_Main.lua` — guarded zgui module function call in startup loop
- `src_new/scripts/.../login/001_Login_Function.lua` — guarded `slc_reset`/`slc_force_display` calls (functions may not exist)
- `src_new/scripts/.../ataxia_ndb/004_ataxiaNDB_Highlighting.lua` — fallback to Rogues colour when city not in highlighting table
- `src_new/triggers/.../chasing/002_PEOPLE_CAPTURE.lua` — quoted bare `north` identifier to string `"north"`

**Problem**: Seven different nil-value errors fired on login and during gameplay — `attempt to index global 'target'`, `attempt to index field '?'`, `attempt to compare number with nil`, `attempt to call field '?'`, `attempt to call global 'slc_force_display'`, `bad argument #1 to 'format'`, and `attempt to concatenate global 'movedirection'`.

**Fix**: Added defensive nil guards to all 7 locations. Each fix is a minimal early-return or fallback — no architectural changes.

Also removed unused Targeting keybind group (6 keys: Left Leg, Right Leg, Torso, Head, left_arm, Right_Arm) from `src_new/keys/` and `_groups.yaml`.

---

## 2026-03-06 — Fix: Alias `regex:` fields not parsed by converter

**Files modified**:
- `tools/convert_to_muddler.py` — `fallback_yaml_parse()`

**Problem**: Aliases with unquoted `regex:` values containing YAML special characters (e.g., `^snt(?: (.+))?$`) failed primary YAML parsing. The fallback parser only fixed `pattern:` lines but not `regex:` lines, causing the file to be silently skipped with a "No YAML header" warning. The Snipe alias (`003_Snipe.lua`) was missing from the built package because of this.

**Fix**: Extended fallback parser regex from `pattern:` to `(?:pattern|regex):` so both trigger patterns and alias regexes are auto-quoted when they contain special YAML characters.

---

## 2026-03-06 — Feature: Snipe system uses SHOOT for knight classes

**Files modified**:
- `src_new/scripts/.../snipe/001_Snipe_System.lua`

**Change**: Runewarden and Infernal classes use `shoot` (Weaponmastery) instead of `snipe` (Subterfuge). Added `snipe.getCommand()` helper that checks `gmcp.Char.Status.class` and returns the correct command. The `snt` alias, success trigger, and failure trigger are unchanged — only the sent command differs.

---

## 2026-03-06 — Fix: Focus trigger now clears impatience from tracking

**Files modified**:
- `src_new/triggers/.../399_Focus_(known).lua` — else branch (non-lovers cure)
- `src_new/triggers/.../398_Focus_(UNK).lua` — all focus uses

**Problem**: When target used Focus and cured a goldenseal aff other than impatience, our tracking didn't infer that impatience was absent. If focus cured something else, impatience can't be present (focus would prioritize it).

**Fix**: Added `erAff("impatience")` + V2/V3 removal on focus use. In 399 (known variant), only in the non-lovers branch (the lovers branch already cleared impatience explicitly). In 398 (UNK variant), on all focus uses (impatience is gone either way — cured by focus or wasn't present).

---

## 2026-03-06 — Fix: Shrugging trigger gated to Serpent only

**Files modified**:
- `src_new/triggers/.../passive_active/015_Shrugging_(Serpent).lua`

**Problem**: The "hunches shoulders" trigger (Shrugging) only fired for Serpent targets (class gate: `class == "Serpent"`). Other classes also use this ability.

**Fix**: Removed the Serpent class gate. Now clears `weariness` + 1 random affliction from V1/V2/V3 tracking for any targeted player.

---

## 2026-03-06 — Tweak: Lower asthma threshold from 50% to 33% for manaleech+disfigure transition

**Files modified**:
- `src_new/scripts/.../apostate/015_CC_Apostate.lua` — `selectPrimaryCurse()` (line ~263), `selectSecondaryCurse()` (lines ~326, ~333)

**Change**: Lowered the asthma probability threshold from `>= 0.50` to `>= 0.33` in three places. Once clumsy and weariness are both at 33%, asthma is delivered. As soon as asthma reaches 33%, the system transitions to manaleech+disfigure immediately rather than waiting for 50% certainty. This applies earlier pressure and pairs with the existing disfigure-on-manaleech-round logic.

---

## 2026-03-06 — Fix: Disfigure firing prematurely due to off-balance button spam

**Files modified**:
- `src_new/scripts/.../apostate/015_CC_Apostate.lua` — disfigure gate (line ~605)

**Problem**: Spamming the attack button while off-balance caused `selectPrimaryCurse()` to pick manaleech (asthma already tracked as applied from the previous round's trigger). The `buildAttack()` function then appended `disfigure` to the queued command. When balance returned, the queued deadeyes+disfigure fired — but disfigure was computed based on stale state (manaleech hadn't actually been cursed yet).

**Fix**: Added `gmcp.Char.Vitals.bal == "1"` gate to the disfigure condition. Disfigure only appends when actually on balance, ensuring it fires on the real manaleech round, not a pre-queued off-balance press.

---

## 2026-03-06 — Fix: Legacy apostate files still active, causing unwanted disfigure

### Bugfix: Disfigure firing on clumsy+asthma round instead of manaleech round

**Files modified**:
- `src_new/scripts/.../apostate/001_CLUMSY_PRIOS.lua` through `013_LOCK_ATTACK.lua` — all 13 legacy files set to `isActive: 'no'`

**Problem**: All 13 legacy apostate scripts (001-013) were still `isActive: 'yes'` despite being replaced by `015_CC_Apostate.lua`. The legacy `013_LOCK_ATTACK.lua:114` had its own disfigure logic (`want_disloyalty and tAffs.asthma`) that fired as soon as the asthma curse landed (V1 boolean set immediately by trigger), not when asthma was confirmed stuck. This caused disfigure to fire on the first clumsy+asthma round instead of waiting for the manaleech round.

**Fix**: Deactivated all 13 legacy files. The unified `015_CC_Apostate.lua` already has correct disfigure logic gated behind `c1 == "manaleech" or c2 == "manaleech"` (line 605).

---

## 2026-03-06 — Fix: 4 recurring nil-access runtime errors

### Bugfix: Limb Counter Window, Tekura 6-Limb, Capture Msg, Start Shikudo all spamming errors

**Files modified**:
- `src_new/scripts/.../windows/001_Limb_Counter_Window.lua` — nil guard on `lb[target].hits`, removed duplicate YAML header
- `src_new/scripts/.../tekura/002_Tekura_6Limb_Offense.lua` — nil guard on `amount` in `onLimbHitUpdated`
- `src_new/triggers/.../ataxia_chat_capture/002_Capture_Msg.lua` — nil guard on `ataxiaBasher.targetList`
- `src_new/triggers/.../169_Start_Shikudo.lua` — nil guard on `monk` global

**Problems**:
1. **Limb Counter Window:184** — `lb[target].hits[ln]` crashed when `lb[target]` was nil (no limb data initialized for current target). Fired every prompt tick.
2. **Tekura 6-Limb Offense:74** — `amount > 16` crashed when `limb_init.lua` raised `"limb hits updated"` with only 3 args (no amount). Fired on every limb reset.
3. **Capture Msg:6** — `ataxiaBasher.targetList[area]` crashed when `ataxiaBasher.targetList` was nil (basher not initialized). Fired on every say/tell.
4. **Start Shikudo:1** — `monk.shikudo.start()` crashed because `monk` global doesn't exist. Trigger marked `isActive: 'no'` in source but was active in installed profile.

**Fixes**: Added nil guards at each crash site. Also removed duplicate YAML header block in Limb Counter Window and added `or 0` fallback for missing hit values.

---

## 2026-03-06 — Fix: Baalzadeen re-summoned every dispatch

### Bugfix: Apostate offense wastes balance summoning Baalzadeen when already present

**Files modified**:
- `src_new/scripts/.../apostate/014_Levi_Apostate.lua` — `baalzadeen()` function
- `src_new/scripts/.../apostate/015_CC_Apostate.lua` — dispatch Baalzadeen check
- `src_new/triggers/.../apostate/025_BAALZADEEN_SUMMONED.lua` — **New** trigger
- `src_new/triggers/.../apostate/014_NO_BAALZADEEN.lua` — reset flag on failure

**Problem**: Every `apostate.dispatch()` call sent `queue prepend free summon baalzadeen` before the attack, even when the Baalzadeen was already in the room. This consumed balance on a redundant summon every round. Two issues:
1. `baalzadeen()` used `table.contains(zgui.roomDenizenList, "a Baalzadeen")` — exact string match failed if the GMCP name differed in casing/article, or if the entity had a non-`"m"` attrib (landing in `roomItemList` instead)
2. No guard against re-sending the summon while waiting for GMCP to confirm the Baalzadeen appeared

**Fix**:
1. All daemon utility functions (`baalzadeen()`, `bloodworm()`, `demon()`, `daemonite()`, `fiend()`) switched from `zgui.roomDenizenList` to `ataxia.denizensHere` with case-insensitive partial matching. `zgui.roomDenizenList` was not populated; `ataxia.denizensHere` is the reliable GMCP-backed table used by the basher
2. Fixed `daemonite()` and `fiend()` — they iterated `zgui.roomItemList` (wrong list) and called `item.name:match()` on plain string values (would crash)
3. Added `apostate.state.baalzadeenSummoned` flag — set `true` when summon is sent, prevents re-sending every dispatch
4. New trigger `025_BAALZADEEN_SUMMONED.lua` matches "You call out, ordering your Baalzadeen to return to serve your whim." and resets `baalzadeenSummoned = false`
5. `014_NO_BAALZADEEN.lua` also resets the flag so dispatch can retry after a failure

---

## 2026-03-06 — Fix: Root group init script lost during hierarchy flattening

### Bugfix: `ataxiaTemp` / `ataxiagui` / `ataxiaTables` nil on load

**File modified**: `tools/convert_to_muddler.py`

**Problem**: The hierarchy flattening (root group unwrap) promoted children to the top level but dropped the root group's own inline `script:` property. The `Levi_Ataxia` root group in `scripts/_groups.yaml` contained the init script that creates `ataxiaTemp`, `ataxia`, `ataxiaTables`, `ataxiagui`, `ataxiaVersion`, `muteList`, `ataxia.bals`, and the `ataxia_Echo()`/`ataxiaEcho()` functions. Without this script, every prompt trigger, vitals handler, basher function, and limb display crashed with `attempt to index global 'ataxiaTemp' (a nil value)`.

**Symptoms**:
- `[ERROR] Prompt Running: attempt to index global 'ataxiaTemp' (a nil value)`
- `[ERROR] Limb Counter Window: attempt to index global 'ataxiaNDB' (a nil value)`
- `[ERROR] ataxia_Vitals_Update: attempt to index global 'ataxiaTemp' (a nil value)`
- `[ERROR] Bashing Functions: attempt to index global 'ataxiaTemp' (a nil value)`
- Basher sending invalid commands (`lipread`, `scales`, `conjure`) — class not detected due to missing init

**Fix**: When unwrapping a root group, if it has an inline `script:`, inject a synthetic `"Levi_Ataxia Init"` script node at position 0 of the children array. This ensures the init code loads before any child scripts. Only the `scripts` type was affected — triggers, aliases, timers, and keys had no root group inline scripts.

**Root cause**: The flatten plan (2026-03-06) added root group unwrapping to prevent triple-nested `Levi_Ataxia` in Mudlet. The unwrap code at line 440 extracted `children` from the JSON node but did not check for the node's own `script` property.

---

## 2026-03-06 — Documentation Refresh

### Improvement: Comprehensive markdown documentation update

**Files modified**:
- `.claude/AGENTS.md` — Added Combat Systems Quick Reference table (10 offense systems + 2 utility systems), Serpent Offense section, Shaman Offense section, Snipe System section, Setup Wizard section. Updated affliction tracking reference with `erAff()` V1-only warning, added `apostate.hasAff()` and `dwbRunie.hasAff()` to class routing. Expanded Key Files Reference table. Updated basher section with additional files and single-gate architecture notes.
- `docs/ai-includes/agent-teams.md` — Updated Isolated Directories table with correct namespaces (`shamanOffense`, `apostate`, `serp_*`, `dwbRunie`, `snipe`, `infernalDWC2L`). Added setup wizard and shaman spirit system to Shared/Contended Files. Updated trigger ownership to mention class-specific subdirectories.
- `CLAUDE.md` — Updated Combat Systems Index: serpent (Documented, 1 file), shaman (Documented, 1 file), snipe (Documented). Added Setup Wizard section with full command table. Updated class modules list in Ataxia Combat System overview.

**Files verified (no changes needed)**:
- `.claude/classes/README.md` — Already accurate (26 classes, lock table, combat concepts)
- `.claude/databases/README.md` — Already accurate (4 YAML databases)
- `.claude/templates/README.md` — Already accurate (3 templates)

---

## 2026-03-06 — Setup Wizard & Separator Fix

### Feature: In-game setup wizard (`levi setup`)

**Files added**:
- `src_new/scripts/.../misc_scripts/020_Setup_Wizard.lua` — `leviSetup` namespace with guided configuration for all system settings
- `src_new/aliases/.../toggles_settings_etc/021_Setup_Wizard.lua` — `^levi setup ?(.*)$` alias to dispatch the wizard

**What it does**: Provides a single `levi setup` command that walks players through configuring:
- Class detection and weapon setup
- Server-side separator
- Basher settings (gold pack, flee thresholds, target lists)
- Health/mana sipping thresholds
- Affliction tracking mode (V1/V2/V3)
- Combat toggles (party relay, auto-gallop, raid mode, etc.)
- GUI creation and NDB configuration
- Full status overview (`levi setup status`)

Each category: `levi setup class`, `levi setup separator`, `levi setup weapons`, `levi setup basher`, `levi setup sipping`, `levi setup tracking`, `levi setup combat`, `levi setup gui`, `levi setup ndb`, `levi setup install`, `levi setup status`.

### Feature: Installation walkthrough (`levi setup install`)

Added `levi setup install` command that walks players through the three one-time install commands:
- `atinstall` — Core Ataxia system (server-side curing config, prompt, defaults)
- `abinstall` — Basher system (target lists, flee, shield timers)
- `aninstall` — Name Database (player tracking, city highlighting)

Subcommands: `levi setup install all` (runs basher + NDB directly, guides atinstall), `levi setup install ataxia`, `levi setup install basher`, `levi setup install ndb`.

### Feature: Post-install configuration guide (`levi setup guide`)

Added `levi setup guide` with per-subsystem walkthroughs showing every configurable option:
- `levi setup guide ataxia` — Separator, system toggle, custom prompt, defence profiles (defup/defadd/defremove), curing priorities, item highlighting, sipping, room shortening, GUI, raid mode, auto-gallop, gag clotting
- `levi setup guide basher` — Enable/disable, target lists (bash room/add/remove/list), flee thresholds, danger mobs, ignore lists, gold pack, shield swap/timer, rageraze, tree blackout, Dragon-specific options
- `levi setup guide ndb` — City highlight colours, highlight toggle/priority, enemy formatting (bold/italic/underline), player notes, whois/honours lookup, settings display

Each entry shows both the direct in-game command (e.g. `aconfig separator`) and the wizard equivalent (e.g. `levi setup separator`), so users know where to go for quick changes.

### Bugfix: Separator no longer hardcoded on every login

**File modified**: `src_new/scripts/.../002_Check_For_Any_Missing_Variables.lua`

**Problem**: `ataxiaCheckForMissing()` unconditionally set `ataxia.settings.separator = ";"` on every login, overwriting any user-configured separator.

**Fix**: Only set the default when the separator is nil or empty, preserving saved user preference.

---

## 2026-03-06 — Flatten Redundant Levi_Ataxia Nesting

### Improvement: Remove triple-nested Levi_Ataxia wrapper groups

**Files modified**:
- `src_new/scripts/_groups.yaml` — Dissolved `LEVI > Ataxia > Ataxia` and `Levi Scripts` wrappers; moved inner Ataxia init script to root
- `src_new/triggers/_groups.yaml` — Dissolved `For Levi > leviticus` wrappers
- `src_new/timers/_groups.yaml` — Dissolved `For Levi > Levi_062424 > leviticus > Levi Ataxia` chain
- `src_new/keys/_groups.yaml` — Dissolved `Levitax` wrapper
- `tools/convert_to_muddler.py` — Added per-type hierarchy rewriting to strip dissolved group names from file YAML headers; unwrap root group in JSON output so children appear directly in the array
- `tools/flatten_groups.py` — New helper script for flattening `_groups.yaml` intermediate groups

**Problem**: The Mudlet package tree showed 3 levels of `Levi_Ataxia` before reaching actual content groups, caused by three layers combining: (1) Mudlet package import creates a root group, (2) Muddler directory adds another wrapper, (3) JSON root group object adds a third. Each item type also had its own redundant intermediate groups (e.g., scripts had `LEVI > Ataxia > Ataxia`, triggers had `For Levi > leviticus`).

**Fix**: Two-part approach:
1. Flattened `_groups.yaml` files to remove intermediate wrapper groups, promoting their children directly under `Levi_Ataxia`
2. Modified `convert_to_muddler.py` to (a) rewrite stale hierarchy references in file YAML headers to match the new flat structure, and (b) unwrap the root group in JSON output so Muddler doesn't add another layer

Result: Single `Levi_Ataxia` level (the package root), then directly into content groups.

---

## 2026-03-06 — Flatten Alias Hierarchy

### Improvement: Reduce deeply nested alias group structure

**Files modified**:
- `src_new/aliases/_groups.yaml` — Rewritten with flat hierarchy (max 5 levels vs previous 10+)
- 520 alias `.lua` files — All `hierarchy:` YAML headers updated to new paths
- `tools/flatten_alias_hierarchy.py` — New tool for bulk hierarchy path remapping

**Problem**: Alias groups were nested 7-10 levels deep (e.g., `Levi_Ataxia > For Levi > Levi_062424 > Levi > LeviticusREG > Leviticus > BladeMaster`) due to accumulated organizational layers over years. This made navigating the alias tree in Mudlet tedious.

**Fix**: Consolidated all aliases into a clean top-level structure under `Levi_Ataxia`:
- `Classes/` — All 13 class-specific alias groups (Apostate, Blademaster, Knight, Monk, etc.)
- `General/` — Movement, Targeting, Shopkeeping, Freezetag, Egghunt
- `Artefacts/` — LegendDeck, Dragon Talisman, Rageblade
- `Combat/` — Combat Aliases, Defence, Enemy Management, Limb
- `Ataxia/` — NDB, Basher, Config, Crafting, Defence Config, Fishing, Shaman System
- `Systems/` — Gear System, zData, zGUI Redux
- `Utility/` — Echo, delete old profiles, run-lua-code
- `RAGEPULL` (disabled)

All group-level scripts (LegendDeck notes, Infernal forge notes, Dragon Talisman combine, Inkmilling help, Custom Prompt documentation) and `isActive: false` flags preserved.

---

## 2026-03-06 — NDB API Error Handling (Blacklist Non-Players)

### Bug Fix: Non-player names (items, NPCs) cause infinite API lookup spam

**Files modified**:
- `src_new/scripts/.../ataxia_ndb/007_ataxiaNDB_Failed.lua` — Handle "Forbidden" API responses; added `ataxiaNDB_blacklistName()` and `ataxiaNDB_isBlacklisted()` functions
- `src_new/scripts/.../ataxia_ndb/002_Get_Information.lua` — `ataxiaNDB_Acquire()` and `ataxiaNDB_NameList()` skip blacklisted names
- `src_new/scripts/.../ataxia_ndb/003_ataxiaNDB_API.lua` — `ataxiaNDB_SortOnline()` filters blacklisted names from API queue
- `src_new/scripts/.../ataxia_ndb/001_Ataxia_NDB_Settings.lua` — Added `notPlayers` table to default settings
- `src_new/triggers/.../747_Get_Person.lua` — Explorers Rankings skips blacklisted names

**Problem**: Item names like "earrings" were being detected as player names (e.g., from GMCP player lists or explorers rankings). The API returned 403 Forbidden, but the error handler only recognized "Not Found" — Forbidden fell through to a generic echo with no corrective action. On every subsequent WHO/explorers query, the same name was re-discovered and re-queued, producing repeated "Error downloading" + "1 new names identified" spam.

**Fix**: Added a `notPlayers` blacklist persisted in `ataxiaNDB`. When the API returns Forbidden (or Not Found), the name is added to `ataxiaNDB.notPlayers`. All lookup entry points (`ataxiaNDB_Acquire`, `ataxiaNDB_NameList`, `ataxiaNDB_SortOnline`, explorers trigger) now check `ataxiaNDB_isBlacklisted()` before making API calls. First failure adds to blacklist; subsequent queries skip silently.

---

## 2026-03-06 — Converter mStayOpen Fix (Defence List Spam + 50+ Triggers)

### Bug Fix: mStayOpen triggers with children broken by converter

**File modified**: `tools/convert_to_muddler.py` — `_group_to_json()` method

**Problem**: Triggers with `mStayOpen > 0` that also have child triggers (referenced via `hierarchy`) were being split into two XML nodes: a folder (holding children) and a separate leaf trigger (with the pattern/fireLength). Children ended up under the folder (which has no stay-open window), not under the trigger. This broke Mudlet's `mStayOpen` mechanism, which requires children to be nested directly under the trigger.

**Visible symptom**: `"(LEVI): Defences currently active:"` echoed on every prompt line (~25 lines of spam), because the `Defence List` trigger's child `get Defence` was under an inert folder instead of the 99-line stay-open trigger.

**Fix**: When a leaf trigger has `mStayOpen > 0` AND shares its name with an auto-created child group, the converter now merges the trigger's properties (patterns, fireLength, script, multiline settings, filter, highlight, etc.) INTO the group node, sets `isFolder: "no"`, and skips the duplicate leaf. This produces a single XML node that is both a trigger and a parent — exactly what Mudlet expects.

**Scope**: Generic fix handles all 50+ mStayOpen triggers across the codebase that are also hierarchy parents, not just Defence List.

---

## 2026-03-06 — Blademaster Bash Display Fix (Shin, Stance, DPS)

### Bug Fix: Shin, stance, and DPS not showing in bash info window

**Files modified**:
- `src_new/scripts/.../windows/001_Limb_Counter_Window.lua` — Fixed Shin display + added Stance for Blademaster
- `src_new/scripts/.../basher/003_Bash_Stats_Functions.lua` — Implemented missing `bashStats_getDPS()` function

**Problems**:
1. **Shin**: Window used `bmshin` global from disabled `001_Logic.lua` (`isActive: 'no'`). Variable was always nil, guard skipped display. Fix: call `blademaster.getShin()` directly (defined in active `005_CC_BM_Ice.lua`), with fallback to `ataxia.vitals.class`.
2. **Stance**: No Blademaster stance section existed in the window (only Monk had one). Fix: added `ataxia.vitals.stance` display under the Shin line for Blademaster.
3. **DPS**: Window checked `if bashStats and bashStats_getDPS` but `bashStats_getDPS()` was never implemented — only `resetBashingStats()` existed. The damage tracking infrastructure was already working (trigger 350 accumulates `totalDamage`, balance timers record `lastBalanceDamage`/`lastBalanceTime`), but no function computed DPS from it. Fix: implemented `bashStats_getDPS()` returning session DPS and per-balance DPS.

---

## 2026-03-06 — Prompt Newline Fix

### Enhancement: Force prompt onto its own line

**File modified**: `src_new/triggers/levi_ataxia/for_levi/leviticus/318_Prompt_Trigger.lua`

**Problem**: Achaea sends the prompt on the same line as the preceding game text (no newline before the GA telnet signal). This makes the prompt visually merge with combat/room output.

**Fix**: Added `echo("\n")` at the start of the prompt trigger body, before `ataxia_promptCommands()`. This forces a line break so the prompt always appears on its own line.

---

## 2026-03-06 — ataxiaNDB `qwp` Fix (Missing Event Handlers)

### Bug Fix: `qwp` (online player list) never displays results

**Files added**:
- `src_new/scripts/.../ataxia_ndb/006_ataxiaNDB_Success.lua` — `sysDownloadDone` event handler for NDB downloads
- `src_new/scripts/.../ataxia_ndb/007_ataxiaNDB_Failed.lua` — `sysDownloadError` event handler for NDB download failures

**Root cause**: Two scripts from the original XML package — `ataxiaNDB_Success` and `ataxiaNDB_Failed` — were never extracted to `src_new/` during the initial conversion to the Muddler build system. These scripts are the glue between `downloadFile()` and the NDB processing:
- `ataxiaNDB_Success` listens for `sysDownloadDone`, checks if the file is in the `ataxiaNDB/` folder, routes `Online.json` to `ataxiaNDB_SortOnline()`, and parses individual player JSON into `ataxiaNDB.players[]`
- `ataxiaNDB_Failed` listens for `sysDownloadError` and handles download failures (e.g., player not found → removes from DB)

Without these handlers, `qwp` would call `ataxiaNDB_GetOnline()` → `downloadFile()` → download completes → **nothing happens** (no handler routes the file to processing).

**Also affected**: `ndb check <name>`, `ndb update`, and any other command using `ataxiaNDB_Acquire()` — individual player lookups also silently failed.

---

## 2026-03-06 — Converter Fix + Login Bug Fixes

### Critical: Muddler Converter Bug Fix (`tools/convert_to_muddler.py`)

**Problem**: When a non-folder trigger (`isFolder: 'no'`) has children AND a pattern with `mStayOpen`, the converter splits it into two entries: a folder (with children) and a separate trigger (with pattern + fireLength). Muddler auto-matches `.lua` script files by item name — since both entries share the same name, the folder unintentionally picks up the trigger's script. This caused the folder's script to execute on every child match (including every prompt), leading to:

- Game text being invisible (child trigger `^(.+).$` calling `deleteLine()` on every line)
- Defence list repeating "Defences currently active:" on every prompt
- Tattoo display firing on every prompt
- ~70 other multiline trigger groups silently broken

**Fix**: The converter now detects when a trigger shares a name with a sibling folder. In that case, the trigger's script is embedded inline in the JSON (`"script": "..."`) instead of written as a separate `.lua` file. The folder stays script-less. This affected 70 trigger groups (lua file count: 1404 -> 1334).

### Bug Fix: Defence List spam on every prompt

**Files changed**:
- `src_new/triggers/.../leviticus/710_Defence_List.lua` — Added `capturing_defences = true` flag
- `src_new/triggers/.../leviticus/711_get_Defence.lua` — Added `if not capturing_defences then return end` guard
- `src_new/triggers/.../leviticus/712_prompt_2.lua` — Added guard + `capturing_defences = nil` cleanup

**Root cause**: Converter bug (above) caused the folder's children to fire continuously. The `get Defence` child with pattern `^(.+).$` matched every line and called `deleteLine()`, hiding all game text. The prompt child called `ataxia_reportDefences()` on every prompt.

### Bug Fix: Tattoo display repeating on every prompt

**Files changed**:
- `src_new/triggers/.../tattoo_stuff/001_Tattoo_List.lua` — Added `capturing_tattoos = true` flag
- `src_new/triggers/.../tattoo_stuff/002_Gag_Lines.lua` — Added `if not capturing_tattoos then return end` guard
- `src_new/triggers/.../tattoo_stuff/003_Empty_Slot.lua` — Added guard
- `src_new/triggers/.../tattoo_stuff/004_Found_Tattoo.lua` — Added guard
- `src_new/triggers/.../tattoo_stuff/005_End_Capturing.lua` — Changed guard from `if not tattoosOnMe` to `if not capturing_tattoos` + cleanup

**Root cause**: Same converter bug. `tattoosOnMe` persisted after first use, so the old guard never blocked subsequent prompt-fired executions.

### Bug Fix: `ataxia_changeLog` nil error on login

**Files changed**:
- `src_new/scripts/.../ataxia/003_Install_System.lua` — Added nil guard: `if ataxia_changeLog then ataxia_changeLog() end`
- `src_new/aliases/.../172_Show_Changelog.lua` — Added nil guard + user-friendly message

**Root cause**: `ataxia_changeLog()` was called in two places but the function was never defined in the codebase.

### Design Pattern: `capturing_` flags for multiline trigger groups

The converter bug means all multiline trigger groups with children have their children fire continuously. The workaround is a global flag pattern:
1. Parent trigger sets `capturing_<name> = true`
2. All children check `if not capturing_<name> then return end`
3. Prompt/closing child clears `capturing_<name> = nil`

With the converter fix applied, this pattern is technically redundant for new builds but provides defense-in-depth.

### Bug Fix: Game text invisible — Readaura stuff `deleteLine()` on every line

**Files changed**:
- `src_new/triggers/.../leviticus/508_Readaura_stuff.lua` — Added `capturing_readaura = true` flag
- `src_new/triggers/.../leviticus/509_def.lua` — Added `if not capturing_readaura then return end` guard
- `src_new/triggers/.../leviticus/510_End.lua` — Added guard + `capturing_readaura = nil` cleanup

**Root cause**: The "Readaura stuff" multiline group (Occultist readaura) has a child trigger "def" with pattern `^(.+).$` and unconditional `deleteLine()`. Due to the converter bug, this child fires on every line of game text, deleting everything. This was the **primary cause** of all game text being invisible after login.

### Bug Fix: Fullsense-Hyena prompt deleting lines on every prompt

**Files changed**:
- `src_new/triggers/.../leviticus/456_Fullsense-Hyena.lua` — Added `capturing_fullsense_hyena = true` flag
- `src_new/triggers/.../leviticus/457_Each_person.lua` — Added `if not capturing_fullsense_hyena then return end` guard
- `src_new/triggers/.../leviticus/458_prompt.lua` — Added guard + cleanup, moved `deleteLine()` after guard

**Root cause**: Same converter bug. The prompt child called `deleteLine()` unconditionally before checking `fullSensePeople`, deleting the prompt line on every prompt.

### Bug Fix: Fullsense-Demon prompt deleting lines on every prompt

**Files changed**:
- `src_new/triggers/.../leviticus/459_Fullsense-Demon.lua` — Added `capturing_fullsense_demon = true` flag
- `src_new/triggers/.../leviticus/460_Each_person_1.lua` — Added `if not capturing_fullsense_demon then return end` guard
- `src_new/triggers/.../leviticus/461_prompt_1.lua` — Added guard + cleanup, moved `deleteLine()` after guard

**Root cause**: Same as Fullsense-Hyena above, but for the Baalzadeen variant.

### Bug Fix: Defence List prompt — `deleteLine()` ordering

**Files changed**:
- `src_new/triggers/.../leviticus/712_prompt_2.lua` — Moved `deleteLine()` after `capturing_defences` guard

**Root cause**: `deleteLine()` was called before the `capturing_defences` check, so the prompt line was deleted on every prompt even when not capturing defences.
