# Sentinel

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Limb (depends on morph/companion)
- **Difficulty**: Medium
- **Lock Affliction**: Weariness (blocks Fitness passive cure)

## Skills
```
Woodlore: Animal companion and tracking abilities
Metamorphosis: Shapeshifting into various forms
Skirmishing: Combat techniques with spear and traps
```

## Metamorph Forms
```yaml
# Sentinel-Exclusive Forms
jaguar:
  description: "Stealthy jungle cat"
  style: "Fast attacks, stealth"
  strength: "Speed, ambush capability"
  sentinel_only: true

basilisk:
  description: "Petrifying gaze serpent"
  style: "Gaze attacks, petrification"
  strength: "Crowd control, instant kill potential"
  shared: true
  notes: "Sentinel specializes in this differently than Druid"

# Shared Forms (with Druid)
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

### Primary Kill: Eviscerate (Skirmishing)
```yaml
type: limb
summary: Break limbs with spear, then eviscerate

prerequisites:
  - Both legs broken (level 2)
  - One arm broken (level 2)
  - Target prone

steps:
  1: "Use spear attacks to damage limbs"
  2: "Focus legs first, then arm"
  3: "Knock target prone"
  4: "EVISCERATE <target>"

required_limbs:
  left_leg: 2
  right_leg: 2
  left_arm: 2
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

### Alternative Kill: Animal Companion Pressure
```yaml
type: hybrid
summary: Use animal companion for affliction/damage pressure

steps:
  1: "Bond with animal companion (wolf, bear, etc.)"
  2: "Command companion attacks"
  3: "Apply afflictions through companion and self"
  4: "Work toward lock or damage kill"

notes: "Companion provides additional attack per round"
```

## Offensive Abilities
```yaml
# Woodlore
bond:
  skill: Woodlore
  balance: eq
  effect: "Bond with animal companion"
  syntax: "BOND <animal>"
  animals: [wolf, spider, bird, snake, etc.]

command:
  skill: Woodlore
  balance: free
  effect: "Command companion"
  syntax: "ORDER <companion> <command>"
  notes: "Free balance"

track:
  skill: Woodlore
  balance: eq
  effect: "Track target"
  syntax: "TRACK <target>"

# Metamorphosis
morph:
  skill: Metamorphosis
  balance: eq
  effect: "Transform into a form"
  syntax: "MORPH <form>"
  forms: [jaguar, basilisk, wolf, bear, eagle]

attack:
  skill: Metamorphosis
  balance: bal
  effect: "Attack in current morph form"
  syntax: "ATTACK <target>"

# Skirmishing
spear:
  skill: Skirmishing
  balance: bal
  effect: "Spear attack with venom"
  syntax: "SPEAR <target> <venom>"
  notes: "Can apply venoms"

impale:
  skill: Skirmishing
  balance: bal
  effect: "Impale target with spear"
  syntax: "IMPALE <target>"

eviscerate:
  skill: Skirmishing
  balance: bal
  effect: "Instant kill when limbs broken"
  syntax: "EVISCERATE <target>"
  notes: "Requires broken limbs + prone"

trap:
  skill: Skirmishing
  balance: eq
  effect: "Set traps"
  syntax: "SET TRAP"
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

companion_alert:
  skill: Woodlore
  effect: "Companion alerts to danger"
  notes: "Some companions provide warning abilities"
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
enabled: true
target_order: [left_leg, right_leg, left_arm]  # for eviscerate
break_requirements:
  left_leg: 2
  right_leg: 2
  left_arm: 2
finisher: "EVISCERATE <target>"
```

## Bashing (PvE)
```yaml
attack_command: "SPEAR <target>" or "ATTACK <target>" in morph
attack_skill: Skirmishing/Metamorphosis
battlerage_abilities:
  - spear: "Basic damage"
  - companion_attack: "Companion damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - weariness: "Restores your Fitness"
  - broken_limbs: "Prevent eviscerate setup"
  - entanglement: "WRITHE out of traps"
  - petrification: "Cure before full petrify"
  - venoms: "Spear can apply venoms"

dangerous_abilities:
  - eviscerate: "Instant kill when limbs broken"
  - petrify: "Basilisk instant kill"
  - companion: "Additional attacks"
  - traps: "Room-based hazards"

avoid:
  - "Getting limbs broken for eviscerate"
  - "Standing on traps"
  - "Ignoring companion"
  - "Letting petrification build (basilisk)"

recommended_strategy: |
  Parry legs to slow eviscerate route.
  Kill or distract their companion.
  Watch for trap locations.
  Track which morph form they're in.
  Apply weariness to block their Fitness.
  Use selarnia venom to force them out of morph.
```

## Implementation Notes
```
Triggers to watch for:
- "morphs into a *" - form change
- "orders * to attack" - companion attacking
- "Your * is damaged/broken" - limb tracking
- "eviscerates you" - instant kill attempt
- "Your body stiffens" - petrification building
- Trap activation messages

GMCP considerations:
- Track gmcp.Char.Vitals for limb percentages if available
- Otherwise parse damage messages
- Companion presence via room items

Edge cases:
- Selarnia venom forces them out of morph
- Companion orders are FREE balance
- Traps persist until triggered
- Different morphs have very different abilities
- Petrification has buildup before instant kill
- Jaguar can enter stealth
```
