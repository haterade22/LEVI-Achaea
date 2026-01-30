# Apostate

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Damage
- **Difficulty**: Medium
- **Lock Affliction**: Voyria (blocks immunity elixir sip, cured first by Demon Syphon)

## Skills
```
Evileye: Gaze-based affliction application (delivers ALL lock afflictions)
Necromancy: Death magic, corpse manipulation, and Daegger Hunt
Apostasy: Demon summoning (Baalzadeen) and unholy powers
```

## Core Combat Mechanics
```yaml
combat_style: "Affliction-heavy momentum-based class"

evileye_afflictions:
  description: "Can deliver ALL lock afflictions via Evileye alone"
  lock_affs: [asthma, anorexia, paralysis, impatience]
  slickness_note: "Requires manaleech to be present to deliver slickness"

instakill:
  name: "Catharsis"
  condition: "Target at 50% mana or below"
  counter: "Prioritize sipping mana over health"

passive_cure:
  name: "Demon Syphon"
  tick: "Every 10 seconds"
  priority: "Always cures voyria FIRST if present"
  counter: "Time voyria application to land right after syphon tick"
```

## Daemonic Entities
```yaml
baalzadeen:
  description: "Primary demon companion, always with Apostate"
  abilities:
    syphon: "Passive cure every 10 seconds"
    restore: "Heal Apostate's health and mana (uses balance)"
    apathy: "Apostate takes no damage, then 60% of total when ends"
    trace: "Track target's movements (useful vs serpents)"
    strip: "Remove defenses"
    sear: "Fire damage"
    beckon: "Pull targets from adjacent rooms"
    catharsis: "Instakill at 50% mana"
  notes: "All abilities consume Baalzadeen's health"

bloodworms:
  description: "Summoned in room and adjacent rooms"
  afflictions: [masochism, dizziness, damage]
  trigger: "Activates when you are UNDEAF"
  counter: "Keep deafness up"

fiend:
  description: "Bleeding-focused entity (mutually exclusive with Nightmare/Daemonite)"
  effects:
    - "Applies bleeding"
    - "Applies haemophilia"
  synergy: "Combines with Daegger Hunt for massive bleed"
  danger: |
    Low bleeding builds up, then haemophilia applied.
    When you cure haemophilia, you've built up 600+ bleeding.
    Clotting drains mana significantly -> Catharsis range.
  counter: "Curseward or leave room when bleeding exceeds 500"

nightmare:
  description: "Sleep-focused entity (mutually exclusive with Fiend/Daemonite)"
  afflictions: [hypersomnia, dementia, hellsight]
  kill_route: "Opens sleep lock potential (rarely used, unreliable)"
  counter: |
    Put metawake up when afflicted with hypersomnia (if not low mana).
    Drop metawake when hypersomnia cured.
    Warning: Metawake has high mana drain.

daemonite:
  description: "Hinder-focused entity (mutually exclusive with Fiend/Nightmare)"
  effect: "Throws you off balance periodically"
  usage: "Mostly used as group combat hinder"
  counter: "Leave room"
```

## Kill Routes

### Primary Kill: Catharsis (Mana Kill)
```yaml
type: execute
summary: Drain mana to 50%, then Catharsis for instant kill

prerequisites:
  - Target must be at 50% mana or below
  - Baalzadeen must be present

steps:
  1: "Apply afflictions via Evileye to pressure curing"
  2: "Use Fiend + Daegger Hunt for bleeding pressure"
  3: "Target clots bleeding, draining mana"
  4: "Apply manaleech for additional mana drain"
  5: "When target at 50% mana, CATHARSIS <target>"

notes: "Primary kill method - always watch target's mana"
```

### Alternative Kill: Affliction Lock
```yaml
type: affliction
summary: Use Evileye to deliver all lock afflictions

steps:
  1: "Apply asthma via Evileye (blocks smoking)"
  2: "Apply anorexia via Evileye (blocks eating)"
  3: "Apply manaleech (required for slickness delivery)"
  4: "Apply slickness via Evileye (blocks applying)"
  5: "Apply paralysis via Evileye (blocks tree)"
  6: "Apply impatience via Evileye (blocks focus)"
  7: "Apply voyria for class-specific lock"
  8: "Damage to death or Catharsis"

required_afflictions:
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying (needs manaleech first)"
  - paralysis: "blocks tree"
  - impatience: "blocks focus"
  - voyria: "blocks immunity, but cured first by Syphon"
```

### Alternative Kill: Corrupt Burst
```yaml
type: damage
summary: Stack afflictions then Corrupt for massive damage

prerequisites:
  - Target must have many afflictions
  - Works best with Int spec (Grook Apostates)

steps:
  1: "Stack afflictions via Evileye and entities"
  2: "Include afflictions from allies if in group"
  3: "CORRUPT <target>"
  4: "Damage scales with TOTAL afflictions (not just Evileye)"
  5: "Follow up with Catharsis if not dead"

mechanics:
  - "Removes only Evileye-given afflictions"
  - "Damage scales based on ALL afflictions target has"
  - "Example: 5 Evileye affs + 3 entity affs = damage scales on 8"

notes: "Risky but viable, especially for Int spec Grook Apostates"
```

### Alternative Kill: Bleed Out (Fiend + Daegger)
```yaml
type: damage
summary: Stack bleeding through Fiend and Daegger Hunt

steps:
  1: "Summon Fiend"
  2: "Use Daegger Hunt for additional bleeding"
  3: "Fiend applies haemophilia to prevent clotting"
  4: "Bleeding builds rapidly"
  5: "Target dies to bleed or mana drain from clotting -> Catharsis"

notes: "Synergy between Fiend and Daegger Hunt is very effective"
```

## Offensive Abilities
```yaml
# Evileye
evileye:
  skill: Evileye
  balance: eq
  effect: "Apply affliction via gaze"
  syntax: "EVILEYE <target> <affliction>"
  afflictions:
    - asthma: "EVILEYE ASTHMA"
    - anorexia: "EVILEYE ANOREXIA"
    - slickness: "EVILEYE SLICKNESS (needs manaleech)"
    - paralysis: "EVILEYE PARALYSE"
    - impatience: "EVILEYE IMPATIENCE"
    - manaleech: "EVILEYE MANALEECH"
    - many_more: "Various mental/physical afflictions"

# Necromancy
daegger_hunt:
  skill: Necromancy
  balance: eq
  effect: "Causes bleeding, synergizes with Fiend"
  syntax: "DAEGGER HUNT <target>"
  notes: "Rebounding hinders this slightly"

soulspear:
  skill: Necromancy
  balance: eq
  effect: "Drain life from target"
  damage_type: magic
  syntax: "SOULSPEAR <target>"

# Apostasy
summon:
  skill: Apostasy
  balance: eq
  effect: "Summon daemonic entity"
  syntax: "SUMMON <entity>"
  entities: [baalzadeen, bloodworms, fiend, nightmare, daemonite]

catharsis:
  skill: Apostasy
  balance: eq
  effect: "Instant kill at 50% mana"
  syntax: "CATHARSIS <target>"
  notes: "Main execute - watch target mana!"

corrupt:
  skill: Apostasy
  balance: eq
  effect: "Massive damage based on affliction count"
  syntax: "CORRUPT <target>"
  notes: "Removes Evileye affs, damage scales on ALL affs"

beckon:
  skill: Apostasy
  balance: eq
  effect: "Pull targets from adjacent rooms"
  syntax: "BECKON" or "BECKON <target>"
  blocked_by: [offbalance, prone, being_blocked]
  notes: "Can beckon everyone or specific target"

gravehands:
  skill: Apostasy
  balance: eq
  effect: "Strong movement hinder"
  syntax: "GRAVEHANDS"
  counters: [evade, swing, aerial, "move 2 rooms away"]
```

## Defensive Abilities
```yaml
demon_syphon:
  skill: Apostasy
  effect: "Passive cure every 10 seconds"
  priority: "Always cures voyria FIRST"
  notes: "Time voyria to land right after syphon"

apathy:
  skill: Apostasy
  effect: "Take no damage, then 60% of total when ends"
  syntax: "ORDER BAALZADEEN APATHY"
  notes: "Trades immediate damage for reduced total"
```

## Passive Cures
```yaml
demon_syphon:
  cures: [various, voyria_first]
  tick: "Every 10 seconds"
  notes: "Always prioritizes curing voyria first"
```

## Limb Strategy
```yaml
enabled: false
notes: "Apostate is affliction/mana-based, not limb-based"
```

## Bashing (PvE)
```yaml
attack_command: "ORDER BAALZADEEN ATTACK <target>"
attack_skill: Apostasy
battlerage_abilities:
  - baalzadeen_attack: "Demon damage"
  - soulspear: "Magic damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - paralysis: "Cure first to maintain offensive pressure"
  - asthma: "Critical for smoking ability"
  - manaleech: "Prevents slickness delivery + drains mana"
  - slickness: "Restore salve application"
  - anorexia: "Restore eating ability"
  - haemophilia: "Prevent bleed buildup (cure before 500+ bleeding)"

dangerous_abilities:
  - catharsis: "INSTANT KILL at 50% mana - prioritize mana sipping!"
  - gravehands: "Strong movement hinder"
  - corrupt: "Massive burst damage based on affliction count"
  - fiend_daegger: "Bleed + haemophilia combo"
  - beckon: "Pulls from adjacent rooms"

avoid:
  - "Being below 50% mana (Catharsis range)"
  - "Letting bleeding build above 500 with haemophilia"
  - "Being undeaf near bloodworms"
  - "Standing in gravehands when you can escape"
  - "Having too many mental afflictions vs Int spec Apostate"

use_instead_of_shield: |
  CURSEWARD is better than shield when close to lock.
  Shield is not useless but well-timed curseward hinders more.
  Lower paralysis priority when curseward is up.

escape_strategy: |
  Gravehands counter: Evade, Swing up into trees, Aerial, etc.
  Normal movement has low success chance but try anyway.
  Once out, move 2 ROOMS away to avoid Beckon (only works adjacent).

rebounding: "Keep rebounding up - hinders Daegger Hunt slightly"

disloyalty: |
  If stacked properly (behind asthma), disloyalty can disrupt
  their entity-dependent offense significantly.

recommended_strategy: |
  PRIORITIZE SIPPING MANA over health - Catharsis kills at 50% mana!
  Keep deafness up to avoid Bloodworm afflictions.
  Cure paralysis first to maintain pressure.
  Watch for asthma + manaleech combo (slickness incoming).
  Curseward when close to lock instead of shield.
  If bleeding builds with haemophilia active, curseward or flee.
  Move 2 rooms away when escaping gravehands to avoid beckon.
  Time voyria application right after Demon Syphon tick (10s).
```

## Implementation Notes
```
Triggers to watch for:
- "Summoning up the curse of X" - Deadeyes curse (439_NEW_DEADEYES.lua)
- "fixes you with an icy stare" - Evileye affliction incoming
- "A fiendish * appears" - demon summoned
- "Baalzadeen syphons" - passive cure tick (10s cycle)
- "Gravehands burst from the ground" - movement hinder
- "beckons" - being pulled from adjacent room
- "corrupts you" - massive damage incoming
- "catharsis" - instant kill attempt (check mana!)
- "Bloodworms" - keep deafness up
- Fiend bleeding messages
- Daegger Hunt bleeding messages

Deadeyes Curse Mappings (439_NEW_DEADEYES.lua):
- clumsy → clumsiness
- stupid → stupidity
- dizzy → dizziness
- plague → voyria
- sicken → manaleech (first), slickness (if manaleech present)
- vomiting → nausea
- reckless → recklessness
- paralysis → paralysis
- sleep → hypersomnia
- bleed → haemophilia

GMCP considerations:
- Track gmcp.Char.Afflictions for current affs
- CRITICAL: Track gmcp.Char.Vitals.mp for Catharsis threshold
- Demon presence via room items
- Bleeding amount tracking important

Edge cases:
- Evileye is eq-based, entity orders vary
- Demon Syphon ALWAYS cures voyria first (10s tick)
- Slickness requires manaleech to be present first
- Corrupt removes only Evileye afflictions but damage scales on ALL
- Beckon blocked by offbalance, prone, or being blocked
- Beckon only works on adjacent rooms - move 2 away to escape
- Curseward > Shield when near lock
- Apathy: No damage during, then 60% of total at end
- Fiend/Nightmare/Daemonite mutually exclusive (only one in room)
- Bloodworms only trigger when undeaf

Catharsis Threshold:
- INSTANT KILL at 50% mana
- Always prioritize mana sipping
- Clotting bleeding drains mana significantly
- Watch for Fiend + Daegger bleed -> clot -> mana drain -> Catharsis
```

---

## CC_Apostate System (015_CC_Apostate.lua)

### Architecture
The Apostate offensive system was consolidated from 14 legacy files into a single `apostate` namespace following the Blademaster pattern. Files 001-013 are all disabled (`isActive: 'no'`). File 014 retains backward-compat wrappers and daemon utility functions.

### File Map
| File | Purpose |
|------|---------|
| `015_CC_Apostate.lua` | Complete unified system — namespace, state, V3 routing, curse engine, attack builder, dispatch |
| `014_Levi_Apostate.lua` | Backward-compat wrappers (all old function names → `apostate.dispatch()`) + daemon utilities |
| `001-013_*.lua` | Legacy files, all disabled |

### Entry Point
```lua
apostate.dispatch()
-- 1. Validate target exists and is in room
-- 2. Check for aeon (don't act)
-- 3. Initialize pm (target mana) if not set
-- 4. Select curses via dual-slot engine
-- 5. Build attack (pre + main + post)
-- 6. Ensure baalzadeen is summoned
-- 7. Check for paralysis (don't send if paralyzed)
-- 8. Assemble and send via queue addclear freestand
```

### Namespace & State
```lua
apostate = apostate or {}
apostate.state = {
  mode = "lock",            -- "lock", "corrupt", "vivisect", "sleep", "group"
  corrupted = false,        -- corrupt has been fired (awaiting catharsis)
  lastCorruptTime = 0,      -- corrupt cooldown tracking
  daeggerhere = false,      -- daegger summoned
  freshblood = false,       -- fresh blood available for bloodpact
  fiendthing = "nightmare", -- preferred lesser daemon
  wantDisloyalty = false,   -- disfigure toggle
  partyrelay = true,        -- relay to party
}

apostate.config = {
  corruptThreshold = 0.7,   -- V3 probability threshold for corrupt consideration
  lockThreshold = 0.3,      -- V3 threshold for "has affliction"
  catharsisThreshold = 50,  -- mana % for catharsis execute
  sapThreshold = 60,        -- mana % for sap consideration
  debugEcho = false,        -- enable debug output
}
```

### Kill Routes (4 Modes)
| Mode | Description | Kill Condition |
|------|-------------|----------------|
| **lock** | DEADEYES dual-curse delivery building toward truelock + class lock | Truelock → voyria → damage/catharsis |
| **corrupt** | Stack afflictions → `demon corrupt` for burst damage | Corrupt dmg >= assessed health, or mana pushed to catharsis range |
| **vivisect** | Truelock → trample prone → shrivel all 4 limbs → vivisect | All limbs broken while truelocked |
| **sleep** | Build asthma + impatience + hypersomnia → sleep curse | Hypersomnia + sleep curse with asthma/impatience protecting it |

### Dual-Slot Curse Priority Engine
DEADEYES delivers 2 curses per action (2.3s balance). Each slot has an independent priority chain:

**Curse 1 (`selectPrimaryCurse`)** — Direct affliction stacking:
```
clumsiness → asthma → manaleech → impatience → slickness → anorexia
→ sleep mode curses / nightmare synergy / sensitivity (when deaf)
→ fillers (stupidity, dizziness, weariness, nausea, confusion, etc.)
→ class lock affliction → fallback: clumsy
```

**Curse 2 (`selectSecondaryCurse(c1)`)** — Sicken cascade + lock support:
```
sicken (delivers paralysis when target lacks it)
→ impatience → asthma
→ sicken again (delivers manaleech/slickness when asthma blocks smoke cure)
→ anorexia → slickness → manaleech
→ fillers (skipping whatever c1 is)
→ class lock affliction → fallback
```

**Key rules:**
- Curse 2 never duplicates curse 1 — the `c1` parameter is checked at every step
- Sicken cascade: delivers `paralysis → manaleech → slickness` in order based on what target has
- First sicken use: paralysis (for tree block)
- Second sicken use: after asthma secured, delivers manaleech/slickness (asthma protects smoke cure)

**Orchestrator (`selectCurses`):**
- Curseward detected → breach + secondary
- Truelock >= 70% → class lock aff + secondary
- Otherwise → primary + secondary

### Lock Progression
```
softlock  = asthma + anorexia + slickness
hardlock  = softlock + impatience
truelock  = hardlock + paralysis
classlock = truelock + voyria
```

### Attack Builder Priority
Kill condition checks in order:
1. `needVivisect()` — All 4 limbs broken → vivisect
2. `needShieldStrip()` — Catharsis/corrupt ready but target shielded
3. `needTrample()` — Truelocked + target prone → trample
4. `needCatharsis()` — Target mana below `catharsisThreshold`
5. `needCorrupt()` — Corrupt damage >= assessed health, or pushes mana to catharsis range
6. Corrupt followup — Corrupt already fired → follow with catharsis
7. `needShrivel()` — Vivisect mode, truelocked, prone, limbs remaining
8. Default: DEADEYES dual-curse delivery

### Corrupt Damage Calculator
```lua
function apostate.corruptDmg()
  -- Categorizes afflictions into physical, mental, smoke
  -- Physical affs × 7 + Mental affs × 8 + Smoke affs × 9
  -- V3 mode: weights each affliction by probability (0.0-1.0)
  -- V1/V2 mode: binary 1.0 or 0 per affliction
  -- Returns expected damage value for kill-condition checks
end
```

### V3/V2/V1 Tracking Integration
Same routing chain as Blademaster (`blademaster.hasAff`):
```lua
function apostate.hasAff(aff)
  -- V3: haveAffV3(aff) with lockThreshold (0.3)
  -- V2: haveAffV2(aff) or tAffsV2[aff]
  -- V1: tAffs[aff]
end

function apostate.getAffProb(aff)
  -- V3: getAffProbabilityV3(aff) returns 0.0-1.0
  -- Fallback: binary 1.0 or 0
end

function apostate.getTrackingSystem()
  -- Returns "V3", "V2", or "V1"
end

function apostate.getLocks()
  -- Returns {softlock=prob, hardlock=prob, truelock=prob}
  -- V3: getLockStatusV3()
  -- Fallback: boolean check of required afflictions
end
```

### Pre/Post Attack Actions
**Pre-attack:**
- Bloodpact setup (fresh blood + no pentagram active)
- Daegger summon when catharsis/prone situations require it

**Post-attack:**
- Bloodworm summon (when fresh blood available)
- Daemon resummon (when wrong daemon type present)
- Disfigure for disloyalty (when asthma is held)

**Design decision:** Daegger hunt was intentionally removed from commands — it slows offense when seconds matter.

### Backward Compatibility (014_Levi_Apostate.lua)
All old function names route to `apostate.dispatch()` with appropriate mode:

| Legacy Function | Mode |
|-----------------|------|
| `leviclumsapo()` | lock |
| `leviweariapo()` | lock |
| `levisleepapo()` | sleep |
| `apostate_lock()` | lock |
| `apostate_lockattack()` | (current) |
| `apostate_lockImpale()` | lock |
| `apostate_sleepattack()` | sleep |
| `apostate_clumsy()` | lock |
| `apostate_vivisect()` | vivisect |
| `apostate_weari()` | lock |
| `apostate_mental()` | lock |
| `apostate_kelp()` | lock |
| `apostate_group()` | group |
| `apostate_clumsyillusion()` | lock |

Legacy global wrappers kept: `corruptDmg()`, `corruptKill()`, `cathCorrupt()`

### Daemon Utilities (014_Levi_Apostate.lua)
These functions remain in 014 and are called by the attack builder:

| Function | Purpose |
|----------|---------|
| `bloodPact()` | Bloodpact setup (fresh blood + no pentagram) |
| `bloodworm()` | Summon bloodworms (post-attack) |
| `baalzadeen()` | Ensure Baalzadeen summoned |
| `apopentagram()` | Pentagram setup |
| `demon()` | Summon preferred lesser daemon |
| `daemonite()` | Summon daemonite entity |
| `fiend()` | Summon fiend entity |
| `nightmare()` | Summon nightmare entity |

### Commands (Aliases)
| Alias | Regex | Action |
|-------|-------|--------|
| `cath` | `^cath$` | `apostate_lock()` → dispatch (lock) |
| `KELP STACK` | `^kel$` | Class-conditional dispatch (lock) |
| `Group Attack` | `^yy$` | `apostate_group()` → dispatch (group, currently disabled) |
| `Levi Lock Apo` | `^ll$` | `apostate_lock()` → dispatch (lock) |
| `Vivisect` | `^viv$` | `apostate_vivisect()` → dispatch (vivisect) |
| `SLEEP` | `^slee$` | `apostate_sleepattack()` → dispatch (sleep) |
| `Corrupt` | `^corr$` | `apostate.setMode("corrupt")` → dispatch (corrupt) |

### Debug & Status
```lua
apostate.status()
-- Displays: mode, tracking system, corrupt damage estimate,
-- lock probabilities (soft/hard/true), current curse selections,
-- daemon type, corrupted state, target mana, last assess value
```

### Changelog
- **v1.0** (Jan 2025): Consolidated 14 files → single `015_CC_Apostate.lua`
- Integrated V3 affliction tracker (probability-based decisions)
- All classes use clumsiness route (no weariness split)
- Dual-slot curse engine with sicken cascade
- Removed daegger hunt from attack commands
- Added corrupt damage calculator with V3 weighting
- Backward-compat wrappers in 014 for all legacy function names
