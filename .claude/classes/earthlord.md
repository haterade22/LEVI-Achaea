# Earthlord

## Metadata
- **Type**: Elemental Lord
- **Combat Style**: Limb | Damage
- **Difficulty**: Hard
- **Lock Affliction**: Weariness (blocks Fitness passive cure)

## Skills
```
Subjugation: Elemental dominion and control
Manifestation: Elemental body transformation
Evocation: Earth elemental magic and attacks
```

## Kill Routes

### Primary Kill: Crush/Stone
```yaml
type: damage
summary: Use earth manipulation for crushing damage

prerequisites:
  - Must accumulate elemental charge
  - Charge builds through evocation attacks

steps:
  1: "Apply stone-based afflictions"
  2: "Use earth evocation for crushing damage"
  3: "Apply sensitivity to increase damage"
  4: "CRUSH or PETRIFY when conditions met"

notes: "Earth element focuses on crushing and petrification"
```

### Alternative Kill: Affliction Lock
```yaml
type: affliction
summary: Use earth abilities for affliction stacking

steps:
  1: "Apply earth-based afflictions"
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

### Alternative Kill: Petrification
```yaml
type: execute
summary: Turn target to stone for instant kill

prerequisites:
  - Must build petrification on target
  - Target must be unable to cure

steps:
  1: "Apply stone touch effects"
  2: "Build petrification stacks"
  3: "When threshold reached, PETRIFY <target>"
  4: "Target turns to stone (instant kill)"

notes: "Similar to basilisk petrification"
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
  effect: "Manifest earth elemental form"
  syntax: "MANIFEST EARTH"

stoneform:
  skill: Manifestation
  balance: eq
  effect: "Transform into stone"
  syntax: "STONEFORM"
  notes: "High damage resistance but slow"

# Evocation
crush:
  skill: Evocation
  balance: eq
  effect: "Crushing earth damage"
  damage_type: earth
  syntax: "CRUSH <target>"

earthquake:
  skill: Evocation
  balance: eq
  effect: "Room-wide earth damage"
  syntax: "EARTHQUAKE"
  notes: "Area effect"

stalagmite:
  skill: Evocation
  balance: eq
  effect: "Impale with stone spike"
  syntax: "STALAGMITE <target>"

petrify:
  skill: Evocation
  balance: eq
  effect: "Turn target to stone"
  syntax: "PETRIFY <target>"
  notes: "Requires buildup"
```

## Defensive Abilities
```yaml
fitness:
  skill: Manifestation
  effect: "Passively cures asthma"
  cures: [asthma]
  blocked_by: [weariness]

stoneform:
  skill: Manifestation
  effect: "Transform into stone for protection"
  syntax: "STONEFORM"
  notes: "Very high damage resistance"

stonewalls:
  skill: Evocation
  effect: "Create stone walls"
  syntax: "STONEWALLS"
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
enabled: partial
notes: "Earth attacks can do limb damage but main focus is crushing/petrification"
```

## Bashing (PvE)
```yaml
attack_command: "CRUSH <target>"
attack_skill: Evocation
battlerage_abilities:
  - crush: "Crushing damage"
  - stalagmite: "Piercing damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - weariness: "Restores your Fitness"
  - petrification: "Cure before fully petrified"
  - sensitivity: "Reduces their damage"
  - prone: "Stand up from earthquake"

dangerous_abilities:
  - petrify: "Instant kill when threshold reached"
  - crush: "High crushing damage"
  - earthquake: "Room-wide damage and prone"
  - stoneform: "Makes them very tanky"

avoid:
  - "Letting petrification build"
  - "Standing during earthquake"
  - "Ignoring weariness"
  - "Extended fights (they're tanky)"

recommended_strategy: |
  Cure petrification stacks immediately.
  Apply weariness to block their Fitness.
  Avoid earthquake by leaving room if possible.
  Pressure them quickly - stoneform makes them hard to kill.
  Watch for stonewalls blocking movement.
```

## Implementation Notes
```
Triggers to watch for:
- "crushes you" - crushing damage
- "Your body stiffens" - petrification building
- "The earth shakes" - earthquake
- "turns to stone" - stoneform activation
- Petrification stack messages

GMCP considerations:
- Track gmcp.Char.Afflictions for afflictions
- Petrification stacks may need message parsing
- Prone from earthquake

Edge cases:
- Weariness blocks their Fitness (class-specific)
- Stoneform provides very high defense but slows them
- Petrification has buildup before instant kill
- Earthquake affects whole room
- Stonewalls can block movement
```
