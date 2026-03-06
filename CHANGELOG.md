# LEVI-Achaea Changelog

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
