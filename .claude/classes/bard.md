# Bard

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Damage
- **Difficulty**: Medium
- **Lock Affliction**: Voyria (blocks immunity elixir sip)

## Skills
```
Composition: Song-based abilities and harmonics
Bladedance: Combat dancing with rapier
Sagas: Storytelling abilities and effects (default)
  -OR-
Woe: Alternative Cyrene-exclusive skill
```

## Specializations
```yaml
Sagas:
  description: "Default storytelling abilities"
  style: "Narrative-based combat effects"
  unlock: "Default for most bards"

Woe:
  description: "Cyrene-exclusive variant"
  style: "Alternative to Sagas"
  unlock: "Cyrene city exclusive"
```

## Kill Routes

### Primary Kill: Runeblade Resonance
```yaml
type: damage
summary: Build resonance through songs and attacks, culminating in burst damage

prerequisites:
  - Must build resonance on target
  - Resonance built through rapier attacks and songs

steps:
  1: "Apply songs for affliction pressure"
  2: "Use bladedance attacks to build resonance"
  3: "Stack resonance to high levels"
  4: "Trigger resonance for burst damage kill"

notes: "Resonance damage scales with buildup"
```

### Alternative Kill: Affliction Lock
```yaml
type: affliction
summary: Use composition and bladedance for affliction stacking

steps:
  1: "Apply afflictions through songs"
  2: "Use bladedance venoms for additional pressure"
  3: "Stack toward true lock"
  4: "Apply voyria to block immunity sip"
  5: "Damage to death through lock"

required_afflictions:
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying"
  - paralysis: "blocks tree"
  - impatience: "blocks focus"
  - voyria: "blocks immunity elixir (class-specific)"
```

### Alternative Kill: Song Damage
```yaml
type: damage
summary: Use song damage abilities for sustained output

steps:
  1: "Apply sensitivity"
  2: "Use damaging songs"
  3: "Combine with bladedance attacks"
  4: "Kill through accumulated damage"
```

## Offensive Abilities
```yaml
# Composition
song:
  skill: Composition
  balance: eq
  effect: "Play a song with various effects"
  syntax: "SING <song>"
  songs:
    - lament: "Damage over time"
    - cantata: "Affliction application"
    - requiem: "Devastating effect at high resonance"

tune:
  skill: Composition
  balance: eq
  effect: "Tune instrument for different effects"
  syntax: "TUNE <tuning>"

dissonance:
  skill: Composition
  balance: eq
  effect: "Apply dissonance affliction"
  syntax: "SING DISSONANCE AT <target>"

# Bladedance
slash:
  skill: Bladedance
  balance: bal
  effect: "Slash with rapier, can apply venom"
  syntax: "SLASH <target> <venom>"

thrust:
  skill: Bladedance
  balance: bal
  effect: "Thrust attack"
  syntax: "THRUST <target>"

riposte:
  skill: Bladedance
  balance: bal
  effect: "Counter-attack"
  syntax: "RIPOSTE <target>"

# Sagas
recite:
  skill: Sagas
  balance: eq
  effect: "Recite a saga for effect"
  syntax: "RECITE <saga>"
```

## Defensive Abilities
```yaml
fitness:
  skill: Bladedance
  effect: "Passively cures asthma"
  cures: [asthma]
  blocked_by: [weariness]

harmonic_shield:
  skill: Composition
  effect: "Song-based damage absorption"
  syntax: "SING HARMONY"
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
enabled: false
notes: "Bard is affliction/resonance-based, not limb-based"
```

## Bashing (PvE)
```yaml
attack_command: "BATTLERAGE SLASH <target>"
attack_skill: Bladedance
battlerage_abilities:
  - slash: "Basic damage"
  - song: "Song damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - asthma: "Restore smoking ability"
  - slickness: "Restore salve application"
  - anorexia: "Restore eating ability"
  - paralysis: "Restore tree usage"
  - dissonance: "Cure song afflictions"

dangerous_abilities:
  - resonance_burst: "High burst damage"
  - songs: "Affliction pressure and damage"
  - bladedance: "Venom application with rapier"

avoid:
  - "Letting resonance build high"
  - "Ignoring song afflictions"
  - "Letting lock afflictions stack"

recommended_strategy: |
  Track resonance buildup and pressure them.
  Cure song-based afflictions quickly.
  Prioritize curing lock afflictions.
  Apply weariness to block their Fitness.
  Rebounding helps slow their attacks.
  Don't let voyria stick or you can't sip immunity.
```

## Implementation Notes
```
Triggers to watch for:
- "sings a * at you" - song effect incoming
- "slashes at you with a rapier" - bladedance attack
- Resonance level messages
- Song effect messages

GMCP considerations:
- Track gmcp.Char.Afflictions for afflictions
- Resonance may need message parsing

Edge cases:
- Voyria is their class-specific lock aff
- Bladedance allows venom application
- Resonance builds and can burst
- Different songs have different effects
- Sagas vs Woe have different abilities
```
