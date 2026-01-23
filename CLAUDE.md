# LEVI-Achaea Combat System - AI Assistant Guide

## Project Overview

This repository contains the **"For Levi" Mudlet package**, a comprehensive combat and automation system for Achaea (an Iron Realms Entertainment MUD). The system is built in Lua for the Mudlet client and handles complex combat mechanics including affliction tracking, intelligent curing, combat offense, and defensive automation.

**Current Systems**:
- **Mudlet Mapper (mmp)** - Advanced pathfinding and navigation
- **Ataxia Combat System** - Affliction tracking, defense management, combat automation
- **ataxiaNDB** - Player database with API integration
- **ataxiagui** - Custom GUI with Geyser

**Reference System**: Orion (community combat system)

---

## Technical Context

### What is Achaea?
- Text-based multiplayer game with real-time combat
- Complex affliction system (30+ different afflictions per class)
- Class-based combat with unique abilities per class (26 classes)
- Each class has at most 3 class skills; each skill has many abilities
- Requires sub-second reaction times
- Combat involves illusions that can fake afflictions
- Multiple balance types (balance, equilibrium, class-specific)
- Server-side curing (SSC) exists but custom systems provide competitive advantages

### Mudlet Platform
- Lua 5.1 based MUD client with event system
- **Triggers**: Fire on incoming game text (regex/substring/exact match)
- **Aliases**: User command shortcuts
- **Timers**: Delayed action execution
- **Scripts**: Lua code modules
- **Event system**: Named/anonymous event handlers for inter-module communication
- **GMCP**: JSON-based game data feed (Game.Core.MCP)
- **GUI components**: Gauges, labels, miniconsoles for displays

### Mudlet Package Structure (XML Format)
```xml
<MudletPackage>
  <TriggerPackage>      <!-- Trigger groups and individual triggers -->
  <TimerPackage>        <!-- Timer definitions -->
  <AliasPackage>        <!-- Command aliases -->
  <ScriptPackage>       <!-- Lua script modules -->
  <ActionPackage>       <!-- Buttons/UI actions -->
  <KeyPackage>          <!-- Keybindings -->
</MudletPackage>
```

---

## Repository Structure

```
LEVI-Achaea/
├── .claude/
│   ├── AGENTS.md           # Agent instructions for AI development
│   └── classes/            # 26 class files + lock_types.md
├── docs/
│   ├── plans/              # Project plans and reviews
│   ├── legend-deck.md      # Legend Deck card reference
│   └── artefacts-reference.md
├── src/
│   ├── loader.lua          # Auto-loads all systems in order
│   ├── mmp/                # 134 files - Mudlet Mapper navigation
│   ├── ataxia/             # 304 files - Combat system
│   ├── ataxiaBasher/       # 13 files - Automated hunting
│   ├── ataxiagui/          # 5 files - GUI with Geyser
│   └── ataxiaNDB/          # 7 files - Player database
├── CLAUDE.md               # This file
├── GETTING_STARTED.md      # Setup and usage guide
└── README.md               # Project overview
```

### Source Code Organization

Each subsystem uses numbered files (001_, 002_, etc.) to enforce load order:
- **mmp/** - Pathfinding, speedwalking, fast travel, multi-game support
- **ataxia/** - Affliction tracking, defense management, class offenses
- **ataxiaBasher/** - Experience tracking, class-specific bashing, emergency defenses
- **ataxiagui/** - Vitals bars, map window, chat tabs
- **ataxiaNDB/** - API integration, city tracking, name highlighting

---

## Current System Components

### Mudlet Mapper (mmp)
- `mmp.gotoRoom(roomID)` - Navigate to a specific room
- `mmp.gotoArea(areaName)` - Navigate to area entrance
- `mmp.gotoFeature(featureName)` - Navigate to map features
- `mmp.getPath(from, to)` - Calculate and cache paths
- `mmp.fixPath()` - Optimize paths for sprint/dash/gallop
- Fast travel integration (wings, tarot, harness, pebble)
- Balance-aware movement with GMCP integration
- Multi-game support (Achaea, Aetolia, Lusternia, Imperian)

### Ataxia Combat System
- **Affliction Tracking**: 100+ afflictions with color-coded display
- **Target Affliction Tracking**: Dual system for tracking enemy afflictions (see below)
- **Limb Tracking**: `selfLimbDamage` for damage percentages, `tLimbs` for enemy tracking
- **Fracture Management**: Two-handed combat tracking
- **Defense Management**: Automatic parrying, SSC integration
- **Basher**: `ataxiaBasher` for automated hunting (see details below)
- **Class Modules**: Pariah, Bard, Monk, Magi, Two-Handed, Infernal DWC
- **Shikudo Dispatch System**: Full auto-combat for Monk/Shikudo spec
  - `200_Shikudo.lua` (V1) - Balanced leg prep, both legs 90%+
  - `201_Shikudo_V2.lua` (V2) - Focus fire one leg, clumsy first
  - `203_Shikudo_Lock.lua` (Lock) - Pure affliction-based locking with Telepathy
  - V1/V2 Commands: `shikudo.dispatch()`, `shikudov2.dispatch()`, `skstatus()`, `skv2status()`
  - Lock Commands: `shikudolock()`, `sklstatus()`, `sklockstatus()`
- **Infernal DWC Vivisect System**: Full auto-combat for Infernal DWC spec
  - `003_Infernal_DWC_Vivisect.lua` - Undercut + DSL vivisect strategy
  - Commands: `infernalDWCVivisect()`, `infernalDWCStatus()`, `infernalDWCReset()`
  - Phases: NAUSEA_SETUP → PREP → EXECUTE → KILL
  - Kill route: Undercut (break leg + 4s salve lock) → DSL with epteth/epseth (break arm + level 1 to remaining limbs) → Vivisect
  - RIFTLOCK mode: Counter to RESTORE ability (anorexia + slickness + addiction lock)

### Target Affliction Tracking System

The system uses a **dual-layer approach** for tracking afflictions applied to enemies:

**Core Files:**
- `src_new/scripts/levi_ataxia/levi/ataxia/017_Affliction_Management.lua` - Main tracking functions
- `src_new/triggers/levi_ataxia/for_levi/leviticus/439_NEW_DEADEYES.lua` - Apostate curse detection

**Dual System Design:**

| Layer | Table | Purpose |
|-------|-------|---------|
| **Core Tracking** | `tAffs` | Always tracks afflictions unconditionally (boolean) |
| **Confidence Tracking** | `tAffConfidence` | Optional enhancement with confidence levels (0.0-1.0) |

**Core Functions:**

| Function | Purpose |
|----------|---------|
| `tarAffed(...)` | Add afflictions to target (variadic - accepts multiple) |
| `tarAffedConfirmed(...)` | Add afflictions with 1.0 confidence (confirmed by game message) |
| `erAff(what)` | Remove affliction from target tracking |
| `haveAff(what)` | Check if target has affliction (core tracking) |
| `haveAffWithConfidence(aff, minConf)` | Check with minimum confidence threshold |
| `getAffConfidence(aff)` | Get current confidence level for affliction |
| `resetAffConfidence()` | Clear all confidence values (called on target change) |

**Confidence Levels:**

| Level | Value | Meaning |
|-------|-------|---------|
| Confirmed | 1.0 | Saw game confirmation message |
| Assumed | 0.7 | Assumed from venom/attack landing |
| Threshold | 0.3 | Below this, affliction considered cured |

**How It Works:**
1. Core tracking (`tAffs[aff] = true`) happens unconditionally when attacks land
2. Confidence tracking is an optional enhancement layer that doesn't affect core tracking
3. When enemy cures, `erAff()` clears both the core tracking and confidence
4. Combat logic can use either `haveAff()` (simple) or `haveAffWithConfidence()` (advanced)

**Example Usage:**
```lua
-- Simple check (core tracking)
if haveAff("paralysis") then
  -- Target has paralysis
end

-- Advanced check (confidence-based)
if haveAffWithConfidence("paralysis", 0.5) then
  -- Target probably has paralysis (50%+ confidence)
end
```

### Target Affliction Tracking V2 System

**NEW**: Advanced affliction tracking with certainty levels, stack tracking, and AK-inspired cure detection.

**Full Documentation:** `.claude/projects/affliction-tracking-v2/`

**Toggle:**
```lua
ataxia.settings.useAffTrackingV2 = true   -- Enable V2
ataxia.settings.useAffTrackingV2 = false  -- Disable, use old system (default)
```

**Key Features:**
- Certainty-based tracking (0/1/2+ levels with stacking support)
- Verifiability-based priority (unverifiable affs assumed cured first)
- Random cure counter (tracks tree/focus/passive cures like AK's `ak.randomaffs`)
- Backtracking system (reverses incorrect guesses)
- Third-party verification (fumble confirms clumsiness, smoke confirms no asthma)

**V2 Functions:**

| Function | Purpose |
|----------|---------|
| `confirmAffV2(aff)` | Set certainty to 2 (confirmed) |
| `removeAffV2(aff)` | Set certainty to 0 (cured) |
| `haveAffV2(aff)` | Check if certainty >= 1 |
| `stackAffV2(aff)` | Add a stack (+2 certainty) |
| `getStackCountV2(aff)` | Get number of stacks |
| `onTargetTreeV2(target)` | Handle tree tattoo cure |
| `onTargetFocusV2(target)` | Handle focus cure |

**V2 Files:**
```
src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_v2/
├── 001_Core.lua           # Certainty + stack + random cure tracking
├── 002_Herb_Cures.lua     # Priority lists for all 7 herbs
├── 003_Backtracking.lua   # Guess storage and reversal
└── 004_Verification.lua   # Fumble/smoke signal handlers
```

**Integrated Triggers:**
- 15 herb triggers → `targetAteWrapper()`
- Tree trigger → `onTargetTreeV2()`
- Focus triggers → `onTargetFocusV2()`
- 16 class cure triggers → `removeAffV2()` / `reduceRandomAffCertaintyV2()`

**Offense System Requirements:**
When coding offense systems, check `ataxia.settings.useAffTrackingV2`:
- If enabled: Use `haveAffV2(aff)` and `haveConfirmedAffV2(aff)` for affliction checks
- If disabled: Fall back to `haveAff(aff)` (old system)
- For stacking afflictions: Use `getStackCountV2(aff)` to check multiple stacks
- For lock detection: Use `haveAffV2()` which returns true for certainty >= 1 (likely or confirmed)

### ataxiaBasher (Automated Hunting System)

The basher provides automated target selection and attack execution for PvE hunting.

**Core Files:**
- `src/ataxiaBasher/008_search_targets.lua` - Target selection and room scanning
- `src/ataxiaBasher/005_Bashing_Functions.lua` - Attack assembly and execution
- `src/ataxiaBasher/006_Class_Bashing.lua` - Class-specific bashing attacks
- `src/ataxiaBasher/010_Autobashing_Functions.lua` - Main patterns loop

**Key Functions:**
| Function | Purpose |
|----------|---------|
| `search_targets()` | Scans room for valid targets from `ataxiaBasher.targetList[area]` |
| `ataxiaBasher_attack()` | Assembles and sends attack command |
| `ataxiaBasher_patterns()` | Main loop - fires attacks when balanced |
| `ataxiaBasher_stormhammer()` | Populates AoE target list |
| `ataxiaBasher_countMobsInRoom(mobName)` | Counts specific mob types in current room |
| `ataxiaBasher_preCombatLdeck()` | Pre-combat legend deck card draws |

**Key Variables:**
| Variable | Purpose |
|----------|---------|
| `ataxiaBasher.enabled` | System on/off toggle |
| `ataxiaBasher.manual` | Manual targeting mode |
| `ataxiaBasher.targetList[area]` | Table of target mob names per area |
| `ataxia.denizensHere` | Table of NPCs in current room (id → name) |
| `target` | Current target ID |
| `found_target` | Boolean - valid target exists |
| `stormhammerTargets` | List of IDs for AoE attacks |

**Pre-Combat Legend Deck Draws:**

The basher automatically draws legend deck cards before attacking dangerous multi-target rooms:

| Condition | Cards Drawn |
|-----------|-------------|
| 3+ elite mhun keepers | Maran + Matic |
| 3 mhun knights | Maran only |
| 4+ mhun knights | Maran + Matic |

Cards are drawn using the queue system (`queue add free ldeck draw <card>`) and only once per room entry (tracked via `ataxiaBasher.ldeckDrawnRoom`).

**Attack Flow:**
```
Room Entry (GMCP)
    ↓
Prompt Trigger → ataxia_promptCommands()
    ↓
search_targets() → Find valid target from targetList
    ↓
ataxiaBasher_preCombatLdeck() → Draw cards if dangerous room
    ↓
ataxiaBasher_patterns() → Check balance/standing
    ↓
ataxiaBasher_attack() → Build and send attack command
```

### GUI System (ataxiagui)
- Left panel: Players, Room info, Bash stats
- Right panel: Map display, Chat tabs
- Bottom panel: Health/Mana/Willpower/Endurance gauges
- Balance/Equilibrium indicators
- Tabbed chat (All, City, Clans, Misc, Order, Party, Tells)

### Player Database (ataxiaNDB)
- Fetches from Achaea API (`http://api.achaea.com/characters/`)
- Tracks: name, city, house, class, level, XP rank, player kills
- City-based name highlighting
- Enemy and army rank tracking

---

## Achaea Classes Reference

Achaea has **26 classes** total: 21 base classes + 4 Elemental Lords + Dragon.

Each class has:
- At most 3 class skills with many abilities each
- Unique bashing (hunting) attacks
- Unique battlerage attacks

### Class Progression
1. **Fledgling** - Initial stage, only 2 of 3 skills, capped at Skilled level
2. **Journeyman** - Level 20+, skills capped at Fabled level
3. **Full Member** - After `EMBRACE CLASS` (Level 30 + House rank 2, or Level 50 without house), gains 3rd skill, no learning limits

**Getting a Class**: Visit Certimene in Delos: `ASK CERTIMENE BECOME <class>`

**Changing Class**:
- **Multiclass**: Can have multiple classes (`HELP MULTICLASS`)
- **Quit Class**: Use `QUIT CLASS` to leave (98% lesson refund before full member, 50% after)

### Base Classes (21)

| Class | Description | Skills |
|-------|-------------|--------|
| Alchemist | Enigmatic figures wielding the power of the ether | Alchemy, Physiology, Formulation/Sublimation |
| Apostate | Evil, necromantic daemon summoners | Evileye, Necromancy, Apostasy |
| Bard | Sword, Song, and Story at the disposal of the Virtuoso | Composition, Bladedance, Sagas (or Woe for Cyrene) |
| Blademaster | Masters of the legendary Two Arts | TwoArts, Striking, Shindo |
| Depthswalker | Fearless manipulators of shadow and time | Aeonics, Shadowmancy, Terminus |
| Druid | Forest-loving metamorphs | Groves, Metamorphosis, Reclamation |
| Infernal | Evil warriors employing necromantic methods (Knight) | Malignity, Oppression, Weaponmastery |
| Jester | Happy-go-lucky pranksters and roguish entertainers | Puppetry, Pranks, Tarot |
| Magi | Masters of the four elements and crystalline vibrations | Crystalism, Elementalism, Artificing |
| Monk | Forges mind, body, and spirit into a unified whole | Tekura/Shikudo, Kaido, Telepathy |
| Occultist | Chaos-loving summoners of extra-planar entities | Domination, Tarot, Occultism |
| Paladin | Valorous warriors with eagle companion (Knight) | Excision, Valour, Weaponmastery |
| Pariah | Cheaters of Death and bringers of plagues | Memorium, Pestilence, Charnel |
| Priest | Holy warriors with a fearsome guardian angel | Spirituality, Devotion, Zeal |
| Psion | Weavers of Aldar magic | Weaving, Psionics, Emulation |
| Runewarden | Mystic warriors who employ runic lore (Knight) | Runelore, Discipline, Weaponmastery |
| Sentinel | Metamorphing forest rangers with animal companions | Woodlore, Metamorphosis, Skirmishing |
| Serpent | Masters of venoms and subterfuge (see Ekanelia below) | Subterfuge, Venom, Hypnosis |
| Shaman | Mystical users of Vodun dolls, curses, and bound spirits | Vodun, Curses, Spiritlore |
| Sylvan | Forest-lovers who blend mastery of three elements | Propagation, Groves, Weatherweaving |
| Unnamable | Frenzied mutant warriors for Chaos (Knight) | Dominion, Anathema, Weaponmastery |

### Elemental Lords (4 separate classes)
- Airlord, Earthlord, Firelord, Waterlord

### Dragon (End-Game Class)
- Unlocked at level 99
- 6 color variants: Red, Black, Silver, Gold, Blue, Green
- Each color has unique breath weapon and battlerage

### Class Specializations

**Knight Classes** (Infernal, Paladin, Runewarden, Unnamable) - Weaponmastery specs:
- **DWC (Dual Wield Cutting)** - Double venom application, fast attacks
- **DWB (Dual Wield Blunt)** - Double breaks, best limb prep
- **SnB (Sword and Board)** - Impale/stun, shield abilities, damage mitigation
- **2H (Two-Handed)** - Best damage, passive paralysis curing, strip rebounding/shield

**Monk**:
- **Tekura** - Unarmed martial arts (default)
- **Shikudo** - Staff-based combat (requires Trans Tekura to unlock)

**Alchemist**:
- **Formulation** - Default alchemical field
- **Sublimation** - Alternative field using Hashan's Wellspring

**Metamorphosis** (Druid/Sentinel):
- **Druid-exclusive morphs**: Hydra, Wyvern
- **Sentinel-exclusive morphs**: Jaguar, Basilisk

**Bard**:
- **Sagas** - Default third skill
- **Woe** - Exclusive to Cyrene

---

## Key Concepts

### Afflictions
- Negative status effects applied during combat (~55+ different afflictions)
- Must be cured in correct order (priority-based)
- Some afflictions hide or fake others (diagnosis required)
- GMCP provides: `gmcp.Char.Afflictions.List`, `.Add`, `.Remove`

#### Cure Types
| Action | Description | Examples |
|--------|-------------|----------|
| **Eat** | Consume herb or mineral | Bloodroot (paralysis), Kelp (asthma) |
| **Apply** | Apply salve to body part | Epidermal (anorexia), Mending (crippled) |
| **Smoke** | Smoke from pipe | Elm (aeon), Valerian (slickness) |
| **Sip** | Drink elixir | Immunity (voyria) |
| **Writhe** | Escape bindings | Entangled, Transfixed, Webbed |
| **Clot** | Stop bleeding | Bleeding |
| **Focus** | Mental cure | Breaks some locks |
| **Tree** | Tree tattoo | Cures random affliction |

#### Herb/Mineral Groupings
Each herb has an alchemical mineral equivalent (same cure balance):
- **Ginseng/Ferrum**: Addiction, Haemophilia, Lethargy, Nausea
- **Kelp/Aurum**: Asthma, Clumsiness, Sensitivity, Weariness
- **Goldenseal/Plumbum**: Epilepsy, Impatience, Stupidity, Dizziness
- **Bloodroot/Magnesium**: Paralysis, Slickness (alt)
- **Lobelia/Argentum**: Agoraphobia, Recklessness, Vertigo
- **Bellwort/Cuprum**: Generosity, Pacifism, Peace
- **Prickly Ash/Stannum**: Confusion, Dementia, Paranoia

#### Complete Cure Herb Reference
**Sources:** [Venom (Skill)](https://wiki.achaea.com/Venom_(Skill)), [Oppression](https://wiki.achaea.com/Oppression)

| Herb | Afflictions Cured |
|------|-------------------|
| **kelp** | clumsiness, healthleech, weariness, asthma, sensitivity, hypochondria, parasite |
| **ginseng** | nausea, haemophilia, addiction, darkshade, flushings, lethargy, scytherus |
| **goldenseal** | stupidity, impatience, depression, sandfever, epilepsy, dizziness, dissonance, shyness |
| **lobelia** | recklessness, vertigo, spiritburn, tenderskin, loneliness, claustrophobia, masochism, agoraphobia |
| **ash** | confusion, hypersomnia, hallucinations, paranoia, dementia, crescendo |
| **bellwort** | timeloop, justice, lovers, peace, pacified, generosity, indifference, diminished |
| **bloodroot** | paralysis |

#### Venom → Affliction → Cure Reference
| Venom | Affliction | Cure | Combat Use |
|-------|------------|------|------------|
| **curare** | paralysis | bloodroot | Venomlock, prevent tree |
| **kalmia** | asthma | kelp | Softlock, block smoking |
| **xentio** | clumsiness | kelp | Kelp stack, 33% miss chance |
| **euphorbia** | nausea | ginseng | Block parry, enable limb prep |
| **gecko** | slickness | kelp | Softlock, block salves (also cured by smoking valerian if no asthma!) |
| **slike** | anorexia | kelp | Softlock, block eating |
| **prefarar** | sensitivity (or removes deafness) | kelp | Damage amplification |
| **vardrax** | addiction | ginseng | Riftlock helper, eating triggers cooldown |
| **delphinium** | sleep | wake/insomnia | Sleeplock, prone via leg break |
| **epseth** | crippled leg (level 1) | mending | Limb pressure |
| **epteth** | crippled arm (level 1) | mending | Limb pressure |
| **voyria** | voyria (sip damage) | antidote | Lock aff for healers |
| **eurypteria** | recklessness | lobelia | Lock aff for Depthswalker |
| **digitalis** | shyness | goldenseal | Mental stack |
| **larkspur** | dizziness | goldenseal | Mental stack |
| **monkshood** | disloyalty | lobelia | Hinder loyalty-based abilities |
| **aconite** | stupidity | goldenseal | Mental stack, focus bait |
| **darkshade** | darkshade (light allergy) | ginseng | Hinder targeting |
| **notechis** | haemophilia | ginseng | Lock aff for Magi/Sylvan, Agony synergy |
| **sumac** | impatience | goldenseal | Truelock completion |
| **vernalius** | weakness | kelp | Hinder physical actions |
| **oleander** | blindness | smoke | Hinder targeting |
| **colocasia** | blindness + deafness | smoke + deafness | Full sensory denial |
| **loki** | random affliction | varies | Unpredictable pressure |

#### Hellforge Investments (Infernal Only)
| Investment | Affliction | Cure | Notes |
|------------|------------|------|-------|
| **INVEST TORTURE** | haemophilia | ginseng | Enables Agony passive healing |
| **INVEST EXPLOIT** | weariness + paranoia | kelp + ash | Two affs at once, blocks Fitness |
| **INVEST TORMENT** | healthleech | kelp | Sustained damage, confusion if already has healthleech |
| **INVEST PUNISHMENT** | scaling damage | n/a | More damage on wounded targets |

#### Affliction Locks

**See also**: `.claude/classes/lock_types.md` for comprehensive documentation.

##### Softlock (3 affs)
```yaml
afflictions:
  asthma: "Prevents smoking pipes - cured by eating Kelp"
  anorexia: "Prevents eating herbs - cured by applying Epidermal or Focus"
  slickness: "Prevents applying salves - cured by eating Bloodroot or smoking Valerian"
escape: "FOCUS to cure anorexia, then eat bloodroot, then eat kelp"
```

##### Venomlock (4 affs)
```yaml
afflictions: [paralysis, asthma, anorexia, slickness]
paralysis: "Prevents Tree tattoo - cured by eating Bloodroot"
escape: "FOCUS to cure anorexia, then eat bloodroot (cures para OR slick)"
```

##### Truelock / Hardlock (5 affs)
```yaml
afflictions: [paralysis, asthma, anorexia, slickness, impatience]
impatience: "Prevents using Focus - cured by eating Goldenseal"
escape: "None without external help"
requires: "Class-specific affliction to block passive cures"
```

##### Focuslock (Alternative to Truelock)
```yaml
afflictions: [paralysis, asthma, anorexia, slickness]
strategy: "Stack mental afflictions (goldenseal cures) instead of impatience"
mental_affs: [stupidity, dizziness, epilepsy, shyness, depression]
escape: "Focus may randomly cure anorexia instead of mental aff"
```

##### Riftlock (Limb-based)
```yaml
afflictions:
  broken_arms: "2 broken arms - prevents rifting herbs"
  slickness: "Prevents applying mending salve"
  asthma: "Prevents smoking valerian"
helper: "Addiction (Vardrax) forces eating held items"
escape: "Smoke valerian → mend arms → rift herbs"
```

##### Salvelock (Enhanced Riftlock)
```yaml
afflictions:
  mangled_arms: "Level 2+ breaks - prevents Restore ability"
  slickness: "Prevents applying mending"
  asthma: "Prevents smoking"
escape: "Very difficult - requires multiple mending applications"
```

##### Sleeplock (Timing-based)
```yaml
steps:
  1: "First Sleep/Delphinium strips Insomnia defence"
  2: "Second strips Gypsum/Kola defence"
  3: "Third puts opponent to sleep"
timing: "All three must hit in rapid succession"
```

##### Aeonlock (Time-manipulation)
```yaml
afflictions:
  aeon: "Only one action at a time on lengthy balance"
  asthma: "Prevents smoking Elm to cure aeon"
strategy: "Stack kelp affs to keep asthma stuck"
kelp_stack: [asthma, clumsiness, sensitivity, weariness, healthleech]
```

#### Class-Specific Lock Afflictions
| Classes | Extra Affliction | Blocks |
|---------|-----------------|--------|
| Knights, Monk, Serpent, Sentinel, Druid, Blademaster, Elemental Lords | Weariness | Various passive cures |
| Apostate, Pariah, Bard, Priest | Voyria | Sip-based healing |
| Magi, Sylvan | Haemophilia | Blood-based cures |
| Alchemist | Stupidity | Transmutation cures |
| Depthswalker | Recklessness | Shadow cures |
| Psion | Confusion | Mental cures |
| Jester, Occultist, Shaman | Paralysis | Already in base lock |

#### Server-Side Curing (SSC)
Achaea provides built-in curing that simulates average latency. Custom systems can integrate with or replace it.

**Core Commands:**
| Command | Description |
|---------|-------------|
| `CURING ON/OFF` | Enable/disable the system |
| `CURING STATUS` | Show current curing status |
| `CURING AFFLICTIONS ON/OFF` | Toggle affliction curing |
| `CURING DEFENCES ON/OFF` | Toggle defence upkeep |
| `CURING SIPPING ON/OFF` | Toggle health/mana sipping |
| `CURING SIPHEALTH/SIPMANA <percent>` | Set sip thresholds |
| `CURING FOCUS ON/OFF` | Toggle FOCUS ability usage |
| `CURING TREE ON/OFF` | Toggle TREE tattoo usage |
| `CURING BATCH ON/OFF` | Send multiple cures at once |

**Priority Management:**
| Command | Description |
|---------|-------------|
| `CURING PRIORITY LIST` | List affliction cure priority |
| `CURING PRIORITY <aff> <priority>` | Move affliction priority |
| `CURING PRIORITY RESET` | Reset to default priority |
| `CURING PRIORITY DEFENCE LIST` | List defence upkeep priority |

**Curingsets** (save/load priority configurations):
| Command | Description |
|---------|-------------|
| `CURINGSET NEW <name>` | Create new curingset |
| `CURINGSET SWITCH <name>` | Switch to a curingset |
| `CURINGSET LIST` | List all curingsets |
| `CURINGSET CLONE <from>` | Clone into current setup |

**Manual Queue:**
| Command | Description |
|---------|-------------|
| `CURING QUEUE ADD <cure>` | Add manual cure to queue |
| `CURING QUEUE LIST` | List queue contents |
| `CURING PREDICT <aff>` | Tell system you have an affliction |
| `CURING PRIOAFF <aff>` | Temporarily prioritise an affliction |

**Example Pattern (Ataxia style):**
```lua
ataxia.afflictions = ataxia.afflictions or {}

local function affsAdd()
  local aff = gmcp.Char.Afflictions.Add.name
  ataxia.afflictions[aff] = true
  raiseEvent("aff gained", aff)

  -- Special handling
  if aff == "amnesia" then
    send("touch flaws")
  elseif aff == "aeon" then
    send("curing batch off")
  end
end

registerAnonymousEventHandler("gmcp.Char.Afflictions.Add", affsAdd)
```

### Combat Strategies
Classes generally focus on one of two kill paths:

**Affliction-Based**: Stack afflictions to achieve a lock or kill condition
- Build toward Soft Lock → Tree Lock → True Lock
- Use class-specific affliction to complete the lock
- Examples: Serpent, Shaman, Apostate

### Serpent Combat System (Ekanelia + Impulse)

Modern Serpent combat revolves around two key mechanics:

**Impulse** - Instant mental affliction delivery when:
- Target has asthma AND weariness AND no fangbarrier
- Delivers impatience or anorexia instantly (no SNAP timing needed)

**Ekanelia** - BITE venom transformation that ADDS bonus afflictions:
| Venom | Conditionals Required | Normal + Bonus Effect |
|-------|----------------------|----------------------|
| kalmia | clumsiness + weariness | asthma + **slickness** |
| monkshood | asthma + masochism + weariness | disfigurement + **impatience** |
| curare | hypersomnia + masochism | paralysis + **hypochondria** |
| loki | confusion + recklessness | random + **nausea + paralysis** |
| scytherus | addiction + nausea | scytherus + **camus damage** |

**Fratricide** - Causes Impulse-delivered afflictions to RELAPSE after cure
- Combined with scytherus = ~1200 damage per relapse tick
- CRITICAL to cure early when fighting serpents

**Kill Routes**:
1. **True Lock**: asthma + slickness + paralysis + impatience + anorexia + weariness
2. **Darkshade Kill**: Keep darkshade stuck for 26 seconds (protected by ginseng stack)

**Defense Priority vs Serpent**:
1. Tree when Impulse enabled + mental affliction present
2. Re-apply fangbarrier (quicksilver) when stripped
3. Cure fratricide IMMEDIATELY when scytherus present
4. Block Ekanelia setups by curing masochism, clumsiness, or confusion early

**Key Files**: `.claude/classes/serpent.md`, `src_new/scripts/.../serpent/002_Ekanelia_Offense.lua`

**Limb Damage-Based**: Break limbs to enable killing blows
- Limbs track damage as percentage (0-200%+)
- **Level 1 break**: Limb reaches ~33% (damaged)
- **Level 2 break**: Limb reaches 100% (crippled/broken)
- **Level 3 break**: Limb reaches 200% before victim can apply restoration+mending (mangled)
- Cured with: Restoration salve (damage), Mending salve (breaks)
- Examples: Knights (2H spec), Monk, Blademaster

**Limbs**: Head, Torso, Left Arm, Right Arm, Left Leg, Right Leg

### Offensive System Development Guidelines

**CRITICAL**: Before coding ANY offensive combat system, agents MUST read:
1. `.claude/classes/lock_types.md` - Lock definitions and escape routes
2. `.claude/classes/<class>.md` - Target class kill routes and vulnerabilities
3. `.claude/classes/README.md` - Affliction stacking reference

**Lock knowledge is essential for:**
- Building toward softlock → venomlock → truelock
- Understanding which afflictions to prioritize
- Knowing gating requirements for key afflictions (e.g., paralysis needs nausea + weariness + asthma for Waterlord)
- Anticipating defender cure priorities and escape routes

**When creating offensive Lua files, include this header:**
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

### Balances
- **Balance**: Physical action cooldown (~2-4 seconds)
- **Equilibrium**: Mental action cooldown (~2-4 seconds)
- **Cure balances**: herb, salve, mineral, smoke, focus, tree, sip, moss
- **Class-specific**: kai (Monk), blood (Praenomen), devotion (Priest), etc.
- Tracked via GMCP (`gmcp.Char.Vitals.bal/eq`) and text triggers

**Example Pattern:**
```lua
ataxia.balance = ataxia.balance or {}
ataxia.balance.stopwatches = ataxia.balance.stopwatches or {}

function ataxia.balance.lost(bal)
  if not ataxia.balance.stopwatches[bal] then
    ataxia.balance.stopwatches[bal] = createStopWatch()
  end
  ataxia.bals[bal] = false
  startStopWatch(ataxia.balance.stopwatches[bal], true)
end

function ataxia.balance.regained(bal)
  ataxia.bals[bal] = true
  if ataxia.balance.stopwatches[bal] then
    local time = stopStopWatch(ataxia.balance.stopwatches[bal])
    cecho(" <dark_turquoise>(<plum>"..(math.floor(time*100)/100).."<dark_turquoise>)")
  end
end
```

### Server-Side Curing (SSC)
- Built-in Achaea curing system
- Configurable via `CURING` commands
- Can be integrated with custom systems

```lua
-- Initialize with custom curingset
send("curingset new ataxia", false)
send("curingset switch ataxia", false)
send("curing priority defence list reset", false)
```

### Queue System
- Achaea has built-in ability queuing
- Commands: `QUEUE ADD`, `QUEUE INSERT`, `QUEUE PREPEND`
- Executes on balance recovery
- Multiple queue types (bal, eq, eqbal, free)

---

## Development Guidelines

### Namespace Pattern
```lua
-- All system code under namespaces
ataxia = ataxia or {}
ataxia.afflictions = ataxia.afflictions or {}
ataxia.balance = ataxia.balance or {}
ataxia.defense = ataxia.defense or {}

mmp = mmp or {}
mmp.settings = mmp.settings or {}

ataxiagui = ataxiagui or {}
ataxiaNDB = ataxiaNDB or {}
```

### Initialization Pattern
```lua
function ataxia.initialize()
  -- Setup file paths
  ataxia.filepath = getMudletHomeDir() .. "/AtaxiaSaves"
  if not io.exists(ataxia.filepath) then
    lfs.mkdir(ataxia.filepath)
  end

  -- Request GMCP data
  sendGMCP([[ Core.Supports.Add [ "Comm.Channel 1" ] ]])
  sendGMCP([[ Core.Supports.Add ["IRE.Target 1"] ]])
  sendGMCP("IRE.Rift.Request")
  sendGMCP("Char.Items.Inv")

  -- Initialize subsystems
  ataxia.loadSettings()
  ataxia.balance.reset()

  raiseEvent("ataxia system loaded")
end

registerAnonymousEventHandler("gmcp.Char.Name", "ataxia.initialize")
```

### Event-Driven Architecture
```lua
-- Raise custom events for inter-module communication
raiseEvent("aff gained", "paralysis")
raiseEvent("aff lost", "paralysis")
raiseEvent("ataxia system loaded")

-- Other modules listen
registerAnonymousEventHandler("aff gained", "updateUI")
```

### Echo/Debug Pattern
```lua
function ataxia.echo(text)
  cecho("\n<dark_orchid>[<light_slate_blue>Ataxia<dark_orchid>]<lavender>: <plum>" .. text)
end

function ataxia.decho(text)
  if ataxia.debug then
    ataxia.echo(text)
  end
end

-- Quiet commands (no echo)
function ataxia.quietSend(command)
  send(command, false)
end
```

---

## Testing Approach

### Mock GMCP Data
```lua
gmcp = gmcp or {}
gmcp.Char = gmcp.Char or {}
gmcp.Char.Vitals = {bal="1", eq="1", hp=5000, maxhp=5000}
gmcp.Char.Afflictions = {List = {}}
```

### Performance Considerations
- **Sub-second response times critical**
- Optimize trigger patterns (use specific strings over wildcards)
- Cache frequently accessed data
- Minimize table creation in hot paths (balance/prompt triggers)
- Use stopwatches for precise timing
- Avoid expensive operations in prompt triggers

---

## Common Pitfalls & Solutions

### Pitfall: Trusting Combat Messages
```lua
-- BAD: Assuming affliction was applied
if matches[1]:find("You jab") then
  target.affs.paralysis = true  -- They might have shrugging!
end

-- GOOD: Track attempts, confirm with diagnose/death messages
if matches[1]:find("You jab") then
  target.affAttempts.paralysis = true
end
```

### Pitfall: Not Handling Blackout
```lua
-- BAD: Assuming vitals are accurate
if ataxia.vitals.hp < 1000 then
  sip health
end

-- GOOD: Check for blackout first
if not ataxia.afflictions.blackout and ataxia.vitals.hp < 1000 then
  sip health
end
```

### Pitfall: Hardcoded Timing
```lua
-- BAD: Assuming 2s balance
tempTimer(2.0, function() doNextAttack() end)

-- GOOD: Use stopwatches and balance regain events
function ataxia.balance.regained("bal")
  doNextAttack()
end
```

---

## GMCP Data Reference

### Vitals (fires on prompt)
```lua
gmcp.Char.Vitals = {
  hp = "5000",
  maxhp = "5000",
  mp = "4500",
  maxmp = "4500",
  bal = "1",  -- "1" = have balance, "0" = don't have
  eq = "1",
  charstats = {"Endurance: 18500/18500", "Willpower: 18500/18500", ...}
}
```

### Afflictions
```lua
gmcp.Char.Afflictions.List = {
  {name = "asthma", cure = "kelp"},
  {name = "clumsiness", cure = "kelp"}
}
gmcp.Char.Afflictions.Add = {name = "paralysis", cure = "bloodroot"}
gmcp.Char.Afflictions.Remove = {"asthma"}
```

### Room Info
```lua
gmcp.Room.Info = {
  num = 12345,
  name = "A dark alley",
  area = "Ashtan"
}
```

---

## Important Considerations

### Things to Remember
- Achaea has 26 classes (21 base + 4 Elemental Lords + Dragon) with unique mechanics
- Server-side curing exists but custom systems provide advantages
- Illusions and hidden afflictions are common (use diagnosis)
- Combat logs can be several hundred lines per second
- System must handle disconnections/reconnections gracefully
- Blackout hides all vitals and afflictions (special handling required)
- Aeon/retardation slow down actions (disable batching)
- Some afflictions prevent certain actions (paralysis, stun, etc.)

### Things to Avoid
- Hardcoded delays (server-side timing varies by ping)
- Assuming affliction order from attacks
- Trusting all game output without verification (illusions exist)
- Over-automating (ToS compliance concerns)
- Blocking the main thread with heavy processing
- Creating tables in hot paths (prompt/vitals triggers)
- Using wildcards excessively in triggers
- Global variable pollution (use namespaces)

---

## Resources & References

- **Achaea Wiki**: https://wiki.achaea.com/
- **Mudlet Documentation**: https://wiki.mudlet.org/
- **Lua 5.1 Reference**: https://www.lua.org/manual/5.1/
- **Achaea API**: http://api.achaea.com
- **IRE Mapping Script Wiki**: http://wiki.mudlet.org/w/IRE_mapping_script
- **Achaea Forums**: https://forums.achaea.com/

---

## Questions to Ask When Developing

### Correctness
- Does this handle illusions correctly?
- What happens during blackout?
- How does aeon/retardation affect this?
- Does it work when stunned/asleep/dead?

### Performance
- Is this timing-sensitive code optimized?
- Are we creating unnecessary tables?
- Should this be cached?
- Can triggers be more specific?

### Compatibility
- Does this work for all classes or just one?
- Are there class-specific edge cases?
- How does this behave with different artifacts?

### Reliability
- How does this behave when offline/reconnecting?
- What if GMCP data is delayed?
- Is there graceful degradation?
- Are errors handled properly?

---

## Infernal DWC Vivisect Combat System

### Overview
The Infernal DWC Vivisect system provides automated combat for the Dual Wield Cutting (DWC) specialization, targeting the vivisect instant kill.

### Key File
`src_new/scripts/levi_ataxia/levi/levi_scripts/dwc/003_Infernal_DWC_Vivisect.lua`

### Vivisect Kill Requirements
```yaml
vivisect_requirement: "All 4 limbs at level 1+ break"

break_levels:
  level_1:
    sources: ["epteth venom (arms)", "epseth venom (legs)"]
    effect: "Withered state - counts for vivisect"
    cure: "Single restoration (4s salve balance)"

  level_2:
    sources: ["Physical damage 100%+", "Undercut on prepped leg"]
    effect: "Broken/crippled - also counts for vivisect"
    cure: "Restoration (4s) + Mending (4s) = 8s minimum"

key_mechanic: |
  Epteth/epseth venoms give level 1 breaks to NON-TARGETED limbs!
  DSL right arm with epteth/epseth:
    - Physically breaks right arm (level 2)
    - Epteth gives level 1 to LEFT arm
    - Epseth gives level 1 to RIGHT leg
```

### Phase Progression
| Phase | Description | Entry Condition |
|-------|-------------|-----------------|
| **NAUSEA_SETUP** | Apply nausea to bypass parry | Start phase |
| **PREP** | Build limb damage to 90%+ | Nausea stuck |
| **EXECUTE** | Break limbs with undercut + DSL | Both arms + left leg at 90%+ |
| **KILL** | Vivisect | Left leg broken + right arm broken |
| **RIFTLOCK** | Lock mode (counter to RESTORE) | Target uses RESTORE |

### Execute Sequence (Optimized 2-Attack Kill)
```
Step 0: UNDERCUT left leg (battleaxe)
  → Breaks leg (level 2)
  → 4 second salve lock
  → Invest exploit for paranoia + weariness

Step 1: DSL right arm epteth epseth (scimitars)
  → Breaks right arm (level 2)
  → Epteth gives left arm level 1
  → Epseth gives right leg level 1
  → All 4 limbs now at level 1+

KILL: VIVISECT
```

### Key Helper Functions
| Function | Purpose |
|----------|---------|
| `infernalDWC.getPhase()` | Determines current combat phase |
| `infernalDWC.selectVenoms()` | Selects venoms based on phase |
| `infernalDWC.selectLimbTarget()` | Chooses limb to attack |
| `infernalDWC.advanceExecuteStep()` | Tracks execute sequence progress |
| `infernalDWC.getFocusArm()` | Returns arm with lower damage |
| `infernalDWC.isFocusLegPrepped()` | Checks if left leg at 90%+ |

### RIFTLOCK Mode
Activated when target uses RESTORE (heals all limbs). Counter-strategy:
- Break arms (prevents rifting herbs)
- Stick anorexia + slickness + addiction
- Maintain paralysis

### Commands
| Command | Purpose |
|---------|---------|
| `infernalDWCVivisect()` | Main dispatch function |
| `infernalDWCStatus()` | Display current state |
| `infernalDWCReset()` | Reset all state |
| `infernalDWC.enterRiftlock()` | Enter riftlock mode |
| `infernalDWC.exitRiftlock()` | Exit riftlock mode |

### Configuration
```lua
infernalDWC.config = {
    prepThreshold = 90,      -- Limb % to consider "prepped"
    breakThreshold = 100,    -- Limb % to consider "broken"
    weapon1 = "scimitar405403",
    weapon2 = "scimitar405398",
    battleaxe = "battleaxe590991",
}
```

### Documentation
See `.claude/classes/infernal.md` for complete DWC vivisect strategy documentation.

---

## Blademaster Combat System

### Strategies Available

| Strategy | Command | Description |
|----------|---------|-------------|
| **Double-Prep** | `bmd` | Legs only - prep both legs, double-break, mangle |
| **Quad-Prep** | `bmdq` | Arms + legs - prep all 4, break arms, break legs, mangle |
| **Brokenstar** | `bmbs` | Upper + legs + impale route - instant kill at 700 bleed |

### Brokenstar Kill Route (bmbs)

```
1. UPPER PREP: Centreslash up/down to get torso+head to 90%+
2. LEG PREP: Legslash alternating to get both legs to 90%+
3. UPPER BREAK: Centreslash up/down to break torso+head (100%+)
4. LEG BREAK: Legslash + KNEES to break legs and prone
5. IMPALE: Impale the prone target
6. IMPALESLASH: Slash arteries for bleeding
7. BLADETWIST: Twist until 700+ bleeding (discern on 3rd)
8. WITHDRAW: Withdraw blade (or skip if writhed free)
9. BROKENSTAR: Execute instant kill
```

### Dynamic Centreslash Direction

The system auto-selects UP or DOWN to balance torso/head damage:
- **UP**: Torso = primary (18.1%), Head = secondary (12.1%)
- **DOWN**: Head = primary (18.1%), Torso = secondary (12.1%)
- Always hits the **LOWER** limb as primary (like `getFocusLeg()` for legs)

### Key Helper Functions

| Function | Purpose |
|----------|---------|
| `blademaster.getFocusLeg()` | Returns "left" or "right" based on lower leg |
| `blademaster.getCentreslashDirection()` | Returns "up" or "down" based on lower limb |
| `blademaster.checkWillPrepBothLegs()` | True if next hit preps both legs to 90%+ |
| `blademaster.checkWillPrepUpper()` | True if next centreslash preps both torso/head |

### Documentation
See `.claude/classes/blademaster.md` for complete documentation.

---

## Lessons Learned (Combat System Development)

### Mudlet Trigger Patterns

**Problem**: Strict regex anchors (`^` and `$`) can fail in Mudlet due to line processing quirks.

```lua
-- BAD: May not match due to anchors
"^You observe .+ \\[(\\d+)\\]$"

-- GOOD: More flexible, still specific
"You observe .+ \\[(\\d+)\\]"
```

**Best Practices**:
- Avoid `^` and `$` unless absolutely necessary
- Use `.+` (one or more) instead of `.*` (zero or more) when content is expected
- Test patterns against actual game output before deploying

### Counter Incrementing (Button Spam Issue)

**Problem**: Incrementing counters in dispatch/combo builder functions causes them to increment on every button press, not just when the action fires.

```lua
-- BAD: In buildComboBrokenstar() - called every button press
blademaster.state.bladetwistCount = blademaster.state.bladetwistCount + 1
combo = "bladetwist;discern " .. target

-- GOOD: Use trigger to increment when action actually fires
blademaster.bladetwistTriggerID = tempRegexTrigger(
  "BLADETWIST \\[\\|\\] BLADETWIST \\[\\|\\] BLADETWIST",
  function()
    blademaster.state.bladetwistCount = blademaster.state.bladetwistCount + 1
  end
)
```

### Limb Balancing Strategy

**Problem**: When attacking two limbs with asymmetric damage, one limb reaches threshold before the other.

**Solution**: Always hit the **LOWER damage limb as primary** to balance progression.

```lua
function blademaster.getFocusLeg()
  local LL = blademaster.getLL()
  local RL = blademaster.getRL()
  return (LL <= RL) and "left" or "right"
end

function blademaster.getCentreslashDirection()
  local torso = blademaster.getTorso()
  local head = blademaster.getHead()
  return (head <= torso) and "down" or "up"
end
```

### Mounted Target Handling

**Problem**: KNEES on a mounted target DISMOUNTS instead of PRONING.

**Solution**: Dismount on the final prep hit (before double-break), then KNEES on double-break will properly prone.

```lua
if phase == "leg_prep" then
  -- Dismount during final prep hit if mounted + hamstrung
  if tmounted and tAffs.hamstring and blademaster.checkWillPrepBothLegs() then
    return "knees"  -- Dismount now
  end
  return blademaster.selectPrepStrike()
end
```

### Phase Transition Triggers

**Problem**: State-based phase transitions fail when triggers don't capture values correctly.

**Best Practices**:
1. Use simple, robust trigger patterns for critical state updates
2. Log trigger fires during debugging to verify they're matching
3. Have fallback phase logic when triggers miss
4. Always update both state flags and values (e.g., `bleedingReady = true` AND `targetBleeding = value`)

### Writhe/Escape Handling

**Problem**: Target escaping (writhe from impale, standing from prone) should preserve progress.

**Best Practices**:
1. On writhe: Keep `bleedingReady` and `targetBleeding` - don't reset progress
2. Check if target is still prone after writhe (free re-impale!)
3. If bleeding >= 700 and not impaled, can go directly to brokenstar

```lua
function blademaster.onTargetUnimpaled()
  blademaster.state.isImpaled = false
  -- Keep bleedingReady and targetBleeding - we built that progress!

  if tAffs.prone then
    cecho("[BM] Target writhed free but STILL PRONE - FREE RE-IMPALE!")
  elseif blademaster.state.bleedingReady then
    -- Go to brokenstar phase (checked in getPhaseBrokenstar)
  end
end
```

---

**Last Updated**: 2026-01-20
**Project Lead**: Michael
**Development Environment**: VS Code + Mudlet + Claude Code
**Reference Systems**: Orion, Ataxia
