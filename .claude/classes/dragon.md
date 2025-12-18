# Dragon

## Metadata
- **Type**: End-Game Class
- **Combat Style**: Damage | Limb | Affliction
- **Difficulty**: Hard
- **Lock Affliction**: Weariness (for lock route)

## Skills
```
Dragoncraft: Dragon-specific abilities and powers
Draconic Skills: Varies by dragon color (6 colors available)
```

## Dragon Colors
```yaml
red:
  description: "Fire-focused dragon"
  breath_weapon: "Fire breath"
  strength: "High fire damage, ablaze application"

black:
  description: "Acid/Poison-focused dragon"
  breath_weapon: "Acid breath"
  strength: "Damage over time, corrosion"

silver:
  description: "Ice-focused dragon"
  breath_weapon: "Ice breath"
  strength: "Freezing, control"

gold:
  description: "Lightning-focused dragon"
  breath_weapon: "Lightning breath"
  strength: "High burst damage"

blue:
  description: "Water-focused dragon"
  breath_weapon: "Water breath"
  strength: "Drowning, water control"

green:
  description: "Poison/Nature-focused dragon"
  breath_weapon: "Poison breath"
  strength: "Affliction stacking, venoms"
```

## Core Combat Mechanics
```yaml
dragonbreath:
  description: "Resource that powers breath abilities"
  required_for: [blast, breathstream, breathstorm, breathrain]
  summon: "Must summon dragonbreath before using breath attacks"

primary_attacks:
  rend:
    description: "Balance-based attack with venom delivery"
    targeting: "Can target limbs OR deliver venoms"
    limb_damage: "4 hits to break any limb regardless of health"
    untargetted: "Slightly faster venom delivery"
    usage: "Primary PvP attack"

  gut:
    description: "Stronger, slower attack with venom"
    targeting: "Cannot target limbs"
    usage: "Primary hunting/bashing attack"
    notes: "Better for PvE, Rend better for PvP"

prone_combo:
  description: "Dragons deal massive damage to prone targets"
  key_ability: "Bite"
  amplifiers:
    - sensitivity: "Increases bite damage"
    - broken_torso: "Increases bite damage"
  notes: "Bite damage is negligible if target NOT prone"
```

## Kill Routes

### Primary Kill: Prone Bite (Damage)
```yaml
type: damage
summary: Prep limbs, break torso and legs, bite prone target for massive damage

prerequisites:
  - Prep both legs and torso
  - Apply sensitivity via dragoncurse
  - Have breathstorm active for bonus damage

steps:
  1: "Prep torso and both legs with rend/dragoncurse/breathgust"
  2: "Apply sensitivity via DRAGONCURSE SENSITIVITY"
  3: "Place BREATHSTORM for additional damage"
  4: "Break TORSO (increases prone bite damage)"
  5: "Break LEG"
  6: "Break LEG (target now prone)"
  7: "BITE (massive damage to prone target)"
  8: "BITE again if needed"

damage_amplifiers:
  - sensitivity: "From dragoncurse"
  - broken_torso: "Increases prone bite damage"
  - breathstorm: "Ongoing room damage"
  - undeaf_roar: "If target undeaf, roar deals more"

notes: |
  Torso break is critical for maximizing bite damage.
  Sensitivity should be applied before biting.
  Breathstorm adds passive damage during combo.
```

### Primary Kill: Devour (Execute)
```yaml
type: execute
summary: Swallow target whole - speed based on broken limbs

prerequisites:
  - Multiple broken limbs reduce devour time
  - Base devour time: 10 seconds
  - Under 5 seconds = cannot be stopped except by leaving

steps:
  1: "Prep torso, one arm, and both legs"
  2: "Break TORSO"
  3: "Break ARM"
  4: "Break LEG"
  5: "Break LEG"
  6: "DEVOUR <target>"

devour_mechanics:
  base_time: "10 seconds"
  reduction: "Each broken limb reduces time"
  unstoppable: "Under 5 seconds cannot be stopped except leaving room"
  preferred_vs: "Targets who don't die to damage easily"

notes: |
  More difficult and telegraphed than bite route.
  Preferred method vs high-health/artifact-tanky opponents.
  Execute properly and it's extremely difficult to avoid.
```

### Alternative Kill: Affliction Lock
```yaml
type: affliction
summary: Stack lock afflictions via dragoncurse and rend venoms

steps:
  1: "Apply asthma via rend venom"
  2: "Apply slickness via rend venom"
  3: "Apply anorexia via rend venom"
  4: "Apply paralysis via DRAGONCURSE PARALYSIS"
  5: "Apply impatience via DRAGONCURSE IMPATIENCE"
  6: "Apply weariness via DRAGONCURSE WEARINESS"
  7: "Once locked, BITE or DEVOUR as required"

required_afflictions:
  - asthma: "blocks smoking"
  - slickness: "blocks applying"
  - anorexia: "blocks eating"
  - paralysis: "blocks tree"
  - impatience: "blocks focus"
  - weariness: "blocks fitness (lock aff)"

notes: |
  Most difficult route to accomplish.
  Use rend for venoms and dragoncurse for afflictions.
  Once locked, finish with Bite or Devour.
```

## Group Combat Tactics
```yaml
primary_role: "Heavy damage dealer with lyre break capability"

standard_rotation:
  1: "DRAGONCURSE <target> or DRAGONCURSE <affliction> (sensitivity/impatience/paralysis)"
  2: "REND <target> (with curare or prefarar venom)"
  3: "BREATHGUST (prone after every balance attack)"

lyre_breaking:
  blast: "Primary in-room lyre break, requires dragonbreath"
  breathstream: "Line of sight lyre break, requires dragonbreath"

key_group_abilities:
  breathstorm:
    description: "Room attack hitting all on ENEMIES list"
    duration: "Stays for 2 ticks, then needs reapplication"
    priority: "Place when enemies coming to engage"
    notes: "Only one breathstorm per room - make sure it's YOURS"

  breathstream:
    description: "Line of sight attack"
    effects: "Breaks shields, breaks lyre, consistent damage"
    special: "Bypasses Timewell and Retardation defenses"

  roar:
    description: "Damage attack"
    effect_undeaf: "More damage if target undeaf"
    effect_deaf: "Less damage but undeafs them"
    blocked_by: "Magi vibe of silence"

recommended_venoms:
  - curare: "Paralysis for hinder"
  - prefarar: "Prefarar venom"
```

## Offensive Abilities
```yaml
# Primary Attacks
rend:
  skill: Dragoncraft
  balance: bal
  effect: "Attack with venom delivery, can target limbs"
  syntax: "REND <target>" or "REND <target> <limb>"
  limb_breaks: "4 hits to break any limb"
  notes: "Primary PvP attack"

gut:
  skill: Dragoncraft
  balance: bal
  effect: "Stronger slower attack with venom, no limb targeting"
  syntax: "GUT <target>"
  notes: "Primary hunting attack"

bite:
  skill: Dragoncraft
  balance: bal
  effect: "Massive damage to PRONE targets"
  syntax: "BITE <target>"
  amplified_by: [sensitivity, broken_torso]
  notes: "Negligible damage if target NOT prone"

# Affliction Delivery
dragoncurse:
  skill: Dragoncraft
  balance: eq
  effect: "Deliver affliction after short delay"
  syntax_unspecified: "DRAGONCURSE <target>"
  syntax_specified: "DRAGONCURSE <target> <affliction>"
  unspecified_effect: "Three random hidden afflictions"
  available_afflictions:
    - paralysis: "Max hinder option"
    - impatience: "Recommended"
    - sensitivity: "Recommended - amplifies damage"
    - asthma: "Lock component"
    - stupidity: "Disrupts curing"
    - weariness: "Lock affliction"
    - recklessness: "Blocks defensive abilities"

# Utility Attacks
roar:
  skill: Dragoncraft
  balance: eq
  effect: "Damage attack"
  syntax: "DRAGONROAR <target>"
  undeaf: "More damage"
  deaf: "Less damage, removes deafness"
  blocked_by: "Magi silence vibe"

tailsmash:
  skill: Dragoncraft
  balance: bal
  effect: "Break shield defense"
  syntax: "TAILSMASH <target>"
  notes: "Does NOT bypass prismatic barrier (lyre). Can combo with dragoncurse."

enmesh:
  skill: Dragoncraft
  balance: bal
  effect: "Parry bypass OR entangle"
  syntax: "ENMESH <target>"
  if_standing: "100% parry bypass"
  if_prone: "Entangles target"

# Breath Abilities (require dragonbreath summoned)
blast:
  skill: Dragoncraft
  balance: eq
  effect: "Break shields AND lyres, deals damage"
  syntax: "BLAST <target>"
  requires: "Dragonbreath summoned"
  notes: "Primary in-room lyre break"

breathstream:
  skill: Dragoncraft
  balance: eq
  effect: "Line of sight attack, breaks shields and lyres"
  syntax: "BREATHSTREAM <direction>"
  requires: "Dragonbreath summoned"
  special: "Bypasses Timewell and Retardation"

breathstorm:
  skill: Dragoncraft
  balance: eq
  effect: "Room attack hitting all on ENEMIES list"
  syntax: "BREATHSTORM"
  requires: "Dragonbreath summoned"
  duration: "2 ticks"
  notes: "Only one per room - ensure it's yours"

breathrain:
  skill: Dragoncraft
  balance: eq
  effect: "Attack all on ground from flying"
  syntax: "BREATHRAIN"
  requires: "Dragonbreath summoned, must be flying"
  countered_by: "Shield, gives warning"

breathgust:
  skill: Dragoncraft
  balance: free
  effect: "Prone target"
  syntax: "BREATHGUST <target>"
  notes: "Use after EVERY balance-consuming attack"

# Retardation Niche
tailsweep:
  skill: Dragoncraft
  balance: bal
  effect: "Swing tail at enemies list, chance to prone"
  syntax: "TAILSWEEP"
  notes: "Can fail, useful in retardation"

trample:
  skill: Dragoncraft
  balance: bal
  effect: "Trample all prone targets in room"
  syntax: "TRAMPLE"
  notes: "Indiscriminate - hits all prone"
```

## Defensive Abilities
```yaml
pierce_the_veil:
  skill: Dragoncraft
  effect: "Escape to Parthren Gare"
  syntax: "PIERCE THE VEIL"
  notes: "Primary escape method - compose yourself and return"

scales:
  skill: Dragoncraft
  effect: "Natural armor from dragon scales"
  notes: "Passive damage reduction"

flight:
  skill: Dragoncraft
  effect: "Aerial movement and evasion"
  syntax: "FLY"
  notes: "Can avoid ground-based attacks, enables breathrain"

regeneration:
  skill: Dragoncraft
  effect: "Passive health regeneration"
  notes: "Innate dragon ability"
```

## Passive Cures
```yaml
# Dragons have various innate resistances
# Specific passive cures vary by dragon color
# Generally high natural resistances as end-game class
```

## Limb Strategy
```yaml
enabled: true
primary_targets: [torso, left_leg, right_leg]

limb_mechanics:
  rend_targeted: "4 hits to break any limb regardless of health"
  torso_priority: "Broken torso increases prone bite damage"
  legs_priority: "Broken legs = prone = massive bite damage"

devour_prep:
  targets: [torso, arm, left_leg, right_leg]
  purpose: "Each broken limb reduces devour time"
  threshold: "Under 5 seconds = unstoppable"

strategy: |
  For Bite route: Prep torso and both legs.
  For Devour route: Prep torso, one arm, both legs.
  Use enmesh for parry bypass when target is standing.
  Breathgust after every attack to keep prone.
```

## Bashing (PvE)
```yaml
attack_command: "GUT <target>"
attack_skill: Dragoncraft
notes: "Gut is primary hunting attack, Rend for PvP"
battlerage_abilities:
  - gut: "Primary bashing damage"
  - rend: "Alternative attack"
```

## Fighting Against This Class
```yaml
priority_cures:
  - sensitivity: "EAT KELP - reduces their massive bite damage"
  - paralysis: "EAT BLOODROOT - they dragoncurse this for hinder"
  - impatience: "EAT GOLDENSEAL - common dragoncurse target"
  - broken_legs: "APPLY RESTORATION - prevents prone setup"
  - broken_torso: "APPLY RESTORATION - reduces bite damage"
  - prone: "STAND - must avoid prone bites"

dangerous_abilities:
  - bite: "Massive damage when PRONE with sensitivity/broken torso"
  - devour: "Execute that speeds up with broken limbs"
  - breathstorm: "Persistent room damage"
  - breathstream: "LOS attack that bypasses Timewell/Ret"
  - blast: "Breaks shield AND lyre"
  - enmesh: "Parry bypass OR entangle"
  - breathgust: "Free action prone"

avoid:
  - "Being prone with sensitivity and broken torso"
  - "Having 4+ broken limbs (fast devour)"
  - "Standing in their breathstorm"
  - "Letting them build momentum"
  - "Static parrying (enmesh bypasses)"

devour_counter:
  under_5s: "Cannot stop except leaving room"
  over_5s: "Various counters available"
  prevention: "Don't let multiple limbs break"

recommended_strategy: |
  PRIORITY: Don't get prone with sensitivity + broken torso.
  Cure sensitivity immediately - it amplifies bite massively.
  Restore broken legs ASAP to avoid prone setup.
  Restore broken torso to reduce bite damage.
  Watch for dragoncurse - often delivers paralysis/impatience.
  If they prep 4 limbs, they're going for devour.
  Devour under 5 seconds is unstoppable - flee before that point.
  Breathstorm stays 2 ticks - leave room or accept damage.
  Their breathstream bypasses Timewell and Retardation.
  Blast breaks both shield AND lyre - have backup defense.
  End-game class with high power - be prepared for burst.
```

## Implementation Notes
```
Triggers to watch for:
- "rends you" - limb prep or venom
- "rends your *" - specific limb being prepped
- "guts you" - venom delivery
- "bites you" - DANGER if prone
- "dragoncurses you" - affliction incoming (delayed)
- "breathgust" - prone incoming
- "breathstorm" - room damage active
- "breathstream" - LOS attack
- "blast" - shield/lyre break
- "enmesh" - parry bypass or entangle
- "begins to devour" - EXECUTE starting, track time
- "roars" - damage attack
- "tailsmash" - shield break attempt

GMCP considerations:
- Track gmcp.Char.Afflictions for afflictions
- Track limb damage percentages
- Dragon color affects breath element
- Devour timing is critical to track

Edge cases:
- Rend takes 4 hits to break limb REGARDLESS of health
- Bite damage negligible if NOT prone
- Broken torso increases bite damage
- Sensitivity increases bite damage
- Devour under 5 seconds = unstoppable
- Breathstream bypasses Timewell and Retardation
- Blast breaks lyre, tailsmash does NOT
- Enmesh: parry bypass if standing, entangle if prone
- Breathgust is FREE action - use after every attack
- Only one breathstorm per room
- Roar blocked by Magi silence vibe
- Pierce the Veil = escape to Parthren Gare

Limb Break Count for Rend:
- 4 targeted rends = broken limb (any limb)

Devour Time Reduction:
- Base: 10 seconds
- Each broken limb reduces time
- Under 5 seconds = cannot be stopped

Attack Priority (1v1):
1. Dragoncurse sensitivity/impatience/paralysis
2. Rend with curare/prefarar
3. Breathgust after every attack
4. Break torso -> legs -> bite OR
5. Break torso -> arm -> legs -> devour
```
