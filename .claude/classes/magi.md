# Magi

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Damage
- **Difficulty**: Hard
- **Lock Affliction**: Haemophilia (prevents clotting, key for their kill)

## Skills
```
Crystalism: Vibrational crystal magic
Elementalism: Elemental magic (fire, water, air, earth)
Artificing: Item creation and enhancement
```

## Kill Routes

### Primary Kill: Staffcast Damage
```yaml
type: damage
summary: High elemental damage through staff casting

prerequisites:
  - Must have staff wielded
  - Elemental charges built up

steps:
  1: "Build elemental charges"
  2: "Apply sensitivity to increase damage"
  3: "Apply haemophilia to prevent clotting"
  4: "Staffcast high damage elemental attacks"
  5: "Kill through accumulated damage"

notes: "Magi can do very high burst damage with staffcasts"
```

### Alternative Kill: Crystal Vibrations Lock
```yaml
type: affliction
summary: Use crystal vibrations to stack afflictions

steps:
  1: "Set up vibrating crystals"
  2: "Stack afflictions through crystal effects"
  3: "Apply lock afflictions"
  4: "Apply haemophilia to prevent clotting"
  5: "Work toward true lock"
  6: "Damage to death through lock"

required_afflictions:
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying"
  - paralysis: "blocks tree"
  - impatience: "blocks focus"
  - haemophilia: "prevents clotting (class-specific)"
```

### Alternative Kill: Elemental Combos
```yaml
type: damage
summary: Combine elemental effects for combo damage

steps:
  1: "Apply freezing (water element)"
  2: "Apply ablaze (fire element)"
  3: "Combine elements for increased effects"
  4: "Use staffcast for burst damage"
```

## Offensive Abilities
```yaml
# Crystalism
vibrate:
  skill: Crystalism
  balance: eq
  effect: "Vibrate a crystal for effect"
  syntax: "VIBRATE <crystal>"
  crystals:
    - purity: "Cure afflictions"
    - empower: "Increase damage"
    - disruption: "Disrupt target"
    - stability: "Defensive stability"

embed:
  skill: Crystalism
  balance: eq
  effect: "Embed crystal in room"
  syntax: "EMBED <crystal>"

# Elementalism
staffcast:
  skill: Elementalism
  balance: eq
  effect: "Cast elemental attack through staff"
  syntax: "STAFFCAST <element> <target>"
  elements:
    - fire: "Fire damage, can ablaze"
    - water: "Water damage, can freeze"
    - air: "Air damage, lightning"
    - earth: "Earth damage, crushing"

freeze:
  skill: Elementalism
  balance: eq
  effect: "Apply freezing effect"
  syntax: "STAFFCAST WATER <target>"
  affliction: freezing

ablaze:
  skill: Elementalism
  balance: eq
  effect: "Set target on fire"
  syntax: "STAFFCAST FIRE <target>"
  affliction: ablaze

# Artificing
imbue:
  skill: Artificing
  balance: eq
  effect: "Imbue items with power"
  syntax: "IMBUE <item>"
```

## Defensive Abilities
```yaml
stonewalls:
  skill: Elementalism
  effect: "Create stone walls for protection"
  syntax: "ERECT STONEWALLS"

purity_crystal:
  skill: Crystalism
  effect: "Crystal that cures afflictions"
  syntax: "VIBRATE PURITY"
  notes: "Blocked by haemophilia for some effects"
```

## Passive Cures
```yaml
# Magi has crystal-based curing
purity:
  cures: [various]
  blocked_by: [haemophilia]
  trigger: "Vibrate purity crystal"
  notes: "Haemophilia disrupts their cure system"
```

## Limb Strategy
```yaml
enabled: false
notes: "Magi is element/affliction-based, not limb-based"
```

## Bashing (PvE)
```yaml
attack_command: "STAFFCAST FIRE <target>"
attack_skill: Elementalism
battlerage_abilities:
  - staffcast: "Elemental damage"
  - vibrate: "Crystal effects"
```

## Fighting Against This Class
```yaml
priority_cures:
  - freezing: "APPLY CALORIC - prevents being frozen solid"
  - ablaze: "APPLY MENDING - stops fire damage"
  - haemophilia: "EAT GINSENG - restore clotting"
  - sensitivity: "Reduce their damage"

dangerous_abilities:
  - staffcast: "High burst elemental damage"
  - elemental_combos: "Combined element effects"
  - crystals: "Various effects and room control"

avoid:
  - "Standing near their embedded crystals"
  - "Letting freezing + ablaze combo"
  - "Low health with sensitivity active"
  - "Ignoring haemophilia (key affliction)"

recommended_strategy: |
  Cure freezing and ablaze quickly to prevent combo.
  Keep caloric salve ready for freezing.
  Apply haemophilia to disrupt their crystal curing.
  Destroy or leave rooms with embedded crystals.
  Pressure them before they can build up staffcast damage.
  Watch for stonewalls blocking movement.
```

## Implementation Notes
```
Triggers to watch for:
- "staffcasts * at you" - elemental attack incoming
- "vibrates *" - crystal effect
- "You are ablaze" - fire damage ticking
- "You are frozen" - frozen effect
- Crystal embedding messages
- Stonewall messages

GMCP considerations:
- Track gmcp.Char.Afflictions for afflictions
- Ablaze and freezing in afflictions
- Crystal state may need message parsing

Edge cases:
- Haemophilia blocks their crystal curing
- Elemental combos (fire+water) do extra effects
- Stonewalls can block movement
- Embedded crystals persist until destroyed
- Staff is required for staffcasting
- High burst potential but setup required
```
