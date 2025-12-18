# Psion

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Damage
- **Difficulty**: Hard
- **Lock Affliction**: Confusion (disrupts their weaving/emulation)

## Skills
```
Weaving: Aldar magic thread manipulation
Psionics: Mental powers and attacks
Emulation: Copy and replicate abilities
```

## Kill Routes

### Primary Kill: Mind Crush
```yaml
type: execute
summary: Build mental damage, then crush mind for instant kill

prerequisites:
  - Must accumulate sufficient mental damage
  - Target's mental state must be weakened

steps:
  1: "Apply mental afflictions through Psionics"
  2: "Build mental damage through attacks"
  3: "Weaken target's mental defenses"
  4: "When threshold met, MINDCRUSH <target>"

notes: "Mental damage tracked separately from physical"
```

### Alternative Kill: Affliction Lock
```yaml
type: affliction
summary: Use Psionics for affliction stacking

steps:
  1: "Apply mental afflictions through Psionics"
  2: "Use Weaving for additional pressure"
  3: "Stack toward true lock"
  4: "Apply confusion to block their abilities"
  5: "Damage to death through lock"

required_afflictions:
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying"
  - paralysis: "blocks tree"
  - impatience: "blocks focus"
  - confusion: "disrupts weaving/emulation (class-specific)"
```

### Alternative Kill: Emulation Damage
```yaml
type: damage
summary: Use emulated abilities for damage

steps:
  1: "Emulate powerful damage abilities"
  2: "Apply sensitivity"
  3: "Use emulated and native attacks"
  4: "Kill through accumulated damage"

notes: "Emulation allows copying abilities from other classes"
```

## Offensive Abilities
```yaml
# Weaving
weave:
  skill: Weaving
  balance: eq
  effect: "Weave Aldar magic threads"
  syntax: "WEAVE <pattern>"
  patterns:
    - binding: "Root target"
    - destruction: "Damage"
    - affliction: "Apply afflictions"

thread:
  skill: Weaving
  balance: eq
  effect: "Manipulate magic threads"
  syntax: "THREAD <ability>"

# Psionics
mindblast:
  skill: Psionics
  balance: eq
  effect: "Mental damage attack"
  damage_type: mental
  syntax: "MINDBLAST <target>"

mindcrush:
  skill: Psionics
  balance: eq
  effect: "Instant kill when mental damage high"
  syntax: "MINDCRUSH <target>"
  notes: "Main execute ability"

dominate:
  skill: Psionics
  balance: eq
  effect: "Dominate target's mind"
  syntax: "DOMINATE <target>"

mindread:
  skill: Psionics
  balance: eq
  effect: "Read target's mind"
  syntax: "MINDREAD <target>"

# Emulation
emulate:
  skill: Emulation
  balance: eq
  effect: "Copy an ability from another class"
  syntax: "EMULATE <ability>"
  notes: "Can copy abilities from classes you've studied"

study:
  skill: Emulation
  balance: eq
  effect: "Study a class for emulation"
  syntax: "STUDY <class>"
```

## Defensive Abilities
```yaml
mindshield:
  skill: Psionics
  effect: "Mental damage reduction"
  syntax: "MINDSHIELD"

weave_defense:
  skill: Weaving
  effect: "Defensive thread pattern"
  syntax: "WEAVE DEFENSE"
```

## Passive Cures
```yaml
# Psion has weaving-based curing
# Confusion disrupts their weaving ability
weave_cure:
  cures: [various]
  blocked_by: [confusion]
  trigger: "Weave cure pattern"
```

## Limb Strategy
```yaml
enabled: false
notes: "Psion is mental/affliction-based, not limb-based"
```

## Bashing (PvE)
```yaml
attack_command: "MINDBLAST <target>"
attack_skill: Psionics
battlerage_abilities:
  - mindblast: "Mental damage"
  - weave: "Thread damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - asthma: "Restore smoking ability"
  - slickness: "Restore salve application"
  - anorexia: "Restore eating ability"
  - paralysis: "Restore tree usage"
  - mental_affs: "Various Psionics afflictions"

dangerous_abilities:
  - mindcrush: "Instant kill when mental damage high"
  - mindblast: "Mental damage buildup"
  - emulation: "Can use abilities from other classes"
  - weaving: "Various thread effects"

avoid:
  - "Letting mental damage build up"
  - "Ignoring mental afflictions"
  - "Being surprised by emulated abilities"
  - "Standing in weave binding"

recommended_strategy: |
  Track mental damage and pressure them.
  Apply confusion to block their weaving cures.
  Be prepared for emulated abilities.
  Cure mental afflictions quickly.
  Prioritize curing lock afflictions.
  Aggressive offense to prevent mindcrush buildup.
```

## Implementation Notes
```
Triggers to watch for:
- "blasts your mind" - mental damage
- "weaves a *" - thread being woven
- "crushes your mind" - mindcrush attempt
- "emulates" - ability being copied
- Mental affliction messages

GMCP considerations:
- Track gmcp.Char.Afflictions for afflictions
- Mental damage may need message parsing
- Confusion in afflictions

Edge cases:
- Confusion blocks their weaving cures (class-specific)
- Mental damage tracked separately
- Emulation can copy many different abilities
- Weave patterns have different effects
- Mind crush requires mental damage threshold
- Studied classes determine emulation options
```
