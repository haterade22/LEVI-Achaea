# Waterlord

## Metadata
- **Type**: Elemental Lord
- **Combat Style**: Affliction | Execute
- **Difficulty**: Hard
- **Lock Affliction**: Weariness (blocks Purify passive cure)

## Skills
```
Subjugation: Elemental dominion and control
Manifestation: Elemental body transformation (Water Form)
Evocation: Water elemental attacks, Flux combos, Desiccate/Drown
```

## Core Combat Mechanics
```yaml
flux_system:
  description: "Combination ability that gives bonus effects to first ability"
  syntax: "FLUX <ability1> <ability2>"
  mechanic: "First ability in combo gets bonus effect (shown in parentheses)"
  usage: "Core to Waterlord offense - chain abilities for synergies"

latch_system:
  description: "Key ability for instakill setup"
  tracked_afflictions: [addiction, haemophilia, nausea, lethargy, severe_bleeding]
  effects_by_count:
    2: "Binding effect, hinders fleeing"
    3: "Moderate bleeding (or increases existing bleeding)"
    4: "Knocks sip balance, sets up instakill (requires severe bleeding)"
  severe_bleeding_threshold: 200

flooding:
  saturation: "Floods current room"
  submerge: "Floods all adjacent rooms (requires flooded room)"
  benefits:
    - "Purify gives second cure 10s later in water"
    - "Tidalwave ignores movement hinders in flooded rooms"
    - "Whirlpool beckons from all adjacent flooded rooms"
    - "Drown without Rise if underwater"
```

## Kill Routes

### Primary Kill: Desiccate (Latch Execute)
```yaml
type: execute
summary: Latch with 4 afflictions including severe bleeding, then Desiccate within sip balance window

prerequisites:
  latch_requirements:
    - "4 afflictions from: addiction, haemophilia, nausea, lethargy, severe bleeding"
    - "One MUST be severe bleeding (200+)"
    - "Haemophilia required to maintain bleeding"

mechanics:
  latch_effect: "Knocks target off sip balance"
  window: "~4.5 seconds to Desiccate before sip balance returns"
  follow: "Can follow if they leave room - kill still completes"

steps:
  1: "Apply haemophilia via THIN"
  2: "Apply 200+ bleeding via THIN (if already haemophilic)"
  3: "Apply nausea via ROIL"
  4: "Apply lethargy via PARCH or addiction via FLUX PARCH"
  5: "LATCH when 4 afflictions present (including severe bleeding)"
  6: "Target knocked off sip balance"
  7: "DESICCATE within ~4.5 seconds"

notes: |
  Standard kill path for Waterlords.
  Target may prioritize latch afflictions - watch for focuslock opening.
  Can follow to complete kill even if they flee.
```

### Alternative Kill: Drown (Channeled)
```yaml
type: execute
summary: Channeled instakill sped up by asthma and nausea

prerequisites:
  - Must use RISE if not standing underwater
  - Channel time reduced by asthma and/or nausea

steps:
  1: "Apply asthma via CHOKE"
  2: "Apply nausea via ROIL"
  3: "If not underwater, RISE <target>"
  4: "DROWN <target> (channeled)"

notes: |
  Asthma and nausea both speed up the channel.
  Underwater allows direct Drown without Rise.
```

### Alternative Kill: Focuslock
```yaml
type: affliction
summary: Lock target when they over-prioritize curing latch afflictions

mechanics:
  available_lock_affs:
    asthma: "CHOKE"
    slickness: "PERSPIRE"
    weariness: "DRENCH"
    paralysis: "FLUX CHOKE (gated behind nausea + weariness + asthma)"
    anorexia: "FLUX ROIL (gated behind asthma + weariness)"

  gating:
    paralysis: "Requires nausea + weariness + asthma present"
    anorexia: "Requires asthma + weariness present"

steps:
  1: "Apply asthma via CHOKE"
  2: "Apply weariness via DRENCH"
  3: "Apply slickness via PERSPIRE"
  4: "Apply nausea via ROIL"
  5: "FLUX CHOKE for paralysis (with nausea + weariness + asthma)"
  6: "FLUX ROIL for anorexia (with asthma + weariness)"
  7: "Knock focus balance repeatedly with ROIL (if nauseous) or FLUX DRENCH"
  8: "Apply stupidity + recklessness via WRECK"
  9: "Target struggles to cure anorexia with stupidity"

notes: |
  Opens when targets over-cure latch afflictions.
  Repeatedly knock focus balance to prevent breaking lock.
  Stupidity + recklessness severely lowers cure chances.
```

## Group Combat Tactics
```yaml
role: "Distance beckon, affliction pressure, damage output"

tsunami_utility:
  description: "Distance beckon - great threat"
  range: "Up to 3 rooms (5 with artefact)"
  warning: "Floods your room - can upset runelorists"

group_synergy:
  description: "Coordinate with impatience givers for fast locks"
  synergy_classes: [apostate, shaman, bard]
  reason: "Waterlord struggles with paralysis and anorexia"
  strategy: "Others give paralysis/anorexia while you provide rest"

wreck_damage:
  description: "High damage output in groups"
  effect: "Stupidity + recklessness, or damage if either present"
  max_damage: "Requires target to be PRONE and PARALYZED"
  notes: "Damage significantly reduced without both conditions"
```

## Offensive Abilities
```yaml
# Primary Attacks
blade:
  skill: Evocation
  balance: bal
  effect: "Simple damage, breaks shield if present"
  syntax: "BLADE <target>"
  notes: "Shield break utility"

flux:
  skill: Evocation
  balance: bal
  effect: "Combo ability - first ability gets bonus effect"
  syntax: "FLUX <ability1> <ability2>"
  notes: "Core offensive mechanic"

# Affliction Abilities
choke:
  skill: Evocation
  balance: bal
  effect: "Gives asthma. If asthmatic: hallucinations"
  syntax: "CHOKE <target>"
  flux_bonus: "If nausea + weariness present: also paralysis"

drench:
  skill: Evocation
  balance: bal
  effect: "Gives weariness. If weary: confusion"
  syntax: "DRENCH <target>"
  flux_bonus: "If asthma + slickness + anorexia present: knocks focus balance"

parch:
  skill: Evocation
  balance: bal
  effect: "Gives lethargy"
  syntax: "PARCH <target>"
  flux_bonus: "If weariness + haemophilia present: also addiction"

perspire:
  skill: Evocation
  balance: bal
  effect: "Gives slickness AND prones"
  syntax: "PERSPIRE <target>"

roil:
  skill: Evocation
  balance: bal
  effect: "Gives nausea. If nauseous: knocks focus balance"
  syntax: "ROIL <target>"
  flux_bonus: "If asthma + weariness present: also anorexia"

thin:
  skill: Evocation
  balance: bal
  effect: "Gives haemophilia. If haemophilic: 200 bleeding"
  syntax: "THIN <target>"
  notes: "Key for latch setup (need haemophilia + 200 bleeding)"

wreck:
  skill: Evocation
  balance: bal
  effect: "Gives stupidity AND recklessness"
  syntax: "WRECK <target>"
  if_present: "Does damage if either affliction already present"
  max_damage: "Full damage only if PRONE and PARALYZED"
  notes: "Damage significantly reduced without both conditions"

# Instakill Setup
latch:
  skill: Evocation
  balance: bal
  effect: "Various effects based on affliction count"
  syntax: "LATCH <target>"
  tracked_affs: [addiction, haemophilia, nausea, lethargy, severe_bleeding]
  effects:
    2: "Binding effect, hinders fleeing"
    3: "Moderate bleeding or increases existing"
    4: "Knocks sip balance, sets up instakill (need severe bleeding)"
  notes: "4 affs with severe bleeding = ~4.5s window for Desiccate"

desiccate:
  skill: Evocation
  balance: bal
  effect: "Instant kill after successful 4-aff Latch"
  syntax: "DESICCATE <target>"
  requirement: "Must Latch with 4 afflictions first"
  window: "~4.5 seconds after Latch"
  notes: "Can follow to complete if they flee"

rise:
  skill: Evocation
  balance: eq
  effect: "Lift target for Drown (if not underwater)"
  syntax: "RISE <target>"

drown:
  skill: Evocation
  balance: eq
  effect: "Channeled instakill"
  syntax: "DROWN <target>"
  sped_by: [asthma, nausea]
  notes: "No Rise needed if underwater"

# Movement/Utility
tsunami:
  skill: Evocation
  balance: eq
  effect: "Beckon from distance"
  syntax: "TSUNAMI <target>"
  range: "Up to 3 rooms (5 with artefact)"
  side_effect: "Floods your room"

whirlpool:
  skill: Evocation
  balance: eq
  effect: "Beckon all adjacent flooded rooms"
  syntax: "WHIRLPOOL"
  requirement: "Must be in flooded room, adjacent rooms flooded"
```

## Defensive Abilities
```yaml
purify:
  skill: Evocation
  balance: bal
  effect: "Cures an affliction"
  syntax: "PURIFY"
  cooldown: "10 seconds"
  blocked_by: [weariness]
  water_bonus: "In water: cures SECOND affliction 10s later"
  note: "Secondary cure NOT blocked by weariness"

tidalwave:
  skill: Evocation
  balance: eq
  effect: "Carry as far as possible in one direction"
  syntax: "TIDALWAVE <direction>"
  mechanics:
    - "Goes over walls"
    - "Blocked by closed doors"
    - "In flooded room: ignores movement hindering effects"

lifestream:
  skill: Evocation
  balance: eq
  effect: "Self healing (can heal others)"
  syntax: "LIFESTREAM" or "LIFESTREAM <target>"
  notes: "Similar to Devotionist Hands"

cohesion:
  skill: Evocation
  effect: "Persistent defence, lowers incoming damage"
  syntax: "COHESION"

saturation:
  skill: Evocation
  balance: eq
  effect: "Floods the current room"
  syntax: "SATURATION"

submerge:
  skill: Evocation
  balance: eq
  effect: "Floods all adjacent rooms"
  syntax: "SUBMERGE"
  requirement: "Must be in flooded room"

hydra:
  skill: Evocation
  balance: eq
  effect: "Summon a hydra"
  syntax: "HYDRA"
  warning: |
    LAST RESORT ONLY.
    Leaves you incredibly weak and momentarily stunned.
    Hydra attacks ANYONE not a water elemental, including allies.
```

## Passive Cures
```yaml
purify:
  cures: [one_affliction]
  blocked_by: [weariness]
  cooldown: "10 seconds"
  trigger: "Active ability, uses balance"
  water_bonus: "Second affliction cured 10s later in water (not blocked by weariness)"
  notes: "Weariness is class-specific lock affliction"
```

## Limb Strategy
```yaml
enabled: false
notes: "Waterlord is affliction-based, not limb-based"
```

## Bashing (PvE)
```yaml
attack_command: "BLADE <target>"
attack_skill: Evocation
battlerage_abilities:
  - blade: "Basic damage"
  - flux: "Combo attacks"
```

## Fighting Against This Class
```yaml
priority_cures:
  - haemophilia: "EAT GINSENG - prevents severe bleeding for latch"
  - nausea: "EAT GINSENG - latch affliction + speeds drown"
  - asthma: "EAT KELP - speeds drown, gates paralysis"
  - weariness: "EAT KELP - blocks Purify, gates anorexia"
  - lethargy: "EAT GINSENG - latch affliction"
  - addiction: "EAT GINSENG - latch affliction"
  - bleeding: "CLOT - severe bleeding (200+) needed for latch kill"

dangerous_abilities:
  - desiccate: "Instant kill after 4-aff Latch (~4.5s window)"
  - latch: "4 affs + severe bleeding = sip balance knocked"
  - drown: "Channeled instakill (sped by asthma/nausea)"
  - tsunami: "Distance beckon (3-5 rooms)"
  - wreck: "High damage with stupidity/recklessness + prone/paralysis"
  - whirlpool: "Mass beckon from flooded rooms"

avoid:
  - "Having 4 latch afflictions with severe bleeding"
  - "Being in flooded room near waterlord"
  - "Standing in whirlpool range with flooded rooms"
  - "Letting nausea + asthma stick (speeds drown)"
  - "Being prone + paralyzed (max wreck damage)"

latch_afflictions:
  track_these: [addiction, haemophilia, nausea, lethargy, severe_bleeding]
  kill_setup: "4 of these (must include severe bleeding)"
  counter: "Keep under 4 or cure haemophilia to prevent bleeding"

focuslock_warning: |
  If you over-cure latch afflictions, may open yourself to focuslock.
  Waterlord has all lock afflictions (paralysis/anorexia gated).
  Balance curing between latch and lock afflictions.

recommended_strategy: |
  PRIORITY: Keep haemophilia cured - prevents severe bleeding for latch.
  CLOT below 200 bleeding to avoid severe bleeding condition.
  Track latch affliction count (addiction, haemophilia, nausea, lethargy, bleeding).
  4 latch affs with severe bleeding = ~4.5s to die.
  Cure asthma + nausea to slow Drown channel.
  Apply weariness to block their Purify.
  Be careful curing - don't open yourself to focuslock.
  Avoid flooded rooms (whirlpool mass beckon).
  Tsunami can beckon from 3-5 rooms away.
  Wreck does max damage only if prone AND paralyzed.
  Hydra attacks everyone except water elementals - use cautiously.
```

## Implementation Notes
```
Triggers to watch for:
- "chokes you" - asthma/hallucinations
- "drenches you" - weariness/confusion
- "parches you" - lethargy
- "perspires" - slickness + prone
- "roils" - nausea or focus knock
- "thins" - haemophilia or 200 bleeding
- "wrecks you" - stupidity + recklessness or damage
- "latches" - check affliction count
- "desiccates" - instant kill attempt
- "rises" - drown setup
- "drowns" - channeled kill
- "tsunami" - distance beckon
- "whirlpool" - mass beckon
- Room flooding messages

GMCP considerations:
- Track gmcp.Char.Afflictions for latch afflictions
- Track bleeding amount (200+ = severe)
- Track sip balance after latch
- Count latch afflictions: addiction, haemophilia, nausea, lethargy, severe bleeding

Edge cases:
- Latch needs 4 afflictions INCLUDING severe bleeding (200+)
- Desiccate window is ~4.5 seconds after Latch
- Can follow and complete Desiccate even if they flee
- Paralysis gated behind nausea + weariness + asthma
- Anorexia gated behind asthma + weariness
- Purify blocked by weariness (but water bonus cure is NOT)
- Drown channel sped by both asthma AND nausea
- Wreck damage significantly reduced without prone + paralysis
- Tsunami floods the room (can upset runelorists)
- Hydra attacks EVERYONE not water elemental including allies
- Tidalwave ignores movement hinders in flooded rooms

Latch Effects by Count:
- 2: Binding (hinders fleeing)
- 3: Moderate bleeding
- 4: Knocks sip balance (need severe bleeding)

Flux Bonus Effects:
- FLUX CHOKE: +paralysis (if nausea + weariness + asthma)
- FLUX DRENCH: +focus knock (if asthma + slickness + anorexia)
- FLUX PARCH: +addiction (if weariness + haemophilia)
- FLUX ROIL: +anorexia (if asthma + weariness)
```
