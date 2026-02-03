# Depthswalker

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Damage | Mana Kill
- **Difficulty**: Hard
- **Lock Affliction**: Recklessness (blocks Accelerate passive cure)

## Skills
```
Aeonics: Time manipulation, retardation, aeon, timeloop
Shadowmancy: Shadow manipulation, instills, affliction delivery
Terminus: Death/void powers, mutilate, dictate, room hinders
```

## Core Combat Mechanics

### Attack Pattern
The standard DW attack sequence:
```
shadow attune <target> to <attune>
shadow instill scythe with <instill>
chrono assert|chrono loop [boost]
shadow reap <target> [venom]
```

### Dual-Slot System
Unlike some classes, DW has **two independent affliction delivery methods per attack**:
- **Instill slot**: Delivers DW-specific stacking afflictions
- **Venom slot**: Delivers standard venom afflictions via shadow reap

When using **chrono loop**, the venom slot is sacrificed for double instill application (timeloop aff + doubled instill effect).

### Instill System
```yaml
description: "Primary DW affliction delivery via weapon instill"
syntax: "shadow instill <weapon> with <instill_type>"

valid_instills:
  - degeneration
  - depression
  - retribution
  - madness
  - leach
  - impatience

IMPORTANT: "timeloop is NOT an instill - it comes from chrono loop command"
```

### Instill Stacks (Affliction Progression)
Each instill type gives afflictions in a specific order. If target already has an affliction, the next one in the stack is applied:

```yaml
degeneration:
  stack: [clumsiness, weariness, paralysis]
  cure: kelp
  capstone: "Damage burst"
  notes: "Capstone damage is HALVED without shadow claimed"

depression:
  stack: [depression, nausea, hypochondria]
  cure: goldenseal
  capstone: "depression + anorexia + masochism (all three)"
  notes: "Masochism causes self-damage when target cures"

retribution:
  stack: [justice, retribution]
  cure: bellwort
  capstone: "Mana sap"
  notes: "Both justice and retribution are bellwort-cured"

madness:
  stack: [shadowmadness, vertigo, hallucinations]
  cure: ash
  capstone: "Stun"
  notes: "Stun provides window for depression capstone"

leach:
  stack: [parasite, healthleech, manaleech]
  cure: kelp (healthleech, manaleech) / goldenseal (parasite)
  capstone: "Enables shadow claim"
  notes: "healthleech and manaleech are kelp-cured - need kelp pressure first!"

impatience:
  stack: [impatience]
  cure: goldenseal
  capstone: none
  notes: "Direct affliction, no stack. ONLY way DW can give impatience"
```

### Chrono Commands
```yaml
chrono_assert:
  effect: "Standard attack timing"
  usage: "Default when not using timeloop"

chrono_loop:
  effect: "Applies timeloop affliction + doubles instill effect"
  requirement: "Age < 250 years (unboosted)"
  usage: "Fast affliction stacking"

chrono_loop_boost:
  effect: "Same as chrono loop but works at any age"
  requirement: "None (boosted version)"
  usage: "Critical for healthleech→manaleech transition"
  notes: "Costs 10 lessons in Aeonics to unlock"
```

### Timeloop Mechanics
```yaml
description: "Timeloop doubles the instill affliction delivery"

when_to_use:
  - "CRITICAL: When healthleech stuck but not manaleech - use chrono loop boost"
  - "Building toward capstone (3-4 DW affs)"
  - "Lock mode when rushing affliction count"
  - "Bellwort phase to apply timeloop affliction"

important: |
  Timeloop is NOT an instill. It comes from chrono loop command.
  When chrono loop fires, target gets timeloop affliction AND
  the instill effect is doubled (2 afflictions from the stack).
```

### Bellwort Stack Strategy
```yaml
description: "Bury target with bellwort-cured afflictions"

bellwort_affs:
  - timeloop: "From chrono loop"
  - justice: "From instill retribution (first stack)"
  - retribution: "From instill retribution (second stack)"

strategy: |
  All three are bellwort-cured. Target can only eat bellwort once
  per balance, so with 3 bellwort affs, 2 remain stuck at all times.
  This creates massive DW aff pressure toward capstone.

how_to_apply:
  - "Use chrono loop to apply timeloop"
  - "Use instill retribution to get justice (first)"
  - "Use instill retribution again to get retribution (second)"
```

### Shadow Resource
```yaml
description: "Critical resource for executes and damage"

how_to_claim:
  - "Stack leach afflictions: parasite → healthleech → manaleech"
  - "When all 3 present + capstone ready (5 DW affs): leach capstone fires"
  - "After leach capstone: SHADOW CLAIM <target>"

trigger_pattern: "^You claim the shadow of (\\w+), storing it within your phylactery.$"
trigger_message: "You claim the shadow of <target>, storing it within your phylactery."

usage:
  - "Required for Mutilate execute"
  - "Enhances damage (degeneration capstone HALVED without shadow)"

global_variable: "haveshadow (set by triggers)"
```

## Kill Routes

### Lock Route
```yaml
type: affliction
summary: "Build toward truelock with bellwort stack + standard lock affs"

phases:
  1_kelp:
    description: "Stick clumsiness for kelp pressure"
    instill: degeneration
    venom: curare
    chrono: assert
    notes: "They must cure paralysis (curare) instead of clumsiness"

  2_shadow:
    description: "Build leach stack toward shadow claim"
    instill: leach
    venom: curare
    chrono: "loop boost when healthleech stuck"
    notes: "healthleech/manaleech are kelp-cured - need kelp pressure first!"

  3_bellwort:
    description: "Bury target with bellwort affs"
    instill: retribution (for justice, then retribution)
    venom: varies
    chrono: "loop when timeloop missing"
    notes: "3 bellwort affs = 2 always stuck"

  4_lock:
    description: "Standard lock progression"
    instill: depression/impatience
    venom: kalmia → gecko → curare → slike
    notes: "Impatience ONLY via instill"

required_afflictions:
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying"
  - paralysis: "blocks tree"
  - impatience: "blocks focus (ONLY via instill)"
  - recklessness: "blocks Accelerate passive cure"
```

### Damage Route
```yaml
type: damage
summary: "Claim shadow, then spam degeneration for capstone damage"

IMPORTANT: "Degeneration capstone damage is HALVED without shadow!"

phases:
  1_kelp:
    description: "Spam degeneration + curare for kelp pressure"
    instill: degeneration
    venom: curare
    chrono: assert
    notes: "Need clumsiness stuck before going for leach"

  2_shadow:
    description: "Build leach stack toward shadow claim"
    instill: leach
    venom: "curare (default) / kalmia (when healthleech stuck)"
    chrono: "loop boost when healthleech stuck"
    notes: |
      Critical timing: When healthleech stuck, switch to kalmia.
      Asthma blocks herb cure, so manaleech will stick.
      Use chrono loop boost to double-apply leach.

  3_damage:
    description: "Shadow claimed - spam degeneration"
    instill: degeneration
    venom: curare
    chrono: assert
    notes: "Full capstone damage with shadow"

venom_strategy: |
  - Default: curare for paralysis pressure
  - When healthleech stuck: kalmia to block herb cure for manaleech
```

### Dictate Route (Mana Kill)
```yaml
type: execute
summary: "Drain mana with retribution capstone, execute with dictate"

threshold_formula: "40% + (5% × DW_affliction_count)"

threshold_examples:
  0_affs: "40% mana"
  3_affs: "55% mana"
  5_affs: "65% mana"
  7_affs: "75% mana"

strategy:
  1: "Build bellwort stack (adds 3 DW affs)"
  2: "Stack additional DW affs (depression, madness, degeneration)"
  3: "Use retribution capstone for mana sap"
  4: "When mana below threshold: SHADOW DICTATE <target>"
```

### Madpression Route
```yaml
type: combo
summary: "Madness capstone (stun) → Depression capstone (anorexia + masochism)"

strategy:
  1: "Build to 5 DW afflictions"
  2: "Fire madness capstone → target stunned"
  3: "Fire depression capstone → target gets masochism"
  4: "Target cures while stunned → takes masochism damage"
  5: "Continue pressure or finish with damage/execute"

notes: |
  Very effective burst strategy.
  Masochism causes damage when target cures.
  Stun provides free window to apply depression capstone.
```

## Offense Implementation (015_CC_Depthswalker.lua)

### Namespace Structure
```lua
depthswalker = depthswalker or {}

depthswalker.state = {
    mode = "lock",           -- lock/damage/dictate/madpression/group
    haveShadow = false,      -- synced from global 'haveshadow'
    distorted = false,       -- synced from global 'depdistort'
}

depthswalker.config = {
    lockThreshold = 0.3,             -- V3 probability threshold
    highConfidence = 0.7,            -- for truelock detection
    scytheId = "scythe20431",        -- weapon ID
    cullHealthThreshold = 35,        -- HP% for cull
    mutilateHealthThreshold = 40,    -- HP% for mutilate
    mutilateManaThreshold = 30,      -- MP% for mutilate
    debugEcho = false,               -- show debug info
}

depthswalker.DW_AFFS = {
    "depression", "retribution", "parasite", "madness",
    "degeneration", "healthleech", "manaleech", "justice", "timeloop"
}
```

### V3 Integration
```lua
-- Routes to V3 when enabled, falls back to V2/V1
function depthswalker.hasAff(aff)
    if affConfigV3 and affConfigV3.enabled and haveAffV3 then
        return haveAffV3(aff)
    end
    -- V2/V1 fallback...
end

-- Get probability from V3 (for threshold decisions)
function depthswalker.getAffProb(aff)
    if affConfigV3 and affConfigV3.enabled and getAffProbabilityV3 then
        return getAffProbabilityV3(aff)
    end
    return depthswalker.hasAff(aff) and 1.0 or 0.0
end
```

### Key Functions
```lua
-- Main entry point
depthswalker.dispatch()

-- Mode setter
depthswalker.setMode(mode)  -- "lock", "damage", "dictate", "madpression", "group"

-- Status display
depthswalker.status()

-- Selection functions
depthswalker.selectInstill()     -- returns instill type
depthswalker.selectVenom()       -- returns venom name
depthswalker.shouldTimeloop()    -- returns true/false
depthswalker.getChronoCommand()  -- returns "chrono assert"/"chrono loop"/"chrono loop boost"
```

### Aliases
```
dw          - depthswalker.dispatch()
dwm <mode>  - depthswalker.setMode(matches[2])
dws         - depthswalker.status()
dwd         - toggle debugEcho
```

### Global Variables Used
```lua
target          -- current target name
haveshadow      -- shadow claimed (set by triggers)
depdistort      -- distort active (set by triggers)
envenomList     -- populated by dispatch() with selected venom
php             -- target health %
pm              -- target mana %
```

## Trigger Integration

### envenomList Pattern
The offense populates `envenomList` before attacking. Triggers read this to know which venom was applied:

```lua
-- In dispatch():
envenomList = {}
if not depthswalker.selections.useTimeloop and depthswalker.selections.venom then
    table.insert(envenomList, depthswalker.selections.venom)
end

-- In triggers:
local venomName = (envenomList and envenomList[1]) or "unknown"
```

### V3 Tracking in Triggers
Triggers should call both V1/V2 tracking AND V3:
```lua
tarAffed("affliction")
if applyAffV3 then applyAffV3("affliction") end
```

## Capstones
```yaml
description: "When 5+ DW afflictions present, next instill triggers capstone"

trigger_condition: "depthswalker.capstoneReady() returns true when 5+ DW affs"

capstone_type: "Matches the instill type being used"

capstones:
  degeneration: "Damage burst (HALVED without shadow!)"
  depression: "depression + anorexia + masochism"
  madness: "Stun"
  retribution: "Mana sap"
  leach: "Enables shadow claim"
```

## Room Hinder Abilities
```yaml
distort:
  skill: Terminus
  effect: "Room-wide hinder"
  syntax: "DISTORT"
  notes: "Slows enemy movement/actions in room"

preempt:
  skill: Terminus
  effect: "Prevents fleeing"
  syntax: "PREEMPT"
  notes: "Keeps target in room for kills"

retardation:
  skill: Aeonics
  effect: "Create retardation field - extreme action slow"
  syntax: "RETARDATION"
  notes: "Room-wide slow effect, dangerous for everyone"
```

## Defensive Abilities
```yaml
accelerate:
  skill: Aeonics
  effect: "Passive cure for DW"
  blocked_by: [recklessness]
  notes: "Class-specific passive cure"

shift:
  skill: Shadowmancy
  effect: "Shadow movement ability"
  syntax: "SHIFT <direction>"
  notes: "Escape mechanism"

rewind:
  skill: Aeonics
  effect: "Revert to previous state"
  syntax: "REWIND"
  notes: "Powerful defensive reset"
```

## Fighting Against This Class
```yaml
priority_cures:
  - aeon: "SMOKE ELM - extremely important!"
  - asthma: "Restore smoking for aeon cure"
  - timeloop: "Doubles their affliction output"
  - recklessness: "Restores Accelerate if you're DW"
  - paralysis: "Maintain ability to tree/act"
  - masochism: "Prevents self-damage when curing"

dangerous_abilities:
  - mutilate: "Instant kill at 40% HP / 30% MP with shadow"
  - dictate: "Mana kill at 40% + 5% per DW aff"
  - aeon: "Slows ALL actions significantly"
  - chrono_loop_boost: "Doubles affliction application"
  - madness_capstone: "Stun at 5 DW affs"
  - depression_capstone: "Anorexia + masochism at 5 DW affs"

watch_for:
  - "5+ DW afflictions = capstone ready"
  - "Shadow claimed = Mutilate possible"
  - "High DW aff count = lower Dictate threshold"
  - "Bellwort stack (timeloop+justice+retribution) = sustained pressure"
```

## Limb Strategy
```yaml
enabled: false
notes: "Depthswalker is affliction-based, not limb-based"
```

## Bashing (PvE)
```yaml
attack_command: "BATTLERAGE SHADOWSTRIKE <target>"
attack_skill: Shadowmancy
```
