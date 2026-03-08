# LEVI-Achaea Changelog

---

## 2026-03-07 — NDB: Auto-honours hidden-city players + `an refresh` command

**Files**: `006_ataxiaNDB_Success.lua`, `198_Refresh_Honours.lua` (new)

**Feature 1 — Auto-honours hidden cities**: When the API returns `(hidden)` for a player's city and no prior city is known, the system now queues an automatic `honours` lookup instead of showing a warning. Hidden-city names are collected during the API batch and drained with 2s spacing after the batch completes.

**Feature 2 — `an refresh [city]`**: New alias to send `honours` for all tracked players (or filtered by city) to update mark, army rank, and dauntless status — data only available from in-game `honours`, not from the API. Uses 2s spacing between sends with ETA display and completion message.

---

## 2026-03-07 — Namespace rename: zData → ataxia.data + buildHunter fix

**Problem**: The hunting statistics system (`zData`) used a legacy namespace inconsistent with the standardized `ataxia` namespace. Additionally, `buildHunter` crashed with `attempt to call method 'loadPosition' (a nil value)` on some Mudlet versions.

**Fix — Namespace rename** (`zData` → `ataxia.data`):
- `src_new/scripts/_groups.yaml` — Inline init script: all `zData` refs → `ataxia.data`. Added backward-compat shim `zData = ataxia.data` at end of init block. Group names unchanged (build hierarchy).
- `src_new/scripts/.../zdata/001_Experience_Database.lua` — All `zData` → `ataxia.data`
- `src_new/scripts/.../zdata/002_movement.lua` — All `zData` → `ataxia.data`
- `src_new/scripts/.../zdata/004_buildHunter.lua` — All `zData` → `ataxia.data`
- `src_new/aliases/.../zdata/001_(zBash).lua` — All `zData` → `ataxia.data`
- `src_new/triggers/.../zdata/001-014` — All Lua code `zData` → `ataxia.data` (YAML hierarchy names unchanged)
- `src_new/triggers/.../highlighting/014_Paragon.lua` — `zData` → `ataxia.data`

**Fix — buildHunter loadPosition**: Wrapped `loadPosition()` call in nil check (`if window.loadPosition then`) for Mudlet version compatibility.

**Fix — buildChat startup**: Added `zgui.buildChat = ataxia.buildChat` shim after function definition in `012_buildChat.lua`. The startup module dispatch (`039_EDIT_ME__Startup_Main.lua` lines 89-91) calls `zgui["buildChat"]()` — after the previous rename to `ataxia.buildChat()`, this was nil and the chat never built at startup.

---

## 2026-03-07 — Bugfix: NDB alias crashes on unknown classes

**Files**: `186_Show_Class_Count.lua`, `187_Show_City_Count.lua`, `190_Tracked_of_class.lua`

**Root cause**: The `an classes` and `an cclasses` aliases had hardcoded `classes` tables missing Unnamable, Airlord, Earthlord, Firelord, and Waterlord. When a tracked player had one of these classes, `table.insert(classes[tab.class], ...)` crashed with "bad argument #1 to 'insert' (table expected, got nil)". The `an class` alias was also missing these classes from its `classList` used for the "Classless" filter.

**Fix**:
- Added all 5 missing classes to `classList` in all 3 alias files
- Replaced hardcoded `classes` table with dynamic construction from `classList`
- Added nil guard: `if not classes[tab.class] then classes[tab.class] = {} end`
- Added nil guard on `tab.class` and `tab.level` checks
- Added `math.max(0, ...)` guard on `string.rep` padding (prevents crash on long class names)
- Added nil guard on highlighting colour lookup in `an cclasses` (prevents crash for unknown city)

---

## 2026-03-07 — ClassDetect: Differentiate Shikudo from Tekura monks

**Problem**: ClassDetect set `attackerClass = "Monk"` for all monk attacks, switching to the generic `monk` curingset. Shikudo monks (staff-based) need the `shikudo` curingset for different curing priorities.

**Fix**:
- `src_new/triggers/.../determine_class/006_Monk_Class_Grab.lua` — Action now checks `line` for weapon keywords (`whips`, `staff`, `thrust`, `kata`, `sweeps`). Staff attacks → `"Shikudo"`, bare fist/kick attacks → `"Monk"` (Tekura).
- `src_new/scripts/.../class_detect/001_Class_Detect_Engine.lua` — Added `["Shikudo"] = "shikudo"` to `curingsetMap`.
- `src_new/scripts/.../self_limb_tracking/003_Parrying.lua` — Anti-Shikudo parry check now accepts `attackerClass == "Shikudo"` directly (in addition to legacy `"Monk"` + `shikudostance` fallback).

**Note**: Run `csd setup` in-game to create the `shikudo` curingset if it doesn't exist yet.

---

## 2026-03-07 — Chat: Channel colors + namespace rename (zgui.chat → ataxia.chat)

**Problem**: Chat miniconsoles showed mostly white/uncolored text. The `showChat()` function relied on `ansi2decho(gmcp.Comm.Channel.Text.text)` which doesn't carry the same ANSI coloring as the main console telnet stream. Only `shout` had custom color treatment. Additionally, the chat system used the legacy `zgui.chat` namespace instead of the standardized `ataxia` namespace.

**Fix — Channel colors**:
- `src_new/scripts/.../update_windows/001_showChat.lua` — Added `channelColors` map matching Achaea's CONFIG COLOUR (says=cyan, ct=red, ht/tell=yellow, party=magenta, newbie=green, etc.). Replaced `decho()` with `cecho()` using channel color for full message. Removed shout-only special case (now handled by color map). Removed unused `ansi2decho()` conversion.
- `src_new/scripts/.../gui_stuff/003_Chat_Capture_Things.lua` — Same channel color map and `cecho()` replacement for the ataxiagui chat handler.

**Fix — Namespace rename** (`zgui.chat` → `ataxia.chat`, `zgui.chatSize` → `ataxia.chatSize`):
- `src_new/scripts/.../build_windows/012_buildChat.lua` — `zgui.buildChat()` → `ataxia.buildChat()`, all `zgui.chat` → `ataxia.chat`
- `src_new/scripts/.../build_windows/013_Chat_Cmd_Prompt.lua` — `zgui.chatSend` → `ataxia.chatSend`, all `zgui.chat` → `ataxia.chat`
- `src_new/aliases/.../zgui_redux/006_(ZCHAT)_Toggle_Chat_Command_Line.lua` — Alias renamed `zchat` → `ataxiachat`, all `zgui.chat` → `ataxia.chat`
- `src_new/aliases/.../zgui_redux/002_(ZGUIS)_zGUI_Size.lua` — `zgui.chatSize` → `ataxia.chatSize`
- `src_new/scripts/.../039_EDIT_ME__Startup_Main.lua` — `zgui.chatSize` → `ataxia.chatSize`

---

## 2026-03-07 — Apostate: Disfigure fires on asthma round + CORRUPT V2/V3 reset

**Files modified**:
- `src_new/scripts/.../apostate/015_CC_Apostate.lua` — Moved disfigure from manaleech round to asthma round (probes whether target smokes before committing manaleech). Changed separator from `::` to `;` so disfigure fires same server tick as DEADEYES (bal+eq consumed simultaneously via `queue addclearfull freestand`). Removed `gmcp.Char.Vitals.bal == "1"` guard that prevented disfigure from firing when dispatch was called from reboundHold callback (GMCP bal update hadn't arrived yet in same data chunk). The `disfigureSent` flag already prevents spam.
- `src_new/triggers/.../apostate/007_CORRUPT.lua` — Added `resetAffsV2()` and `resetStatesV3()` calls after `expandAlias("res")`. Demon corrupt resets all target afflictions but the trigger only cleared V1 (via `res` alias). V2 certainty tracking and V3 probability branching states were stale after corrupt.

---

## 2026-03-07 — Full ataxiaNDB Overhaul (7 Phases)

Comprehensive overhaul of the player database system across 7 phases: critical bug fixes, case normalization, hash table conversions, namespace cleanup, robustness improvements, code quality polish, and new features.

### Phase 1: Critical Bug Fixes

**Files modified**:
- `src_new/scripts/.../ataxia_ndb/003_ataxiaNDB_API.lua` — Fixed `ataxia_Echo(...)` typo → `ataxiaEcho(...)`. Added nil guard on `io.open` in `ataxiaNDB_Remove`. All `string.rep` padding calls guarded with `math.max(0, ...)` to prevent crash on long names.
- `src_new/scripts/.../ataxia_ndb/006_ataxiaNDB_Success.lua` — Wrapped `yajl.to_value(s)` in `pcall` with error handling (removes corrupt JSON file on failure). Added nil guards on all API response fields (`t.house`, `t.city`, `t.class`, `t.level`, `t.xp_rank`, `t.player_kills`). Added nil guard on `io.open`. Changed string timer `tempTimer(3, [[honoursPerson = nil]])` to function closure.
- `src_new/scripts/.../ataxia_ndb/007_ataxiaNDB_Failed.lua` — Fixed Windows path separator: `filepath:match("[/\\]([%w_]+)%.json")` (was Unix-only `/`).
- `src_new/scripts/.../ataxia_ndb/005_ataxiaNDB_Display_API.lua` — All `string.rep` padding calls guarded with `math.max(0, ...)`. Added unknown class guard in `displayOnlineClass` (creates bucket dynamically). Added missing classes to classList: Pariah, Psion, Unnamable, Dragon, Airlord, Earthlord, Firelord, Waterlord. Fixed typo "acqusition" → "acquisition" (×2).

### Phase 2: Case Normalization

**Files modified**:
- `src_new/scripts/.../ataxia_ndb/003_ataxiaNDB_API.lua` — Standardized all API functions to use `name:title()` for player lookups: `ataxiaNDB_Exists`, `ataxiaNDB_isMark`, `ataxiaNDB_armyRank`, `ataxiaNDB_getColour`, `ataxiaNDB_getCitizenship`. Removed all dead underworld branches from `getColour` and `getCitizenship`. Simplified `getColour` to a single highlighting table lookup.

### Phase 3: Hash Table Conversions

**Files modified**:
- `src_new/scripts/.../ataxia_ndb/001_Ataxia_NDB_Settings.lua` — Converted `divine` from array to hash (`{Aegis=true, Artemis=true, ...}`). Removed `Underworld = "a_brown"` from highlighting table.
- `src_new/scripts/.../ataxia_ndb/002_Get_Information.lua` — Changed `table.contains(ataxiaNDB.divine, name)` → `ataxiaNDB.divine[name]` for O(1) lookup.
- `src_new/scripts/.../ataxia_ndb/003_ataxiaNDB_API.lua` — Same divine hash lookup change. Converted `apiOnlineFound` dedup from O(n²) `table.contains` to set-based O(1) dedup.
- `src_new/scripts/.../ataxia_ndb/007_ataxiaNDB_Failed.lua` — Converted blacklist to hash: `ataxiaNDB.notPlayers[name] = true` with hash-based `ataxiaNDB_isBlacklisted` using `:title()` fallback.
- `src_new/scripts/.../001_Save_Load_Settings.lua` — Added `migrateArrayToHash()` function that runs after `table.load` to convert existing array-format `notPlayers` and `divine` saves to hash format on first load.

### Phase 4: Namespace & Globals Cleanup

**Files modified**:
- `src_new/scripts/.../ataxia_ndb/002_Get_Information.lua` — `ndbWatcher` → `ataxiaNDB._watcher`. Removed redundant `ataxiaNDB_isBlacklisted and` nil checks.
- `src_new/scripts/.../ataxia_ndb/003_ataxiaNDB_API.lua` — `apiOnlineFound` → `ataxiaNDB._onlineFound` (made `apiNeedUpdate` local as it's only used within `SortOnline`).
- `src_new/scripts/.../ataxia_ndb/005_ataxiaNDB_Display_API.lua` — `parsingCity` → `ataxiaNDB._parsingCity`. Uses `ataxiaNDB._onlineFound`.
- `src_new/scripts/.../ataxia_ndb/006_ataxiaNDB_Success.lua` — `honoursPerson` → `ataxiaNDB._honoursPerson`.
- `src_new/triggers/.../745_Get_Player_Information.lua` — Uses `ataxiaNDB._honoursPerson`, `ataxiaNDB._mark`, `ataxiaNDB._armyRank`, `ataxiaNDB._dauntless`.
- `src_new/triggers/.../additional_information_ndb/001_Check_Player_City.lua` — `honoursPerson` → `ataxiaNDB._honoursPerson`.
- `src_new/triggers/.../additional_information_ndb/002_Close_Capturing.lua` — All globals namespaced: `honoursPerson`, `NDBIsMark`, `NDBARank`, `NDBIsDauntless` → `ataxiaNDB._honoursPerson`, `ataxiaNDB._mark`, `ataxiaNDB._armyRank`, `ataxiaNDB._dauntless`.
- `src_new/triggers/.../additional_information_ndb/003_Army_Rank.lua` — `NDBARank` → `ataxiaNDB._armyRank`.
- `src_new/triggers/.../additional_information_ndb/004_Ivory_Mark.lua` — `NDBIsMark` → `ataxiaNDB._mark`.
- `src_new/triggers/.../additional_information_ndb/005_Quisalis_Mark.lua` — `NDBIsMark` → `ataxiaNDB._mark`.
- `src_new/aliases/.../182_Honours_Person.lua` — `honoursPerson` → `ataxiaNDB._honoursPerson`.
- `src_new/aliases/.../181_Parse_QWHO.lua` — `parsingCity` → `ataxiaNDB._parsingCity`.

### Phase 5: Robustness

**Files modified**:
- `src_new/scripts/.../ataxia_ndb/004_ataxiaNDB_Highlighting.lua` — Removed `collectgarbage("stop")` and `collectgarbage()` GC hack. Switched string callbacks to function closures for `tempTrigger` (faster, no `loadstring`). Added event handler dedup with `ataxiaNDB._highlightHandlerId` (kills old handler before re-registering). Function closure for `enemyHighlights` timer. Removed `"underworld"` from `updateHighlights` condition.
- `src_new/scripts/.../ataxia_ndb/003_ataxiaNDB_API.lua` — Clean trigger ref on `ataxiaNDB_Remove` (`killTrigger` + nil assignment).

### Phase 6: Code Quality Polish

**Files modified**:
- `src_new/scripts/.../ataxia_ndb/005_ataxiaNDB_Display_API.lua` — Cached `getCitizenship` in `displayOnline` (was calling twice per player). Removed underworld from `displayOnline` (`underworld = {}` bucket and dead branch).
- `src_new/scripts/.../ataxia_ndb/003_ataxiaNDB_API.lua` — Simplified verbose boolean patterns in `ataxiaNDB_isEnemy`, `ataxiaNDB_Exists`, `ataxiaNDB_isCitizenOf`.

### Phase 7: New Features — Dauntless Tracking & Lookup Commands

**New files**:
- `src_new/triggers/.../additional_information_ndb/006_Dauntless.lua` — New trigger capturing `^(He|She|Fae) is one of The Dauntless\.$` from honours output. Sets `ataxiaNDB._dauntless = true`.
- `src_new/aliases/.../194_Show_Marks.lua` — `an marks [city]` alias: lists all tracked Mark members (Ivory/Quisalis), optionally filtered by city. Sorted alphabetically, color-coded by city.
- `src_new/aliases/.../195_Show_Army.lua` — `an army [city]` alias: lists all tracked army members sorted by rank descending. Rank 3+ highlighted in red (attackable for sanctions).
- `src_new/aliases/.../196_Show_Dauntless.lua` — `an dauntless [city]` alias: lists all tracked Dauntless members, color-coded by city.
- `src_new/aliases/.../197_Show_Threats.lua` — `an threats [city]` alias: combined threat view showing marks + army rank 3+ + dauntless with counts per category.

**Files modified**:
- `src_new/triggers/.../745_Get_Player_Information.lua` — Added `ataxiaNDB._dauntless = false` initialization alongside existing mark/army inits.
- `src_new/triggers/.../additional_information_ndb/002_Close_Capturing.lua` — Added dauntless save/clear block (sets `.dauntless = true` or clears to nil). Added `ataxiaNDB._dauntless = nil` cleanup.
- `src_new/scripts/.../ataxia_ndb/003_ataxiaNDB_API.lua` — Added `ataxiaNDB_isDauntless(name)` function.
- `src_new/scripts/.../ataxia_ndb/005_ataxiaNDB_Display_API.lua` — Added dauntless display in `displayWho`: shows "The Dauntless" line when player is dauntless.
- `src_new/scripts/.../ataxia_ndb/006_ataxiaNDB_Success.lua` — Preserves dauntless status across API refresh (`local isDauntless = ataxiaNDB_isDauntless(name)` before player record overwrite).

---

## 2026-03-07 — Bugfix: CORRUPT trigger resets V2 and V3 affliction tracking

**Files modified**:
- `src_new/triggers/.../apostate/007_CORRUPT.lua` — Added `resetAffsV2()` and `resetStatesV3()` calls after `expandAlias("res")`. Corrupt clears all afflictions on the target, but the trigger only reset V1 (`tAffs` via `res` alias). V2 certainty table and V3 branching states retained stale afflictions, causing the offense system to think afflictions were still present after corrupt fired.

---

## 2026-03-07 — Fix: Disfigure fires on asthma round instead of manaleech

**Files modified**:
- `src_new/scripts/.../apostate/015_CC_Apostate.lua` — Moved disfigure from manaleech round to asthma round. Disfigure now fires inline (`;` separator) with the deadeyes that delivers asthma, acting as an asthma probe: if target smokes before next balance, asthma was cured → skip manaleech (smoke-cured, wasted without asthma). If they don't smoke → asthma confirmed → safe to push manaleech. Also changed `disfigureSent` flag reset from manaleech to asthma gating. Removed debug echoes. Changed separator from `::` to `;` for same-tick execution (bal + eq).

---

## 2026-03-07 — Performance: SLC event handler accumulation + hot path optimization

**Files modified**:
- `src_new/scripts/.../self_limb_tracking/002_Track_The_Damage.lua` — **Critical**: Fixed event handler accumulation on script reload — `registerAnonymousEventHandler` for `"aff gained"`, `"aff cured"`, and `"self limb damaged"` now stores handler IDs and kills old ones before re-registering. Previously, each reload added duplicate handlers (N reloads = N redundant GUI redraws per damage event). Also debounced GUI updates with dirty-flag + `tempTimer(0)` to coalesce rapid hits into single redraw. Moved `shortNames` table to module-level `SHORT_NAMES` constant
- `src_new/scripts/.../self_limb_tracking/003_Parrying.lua` — Moved per-call `limbList` table allocation to module-level `LIMB_LIST` constant (was allocating identical 6-entry table every prompt)
- `src_new/scripts/.../self_limb_tracking/004_Defensive_Reactions.lua` — Fixed event handler accumulation: `"self limb threshold"` handler now cleaned up on reload. Added aeon check to auto-shield (prevents wasting shield tattoo under aeon). Added per-limb `partyCalloutSent` flag to prevent party callout spam (resets when limb returns to safe)

---

## 2026-03-07 — Bugfix: Anti-Shikudo parry never activating + safety fixes

**Files modified**:
- `src_new/scripts/.../self_limb_tracking/003_Parrying.lua` — Fixed critical case mismatch: `attackerClass == "monk"` → `"Monk"` (class detect engine stores titlecase). Anti-Shikudo parry was completely inert. Also wrapped Tykonos/Maelstrom recursive fallback in `pcall` so `cfg.antiShikudo` is always restored even on error
- `src_new/scripts/.../010_Prompt_Running.lua` — Changed hardcoded `tempTimer(3, ...)` parry spam cooldown to use `selfLimbDamage.config.parrySpamCooldown` (configurable, default 3s)

---

## 2026-03-07 — Bugfix: Double `onHerbCureV3()` calls in herb triggers + 002/004 fixes

**Files modified (round 1 — redundant V3 calls)**:
- `src_new/triggers/.../herbs/001_Goldenseal(U).lua` — Removed redundant `onHerbCureV3("goldenseal")` call
- `src_new/triggers/.../herbs/003_Kelp_(Unknown).lua` — Removed redundant `onHerbCureV3("kelp")` call
- `src_new/triggers/.../herbs/006_Ash.lua` — Removed redundant `onHerbCureV3("ash")` call
- `src_new/triggers/.../herbs/007_Ginseng.lua` — Removed redundant `onHerbCureV3("ginseng")` call
- `src_new/triggers/.../herbs/008_Ginseng_with_Flushings.lua` — Removed redundant `onHerbCureV3("ginseng")` call
- `src_new/triggers/.../herbs/009_Bellwort_Cuprum.lua` — Removed redundant `onHerbCureV3("bellwort")` call
- `src_new/triggers/.../herbs/010_Lobelia.lua` — Removed redundant `onHerbCureV3("lobelia")` call

**Root cause**: 7 herb triggers called `targetAteWrapper(herb)` (which internally calls `onHerbCureV3(herb)` when V3 is enabled) AND then directly called `onHerbCureV3(herb)` again. This caused V3 to model two herb cures per eat instead of one, halving affliction probabilities (e.g., 67% → 33%). The apostate `selectPrimaryCurse()` checks `asthmaProb >= 0.33` — with halved probabilities, asthma at 33% borderline fell into the wrong branch, selecting clumsy instead of manaleech.

**Files modified (round 2 — agent review findings)**:
- `src_new/triggers/.../herbs/004_Goldenseal_(Mycalium).lua` — Changed `targetAteWrapper("mycalium")` → `targetAteWrapper("goldenseal")`. "mycalium" is an affliction name, not a herb — `getCurableAffs("mycalium")` returned nil, making the wrapper a silent no-op for all tracking systems (V1/V2/V3). Also removed now-redundant direct `onHerbCureV3("goldenseal")` call. Added `removeAffV3("mycalium")` alongside existing `erAff("mycalium")` for V3 consistency.
- `src_new/triggers/.../herbs/002_Goldenseal_(Madness).lua` — Replaced manual `erAff("anorexia")` + `removeAffV3("anorexia")` + direct `onHerbCureV3("goldenseal")` with `targetAteWrapper("goldenseal")` for proper V1/V2/V3 routing (was missing V2 tracking entirely). Added `removeAffV3("shadowmadness")` alongside existing `erAff("shadowmadness")`. Anorexia clearing is now handled inside `targetAteWrapper()`.

**Not changed**: 005_Bloodroot_TEST — has custom V2 handler `onTargetBloodrootV2()` + direct `onHerbCureV3("bloodroot")`, functionally correct as-is.

---

## 2026-03-07 — Feature: SLC (Self Limb Counter) Complete Revamp

**Files modified**:
- `src_new/scripts/.../self_limb_tracking/001_Different_Attacks.lua` — Cleaned up dead code: removed all empty `confirm_*`/`confirmed_*` functions and tempLineTrigger chains, replaced with single `highlightLimb()` helper
- `src_new/scripts/.../self_limb_tracking/002_Track_The_Damage.lua` — Major rewrite: added full config system with defaults merge, per-limb threshold tracking (safe/warning/critical/broken), configurable torso break detection (100% instead of 97% guess), `"self limb threshold"` and `"self limb damaged"` events, updated GUI with hits-to-break display + `[P]` parry marker + `[!!]`/`[!]` indicators, color-coded thresholds
- `src_new/scripts/.../self_limb_tracking/003_Parrying.lua` — Complete rewrite: replaced broad 25/50/75% damage brackets with precise hits-to-break priority weights from config (`parryWeights`), added anti-Shikudo dynamic parry intelligence (stance-aware: Willow=legs with alternation, Rain=arms, Oak/Gaital=head with hyperfocus fallback to legs)
- `src_new/scripts/.../self_limb_tracking/004_Defensive_Reactions.lua` — **New file**: event-driven defensive reactions listening to `"self limb threshold"` — SSC priority (`curing prioaff`), auto-shield on critical, party callout, class-specific ability framework
- `src_new/aliases/.../slc/005_SLC_Toggle.lua` — **New file**: `slc` runtime toggle alias (`slc on/off`, `slc shield/party/ssc/warn/crit/shikudo on/off`, `slc parry <mode>`, `slc reset`, `slc gui`)
- `src_new/scripts/.../001_Save_Load_Settings.lua` — Added `selfLimbDamage.config` to save/load cycle (persisted as separate `slcconfig` file)
- `src_new/scripts/.../misc_scripts/020_Setup_Wizard.lua` — Added `levi setup slc` section with interactive toggle display and threshold configuration
- `src_new/triggers/.../035_reset.lua` — Rewired from legacy `slc.hitcount` to `ataxia_clearLimbDamage()`
- `src_new/triggers/.../036_Limb_healed.lua` — Rewired from legacy `slc.hitcount` to `ataxia_clearLimbDamage()`

**Files deactivated** (legacy SLC, `isActive: 'no'`):
- `src_new/scripts/.../slc/001_functions.lua`
- `src_new/scripts/.../slc/002_slc_variables.lua`
- `src_new/aliases/.../slc/001_SLC_Display.lua`
- `src_new/aliases/.../slc/002_SLC_Reset.lua`
- `src_new/aliases/.../slc/003_SLC_Set_#_of_Hits_Needed.lua`
- `src_new/aliases/.../slc/004_SLC_geyser_toggle.lua`

**What changed**: The game now shows exact limb damage percentages (e.g., "dealt 13.7% damage to your torso"). The old SLC was a hit-count estimator — obsolete. The new system:
- Tracks exact damage % per limb with threshold states (safe → warning → critical → broken)
- Fires events on threshold transitions for defensive automation
- Smart parry: weight-based algorithm using hits-to-break, configurable per mode (stand/defend/manual/random)
- Anti-Shikudo: dynamic parry that reads opponent's stance and adjusts targets (Willow→legs, Rain→arms, Oak/Gaital→head with hyperfocus detection)
- Full defensive suite: SSC priority changes, auto-shield, party callouts, class ability framework
- Every feature independently toggleable via `slc` alias or `levi setup slc`
- Config persists across sessions via save/load system

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
