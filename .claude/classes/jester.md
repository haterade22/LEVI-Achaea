# Jester

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction
- **Difficulty**: Medium
- **Lock Affliction**: Paralysis (already in lock - no special blocker needed)

## Skills
```
Puppetry: Puppet manipulation for combat
Pranks: Tricks, traps, and mischief
Tarot: Card-based abilities (shared with Occultist)
```

## Kill Routes

### Primary Kill: Puppet Lock
```yaml
type: affliction
summary: Use puppets to stack afflictions faster than target can cure

prerequisites:
  - Must have target's puppet fashioned
  - Puppet must have hair/blood binding

steps:
  1: "FASHION PUPPET FOR <target>"
  2: "BIND <target> TO PUPPET (requires hair or blood)"
  3: "CURSE PUPPET WITH <affliction>"
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

notes: "Jester doesn't need extra lock aff - paralysis in lock is sufficient"
```

### Alternative Kill: Tarot Lock
```yaml
type: affliction
summary: Use tarot cards for affliction pressure

steps:
  1: "INSTILL cards with afflictions"
  2: "FLING cards at target"
  3: "Use aeon for slowing"
  4: "Stack toward true lock"
  5: "Damage to death"
```

### Alternative Kill: Pranks Damage
```yaml
type: damage
summary: Use prank abilities for damage and harassment

steps:
  1: "Set up traps and prank items"
  2: "Apply sensitivity"
  3: "Use damaging pranks"
  4: "Kill through accumulated damage and pressure"
```

## Offensive Abilities
```yaml
# Puppetry
fashion:
  skill: Puppetry
  balance: eq
  effect: "Create a puppet for target"
  syntax: "FASHION PUPPET FOR <target>"
  notes: "Required before puppet attacks"

bind_puppet:
  skill: Puppetry
  balance: eq
  effect: "Bind target to puppet using hair or blood"
  syntax: "BIND <target> TO PUPPET"
  notes: "Must have their hair/blood"

curse_puppet:
  skill: Puppetry
  balance: eq
  effect: "Apply affliction through puppet"
  syntax: "CURSE PUPPET WITH <affliction>"
  afflictions_available:
    - asthma
    - anorexia
    - slickness
    - paralysis
    - impatience
    - many_more

pincushion:
  skill: Puppetry
  balance: eq
  effect: "Damage through puppet"
  syntax: "PINCUSHION PUPPET"

# Pranks
blackjack:
  skill: Pranks
  balance: bal
  effect: "Knock target unconscious"
  syntax: "BLACKJACK <target>"
  notes: "From behind only"

handspring:
  skill: Pranks
  balance: bal
  effect: "Acrobatic attack"
  syntax: "HANDSPRING <target>"

trip:
  skill: Pranks
  balance: bal
  effect: "Trip target, causes prone"
  syntax: "TRIP <target>"

concertina:
  skill: Pranks
  balance: eq
  effect: "Play concertina for effects"
  syntax: "PLAY CONCERTINA"

# Tarot (shared with Occultist)
instill:
  skill: Tarot
  balance: eq
  effect: "Instill a card with affliction"
  syntax: "INSTILL <card> WITH <affliction>"

fling:
  skill: Tarot
  balance: eq
  effect: "Throw card at target"
  syntax: "FLING <card> AT <target>"

aeon:
  skill: Tarot
  balance: eq
  effect: "Apply aeon (slows all actions)"
  syntax: "FLING AEON AT <target>"
```

## Defensive Abilities
```yaml
backflip:
  skill: Pranks
  effect: "Acrobatic dodge"
  syntax: "BACKFLIP"

fool_card:
  skill: Tarot
  effect: "Escape using fool tarot"
  syntax: "FLING FOOL"
```

## Passive Cures
```yaml
# Jester relies on standard curing
# No notable passive cures
```

## Limb Strategy
```yaml
enabled: false
notes: "Jester is affliction-based, not limb-based"
```

## Bashing (PvE)
```yaml
attack_command: "BATTLERAGE HANDSPRING <target>"
attack_skill: Pranks
battlerage_abilities:
  - handspring: "Basic damage"
  - pincushion: "Puppet damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - aeon: "SMOKE ELM - slows all actions"
  - asthma: "Restore smoking ability"
  - slickness: "Restore salve application"
  - anorexia: "Restore eating ability"
  - paralysis: "Restore tree usage"

dangerous_abilities:
  - puppet: "Remote affliction application"
  - aeon: "Slows ALL actions"
  - blackjack: "Unconsciousness from behind"
  - traps: "Various prank traps"

avoid:
  - "Letting them get your hair/blood for puppet"
  - "Letting aeon stick"
  - "Being approached from behind (blackjack)"
  - "Standing on their prank traps"

recommended_strategy: |
  Destroy or steal their puppet if possible.
  Don't give them hair/blood for binding.
  Prioritize curing aeon immediately.
  Cure lock afflictions quickly.
  Keep vigilance up to prevent blackjack.
  Watch for trap locations.
```

## Implementation Notes
```
Triggers to watch for:
- "fashions a small puppet" - they created a puppet
- "binds * to the puppet" - puppet now linked
- "curses the puppet" - affliction incoming
- "jabs pins into" - pincushion damage
- "flings * at you" - tarot card incoming
- "slows down" - aeon applied
- Various prank messages

GMCP considerations:
- Track gmcp.Char.Afflictions for afflictions
- No direct GMCP for puppet status
- Aeon in afflictions

Edge cases:
- Puppet must be fashioned and bound to work
- Hair/blood can be obtained various ways
- Blackjack requires being behind target
- Aeon is very dangerous, cure immediately
- Pranks can set up traps
- Puppet can be destroyed or stolen
```
