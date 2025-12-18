# Alchemist

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Damage
- **Difficulty**: Hard
- **Lock Affliction**: Stupidity (disrupts their ether-based cures)

## Skills
```
Alchemy: Ether manipulation and transmutation
Physiology: Knowledge of the body for afflictions
Formulation: Default alchemical field abilities
  -OR-
Sublimation: Alternative field using Hashan's Wellspring
```

## Specializations
```yaml
Formulation:
  description: "Default alchemical field"
  style: "Traditional ether manipulation"
  unlock: "Default for all alchemists"

Sublimation:
  description: "Hashan Wellspring variant"
  style: "Wellspring-powered abilities"
  unlock: "Alternative specialization"
```

## Kill Routes

### Primary Kill: Ejection
```yaml
type: execute
summary: Build humour imbalance, then eject the overwhelmed humour for kill

prerequisites:
  - Must imbalance target's humours significantly
  - One humour must be overwhelmed

steps:
  1: "Apply humour-affecting abilities"
  2: "Stack one humour to overwhelming levels"
  3: "When humour is overwhelmed, EJECT <humour>"
  4: "Target dies from humour ejection"

notes: "Humours are: sanguine, choleric, melancholic, phlegmatic"
```

### Alternative Kill: Affliction Lock
```yaml
type: affliction
summary: Use Physiology to stack afflictions toward lock

steps:
  1: "Apply afflictions through Physiology abilities"
  2: "Stack lock afflictions"
  3: "Apply stupidity to disrupt their curing"
  4: "Complete true lock"
  5: "Damage to death through lock"

required_afflictions:
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying"
  - paralysis: "blocks tree"
  - impatience: "blocks focus"
  - stupidity: "disrupts ether-based curing"
```

### Alternative Kill: Damage via Ether
```yaml
type: damage
summary: Use ether damage abilities for sustained damage output

steps:
  1: "Apply sensitivity"
  2: "Use ether damage abilities"
  3: "Maintain humour pressure"
  4: "Kill through accumulated damage"
```

## Offensive Abilities
```yaml
# Alchemy
transmute:
  skill: Alchemy
  balance: eq
  effect: "Transmute elements for various effects"
  syntax: "TRANSMUTE <element>"

ether:
  skill: Alchemy
  balance: eq
  effect: "Ether-based attacks"
  syntax: "ETHER <ability> <target>"

# Physiology
afflict:
  skill: Physiology
  balance: eq
  effect: "Apply physiological affliction"
  syntax: "PHYSIOLOGY <affliction> <target>"
  afflictions:
    - sensitivity: "Increased damage"
    - clumsiness: "Fumbled actions"
    - weariness: "Blocks Fitness"
    - many_more: "Various physical afflictions"

# Formulation/Sublimation
formula:
  skill: Formulation
  balance: eq
  effect: "Apply alchemical formula"
  syntax: "FORMULA <type> <target>"

ejection:
  skill: Formulation
  balance: eq
  effect: "Eject overwhelmed humour for instant kill"
  syntax: "EJECT <humour> <target>"
  humours: [sanguine, choleric, melancholic, phlegmatic]
```

## Defensive Abilities
```yaml
ether_cure:
  skill: Alchemy
  effect: "Cure afflictions using ether"
  notes: "Blocked by stupidity"

transmutation_defense:
  skill: Alchemy
  effect: "Defensive transmutations"
  syntax: "TRANSMUTE DEFENCE"
```

## Passive Cures
```yaml
ether_cure:
  cures: [various]
  blocked_by: [stupidity]
  trigger: "Active cure using ether"
  notes: "Alchemist has unique ether-based curing, blocked by stupidity"
```

## Limb Strategy
```yaml
enabled: false
notes: "Alchemist is affliction/humour-based, not limb-based"
```

## Bashing (PvE)
```yaml
attack_command: "BATTLERAGE ETHER <target>"
attack_skill: Alchemy
battlerage_abilities:
  - ether: "Basic damage"
  - transmute: "Elemental damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - asthma: "Restore smoking ability"
  - slickness: "Restore salve application"
  - anorexia: "Restore eating ability"
  - humour_imbalance: "Cure imbalanced humours with ginger"

dangerous_abilities:
  - ejection: "Instant kill when humour overwhelmed"
  - humour_manipulation: "Builds toward ejection"
  - ether_attacks: "Sustained damage and afflictions"

avoid:
  - "Letting any humour become overwhelmed"
  - "Ignoring humour imbalance messages"
  - "Letting afflictions stack"

recommended_strategy: |
  Cure humour imbalances with ginger herb.
  Track which humour they're targeting.
  Prioritize curing lock afflictions.
  Apply stupidity to disrupt their ether curing.
  Pressure them before they can build humour imbalance.
```

## Implementation Notes
```
Triggers to watch for:
- "Your * humour is imbalanced" - track humour state
- "overwhelmed by" - humour is at dangerous level
- Ether attack messages
- Physiology affliction applications

GMCP considerations:
- Track gmcp.Char.Afflictions for afflictions
- Humour state may need message parsing

Edge cases:
- Stupidity blocks their ether curing (class-specific)
- Four humours must be tracked separately
- Ginger cures humour imbalances
- Formulation vs Sublimation have different abilities
- Ejection requires specific humour to be overwhelmed
```
