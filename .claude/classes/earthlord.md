# Earthlord

## Metadata
- **Type**: Elemental Lord
- **Combat Style**: Limb | Execute
- **Difficulty**: Hard
- **Lock Affliction**: Weariness (blocks Eruption passive cure)

## Skills
```
Subjugation: Elemental dominion and control
Manifestation: Elemental body transformation (Earth Form)
Evocation: Earth elemental attacks, shaping, calcify
```

## Core Combat Mechanics
```yaml
shaping:
  description: "Momentum resource - nearly everything requires shaping levels"
  max_level: 4
  gain: "Each hit attempt gives 1 shaping (even if parried or clumsy miss)"
  usage:
    quake: "Requires 2 shaping, costs 1 shaping at max level"
    calcify: "Balanceless at max shaping"
    powderise_leg: "Prones target at max shaping"
    powderise_torso: "Off-balance scales with shaping"

limb_damage:
  hits_to_break: 5
  max_shaping_bonus: "Limb damage DOUBLED at max shaping"

parry_bypass:
  ability: "Quake"
  requirement: "2 shaping minimum"
  at_max_shaping: "Balanceless but consumes 1 shaping"
  effect: "Prones all in location"

offense_style: |
  Earth Lord offense is entirely dependent on breaking limbs properly
  and abusing enemy salve balance priorities.
  No affliction hinder or alternative pressure - pure limb damage.
```

## Kill Routes

### Primary Kill: Calcify Head
```yaml
type: execute
summary: Break legs to prone, calcify head, avalanche to level 2, instant kill

mechanics:
  calcify:
    description: "Restoration-cured affliction lasting ~5 seconds"
    if_not_cured: "Increases limb damage level OR kills outright"
    targets: [head, torso]
    at_max_shaping: "Balanceless"

  head_kill:
    requirement: "Level 2 head break when calcify completes"
    result: "Instant death"

prerequisites:
  - Prep both legs and head
  - Need 3 shaping if using Quake bypass
  - Need max shaping if breaking legs directly

steps:
  with_quake_bypass:
    1: "Prep both legs and head to near-break"
    2: "At 3 shaping: QUAKE (prones, consumes 1 shaping, leaves you at 2)"
    3: "Break RIGHT LEG"
    4: "Break LEFT LEG"
    5: "CALCIFY HEAD + break head (they apply to right leg)"
    6: "AVALANCHE (increases head damage from level 1 to level 2)"
    7: "Calcify completes with level 2 head = death"

  without_quake:
    1: "Prep both legs and head to near-break"
    2: "At max shaping: Break RIGHT LEG (prones from powderise)"
    3: "Break LEFT LEG"
    4: "CALCIFY HEAD + break head"
    5: "AVALANCHE"
    6: "Calcify completes = death"

timing_note: |
  Enemy applies restoration to right leg right before you get balance
  for calcify/break head. This timing allows calcify to complete
  without any issue since they used salve balance on leg.
```

### Alternative Kill: Calcify Torso (Squeeze)
```yaml
type: execute
summary: Level 2 torso break + calcify torso = SQUEEZE kill

mechanics:
  squeeze:
    description: "Instant kill on calcified torso with level 2 break"
    requirement: "Calcify on torso AND level 2 torso damage"

prerequisites:
  - Must get level 2 torso break
  - Calcify must land on torso
  - Abuse salve priorities to land calcify

steps:
  1: "Prep torso and other limbs"
  2: "Use salve priority manipulation (break other limbs)"
  3: "Get level 2 torso damage"
  4: "CALCIFY TORSO"
  5: "When calcify completes, SQUEEZE"

notes: |
  Harder to execute than head route.
  Good for catching unaware targets off guard.
  Requires understanding of enemy salve priorities.
```

### Alternative Kill: Entomb (Environmental)
```yaml
type: execute
summary: Fissure prone target into ground, entomb at half health

requirements:
  - Burrowable environment (not all rooms work)
  - Target must be prone
  - Target must be under 50% health for Entomb
  - Does NOT work in arena

steps:
  1: "Prone target (Quake or Powderise Leg at max shaping)"
  2: "FISSURE (force-burrows prone target)"
  3: "If they don't BURROW ABOVE, use BURY for damage"
  4: "When under 50% health, ENTOMB for instant kill"

notes: |
  Very fun if you can pull it off.
  Requires good timing and awareness.
  Limited by environment type.
  Will not work in arena.
```

## Group Combat Tactics
```yaml
role: "Quick limb breaks and calcify pressure"

primary_tactics:
  - "Use prepping attacks for quick breaks"
  - "Increased prone time from powderise"
  - "Calcify often to force target off salve balance (assists locks)"
  - "Focus on quick breaks and damage"

calcify_note: |
  Given Earth's speed, unlikely to land Calcify kills in group.
  Still possible but focus on pressure.

bellow:
  description: "Group skill - similar to Silence vibration"
  effect: "Reduces enemy guard movements"
  mechanic: "Requires channel - you can do NOTHING but speak while channeling"
  warning: "Any action disrupts the channel, dropping the silence"
  usage: "Negate guard summons for your team"
```

## Offensive Abilities
```yaml
# Primary Attacks
powderise:
  skill: Evocation
  balance: bal
  effect: "Primary prepping attack with limb-specific effects"
  syntax: "POWDERISE <target> <limb>"
  limb_effects:
    head: "Small stun"
    torso: "Knocks off balance (scales with shaping)"
    arm: "Breaks arm (mending cure)"
    leg: "Prones target at MAX shaping"
  notes: "5 hits to break any limb, doubled at max shaping"

quake:
  skill: Evocation
  balance: bal
  effect: "Prone all in location - PRIMARY PARRY BYPASS"
  syntax: "QUAKE"
  requirements: "2 shaping minimum"
  at_max_shaping: "Balanceless but costs 1 shaping level"
  notes: "Critical for setting up calcify kills"

calcify:
  skill: Evocation
  balance: bal
  effect: "Restoration-cured aff, increases limb damage or kills if not cured"
  syntax: "CALCIFY <target> <limb>"
  targets: [head, torso]
  duration: "~5 seconds"
  at_max_shaping: "Balanceless"
  notes: "All kills come from Calcify"

avalanche:
  skill: Evocation
  balance: bal
  effect: "Increases head damage level"
  syntax: "AVALANCHE <target>"
  notes: "Vital for securing Calcify Head kill (level 1 -> level 2)"

squeeze:
  skill: Evocation
  balance: bal
  effect: "Kill target with calcified level 2 torso"
  syntax: "SQUEEZE <target>"
  requirement: "Calcified torso with level 2 damage"

# Environmental Kills
fissure:
  skill: Evocation
  balance: bal
  effect: "Force-burrow prone target"
  syntax: "FISSURE <target>"
  requirement: "Target must be prone, burrowable room"

bury:
  skill: Evocation
  balance: bal
  effect: "Damage to burrowed target"
  syntax: "BURY <target>"

entomb:
  skill: Evocation
  balance: bal
  effect: "Instant kill burrowed target under 50% health"
  syntax: "ENTOMB <target>"
  requirement: "Target burrowed, under 50% health"
  notes: "Does NOT work in arena"

# Utility
crunch:
  skill: Evocation
  balance: bal
  effect: "Break shield"
  syntax: "CRUNCH <target>"

rockslide:
  skill: Evocation
  balance: eq
  effect: "Creates rubble, makes leaving room harder"
  syntax: "ROCKSLIDE"

demolition:
  skill: Evocation
  balance: eq
  effect: "Destroys all stonewalls in room"
  syntax: "DEMOLITION"
  notes: "Balance time increases with walls destroyed"

bellow:
  skill: Evocation
  balance: eq
  effect: "Channel that reduces enemy guard movements"
  syntax: "BELLOW"
  mechanic: "Channel - can only speak, any action drops it"
  notes: "Group utility to negate guard summons"

# Movement
coalesce:
  skill: Evocation
  balance: eq
  effect: "Return to Earth Plane or Prime"
  syntax: "COALESCE"
```

## Defensive Abilities
```yaml
eruption:
  skill: Evocation
  balance: free
  effect: "Active heal, cures random affliction"
  syntax: "ERUPTION"
  balanceless: true
  blocked_by: [weariness]
  notes: "Class-specific passive cure blocked by weariness"

extrusion:
  skill: Evocation
  effect: "Mimics Vitality - health boost when health is low"
  notes: "Passive defensive"

reform:
  skill: Evocation
  balance: eq
  effect: "Active health boost"
  syntax: "REFORM"

strata:
  skill: Evocation
  effect: "Resistant to all damage types"
  syntax: "STRATA"
  notes: "Defensive skill for tanking"

titan:
  skill: Evocation
  effect: "Apex of Earth Form - IMPERVIOUS to damage"
  syntax: "TITAN"
  notes: "Ultimate defensive ability"

tremorsense:
  skill: Evocation
  effect: "See entry/exits of people on ground in your area"
  syntax: "TREMORSENSE"
  limitation: "Does NOT detect fliers"
  notes: "Similar to Mindnet defense"

juggernaut:
  skill: Evocation
  balance: eq
  effect: "Drop totem propper and bring group, bypassing totems"
  syntax: "JUGGERNAUT"
  notes: "Group utility for totem bypass"

stonewalls:
  skill: Evocation
  effect: "Create stone walls"
  syntax: "STONEWALLS"
```

## Passive Cures
```yaml
eruption:
  cures: [random_affliction]
  blocked_by: [weariness]
  trigger: "Active ability, balanceless"
  notes: "Weariness is the class-specific lock affliction"
```

## Limb Strategy
```yaml
enabled: true
primary_targets: [head, left_leg, right_leg]

limb_mechanics:
  hits_to_break: 5
  max_shaping_bonus: "Damage DOUBLED at max shaping"
  powderise_effects:
    head: "Small stun"
    torso: "Off-balance (scales with shaping)"
    arm: "Arm break (mending)"
    leg: "Prone at max shaping"

calcify_targets:
  head: "Level 2 + calcify = death (use avalanche)"
  torso: "Level 2 + calcify = squeeze kill"

strategy: |
  Primary strategy is Calcify Head:
  1. Prep both legs and head
  2. Break legs (prone target)
  3. Calcify head + avalanche
  4. Calcify completes with level 2 head = death

  Use Quake for parry bypass (requires 2 shaping).
  At max shaping, powderise leg prones directly.
  Salve priority manipulation is KEY to landing calcify.
```

## Bashing (PvE)
```yaml
attack_command: "POWDERISE <target> <limb>"
attack_skill: Evocation
battlerage_abilities:
  - powderise: "Limb damage"
  - quake: "Room prone"
```

## Fighting Against This Class
```yaml
priority_cures:
  - calcified_limb: "APPLY RESTORATION - 5 second timer or die/increased damage"
  - broken_legs: "APPLY RESTORATION - prevents prone setup"
  - broken_head: "APPLY RESTORATION - head + calcify = death"
  - weariness: "EAT KELP - restores their Eruption cure"
  - prone: "STAND - prevents calcify setup"

dangerous_abilities:
  - calcify: "5 second restoration cure or limb damage increases/death"
  - avalanche: "Increases head damage for calcify kill"
  - squeeze: "Instant kill on calcified level 2 torso"
  - quake: "Room-wide prone, parry bypass"
  - entomb: "Instant kill at 50% health if burrowed"
  - titan: "Impervious to damage"

avoid:
  - "Having both legs broken (prone setup)"
  - "Letting calcify complete without curing"
  - "Being prone in burrowable room (entomb risk)"
  - "Extended fights (they're very tanky)"
  - "Ignoring head prep (calcify head kills)"

calcify_counter:
  duration: "~5 seconds"
  cure: "APPLY RESTORATION to calcified limb"
  if_not_cured: "Limb damage increases OR instant death"
  priority: "HIGHEST PRIORITY cure when calcified"

recommended_strategy: |
  CURE CALCIFY IMMEDIATELY - you have ~5 seconds or die.
  Watch for leg breaks - they're setting up prone for calcify.
  Watch head prep - calcify head + avalanche = death.
  If both legs prepped, they're going for the kill.
  Quake at 2+ shaping = prone for their setup.
  At max shaping, powderise leg prones without quake.
  They have no affliction hinder - pure limb damage class.
  Apply weariness to block their Eruption cure.
  Very tanky class - Strata resists all damage, Titan is impervious.
  In burrowable rooms, don't get fissured at low health (entomb).
```

## Implementation Notes
```
Triggers to watch for:
- "powderises your *" - limb being prepped
- "Your * is damaged/broken" - track limb state
- "calcifies" - CRITICAL - 5 second cure timer
- "quake" - prone incoming
- "avalanche" - head damage increasing
- "squeezes" - torso kill attempt
- "fissure" - being forced underground
- "entombs" - instant kill attempt
- "bellow" - guard movement silenced
- Shaping level indicators

GMCP considerations:
- Track gmcp.Char.Afflictions for calcify
- Limb damage percentages critical
- Prone state tracking
- 5 hits to break, doubled at max shaping

Edge cases:
- Calcify lasts ~5 seconds, restoration cure
- If not cured: increases limb damage OR kills
- Quake requires 2 shaping, costs 1 at max level
- Calcify is balanceless at max shaping
- Quake is balanceless at max shaping (costs 1 level)
- Limb damage doubled at max shaping
- Each hit gives 1 shaping (even parried/missed)
- Max shaping = 4
- Powderise leg prones at max shaping
- Avalanche critical for head kill (level 1 -> 2)
- Entomb requires burrowable room, doesn't work in arena
- Titan = impervious to damage (apex ability)
- Eruption blocked by weariness (class lock aff)
- Bellow requires channel - any action drops it

Kill Requirements:
- Calcify Head: Level 2 head when calcify completes = death
- Calcify Torso: Level 2 torso + calcify = squeeze kill
- Entomb: Burrowed + under 50% health = death

Shaping Levels:
- 0: No shaping abilities
- 1: Basic attacks
- 2: Quake unlocked (parry bypass)
- 3: Enhanced attacks
- 4 (max): Calcify balanceless, Quake balanceless, limb damage doubled

Typical Kill Sequence:
1. Prep legs + head (5 hits each, or less at max shaping)
2. At 3+ shaping: Quake (prone, now at 2 shaping)
3. Break right leg, break left leg
4. Calcify head + break head
5. Avalanche (head level 1 -> 2)
6. Calcify completes = death
```
