# Occultist

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Instakill
- **Difficulty**: Hard
- **Lock Affliction**: Paralysis (already in lock - no special blocker needed)

## Skills
```
Domination: Entity summoning and control
Tarot: Card-based abilities and afflictions
Occultism: Esoteric powers and instakill mechanics
```

## Kill Routes

### Primary Kill: Absolve (Instakill)
```yaml
type: execute
summary: Stack "karma" through entity attacks, then absolve for instant kill

prerequisites:
  - Must accumulate sufficient karma on target
  - Karma builds through entity attacks and certain abilities

steps:
  1: "Summon entities (Hecate, Lycantha, etc.)"
  2: "Command entities to attack, building karma"
  3: "Use tarot and occultism abilities for additional karma"
  4: "When karma threshold reached, ABSOLVE <target>"
  5: "Target dies instantly"

notes: "Karma decays over time, must maintain pressure"
```

### Alternative Kill: Instill Lock
```yaml
type: affliction
summary: Use tarot instills to stack afflictions toward lock

steps:
  1: "INSTILL CARD WITH <affliction>"
  2: "FLING <card> AT <target>"
  3: "Stack lock afflictions"
  4: "Apply paralysis, impatience for true lock"
  5: "Damage or absolve to kill"

required_afflictions:
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying"
  - paralysis: "blocks tree"
  - impatience: "blocks focus"
```

### Alternative Kill: Entity Damage
```yaml
type: damage
summary: Use entities for sustained damage output

steps:
  1: "Summon damage-focused entities"
  2: "Command entity attacks"
  3: "Apply sensitivity to increase damage"
  4: "Combine with tarot damage"
  5: "Kill through accumulated damage"
```

## Offensive Abilities
```yaml
# Domination
summon:
  skill: Domination
  balance: eq
  effect: "Summon an entity"
  syntax: "SUMMON <entity>"
  entities:
    - hecate: "Affliction focused"
    - lycantha: "Limb damage"
    - palpatar: "Afflictions"
    - pyradius: "Fire damage"
    - cadmus: "Affliction stacking"
    - nin_kharsag: "Powerful attacks"

order:
  skill: Domination
  balance: free
  effect: "Command entity"
  syntax: "ORDER <entity> <command>"

# Tarot
instill:
  skill: Tarot
  balance: eq
  effect: "Instill a card with affliction"
  syntax: "INSTILL <card> WITH <affliction>"

fling:
  skill: Tarot
  balance: eq
  effect: "Throw instilled card at target"
  syntax: "FLING <card> AT <target>"

aeon:
  skill: Tarot
  balance: eq
  effect: "Apply aeon (slows all actions)"
  syntax: "FLING AEON AT <target>"
  notes: "One of most powerful afflictions"

lust:
  skill: Tarot
  balance: eq
  effect: "Force target to follow you"
  syntax: "FLING LUST AT <target>"

hermit:
  skill: Tarot
  balance: eq
  effect: "Transport to hermit card location"
  syntax: "FLING HERMIT"

# Occultism
warp:
  skill: Occultism
  balance: eq
  effect: "Damage ability"
  syntax: "WARP <target>"

absolve:
  skill: Occultism
  balance: eq
  effect: "Instant kill when karma threshold met"
  syntax: "ABSOLVE <target>"
  notes: "Main kill mechanic"

karma:
  skill: Occultism
  balance: eq
  effect: "Check karma level on target"
  syntax: "KARMA <target>"
```

## Defensive Abilities
```yaml
star:
  skill: Tarot
  effect: "Healing card"
  syntax: "FLING STAR"

moon:
  skill: Tarot
  effect: "Cloaking/invisibility"
  syntax: "FLING MOON"

priestess:
  skill: Tarot
  effect: "Barrier"
  syntax: "FLING PRIESTESS"
```

## Passive Cures
```yaml
# Occultist relies on standard curing
# No notable passive cures
```

## Limb Strategy
```yaml
enabled: partial
notes: "Lycantha entity can do limb damage but main focus is karma/afflictions"
```

## Bashing (PvE)
```yaml
attack_command: "ORDER <entity> ATTACK <target>"
attack_skill: Domination
battlerage_abilities:
  - entity_attack: "Basic damage"
  - warp: "Magic damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - aeon: "SMOKE ELM - extremely important, slows all actions"
  - asthma: "Restore smoking ability"
  - slickness: "Restore salve application"
  - anorexia: "Restore eating ability"
  - paralysis: "Restore tree usage"
  - impatience: "Restore focus ability"

dangerous_abilities:
  - absolve: "Instant kill when karma high"
  - aeon: "Slows all your actions significantly"
  - lust: "Forces you to follow them"
  - entities: "Additional damage and afflictions"

avoid:
  - "Letting karma build up"
  - "Ignoring aeon (cure immediately)"
  - "Being lusted into bad situations"
  - "Ignoring entities (can be killed)"

recommended_strategy: |
  Kill their entities to reduce karma generation.
  ALWAYS prioritize curing aeon - it cripples your ability to fight.
  Track karma buildup and pressure them when yours is low.
  Cure lust quickly to avoid being dragged.
  Rebounding helps slow tarot flings.
  Apply pressure to prevent karma from building.
```

## Implementation Notes
```
Triggers to watch for:
- "flings * at you" - tarot card incoming
- "Your karma * increases" - karma building
- "summons a" - entity summoned
- "orders * to" - entity command
- "absolves you" - instant kill attempt
- "slows down" - aeon applied

GMCP considerations:
- Track gmcp.Char.Afflictions for current affs
- Entity presence via room items
- No direct GMCP for karma level

Edge cases:
- Karma decays over time
- Entity orders are free balance
- Aeon slows ALL actions significantly
- Lust can be used to drag into traps
- Multiple entities can be summoned
- Some tarot cards have cooldowns
- Absolve fails if karma too low
```
