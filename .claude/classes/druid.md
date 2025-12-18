# Druid

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Limb (depends on morph)
- **Difficulty**: Medium
- **Lock Affliction**: Weariness (blocks Fitness passive cure)

## Skills
```
Groves: Forest grove creation and manipulation
Metamorphosis: Shapeshifting into various forms
Reclamation: Nature reclamation and restoration powers
```

## Metamorph Forms
```yaml
# Druid-Exclusive Forms
hydra:
  description: "Multi-headed serpent"
  style: "Multiple attack heads, high damage"
  strength: "Multiple simultaneous attacks"
  druid_only: true

wyvern:
  description: "Winged serpent"
  style: "Flight, aerial attacks"
  strength: "Mobility, aerial advantage"
  druid_only: true

# Shared Forms (with Sentinel)
basilisk:
  description: "Petrifying gaze serpent"
  style: "Gaze attacks, petrification"
  strength: "Crowd control, instant kill potential"
  shared: true

wolf:
  description: "Pack predator"
  style: "Fast attacks, pack tactics"
  strength: "Speed, tracking"
  shared: true

bear:
  description: "Powerful predator"
  style: "High damage, resilience"
  strength: "Raw power, tankiness"
  shared: true

eagle:
  description: "Aerial predator"
  style: "Flight, aerial attacks"
  strength: "Mobility, vision"
  shared: true
```

## Kill Routes

### Primary Kill: Maul (Bear Form)
```yaml
type: damage
summary: High damage maul attack in bear form

prerequisites:
  - Must be in bear form
  - Target should have low health

steps:
  1: "Morph into bear"
  2: "Apply sensitivity"
  3: "Use bear attacks to damage"
  4: "MAUL <target> for high damage finish"
```

### Alternative Kill: Petrify (Basilisk Form)
```yaml
type: execute
summary: Gaze attack to petrify target

prerequisites:
  - Must be in basilisk form
  - Target must meet petrification conditions

steps:
  1: "Morph into basilisk"
  2: "Use gaze attacks to build petrification"
  3: "When conditions met, PETRIFY <target>"
  4: "Target turns to stone (instant kill)"
```

### Alternative Kill: Grove Entangle Lock
```yaml
type: affliction
summary: Use grove abilities and morphs for affliction lock

steps:
  1: "Create and empower grove"
  2: "Use grove abilities for entanglement"
  3: "Apply afflictions through morph attacks"
  4: "Work toward true lock"
  5: "Damage to death through lock"

required_afflictions:
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying"
  - paralysis: "blocks tree"
  - impatience: "blocks focus"
  - weariness: "blocks Fitness"
```

## Offensive Abilities
```yaml
# Groves
vinetangle:
  skill: Groves
  balance: eq
  effect: "Tangle target in vines"
  syntax: "VINETANGLE <target>"
  notes: "Grove must be active"

wildgrowth:
  skill: Groves
  balance: eq
  effect: "Cause wild growth in grove"
  syntax: "WILDGROWTH"

# Metamorphosis
morph:
  skill: Metamorphosis
  balance: eq
  effect: "Transform into a form"
  syntax: "MORPH <form>"
  forms: [hydra, wyvern, basilisk, wolf, bear, eagle]

attack:
  skill: Metamorphosis
  balance: bal
  effect: "Attack in current morph form"
  syntax: "ATTACK <target>"
  notes: "Varies by form"

# Reclamation
reclaim:
  skill: Reclamation
  balance: eq
  effect: "Reclaim area for nature"
  syntax: "RECLAIM"

sap:
  skill: Reclamation
  balance: eq
  effect: "Sap target's energy"
  syntax: "SAP <target>"
```

## Defensive Abilities
```yaml
fitness:
  skill: Metamorphosis
  effect: "Passively cures asthma"
  cures: [asthma]
  blocked_by: [weariness]

morph_defenses:
  skill: Metamorphosis
  effect: "Various defenses based on form"
  notes: "Bear has resilience, eagle has flight, etc."

grove_protection:
  skill: Groves
  effect: "Protection while in grove"
  notes: "Grove provides various benefits"
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
notes: "Some morphs (bear) can do limb damage but not primary focus"
```

## Bashing (PvE)
```yaml
attack_command: "ATTACK <target>" (in morph form)
attack_skill: Metamorphosis
battlerage_abilities:
  - attack: "Basic damage in form"
  - maul: "Bear form damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - weariness: "Restores your Fitness"
  - entanglement: "WRITHE out of vines"
  - paralysis: "Restore tree usage"
  - petrification: "Cure before full petrify"

dangerous_abilities:
  - petrify: "Basilisk instant kill"
  - maul: "High bear form damage"
  - vinetangle: "Entanglement"
  - hydra_attacks: "Multiple simultaneous attacks"

avoid:
  - "Standing in their grove"
  - "Ignoring entanglement"
  - "Letting petrification build"
  - "Low health against bear form"

recommended_strategy: |
  Leave their grove if possible - they're stronger in it.
  Writhe out of entanglement quickly.
  Track which morph form they're in.
  Apply weariness to block their Fitness.
  Use selarnia venom to force them out of morph.
  Watch for petrification buildup in basilisk form.
```

## Implementation Notes
```
Triggers to watch for:
- "morphs into a *" - form change
- "You are tangled" - entanglement
- "Your body stiffens" - petrification building
- Various form-specific attack messages
- Grove activation messages

GMCP considerations:
- Track gmcp.Char.Afflictions for afflictions
- Morph form may need message parsing
- Entanglement in afflictions

Edge cases:
- Selarnia venom forces them out of morph
- Grove provides bonuses in that room
- Different morphs have very different abilities
- Hydra can attack multiple times per balance
- Petrification has buildup before instant kill
- Wyvern/eagle can fly
```
