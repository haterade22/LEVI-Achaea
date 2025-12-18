# Airlord

## Metadata
- **Type**: Elemental Lord
- **Combat Style**: Affliction | Damage
- **Difficulty**: Hard
- **Lock Affliction**: Weariness (blocks Fitness passive cure)

## Skills
```
Subjugation: Elemental dominion and control
Manifestation: Elemental body transformation
Evocation: Air elemental magic and attacks
```

## Kill Routes

### Primary Kill: Elemental Burst
```yaml
type: damage
summary: Build elemental charge, then burst for massive damage

prerequisites:
  - Must accumulate elemental charge
  - Charge builds through evocation attacks

steps:
  1: "Apply afflictions for pressure"
  2: "Use air evocation attacks to build charge"
  3: "Apply sensitivity to increase damage"
  4: "When charge high, ELEMENTAL BURST <target>"

notes: "Elemental Lords have high damage potential"
```

### Alternative Kill: Affliction Lock
```yaml
type: affliction
summary: Use elemental abilities for affliction stacking

steps:
  1: "Apply air-based afflictions"
  2: "Stack toward true lock"
  3: "Apply weariness to block Fitness"
  4: "Damage to death through lock"

required_afflictions:
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying"
  - paralysis: "blocks tree"
  - impatience: "blocks focus"
  - weariness: "blocks Fitness (class-specific)"
```

### Alternative Kill: Suffocation
```yaml
type: execute
summary: Use air control to suffocate target

steps:
  1: "Control air around target"
  2: "Apply asphyxiation pressure"
  3: "Maintain air control"
  4: "Target suffocates"

notes: "Air control-based execute"
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
  effect: "Manifest air elemental form"
  syntax: "MANIFEST AIR"

dissolve:
  skill: Manifestation
  balance: eq
  effect: "Dissolve into air"
  syntax: "DISSOLVE"

# Evocation
gust:
  skill: Evocation
  balance: eq
  effect: "Blast of air damage"
  damage_type: air
  syntax: "GUST <target>"

lightning:
  skill: Evocation
  balance: eq
  effect: "Lightning strike"
  damage_type: electric
  syntax: "LIGHTNING <target>"

cyclone:
  skill: Evocation
  balance: eq
  effect: "Create damaging cyclone"
  syntax: "CYCLONE <target>"

suffocate:
  skill: Evocation
  balance: eq
  effect: "Remove air from target's lungs"
  syntax: "SUFFOCATE <target>"
  affliction: asphyxiation
```

## Defensive Abilities
```yaml
fitness:
  skill: Manifestation
  effect: "Passively cures asthma"
  cures: [asthma]
  blocked_by: [weariness]

airform:
  skill: Manifestation
  effect: "Become intangible air"
  syntax: "AIRFORM"
  notes: "Damage reduction in air form"
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
notes: "Airlord is elemental/affliction-based, not limb-based"
```

## Bashing (PvE)
```yaml
attack_command: "LIGHTNING <target>"
attack_skill: Evocation
battlerage_abilities:
  - lightning: "Electric damage"
  - gust: "Air damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - weariness: "Restores your Fitness"
  - asphyxiation: "Prevents suffocation"
  - sensitivity: "Reduces their damage"
  - asthma: "Restore smoking ability"

dangerous_abilities:
  - lightning: "High burst electric damage"
  - suffocate: "Asphyxiation pressure"
  - cyclone: "Area damage"
  - airform: "Makes them harder to hit"

avoid:
  - "Letting elemental charge build"
  - "Ignoring asphyxiation"
  - "Fighting in their cyclone"
  - "Letting weariness stick"

recommended_strategy: |
  Cure asphyxiation quickly to prevent suffocation kill.
  Apply weariness to block their Fitness.
  Track elemental charge buildup.
  Pressure them before they can burst.
  Watch for airform making them harder to damage.
```

## Implementation Notes
```
Triggers to watch for:
- "lightning strikes" - electric damage
- "air rushes from your lungs" - suffocation
- "becomes intangible" - airform
- "cyclone forms" - area effect
- Elemental charge messages

GMCP considerations:
- Track gmcp.Char.Afflictions for afflictions
- Elemental charge may need message parsing
- Asphyxiation tracking

Edge cases:
- Weariness blocks their Fitness (class-specific)
- Airform provides damage reduction
- Lightning can strike from range
- Suffocation has buildup mechanic
- Cyclone affects area
```
