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
│   └── commands/           # Custom Claude Code slash commands
├── docs/
│   └── plans/              # Project plans and reviews
├── CLAUDE.md               # This file
└── README.md               # Project readme
```

### Proposed Modular Architecture
```
/
├── core/           # System initialization, event handling, state management
│   ├── init.lua           # Main initialization sequence
│   ├── events.lua         # Event handler registration
│   ├── state.lua          # Global state management
│   └── config_loader.lua  # Configuration loading
├── tracking/       # Affliction, balance, defense, cooldown tracking
│   ├── afflictions.lua    # Affliction tracking with GMCP integration
│   ├── balances.lua       # Balance/equilibrium tracking with stopwatches
│   ├── defenses.lua       # Defense up/down tracking
│   ├── cooldowns.lua      # Ability cooldown management
│   └── vitals.lua         # HP/MP/EP/WP tracking
├── curing/         # Curing logic, priorities, herb/mineral/salve management
│   ├── priorities.lua     # Dynamic priority system
│   ├── precache.lua       # Rift/inventory precaching
│   ├── queue.lua          # Server queue integration
│   └── ssc_integration.lua # Server-side curing settings
├── offense/        # Combat offense, ability queuing, target tracking
│   ├── classes/           # Class-specific offense modules
│   ├── targeting.lua      # Target selection and tracking
│   ├── queue.lua          # Ability queue management
│   └── combos.lua         # Pre-defined attack sequences
├── ui/             # Gauges, status windows, combat displays
│   ├── gauges.lua         # Health/mana/balance gauges
│   ├── affliction_display.lua
│   └── combat_log.lua
├── config/         # Configuration files, class-specific settings
│   ├── settings.lua       # User preferences
│   ├── class_configs/     # Per-class configurations
│   └── aliases.lua        # System aliases
├── docs/           # Development documentation
└── tests/          # Test files and mock data
```

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
- **Limb Tracking**: `selfLimbDamage` for damage percentages, `tLimbs` for enemy tracking
- **Fracture Management**: Two-handed combat tracking
- **Defense Management**: Automatic parrying, SSC integration
- **Basher**: `ataxiaBasher` for automated hunting
- **Class Modules**: Pariah, Bard, Monk, Magi, Two-Handed
- **Shikudo Dispatch System**: Full auto-combat for Monk/Shikudo spec
  - `200_Shikudo.lua` - V1 system (balanced leg prep, both legs 90%+)
  - `201_Shikudo_V2.lua` - V2 system (focus fire one leg, clumsy first)
  - Commands: `shikudo.dispatch()`, `shikudov2.dispatch()`, `skstatus()`, `skv2status()`

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
| Serpent | Masters of venoms and subterfuge | Subterfuge, Venom, Hypnosis |
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

**Last Updated**: 2025-12-25
**Project Lead**: Michael
**Development Environment**: VS Code + Mudlet + Claude Code
**Reference Systems**: Orion, Ataxia
