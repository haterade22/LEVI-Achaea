# Apostate

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Damage
- **Difficulty**: Medium
- **Lock Affliction**: Voyria (blocks immunity elixir, prevents sip cure)

## Skills
```
Evileye: Gaze-based affliction application
Necromancy: Death magic and corpse manipulation
Apostasy: Demon summoning and unholy powers
```

## Kill Routes

### Primary Kill: True Lock with Voyria
```yaml
type: affliction
summary: Stack afflictions and use voyria to complete lock against sip-cure classes

prerequisites:
  - Must apply afflictions faster than target can cure
  - Voyria blocks immunity elixir (required for classes with sip-based cures)

steps:
  1: "Apply asthma via evileye or demon (blocks smoking)"
  2: "Apply slickness (blocks applying salves)"
  3: "Apply anorexia (blocks eating herbs)"
  4: "Apply paralysis (blocks tree tattoo)"
  5: "Apply impatience (blocks focus)"
  6: "Apply voyria (blocks immunity sip)"
  7: "Damage to death with demon attacks/necromancy"

required_afflictions:
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying"
  - paralysis: "blocks tree"
  - impatience: "blocks focus"
  - voyria: "blocks immunity elixir (class-specific lock aff)"
```

### Alternative Kill: Demon Damage
```yaml
type: damage
summary: Use demon attacks and necromancy for high damage output

steps:
  1: "Summon powerful demon"
  2: "Apply sensitivity to increase damage"
  3: "Command demon attacks while using necromancy damage"
  4: "Stack damage afflictions (darkshade, etc.)"
  5: "Kill through accumulated damage"

notes: "Different demons have different attack types and abilities"
```

### Alternative Kill: Evileye Lock
```yaml
type: affliction
summary: Use evileye gaze attacks for fast affliction stacking

steps:
  1: "EVILEYE <target> <affliction>"
  2: "Stack gazes rapidly"
  3: "Combine with demon afflictions"
  4: "Work toward true lock"

notes: "Evileye is eq-based, can combo with demon attacks"
```

## Offensive Abilities
```yaml
# Evileye
evileye:
  skill: Evileye
  balance: eq
  effect: "Apply affliction via gaze"
  syntax: "EVILEYE <target> <affliction>"
  afflictions_available:
    - asthma: "EVILEYE ASTHMA"
    - anorexia: "EVILEYE ANOREXIA"
    - slickness: "EVILEYE SLICKNESS"
    - paralysis: "EVILEYE PARALYSE"
    - impatience: "EVILEYE IMPATIENCE"
    - many_more

# Necromancy
lifedrain:
  skill: Necromancy
  balance: eq
  effect: "Drain life from target"
  damage_type: magic
  syntax: "SOULSPEAR <target>"

decay:
  skill: Necromancy
  balance: eq
  effect: "Cause decay damage"
  syntax: "DECAY <target>"

vivisect:
  skill: Necromancy
  balance: eq
  effect: "Instant kill on locked/low health target"
  syntax: "VIVISECT <target>"
  notes: "Requires specific conditions"

# Apostasy
summon:
  skill: Apostasy
  balance: eq
  effect: "Summon a demon"
  syntax: "SUMMON <demon>"
  demons:
    - rixil: "Fast attacks"
    - belial: "Damage focused"
    - cadmus: "Affliction focused"
    - hecate: "Utility/defense"
    - pyradius: "Fire damage"
    - palpatar: "Afflictions"
    - lycantha: "Limb damage"
    - nin_kharsag: "Powerful attacks"

order:
  skill: Apostasy
  balance: free
  effect: "Command demon to attack"
  syntax: "ORDER <demon> <command>"
```

## Defensive Abilities
```yaml
shroud:
  skill: Apostasy
  effect: "Demonic protection"
  syntax: "SHROUD"

soulshield:
  skill: Necromancy
  effect: "Soul-based defense"
  syntax: "SOULSHIELD"
```

## Passive Cures
```yaml
# Apostate doesn't have standard passive cures
# Relies on standard curing plus demon utility
```

## Limb Strategy
```yaml
enabled: partial
notes: "Lycantha demon can do limb damage but main focus is afflictions"
```

## Bashing (PvE)
```yaml
attack_command: "ORDER <demon> ATTACK <target>"
attack_skill: Apostasy
battlerage_abilities:
  - demon_attack: "Basic damage"
  - soulspear: "Magic damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - asthma: "Restore smoking ability"
  - slickness: "Restore salve application"
  - anorexia: "Restore eating ability"
  - paralysis: "Restore tree usage"
  - impatience: "Restore focus ability"
  - voyria: "SIP IMMUNITY to cure"

dangerous_abilities:
  - evileye: "Fast eq-based affliction application"
  - demon_attacks: "Additional damage and afflictions"
  - vivisect: "Potential instant kill"
  - lifedrain: "Heals them while damaging you"

avoid:
  - "Letting lock afflictions stack"
  - "Ignoring demon (can be killed)"
  - "Low health with voyria active (can't sip health)"

recommended_strategy: |
  Prioritize curing lock afflictions.
  Kill their demon if it's doing significant damage/afflictions.
  Keep immunity elixir sip available (voyria blocks it).
  Track their evileye usage to anticipate afflictions.
  Rebounding/shield helps slow evileye application.
  Watch for vivisect conditions being set up.
```

## Implementation Notes
```
Triggers to watch for:
- "fixes you with an icy stare" - evileye affliction incoming
- "A fiendish * appears" - demon summoned
- "orders * to attack" - demon attack incoming
- Various demon-specific attack messages
- "vivisects you" - instant kill attempt

GMCP considerations:
- Track gmcp.Char.Afflictions for current affs
- Demon presence via room items
- Evileye applications via messages

Edge cases:
- Evileye is eq-based, demon orders are free
- Different demons have different strengths
- Voyria is cured by sipping immunity
- Demons can be killed or dismissed
- Some evileye abilities have cooldowns
- Vivisect requires specific setup
```
