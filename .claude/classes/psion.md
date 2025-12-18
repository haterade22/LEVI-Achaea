# Psion

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Damage | Mana Kill
- **Difficulty**: Hard
- **Lock Affliction**: Confusion (blocks Expunge passive cure)

## Skills
```
Weaving: Aldar magic thread manipulation and attacks
Psionics: Mental powers, Psi Blast, Psi Excise
Emulation: Copy and replicate abilities
```

## Core Combat Mechanics
```yaml
combat_style: "Fast momentum-based hybrid class with multiple simultaneous kill routes"

weave_mechanics:
  parry: "Psions do NOT get parried"
  rebounding: "Psions DO rebound (recent change)"
  rebound_bypass: "Unweaves, Entwine, and Finishers go through rebounding"
  miss_rate: "Psions do NOT miss naturally"
  clumsiness: "~30% miss rate with clumsiness (weave misses, prep still lands)"
  incisive_prep: "Guarantees weave doesn't miss, but no affliction delivery"

unweaving_system:
  types: [mind, body, spirit]
  mechanic: "If not cured, increases level by 1 every 4 seconds automatically"
  kill_condition: "Any TWO unweaves at level 3+ = Deconstruct instant kill"
  blocking_afflictions:
    spirit: "Asthma (smoke cure blocked)"
    mind: "Impatience/Plumbum afflictions (goldenseal blocked)"
    body: "Ferrum afflictions (ferrum blocked)"

transcendence:
  description: "Resource for special combos"
  free_shield_break: "Every 5 attacks grants free shield break"
  cost: "Burns transcendence, locks out other useful combos"

impatience_delivery:
  requirement: "Target must be PRONE or have DAMAGED HEAD"
  note: "They will hit you with both simultaneously"
```

## Kill Routes

### Primary Kill: Psi Excise (Mana Kill)
```yaml
type: execute
summary: Mana drain via Mind Ravaged + Unweaving Mind, instant kill at 30% mana

prerequisites:
  psi_blast_condition:
    description: "Need 3 of these afflictions to enable Psi Blast"
    afflictions: [unweavingmind, blackout, epilepsy, stupidity, impatience, dizziness]
  mind_ravaged:
    effect: "Every hit you take saps your mana"
    source: "Applied by Psi Blast"

steps:
  1: "Stack plumbum afflictions (stupidity, impatience, dizziness, epilepsy)"
  2: "Apply Unweaving Mind"
  3: "Once 3+ plumbum affs present, PSI BLAST (gives mind ravaged)"
  4: "Continue attacking - each hit drains mana while mind ravaged"
  5: "Unweaving Mind also drains mana as it levels"
  6: "When target at 30% mana, PSI EXCISE for instant kill"

notes: |
  Most common Psion kill path.
  Mind ravaged makes every hit sap mana significantly.
  Combined with unweaving mind for massive mana pressure.
```

### Alternative Kill: Deconstruct (Unweave Execute)
```yaml
type: execute
summary: Get any two unweave types to level 3+, then Deconstruct for instant kill

mechanics:
  unweave_leveling: "Increases by 1 level every 4 seconds automatically if not cured"
  kill_condition: "TWO unweaves at level 3+ = death"
  type_switching: "Psion can change your unweave type, must adapt dynamically"

unweave_types:
  mind:
    cure: "Eat (goldenseal/plumbum)"
    blocking: [impatience, stupidity, dizziness, epilepsy]
    note: "33% chance to cure if multiple plumbum affs"

  body:
    cure: "Eat (ferrum)"
    blocking: [addiction, haemophilia, lethargy, etc.]
    note: "More reliable cure than mind if ferrum clear"

  spirit:
    cure: "Smoke (valerian)"
    blocking: [asthma]
    special: "Cures ONE LEVEL at a time, not all at once"
    example: "Level 5 = needs 7+ smokes to fully clear (levels up while curing)"

steps:
  1: "Track unweave levels on target"
  2: "Apply blocking afflictions for chosen unweave types"
  3: "Let unweaves auto-level while target can't cure"
  4: "When any TWO reach level 3+, DECONSTRUCT for instant kill"

counter_note: |
  Don't always cure highest unweave first.
  Example: UWMind4 + Impatience + Stupidity + UWBody2
  Better to eat ferrum (guarantee body cure) than gamble on 33% mind cure.
  If plumbum cure fails, body might hit 3 and you die.
```

### Alternative Kill: High Damage Burst (Flurry)
```yaml
type: damage
summary: High Unweaving Spirit level + Flurry = percent-based damage burst

mechanics:
  flurry_damage: "Multiplies based on spirit unweave level"
  scaling: "Level 5 spirit unweave flurry = ~90% max health damage"
  damage_type: "Percent health based"

prerequisites:
  - High level Unweaving Spirit on target
  - Asthma to block smoking cures

steps:
  1: "Apply asthma to block smoke cure"
  2: "Apply Unweaving Spirit"
  3: "Let UWS level up (auto-levels every 4s)"
  4: "At high level (4-5), FLURRY for massive burst"
  5: "Follow up with damage to finish"

counters:
  - "Shield"
  - "Reflections"
  - "Hinder"
  - "Cure asthma"
  - "Fly (shield while flying prevents Weave Launch pulldown)"
  - "Run away (UWS will tick down)"
```

### Alternative Kill: Bloodfire Lock
```yaml
type: affliction
summary: Special lock variant using Bloodfire mechanic

required_afflictions:
  - bloodfire: "Special Psion affliction"
  - haemophilia: "Prevents clotting effectively"
  - bleeding: "200+ bleeding"
  - impatience: "Blocks focus"
  - anorexia: "Blocks eating"

notes: |
  Alternative lock route.
  Bloodfire synergizes with bleeding and haemophilia.
```

## Group Combat Tactics
```yaml
role: "Fast affliction and mana pressure"

primary_tactics:
  - "Psi Blast targets to give mind ravaged"
  - "Unweave pressure while group damages"
  - "Lightbind to hinder escape"
  - "Mana drain assists lockdown"

notes: "Very fast class that can pressure multiple kill routes"
```

## Hindering Psions
```yaml
most_effective:
  clumsiness:
    effect: "~30% miss rate on weave attacks"
    note: "Weave prep still lands, but weave attack misses"

  paralysis:
    effect: "Standard hinder"
    priority: "High"

  lethargy:
    effect: "Slows them down"
    priority: "Medium"

shield:
  effect: "Significantly slows their offense"
  weakness: "Transcend gives free shield break every 5 attacks"
  note: "Burns their transcendence, locks them out of combos"

reflections:
  effect: "TREMENDOUSLY shuts down their offense"
  mechanics: |
    Reflection hits give them:
    - No limb prep
    - No damage
    - No afflictions
    - NOT EVEN the weave prep
  bypass: "They have a prep to bypass (not break) reflection"
  note: "Use liberally if you have reflections"

rebounding:
  effect: "Slows them down"
  weakness: "Unweaves, entwine, finishers bypass rebounding"
```

## Offensive Abilities
```yaml
# Weaving
weave:
  skill: Weaving
  balance: eq
  effect: "Primary attack with weave prep affliction"
  syntax: "WEAVE <target> <prep>"
  notes: "Can combo with preps for affliction delivery"

weave_launch:
  skill: Weaving
  balance: eq
  effect: "Pull flying target down"
  syntax: "WEAVE LAUNCH <target>"
  blocked_by: "Shield while flying"

lightbind:
  skill: Weaving
  balance: eq
  effect: "Hinder target from leaving"
  syntax: "LIGHTBIND <target>"
  range: "Works 1 room away - must move 2 rooms to escape"
  cooldown: "~4 second window after falling before can reapply"
  note: "Watch for when it falls to escape"

entwine:
  skill: Weaving
  balance: eq
  effect: "Binding attack"
  syntax: "ENTWINE <target>"
  notes: "Goes through rebounding"

flurry:
  skill: Weaving
  balance: eq
  effect: "Burst damage scaled by spirit unweave level"
  syntax: "FLURRY <target>"
  damage: "Level 5 UWS = ~90% max health"

# Psionics
psi_blast:
  skill: Psionics
  balance: eq
  effect: "Apply mind ravaged (every hit saps mana)"
  syntax: "PSI BLAST <target>"
  requirement: "3 of: unweavingmind, blackout, epilepsy, stupidity, impatience, dizziness"
  notes: "Key to mana kill route"

psi_excise:
  skill: Psionics
  balance: eq
  effect: "Instant kill at 30% mana"
  syntax: "PSI EXCISE <target>"
  requirement: "Target at 30% mana or below"
  notes: "Main mana execute"

# Unweaving
unweave_mind:
  skill: Weaving
  balance: eq
  effect: "Apply unweaving mind (auto-levels, mana drain)"
  syntax: "UNWEAVE MIND <target>"
  cure: "Eat goldenseal/plumbum herb"
  blocked_by: [impatience, stupidity, dizziness, epilepsy]

unweave_body:
  skill: Weaving
  balance: eq
  effect: "Apply unweaving body (auto-levels)"
  syntax: "UNWEAVE BODY <target>"
  cure: "Eat ferrum herb"
  blocked_by: [addiction, haemophilia, lethargy]

unweave_spirit:
  skill: Weaving
  balance: eq
  effect: "Apply unweaving spirit (auto-levels, setup for flurry)"
  syntax: "UNWEAVE SPIRIT <target>"
  cure: "Smoke valerian (ONE level at a time)"
  blocked_by: [asthma]
  special: "Cures one level per smoke, not all at once"

deconstruct:
  skill: Weaving
  balance: eq
  effect: "Instant kill when 2 unweaves at level 3+"
  syntax: "DECONSTRUCT <target>"
  requirement: "Any TWO unweave types at level 3 or higher"

transcend:
  skill: Weaving
  balance: eq
  effect: "Free shield break every 5 attacks"
  syntax: "TRANSCEND"
  cost: "Burns transcendence, locks out other combos"
```

## Defensive Abilities
```yaml
expunge:
  skill: Psionics
  effect: "Active heal - cures any mental affliction"
  syntax: "EXPUNGE"
  priority: "Cures impatience FIRST if present"
  blocked_by: [confusion]
  notes: "Confusion is their class-specific lock affliction"

secondskin:
  skill: Weaving
  effect: "Weave defense - decent protection"
  syntax: "WEAVE SECONDSKIN"
  notes: "Main defensive buff (cloth armor class)"

wavesurge:
  skill: Weaving
  effect: "Move 1-3 rooms in random direction"
  syntax: "WAVESURGE"
  cooldown: "2 minutes"
  notes: "Can go around corners - slippery escape"

psi_projection:
  skill: Psionics
  effect: "Set projection point to swap with"
  syntax: "PSI PROJECTION"
  blocked_by: "Monolith"
  notes: "Can teleport back to projection"
```

## Passive Cures
```yaml
expunge:
  cures: [mental_afflictions]
  priority: "Impatience cured FIRST"
  blocked_by: [confusion]
  trigger: "Active ability"
  notes: |
    Confusion is their class-specific lock affliction.
    Serpents need to modify typical approach.
    Classes with on-demand confusion fare better.
```

## Limb Strategy
```yaml
enabled: partial
primary_targets: [head]

limb_mechanics:
  head_damage:
    level_1: "Allows impatience delivery"
    usage: "Setup for mana kill route"

notes: |
  Psions use head damage to enable impatience delivery.
  Not a traditional limb class but head prep matters.
  Impatience only given if prone OR damaged head.
```

## Bashing (PvE)
```yaml
attack_command: "WEAVE <target>"
attack_skill: Weaving
battlerage_abilities:
  - weave: "Primary damage"
  - psi_blast: "Mental damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - impatience: "EAT GOLDENSEAL - blocks focus, enables psi blast condition"
  - asthma: "EAT KELP - blocks smoke cure for spirit unweave"
  - unweaving_spirit: "SMOKE VALERIAN - cures ONE level at a time"
  - unweaving_mind: "EAT GOLDENSEAL - 33% chance with other plumbum"
  - unweaving_body: "EAT FERRUM - more reliable cure"
  - stupidity: "EAT GOLDENSEAL - slows curing, psi blast condition"
  - prone: "STAND - they need prone/head damage for impatience"

dangerous_abilities:
  - psi_excise: "Instant kill at 30% mana"
  - deconstruct: "Instant kill with 2 unweaves at level 3+"
  - flurry: "~90% HP damage at high spirit unweave"
  - psi_blast: "Mind ravaged = every hit drains mana"
  - lightbind: "Movement hinder, works 1 room away"

avoid:
  - "Having 3+ plumbum afflictions (enables psi blast)"
  - "Letting any TWO unweaves reach level 3 (deconstruct)"
  - "High spirit unweave (flurry burst)"
  - "Being mind ravaged while low mana"
  - "Standing in lightbind range (need 2 rooms away)"
  - "Letting mana drop to 30% (psi excise)"

lightbind_escape:
  window: "~4 seconds after lightbind falls"
  range: "Works 1 room away - move 2 rooms to escape"
  note: "Have loud reflexes for when lightbind falls"

reflection_note: |
  If you have reflections, USE THEM LIBERALLY.
  Reflection hits = no limb prep, no damage, no afflictions, not even weave prep.
  They have a bypass prep but it's costly.

unweave_curing_priority: |
  Don't always cure highest unweave first.
  Example: UWMind4 + Impatience + Stupidity + UWBody2
  - Eating ferrum = guaranteed body cure
  - Eating goldenseal = 33% chance to cure mind (might get stupidity/impatience)
  Choose the GUARANTEED cure to prevent second unweave hitting 3.

recommended_strategy: |
  MANA SIP PRIORITY when mind ravaged or near psi blast condition.
  Track unweave levels - TWO at 3+ = death.
  Apply CLUMSINESS for ~30% miss rate on weaves.
  Apply CONFUSION to block their Expunge cure.
  Shield often - slows them down significantly.
  Use REFLECTIONS liberally if you have them.
  Get back on feet FAST - prone + head damage = impatience.
  Cure impatience, then drop priority when prone to avoid pin.
  When lightbind falls, you have ~4 seconds to run.
  Need to move 2 ROOMS away to escape lightbind range.
  Can hinder them after leaving (gravehands/leg break/iceground).
```

## Implementation Notes
```
Triggers to watch for:
- "weaves at you" - weave attack incoming
- "unweaves your mind/body/spirit" - unweave applied
- "psi blasts you" - mind ravaged incoming
- "mind ravaged" - every hit now drains mana
- "psi excise" - mana kill attempt (30% threshold)
- "deconstructs" - unweave kill attempt
- "flurry" - burst damage incoming
- "lightbinds you" - movement hinder active
- "lightbind fades" - 4 SECOND WINDOW TO RUN
- Unweave level messages
- Mana drain messages

GMCP considerations:
- Track gmcp.Char.Afflictions for afflictions
- Track gmcp.Char.Vitals.mp CRITICALLY (30% = death)
- Unweave levels need message parsing
- Track plumbum affliction count for psi blast condition

Edge cases:
- Psions don't get parried
- Psions DO rebound (unweaves/entwine/finishers bypass)
- Psions don't miss naturally (~30% miss with clumsiness)
- Incisive prep = no miss but no affliction
- Unweaves auto-level every 4 seconds
- Spirit unweave cures ONE level at a time (not all)
- Deconstruct = instant kill at TWO level 3+ unweaves
- Psi Excise = instant kill at 30% mana
- Impatience only delivered if prone OR head damaged
- Lightbind works 1 room away - need 2 rooms to escape
- ~4 second window after lightbind falls to run
- Expunge cures impatience FIRST (blocked by confusion)
- Reflections almost completely shut them down
- Transcend = free shield break every 5 attacks
- Wavesurge = 1-3 rooms random direction (2 min CD)
- Psi Projection blocked by monolith

Psi Blast Condition (need 3 of):
- Unweaving Mind
- Blackout
- Epilepsy
- Stupidity
- Impatience
- Dizziness

Unweave Cure Methods:
- Mind: Eat (goldenseal/plumbum) - shared with other plumbum affs
- Body: Eat (ferrum) - more reliable if ferrum clear
- Spirit: Smoke (valerian) - ONE level per smoke

Kill Thresholds:
- Psi Excise: 30% mana
- Deconstruct: TWO unweaves at level 3+
- Flurry: High spirit unweave (~90% HP at level 5)
```
