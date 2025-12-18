# Shaman

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction
- **Difficulty**: Hard
- **Lock Affliction**: Paralysis (already in lock - no special blocker needed)

## Skills
```
Vodun: Voodoo doll manipulation for afflictions
Curses: Direct curse afflictions and debuffs
Spiritlore: Spirit binding and shamanic powers
```

## Kill Routes

### Primary Kill: Vodun Puppet Lock
```yaml
type: affliction
summary: Use vodun doll to stack afflictions faster than target can cure

prerequisites:
  - Must have target's doll fashioned (FASHION DOLL FOR <target>)
  - Doll must have hair/blood (BIND <target> TO DOLL)

steps:
  1: "FASHION DOLL FOR <target>"
  2: "BIND <target> TO DOLL (requires hair or blood)"
  3: "CURSE DOLL WITH <affliction> to apply afflictions"
  4: "Stack toward true lock: asthma, anorexia, slickness"
  5: "Apply paralysis to block tree"
  6: "Apply impatience to block focus"
  7: "Damage to death through lock"

required_afflictions:
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying"
  - paralysis: "blocks tree"
  - impatience: "blocks focus"

notes: "Shaman doesn't need extra lock aff - paralysis in lock is sufficient"
```

### Alternative Kill: Curse Stack
```yaml
type: affliction
summary: Use Curses skill to directly apply afflictions

steps:
  1: "CURSE <target> <curse> to apply afflictions"
  2: "Stack curses for affliction pressure"
  3: "Combine with vodun for faster stacking"
  4: "Work toward lock or damage kill"
```

### Alternative Kill: Spiritlore Spirits
```yaml
type: damage
summary: Use bound spirits for damage and utility

steps:
  1: "Bind spirits for combat"
  2: "Command spirits to attack"
  3: "Combine spirit damage with affliction pressure"
  4: "Kill through accumulated damage"
```

## Offensive Abilities
```yaml
# Vodun
fashion:
  skill: Vodun
  balance: eq
  effect: "Create a vodun doll for target"
  syntax: "FASHION DOLL FOR <target>"
  notes: "Required before doll attacks"

bind:
  skill: Vodun
  balance: eq
  effect: "Bind target to doll using hair or blood"
  syntax: "BIND <target> TO DOLL"
  notes: "Must have their hair/blood"

curse_doll:
  skill: Vodun
  balance: eq
  effect: "Apply affliction through doll"
  syntax: "CURSE DOLL WITH <affliction>"
  afflictions_available:
    - asthma
    - anorexia
    - slickness
    - paralysis
    - impatience
    - many_more

pincushion:
  skill: Vodun
  balance: eq
  effect: "Damage through doll"
  syntax: "PINCUSHION DOLL"

decay:
  skill: Vodun
  balance: eq
  effect: "Cause limb damage through doll"
  syntax: "DECAY <limb>"

# Curses
curse:
  skill: Curses
  balance: eq
  effect: "Apply curse affliction"
  syntax: "CURSE <target> <curse>"

jinx:
  skill: Curses
  balance: eq
  effect: "Apply jinx debuff"
  syntax: "JINX <target>"

swiftcurse:
  skill: Curses
  balance: eq
  effect: "Fast curse application"
  syntax: "SWIFTCURSE <target> <curse>"

# Spiritlore
bind_spirit:
  skill: Spiritlore
  balance: eq
  effect: "Bind a spirit for combat"
  syntax: "SPIRITBIND <spirit>"

command_spirit:
  skill: Spiritlore
  balance: eq
  effect: "Command bound spirit"
  syntax: "SPIRIT <command>"
```

## Defensive Abilities
```yaml
spiritshield:
  skill: Spiritlore
  effect: "Spirit-based defense"
  syntax: "SPIRITSHIELD"

ancestors:
  skill: Spiritlore
  effect: "Call upon ancestors for protection"
  syntax: "ANCESTORS"
```

## Passive Cures
```yaml
# Shaman has no notable passive cures
# They rely on standard curing
```

## Limb Strategy
```yaml
enabled: partial
target_order: [head, torso]  # decay can target limbs
break_requirements:
  head: 2  # for concussion effects
notes: "Decay ability can damage limbs through doll but main focus is afflictions"
```

## Bashing (PvE)
```yaml
attack_command: "BATTLERAGE PINCUSHION"
attack_skill: Vodun
battlerage_abilities:
  - pincushion: "Basic damage through doll"
  - spirits: "Spirit attacks"
```

## Fighting Against This Class
```yaml
priority_cures:
  - asthma: "Restore smoking ability"
  - slickness: "Restore salve application"
  - anorexia: "Restore eating ability"
  - paralysis: "Restore tree usage"
  - impatience: "Restore focus ability"

dangerous_abilities:
  - vodun_doll: "Remote affliction application"
  - swiftcurse: "Fast curse stacking"
  - decay: "Remote limb damage"
  - spirits: "Additional damage/utility"

avoid:
  - "Letting them get your hair/blood for doll"
  - "Letting curse stacks accumulate"
  - "Ignoring spirits"

recommended_strategy: |
  Destroy or steal their vodun doll if possible.
  Don't give them hair/blood for binding.
  Prioritize curing lock afflictions.
  Track their curse applications.
  Kill bound spirits if they're doing significant damage.
  Keep rebounding up to slow curse application.
```

## Implementation Notes
```
Triggers to watch for:
- "fashions a small doll" - they created a doll
- "binds * to the doll" - doll now linked
- "curses the doll" - affliction incoming
- "jabs pins into" - pincushion damage
- Various curse messages

GMCP considerations:
- Track gmcp.Char.Afflictions for current affs
- No direct GMCP for doll status
- Track curse applications via messages

Edge cases:
- Doll must be fashioned and bound to work
- Hair/blood can be obtained various ways
- Some curses have cooldowns
- Spirits have limited duration
- Doll can be destroyed or stolen
- Binding persists until doll destroyed
```
