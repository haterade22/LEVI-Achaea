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
```yaml
combat_style: "Affliction-heavy with multiple kill routes"

instill_system:
  description: "Primary affliction delivery method"
  mechanics:
    - "Delivers ONE affliction per instill (in order of instill list)"
    - "Cannot deliver an affliction target already has"
    - "Can give impatience only via Instill (no other DW ability)"
  syntax: "INSTILL <target> <affliction1> <affliction2> ..."
  example: "INSTILL person paralysis asthma anorexia"
  notes: |
    Best to put afflictions you REALLY want to land at the end.
    If target has first 3, the 4th gets delivered.

envenom:
  description: "Secondary affliction delivery via weapon"
  usage: "Use with scimitars for additional affliction pressure"

timeloop:
  description: "Doubles instill affliction delivery"
  unboosted:
    effect: "Instill gives 2 afflictions at once"
    limitation: "Character must be under 250 years old"
  boosted:
    effect: "Instill gives 2 afflictions at once (any age)"
    cost: "10 lessons in Aeonics to unlock boosted version"
  priority: "Critical skill - makes locking MUCH faster"

shadow_resource:
  description: "Built through combat, enables executes"
  claim_shadow: "CLAIM SHADOW FROM <target> after Leach capstone"
  usage: "Powers Mutilate and enhances damage"
```

## Instill Capstones
```yaml
description: "When 5 Depthswalker afflictions are on target, next instill triggers capstone"

capstones:
  degeneration:
    effect: "Damage burst"
    notes: "Best for damage-focused strategies"

  depression:
    effect: "Gives anorexia AND masochism"
    notes: "Masochism makes target hurt themselves when curing"
    combo: "Pair with Madness for guaranteed damage"

  madness:
    effect: "Stun target"
    notes: "Free affliction/damage window while stunned"
    combo: "Madness -> Depression -> damage while stunned + masochism"

  retribution:
    effect: "Saps target's mana"
    notes: "Setup for Dictate mana kill"

  leach:
    effect: "Allows you to CLAIM SHADOW FROM <target>"
    notes: "Must claim shadow for Mutilate execute"

capstone_strategy: |
  Depression + Madness combo is powerful:
  1. Stack 5 DW afflictions
  2. Hit Madness capstone (target stunned)
  3. Hit Depression capstone (target gets masochism)
  4. Target cures while stunned = taking damage from masochism
```

## Attune System
```yaml
description: "Passive effect you can maintain"
duration: "160 seconds"
options:
  degeneration:
    effect: "Passive damage ticks"
    usage: "General damage pressure"
  madness:
    effect: "Unknown passive effect"
    usage: "May provide affliction pressure"

notes: "Choose attune based on kill route"
```

## Kill Routes

### Primary Kill: Mutilate (Shadow Execute)
```yaml
type: execute
summary: Instant kill when target below 40% health AND 30% mana with shadow claimed

prerequisites:
  - Target must be below 40% health
  - Target must be below 30% mana
  - Must have shadow claimed from target (via Leach capstone)

steps:
  1: "Stack 5 DW afflictions on target"
  2: "Hit Leach capstone to enable shadow claim"
  3: "CLAIM SHADOW FROM <target>"
  4: "Pressure health below 40% and mana below 30%"
  5: "MUTILATE <target>"

notes: |
  Requires significant setup with shadow claim.
  Health/mana thresholds must both be met.
  Alternative to truelock when opponent is slippery.
```

### Alternative Kill: Dictate (Mana Kill)
```yaml
type: execute
summary: Instant kill based on mana threshold that scales with DW afflictions

prerequisites:
  - Target mana threshold: 40% + 5% per DW affliction on target
  - Example: 5 DW afflictions = 65% mana threshold

steps:
  1: "Stack as many DW afflictions as possible"
  2: "Use Retribution capstone for mana sap"
  3: "Track target's mana and DW aff count"
  4: "When mana below threshold, DICTATE <target>"

threshold_examples:
  0_affs: "40% mana"
  3_affs: "55% mana"
  5_affs: "65% mana"
  7_affs: "75% mana"

notes: |
  Easier threshold than Mutilate but requires affliction stacking.
  Retribution capstone helps drain mana.
  Watch for enemy sipping mana.
```

### Alternative Kill: Damage with Shadow
```yaml
type: damage
summary: Use shadow and Degeneration attune for sustained damage

steps:
  1: "ATTUNE DEGENERATION for passive damage"
  2: "Stack afflictions for pressure"
  3: "Use Degeneration capstone for burst damage"
  4: "Apply sensitivity to increase damage"
  5: "Kill through accumulated damage"

notes: "Less common than lock/execute routes but viable"
```

### Alternative Kill: Truelock
```yaml
type: affliction
summary: Use instills and timeloop to overwhelm curing toward true lock

steps:
  1: "Apply afflictions via INSTILL (use timeloop for 2 at once)"
  2: "Stack asthma, anorexia, slickness"
  3: "Apply paralysis to block tree"
  4: "Apply impatience via instill (ONLY way DW gives impatience)"
  5: "Apply recklessness to block Accelerate"
  6: "Damage to death through lock"

required_afflictions:
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying"
  - paralysis: "blocks tree"
  - impatience: "blocks focus (ONLY via instill)"
  - recklessness: "blocks Accelerate passive cure"

notes: |
  Timeloop makes this MUCH faster (2 affs per instill).
  Impatience can ONLY come from instill - plan accordingly.
  Recklessness is critical to stop their passive cure.
```

### Madness + Depression Combo
```yaml
type: damage
summary: Combo capstones for guaranteed damage

steps:
  1: "Stack 5 DW afflictions"
  2: "Instill to trigger MADNESS capstone (target stunned)"
  3: "Instill again to trigger DEPRESSION capstone (anorexia + masochism)"
  4: "Target is stunned with masochism"
  5: "When stun ends, target cures and takes masochism damage"
  6: "Continue pressure or finish with damage/execute"

notes: |
  Masochism causes damage when target cures afflictions.
  Stun prevents them from doing anything while masochism applied.
  Very effective burst strategy.
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

## Offensive Abilities
```yaml
# Shadowmancy
instill:
  skill: Shadowmancy
  balance: bal
  effect: "Deliver affliction(s) to target"
  syntax: "INSTILL <target> <aff1> <aff2> ..."
  notes: "Primary affliction delivery, 1 aff per use (2 with timeloop)"

envenom:
  skill: Shadowmancy
  balance: free
  effect: "Apply venom to weapon"
  syntax: "ENVENOM <weapon> WITH <venom>"

# Aeonics
aeon:
  skill: Aeonics
  balance: eq
  effect: "Apply aeon - slows ALL target actions drastically"
  syntax: "AEON <target>"
  notes: "One of most powerful afflictions in game"

timeloop:
  skill: Aeonics
  balance: eq
  effect: "Next instill delivers 2 afflictions"
  syntax: "TIMELOOP"
  notes: "Critical for fast locking, unboosted requires <250 age"

retardation:
  skill: Aeonics
  balance: eq
  effect: "Create retardation field"
  syntax: "RETARDATION"
  notes: "Room-wide slow effect"

# Terminus
mutilate:
  skill: Terminus
  balance: eq
  effect: "Instant kill at 40% HP / 30% MP with shadow"
  syntax: "MUTILATE <target>"
  notes: "Requires claimed shadow from Leach capstone"

dictate:
  skill: Terminus
  balance: eq
  effect: "Mana-based instant kill"
  syntax: "DICTATE <target>"
  notes: "Threshold: 40% + 5% per DW affliction"

distort:
  skill: Terminus
  balance: eq
  effect: "Room hinder"
  syntax: "DISTORT"

preempt:
  skill: Terminus
  balance: eq
  effect: "Prevent fleeing"
  syntax: "PREEMPT"
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

images:
  skill: Shadowmancy
  effect: "Create shadow images"
  syntax: "IMAGES"
  notes: "Defensive illusions"

rewind:
  skill: Aeonics
  effect: "Revert to previous state"
  syntax: "REWIND"
  notes: "Powerful defensive reset"

displace:
  skill: Aeonics
  effect: "Displace in time"
  syntax: "DISPLACE"
  notes: "Defensive time ability"
```

## Passive Cures
```yaml
accelerate:
  cures: [varies]
  blocked_by: [recklessness]
  trigger: "Passive, automatic"
  notes: "Recklessness is their class-specific lock affliction"
```

## Terminus Skill Allocation
```yaml
description: "Recommendations for investing lessons in Terminus"

priority_abilities:
  1: "Mutilate (execute)"
  2: "Dictate (mana execute)"
  3: "Distort (room hinder)"
  4: "Preempt (prevent fleeing)"

notes: |
  Terminus contains the main execute abilities.
  Prioritize Mutilate and Dictate early.
  Room hinders valuable for control.
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
battlerage_abilities:
  - shadowstrike: "Basic damage"
  - instill: "Can be used for damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - aeon: "SMOKE ELM - extremely important! Slows all actions"
  - asthma: "Restore smoking (needed for aeon cure)"
  - recklessness: "Restores your Accelerate if you're DW"
  - paralysis: "Maintain ability to tree/act"
  - impatience: "Restore focus ability"
  - masochism: "Prevents self-damage when curing"

dangerous_abilities:
  - mutilate: "Instant kill at 40% HP / 30% MP with shadow"
  - dictate: "Mana kill at 40% + 5% per DW aff"
  - aeon: "Slows ALL actions significantly"
  - retardation: "Room-wide slow field"
  - timeloop: "Doubles their affliction output"
  - madness_capstone: "Stun at 5 DW affs"
  - depression_capstone: "Anorexia + masochism at 5 DW affs"

avoid:
  - "Letting aeon stick (cure IMMEDIATELY)"
  - "Standing in retardation field"
  - "Having 5+ DW afflictions (enables capstones)"
  - "Fighting slowly - their kit punishes slow play"
  - "Being below 40% HP AND 30% MP with shadow claimed"
  - "Letting mana drop with many DW affs (Dictate threshold)"

dw_afflictions_to_track:
  - "Count DW-specific afflictions on you"
  - "5 DW affs = capstone incoming"
  - "More DW affs = lower Dictate threshold"

recommended_strategy: |
  ALWAYS prioritize curing aeon - it cripples your ability to fight.
  Keep asthma cured so you can smoke elm for aeon.
  Track DW affliction count - 5 means capstone.
  Leave retardation field if possible.
  Watch your mana - Dictate threshold changes with DW aff count.
  If they have shadow claimed, stay above 40% HP and 30% MP.
  Aggressive offense is key - don't let them control tempo.
  Apply recklessness to block their Accelerate defense.
  Cure masochism quickly to avoid self-damage.
```

## Implementation Notes
```
Triggers to watch for:
- "slows down" or aeon message - aeon applied
- "A retardation field" - retardation active
- "instills * into you" - affliction incoming
- "claims your shadow" - Mutilate now possible
- "timeloop" - next instill will be doubled
- Capstone trigger messages (madness stun, depression, etc.)
- "mutilates" - execute attempt
- "dictates" - mana kill attempt

GMCP considerations:
- Track gmcp.Char.Afflictions for afflictions
- COUNT DW-specific afflictions for capstone/dictate tracking
- Shadow level may need message parsing
- Aeon in GMCP afflictions

Edge cases:
- Aeon is cured by smoking elm
- Retardation affects the whole room (including DW)
- Timeloop unboosted requires character <250 years old
- Impatience ONLY comes from instill (plan lock accordingly)
- Recklessness blocks Accelerate (class-specific lock aff)
- Capstones trigger at 5 DW afflictions
- Mutilate requires shadow claimed via Leach capstone
- Dictate threshold: 40% mana + 5% per DW affliction
- Masochism from Depression causes self-damage when curing

DW Affliction Tracking:
- Track which afflictions are DW-specific
- 5+ DW affs = capstone ready
- Each DW aff lowers Dictate threshold by 5%

Kill Route Thresholds:
- Mutilate: 40% HP AND 30% MP (with shadow)
- Dictate: 40% MP + 5% per DW aff
- Capstones: 5 DW afflictions
```
