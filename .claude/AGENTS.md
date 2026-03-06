# Agent Instructions for LEVI-Achaea Combat System

This file contains critical instructions for AI agents working on the combat system.

---

## Before Coding Offensive Systems

**You MUST read these files first:**

1. **[classes/lock_types.md](classes/lock_types.md)** - All lock type definitions
   - Softlock, Venomlock, Truelock/Hardlock
   - Focuslock (mental affliction stacking)
   - Riftlock, Salvelock (limb-based)
   - Sleeplock, Aeonlock (timing/control-based)

2. **[classes/<target_class>.md](classes/)** - Class-specific kill routes
   - Kill route prerequisites and steps
   - Gating requirements for key afflictions
   - Class-specific lock affliction

3. **[classes/README.md](classes/README.md)** - Affliction stacking by herb
   - Which afflictions share cure balances
   - Class-specific lock affliction table

---

## Lock Types Quick Reference

| Lock | Afflictions | Escape |
|------|-------------|--------|
| **Softlock** | asthma + anorexia + slickness | Focus → eat bloodroot → eat kelp |
| **Venomlock** | + paralysis | Focus → eat bloodroot |
| **Truelock** | + impatience + class aff | None without help |
| **Focuslock** | mental aff stacking | Hope Focus cures anorexia |
| **Riftlock** | 2 broken arms + slick + asthma | Smoke valerian → mend → rift |
| **Aeonlock** | aeon + asthma + kelp stack | Must cure asthma first |

---

## Combat Systems Quick Reference

### Implemented Offense Systems

| System | Namespace | Dispatch | Key File(s) |
|--------|-----------|----------|-------------|
| **Serpent** | `serp_*` globals | `ek` → `serp_ekanelia_offense()` | `serpent/002_Serpent_Offense.lua` |
| **Shaman** | `shamanOffense` | `zz`/`sr` → `shamanOffense.dispatch()` | `shaman/028_Shaman_Offense.lua` |
| **DWC Infernal** | `infernalDWC` | `zz` → `infernalDWCVivisect()` | `dwc/001_Infernal_DWC_Vivisect.lua` |
| **Blademaster** | `blademaster` | `bmd`/`bmdq`/`bmbs` → `blademaster.run()` | `blademaster/005_CC_BM_Ice.lua` |
| **Apostate** | `apostate` | `ll`/`corr` → `apostate.dispatch()` | `apostate/015_CC_Apostate.lua` |
| **Shikudo V1** | `shikudo` | `shikudo.dispatch()` | `shikudo/001_Shikudo.lua` |
| **Shikudo V2** | `shikudov2` | `shikudov2.dispatch()` | `shikudo/002_Shikudo_R2.lua` |
| **Shikudo Lock** | `shikudoLock` | `shikudolock()` | `shikudo/007_CC_Shikudo_Lock.lua` |
| **DWB Runie** | `dwbRunie` | `dwbRunie.dispatch()` | `dwb_runie/001_DWB_Runie_Logic.lua` |
| **Snipe** | `snipe` | `snt` → `snipe.fire()` | `snipe/001_Snipe_System.lua` |

All script paths are relative to `src_new/scripts/levi_ataxia/levi/levi_scripts/`.

### Utility Systems

| System | Namespace | Dispatch | Key File |
|--------|-----------|----------|----------|
| **Basher** | `ataxiaBasher` | Prompt-driven | `ataxia/genrunning/004_Autobashing_Functions.lua` |
| **Setup Wizard** | `leviSetup` | `levi setup <cmd>` | `ataxia/misc_scripts/020_Setup_Wizard.lua` |

---

## Serpent Offense System

**Full details**: See memory file `serpent.md`

**Key files**:
- `serpent/002_Serpent_Offense.lua` — Unified V3-aware offense
- `triggers/.../serpent/` — Hit triggers (010, 016, 017, 018)

**Dispatch**: `ek` alias → `serp_ekanelia_offense()` → `serp_ekanelia_attack()` → `serp_sendAttack()`

**Modes**:
| Mode | Alias | Strategy |
|------|-------|----------|
| lock | `eklock` | Relapse-based locking (4 phases: SETUP → RELAPSE → REINFORCE → FINISH) |
| hypnolock | `ekhl` | Hypnosis EQ chain + DSTAB → auto-switch to lock |
| hypnosis | `ekhyp` | Fratricide via hypnosis |
| group | `ekgroup` | Reactive gap-filling for group combat |
| darkshade | `ekdark` | Darkshade + ginseng stack → camus transition |
| scytherus | `ekscyth` | Camus damage mode (addiction+nausea → impulse confusion scytherus → bite) |
| auto | `ekauto` | Adaptive strategy |

**Key mechanics**:
- Ekanelia BITE transforms venoms with bonus afflictions (conditional on existing affs)
- Impulse delivers mental affs instantly (requires asthma + weariness + no fangbarrier)
- Fratricide causes impulse-delivered affs to relapse after cure
- `serp_sendAttack()` prepends `order adder kill target::purge::` before attack
- Uses V1 fallback for sileris/fangbarrier (GMCP timing gap)

---

## Shaman Offense System

**Full details**: See memory file `shaman.md`

**Key files**:
- `shaman/028_Shaman_Offense.lua` — Unified V3-aware offense (replaced 001-027)
- `triggers/.../shaman/` — 12 trigger files (001-012)
- `ataxia/shaman_system/` — Spirit binding (001=table, 002=save/load, 003=funcs)

**Dispatch**: `zz`/`sr` alias → `shamanOffense.dispatch()` → `buildAttack()` → `sendAttack()`

**Modes**: group (`shgroup`), lock (`shlock`), bleed (`shbleed`), damage (`shdmg`), tzantza (`shtz`)

**Rotation**: Curse+Relapse(2.2s) → Jinx(2.3s) → Swiftcurse(0.8s) → Curse+Invoke(2.2s) → repeat

**Key mechanics**:
- Jinx pairing: Channel check on BOTH passes (herb + focus curability)
- Coagulation `skipAff` prevents duplicate aff selection
- Manaleech: smoke-cured (not kelp), gated behind asthma
- Spirit invoke priority: Soulrend > Coagulation(haemophilia+BL≥200) > Bloodlet
- `swiftFired` + `jinxUsedThisCycle` flags control rotation gating

---

## Snipe System (Class-Agnostic)

**Full details**: See memory file `snipe.md`

**Key files**:
- `snipe/001_Snipe_System.lua` — Auto-scan snipe system
- `triggers/.../snipe/001_Snipe_Success.lua` — Multiline hit detection
- `triggers/.../snipe/002_Snipe_Failure.lua` — Wrong dir → advance scan
- `aliases/.../targetting/003_Snipe.lua` — `snt` alias

**Usage**: `snt [target] [dir]` — auto-scans room exits if no direction given

**Key mechanics**:
- Direction cache: `snipe.directionCache[target:lower()]` reused across fires
- Scan queue built from `gmcp.Room.Info.exits` in stable order
- Party callout: `pt Shot <target> <dir>` (unless aeon)
- Multiline trigger: Uses `multimatches[1][2]` (NOT `matches[2]`)

---

## Setup Wizard System

**Key file**: `src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/020_Setup_Wizard.lua`

**Namespace**: `leviSetup`

**Dispatch**: `levi setup <cmd> [args]` alias → `leviSetup.dispatch(cmd, rest)`

**Commands**:
| Command | Function | Purpose |
|---------|----------|---------|
| (none) | `setupMain()` | Main menu with all categories |
| `class` | `setupClass(rest)` | Set/detect class |
| `separator` | `setupSeparator(rest)` | Command separator |
| `weapons` | `setupWeapons(rest)` | Weapon IDs |
| `basher` | `setupBasher(rest)` | Basher settings |
| `sipping` | `setupSipping(rest)` | Health/mana sip thresholds |
| `tracking` | `setupTracking(rest)` | V1/V2 tracking mode |
| `combat` | `setupCombat(rest)` | Party relay, looting, gag clot |
| `gui` | `setupGui(rest)` | Toggle GUI on/off |
| `ndb` | `setupNdb(rest)` | NDB highlight colours |
| `install` | `setupInstall()` | Guided install walkthrough |
| `status` | `setupStatus()` | One-page settings overview |
| `guide` | `setupGuide(rest)` | Configuration guides (ataxia/basher/ndb) |

**When modifying**: Follow the existing `cecho()` color pattern (dark_orchid headers, green values, light_slate_blue labels).

---

## Shikudo Lock System Reference

The Lock system (`007_CC_Shikudo_Lock.lua`) uses pure affliction-based locking with Telepathy.

### Lock Progression

| Phase | Afflictions | Next Step |
|-------|-------------|-----------|
| **Softlock** | asthma + anorexia + slickness | Apply paralysis |
| **Venomlock** | + paralysis | Use Telepathy for impatience |
| **Hardlock** | + impatience | Apply weariness |
| **Truelock** | + weariness | Damage pressure to kill |

### Form Abilities for Lock Afflictions

| Form | Key Abilities | Lock Affs Available |
|------|---------------|---------------------|
| **Oak** | livestrike, nervestrike, ruku, kuro | asthma, paralysis, slickness, weariness |
| **Willow** | hiraku, hiru, dart | anorexia, dizziness |
| **Rain** | kuro, hiru, ruku | slickness, weariness, dizziness |
| **Gaital** | needle, ruku, kuro, jinzuku | slickness, weariness, addiction |
| **Maelstrom** | livestrike, ruku, jinzuku | asthma, slickness, addiction |

### Form Transitions

- **Need anorexia?** → Go to Willow (has Hiraku)
- **Have anorexia?** → Go to Oak (all lock affs)
- **Near kata limit?** → Transition to avoid stumble
- **Kill phase + prone?** → Go to Gaital (spinkick)

### Kata Limits per Form

| Form | Max Kata |
|------|----------|
| Rain | 24 |
| All others | 12 |

### Telepathy Integration

Telepathy uses EQ balance (separate from BAL for staff attacks):
1. `mindlock` - Establish first
2. `impatience` - Critical for hardlock
3. `batter` - Mental pressure (stupidity, epilepsy, dizziness)
4. `paralyse` - Backup paralysis

### Shikudo Commands

| System | Dispatch | Status |
|--------|----------|--------|
| V1 | `shikudo.dispatch()` | `skstatus()` |
| V2 | `shikudov2.dispatch()` | `skv2status()` |
| Lock | `shikudolock()` | `sklstatus()` |

---

## Before Coding Defensive Systems

Read the **attacker's class documentation** for:
- Kill routes to counter
- Gating requirements for dangerous afflictions
- Priority cure recommendations
- Class-specific lock affliction to prevent

---

## Serpent Defense Quick Reference

**CRITICAL**: Modern Serpents use **Impulse** (not SNAP) to deliver mental afflictions.

### Impulse Requirements
All three must be true for Impulse to work:
1. Victim has NO sileris/fangbarrier (quicksilver applied)
2. Victim HAS asthma
3. Victim HAS weariness

### Ekanelia Mechanics (BITE Venom Transformation)
Ekanelia allows serpent BITE attacks to deliver BONUS afflictions when specific conditionals are present.
**CRITICAL**: Only works with BITE, not DOUBLESTAB. Serpent sacrifices double venom to use it.

| Venom | Conditionals | Normal + Bonus Effect |
|-------|--------------|----------------------|
| **kalmia** | clumsiness + weariness | asthma + **slickness** |
| **monkshood** | asthma + masochism + weariness | disfigurement + **impatience** |
| **curare** | hypersomnia + masochism | paralysis + **hypochondria** |
| **loki** | confusion + recklessness | random + **nausea + paralysis** |
| **scytherus** | addiction + nausea | scytherus + **camus damage** |

### Ekanelia Defense Priorities
| Danger | Block By Curing | Why |
|--------|-----------------|-----|
| kalmia setup | clumsiness OR weariness | Prevents asthma + slickness in one bite |
| monkshood setup | masochism | Blocks 2 transforms (monkshood + curare) |
| loki trap | confusion OR recklessness | Prevents predictable nausea + paralysis |

### Fratricide + Scytherus (CRITICAL)
- **Fratricide** causes Impulse-delivered afflictions to RELAPSE after cure
- **Scytherus** deals ~1200 damage on each relapse tick
- **CURE PRIORITY**: When fratricide + scytherus present, cure fratricide IMMEDIATELY
- Fratricide cured by **Argentum** (lobelia herb group)

### Cure Competition
| Herb | Competing Afflictions | Priority |
|------|----------------------|----------|
| **Kelp** | asthma vs weariness | Cure ASTHMA (breaks Impulse) |
| **Bloodroot** | paralysis vs slickness | Cure PARALYSIS when asthma present |
| **Argentum** | fratricide vs masochism | Cure FRATRICIDE when scytherus present |

### AntiSerpent Function (001_Anti_Priorities.lua)
**Priority Order**:
1. **approachingLock + tree** → TREE (asthma + slickness + mental)
2. **impulseLockThreat + tree** → TREE (asthma + weariness + no fangbarrier + mental)
3. **fratricide + impulseEnabled + tree** → TREE (stops relapse spiral)
4. **fangbarrier down + impulse conditions** → Re-apply quicksilver
5. **fratricide + scytherus** → Cure fratricide NOW (1200 damage per relapse)
6. **Ekanelia prevention** (masochism, kalmia setup, loki setup)
7. **Impulse prevention** (asthma cure when kelp stack >= 2)
8. **fratricide + impulseEnabled** → Cure fratricide
9. **Standard lock handling**

### Key Files
- `.claude/classes/serpent.md` - Full Serpent mechanics + Ekanelia
- `.claude/classes/lock_types.md` - Serpent lock strategy section
- `src_new/scripts/.../algedonic_defense_1.0/001_Anti_Priorities.lua` - AntiSerpent function
- `src_new/scripts/.../serpent/002_Serpent_Offense.lua` - Serpent offense system

---

## Affliction Stacking Quick Reference

Stack afflictions that share the same cure herb:

| Herb | Afflictions |
|------|-------------|
| **Kelp** | asthma, clumsiness, sensitivity, weariness, healthleech |
| **Ginseng** | addiction, haemophilia, lethargy, nausea, scytherus |
| **Goldenseal** | impatience, stupidity, dizziness, epilepsy, depression |
| **Bloodroot** | paralysis, slickness |
| **Lobelia** | recklessness, vertigo, masochism, guilt |
| **Ash** | confusion, dementia, hallucinations, paranoia |

---

## Code Header Template

When creating/modifying offensive Lua files, include:

```lua
--[[
  OFFENSIVE SYSTEM - <Class Name>

  REQUIRED READING before modifying:
  - .claude/classes/lock_types.md (lock definitions)
  - .claude/classes/<class>.md (class mechanics)

  Lock progression: Softlock → Venomlock → Truelock
  See lock_types.md for affliction requirements and escape routes.
]]--
```

---

## Class-Specific Lock Afflictions

| Classes | Lock Aff | Blocks |
|---------|----------|--------|
| Knights, Monk, Serpent, Sentinel, Blademaster, Elemental Lords | Weariness | Passive cures |
| Apostate, Pariah, Bard, Priest | Voyria | Sip healing |
| Magi, Sylvan | Haemophilia | Blood cures |
| Alchemist | Stupidity | Transmutation |
| Depthswalker | Recklessness | Shadow cures |
| Psion | Confusion | Mental cures |

---

## Target Affliction Tracking Quick Reference

The system uses a **three-tier approach** for tracking enemy afflictions:

| System | Table/Module | Purpose |
|--------|-------------|---------|
| **V1 (Core)** | `tAffs` | Boolean tracking - always present |
| **V2 (Certainty)** | `tAffsV2` / `haveAffV2()` | Certainty-based tracking with stacks |
| **V3 (Probability)** | `afflictionStatesV3` / `haveAffV3()` | Branching probability states (0.0-1.0) |

**Toggle:**
- V2: `ataxia.settings.useAffTrackingV2 = true`
- V3: `affConfigV3.enabled = true`

**Global Functions:**
- `tarAffed(...)` - Add afflictions (variadic)
- `erAff(what)` - Remove affliction (**V1 only** — use `erAffWrapper()` or add `removeAffV3()` for V3)
- `haveAff(what)` - Check if target has affliction (routes V3 → V1)
- `haveAffV2(aff)` - Check with V2 certainty
- `haveAffV3(aff, threshold)` - Check with V3 probability (default 30% threshold)
- `getAffProbabilityV3(aff)` - Get probability 0.0-1.0

**Class-Specific Routing (V3 → V2 → V1):**
- `infernalDWC.hasAff(aff)` - DWC Vivisect system
- `blademaster.hasAff(aff)` - Blademaster Ice Dispatch
- `apostate.hasAff(aff)` - Apostate system
- `dwbRunie.hasAff(aff)` - DWB Runie system

Each class's `hasAff()` routes: V3 (if enabled) → V2 (if enabled) → V1 (fallback).
Shield/rebounding use dual-check pattern: `hasAff("rebounding") or (tAffs and tAffs.rebounding)`

**IMPORTANT**: Never use `hasAff(x) or (tAffs and tAffs.x)` for regular afflictions — trust `haveAff()` alone.
**Exception**: Rebounding/shield SHOULD use V1 fallback due to GMCP timing gap.

**Files:**
- `src_new/scripts/.../017_Affliction_Management.lua` - V1 core tracking (`haveAff()` at line 187)
- `src_new/scripts/.../affliction_tracking_v2/` - V2 certainty system (4 files)
- `src_new/scripts/.../affliction_tracking_core/008_V3_Integration.lua` - V3 integration
- `src_new/scripts/.../dwc/001_Infernal_DWC_Vivisect.lua` - DWC V3 integration
- `src_new/scripts/.../blademaster/005_CC_BM_Ice.lua` - BM V3 integration

---

## Build System

The project uses [Muddler](https://github.com/demonnic/muddler) to build Mudlet packages.

**Build pipeline**:
```bash
# 1. Convert source to Muddler format
python tools/convert_to_muddler.py --src ./src_new --output ./muddler_project

# 2. Build with Muddler (requires Java 8+)
set JAVA_HOME=E:\Java
cd muddler_project
E:\muddle-shadow-1.1.0\muddle-shadow-1.1.0\bin\muddle.bat
```

**Output**: `muddler_project/build/Levi_Ataxia.mpackage`

**Verify conversion**: `python tools/compare_builds.py --old packages/Test_Build.xml --new ./muddler_project`

---

## Key Files Reference

| Path | Purpose |
|------|---------|
| `.claude/classes/lock_types.md` | Comprehensive lock definitions |
| `.claude/classes/README.md` | Class index and combat concepts |
| `.claude/classes/<class>.md` | Per-class kill routes and mechanics (26 classes) |
| `.claude/templates/` | Offense, limb tracking, lock strategy templates |
| `.claude/databases/` | venoms.yaml, afflictions.yaml, locks.yaml, forms.yaml |
| `CLAUDE.md` | Main project documentation |
| `GETTING_STARTED.md` | Setup guide and system overview |
| `docs/ai-includes/agent-teams.md` | Multi-agent team coordination guide |
| `src_new/scripts/.../serpent/002_Serpent_Offense.lua` | Serpent offense (unified) |
| `src_new/scripts/.../shaman/028_Shaman_Offense.lua` | Shaman offense (unified) |
| `src_new/scripts/.../dwc/001_Infernal_DWC_Vivisect.lua` | DWC Infernal vivisect |
| `src_new/scripts/.../blademaster/005_CC_BM_Ice.lua` | Blademaster ice dispatch |
| `src_new/scripts/.../apostate/015_CC_Apostate.lua` | Apostate offense |
| `src_new/scripts/.../shikudo/001_Shikudo.lua` | Shikudo V1 |
| `src_new/scripts/.../shikudo/002_Shikudo_R2.lua` | Shikudo V2 |
| `src_new/scripts/.../shikudo/007_CC_Shikudo_Lock.lua` | Shikudo Lock |
| `src_new/scripts/.../snipe/001_Snipe_System.lua` | Snipe system (class-agnostic) |
| `src_new/scripts/.../misc_scripts/020_Setup_Wizard.lua` | Setup wizard |
| `src_new/scripts/.../017_Affliction_Management.lua` | Target affliction tracking (V1) |
| `src_new/scripts/.../affliction_tracking_core/008_V3_Integration.lua` | V3 integration |

---

## Basher Development Reference

### Key Files

| File | Purpose |
|------|---------|
| `src_new/scripts/.../basher/001_Bashing_Functions.lua` | Attack dispatch, flee logic, battlerage assembly |
| `src_new/scripts/.../basher/002_Class_Bashing.lua` | Class-specific attack builders (20+ classes) |
| `src_new/scripts/.../basher/003_Bash_Stats_Functions.lua` | Session statistics |
| `src_new/scripts/.../genrunning/001_Bashing_API.lua` | Path generation, room scanning, death recovery |
| `src_new/scripts/.../genrunning/002_search_targets.lua` | Target selection, stormhammer, shield retarget, ldeck |
| `src_new/scripts/.../genrunning/003_Engaged_Disengage.lua` | Basher enable/disable handlers |
| `src_new/scripts/.../genrunning/004_Autobashing_Functions.lua` | tryAttack() dispatch gate, throttle |
| `src_new/scripts/.../ataxia/022_Bashing_Functions.lua` | Attack execution, danger levels, flee |
| `src_new/scripts/.../genrunning/010_Prompt_Running.lua` | Active prompt handler |

### Configuration Options

| Setting | Type | Default | Purpose |
|---------|------|---------|---------|
| `ataxiaBasher.enabled` | bool | false | Master on/off |
| `ataxiaBasher.paused` | bool | false | Pause without disable |
| `ataxiaBasher.fleeThreshold` | number | varies | HP% to flee |
| `ataxiaBasher.dangerCount` | number | varies | Max dangerous mobs |
| `ataxiaBasher.targetList` | table | — | Per-area targets |
| `ataxiaBasher.goldPack` | string | `"pack436363"` | Container ID for gold collection |
| `ataxiaBasher.attackCooldown` | number | 0.4 | Default attack cooldown (seconds) |
| `ataxiaBasher.fleeTimeout` | number | 20 | Flee circuit breaker timeout (seconds) |
| `ataxiaBasher.shieldTimers` | table | `{["a mhun knight"]=4.7}` | Per-mob shield durations |
| `ataxiaBasher.shieldTimerDefault` | number | 3.1 | Default shield duration |
| `ataxiaBasher.ldeckRules` | table | see CLAUDE.md | Data-driven legend deck draw rules |
| `ataxiaBasher_attackCooldowns` | table | — | Per-class static cooldown overrides |

### Architecture Notes

- **Single gate**: `tryAttack()` is the ONLY function that calls `ataxiaBasher_attack()`. Gates: anti-spam → bashFlee → paused → canBals()+canStand() → skipRoom → found_target → throttle
- **Anti-spam**: 0.3s fixed timer prevents double-sends. `canBals()` (GMCP) is the real balance gate
- **Room arrival**: GMCP Room → `need_roomCheck=true` → Items.List → denizensHere → prompt → scanRoom() + search_targets() → tryAttack()
- **Dispatch table** built once at load time. Maps class name to function via `_G[]` lookup
- **Stormhammer**: Dirty-flag cached, lazy recompute during prompt cycle
- **Knight classes** have separate standalone functions with 4 specs each
- **Monk** has `monkBashing2()` handling both Tekura and Shikudo specs

### Before Modifying Basher Code

See `docs/plans/basher-review.md` for:
- Current architecture and file analysis
- Known issues and improvement history
- System integrations
