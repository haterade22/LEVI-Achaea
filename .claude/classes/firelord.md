# Firelord

## Metadata
- **Type**: Elemental Lord
- **Combat Style**: Damage | Affliction
- **Difficulty**: Hard
- **Lock Affliction**: Weariness (blocks Fitness passive cure)

## Skills
```
Subjugation: Elemental dominion and control
Manifestation: Elemental body transformation
Evocation: Fire elemental magic and attacks
```

## Kill Routes

### Primary Kill: Fire Damage Burn
```yaml
type: damage
summary: Stack fire damage and ablaze for sustained burn damage

prerequisites:
  - Must apply and maintain ablaze
  - Build fire damage through evocation

steps:
  1: "Apply ablaze (fire DoT)"
  2: "Apply sensitivity to increase damage"
  3: "Stack fire damage through evocation"
  4: "Maintain ablaze while dealing burst damage"
  5: "Target burns to death"

notes: "Fire element excels at sustained damage"
```

### Alternative Kill: Affliction Lock
```yaml
type: affliction
summary: Use fire abilities for affliction stacking

steps:
  1: "Apply fire-based afflictions"
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

### Alternative Kill: Inferno
```yaml
type: execute
summary: Build fire intensity, then inferno for massive burst

prerequisites:
  - Must accumulate fire intensity
  - Target should be weakened

steps:
  1: "Build fire intensity through attacks"
  2: "Apply ablaze for passive damage"
  3: "When intensity maxed, INFERNO <target>"
  4: "Massive fire burst kills target"

notes: "Inferno is fire's burst execute"
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
  effect: "Manifest fire elemental form"
  syntax: "MANIFEST FIRE"

flameform:
  skill: Manifestation
  balance: eq
  effect: "Transform into flame"
  syntax: "FLAMEFORM"
  notes: "Passive damage to attackers"

# Evocation
fireball:
  skill: Evocation
  balance: eq
  effect: "Ball of fire damage"
  damage_type: fire
  syntax: "FIREBALL <target>"

conflagration:
  skill: Evocation
  balance: eq
  effect: "Room-wide fire"
  syntax: "CONFLAGRATION"
  notes: "Area effect"

immolate:
  skill: Evocation
  balance: eq
  effect: "Set target ablaze"
  syntax: "IMMOLATE <target>"
  affliction: ablaze

inferno:
  skill: Evocation
  balance: eq
  effect: "Massive fire burst"
  syntax: "INFERNO <target>"
  notes: "High damage execute"
```

## Defensive Abilities
```yaml
fitness:
  skill: Manifestation
  effect: "Passively cures asthma"
  cures: [asthma]
  blocked_by: [weariness]

flameform:
  skill: Manifestation
  effect: "Transform into flame"
  syntax: "FLAMEFORM"
  notes: "Damages attackers"

firewall:
  skill: Evocation
  effect: "Create wall of fire"
  syntax: "FIREWALL"
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
notes: "Firelord is fire/damage-based, not limb-based"
```

## Bashing (PvE)
```yaml
attack_command: "FIREBALL <target>"
attack_skill: Evocation
battlerage_abilities:
  - fireball: "Fire damage"
  - immolate: "Burning damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - ablaze: "APPLY MENDING - stops fire DoT"
  - weariness: "Restores your Fitness"
  - sensitivity: "Reduces their damage"
  - asthma: "Restore smoking ability"

dangerous_abilities:
  - inferno: "Massive burst damage"
  - ablaze: "Sustained fire damage over time"
  - conflagration: "Room-wide fire"
  - flameform: "Damages you when you attack them"

avoid:
  - "Letting ablaze tick (cure immediately)"
  - "Fighting in conflagration"
  - "Low health with sensitivity active"
  - "Extended melee with flameform active"

recommended_strategy: |
  Cure ablaze immediately with mending salve.
  Apply weariness to block their Fitness.
  Watch for inferno - it's their burst execute.
  Leave room during conflagration if possible.
  Track fire intensity buildup.
  Be careful attacking in flameform - damages you.
```

## Implementation Notes
```
Triggers to watch for:
- "You are ablaze" - fire DoT applied
- "hurls a fireball" - fireball damage
- "flames erupt" - conflagration
- "becomes wreathed in flame" - flameform
- Fire intensity messages

GMCP considerations:
- Track gmcp.Char.Afflictions for afflictions
- Ablaze in afflictions (important!)
- Fire intensity may need message parsing

Edge cases:
- Weariness blocks their Fitness (class-specific)
- Ablaze cured by mending salve
- Flameform damages attackers passively
- Conflagration affects whole room
- Fire intensity builds toward inferno
- High sustained damage potential
```
