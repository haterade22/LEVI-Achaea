# LEVI-Achaea Changelog

---

## 2026-03-14 — V3 affliction tracking: major enhancements

### Added: `scripts/.../affliction_tracking_core/007_Branching_State_Tracker.lua`

**Motivation:** ExpertDiagnoser review revealed multiple gaps in our V3 target affliction tracking compared to mature combat systems. These enhancements improve cure prediction accuracy, add timing intelligence, and provide offense systems with richer query APIs.

**Cure table fixes:**
- Added `burning` to `salveCureTableV3.body` — was missing, caused magi burn tracking to be incomplete
- Added `stuttering` to `salveCureTableV3.head` — was missing from head mending group
- Added SSC anorexia priority: body mending now cures anorexia first before other body affs (matches SSC behavior)

**New features:**
- **`countGroupAffsV3(group, minCount)`** — Query probability that target has N+ afflictions from a cure group across all branches. Predefined groups: `mending_body`, `mending_skin`, `mending_head`, `mending_arm`, `mending_leg`, `mending_all`, all herb groups, `smoke`. Returns 0.0-1.0 probability.
- **`getMostLikelyGroupAffCountV3(group)`** — Get count from most likely branch
- **Cure balance timers** — Track when target can next use each cure type. `startCureBalanceV3(type)`, `canTargetCureV3(type)`, `getCureBalanceTimeV3(type)`, `getAllCureBalancesV3()`. Durations: herb 1.3s, pipe 1.3s, salve 0.8s (1.3s when scalded), focus 2.2s, tree 13s
- **Scalded salve balance doubling** — When target has scalded, salve balance automatically uses 1.3s instead of 0.8s
- **Negative confirmation (backtracking)** — When V3 branches on ambiguous cure, starts a timer. If no second cure action within the balance window, unfolds the branch (re-adds all candidates). Prevents wrong guesses from persisting. Config: `affConfigV3.negativeConfirm`
- **`onClassCureV3(specificAffs, numRandom)`** — V3-native class cure processing. Removes specific affs deterministically + handles N random cures via passive cure pool

### Updated: `scripts/.../affliction_tracking_core/008_V3_Integration.lua`

- All verification signal handlers (`onTargetSmokeV3`, `onTargetFumbleV3`, `onTargetVomitV3`, `onTargetSlickFailV3`) now call `killNegativeConfirmV3()` to clear pending backtrack timers
- `onTargetTreeV3()` and `onTargetFocusV3()` now start cure balance timers
- `onTargetApplySalveV3()` now calls `killNegativeConfirmV3()` + `startCureBalanceV3("salve")` — salve application is a cure action
- `onTargetAteV3()` now calls `killNegativeConfirmV3()` + `startCureBalanceV3("herb")` — eating is a cure action
- `onPassiveCureV3()` now calls `killNegativeConfirmV3()` after state updates — passive cures resolve ambiguity

### Updated: `triggers/.../passive_active/*.lua` (21 class cure triggers)

- Replaced dead V2 stubs (`removeAffV2`, `reduceRandomAffCertaintyV2`) with `onClassCureV3()` calls
- All class-specific cures now properly integrate with V3 branching engine

---

## 2026-03-14 — Fix serpent flay wasting gecko (slickness) without asthma

### Fixed: `scripts/.../serpent/002_Serpent_Offense.lua`

**Motivation:** Flay venom selection could pick gecko (slickness) when the target didn't have asthma. Without asthma blocking smoking, slickness is instantly cured via valerian — a wasted venom slot. Observed in combat: flay rebounding with gecko, target immediately smokes to cure slickness.

**Changes:**
- Added asthma guard on flay fallback: if `envenomList[1]` is gecko but target lacks asthma, substitutes curare
- Added gecko option to flay if/elseif chain (after kalmia): when all 4 base affs present and asthma confirmed, proactively picks gecko
- Gated `scytherus_attack` strategy gecko behind asthma check, falls back to `pickVenom()` without asthma
- Fixed `lock_reinforce` second venom when paralysis missing: now uses `getLockingAffliction("name")` to dynamically look up the target's class-specific lock affliction (e.g., weariness for Knights, voyria for Apostate, haemophilia for Magi), maps it via `AFF_TO_VENOM`, and falls back to voyria. No longer wastes the slot on generic `pickVenom()` output like clumsiness
- Added `voyria` and `haemophilia` entries to `AFF_TO_VENOM` table for lock completion venom lookups

---

## 2026-03-14 — Add auto parry mode to SLC

### Added: `scripts/.../self_limb_tracking/003_Parrying.lua`, `002_Track_The_Damage.lua`

**Motivation:** The existing parry modes (stand, defend, manual, randomarm, randomleg) each use a single static strategy. An `auto` mode dynamically adapts based on enemy class and attack patterns — parrying focused limbs against limb classes (Knights, Monk, Blademaster, etc.) while defaulting to leg bias against affliction classes.

**Changes:**
- New `auto` parry mode: class-aware strategy using `classDetect.state.attackerClass` and hit-pattern detection
- Added `selfLimbDamage.hitHistory` — rolling window of last 6 hits for focus detection
- Added `ataxia_detectLimbFocus()` — analyzes last 4 hits to identify leg/arm/head focus
- Added `ataxia_autoParry()` — computes weighted parry with dynamic bias based on enemy class
- Anti-Shikudo still takes priority in auto mode (delegates to `ataxia_shikudoParry()`)
- Fixed `parryy` alias to use `validModes` table instead of missing `ataxia.parrying.modes`
- Updated `slc parry` and `parryy` help text to include auto mode
- Use: `slc parry auto` or `parryy auto`

---

## 2026-03-14 — Fix armour paragon swap skipping pry/insert

### Fixed: `scripts/.../gear_system/002_Armour_Paragons.lua`

**Motivation:** `armour pvp` (and other profile swaps) would show "Paragons already match profile" and skip pry/insert commands. The `needsSwap` optimization compared `state.currentSlots` against the profile, but `currentSlots` was updated optimistically after sending commands without verifying they succeeded in-game, causing false matches on subsequent calls.

**Changes:**
- Removed the unreliable `needsSwap` check from `swap()` — profile swaps now always send pry + insert commands (idempotent in Achaea, no downside)

---

## 2026-03-14 — Align magi offense with xMagi reference logic

### Fixed: `scripts/.../mage/004_Magi_Offense.lua`

**Motivation:** Multiple logic differences from the xMagi reference system were reducing offense effectiveness.

**Changes:**
- Removed `mode ~= "fire"` gate from glaciate check (Priority 3) — fires whenever hypothermia + dual resonance are met
- Removed `mode ~= "fire"` gate from hypothermia cast (Priority 7) — fires whenever frozen + dual resonance are met
- Removed `mode ~= "fire"` gate from freeze check (Priority 10) — fires whenever shivering + mending pressure conditions are met
- Renamed `countBrokenLimbs()` → `countMendingAffs()` — now counts ALL mending-consuming afflictions (broken limbs + burns + calcified torso/skull), not just broken limbs. Magi is a salve pressure class; freeze is stronger when the target's mending balance is already occupied by burns or calcification
- Erode fallback uses `MAINTAIN` argument to preserve resonance levels when stripping shield (previously used `shield`; ERODE without MAINTAIN drops all resonance by 1)

---

## 2026-03-14 — Fix evibe crash + meteorite syntax

### Fixed: `aliases/.../magi_things/003_Embed_Vibes.lua`

**Motivation:** `evibe` alias crashed with "attempt to index field 'magi' (a nil value)" when `ataxia.magi` hadn't been initialized yet (e.g., first use before toggling any vibes).

**Changes:**
- Added `ataxia.magi = ataxia.magi or {}` and `ataxia.magi.vibes = ataxia.magi.vibes or {}` initialization before accessing the table, matching the pattern in `002_Toggle_Vibes.lua`

### Fixed: `scripts/.../mage/004_Magi_Offense.lua`

**Motivation:** Meteorite cast commands had wrong word order (`cast meteorite <type> at <target>`) — correct Achaea syntax is `CAST METEORITE AT <target> <FLAMING|FROZEN|PURE>`.

**Changes:**
- Fixed all 3 meteorite commands in `selectMeteorite()` to use correct syntax: `cast meteorite at <target> <type> 4` (minimum 4s delay)

---

## 2026-03-14 — Fix hardcoded command separator in Locate Relay

### Updated: `scripts/.../locate_relay/001_Locate_System.lua`, `scripts/.../locate_relay/002_Locate_World.lua`

**Motivation:** Bulk locate relay was joining pt commands with hardcoded `::` instead of using the user's configured command separator (`ataxia.settings.separator`), causing commands to be sent as literal text rather than split into separate commands.

**Changes:**
- Replaced all 3 instances of `table.concat(chunk, "::")` with `table.concat(chunk, sep)` where `sep` reads from `ataxia.settings.separator` (defaulting to `";"`)

---

## 2026-03-14 — Auto-configure travel earrings via II + Probe

### Updated: `scripts/.../misc_scripts/020_Setup_Wizard.lua`

**Motivation:** Manually assigning 9+ earrings to locations required running `II earring`, probing each one individually, then typing `ataxia setup earrings <location> <earringID>` for each. Tedious with 11 earrings.

**Changes:**
- Added `ataxia setup earrings auto` command that automatically discovers and assigns all travel earrings
- Sends `II earring` to collect all earring IDs, then probes each sequentially (0.7s delay) to detect destination via "paired with another held by \<Name\>" pattern
- Displays summary of assigned locations with unmatched earring reporting
- Updated earring setup help text to show the auto option
- Follows existing probe queue patterns from itemCatalog/gearAudit (timer-based end detection, temp trigger cleanup, disconnect handler)

---

## 2026-03-14 — Fix SSC spamming class-specific defenses when not that class

### Updated: `deffing/004_Defence_Sorting_-_Cleaner.lua`, `deffing/002_Deffing_Up.lua`, `class_detect/001_Class_Detect_Engine.lua`

**Motivation:** SSC was repeatedly trying to CAST STONESKIN, CHARGESHIELD, DIAMONDSKIN (magi-only spells) even when the player was not a Magi, producing "[Curing]: CAST STONESKIN / You know of no such spell to cast." spam every prompt.

**Root cause:** `systemDefup()`, `defupFailsafe()`, and `classDetect.reapplyDefencePriorities()` sent all defenses from the active defup profile to SSC without checking whether the player's current class can actually use them.

**Changes:**
- Added `isDefenceForCurrentClass(defName)` helper in `004_Defence_Sorting_-_Cleaner.lua` — cross-references defenses against `ataxiaTables.classDefences` class-to-defense mapping, returning false if the defense belongs to a different class. Universal categories (curatives, shared, tattoos, endgame) always pass.
- Filtered `systemDefup()` and `defupFailsafe()` in `002_Deffing_Up.lua` to skip class-mismatched defenses
- Filtered `classDetect.reapplyDefencePriorities()` in `001_Class_Detect_Engine.lua` to skip class-mismatched defenses after curingset switches

---

## 2026-03-14 — Bulk Locate Relay system (locaterRelay_v3 integration)

### Added: `scripts/.../locate_relay/001_Locate_System.lua`, `002_Locate_World.lua`
### Added: `triggers/.../locate_relay/001_QWC_Parse.lua`, `002_QWC_Total.lua`, `003_Farsee_Success.lua`, `004_WhoB_Parse.lua`, `005_WhoB_End.lua`
### Added: `aliases/.../locate_relay/001_Locate_City.lua`, `002_Locate_Enemies.lua`, `003_Locate_World.lua`, `004_Locate_Data.lua`, `005_Locate_Summary.lua`
### Updated: `triggers/.../locate/001_Locate_Logic.lua`, `scripts/_groups.yaml`, `triggers/_groups.yaml`, `aliases/_groups.yaml`

**Motivation:** The existing locate system only handled single-target farsee requests via party tells. There was no way to bulk-scan an entire city, enemy list, or world to find where players are located. The `locaterRelay_v3.mpackage` provided this capability as a standalone package and has been integrated into the main system.

**Changes:**
- Added `LocateSystem` module — city-specific (`locate mhaldor`) and enemy list (`locate enemies`) bulk scanning with `who b` pre-resolution optimization and sequential farsee queue (0.9s delay)
- Added `LocateWorld` module — global scan (`lw`) of all online players, categorized by city and area with room grouping
- Added 5 triggers in `locate_relay` group (disabled by default, enabled during scans): QWC name parser, total count detector, farsee success handler, who-b line parser, who-b end detector
- Added 5 aliases: `locate <city>`, `locate enemies`, `lw` (world scan), `locate data <location>`, `locate summary`
- Results grouped by room and relayed to party chat (`pt`) in chunks of 20
- Added guard to existing `001_Locate_Logic.lua` to skip when bulk scan is running (prevents double-handling of farsee results)
- Registered `locate_relay` trigger group (isActive: false), `Locate Relay` script group, and `Locate Relay` alias group in `_groups.yaml` files

---

## 2026-03-13 — Chat window colors + handler consolidation (v4.5.1)

### Updated: `update_windows/001_showChat.lua`, `gui_stuff/003_Chat_Capture_Things.lua`

**Motivation:** Chat MiniConsole windows showed all text in white/gray because GMCP `Comm.Channel.Text.text` only contains `\27[0;37m` (white) ANSI — no channel-specific colors. The `ansi2decho()` conversion was faithfully producing white text. Additionally, two duplicate GMCP handlers were both firing on `gmcp.Comm.Channel.Start`.

**Changes:**
- Replaced `ansi2decho()` with `ansi2string()` to strip useless white ANSI wrapper
- Added channel color map (`channelColors`) with distinct decho colors per channel type: green (ct/army), yellow (house), purple (order), orange (clans), cyan (party), magenta (tells), teal (market), red (shout/yell), yellow (newbie)
- All chat text now echoed with channel-appropriate color prefix via `decho()`
- Added `muteList` check before echoing to MiniConsoles (muted users now suppressed in chat windows)
- Disabled legacy `ataxiagui_captureChat` handler — `zgui.showChat()` is now the single active handler
- Removed unused `shortName` variable and `getFgColor()`/`getBgColor()` calls

---

## 2026-03-13 — Basher configurability: wand, stormhammer, gem of cloaking, cleanup

### Removed: `basher/004_Guardians_Of_MoG.lua`
### Updated: `basher/001_Bashing_Functions.lua`, `basher/002_Class_Bashing.lua`, `genrunning/003_Engaged_Disengage.lua`
### Added: `aliases/.../configs/013_Wand_Reflection.lua`, `014_Stormhammer.lua`, `015_Gem_Cloaking.lua`

**Motivation:** Several basher features were hardcoded for a specific player (wand ID, stormhammer always-on, gem of cloaking always-on, Guardians of MoG enemy detection). These are now configurable toggles so any user can enable/disable them.

**Changes:**
- Deleted `004_Guardians_Of_MoG.lua` — inactive script with hardcoded enemy player name, no longer needed
- Removed stale `guardianofmogcunts` variable reference from `003_Engaged_Disengage.lua`
- **Wand of Reflection**: New toggle `ataxiaBasher.wandReflection` (default off) + configurable wand ID via `ataxiaBasher.wandId`. Toggle with `abwand`, set ID with `abwand <id>` (e.g., `abwand wand234800`). Emergency HP check now gated behind toggle.
- **Stormhammer**: New toggle `ataxiaBasher.stormhammer` (default off). Toggle with `abshuse`. Magi multi-target stormhammer only fires when enabled and 3+ valid targets present.
- **Gem of Cloaking**: New toggle `ataxiaBasher.gemCloaking` (default off). Toggle with `abgcuse`. Auto "say Tulahuar" in Moghedu on areabash start now gated behind toggle.

---

## 2026-03-13 — Blood Maiden cloak: configurable auto-activation

### Updated: `basher/001_Bashing_Functions.lua`, `triggers/.../769_Blood_Maiden_Cloak.lua`
### Added: `aliases/.../configs/012_Blood_Maiden_Cloak.lua`

**Motivation:** Blood Maiden cloak is an artefact not everyone owns. The old logic was always-on, counted all denizens (not just targets), had hardcoded Moghedu-specific rules, and didn't model the 3-minute active window correctly.

**Changes:**
- New toggle `ataxiaBasher.bloodMaiden` (default off) — toggle with `bmc` alias
- Trigger now gated on the toggle — won't set `bloodshieldReady` if disabled
- Mob count now only counts mobs in the area's basher target list (not all denizens)
- Removed Moghedu keeper-specific logic — simplified to: 4+ targetable mobs OR boss
- Boss list is configurable via `ataxiaBasher.bloodMaidenBosses` (hash table, persisted)
- Default bosses: Rhuzios, Underlord Seroth, Underlord Dreyvos
- After first activation, tracks a 3-minute active window (`ataxiaTemp.bloodshieldActive`) — cloak can be freely re-activated during this window without needing a new "ready" signal

---

## 2026-03-13 — World Tree area basher restrictions

### Updated: `basher/001_Bashing_Functions.lua`

**Motivation:** The Fathomless Expanse of the World Tree area has mobs that hit hard (triggering false danger/flee) and does not allow Culling Blade. Both needed area-specific suppression.

**Changes:**
- Culling Blade (`reap`) is now skipped when `gmcp.Room.Info.area` is "the Fathomless Expanse of the World Tree"
- Damage-rate flee ("Extreme incoming damage rate") and HP-threshold flee are disabled in the World Tree area — shield and wait checks still apply

---

## 2026-03-13 — Blademaster Ice Path (Quad-Prep) Update

### Updated: `blademaster/005_CC_BM_Ice.lua`

**Motivation:** Refined the quad-prep (`bmdq`) strategy to follow the optimal ice path kill route. Salve curing applies to the left leg first, so always targeting the right leg keeps it broken/mangled longer.

**Changes:**
- Added **flamefist phase** between leg prep and arm break — negates rebounding before the break sequence
- Leg break now always uses **legslash RIGHT** (not balanced) — right stays broken longer since curing restores left first
- Mangle phase now always uses **legslash RIGHT + sternum** — removed the "right to 200% then switch to left" logic
- New state flag `flamefistDone` resets on target change and full reset
- Flamefist pierces rebounding but still razes shield if shielded

**New 6-phase quad-prep order:** arm_prep → leg_prep → flamefist → arm_break → leg_break (RIGHT) → mangle (RIGHT + sternum)

---

## 2026-03-13 — Make system configurable for multiple users

### New: WEAPONLIST auto-detection, configurable weapons/mount/artefacts/earrings

**Motivation:** The system was built for a single character (Leviticus) with hardcoded weapon IDs, mount name, artefact IDs, and earring IDs across ~30 files. This makes the system usable by any player.

**New file:** `misc_scripts/023_Weapon_Detect.lua`
- `ataxia.scanWeapons()` — sends WEAPONLIST, parses output with temp triggers, groups weapons by type
- Auto-suggests slot assignments (DWC weapon1/2, DWB mstar1/2, staff/staff2, etc.)
- Sorts by damage (best weapon = primary slot)
- `ataxia.confirmWeapons()` saves to `ataxia.settings.weapons`
- `ataxia.swapWeaponSlots(s1, s2)` swaps pending assignments before confirming
- `ataxia.setWeaponSlotPending(slot, id)` overrides a slot before confirming

**New file:** `misc_scripts/022_User_Config.lua`
- Centralizes `ataxia.getWeapon(slot)`, `ataxia.getMount()`, `ataxia.getArtefact(slot)`, `ataxia.getEarring(location)`
- All helpers read from `ataxia.settings` at call time (no caching), so Setup Wizard changes take effect immediately
- `ataxia_initUserConfig()` called from `ataxiaCheckForMissing()` on every load
- Added `staff2` slot for Monk/Shikudo staff (separate from Magi `staff`)

**Extended:** `001_Save_Load_Settings.lua`
- `ataxia_defaultSettings()` now initializes `ataxia.settings.weapons` and `ataxia.settings.user` subtables

**Extended:** `020_Setup_Wizard.lua`
- `ataxia setup weapons scan` — auto-detect from WEAPONLIST
- `ataxia setup weapons confirm` — save scan results
- `ataxia setup weapons swap <s1> <s2>` — swap slot assignments
- `ataxia setup weapons set <slot> <id>` — manually set a slot
- `ataxia setup mount <name>` — set mount/companion name
- `ataxia setup artefacts <slot> <id>` — set pendant/bracelet/belt/ring IDs
- `ataxia setup earrings <location> <id>` — set travel earring locations
- `ataxia setup status` now shows mount, artefacts, and expanded weapon list

**Replaced hardcoded weapon IDs** (~30 files):
- `genrunning/003_Engaged_Disengage.lua` — 8 weapon IDs + removed dead `ataxiaTemp.me == "Leviticus"` check
- `dwc_runie/002-007` — scimitar IDs → `ataxia.getWeapon("weapon1"/"weapon2")`
- `dwc/001-002, 002_Group_Lock` — config defaults read from `ataxia.settings.weapons`
- `dwb_runie/001` — config defaults
- `023_LIMB_PREP, 024_RAMPAGE` — wield/wipe/envenom commands
- `i_snb/004_RAMPAGE, 005_LIMB_PREP` — same pattern
- `login/001_Login_Function.lua` — all weapon wielding on login
- `aliases/149_Empower_Weapons.lua` — all 13 weapon variables

**Replaced hardcoded mount name** (5 files):
- "impastus" → `ataxia.getMount()` in 038_TELL_IMPASTUS, 041_DRAGONFORM, 014_Urn, 015_FLYING, 134_NO_STEED_NEED

**Replaced hardcoded artefact IDs** (3 files):
- pendant/bracelet/belt → `ataxia.getArtefact()` in 006_GIVE_ARTIES, 007_WEAR_ARTIES
- ring → `ataxia.getArtefact("ring")` in 013_ICEWALL

**Replaced hardcoded earring IDs** (1 file):
- 9 location→ID pairs → `ataxia.getEarring()` in 080_HELP_Earring.lua
- Refactored from 9 if-then blocks to lookup table + helper function

**Fixed Monk vs Magi staff distinction:**
- `staff` slot = Magi primary staff, `staff2` slot = Monk/Shikudo staff
- Updated `003_Engaged_Disengage.lua` Monk section to use `ataxia.getWeapon("staff2")`
- Updated `login/001_Login_Function.lua` Shikudo wield to use `ataxia.getWeapon("staff2")`

---

## 2026-03-13 — v4.3.5: Fix sysupdate self-update system

**File:** `src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/021_Auto_Update.lua`

**Root cause:** The sysupdate flow called `uninstallPackage("Levi_Ataxia")` from within the package's own YAML-registered event handler. When the package was uninstalled, the `sysDownloadDone` handler was destroyed, making the subsequent `tempTimer` → `installPackage` flow unreliable.

**Fix:**
- Replaced YAML `eventHandlers` with `registerAnonymousEventHandler` — these survive package uninstall since they're registered at the Lua level
- Captured `packageFile` path to a local variable before uninstalling, so the closure doesn't depend on `ataxia.updater` surviving
- Separated `os.remove` into its own 1s timer after `installPackage` to prevent deleting the file before Mudlet finishes reading it
- Added handler cleanup on script reload to prevent duplicate handlers accumulating
- Added status echo at each step for visibility

---

## 2026-03-13 — Serpent: Pharaus V2 offense rewrite

### Major Rewrite: Attack execution, venom selection, and impulse delivery

**File:** `src_new/scripts/levi_ataxia/levi/levi_scripts/serpent/002_Serpent_Offense.lua`

**Motivation:** Ported 9+ improvements from the Pharaus V2 reference implementation to improve serpent lock reliability, reduce wasted EQ, and add new kill pressure mechanics.

**Changes:**

1. **Per-aff fratricide 3s cooldown** — `lastImpulsed[aff] = os.clock()` timestamps + `recordImpulse()` called on every impulse send. Two-pass `selectImpulse(excludeAff)` respects cooldown on Pass 1, ignores on Pass 2 (never returns nil). Replaces hardcoded "confusion" and `selectFallbackSuggestion()`.

2. **canUseSecondary / getPostAction() collision prevention** — Snap/shrug no longer collide with ekanelia impulse delivery. `getPostAction()` returns `(postAction, canUseSecondary)`. Overridden to true when `impatienceConditionsMet()`, `impatienceConditionsRelapse()`, or `kalmiaEkaneliaMet()`.

3. **Kalmia ekanelia during flay** — When `kalmiaEkaneliaMet()` and no eqAction, chains impulse on eq alongside flay on bal (dual-balance attack). Flay venom optimized for kalmia ekanelia context.

4. **Kalmia ekanelia as priority impulse** — Dedicated P3 check before normal impulse. Fires when clumsiness+weariness present, asthma absent, impulse eligible.

5. **Impatience delivery with confidence gates** — `canAttemptImpatience()` (4s cooldown, stamped from confirm trigger) + `impatienceConditionsMet()` (requires third condition: fratricide/hypochondria/scytherus/slickness) + `impatienceConditionsRelapse()` (relaxed: asthma+weariness sufficient). Replaces `serpent.shouldDeliverImpatience()`.

6. **Focus lock push** — `focusLockReady()` fires monkshood impulse when fratricide + 4 mentals + focus down + impatience + asthma + weariness. Overwhelms mental cure capacity.

7. **Enhanced lock_reinforce burst** — Impulse priority: scytherus ekanelia (addiction+nausea → camus spike) → voyria (anorexia+impatience → confusion+disrupted). Sets `voyriaSent`. DStab sequence: paralysis → voyria → vardrax+euphorbia → curare+recklessness.

8. **Unified pickVenom(exclude)** — Priority-based second venom selection with class-aware clumsiness (`wantClumsiness()`), lightwall darkshade (`hasLightwall()`), and slike gate (`slikeGateMet()`). All strategy branches use this instead of strategy-specific `buildSecondVenom*()`.

9. **Behead on prone truelock** — P2 check: truelock + prone → behead (scimitar) before execute.

10. **Rebounding/Shielded globals** — Shield/rebounding detection now also checks `Rebounding` and `Shielded` Ataxia globals (most reliable source).

11. **lastImpulsed cleared on target change** — Prevents stale cooldowns from previous target bleeding into new fight.

**Dead code removed:** `buildSecondVenom()`, `buildSecondVenomGinseng()`, `buildSecondVenomRelapse()`, `serpent.canDeliverAnorexia()`, `serpent.shouldDeliverImpatience()`, `serpent.checkBloodrootExploit()`

### Bug fixes (post-verification)

12. **lastImpatienceAttempt reset on target change** — Impatience cooldown (2.5s) was persisting across target switches, delaying first monkshood attempt on new targets. Now reset to 0 alongside `lastImpulsed = {}`.

13. **complete_softlock requires asthma anchor** — `determineStrategy()` was entering `complete_softlock` with just slickness+anorexia (no asthma), which has no lock value since both are salve/eat cures. Now requires asthma as mandatory anchor before counting anorexia/slickness pieces.

14. **checkImpulseEligible() gecko reset logic** — Was blindly short-circuiting to `true` when `geckoStripAttempted` was set, even if target re-applied quicksilver. Now checks sileris/fangbarrier first and resets `geckoStripAttempted`/`postGeckoLockdown` if defenses are back up, preventing wasted impulse/bite into active fangbarrier.

---

## 2026-03-12 — Serpent: track fangbarrier/sileris strip on flay shield/rebounding

### Bug Fix: Missing flay shield/rebounding patterns in sileris strip trigger

**File:** `src_new/triggers/.../706_Flayed_Sileris.lua`

**Problem:** When flaying shield or rebounding, fangbarrier/sileris is also stripped as a game mechanic side effect, but the trigger was missing the "You flay away X's shield defence" and "You flay away X's aura of rebounding defence" patterns. This meant `checkImpulseEligible()` could still see stale fangbarrier/sileris tracking after a flay.

**Fix:** Added two new regex patterns to trigger 706 to catch flay shield and flay rebounding messages, ensuring `erAff("fangbarrier")` and `erAff("sileris")` fire correctly.

---

## 2026-03-12 — Locate system: farsee + faemirror companion count

### Enhancement: Use farsee with faemirror for locate responses

**Files:** `src_new/triggers/.../locate/001_Locate_Logic.lua`, `003_Party_Locate.lua`, `005_Locate3.lua`, `004_Party_Locate_Scry.lua` (disabled)

All locate triggers now use `farsee` instead of `scry for`. The locate response waits for the faemirror result before replying, including companion count: `[alone]`, `[1 with them]`, `[3 with them]`, etc. Falls back to no companion info after 2s timeout if no faemirror is equipped. Scry bowl trigger disabled (no longer needed).

---

## 2026-03-12 — Fix nil table errors in Room Update and Ally/Enemy trigger

### Bug Fix: Defensive nil checks for uninitialized tables

**Files:** `src_new/scripts/.../update_stuff/002_ataxia_Room_Update.lua`, `src_new/triggers/.../allies_enemies/008_Ally_Enemy_added.lua`

**Problem:** Two race conditions caused `bad argument #1 to 'insert' (table expected, got nil)`:
1. `ataxiaBasher_path` used in Room Update flee logic before basher initialization
2. `ataxiaTemp.allies`/`ataxiaTemp.enemies` used before ALLIES/ENEMIES list trigger populates them

**Fix:** Added nil guards — `ataxiaBasher_path` check before `table.insert`, and `ataxiaTemp[key] = ataxiaTemp[key] or {}` before ally/enemy insertion.

---

## 2026-03-12 — Basher attack gate: block attacks during disabling afflictions

### Enhancement: Expanded basher affliction checks

**Files:** `src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua`

The basher attack send gate now checks for many more disabling afflictions before sending attacks. Previously only checked paralysis, aeon, and peace. Now also blocks on: transfixation, webbed, impaled, constricted, deepsleep, entangled, unconsciousness, and snared. This prevents wasted commands and queue spam when the character can't act.

---

## 2026-03-12 — Auto-flee on PvP attack while bashing

### New Feature: Basher attack detection

**Files:** `src_new/scripts/levi_ataxia/levi/ataxia/genrunning/001_Bashing_API.lua`, `src_new/scripts/levi_ataxia/levi/ataxia/016_Targeting_Functions.lua`

When the basher is enabled and the class detect system fires (`"attacker class detected"` event), the system now automatically:
1. Clears all queues (`cq all`)
2. Turns off auto bash rotation
3. Disables the basher
4. Navigates to Mhaldor via the mapper

Also: `switchTarget` now skips all PvP combat state resets (V3 states, affliction tracking, limb counters, class-specific resets) when bashing is enabled, eliminating the "[V3] States reset" spam during PvE.

---

## 2026-03-12 — Fix: zData hunting database nil errors

### Bug Fix: `mergeLoad` shallow merge wiping functions

**Files:** `src_new/scripts/levi_ataxia/levi/ataxia/001_Save_Load_Settings.lua`

**Problem:** `ataxia.data.db.addChar` and `ataxia.data.db.zoneAdd` were nil at runtime, causing errors on crit hits and zone changes. Both functions are defined in `001_Experience_Database.lua` during script load, but were wiped when `ataxia_loadSettings()` ran on `sysLoadEvent`.

**Root cause:** The `mergeLoad()` helper only merged 1 level deep. When loading saved `ataxia` data from disk, it correctly merged sub-keys of `ataxia.data`, but for nested tables like `ataxia.data.db`, it replaced the entire table with the saved (function-less) copy. Since `table.save` can't serialize Lua functions, the saved `ataxia.data.db` was a plain data table with no `addChar`, `zoneAdd`, `showData`, etc.

**Fix:** Made `mergeLoad` recursive via an inner `deepMerge` function. Now when both the loaded value and existing value are tables at any depth, it merges into the existing table (preserving functions) instead of replacing it.

---

## 2026-03-12 — Item Catalog System

### New Feature: Item Catalog (`catalog`)
A comprehensive inventory cataloging system that scans artefacts, talismans, promo items, and special equipment, cross-referencing each against a knowledge base to identify what every item does.

**Commands:**
| Command | Purpose |
|---------|---------|
| `catalog scan` | Full scan (ARTEFACT LIST + TALISMAN LIST + auto-probe unknowns) |
| `catalog quick` | Quick scan (ARTEFACT LIST + TALISMAN LIST only, no probing) |
| `catalog stop` | Abort an in-progress scan |
| `catalog show [artefacts\|talismans\|promo\|unknown]` | Display cataloged items by type/category |
| `catalog search <keyword>` | Search by name, power, effect, set, or category |
| `catalog info <id>` | Full details for a specific item |
| `catalog note <id> <text>` | Add/update a manual annotation |
| `catalog unknowns` | List unidentified items needing review |
| `catalog save` / `catalog load` | Manual save/load |
| `catalog help` | Command reference |

**Architecture:**
- Knowledge base (`itemCatalog.kb`) covers 200+ artefacts and all known talisman sets with effects, categories, and tiers
- Talisman keyword lookup (`itemCatalog.talismanKB`) maps TALISMAN LIST keywords to effects
- Scans use `tempRegexTrigger` for ARTEFACT LIST and TALISMAN LIST parsing with MORE pagination handling
- Auto-probes unknown items (0.7s delay between probes) and flags them for manual review
- Persistence follows the Legend Deck Manager pattern: `table.save/load` to `getMudletHomeDir()/itemcatalog` with `_ataxia_backup` fallback
- Skip patterns exclude boring consumables (vials, pipes)

### Files added
- `src_new/scripts/.../item_catalog/001_Item_Catalog_Init.lua` — Namespace, config, state machine, echo helpers, skip patterns
- `src_new/scripts/.../item_catalog/002_Item_Catalog_DB.lua` — Knowledge base (~400 lines, 200+ artefacts, all talisman sets)
- `src_new/scripts/.../item_catalog/003_Item_Catalog_Functions.lua` — Scan orchestration, KB matching, display, search, command dispatch
- `src_new/scripts/.../item_catalog/004_Item_Catalog_Save_Load.lua` — Persistence (save/load/backup)
- `src_new/aliases/.../item_catalog/001_Item_Catalog.lua` — `catalog` alias dispatcher

### Files changed
- `src_new/scripts/.../ataxia/001_Save_Load_Settings.lua` — Added `itemCatalog.save()` to `ataxia_saveSettings()` and `itemCatalog.load()` to `ataxia_loadSettings()`

---

## 2026-03-11 — Fix Shalestorm+Scintilla Priority + Burns Double-Counting

### Bug Fixes
- **CRITICAL: Scintilla blocking conflagrate/destroy**: Priority 5 (shalestorm+scintilla) fired every balance, preventing the burning path from ever reaching conflagrate. Burns sat at 5/5 with "CAN BE DESTROYED" but destroy never fired. Fixed by gating scintilla: skip when burns >= 5 (capped) or when conflagrate conditions are met (burns >= 2 + fire >= 2), allowing the burning path to select conflagrate properly.
- **CRITICAL: Burns double/triple counting**: Three pairs of duplicate triggers fired on the same game text, causing burns to increment 2-4x per event:
  - Scintilla spark: `staffcast/004_Immolation` incorrectly added +1 burn on spark (should be +0, ignition 4s later is +1). Deactivated — `010_Scintilla_Spark` is correct.
  - Scintilla ignition: `staffcast/003_Fire_Sco` duplicated `011_Scintilla_Ignition`, both adding +1 = +2 total. Deactivated `003_Fire_Sco`.
  - Emanation fire: `magi_offense_tracking/004_Emanation_Fire` duplicated `enamation/001_Fire_Emanation`, both adding +2 = +4 total. Deactivated `004_Emanation_Fire`.
- **Efreeti burns uncapped**: `025_Burns_Tracking` efreeti increment had no `math.min(..., 5)` cap, allowing burns to exceed 5. Fixed.
- **Misleading burns echo**: `021_Spell_Outcomes` displayed burns counter for all spell patterns (including magma, bombard, mudslide which don't affect burns). Now only shows for fulminate and firelash.
- **Mode echo spam**: `[Magi] Mode set to: salve` echoed on every `zz` keypress even when mode hadn't changed. Now only echoes when mode actually changes.

### Files changed
- `src_new/scripts/.../mage/004_Magi_Offense.lua` — Added burns gates to Priority 5 scintilla; `setMode()` only echoes on actual mode change
- `src_new/triggers/.../staffcast/003_Fire_Sco.lua` — **DELETED** (duplicate of 011_Scintilla_Ignition)
- `src_new/triggers/.../staffcast/004_Immolation.lua` — **DELETED** (duplicate of 010_Scintilla_Spark)
- `src_new/triggers/.../magi_offense_tracking/004_Emanation_Fire.lua` — **DELETED** (duplicate of enamation/001_Fire_Emanation)
- `src_new/triggers/.../general/025_Burns_Tracking.lua` — Added math.min cap to efreeti burns
- `src_new/triggers/.../general/021_Spell_Outcomes.lua` — Burns counter only shows for burn-related spells
- `src_new/scripts/.../limb_management/004_Magi-Specific.lua` — `magi_addBurns()` now syncs from `magi.offense.state.burns` (authoritative) instead of independently incrementing; `magi_checkDestroy()`/`magi_setDestroy()` read from `magi.offense.state.burns` via new `magi_getBurns()` helper

---

## 2026-03-11 — Armour/Paragon System Fixes + Gear Audit README

### Bug Fixes
- **Fixed morph command**: Was sending invalid `armour morph <type>`, now sends correct game command `MORPHARMOUR armour INTO <type>` (`002_Armour_Paragons.lua`)
- **Fixed armour type "(unknown)"**: Auto-detects armour type from current class on init when `currentArmourType` is nil

### Enhancements
- **Paragon type lookup table**: Added `PARAGON_TYPES` with all 24 paragon types and effects. `registerParagon()` now resolves raw game names (e.g., "an aeneaous paragon") to clean display names (e.g., "aeneaous (absorption)"). Stale names re-resolved automatically on load.
- **New `armour types` command**: Shows all 24 paragon types grouped by category (resistance, morphing, combat, regen, storage) with effects
- **README: Gear & Equipment section**: Added Gear Audit (`gearaudit`) and Armour/Paragon (`armour`) documentation to GitHub README

### Files changed
- `src_new/scripts/.../gear_system/002_Armour_Paragons.lua` — PARAGON_TYPES table, resolveParagonName(), morph fix, auto-detect, `types` command
- `CLAUDE.md` — Updated armour section with morph fix, paragon lookup, types command
- `README.md` — Added Gear & Equipment section with gearaudit + armour subsections

---

## 2026-03-11 — Target Priority Queue + Stormhammer Enhancement

### New Feature: Target Priority Queue (`tprio` namespace)
Ordered kill list for group PvP coordination, inspired by Tabethys's Target Priority package. Provides single-key target cycling, party synchronization, and presence-aware auto-targeting.

**New files**:
- `scripts/.../mage/006_Target_Priority.lua` — Core system: `tprio.add()`, `tprio.next()`, `tprio.previous()`, `tprio.first()`, `tprio.switchTo()`, `tprio.autoTarget()`, `tprio.syncEnemies()`, `tprio.pt()`
- `aliases/.../targetting/004_Target_Priority.lua` — `tgh Name1 Name2 Name3` sets priority list
- `aliases/.../targetting/005-011` — `tn` (next), `tb` (back), `tf` (first), `tpt` (party announce), `tpr` (reset), `tps` (show), `tpe` (enemy sync)
- `triggers/.../magi_offense_tracking/016_Party_Target_Priority.lua` — Auto-parses `(Party): X says, "Targets: A, B, C."` to set priority list

**Key features**:
- Position-resync on cycling (handles manual target changes gracefully)
- GMCP room player tracking with incremental add/remove
- Full combat state reset on switch (V3 affs, limbs, burns, balances)
- Ghost/soul filtering from GMCP data

### Enhancement: Stormhammer Mode System
Added runtime mode switching to `magi.storm` with 3 modes:

| Mode | Behavior |
|------|----------|
| `city` (default) | Original — targets enemies from same city as primary target |
| `all` | All enemies in room regardless of city |
| `priority` | Uses `tprio.list` ordering, then fills with remaining enemies |

**Changes to `005_Stormhammer_Targeting.lua`**:
- Added `magi.storm.mode`, `magi.storm.setMode()`, `magi.storm.getMode()`
- Primary target (`target`) always guaranteed in slot 1
- Priority mode iterates `tprio.list` in order for intelligent target selection
- `mm storm` alias cycles through modes (city → all → priority → city)

---

## 2026-03-11 — Stormhammer fires incorrectly after retarget + event name mismatch

### Bug Fix: Scintilla double-counting burns
**Root cause**: `005_Immolation_Staff.lua` added +1 burn via 4s timer on scintilla cast, AND `011_Scintilla_Ignition.lua` added +1 burn when the spark ignited — resulting in +2 burns per scintilla. With shalestorm causing near-instant ignition, both fired giving 2 burns instead of 1.

**Fix**: Removed the burn increment from `005_Immolation_Staff.lua` — the ignition trigger (011) already handles burn tracking when the spark actually ignites.

### Bug Fix: Stormhammer firing at full HP targets
**Root cause**: `targetHealth` (global, set by assess trigger) was never cleared on target switch, death, starburst, or manual reset. `magi.offense.getTargetHP()` checks `targetHealth` before `php`, so stale assess data from a previous target caused stormhammer to fire at HP ≤25% when the new target was actually at 91%+.

**Files changed**:
- `016_Targeting_Functions.lua`: Added `targetHealth = nil` on target switch (next to `php = 100`)
- `016_RESET.lua` (alias): Added `targetHealth = nil` on manual reset
- `401_Target_Has_Died.lua` (trigger): Added `targetHealth = nil` on target death
- `405_Starburst!.lua` (trigger): Added `targetHealth = nil` on target starburst

### Bug Fix: Magi offense and V3 tracker not resetting on target switch
**Root cause**: Event name mismatch — `switchTarget()` raises `"changed target"` but both handlers listened for `"ataxia target changed"` (never raised). This meant `magi.offense.reset()` and `resetStatesV3()` never fired on target change, so burns, shalestorm, scintillaSpark, and V3 affliction probabilities persisted across targets.

**Files changed**:
- `004_Magi_Offense.lua` (line 710): Changed event listener from `"ataxia target changed"` to `"changed target"`
- `007_Branching_State_Tracker.lua` (line 763): Changed event listener from `"ataxia target changed"` to `"changed target"`

---

## 2026-03-11 — Armour & Paragon Management System

### Feature
Configurable armour paragon profile system replacing 8 hardcoded aliases. Supports named profiles with paragon slots (1-3), trait selections, and armour morphing. Auto-swaps between bash and PvP profiles when basher enables/disables. Auto-detects owned paragons via `ii paragon` trigger and current embrasure state via `probe armour` trigger.

### New Files
- **`gear_system/002_Armour_Paragons.lua` (script)**: `ataxia.armour` namespace — profiles, swap logic, morph cooldowns, basher event hooks, persistence
- **`gear_system/002_Armour_Paragons.lua` (alias)**: `armour` command dispatcher (`^armour\s*(.*)$`)
- **`gear_system/001_Paragon_Inventory.lua` (trigger)**: Parses `ii paragon` inventory lines
- **`gear_system/002_Armour_Probe.lua` (trigger)**: Parses `probe armour` embrasure lines

### Deactivated Legacy Aliases
090_Armour_Paragons (`barmp`), 096_Mage_PvE (`magepve`), 097_Serpent_PvE (`serppve`), 098_Shikudo_Pve (`stickpve`), 099_Pariah_PvE (`pariahpve`), 100_BM_Pve_Traits (`bmpve`), 101_stickpvp, 102_Class_PvP (`armourpvp`) — all replaced by `armour <profilename>`

### New Commands
| Command | Purpose |
|---------|---------|
| `armour` | Show all profiles and auto-swap status |
| `armour <name>` | Swap to a named profile |
| `armour add <name>` | Create a new profile |
| `armour remove <name>` | Delete a profile |
| `armour set <n> slot1/2/3 <id>` | Set paragon in slot |
| `armour set <n> traits <...>` | Set trait list |
| `armour set <n> armourtype <t>` | Set morph target (type/auto/none) |
| `armour auto on/off` | Toggle auto-swap on basher enable/disable |
| `armour bash <name>` | Set which profile to use for bashing |
| `armour pvp <name>` | Set which profile to use for PvP |
| `armour morph <type/auto>` | Manually morph armour now |
| `armour scan` | Auto-detect paragons + current embrasures |
| `armour paragons` | Show known paragons |

### Seeded Default Profiles
bash, pvp, stickpvp, magepve, serppve, stickpve, pariahpve, bmpve — matching all legacy alias configurations

---

## 2026-03-11 — Gear Audit BiS (Best in Slot) PvE Analysis

### Feature
Added PvE damage scoring and Best-in-Slot analysis to the gear audit system. Scores each gear item based on offensive stats (damage %, celerity, burst, resistance penetration) and defensive stats (HP, regen, damage reduction), identifies BiS per set per slot AND overall BiS per slot, and generates scrap recommendations with copy-paste `GEAR SCRAP` commands.

### Changes
- **`gear_system/001_Gear_Audit.lua` — config**: Added `bisWeights` (10 stat weights + conditional multipliers) and `scrapThreshold` (0.5 = scrap below 50% of BiS)
- **`gear_system/001_Gear_Audit.lua` — scoreEffect()**: Extracts structured numeric stats from raw effect text (addDmgPct, celerity, burstPct, ignorePct, hpPct, etc. + condition detection)
- **`gear_system/001_Gear_Audit.lua` — calculateScore()**: Applies weighted scoring with burst normalization (per-attack effective value based on cooldown) and conditional multipliers (0.5x location, 0.7x battlerage)
- **`gear_system/001_Gear_Audit.lua` — getBisBySlot()**: Groups items by slot, sorts by score, assigns ranks
- **`gear_system/001_Gear_Audit.lua` — getScrapRecommendations()**: Per-set threshold comparison
- **`gear_system/001_Gear_Audit.lua` — displayBis/displayScore/displayScrap**: Color-coded display with per-set and overall BiS views, detailed score breakdowns, and ready-to-use scrap commands
- **`gear_system/001_Gear_Audit.lua` — command handler**: New subcommands: `bis`, `bis <slot>`, `score <id>`, `scrap`, `scrap <set>`

### New Commands
| Command | Purpose |
|---------|---------|
| `gearaudit bis` | Full PvE BiS analysis (all slots) |
| `gearaudit bis <slot>` | BiS analysis for a specific slot |
| `gearaudit score <id>` | Detailed score breakdown for a gear item |
| `gearaudit scrap` | Scrap recommendations + GEAR SCRAP commands |
| `gearaudit scrap <set>` | Scrap recommendations for a specific set |

---

## 2026-03-11 — Fix basher not attacking after F1 engagement

### Issue
After the Mar 10 refactor of `ataxiaBasher_attack()` into `ataxiaBasher_dangerLevel()`, the basher would engage correctly (find targets, pause mapper) but never send attack commands.

### Root Cause
The refactor removed the `if ataxiaTemp.bashFlee == nil then ataxiaTemp.bashFlee = false end` initialization from the old `ataxiaBasher_attack()`. Without it, `bashFlee` stays `nil` on fresh login. The final guard in `ataxiaBasher_assembleAttack()` used strict equality (`bashFlee == false`) which fails for `nil` since `nil == false` is `false` in Lua.

### Fix
- **`basher/001_Bashing_Functions.lua` — line 339**: Changed `ataxiaTemp.bashFlee == false` to `not ataxiaTemp.bashFlee` (truthy check), matching how all 15+ other callsites already check this variable.

---

## 2026-03-10 — Magi shalestorm+scintilla automation + configurable utility prefixes

### Feature
Automated scintilla casting when shalestorm is active (guarantees spark ignition via shalestorm's automatic damage). Added configurable artefact utility abilities (arachnideye, webbomb) as free-action prefixes.

### Changes
- **`004_Magi_Offense.lua` — selectSpell()**: New priority 5 — when shalestorm is active + torso not calcified + no pending spark + earth>=2, auto-cast `staffcast scintilla`. Works in ALL modes (fire/water/lock/salve/group). Existing lock/salve scintilla branches preserved unchanged
- **`004_Magi_Offense.lua` — sendAttack()**: Added optional utility prefix before `stand::wield`. `useArachnideye` prepends `arachnideye trample <target>` (gated: target not prone). `useWebbomb` prepends `webbomb <target>` (gated: target not entangled). Both default OFF
- **`004_Magi_Offense.lua` — config**: Added `useArachnideye` and `useWebbomb` boolean toggles
- **`004_Magi_Offense.lua` — status()**: Shows arachnideye/webbomb toggle state
- **`004_Magi_Offense.lua` — state**: Added `scintillaSpark`/`scintillaTimer` defaults + reset cleanup
- **`006_Magi_Mode.lua` — mm alias**: Added `mm arach`/`mm web` toggle commands, updated help text

---

## 2026-03-10 — Delete legacy Magi triggers, fix audit gaps

### Issue
16 deactivated legacy Magi triggers were cluttering the codebase. ExpertDiagnoser audit found V3 cure table gaps (6 missing afflictions), missing waking trigger, Slough not clearing weariness, misnamed freeze trigger, and erode line delta too narrow.

### Fix
- **Deleted 16 legacy files**: `general/006-008` (shalestorm), `general/011,013,016,017,018` (spell outcomes), `general/021_Dehydrate_-_Frozen` (misnamed freeze), `destroy-related/001-006` (all), `elementals/001_Efreeti`
- **Removed empty directories**: `destroy-related/`, `elementals/`
- **V3 cure tables** (`007_Branching_State_Tracker.lua`, `008_V3_Integration.lua`): Added `fulminated` (goldenseal), `guilt`+`horror` (lobelia), `pyre` (bellwort), `rebbies` (kelp), `unweavingspirit` (smoke), `stuttering` (focus)
- **`passive_active/021_Waking_Up.lua`** — New: detects target waking from sleep (yawn + gasp patterns), calls `erAff("sleep")`
- **`passive_active/016_Slough_(Fire_Lord).lua`** — Added `erAff("weariness")` before passive cure call
- **`general/021_Freeze.lua`** — New: renamed from misnamed "Dehydrate - Frozen", added target validation
- **`magi_offense_tracking/015_Erode.lua`** — `conditonLineDelta` 1→3 (matches reference, allows intervening combat lines)

---

## 2026-03-10 — Deactivate duplicate shalestorm triggers

### Issue
Three old shalestorm triggers (006, 007, 008 in `general/`) wrote to `magi.shalestorm` which nothing reads — the offense script reads `magi.offense.state.shalestorm` from the new unified `023_Shalestorm.lua`. Both sets fired on the same patterns, causing double `erAff("shield")` calls and dead writes.

### Fix
- **`general/006_Shalestorm_down.lua`** — Deactivated (superseded by 023)
- **`general/007_Shalestorm_shield.lua`** — Deactivated (superseded by 023)
- **`general/008_Shalestorm_up.lua`** — Deactivated (superseded by 023)

---

## 2026-03-10 — Erode trigger + missing class cure triggers + Fitness V3

### Issue
Erode spell had no trigger to parse which defense was stripped beyond shield (rebounding, blindness, etc.). Three class-specific cure abilities (Continuation/Monk, Priest Healing, Sylvan Root) had no tracking triggers. Fitness trigger (007) lacked V3 integration and didn't set `targetIshere`.

### Fix
- **`magi_offense_tracking/015_Erode.lua`** — New multiline trigger: parses eroded defense name from followup line, calls `erAff()` for shield + stripped defense (rebounding, blindness, deafness, caloric, insomnia, cloak, speed), party relay
- **`passive_active/018_Continuation_(Monk).lua`** — New: detects Monk continuation (`gives a great shout of exertion`), clears weariness + 1 random via V3
- **`passive_active/019_Priest_Healing.lua`** — New: detects Priest healing projection, clears voyria if present else 1 random via V3
- **`passive_active/020_Sylvan_Root.lua`** — New: detects Sylvan root (`stands suddenly upright, rooted to the earth`), clears haemophilia + 1 random via V3
- **`passive_active/007_Fitness_(Knights_Monk_BM).lua`** — Added `collapseAffAbsentV3("asthma")`/`collapseAffAbsentV3("weariness")` for V3 branch collapse, added `targetIshere = true`

---

## 2026-03-10 — Magi Trigger Audit: Fix duplicates, add missing triggers

### Issue
5 legacy triggers (011_Mudslide, 013_Fulminate, 016_Bombard, 017_Magma, 018_Firelash) fired on the same regex patterns as 021_Spell_Outcomes.lua, causing double burns counting, double affliction applications, and double scalded tracking. Additionally, 021 had bugs: dehydrate incorrectly incremented burns on cast (before outcome known), fulminate lacked smart chain logic, bombard missed clumsiness, mudslide missed slickness, firelash missed burning.

### Fix
- **Rewrote 021_Spell_Outcomes.lua** with merged logic from all 5 legacy triggers
- **Deactivated 5 legacy duplicates** (`isActive: 'no'`): 011, 013, 016, 017, 018
- **Created 7 new triggers** in `magi_offense_tracking/` (008-014): Transfix, Transfix Unblind, Scintilla Spark/Ignition, Staffcast Lightning/Freeze, Deepfreeze

### Changes
- **`general/021_Spell_Outcomes.lua`** — Full rewrite with merged logic: fulminate smart chain (fulminated→epilepsy→paralysis), dehydrate no longer increments burns on cast, bombard tracks clumsiness, mudslide tracks slickness+prone, firelash tracks burning+burns, magma has 20s scalded timer
- **`general/011_Mudslide.lua`** — Deactivated (superseded by 021)
- **`general/013_Fulminate.lua`** — Deactivated (smart chain merged into 021)
- **`general/016_Bombard.lua`** — Deactivated (clumsiness merged into 021)
- **`general/017_Magma.lua`** — Deactivated (scalded+timer merged into 021)
- **`general/018_Firelash.lua`** — Deactivated (burning+burns merged into 021)
- **`magi_offense_tracking/008_Transfix.lua`** — New: tracks transfix writhing on target
- **`magi_offense_tracking/009_Transfix_Unblind.lua`** — New: detects transfix curing blindness
- **`magi_offense_tracking/010_Scintilla_Spark.lua`** — New: 4s spark timer tracking
- **`magi_offense_tracking/011_Scintilla_Ignition.lua`** — New: burning + burns increment on ignition
- **`magi_offense_tracking/012_Staffcast_Lightning.lua`** — New: staffcast lightning relay
- **`magi_offense_tracking/013_Staffcast_Freeze.lua`** — New: horripilation from staffcast freeze
- **`magi_offense_tracking/014_Deepfreeze.lua`** — New: AoE frozen tracking

---

## 2026-03-10 — README: Fix broken .claude/classes/ link

### Problem
The `.claude/classes/` link in README.md returned a 404 on GitHub. The link target was `LEVI-Achaea/.claude/classes/` — the extra `LEVI-Achaea/` prefix caused a double path since the repo name is already part of the GitHub URL structure.

### Fix
Changed link target from `LEVI-Achaea/.claude/classes/` to `.claude/classes/`.

### Changes
- **`README.md`** — Fixed relative link path for the `.claude/classes/` directory

---

## 2026-03-10 — Limb Counter: Convert to Adjustable.Container

### Summary
Converted the Limb Counter window (`tarc`) from a raw `Geyser.MiniConsole` to an `Adjustable.Container` with an embedded `MiniConsole`. Users can now drag, resize, lock, and pop out the limb counter window, and its position auto-saves across sessions.

### Changes
- **`windows/001_Limb_Counter_Window.lua`** — Wrapped `tarc` in `Adjustable.Container:new({name = "tarc.window"})` with dark styling; embedded `Geyser.MiniConsole` as `tarc.console` inside a `Geyser.Container`; added simple forwarding functions (`tarc:cecho()` → `tarc.console:cecho()`, `tarc:clear()` → `tarc.console:clear()`) for backward compatibility with `tarc.write()` callers

### Notes
- All existing code calling `tarc:cecho(text)` and `tarc:clear()` works without modification
- Window position persists via Adjustable.Container's auto-save (`name = "tarc.window"`)
- Use `zfix tarc.window` to reset position if needed

---

## 2026-03-10 — Serpent: Darkshade mode second venom should be curare

### Issue
In darkshade mode, `apply_darkshade` strategy was hitting with `curare + darkshade` (curare first) instead of `darkshade + curare`. Similarly, `ginseng_pressure` in darkshade mode put curare first. The second venom should always be curare (to maintain paralysis and block tree) unless paralysis is already present.

### Fix
- `apply_darkshade` + darkshade mode: darkshade first, curare second (falls back to `buildSecondVenom()` if paralysis present)
- `ginseng_pressure` + darkshade mode: ginseng aff first, curare second

### Changes
- **`002_Serpent_Offense.lua`** — Reordered venoms in `apply_darkshade` and `ginseng_pressure` strategies for darkshade mode

---

## 2026-03-10 — Serpent: Fix double dispatch on gecko strip round

### Root Cause
The `attackInFlight` guard in `serp_ekanelia_offense()` was defeated by the GMCP vitals event handler, which cleared `attackInFlight` on **every** `gmcp.Char.Vitals` update where `bal == "1"` (level-triggered). When the user mashed the keybind, a second dispatch snuck through within ~100ms because the vitals handler fired between presses with stale `bal = "1"` (server hadn't consumed balance yet).

This caused: gecko strip echo + impulse echo on the same balance, but only the gecko dstab executed. The impulse queued for next balance via `queue addclear freestand`, creating a confusing echo mismatch.

### Fix
Changed the balance recovery handler from level-triggered to **edge-triggered** — `attackInFlight` now only clears on the `0→1` bal transition, not on every prompt where bal happens to be "1".

### Changes
- **`002_Serpent_Offense.lua`** — Edge-triggered `attackInFlight` clear via `serpent.state.lastBalState` tracking; added state init

---

## 2026-03-10 — GUI Simplification

### Summary
Stripped down the GUI to only load essential windows on startup. The full Geyser GUI (`ataxiagui`) is now disabled by default. All scripts remain active (`isActive: 'yes'`) — the change is purely in which windows get built on login.

### Windows that load on startup
- **Chat** — Tabbed chat window (zgui)
- **Map** — Mapper window (zgui)
- **Bash Window** — Basher status console (zgui)
- **Limb Counter** — Target limb tracking (standalone `tarc` namespace)
- **Hunter** — Hunting Scrolls (ataxia.data, loaded independently)

### Windows no longer loaded by default
Target Affs, Room Players, Room Denizens, Vital Bars, Cape gauge, Affliction Lock, Self Affs, Enemy/Ally lists, Prompt window, Stats window, Room Info — all still available via `zshow` if needed.

### Changes
- **`039_EDIT_ME__Startup_Main.lua`** — Removed `buildTarAffs`, `buildRoomPlayers`, `buildRoomDenizens` from `zgui.modules`; added `buildBashWindow`; removed vital bars `ataxia.bars.buildAll()` call; removed `zgui.vitals` init block; cleaned up unused font size vars
- **`002_Check_For_Any_Missing_Variables.lua`** — Default `ataxia.usegui = false` (was `true`) so the full Geyser border GUI doesn't load for new installs
- **`020_Setup_Wizard.lua`** — Updated `ataxia setup gui` to explain simplified GUI; `on`/`off` toggle still works for users who want the full Geyser layout; updated `ataxia setup status` label

### Notes
- Existing users with `ataxia.usegui = true` saved will still get the full Geyser GUI until they run `ataxia setup gui off`
- All update functions (`showAffs`, `showAllies`, `showEnemies`, `showRoomInfo`, `showCape`) remain defined and safe to call — Mudlet silently ignores writes to non-existent consoles
- No nil-guards needed — all call sites are either self-guarding or target consoles that handle missing windows gracefully

---

## 2026-03-10 — Shikudo Party Callout Fix

### Problem
Third-person Shikudo "Calls" triggers (004-007 in `calls/`) fired on effect text visible from ANY monk's attacks, not just the player's. This caused false party callouts (`pt Rat: clumsiness`, etc.) and incorrect affliction tracking when other monks (e.g., Mystor) attacked nearby.

### Fix
Deactivated all 4 redundant third-person triggers — the first-person equivalents (578, 569, 572, 576) already handle the player's own attacks correctly with `isTargeted()` gates:

| Deactivated Trigger | First-Person Equivalent |
|---------------------|------------------------|
| `004_Ruku_Clumsiness_Healthleech.lua` | `578_1Ruku_arms_(healthleech_clumsy).lua` |
| `005_Kuro_Weariness_Lethargy.lua` | `572_1Kuro_(weariness_lethargy).lua` |
| `006_Ruku_Torso_Slickness.lua` | `569_2Ruku_torso_(slickness).lua` |
| `007_Livestrike_Asthma.lua` | `576_Livestrike_(asthma).lua` |

---

## 2026-03-10 — Magi Offense Audit Fixes (P1-P6)

### Summary
Fixed 6 priority issues from reference system audit (xMagi/Tabethys comparison). Burns double-counting, missing burns decrement, fire resonance conditional logic, conflagrate gate, and meteorite variant keyword.

### Issues Fixed

**P1/P3 — Burns double-counting from duplicate triggers**
- Deactivated 3 old triggers that overlapped with new unified triggers:
  - `elementals/001_Efreeti.lua` → duplicated by `025_Burns_Tracking.lua`
  - `fire/001_Fire_Third.lua` → duplicated by `022_Resonance_Afflictions.lua`
  - `fire/002_Fire_Second.lua` → duplicated by `022_Resonance_Afflictions.lua`
- Old triggers under `staffcast/`, `fire/003` kept active (unique patterns, not duplicates)

**P2 — Burns never decrement**
- Added pattern `^The fires consuming (\w+) diminish somewhat\.$` to `025_Burns_Tracking.lua`
- Decrements `magi.offense.state.burns`, clears `burning` aff and `conflagrated` flag when burns reach 0

**P4 — Conflagrate gate too strict**
- Changed from `burning >= 2 and r.fire >= 2 and r.air >= 2` to `burning >= 2 and r.fire >= 2`
- Reference system (xMagi) only requires `fire >= 2`, not `air >= 2`

**P6 — Meteorite missing "pure" keyword**
- Changed `"cast meteorite at "` to `"cast meteorite pure at "` in `selectMeteorite()` fallback

**Fire resonance conditional logic (in 022_Resonance_Afflictions.lua)**
- Fire level 2: Now checks scalded state before incrementing burns (scalded first, then burns if already scalded)
- Fire level 3 blistered: Added `tempTimer(15, ...)` for blistered fade
- Fire level 3 burning: Added burns counter display with `cecho()`
- Uses `magi.offense.setScalded()` for 20s timer management

### Files Changed
- `triggers/.../elementals/001_Efreeti.lua` — `isActive: 'no'`
- `triggers/.../fire/001_Fire_Third.lua` — `isActive: 'no'`
- `triggers/.../fire/002_Fire_Second.lua` — `isActive: 'no'`
- `triggers/.../general/022_Resonance_Afflictions.lua` — fire conditional logic
- `triggers/.../general/025_Burns_Tracking.lua` — burns diminish pattern
- `scripts/.../mage/004_Magi_Offense.lua` — conflagrate gate + meteorite pure

**P9 — Caloric defense tracking (frostbite proxy → direct nocaloric)**
- Changed `caloric` variable from frostbite proxy to direct `not hasAff("nocaloric")`
- `nocaloric` already tracked by existing triggers (391, dehydrate, freeze chain, waterbond)

### Deferred Issues
- P5 (staffcast lightning → stupidity): Unknown game text pattern
- P7 (firestorm target burns): Unknown game text pattern
- P11-P13: Low priority cleanup

---

## 2026-03-10 — Default Curing Priorities Overhaul

### Summary
Complete overhaul of SSC default curing priorities in `ataxia_defaultCuringPrios()`. Many afflictions were at dangerously low priorities (e.g., peace at 16, fear at 20, confusion at 20) with comments about dynamic swaps that were never implemented. Priorities now reflect actual combat urgency.

### File Changed
`001_Default_Curing_Prios.lua` (scripts/levi_ataxia/levi/ataxia/ataxia/)

### Architecture Change
- `ataxia_sendDefaultPrios()` refactored to loop over the `ataxia_defaultCuringPrios()` table instead of hardcoded send strings — eliminates duplication and keeps table+send in sync
- Fixed `local function` → global `function` for `ataxia_sendDefaultPrios()` (was nil when called from alias)

### Priority Changes (24 afflictions adjusted)
| Affliction | Old | New | Reason |
|-----------|-----|-----|--------|
| peace | 16 | 2 | Can't attack or defend — total incapacitation |
| pacified | 14 | 3 | Can't use aggressive actions |
| paralysis | 4 | 3 | User priority: stay unparalyzed. Blocks tree. No bloodroot competition |
| impatience | 6 | 4 | Blocks focus. Hardlock component |
| prone | 9 | 2 | Enables kill combos (impale, vivisect, trample) |
| fear | 20 | 5 | Forces fleeing. Bal-free cure |
| disrupted | 9 | 2 | Blocks tree tattoo. Bal-free cure |
| clumsiness | 14 | 7 | 33% miss chance |
| voyria | 9 | 2 | Class lock aff. Sip-cured (separate balance) |
| nausea | 11 | 8 | Blocks parry. Important vs limb classes |
| stupidity | 18 | 8 | Focus handles normally, but 18 was absurd fallback |
| epilepsy | 18 | 8 | Random seizures lose balance |
| recklessness | 21 | 8 | 50% more damage taken |
| masochism | 21 | 8 | Ekanelia enabler for Serpents |
| confusion | 20 | 8 | Blocks actions. Ash-cured |
| dizziness | 23 | 9 | Vertigo synergy |
| vertigo | 16 | 9 | Dizziness+vertigo = falling |
| healthleech | 14 | 9 | Ticking damage |
| addiction | 11 | 9 | Riftlock enabler |
| horror | 8 | 10 | Less urgent than combat affs |
| paranoia | 17 | 10 | Blocks ally help |
| dementia | 17 | 10 | Random actions |
| shyness | 23 | 12 | Focus fallback was at 23 |
| timeloop | 5 | 4 | DW mechanic — moved from 5 to 4 |

### Stacking Affliction Variants Added
- `burning1`–`burning5` at priority 9
- `pyre1`–`pyre3` at priority 9, `pyre` base at 8
- `horror1`–`horror5` at priority 9
- `unweavingbody1`/`unweavingbody2`/`unweavingmind1`/`unweavingmind2` at 25 (low stacks deprioritized)
- `unweavingbody3`–`5`/`unweavingmind3`–`5` at 2 (high stacks = critical)
- `insomnia` at 26 (SSC custom handling)

### Other Adjustments
- `mangledhead` moved from 9 → 8
- Removed generic `unweavingbody`/`unweavingmind` entries (replaced by leveled variants)
- `indifference` set to 25 (deprioritized)
- Writhe affs (entangled, bound, webbed, etc.) kept at 2
- Priority 1 remains RESERVED for dynamic swap system

---

## 2026-03-10 — Magi Burns: Scintilla Not Incrementing Burns Counter

### Root Cause
`004_Immolation.lua` (scintilla success trigger) only set `timmolation = true` without incrementing `magi.offense.state.burns`. Burns counter stayed at 0 through 6+ scintilla casts, only incrementing when fire resonance passive ("Flames ignite") or efreeti ticks fired.

### Fix
| File | Change |
|------|--------|
| `staffcast/004_Immolation.lua` | Added burns increment + `tarAffed("burning")` + burn counter echo on scintilla hit |

---

## 2026-03-10 — Simultaneity Defense Tracking Fix

### Root Cause
GMCP never reports "simultaneity" as a defense — it's not in `gmcp.Char.Defences.List`. The `def` command only displayed defenses from GMCP, so simultaneity always showed `[-]` even when active.

### Fix
| File | Change |
|------|--------|
| `012_Fortify.lua` | Set `ataxia.defences["simultaneity"] = true` when "You forge a channel" trigger fires |
| `003_Defence_Reporting.lua` | Inject text-tracked defenses (simultaneity) into the `def` display when `ataxia.defences` flag is set |

---

## 2026-03-10 — Magi Offense: Alias Routing per Mode

### Alias Mode Routing (5 files)
| Alias | Regex | Magi Mode | File |
|-------|-------|-----------|------|
| First Attack | `^zz$` | salve (default) | `152_First_Attack_(All_Classes).lua` |
| Second Attack | `^xx$` | fire | `155_Second_Attack_(All_Classes).lua` |
| Third Attack | `^cc$` | lock | `156_Third_Attack_(All_Classes).lua` |
| Fourth Attack | `^vv$` | water | `153_Fourth_Attack_(All_Classes).lua` |
| Group Attack | `^sr$` | group | `154_Group_(All_Classes).lua` (already wired) |
| Scytherus | `^srr$` | stormhammer | `157_Scytherus_(All_Classes).lua` |

Each alias now calls `magi.offense.setMode(mode)` before `magi.offense.dispatch()` so mode is explicit per keybind. Stormhammer (`srr`) uses `magi.storm.fire()` with fallback to raw `cast stormhammer`.

---

## 2026-03-10 — Magi Offense: Mode Logic + Final Trigger Fixes

### Trigger Fixes (continued)
| File | Fix |
|------|-----|
| `024_Meteorite.lua` | Flaming variant missing `tarAffed("burning")` — V3 never knew target was burning from meteorite |
| `024_Meteorite.lua` | Burns increment uncapped — added `math.min(..., 5)` + tburns sync |
| `022_Resonance_Afflictions.lua` | Fire moderate/major branches missing `tarAffed("burning")` — V3 unaware of resonance burns |
| `022_Resonance_Afflictions.lua` | Burns increment uncapped — added `math.min(..., 5)` + tburns sync |

### New Mode Logic (004_Magi_Offense.lua)
- **Salve mode** (`selectSalveSpell()`): Prioritizes earth resonance for salve-curable affs (limb breaks, cracked ribs, calcified torso), magma for salve balance lock, scintilla for calcify
- **Group mode** (`selectGroupSpell()`): Stormhammer threshold raised to 50% HP (vs 25% default), emanation fire/earth at cap for AoE pressure, shalestorm for earth AoE, pure damage fallback
- **Firestorm state sync**: `dispatch()` now syncs `magi.firestorm` legacy global into `magi.offense.state.firestorm`

---

## 2026-03-10 — Magi Offense Bug Fixes & Trigger Updates

Comprehensive review and bug fix pass across the entire Magi offense system. Fixed critical bugs in the core offense script, all 4 emanation triggers, shalestorm, burns tracking, conflagrate fail, and calcify triggers. Updated 16+ files to sync `tburns` with `magi.offense.state.burns`.

### Critical Fixes (004_Magi_Offense.lua)
- **State table clobbered on reload**: Unconditional `state = {...}` wiped runtime state. Changed to merge pattern preserving existing values
- **Missing bal/eq guard in dispatch()**: Would fire selectSpell+sendAttack while off-balance/off-eq. Added GMCP vitals check
- **Water kill route non-functional**: `st.frozen`/`st.hypothermia` state flags were NEVER set by triggers. Replaced with V3 probability queries (`getAffProb("frozen") >= 0.5`)
- **Conflagrate missing air check**: Would attempt conflagrate without `r.air >= 2`, wasting rounds on failed casts

### Trigger Fixes
| File | Fix |
|------|-----|
| `020_Conflagrated_Fail.lua` | Regex typo `noavail` → `no avail` — trigger was NEVER firing |
| `025_Burns_Tracking.lua` | Firestorm pattern tracked self-damage, not target burns — removed incorrect increment |
| `023_Shalestorm.lua` | `erAff("shield")` incorrectly called on limb break (not shield break) — removed |
| `004_Earth_Emanation.lua` | Premature `tarAffed("calcifiedskull")` on emanation cast (process, not result) — removed |
| `001-004 Emanation triggers` | Added target validation (`matches[2] == target`) — prevented wrong-target tracking |
| `001-004 Emanation triggers` | Hardcoded "primordial staff" → flexible `an? \w+ staff` — works with any staff |
| `026_Calcify.lua` | Pattern mismatch with emanation ("elemental" vs "primordial") — made staff-agnostic |
| `002_Water_Emanation.lua` | Updated to use `magi.offense.ptRelay()`, added target validation |
| `003_Air_Emanation.lua` | Updated to use `magi.offense.ptRelay()`, added target validation |

### tburns Sync (16 files)
All trigger/script/alias files using old `tburns` global now sync with `magi.offense.state.burns`:
- Increment: `math.min(state.burns + N, 5)` + `tburns = state.burns`
- Decrement: `math.max(state.burns - 1, 0)` + `tburns = state.burns`
- Reset: `state.burns = 0; tburns = 0`
- Files: efreeti, fire second/third, firestorm tick/up, dehydrate, firelash, increase burning, fire staffcast, immolation, tree decrement, caloric decrement, RESET alias, login function, targeting functions

### Other Fixes
- `001_Resonance.lua`: Fixed event handler accumulation (`killAnonymousEventHandler` before re-register)

---

## 2026-03-10 — Psion Offense Modernization (psion namespace)

Complete rewrite of the Psion offense system. Replaced 720 lines of duplicated functions (`levipsionmind` defined 3 times) and 20+ global variables with a unified `psion` namespace following modern conventions (Shaman/Apostate/Serpent pattern). Added rebounding stripping logic (recent game change: Psion weaves now blocked by rebounding, but unweaves/deconstruct bypass it). Fixed multiple operator precedence bugs and a class-check logic error.

### Modified Files
| File | Changes |
|------|---------|
| `scripts/.../psion/001_Levi_Psion_Logic.lua` | Full rewrite: `psion` namespace with state/config, V3 affliction routing (`psion.hasAff()` → `haveAff()`), dispatch guards (target/aeon/balance/reboundHold), rebounding strip via cleave, `selectPrepare()`/`selectWeave()`/`selectTranscend()`/`buildAttack()`/`sendAttack()`, 2 modes (mind/flurry), combat echo, backward-compat shims (`levipsionmind()`/`levipsionflurry()`), tempAlias registration with reload cleanup |
| `aliases/.../152_First_Attack_(All_Classes).lua` | Added Psion branch → `psion.dispatch()` |

### Bug Fixes
- **Operator precedence**: `tAffs.impatience and not tAffs.stupidity or not tAffs.dizziness` evaluated incorrectly (Lua `and`/`or` precedence) — fixed with parentheses
- **Class check always true**: `~= "Priest" or ~= "Occultist" or ~= "Pariah"` is always true — changed to lookup table
- **Flurry invert gate**: `inverted == true and tAffs.unweavingspirit or tAffs.criticalspirit` triggered on criticalspirit regardless of inverted — fixed with parentheses
- **No weave fallback**: `psionweave[1]` could be nil causing errors — `selectWeave()` now always returns a string

### Rebounding Handling (New)
- Regular weave attacks (overhand, backhand, deathblow, sever, puncture) are blocked by rebounding
- Unweaves (mind/body/spirit) and Deconstruct bypass rebounding
- When rebounding detected + non-bypass weave needed → `weave cleave` strips rebounding (prepare aff still lands)
- Early fight: unweaves are prioritized anyway, so rebounding is bypassed for free

---

## 2026-03-10 — Unified Magi Offense System (magi.offense)

Complete rewrite of the Magi combat system. Consolidated 5 fragmented functions (MagiMain, MagiLock, MagiWaterFocus, MagiFireNew, MagiSalveFocus) across 2 old files into a single unified `magi.offense` namespace with 5 combat modes, full resonance budgeting, meteorite shield breaking, burns tracking, calcify tracking, shalestorm tracking, and V3 affliction integration. Based on reference systems from top Magi players (xMagi decision tree + Tabethys triggers).

### New Files
| File | Purpose |
|------|---------|
| `scripts/.../mage/004_Magi_Offense.lua` | Unified offense (~570 lines): dispatch, 13-priority decision tree, 5 modes, meteorite variants, vibration auto-management, backward-compat wrappers |
| `triggers/.../general/021_Spell_Outcomes.lua` | Spell success detection (magma, dehydrate, fulminate, bombard, firelash, mudslide) |
| `triggers/.../general/022_Resonance_Afflictions.lua` | 12 resonance passive effect triggers (air/earth/fire/water affs on target) |
| `triggers/.../general/023_Shalestorm.lua` | Shalestorm start/hit/shield/end with anti-illusion guard |
| `triggers/.../general/024_Meteorite.lua` | Meteorite shield-break variant detection (flaming/frozen/pure/no-wards) |
| `triggers/.../general/025_Burns_Tracking.lua` | Burns counter from efreeti/conflagrate/firestorm |
| `triggers/.../general/026_Calcify.lua` | Calcified torso/skull detection and fade tracking |
| `aliases/.../magi_things/006_Magi_Mode.lua` | `mm` mode-switch alias (fire/water/lock/salve/group/debug/vibes/reset) |

### Modified Files
| File | Changes |
|------|---------|
| `152_First_Attack_(All_Classes).lua` (zz) | Added Magi branch → `magi.offense.dispatch()` |
| `154_Group_(All_Classes).lua` (sr) | Added Magi branch → group mode dispatch |
| `enamation/001_Fire_Emanation.lua` | Updated burns tracking to use `magi.offense.state.burns` |
| `enamation/004_Earth_Emanation.lua` | Added `magi.offense.state.calcifiedSkull` sync |
| `general/019_Conflagrated.lua` | Synced with `magi.offense.state.conflagrated` and burns |
| `general/020_Conflagrated_Fail.lua` | Added state reset on conflagrate failure |

### Removed Files
| File | Reason |
|------|--------|
| `scripts/.../mage/002_Logic.lua` | Old MagiMain/MagiLock — replaced by 004 |
| `scripts/.../mage/003_Magi_Levi_Logic_2.lua` | Old MagiWaterFocus/MagiFireNew/MagiSalveFocus — replaced by 004 |

### Key Improvements
- **Meteorite shield breaking**: 4 variants (flaming/pure/frozen/erode) selected by resonance state
- **Resonance budgeting**: Never wastes capped resonance, always emanates at cap
- **Burns pipeline**: magma → scalded(20s timer) → burns counter → conflagrate → destroy
- **Glaciate pathway**: Dual-resonance gate (water>=2 AND air>=2) for freeze → hypothermia → glaciate
- **Calcify tracking**: Tracks calcified torso/skull state, adjusts emanation earth priority
- **V3 integration**: Uses `haveAff()`/`getAffProbabilityV3()` for confidence-based gating
- **5 modes**: fire, water, lock, salve, group (via `mm <mode>`)
- **Backward compat**: Old function name wrappers preserved

---

## 2026-03-10 — Remove legacy dispatch calls from master combat aliases

Cleaned all 5 master combat aliases (`zz`, `xx`, `cc`, `vv`, `sr`) by removing legacy bare-function dispatch calls. Only modern namespace-based systems remain.

**Removed legacy calls** (classes without modern systems): Dragon, Bard, Psion, Runie DWC, Infernal SnB, Infernal DWB, Infernal 2H, Magi, Pariah, plus Monk `lock_base_prios()`/`formswaplock()` and Apostate `apostate_group()` wrapper (replaced with direct `apostate.setMode("group"); apostate.dispatch()`).

**Modern systems retained**: Monk (tekura6/shikudo), Runie DWB (dwbRunie), Infernal DWC (infernalDWCVivisect/GroupLock), Depthswalker, Blademaster (bmd/bmdq/bmbs), Apostate, Serpent, Shaman.

| File | Changes |
|------|---------|
| `152_First_Attack_(All_Classes).lua` (zz) | Removed Dragon, Bard, Psion, Runie DWC, Infernal SnB (×2), Infernal DWB, Infernal 2H, Magi, Pariah |
| `155_Second_Attack_(All_Classes).lua` (xx) | Removed Bard, Runie DWC, Dragon, Magi, Infernal DWB, Infernal 2H, Infernal SnB, Psion, Pariah |
| `156_Third_Attack_(All_Classes).lua` (cc) | Removed Monk, Bard, Runie DWC, Infernal SnB, Infernal 2H, Magi, Infernal DWB, Infernal DWC legacy |
| `153_Fourth_Attack_(All_Classes).lua` (vv) | Removed Monk, Infernal DWB, Infernal SnB, Magi; replaced `apostate_group()` with modern dispatch |
| `154_Group_(All_Classes).lua` (sr) | Removed Runie DWC, Infernal DWB, Infernal SnB, Magi; cleaned BM legacy fallback |

---

## 2026-03-10 — Wire Infernal DWC group combat to `sr` alias

The `sr` (group combat) alias for Infernal DWC was calling the legacy `dwcpriosbasicinfernalgroup()`. Replaced with `infernalGroupLockAttack()` which provides full truelock offense with V3 tracking, hellforge exploit, class-aware lock afflictions, and rebounding/shield handling.

| File | Changes |
|------|---------|
| `aliases/.../154_Group_(All_Classes).lua` | Infernal DWC branch now calls `infernalGroupLockAttack()` instead of `dwcpriosbasicinfernalgroup()` |

---

## 2026-03-10 — Magi Group PvP: Transfix/Staffcast Coordination + Smart Stormhammer

### Transfix/Staffcast Coordination (Part A)
When playing Magi, automatically react to transfix events from any source:
- **Self transfix success** (`505_Transfixed.lua`): Auto-queues `staffcast horripilation at target`
- **Self transfix unblind** (`504_Transfix_Unblind.lua`): Auto-queues `cast transfix target` to retry
- **Third-party transfix** (`general/010_Third_Party_Transfix.lua`): New trigger, staffcasts current target
- **Third-party unblind** (`general/011_Third_Party_Transfix_Unblind.lua`): New trigger, re-transfixes named target
- **Party callouts** (`party_targetting/005_Party_Magi_Coordination.lua`): New trigger reacts to "Staffcast: X", "X: Transfixed", "X: Unblind" from any party member

All gated behind `gmcp.Char.Status.class == "Magi"` and use `queue addclearfull freestand`.

### Smart Stormhammer (Part B)
New `storm` alias for group combat stormhammer targeting:
- **Targeting script** (`mage/005_Stormhammer_Targeting.lua`): Picks up to 3 enemies from the **same city as current target** in the room
- **Storm alias** (`magi_things/005_Storm.lua`): `^storm$` → selects targets and fires `cast stormhammer at X and Y and Z`
- **Starburst tracking** (`general/012_Storm_Starburst.lua`): Marks targets that starburst as alive (don't replace)
- **Death replacement** (`general/013_Storm_Death_Replace.lua`): Auto-replaces dead targets with next available same-city enemy

**Files**: 2 edited, 7 new

---

## 2026-03-10 — Overhaul: Default SSC curing priorities

Comprehensive overhaul of default curing priorities sent to Achaea's server-side curing (SSC) system. Many afflictions had priorities set for dynamic swaps that were never implemented (e.g., stupidity at 18 "move to 9 if off focus balance"), leaving dangerous gaps in curing. Additionally, several combat-critical afflictions (peace, fear, confusion, recklessness, masochism) were at very low priority despite being highly impactful.

**23 priority changes** — all raising urgency except horror (8→10, less urgent than recklessness/masochism):

| Affliction | Old | New | Why |
|-----------|-----|-----|-----|
| peace | 16 | 2 | Cannot attack or defend |
| pacified | 14 | 3 | Prevents aggressive actions |
| paralysis | 4 | 3 | User priority: stay unparalyzed. Blocks tree. No bloodroot competition |
| impatience | 6 | 4 | Blocks focus. Hardlock component |
| prone | 9 | 5 | Enables kill combos |
| fear | 20 | 5 | Forces fleeing. Bal-free cure |
| disrupted | 9 | 5 | Blocks tree tattoo. Bal-free cure |
| clumsiness | 14 | 7 | 33% miss chance |
| voyria | 9 | 7 | Sip-cured, class lock aff |
| nausea | 11 | 8 | Blocks parry |
| stupidity | 18 | 8 | Focus fallback was absurdly low |
| epilepsy | 18 | 8 | Seizures lose balance |
| recklessness | 21 | 8 | 50% more damage taken |
| masochism | 21 | 8 | Ekanelia enabler |
| confusion | 20 | 8 | Blocks actions, ash-cured |
| dizziness | 23 | 9 | Vertigo synergy |
| vertigo | 16 | 9 | Falling damage |
| healthleech | 14 | 9 | Ticking damage |
| addiction | 11 | 9 | Riftlock enabler |
| horror | 8 | 10 | Less urgent than combat affs |
| paranoia | 17 | 10 | Blocks ally help |
| dementia | 17 | 10 | Random actions |
| shyness | 23 | 12 | Focus fallback was absurdly low |

**Priority 1 reserved**: No default priorities at 1 — slot is reserved for on-the-fly emergency swaps (paraAst, brSlick, astImp, WATER, hypoImp all boost to 1 dynamically). Old prio 1 affs (aeon, hypothermia, peace) moved to 2; old prio 2 affs (sleeping, slickness, pacified, paralysis) moved to 3.

**Code refactor**: Replaced duplicated hardcoded `send()` calls in `ataxia_resetOnLogin()` and `ataxia_resetPrios()` with a shared `ataxia_sendDefaultPrios()` helper that loops over the `ataxia_defaultCuringPrios()` table. This eliminates desync risk between the table and the SSC commands.

| File | Changes |
|------|---------|
| `scripts/.../ataxia/001_Default_Curing_Prios.lua` | Updated 23 priorities in `ataxia_defaultCuringPrios()`, refactored reset functions to use shared table-driven helper |

---

## 2026-03-10 — Perf: Basher attack hot-path optimization

The basher attack dispatch (`ataxiaBasher_attack()`) ran ~90 lines of deeply nested inline flee logic with recursive calls, redundant function invocations (stormhammer recomputed 3x, search_targets 3x, updateVitals redundantly), all executing every prompt when health was low. The clean danger-level system (`ataxiaBasher_dangerLevel()` / `ataxiaBasher_executeFlee()`) existed but was dead code — never wired into the attack path.

**Fix**: Replaced the entire inline flee/shield/threshold block with clean calls to the existing danger-level system. Removed redundant `ataxiaBasher_stormhammer()` call from `ataxiaBasher_assembleAttack()` (already called once per prompt cycle via dirty-flag in `ataxiaBasher_patterns()`). Eliminated recursive `ataxiaBasher_patterns()` call and redundant `search_targets()` / `ataxiagui_updateVitals()` calls from the attack path.

| File | Changes |
|------|---------|
| `scripts/.../basher/001_Bashing_Functions.lua` | Rewrote `ataxiaBasher_attack()` to use `ataxiaBasher_dangerLevel()` + `ataxiaBasher_executeFlee()`. Removed redundant `ataxiaBasher_stormhammer()` from `ataxiaBasher_assembleAttack()` |

---

## 2026-03-10 — Fix: Chat windows lose original MUD colors

Chat capture was stripping all ANSI escape sequences and applying a flat per-channel color (e.g., all "says" in cyan). This lost the MUD's original per-word coloring (player names, channel tags, speech text).

**Fix**: Replaced `stripAnsi()` + `cecho()` with Mudlet's built-in `ansi2decho()` + `decho()`, which converts ANSI escape codes to decho color format and preserves the original coloring from the server.

| File | Changes |
|------|---------|
| `scripts/.../update_windows/001_showChat.lua` | Removed `stripAnsi()`, `channelColors`, `getChannelColor()`. Use `ansi2decho()` + `decho()` for display |
| `scripts/.../gui_stuff/003_Chat_Capture_Things.lua` | Same changes for the ataxiagui chat system |

---

## 2026-03-10 — Fix: Death/starburst causes double death from basher spam

When dying during bashing, the basher would keep attacking on the next prompt — causing a second death immediately after starburst resurrection. Three root causes:

1. **No trigger for player's own starburst** — trigger 405 only matched when *your target* starburst, not when *you* starburst. The text "Your starburst tattoo flares as the world is momentarily tinted red" was completely unhandled.
2. **`ataxiaBasher_onDeath()` only paused** — set `ataxiaBasher.paused = true` but left `ataxiaBasher.enabled = true`, so the prompt handler still ran `search_targets()` and could dispatch attacks before the pause took effect.
3. **Auto bash rotation never cleared** — `autoBashRotation` stayed true after death, causing `basher_disengaged()` to auto-move to the next bashing area.

**Fix**: `ataxiaBasher_onDeath()` now fully disables the basher (`enabled = false`), clears all queues (`cq all`), kills all active timers (flee, stuck, anti-spam), turns off auto bash rotation, stops mapper movement, and after a 2s delay moves to `mmp.previousroom` (the room before where you died) to heal up safely.

| File | Changes |
|------|---------|
| `scripts/.../genrunning/001_Bashing_API.lua` | Rewrote `ataxiaBasher_onDeath()` — full disable instead of pause, clears rotation, kills timers, moves to safe room |
| `triggers/.../406_Own_Starburst.lua` | **New** — triggers on "Your starburst tattoo flares", calls `ataxiaBasher_onDeath()` |
| `triggers/.../407_Player_Slain.lua` | **New** — triggers on "You have been slain by", calls `ataxiaBasher_onDeath()` (fires before starburst line) |

---

## 2026-03-10 — Fix: Nil guard errors across prompt, display, and event systems

Fixed 7 runtime errors caused by nil field access during early login, blind state, or missing data. All fixes add proper nil guards with fallback defaults.

| File | Error | Fix |
|------|-------|-----|
| `scripts/.../misc_scripts/021_Auto_Update.lua` | `Auto_Update` called as nil — Mudlet `eventHandlers` expects global function matching script name | Added global `Auto_Update(event, ...)` dispatcher routing to `ataxia.updater.onDownloadDone`/`onDownloadError` |
| `scripts/.../defence/001_Pre_Apply.lua` | `slc.percentages` nil when SLC not initialized | Added `if not slc or not slc.percentages then return end` early guard |
| `scripts/.../012_Prompt_Substitution.lua` | `ataxia.vitals.hpp/mpp/epp/wpp` nil on early prompts | Added `local var = ataxia.vitals.xxx or 0` for all 8 colour functions (hcolour, mcolour, ecolour, wcolour, darkh, darkm, darke, darkw) |
| `scripts/.../windows/001_Limb_Counter_Window.lua` | `gmcp.IRE.Target` nil when no target | Added nil guard chain `gmcp.IRE and gmcp.IRE.Target and gmcp.IRE.Target.Info` |
| `scripts/.../windows/001_Limb_Counter_Window.lua` | `mymomentum` nil for non-DWB classes | Changed to `(mymomentum or 0)` |
| `scripts/.../update_stuff/003_ataxia_RoomContents_Update.lua` | `gmcp.Char.Items.Add` accessed during Remove event | Removed erroneous `gmcp.Char.Items.Add.location` check from Remove branch |
| `triggers/.../276_Limb_Prompt.lua` | `gmcp.Char.Vitals.charstats` nil + operator precedence bug | Added nil guard for charstats, fixed `and`/`or` parentheses, added `or 0` fallback |

---

## 2026-03-09 — Auto-Update System (`sysupdate`)

Added in-game auto-update system that checks for new versions on login and allows one-command updates. Uses Mudlet's async `downloadFile` + `sysDownloadDone` event pattern (same as the mapper), not fragile `tempTimer` delays.

**On login (5s after load):**
- Downloads `version.txt` from GitHub, compares against `ataxiaVersion`
- If newer version available: shows notification with "Type SYSUPDATE to update"
- If current: shows "up to date" confirmation

**`sysupdate` command:**
- Downloads latest `Levi_Ataxia.mpackage` from GitHub
- Uninstalls old package, installs new one, cleans up temp file

**Version bump workflow (for releases):**
1. Update `version.txt` with new version string
2. Update `muddler_project/mfile` `"version"` field
3. Build with muddler
4. Push to GitHub (mpackage + version.txt)

| File | Changes |
|------|---------|
| `version.txt` | **New** — Single-line version string (currently `4.1`) |
| `scripts/.../misc_scripts/021_Auto_Update.lua` | **New** — `ataxia.updater` namespace, version check + download + install logic |
| `aliases/.../levi_062424/201_Sysupdate.lua` | **New** — `^sysupdate$` alias |

---

## 2026-03-09 — ClassDetect: Default unsupported curingsets to "normal" + AntiPsion fix

**ClassDetect curingset validation**: Added a `validCuringsets` whitelist so classes that map to curingsets that don't exist in-game fall back to "normal" instead of sending invalid `curingset switch` commands. Also changed Runewarden mapping from "runewarden" to "knights".

**AntiPsion rewrite**: Fixed priority order — mind (≥2) checked first (was second), body (≥2) second, spirit+asthma third. Removed requirement for both body AND mind to be present simultaneously. Spirit no longer requires ≥2 check.

| File | Changes |
|------|---------|
| `scripts/.../class_detect/001_Class_Detect_Engine.lua` | Added `classDetect.validCuringsets` whitelist, validation in `switchCuringset()`, Runewarden → "knights" |
| `scripts/.../algedonic_defense_1.0/001_Anti_Priorities.lua` | Rewrote `Algedonic.AntiPsion()` with correct priority order |

---

## 2026-03-09 — Fix: DWB Runie lag when spamming ZZ + wrong queue command

Spamming `zz` on DWB Runewarden caused massive lag because the dispatch had no balance gate, no anti-spam timer, and sent 9+ commands per keypress. Additionally used `queue addclear freestand` instead of `queue addclearfull free`, causing queued commands to stack instead of replace.

**Root causes:**
1. No balance check before dispatch — sent attacks every keypress regardless of balance state
2. No anti-spam cooldown — unlike basher (0.3s timer) or serpent (balance gate)
3. `queue addclear` only clears the free queue, not all queues — spam stacked commands

**Fix:**
- Added GMCP balance gate at top of `dwbRunie.dispatch()` (`gmcp.Char.Vitals.bal ~= "1"`)
- Added 0.3s anti-spam cooldown timer in `dwbRunie.sendAttack()` (same pattern as basher)
- Changed `queue addclear freestand` → `queue addclearfull free` (same pattern as apostate)

| File | Changes |
|------|---------|
| `scripts/.../dwb_runie/001_DWB_Runie_Logic.lua` | Balance gate + anti-spam in `dispatch()`, queue command fix + cooldown timer in `sendAttack()` |

---

## 2026-03-09 — GUI: Increase SLC window default height

Increased the Self Limb Counter (SLC) GUI window default height by 20% (180 → 216) to fit more data. Existing windows need `zfix selfLimbDamageWindow` to pick up the new default.

| File | Changes |
|------|---------|
| `scripts/.../self_limb_tracking/002_Track_The_Damage.lua` | Default height 180 → 216 |

---

## 2026-03-09 — Fix: TK6 PREP breaks limb prematurely + wastes punches as jabs

During PREP phase, when only 1 unprepped limb remained and a kick would break it (e.g., RL at 84.5% + 18.3% kick = 102.8%), the kick fallback had no break guard and kicked it anyway. Both punches then fell back to generic `"jbp arms"` (wasted jabs to left shoulder) because the candidate pool only contained unprepped limbs.

**Root causes:**
1. Kick fallback (last resort) picked lowest-damage candidate with no break check
2. `allCandidates` only contained unprepped limbs — prepped-but-not-broken limbs were invisible to punch selection
3. Punch fallback used ambiguous `"jbp arms"` instead of explicit limb targeting

**Fix:**
- Expanded candidate pool: `unprepCandidates` (priority) + `overflowCandidates` (prepped-but-not-broken, safe overflow)
- `findSafeLimb()` now searches 4 passes: non-parried unprepped → parried unprepped → non-parried overflow → parried overflow
- When no kick target is safe, uses RHK (roundhouse kick) as filler — does no limb damage
- Punch fallback uses `jbp` filler (no limb damage) instead of ambiguous `"jbp arms"` that targeted random limbs
- JBP filler always ordered first in combo (slot 1) — disables parry for the following real punch in slot 2

| File | Changes |
|------|---------|
| `scripts/.../tekura/002_Tekura_6Limb_Offense.lua` | Rewrote `buildPrepAttack()`: dual candidate pools, RHK filler kick, explicit punch targeting |

---

## 2026-03-09 — Fix: Tekura basher attacks fail when wielding weapons

Tekura combos (`sdk ucp ucp` / `rhk ucp ucp`) require empty hands. Added `unwield all` before all 3 tekura attack paths in the Monk basher (shielded+rageraze, shielded+no-rageraze, normal).

| File | Changes |
|------|---------|
| `scripts/.../basher/002_Class_Bashing.lua` | Prepended `unwield all` (via separator) before all 3 tekura `combo` commands |

---

## 2026-03-09 — Fix: Hunting Scrolls `<ansiMagenta>` rendered as literal text

`ansiMagenta` is not a valid `cecho`/`cechoLink` color name — it's an `hecho` format. All 30+ occurrences in the Hunting Scrolls display were rendering as literal `<ansiMagenta>` text instead of magenta color.

| File | Changes |
|------|---------|
| `scripts/.../zdata/001_Experience_Database.lua` | Replaced all `ansiMagenta` with `magenta` (both variable assignments and inline cecho tags) |

---

## 2026-03-09 — Feature: Players in Area (Mindnet) display in tarc window

When Monk/BM has mindnet defense active, the game fires enter/leave messages for players in the area. The mindnet trigger now maintains a persistent `ataxia.playersInArea` list and displays it in the tarc bashing window with NDB city-based coloring. List clears automatically on area change.

| File | Changes |
|------|---------|
| `triggers/.../telepathy/001_Mindnet.lua` | Added enter/leave tracking to populate `ataxia.playersInArea`, refresh tarc on update |
| `scripts/.../update_stuff/002_ataxia_Room_Update.lua` | Clear `ataxia.playersInArea` on area change via `ataxia._lastMindnetArea` |
| `scripts/.../windows/001_Limb_Counter_Window.lua` | Added "Players in Area:" display section (magenta header, NDB coloring) |

---

## 2026-03-08 — Fix: Stale tAffs reads across offense systems

Multiple offense scripts read `tAffs.<aff>` directly instead of `haveAff("<aff>")`. After V3 correctly cured afflictions, the stale `tAffs` cache could retain `true` values (intermediate 1-30% probability range not cleared by `syncToOldSystemV3()`), causing wrong strategy decisions and incorrect displays.

| File | Changes |
|------|---------|
| `serpent/002_Serpent_Offense.lua` | Replaced all 8 `tAffs.darkshade` with `haveAff("darkshade")` |
| `apostate/015_CC_Apostate.lua` | Replaced `tAffs.dementia`/`tAffs.hypersomnia` with `haveAff()` (nightmare aff tracking) |
| `bard/001_LeviBard.lua` | Replaced 14 bare `tAffs.<aff>` with `haveAff()` (paralysis, asthma, slickness, lethargy, sensitivity, dizziness, addiction). Fixed 2 shield/rebounding checks to use V1 fallback pattern |

---

## 2026-03-08 — Fix: table.load wiping runtime functions and state

`table.load(file_loc, ataxia)` in `ataxia_loadSettings()` replaced the entire `ataxia` table contents on `sysLoadEvent`, destroying runtime sub-tables with functions that were initialized by scripts before the load event. This caused `ataxia.data.db.addChar` (nil), `ataxia.data.movement` (nil), and `ataxiaBasher.ldeckRules` (nil) errors on every prompt/trigger fire.

**Root cause**: `table.save` can't serialize functions. When `table.load` replaces a sub-table, the saved version has data but no functions — wiping `ataxia.data.movement()`, `ataxia.data.db.addChar()`, etc.

**Fix**: Replaced `table.load(path, ataxia)` with a `mergeLoad()` helper that loads into a temp table and merges keys into the existing table, preserving sub-tables that contain runtime functions. Same pattern applied to `ataxiaBasher` load. Added nil guards to `ataxiaBasher_countMobsInRoom()` and `ataxiaBasher_preCombatLdeck()`.

| File | Changes |
|------|---------|
| `ataxia/001_Save_Load_Settings.lua` | Added `mergeLoad()` helper; use it for `ataxia` and `ataxiaBasher` loads |
| `genrunning/002_search_targets.lua` | Nil guard on `ataxia.denizensHere` in `countMobsInRoom()`, nil guard on `ldeckRules` in `preCombatLdeck()` |

---

## 2026-03-08 — Feature: Profile Backup for All Saved Data

Added redundant profile backup alongside existing disk saves. Every save now copies data into a `_ataxia_backup` global table (Mudlet saved variable), providing a fallback if disk files are lost or corrupted. On load, if a disk file is missing, the system automatically restores from the profile backup.

**Backup keys**: `ataxia`, `basher`, `basherpaths`, `ndb`, `extraction`, `slcconfig`, `shaman`, `legenddeck`, `legenddeck_config`, `classDetect`, `gearaudit`, `bars_config`

| File | Changes |
|------|---------|
| `ataxia/001_Save_Load_Settings.lua` | Save: backup 6 datasets to `_ataxia_backup`. Load: fallback from backup for all 6 |
| `shaman_system/002_Save_Load_functions.lua` | Save: backup shaman config. Load: fallback |
| `legend_deck/004_Legend_Deck_Save_Load.lua` | Save: backup deck + config. Load: fallback |
| `class_detect/001_Class_Detect_Engine.lua` | Save: backup classDetect data. Load: fallback |
| `gear_system/001_Gear_Audit.lua` | Save: backup gear data. Load: fallback |
| `build_windows/016_buildVitalBars.lua` | Save: backup bars config. Load: fallback |

**Setup**: Add `_ataxia_backup` as a saved variable in Mudlet's Variables panel (one-time, type: table).

---

## 2026-03-08 — Fix: ataxiaNDB API crash with numeric target (bashing)

Fixed crash in `ataxiaNDB_Exists()` when `target` is a numeric GMCP NPC ID (during bashing). The Prompt Trigger calls `ataxiaNDB_getClass(target)` every prompt, which called `name:title()` on a number. Added type guard `type(name) ~= "string"` in `ataxiaNDB_Exists()` — protects all 50+ NDB API callers across the codebase.

| File | Fix |
|------|-----|
| `ataxia_ndb/003_ataxiaNDB_API.lua` | `ataxiaNDB_Exists()`: reject non-string `name` values (returns `false`) |

---

## 2026-03-08 — User-Facing Command Rename: `levi` → `ataxia`

Renamed all user-facing aliases from `levi` prefix to `ataxia` prefix for consistency with the system name. Internal Lua namespace (`leviSetup`) is unchanged.

| Old Command | New Command |
|-------------|-------------|
| `levi setup` | `ataxia setup` |
| `levi setup class` | `ataxia setup class` |
| `levi setup basher` | `ataxia setup basher` |
| `levi setup sipping` | `ataxia setup sipping` |
| *(all other `levi setup` subcommands)* | *(same with `ataxia setup` prefix)* |
| `levibars` | `ataxiabars` |

Header text in setup wizard changed from "LEVI Setup Wizard" to "Ataxia Setup Wizard".

---

## 2026-03-08 — Nil Guard for `ataxiaBasher.targetList` (F1 Autobash Crash)

Fixed a crash when pressing F1 (autobash) before basher settings were loaded. `search_targets()` accessed `ataxiaBasher.targetList[area]` without checking if `targetList` was initialized, causing a nil index error.

| File | Issue | Fix |
|------|-------|-----|
| `genrunning/002_search_targets.lua` | `ataxiaBasher.targetList` nil before basher settings loaded | Added nil guard: early return if `targetList` is nil |

---

## 2026-03-08 — Nil Guard Fixes for Blind/Startup State

Fixed 8 runtime errors that occurred when logging in blind (no `gmcp.Room` data) or during early connection (incomplete GMCP state).

| File | Issue | Fix |
|------|-------|-----|
| `defence/001_Pre_Apply.lua` | `gmcp.Room.Info.exits` nil when blind | Early return guard |
| `318_Prompt_Trigger.lua` | `ataxiaTables.limbData` nil before init | Wrapped in nil check |
| `016_Targeting_Functions.lua` | `ataxiaTemp.enemies` nil, `ataxia.playersHere` non-table | Default to `{}`, type check |
| `012_Prompt_Substitution.lua` | `ataxiaTemp.mobhealth` nil comparison | Added nil check before `~= 0` |
| `003_ataxia_RoomContents_Update.lua` | `gmcp.Char.Items.List` nil during early connect | Early return guard |
| `006_showAffs.lua` | `target` nil before `:title()` | Added nil check |
| `008_showRoomInfo.lua` | `gmcp.Room.Info` nil when blind | Early return guard |
| `352_Room_Info_Shortener.lua` | `gmcp.Room.Info` nil when blind | Early return guard (already deactivated) |

---

## 2026-03-08 — V3 Affliction Tracker Migration: Single Source of Truth

**Major architecture change**: Migrated from three parallel affliction tracking systems (V1 boolean, V2 certainty, V3 probability) to **V3-only**. The branching probability engine is now the single source of truth, with `tAffs` maintained as a synchronized read cache for backward compatibility.

### Core Changes

**007_Branching_State_Tracker.lua** (V3 engine):
- Set `affConfigV3.enabled = true` permanently
- Removed all toggle guards (`if not affConfigV3.enabled then return end`) from every function
- Removed all `raiseEvent` calls from `applyAffV3()` and `removeAffV3()` — events now owned by public API
- Removed circular `"tar afflicted"` event listener that re-applied affs from V1→V3
- Removed V2 sync block from `syncToOldSystemV3()`
- Removed V2 display delegation from `updateAffDisplayV3()`

**017_Affliction_Management.lua** (public API):
- `haveAff()` now routes to `haveAffV3()` first, with `tAffs` fallback during load order
- `erAff()` now calls `removeAffV3()` internally
- `tarAffed()` now calls `applyAffV3()` internally for each affliction
- All helper functions (`tarSingleAff`, `tarDoubleAff`, `tarTripleAff`, `addAffList`, `tarBonusAff`, `tarZealHit`) updated to call `applyAffV3()`

**008_V3_Integration.lua** (integration layer):
- Simplified all wrapper functions (`targetAteWrapper`, `tarAffedWrapper`, `erAffWrapper`, `haveAffWrapper`) — now thin delegates to public API
- Removed all toggle guards from 14 verification handlers
- Added `treeCurableAffsV3` and `focusCurableAffsV3` cure lists (migrated from V2)
- Added 19 V2 backward-compatibility stubs routing to V3 (`addAffV2`, `removeAffV2`, `haveAffV2`, `targetAteV2`, `onBloodrootApplyConfirmV2`, etc.)
- Removed `enableV3()`, `disableV3()`, `toggleV3()` — replaced with no-op stubs
- `isV3Active()` now always returns `true`

### V2 Deactivation
Set `isActive: 'no'` on 6 V2 files:
- `001_Core.lua`, `002_Herb_Cures.lua`, `003_Backtracking.lua`, `004_Verification.lua`, `005_buildTarAffsV2.lua`, `006_showAffsV2.lua`

### Reset Site Coverage
Added `if resetStatesV3 then resetStatesV3() end` to all 8 `tAffs` reset locations:
- `016_Targeting_Functions.lua`, `001_Login_Function.lua`, `003_TargetOutOfRoom.lua`, `016_RESET.lua`, `011_Reset_Afflictions_on_Target.lua`, `401_Target_Has_Died.lua`, `405_Starburst!.lua`, `010_Phoenix_(BM).lua`

### Offense System Simplification
Simplified 5 class-specific `hasAff()` wrappers to `return haveAff(aff)`:
- `apostate.hasAff()`, `blademaster.hasAff()`, `infernalDWC.hasAff()`, `infernalDWC2L.hasAff()`, `depthswalker.hasAff()`

### Event Architecture
- Events (`"tar afflicted"`, `"target cured aff"`) now fire exclusively from public API (`tarAffed()`, `erAff()`)
- V3 internal functions (`applyAffV3`, `removeAffV3`) no longer raise events — prevents double-firing

### Bug Fixes
- **447_Inundate.lua**: Was bypassing V3 by setting `tAffs` directly. Now calls `tarAffed()` for proper V3 tracking
- **442_Got_Sileris.lua**: Fixed pre-existing typo `"fanbarrier"` → `"fangbarrier"`
- **008_V3_Integration.lua**: Added missing `onBloodrootApplyConfirmV2()` stub

---

## 2026-03-07 — Tekura: Modernize offense with BM/DWC/DWB patterns + fix 6-limb KILL phase

**Improvements applied to both Tekura systems** (001_Tekura_Offense.lua, 002_Tekura_6Limb_Offense.lua):

1. **V3→V2→V1 affliction routing** — `tekura.hasAff()` / `tekura6.hasAff()` replaces raw `tAffs` access. Works with V3 probability, V2 certainty, or V1 boolean tracking.
2. **`wouldBreakLimb()` guard** — Prevents accidental limb breaks during PREP by treating near-break limbs as prepped (DWC pattern).
3. **`attackInFlight` flag** — Anti-desync: prevents `envenomList`-style state corruption while off-balance (DWC pattern).
4. **Target-change auto-reset** — Parry tracking and state automatically cleared when switching targets (DWB pattern).
5. **Echo debounce** — 0.3s guard prevents spam when rapidly pressing attack key (DWB pattern).
6. **Rebounding handling** — New `checkRebounding()` with V1 fallback for GMCP timing gap. Razes rebounding before attacking.
7. **Shield V1 fallback** — `checkShield()` now uses V1 fallback pattern for reliability.
8. **Aeon guard** — Dispatch skipped when under aeon effect.
9. **Centralized `sendAttack()`** — Lock-break check + target presence check before sending (BM pattern).

**Bug fix (both systems)**: KILL phase now uses Bear stance + prone instead of limb damage checks. Bear stance means we already completed the break phases (`;brs` switches to Bear). Previously the 6-limb system required ALL 6 limbs broken (impossible — head never explicitly broken in attack flow), and the 4-limb system checked leg damage that could be cured by the time balance returned. Now: `ataxia.vitals.stance == "Bear" and prone → BBT`.

**Files modified**:
- `src_new/scripts/.../tekura/001_Tekura_Offense.lua` — All 9 improvements
- `src_new/scripts/.../tekura/002_Tekura_6Limb_Offense.lua` — All 9 improvements + KILL phase fix

---

## 2026-03-07 — Monk: Fix Tekura/Shikudo spec detection in zz/xx aliases

**Problem**: Pressing `zz` as a Tekura Monk called `shikudo.dispatch()` unconditionally — wielding a staff and showing `[Shikudo:DISPATCH]` instead of Tekura combat. The `xx` alias had the inverse problem (always called `tekura.dispatch.run()`).

**Fix**: Both aliases now check `ataxia.vitals.stance` (populated from GMCP charstats when Tekura is active). If stance is truthy → Tekura dispatch; otherwise → Shikudo dispatch.

**Files modified**:
- `src_new/aliases/.../152_First_Attack_(All_Classes).lua` — Monk branch: added spec detection
- `src_new/aliases/.../155_Second_Attack_(All_Classes).lua` — Monk branch: added spec detection

---

## 2026-03-07 — Fix literal `<ansi_*>` tags printed as text in cecho() calls

**Problem**: Multiple scripts used `<ansi_yellow>` and `<ansi_light_cyan>` color tags in `cecho()` calls. These rendered as literal text instead of colors (e.g., `<ansi_light_cyan>[Levi]:` in startup, `<ansi_yellow>(44.4%)` in limb damage).

**Fix**: Replaced all `<ansi_*>` tags with standard Mudlet color names: `<ansi_yellow>` → `<yellow>`, `<ansi_light_cyan>` → `<light_cyan>`.

**Files modified** (6 total):
- `src_new/scripts/.../limb/002_limb_management.lua` — limb damage percentage echo
- `src_new/scripts/.../affliction_tracking_core/004_Verification.lua` — softlock echo
- `src_new/scripts/.../affliction_tracking_core/008_V3_Integration.lua` — softlock echo
- `src_new/scripts/.../totem/001_Totem_Checker.lua` — totemChecker.echo()
- `src_new/scripts/.../snipe/001_Snipe_System.lua` — snipe.echo()
- `src_new/scripts/_groups.yaml` — Algedonic.Echo() inline script

---

## 2026-03-07 — Apostate: Fix mental mode impatience loop

**Problem**: Mental mode sent `impatience + paralysis` every round forever. `selectPrimaryCurseMental()` required impatience at 100% V3 probability (`< 1.0`) before advancing to stupidity/dizziness/epilepsy. But the target cures impatience with goldenseal each round, so it never reaches 100%. The goldenseal flood (the whole point of mental mode) never happens.

**Fix**: Changed impatience delivery threshold from 100% to 25% in both primary and secondary mental selectors. Now all mentals use the same 25% "deliver once, move on" threshold. The 100% impatience requirement remains in `mentalReady()` — it gates the *transition to lock*, not delivery.

**Priority reorder**: Removed clumsiness from mental stack. Replaced epilepsy with vertigo (lobelia-cured). New order: impatience → stupidity → dizziness → vertigo. Transition: impatience(100%) + 2 of {stupidity, dizziness, vertigo}.

**Files modified**:
- `src_new/scripts/.../apostate/015_CC_Apostate.lua` — Mental selectors: impatience threshold 1.0 → 0.25, removed clumsy, epilepsy → vertigo

---

## 2026-03-07 — Apostate: Fix anorexia not selected when c1=sicken

**Problem**: `selectSecondaryCurse("sicken")` skipped anorexia because it was gated behind `apostate.hasAff("slickness")`, which returned false. When c1=sicken, slickness will be delivered by that same curse round — but the gate didn't account for this. Result: plague selected instead of anorexia.

**Fix**: Added `or c1 == "sicken"` to the anorexia gate, so anorexia is selectable when sicken (slickness delivery) is the primary curse.

**Files modified**:
- `src_new/scripts/.../apostate/015_CC_Apostate.lua` — line 341: anorexia gate now checks `c1 == "sicken"`

---

## 2026-03-07 — Apostate: Merge 014 into 015, mental mode updates

**Merge**: Deleted `014_Levi_Apostate.lua` — all backward-compat wrappers, daemon utilities (`bloodworm`, `baalzadeen`, `demon`, `apopentagram`, `bloodPact`, `daemonite`, `fiend`), legacy wrappers (`corruptDmg`, `corruptKill`, `cathCorrupt`), and `nightmare()` tracking moved into `015_CC_Apostate.lua`.

**Mental mode updates**: Priority reordered to clumsiness → impatience → stupidity → dizziness → epilepsy. Clumsiness first for 33% miss hinder. Thresholds changed from 33% to 25% for mentals (impatience stays 100%). Both primary and secondary selectors updated.

**Alias**: `xx` now sets apostate to mental mode (was corrupt). `men` still activates mental mode.

**Files modified**:
- `src_new/scripts/.../apostate/015_CC_Apostate.lua` — Absorbed all 014 content; mental mode reordered + thresholds adjusted
- `src_new/scripts/.../apostate/014_Levi_Apostate.lua` — Deleted
- `src_new/aliases/.../155_Second_Attack_(All_Classes).lua` — Apostate block: corrupt → mental

---

## 2026-03-07 — Fix: Chat channel colors not applied in miniconsoles

**Problem**: Most chat channel colors (tells=yellow, says=cyan, clan=white, etc.) appeared as white/default in the GUI chat miniconsoles. Only channels with exact GMCP name matches (like `"shout"`) showed their configured color.

**Root cause**: The color lookup used exact key match (`channelColors[gmcp.Comm.Channel.Start]`), but Achaea's GMCP channel names include suffixes — e.g., `"tells Proficy"` for tells, `"clt Holocaust Inc"` for clans. The exact lookup for `"tells Proficy"` against key `"tell"` returned nil → fell back to `"<white>"`. Window routing already worked because it used `string.starts()` prefix matching.

**Fix**: Added `getChannelColor(ch)` helper that iterates `channelColors` with `string.starts()` prefix matching, replacing the exact key lookup. Applied to both chat display files.

**Files modified**:
- `scripts/.../update_windows/001_showChat.lua` — Added `getChannelColor()`, replaced exact lookup
- `scripts/.../gui_stuff/003_Chat_Capture_Things.lua` — Added `getChannelColor()`, replaced exact lookup

**Shout color**: Changed from red → teal (`<teal>`) in both files.

---

## 2026-03-07 — ClassDetect: Shikudo differentiation + defence priority re-application

**Problem 1**: ClassDetect treated all monks as "Monk", switching to the `monk` curingset even for Shikudo (staff) monks who need the `shikudo` curingset.

**Fix**: The Monk Class Grab trigger now inspects the matched line text for weapon keywords (`whips`, `staff`, `thrust`, `kata`, `sweeps`) to distinguish Shikudo from Tekura. Added `["Shikudo"] = "shikudo"` to `curingsetMap`. Updated anti-Shikudo parry check to accept `attackerClass == "Shikudo"` directly.

**Problem 2**: After switching curingsets, SSC re-applied the curingset's own defence priority list, which may include abilities the player doesn't have (e.g., toughness, shin for a non-BM). This caused "I don't know what X does" spam.

**Fix**: Added `classDetect.reapplyDefencePriorities()` — after every curingset switch, sends `curing priority defence list reset` to wipe the curingset's embedded list, then re-sends the player's own defence profile from `ataxia.settings.defences.defup[current]` using `curing priority defence ... 25`, matching the pattern in `systemDefup()`.

**Problem 3**: Shikudo monks also use kicks (no weapon keywords), causing ClassDetect to flip-flop between "Shikudo" and "Monk" on alternating attack lines. This triggered repeated curingset switches.

**Fix**: Trigger action now checks if the attacker is already identified as Shikudo — if so, kick-only lines just reset the combat timeout instead of downgrading to "Monk".

**Problem 4**: The `362_Shikudo_Bashing_Error` trigger had an overly broad regex (`^I'm sorry, I don't know what "(\w+)" does\.$`) that matched ALL unknown ability errors, not just livestrike. The defence priority spam ("toughness", "shin", "weathering") triggered this, calling `ataxiaBasher_attack()` when the basher wasn't initialized, causing nil errors on `ataxiaBasher.noShieldBreak` and `ataxiaBasher.targetList`.

**Fix**: Removed the broad regex pattern — trigger now only matches the specific livestrike error messages it was designed for.

**Files modified**:
- `triggers/.../determine_class/006_Monk_Class_Grab.lua` — Shikudo vs Tekura keyword detection + no-downgrade guard
- `scripts/.../class_detect/001_Class_Detect_Engine.lua` — Added `["Shikudo"]` to curingsetMap, added `reapplyDefencePriorities()` with defence list reset, called from `switchCuringset()`
- `scripts/.../self_limb_tracking/003_Parrying.lua` — Updated `isShikudo` check to accept `attackerClass == "Shikudo"` directly
- `triggers/.../362_Shikudo_Bashing_Error.lua` — Removed overly broad regex pattern, kept only specific livestrike patterns

---

## 2026-03-07 — Fix: GMCP nil errors when blind

**Problem**: When the player is blind, the server stops sending `gmcp.Room` data (and sometimes `gmcp.Char`), causing `gmcp.Room` to be `nil`. Five triggers accessed `gmcp.Room.Info.*` and `gmcp.Char.*` without nil guards, producing a flood of errors on every prompt line.

**Root cause**: Lua pattern conditions (type 4) in map-switching triggers and inline code in prompt triggers indexed into `gmcp.Room.Info` and `gmcp.Char.Status` directly, with no nil check for the parent tables.

**Fix**: Added nil guards (`gmcp.Room and gmcp.Room.Info and ...`) to all unprotected GMCP accesses. When blind, these triggers now silently skip instead of erroring.

**Files modified**:
- `triggers/.../wilderness_map/002_GMCP_Rooms.lua` — Nil guard on pattern conditions (`gmcp.Room.Info.num`)
- `triggers/.../wilderness_map/003_GMCP_Wilderness.lua` — Nil guard on pattern conditions (`gmcp.Room.Info.num`, `.coords`)
- `triggers/.../wilderness_map/004_GMCP_Oceans.lua` — Nil guard on pattern conditions (`gmcp.Room.Info.environment`, `.num`)
- `triggers/.../leviticus/318_Prompt_Trigger.lua` — Nil guard on `gmcp.Char.Status.class` (BM/Monk/Magi checks) and `gmcp.Room.Info.name` (flying check)
- `triggers/.../leviticus/276_Limb_Prompt.lua` — Nil guard on `gmcp.Char.Status.class` and `gmcp.Char.Vitals.charstats` (DWB momentum check)

---

## 2026-03-07 — Configurable movable vital bars (`levibars`)

**New feature**: Individually movable, configurable gauge bars for Health, Mana, Willpower, Endurance, and Cape (shoulder cape kill tracker). Each bar is an `Adjustable.Container` with auto-save/load positions.

**Files created**:
- `build_windows/016_buildVitalBars.lua` — Full `ataxia.bars` namespace: build, show/hide, toggle, reset, update, config save/load
- `aliases/zgui_redux/007_(LEVIBARS)_Vital_Bars.lua` — `^levibars(?: (.+))?$` alias

**Files modified**:
- `gui_stuff/004_Vitals_Related.lua` — Added `ataxia.bars.update()` call in `ataxiagui_updateVitals()`
- `update_windows/007_showCape.lua` — Added `ataxia.bars.updateCape()` calls in `zgui.showCape()` and `zgui.clearCape()`
- `039_EDIT_ME__Startup_Main.lua` — Added `ataxia.bars.buildAll()` call after module dispatch

**Usage**: `levibars` (status), `levibars on/off` (master toggle), `levibars health/mana/willpower/endurance/cape` (individual toggle), `levibars reset` (reset positions). Default: health+mana+cape on, willpower+endurance off, master disabled.

---

## 2026-03-07 — Fix: Chat window shows raw ANSI codes

**Problem**: Chat miniconsoles displayed raw ANSI escape sequences as visible text (e.g., `[0;37m`, `[0;1;36m`) because GMCP text contains embedded ANSI codes that `cecho()` doesn't interpret.

**Fix**: Added `stripAnsi()` helper to strip ANSI escape sequences before passing text to `cecho()`. Applied in both chat display paths.

**Files modified**:
- `update_windows/001_showChat.lua` — Added `stripAnsi()`, applied to GMCP text
- `gui_stuff/003_Chat_Capture_Things.lua` — Same fix
- Both files: removed duplicate YAML headers

---

## 2026-03-07 — Fix: `an refresh` and auto-honours now capture mark/army/dauntless

**Problem**: Both `an refresh` and the hidden-city auto-honours used `send("honours", false)` which bypasses the Mudlet alias system. The NDB capture triggers (`Get Player Information`, `Check Player City`) were never enabled, so mark, army rank, and dauntless data was silently lost during bulk honours.

**Fix**: Rewrote both systems to use `ataxiaNDB_processRefreshQueue()` — a sequential queue processor that properly sets `_honoursPerson`, enables capture triggers, sends `honours`, and chains to the next player after Close Capturing completes. Includes 8s safety timeout per player.

**Files modified**:
- `006_ataxiaNDB_Success.lua` — Added `ataxiaNDB_processRefreshQueue()` and `ataxiaNDB_onHonoursCaptureComplete()`. Rewrote `ataxiaNDB_drainHonoursQueue()` to use the new queue mechanism.
- `002_Close_Capturing.lua` (trigger) — Added call to `ataxiaNDB_onHonoursCaptureComplete()` to advance the refresh queue after each capture.

---

## 2026-03-07 — NDB: Auto-honours hidden-city players + `an refresh` command

**Files**: `006_ataxiaNDB_Success.lua`, `198_Refresh_Honours.lua` (new)

**Feature 1 — Auto-honours hidden cities**: When the API returns `(hidden)` for a player's city and no prior city is known, the system now queues an automatic `honours` lookup instead of showing a warning. Hidden-city names are collected during the API batch and drained with 2s spacing after the batch completes.

**Feature 2 — `an refresh [city]`**: New alias to send `honours` for all tracked players (or filtered by city) to update mark, army rank, and dauntless status — data only available from in-game `honours`, not from the API. Uses sequential honours capture with proper trigger setup.

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
- `src_new/scripts/.../apostate/015_CC_Apostate.lua` — Moved disfigure from manaleech round to asthma round (probes whether target smokes before committing manaleech). Removed `gmcp.Char.Vitals.bal == "1"` guard that prevented disfigure from firing when dispatch was called from reboundHold callback. **Fixed orphaned disfigure**: `queue add free` approach failed because deadeyes ends up in Achaea's auto-queue (not the manual freestand queue), which fires first on balance return and consumes balance — the `free` queue's disfigure then waits for the NEXT balance return and fires alone. Fix: replaced with a one-shot `tempTrigger("curse of asthma", ...)` that sends disfigure when deadeyes text appears in the same server output batch. Trigger cleanup on mode change, target change, and non-asthma rounds.
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
