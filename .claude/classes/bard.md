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
attack_command: "blade flick <target>"   # flick's raze (nomos) is baked into the composition, so no refrain needed; OR 'blade punctuate <target> paean' (punctuate IS the raze; paean is the song) when the bashPunctuate toggle is on (psychic-resistant denizens)
attack_skill: Bladedance
warmarch: "Mnemosyne 'Warmarch' boon makes the paean refrain hit denizens (+100% psychic). While bardWarmarch is set, flick becomes 'blade flick <target> paean'. Set on boon claim / seeing it in the BOONS list; cleared on Mnemosyne run start/end (triggers 001/009/010)."
mechanic:
  footwork_tempo: "The dance auto-cycles front -> side -> back -> loop as you attack. Tempo/stance sets attacks-per-position before you're carried onward: Adagio 4/4/3, Moderato 3/2/2, Allegro 2/1/1, none 5/2/1. Tracked by bardtempo/bardtempostance/bardtemposequence (tempo triggers)."
  back_bonus: "Bladedance attacks vs denizens deal BONUS DAMAGE from the back position (AB FOOTWORK). The bashing goal is to maximize back-position uptime."
battlerage: "ataxiaBasher_bardBattlerage() (basher/001). Priority: culling blade (reap, if off cooldown) > charm 2nd denizen (2+ denizens, >=32 rage) > trill target (2+ denizens, >=28, off ~42s cd) > howlslash (>=36) > moulinet (>=14)."
lifecycle:
  bash_start: "basher_engaged() (genrunning/003) sets tempo (bashTempo) and calls ataxiaBasher_bardCompose() ONCE."
  compose: "ataxiaBasher_bardCompose() (basher/002) wields the lyre (required to perform), ends any prior performance, composes bashCompose, and arms the 15-min 'Bard Performance' timer. Compose is NOT done per attack."
  refresh: "The performance lasts 15 min. On timer expiry the Bard Performance timer (timers/004) re-runs ataxiaBasher_bardCompose(); disengage disables the timer so it never fires while idle. If it lapses early, the 'You can hardly manipulate a grand performance...' line (performance_tracking/005) also re-composes while bashing."
config:
  bashTempo: "ataxia.bardStuff.bashTempo (default 'moderato'). Sent as 'TEMPO <name>' at bash start. Alias: 'bashtempo <adagio|moderato|allegro|none>'. 'none' = unmanaged."
  bashCompose: "ataxia.bardStuff.bashCompose (default 'paean prelude scherzo sonata maqam') = paean song + prelude/scherzo(regen)/sonata(cleanse)/maqam(crit)."
  bashPunctuate: "ataxia.bardStuff.bashPunctuate (default false). Toggle with the 'bashpunctuate' alias; true -> attack becomes 'blade punctuate <target> paean' for psychic-resistant denizens."
tempo_choice:
  moderato: "Best steady-state back share (2 of every 7 hits); default. First back attack at hit #6."
  allegro: "Reaches back fastest (hit #4) -> more back hits per kill on squishy denizens that die before Moderato ever reaches back."
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
