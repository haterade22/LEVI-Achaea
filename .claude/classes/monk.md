# Monk

## Metadata
- **Type**: Base Class
- **Combat Style**: Limb | Affliction (Hybrid)
- **Difficulty**: Hard
- **Lock Affliction**: Weariness (blocks Fitness passive cure)

## Skills
```
Tekura: Unarmed martial arts combat (default)
  -OR-
Shikudo: Staff-based martial arts (requires Trans Tekura to unlock)
Kaido: Internal energy manipulation and healing
Telepathy: Mental powers and afflictions
```

## Specializations
```yaml
Tekura:
  description: "Default unarmed martial arts"
  style: "Punches, kicks, and combinations"
  strength: "Versatile combos, good affliction application"
  unlock: "Default for all monks"

Shikudo:
  description: "Staff-based martial arts"
  style: "Staff strikes and sweeps"
  strength: "Better limb damage, different combo routes"
  unlock: "Requires Trans Tekura first"
```

## Kill Routes

### Primary Kill: Throatchop (Limb-Based)
```yaml
type: limb
summary: Break throat to level 3, then throatchop for instant kill

prerequisites:
  - Throat must be at 200% damage (level 3 mangled)
  - Target must be prone or unable to parry

steps:
  1: "Focus attacks on throat/head"
  2: "Use combination attacks for limb damage"
  3: "Get throat to level 3 (200%)"
  4: "THROATCHOP <target> when throat mangled"

required_limbs:
  throat: 3
```

### Alternative Kill: SSK (Super Side Kick) - Damage
```yaml
type: damage
summary: High damage kick when target is prone with broken legs

prerequisites:
  - Target must be prone
  - Both legs broken

steps:
  1: "Break both legs with leg-targeting attacks"
  2: "Knock target prone"
  3: "SSK <target> for massive damage"
  4: "Repeat until dead"

notes: "SSK does huge damage to prone targets with broken legs"
```

### Alternative Kill: Affliction Lock via Telepathy
```yaml
type: affliction
summary: Use Telepathy to stack mental afflictions toward lock

steps:
  1: "Use Telepathy abilities for mental afflictions"
  2: "Apply mind lock afflictions"
  3: "Combine with Tekura attacks for venom application"
  4: "Work toward true lock"
  5: "Damage to death through lock"

notes: "Monk has mental affliction pressure through Telepathy"
```

## Offensive Abilities
```yaml
# Tekura (Unarmed)
punch:
  skill: Tekura
  balance: bal
  effect: "Basic punch attack"
  syntax: "PUNCH <target>"

kick:
  skill: Tekura
  balance: bal
  effect: "Basic kick attack"
  syntax: "KICK <target>"

combination:
  skill: Tekura
  balance: bal
  effect: "Execute a combo of attacks"
  syntax: "<combo> <target>"
  combos:
    - smp: "Side Punch + Mid Punch"
    - sdk: "Side Kick + Double Kick"
    - ucp: "Upper Cut Punch"
    - hfk: "High Front Kick"
    - many_more: "See COMBO LIST"

ssk:
  skill: Tekura
  balance: bal
  effect: "Super Side Kick - massive damage to prone target"
  syntax: "SSK <target>"
  notes: "Huge damage if both legs broken and prone"

throatchop:
  skill: Tekura
  balance: bal
  effect: "Instant kill when throat is mangled (level 3)"
  syntax: "THROATCHOP <target>"

# Shikudo (Staff) - Alternative spec
staffstrike:
  skill: Shikudo
  balance: bal
  effect: "Basic staff attack"
  syntax: "STAFFSTRIKE <target>"

sweep:
  skill: Shikudo
  balance: bal
  effect: "Sweep legs, can prone"
  syntax: "SWEEP <target>"

# Kaido
kai:
  skill: Kaido
  balance: kai
  effect: "Various kai abilities"
  syntax: "KAI <ability>"
  abilities:
    - heal: "Heal HP"
    - cripple: "Self-damage for affliction cure"
    - transmute: "Convert health to mana"

# Telepathy
mindblast:
  skill: Telepathy
  balance: eq
  effect: "Mental damage and affliction"
  syntax: "MINDBLAST <target>"

mindlock:
  skill: Telepathy
  balance: eq
  effect: "Apply mental lock"
  syntax: "MINDLOCK <target>"
```

## Defensive Abilities
```yaml
fitness:
  skill: Tekura
  effect: "Passively cures asthma"
  cures: [asthma]
  blocked_by: [weariness]

kai_heal:
  skill: Kaido
  balance: kai
  effect: "Heal HP using kai"
  syntax: "KAI HEAL"
  notes: "Uses kai balance, separate from regular balance"

kai_cripple:
  skill: Kaido
  balance: kai
  effect: "Self-damage to cure affliction"
  syntax: "KAI CRIPPLE"
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
target_order: [throat, left_leg, right_leg]  # for throatchop or SSK
break_requirements:
  throat: 3  # for throatchop
  left_leg: 2  # for SSK
  right_leg: 2  # for SSK
finisher_options:
  - "THROATCHOP <target>"  # throat level 3
  - "SSK <target>"  # legs broken + prone
```

## Bashing (PvE)
```yaml
attack_command: "BATTLERAGE PUNCH <target>" or combos
attack_skill: Tekura
battlerage_abilities:
  - punch: "Basic damage"
  - kick: "Basic damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - weariness: "Restores your Fitness if you have it"
  - broken_limbs: "Prevent throatchop/SSK setup"
  - prone: "Stand up immediately"
  - mental_affs: "Telepathy can stack mental afflictions"

dangerous_abilities:
  - throatchop: "Instant kill if throat mangled"
  - ssk: "Massive damage when legs broken and prone"
  - combinations: "Fast limb damage accumulation"
  - kai_abilities: "Self-healing and utility"

avoid:
  - "Letting throat get to level 3"
  - "Being prone with both legs broken"
  - "Letting them combo freely"
  - "Ignoring mental afflictions from Telepathy"

recommended_strategy: |
  Parry throat/head to slow throatchop route.
  Parry legs if they're going SSK route.
  Keep restoration salve ready for limb damage.
  Track their kai balance for timing.
  Cure mental afflictions from Telepathy.
  Apply weariness to block their Fitness.
```

## Implementation Notes
```
Triggers to watch for:
- Combination attack patterns (SMP, SDK, etc.)
- "Your * is damaged/broken/mangled" - track limb state
- "executes a super side kick" - SSK incoming
- "chops at your throat" - throatchop attempt
- Telepathy ability messages

GMCP considerations:
- Track gmcp.Char.Vitals for limb percentages if available
- Otherwise parse damage messages
- Kai balance separate from regular bal/eq

Edge cases:
- Kai abilities use separate kai balance
- Shikudo requires Trans Tekura to unlock
- Combinations can hit multiple body parts
- SSK damage scales with leg breaks + prone
- Throatchop requires level 3 throat specifically
- Mental afflictions from Telepathy can add lock pressure
```
