# Waterlord

## Metadata
- **Type**: Elemental Lord
- **Combat Style**: Affliction | Damage
- **Difficulty**: Hard
- **Lock Affliction**: Weariness (blocks Fitness passive cure)

## Skills
```
Subjugation: Elemental dominion and control
Manifestation: Elemental body transformation
Evocation: Water elemental magic and attacks
```

## Kill Routes

### Primary Kill: Drowning
```yaml
type: execute
summary: Fill target's lungs with water for drowning kill

prerequisites:
  - Must apply water breathing affliction
  - Build drowning pressure

steps:
  1: "Apply drowning-related afflictions"
  2: "Fill target's lungs with water"
  3: "Maintain water pressure"
  4: "DROWN <target> when threshold reached"

notes: "Water element specializes in drowning execute"
```

### Alternative Kill: Affliction Lock
```yaml
type: affliction
summary: Use water abilities for affliction stacking

steps:
  1: "Apply water-based afflictions"
  2: "Apply freezing for control"
  3: "Stack toward true lock"
  4: "Apply weariness to block Fitness"
  5: "Damage to death through lock"

required_afflictions:
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying"
  - paralysis: "blocks tree"
  - impatience: "blocks focus"
  - weariness: "blocks Fitness (class-specific)"
```

### Alternative Kill: Ice Damage
```yaml
type: damage
summary: Use ice-based attacks for damage

steps:
  1: "Apply freezing (ice affliction)"
  2: "Apply sensitivity to increase damage"
  3: "Stack ice damage through evocation"
  4: "Kill through accumulated damage"

notes: "Freezing + damage combo"
```

## Offensive Abilities
```yaml
# Subjugation
dominate:
  skill: Subjugation
  balance: eq
  effect: "Dominate elemental forces"
  syntax: "DOMINATE <element>"

command:
  skill: Subjugation
  balance: eq
  effect: "Command subjugated elements"
  syntax: "COMMAND <effect>"

# Manifestation
manifest:
  skill: Manifestation
  balance: eq
  effect: "Manifest water elemental form"
  syntax: "MANIFEST WATER"

waterform:
  skill: Manifestation
  balance: eq
  effect: "Transform into water"
  syntax: "WATERFORM"
  notes: "Fluid movement, hard to pin down"

# Evocation
deluge:
  skill: Evocation
  balance: eq
  effect: "Water damage attack"
  damage_type: water
  syntax: "DELUGE <target>"

freeze:
  skill: Evocation
  balance: eq
  effect: "Freeze target"
  syntax: "FREEZE <target>"
  affliction: freezing

tsunami:
  skill: Evocation
  balance: eq
  effect: "Room-wide water wave"
  syntax: "TSUNAMI"
  notes: "Area effect, can prone"

drown:
  skill: Evocation
  balance: eq
  effect: "Fill lungs with water"
  syntax: "DROWN <target>"
  notes: "Drowning execute"
```

## Defensive Abilities
```yaml
fitness:
  skill: Manifestation
  effect: "Passively cures asthma"
  cures: [asthma]
  blocked_by: [weariness]

waterform:
  skill: Manifestation
  effect: "Transform into water"
  syntax: "WATERFORM"
  notes: "Difficult to target"

icewall:
  skill: Evocation
  effect: "Create wall of ice"
  syntax: "ICEWALL"
```

## Passive Cures
```yaml
fitness:
  cures: [asthma]
  blocked_by: [weariness]
  trigger: "Passive, automatic on asthma gain"
```

## Limb Strategy
```yaml
enabled: false
notes: "Waterlord is water/affliction-based, not limb-based"
```

## Bashing (PvE)
```yaml
attack_command: "DELUGE <target>"
attack_skill: Evocation
battlerage_abilities:
  - deluge: "Water damage"
  - freeze: "Ice damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - drowning: "EAT PEAR - prevents drowning execute"
  - freezing: "APPLY CALORIC - prevents ice effects"
  - weariness: "Restores your Fitness"
  - asthma: "Restore smoking ability"

dangerous_abilities:
  - drown: "Drowning instant kill"
  - freeze: "Ice control and damage"
  - tsunami: "Room-wide prone"
  - waterform: "Hard to target"

avoid:
  - "Letting drowning build up"
  - "Fighting while frozen"
  - "Standing in tsunami"
  - "Extended fight in waterform"

recommended_strategy: |
  Cure drowning with pear immediately.
  Apply caloric for freezing.
  Apply weariness to block their Fitness.
  Watch for tsunami prone effect.
  Track drowning buildup.
  Waterform makes them slippery - hard to lock down.
```

## Implementation Notes
```
Triggers to watch for:
- "water fills your lungs" - drowning
- "You are frozen" - freezing applied
- "A wave crashes" - tsunami
- "becomes liquid" - waterform
- Drowning pressure messages

GMCP considerations:
- Track gmcp.Char.Afflictions for afflictions
- Drowning level may need message parsing
- Freezing in afflictions

Edge cases:
- Weariness blocks their Fitness (class-specific)
- Drowning cured by eating pear
- Freezing cured by caloric salve
- Waterform makes them hard to target
- Tsunami affects whole room
- Drowning has buildup mechanic
```
