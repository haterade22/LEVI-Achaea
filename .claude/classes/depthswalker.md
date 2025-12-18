# Depthswalker

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Damage
- **Difficulty**: Hard
- **Lock Affliction**: Recklessness (blocks their specific defense/cure)

## Skills
```
Aeonics: Time manipulation abilities
Shadowmancy: Shadow-based attacks and manipulation
Terminus: Death and void powers
```

## Kill Routes

### Primary Kill: Unravel
```yaml
type: execute
summary: Build shadow stacks, then unravel for instant kill

prerequisites:
  - Must accumulate sufficient shadow essence on target
  - Shadow built through shadowmancy attacks

steps:
  1: "Apply shadow through Shadowmancy abilities"
  2: "Stack shadow essence on target"
  3: "When shadow threshold reached, UNRAVEL <target>"
  4: "Target's essence is destroyed"

notes: "Shadow decays over time, must maintain pressure"
```

### Alternative Kill: Aeon Lock
```yaml
type: affliction
summary: Use aeon to slow target, then stack toward lock

steps:
  1: "Apply aeon (slows all actions significantly)"
  2: "Use slowed state to stack afflictions"
  3: "Work toward true lock"
  4: "Apply recklessness to block their defenses"
  5: "Damage to death through lock"

required_afflictions:
  - aeon: "Slows ALL actions - critical"
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying"
  - paralysis: "blocks tree"
  - impatience: "blocks focus"
  - recklessness: "class-specific lock aff"
```

### Alternative Kill: Terminus Damage
```yaml
type: damage
summary: Use void damage abilities for high sustained damage

steps:
  1: "Apply sensitivity"
  2: "Use Terminus damage abilities"
  3: "Combine with shadow buildup"
  4: "Kill through accumulated damage"
```

## Offensive Abilities
```yaml
# Aeonics
aeon:
  skill: Aeonics
  balance: eq
  effect: "Apply aeon - slows ALL target actions"
  syntax: "AEON <target>"
  notes: "One of most powerful afflictions in game"

timeslip:
  skill: Aeonics
  balance: eq
  effect: "Slip through time"
  syntax: "TIMESLIP"

retardation:
  skill: Aeonics
  balance: eq
  effect: "Create retardation field"
  syntax: "RETARDATION"
  notes: "Room-wide slow effect"

# Shadowmancy
shadowstrike:
  skill: Shadowmancy
  balance: bal
  effect: "Strike with shadow, builds shadow essence"
  syntax: "SHADOWSTRIKE <target>"

shadowspear:
  skill: Shadowmancy
  balance: bal
  effect: "Spear of shadow, applies affliction"
  syntax: "SHADOWSPEAR <target>"

leach:
  skill: Shadowmancy
  balance: eq
  effect: "Drain shadow from target"
  syntax: "LEACH <target>"

# Terminus
void:
  skill: Terminus
  balance: eq
  effect: "Void-based damage"
  syntax: "VOID <target>"

unravel:
  skill: Terminus
  balance: eq
  effect: "Instant kill when shadow essence high"
  syntax: "UNRAVEL <target>"
  notes: "Main execute ability"
```

## Defensive Abilities
```yaml
shadowveil:
  skill: Shadowmancy
  effect: "Shadow concealment"
  syntax: "SHADOWVEIL"

phaseshift:
  skill: Aeonics
  effect: "Shift out of phase temporarily"
  syntax: "PHASESHIFT"
```

## Passive Cures
```yaml
# Depthswalker has a specific cure blocked by recklessness
# Details vary by implementation
```

## Limb Strategy
```yaml
enabled: false
notes: "Depthswalker is shadow/affliction-based, not limb-based"
```

## Bashing (PvE)
```yaml
attack_command: "BATTLERAGE SHADOWSTRIKE <target>"
attack_skill: Shadowmancy
battlerage_abilities:
  - shadowstrike: "Basic damage"
  - void: "Additional damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - aeon: "SMOKE ELM - extremely important! Slows all actions"
  - asthma: "Restore smoking (needed for aeon cure)"
  - shadow_buildup: "Avoid unravel execute"

dangerous_abilities:
  - aeon: "Slows ALL actions significantly"
  - retardation: "Room-wide slow field"
  - unravel: "Instant kill when shadow high"
  - timeslip: "Time manipulation"

avoid:
  - "Letting aeon stick (cure IMMEDIATELY)"
  - "Standing in retardation field"
  - "Letting shadow essence build"
  - "Fighting slowly - their kit punishes slow play"

recommended_strategy: |
  ALWAYS prioritize curing aeon - it cripples your ability to fight.
  Keep asthma cured so you can smoke elm for aeon.
  Track shadow buildup and pressure them.
  Leave retardation field if possible.
  Apply recklessness to block their defenses.
  Aggressive offense is key - don't let them control tempo.
```

## Implementation Notes
```
Triggers to watch for:
- "slows down" or aeon message - aeon applied
- "A retardation field" - retardation active
- Shadow buildup messages
- "unravels your essence" - unravel attempt
- Timeslip/phaseshift messages

GMCP considerations:
- Track gmcp.Char.Afflictions for afflictions
- Shadow level may need message parsing
- Aeon in GMCP afflictions

Edge cases:
- Aeon is cured by smoking elm
- Retardation affects the whole room
- Shadow decays over time without refreshing
- Timeslip can dodge attacks
- Recklessness is their class-specific lock aff
- Fighting in retardation is extremely dangerous
```
