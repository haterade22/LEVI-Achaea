# Pariah

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Damage
- **Difficulty**: Hard
- **Lock Affliction**: Voyria (blocks immunity elixir sip)

## Skills
```
Memorium: Memory manipulation and mental powers
Pestilence: Disease and plague abilities
Charnel: Death and corpse manipulation
```

## Kill Routes

### Primary Kill: Pestilence Kill
```yaml
type: affliction
summary: Stack diseases and plagues to overwhelm target

prerequisites:
  - Must accumulate disease stacks on target
  - Diseases spread and worsen over time

steps:
  1: "Apply initial diseases through Pestilence"
  2: "Stack diseases to increase severity"
  3: "Apply voyria to block immunity sipping"
  4: "Let diseases compound and spread"
  5: "Target dies from overwhelming plague"

notes: "Diseases can spread to max severity if uncured"
```

### Alternative Kill: Affliction Lock
```yaml
type: affliction
summary: Use Memorium and Pestilence for affliction stacking

steps:
  1: "Apply mental afflictions through Memorium"
  2: "Apply physical afflictions through Pestilence"
  3: "Stack toward true lock"
  4: "Apply voyria to block immunity"
  5: "Damage to death through lock"

required_afflictions:
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying"
  - paralysis: "blocks tree"
  - impatience: "blocks focus"
  - voyria: "blocks immunity elixir (class-specific)"
```

### Alternative Kill: Charnel Damage
```yaml
type: damage
summary: Use death-based damage abilities

steps:
  1: "Apply sensitivity"
  2: "Use Charnel damage abilities"
  3: "Combine with disease pressure"
  4: "Kill through accumulated damage"
```

## Offensive Abilities
```yaml
# Memorium
memory:
  skill: Memorium
  balance: eq
  effect: "Manipulate target's memories"
  syntax: "MEMORY <ability> <target>"

forget:
  skill: Memorium
  balance: eq
  effect: "Force target to forget"
  syntax: "FORGET <target>"
  affliction: amnesia

implant:
  skill: Memorium
  balance: eq
  effect: "Implant false memory"
  syntax: "IMPLANT <target>"

# Pestilence
infect:
  skill: Pestilence
  balance: eq
  effect: "Infect target with disease"
  syntax: "INFECT <target> <disease>"
  diseases:
    - plague: "General weakening"
    - consumption: "Drains health"
    - fever: "Confusion and weakness"
    - many_more: "Various diseases"

spread:
  skill: Pestilence
  balance: eq
  effect: "Spread diseases to others"
  syntax: "SPREAD <target>"

worsen:
  skill: Pestilence
  balance: eq
  effect: "Worsen existing disease"
  syntax: "WORSEN <target>"

# Charnel
drain:
  skill: Charnel
  balance: eq
  effect: "Drain life from target"
  syntax: "DRAIN <target>"
  damage_type: magic

corpse:
  skill: Charnel
  balance: eq
  effect: "Manipulate corpses"
  syntax: "CORPSE <ability>"

deathaura:
  skill: Charnel
  balance: eq
  effect: "Emanate death aura"
  syntax: "DEATHAURA"
```

## Defensive Abilities
```yaml
disease_resistance:
  skill: Pestilence
  effect: "Resistance to diseases"
  notes: "Pariahs are resistant to their own plagues"

corpse_shield:
  skill: Charnel
  effect: "Use corpse for defense"
  syntax: "CORPSE SHIELD"
```

## Passive Cures
```yaml
# Pariah relies on standard curing
# Voyria blocks their immunity elixir use as well
```

## Limb Strategy
```yaml
enabled: false
notes: "Pariah is disease/affliction-based, not limb-based"
```

## Bashing (PvE)
```yaml
attack_command: "BATTLERAGE DRAIN <target>"
attack_skill: Charnel
battlerage_abilities:
  - drain: "Life drain damage"
  - infect: "Disease damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - diseases: "Cure diseases before they worsen"
  - asthma: "Restore smoking ability"
  - slickness: "Restore salve application"
  - anorexia: "Restore eating ability"
  - amnesia: "From Memorium"
  - voyria: "SIP IMMUNITY to cure"

dangerous_abilities:
  - diseases: "Stack and worsen over time"
  - spread: "Can spread diseases"
  - drain: "Life drain damage"
  - memory_manipulation: "Mental afflictions"

avoid:
  - "Letting diseases stack and worsen"
  - "Ignoring voyria (can't sip immunity)"
  - "Standing near diseased allies"
  - "Letting lock afflictions stack"

recommended_strategy: |
  Cure diseases quickly before they worsen.
  Don't let voyria stick - need immunity sips.
  Track disease severity levels.
  Prioritize curing lock afflictions.
  Stay away from diseased allies to prevent spread.
  Pressure them to prevent disease stacking.
```

## Implementation Notes
```
Triggers to watch for:
- "infects you with" - disease applied
- "Your * worsens" - disease severity increased
- "spreads" - disease spreading
- "drains life from" - charnel damage
- Memory manipulation messages
- Amnesia application

GMCP considerations:
- Track gmcp.Char.Afflictions for afflictions
- Disease severity may need message parsing
- Voyria in afflictions

Edge cases:
- Voyria is their class-specific lock aff
- Diseases worsen over time if uncured
- Disease spread can affect multiple targets
- Corpse abilities require corpses
- Death aura is room-wide effect
- Memory manipulation causes mental affs
```
