# Alchemist

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Damage | Bleed
- **Difficulty**: Hard
- **Lock Affliction**: Stupidity (disrupts their ether-based cures)

## Skills
```
Alchemy: Humour manipulation and transmutation
Physiology: Knowledge of the body for afflictions
Formulation: Default alchemical field abilities
  -OR-
Sublimation: Alternative field using Hashan's Wellspring
```

## Specializations
```yaml
Formulation:
  description: "Default alchemical field"
  style: "Traditional ether manipulation"
  unlock: "Default for all alchemists"

Sublimation:
  description: "Hashan Wellspring variant"
  style: "Wellspring-powered abilities"
  unlock: "Alternative specialization"
```

## Core Combat Mechanics
```yaml
humours:
  sanguine:
    temper_effect: "Faster paralysis wrack"
    inundate_effect: "Massive bleeding"
    max_tempers: 8

  choleric:
    temper_effect: "At 3 tempers, chance to block focus and tree"
    inundate_effect: "Direct damage (scales with tempers)"
    max_tempers: 8

  melancholic:
    temper_effect: "Various effects"
    inundate_effect: "Mana damage"
    max_tempers: 8

  phlegmatic:
    temper_effect: "Setup for affliction delivery"
    inundate_effect: "Afflictions based on temper count"
    affliction_tiers:
      1-3: [lethargy]
      4-5: [lethargy, anorexia]
      6-7: [lethargy, anorexia, slickness]
      8: [lethargy, anorexia, slickness, weariness]

basic_combo: "TEMPER <humour> or INUNDATE <humour> + WRACK <affliction> or TRUEWRACK <aff1> <aff2>"

educe_abilities:
  iron: "Extra damage (use with choleric inundate)"
  tin: "Damage defense"
  salt: "Heal extra affliction (10s cooldown)"
  copper: "Break shield (copper + wrack to break and attack)"
```

## Kill Routes

### Primary Kill: Truelock via Phlegmatic Humour
```yaml
type: affliction
summary: Temper phlegmatic humour to deliver multiple lock afflictions on inundate

method_4_tempers:
  description: "Fastest lock, vulnerable to fitness and tree"
  steps:
    1: "Temper sanguine once (keep at least 1 temper)"
    2: "Temper phlegmatic while wracking paralysis"
    3: "At 4 tempers: INUNDATE PHLEGMATIC + HOMUNCULUS SHRIEK + TRUEWRACK SLICKNESS ASTHMA"
    4: "Followup: TRUEWRACK WEARINESS IMPATIENCE"
    5: "Followup: WRACK PARALYSIS"
  notes: |
    Inundate delivers anorexia + lethargy.
    Homunculus shriek temporarily prevents focus.
    25% chance tree cures lethargy (lock can still work).
    Vulnerable to fitness before impatience applied.

method_6_tempers:
  description: "More secure, stops fitness"
  steps:
    1: "Temper sanguine once"
    2: "Temper phlegmatic to 6 while wracking paralysis"
    3: "INUNDATE PHLEGMATIC + HOMUNCULUS SHRIEK + TRUEWRACK WEARINESS ASTHMA"
    4: "Followup: TRUEWRACK RECKLESSNESS IMPATIENCE (for dragon) or WRACK IMPATIENCE"
    5: "Followup: WRACK PARALYSIS"
  alternative: |
    If sanguine also at 3 tempers:
    INUNDATE PHLEGMATIC + SHRIEK + TRUEWRACK PARALYSIS ASTHMA
    Then TRUEWRACK WEARINESS IMPATIENCE

method_8_tempers:
  description: "Most secure lock"
  steps:
    1: "Temper sanguine to 3"
    2: "Temper phlegmatic to 8 while wracking paralysis"
    3: "INUNDATE PHLEGMATIC + HOMUNCULUS SHRIEK + TRUEWRACK RECKLESSNESS ASTHMA"
    4: "Followup: WRACK IMPATIENCE"
    5: "Followup: WRACK PARALYSIS"
  notes: |
    Inundate gives weariness at 8 tempers.
    With 3 sanguine tempers, can truewrack paralysis + asthma together.
    If target shields, EDUCE COPPER + WRACK IMPATIENCE to complete lock.
```

### Alternative Kill: Truelock via Sanguine Truewrack
```yaml
type: affliction
summary: Use 3 sanguine tempers for paralysis truewrack combos

steps:
  1: "Temper sanguine to 3 with paralysis wrack"
  2: "TRUEWRACK PARALYSIS ASTHMA"
  3: "(Target eats magnesium, then aurum)"
  4: "TRUEWRACK PARALYSIS ASTHMA"
  5: "(Target eats magnesium)"
  6: "HOMUNCULUS SHRIEK + TRUEWRACK SLICKNESS ANOREXIA"
  7: "TRUEWRACK IMPATIENCE WEARINESS"
  8: "WRACK PARALYSIS"

vulnerabilities:
  - "Tree tattoo"
  - "Fitness after slickness/anorexia before impatience/weariness"
```

### Alternative Kill: Bleeding Out (Sanguine Inundate)
```yaml
type: damage
summary: Temper and inundate sanguine repeatedly for massive bleeding

steps:
  1: "Temper sanguine while wracking paralysis"
  2: "At 8 tempers, INUNDATE SANGUINE"
  3: "Temper sanguine again to 8"
  4: "INUNDATE SANGUINE again"
  5: "Repeat until target dies from bleeding"

notes: |
  Many targets die to first 8-temper inundate.
  Clotting drains willpower significantly.
  Can inundate at fewer tempers to deplete willpower over time.

homunculus_corruption:
  description: "Advanced bleed strategy"
  effect: "Target bleeds mana and clots with health"
  strategy: |
    Corrupt target's humours early.
    Inundate sanguine - they may clot all health and die.
    Or they won't clot to save health, mana bleed builds up.
    When corruption fades, massive health bleed kills them.
```

### Alternative Kill: Damage Out (Choleric Inundate)
```yaml
type: damage
summary: Temper choleric for direct damage on inundate

steps:
  1: "Temper sanguine once"
  2: "Temper choleric while wracking paralysis"
  3: "Apply sensitivity via truewrack"
  4: "INUNDATE CHOLERIC + EDUCE IRON for maximum damage"
  5: "Repeat until target dies"

notes: "Choleric damage scales with number of tempers"
```

### Alternative Kill: Aurify
```yaml
type: execute
summary: Kill target when health AND mana below 60%

methods:
  sanguine_bleed:
    description: "Bleed health, clotting drains mana"
    steps:
      1: "Inundate sanguine for bleeding"
      2: "Target clots (loses mana)"
      3: "AURIFY when both below 60%"

  choleric_melancholic:
    description: "Damage health and mana directly"
    steps:
      1: "Temper both choleric and melancholic"
      2: "Inundate choleric (health damage)"
      3: "Inundate melancholic (mana damage)"
      4: "AURIFY when both below 60%"

  sanguine_choleric:
    description: "Bleed then damage"
    steps:
      1: "Temper sanguine and choleric"
      2: "Inundate sanguine (bleeding)"
      3: "Inundate choleric (damage)"
      4: "AURIFY (clotting drained mana)"
```

## Offensive Abilities
```yaml
# Core Alchemy
temper:
  skill: Alchemy
  balance: eq
  effect: "Add temper to a humour (max 8)"
  syntax: "TEMPER <humour>"
  notes: "Can combo with wrack"

inundate:
  skill: Alchemy
  balance: eq
  effect: "Trigger tempered humour effect"
  syntax: "INUNDATE <humour>"
  notes: "Can combo with wrack/truewrack"

wrack:
  skill: Alchemy
  balance: bal
  effect: "Apply single affliction"
  syntax: "WRACK <affliction>"
  notes: "Faster if target's sanguine humour tempered"

truewrack:
  skill: Alchemy
  balance: bal
  effect: "Apply TWO afflictions at once"
  syntax: "TRUEWRACK <affliction1> <affliction2>"
  notes: "Key to fast locking"

# Educe (between temper and wrack)
educe_iron:
  skill: Alchemy
  balance: eq
  effect: "Add extra damage"
  syntax: "EDUCE IRON"
  notes: "Use with choleric inundate or group damage"

educe_copper:
  skill: Alchemy
  balance: eq
  effect: "Strip shield defense"
  syntax: "EDUCE COPPER"
  notes: "Always EDUCE COPPER + WRACK to break and attack"

educe_salt:
  skill: Alchemy
  balance: eq
  effect: "Cure an extra affliction"
  syntax: "EDUCE SALT"
  cooldown: 10s

educe_tin:
  skill: Alchemy
  balance: eq
  effect: "Damage reduction"
  syntax: "EDUCE TIN"

# Homunculus
homunculus_shriek:
  skill: Alchemy
  balance: free
  effect: "Temporarily prevents focus"
  syntax: "HOMUNCULUS SHRIEK <target>"
  notes: "Critical for securing locks"

homunculus_corruption:
  skill: Alchemy
  balance: eq
  effect: "Target bleeds mana, clots with health"
  syntax: "HOMUNCULUS CORRUPT <target>"
  notes: "Advanced bleed strategy"

# Execute
aurify:
  skill: Alchemy
  balance: eq
  effect: "Instant kill when target HP and MP both below 60%"
  syntax: "AURIFY <target>"
```

## Defensive Abilities
```yaml
educe_tin:
  skill: Alchemy
  effect: "Damage reduction"
  syntax: "EDUCE TIN"

educe_salt:
  skill: Alchemy
  effect: "Cure extra affliction"
  syntax: "EDUCE SALT"
  cooldown: 10s
```

## Passive Cures
```yaml
# Alchemist has active cures through educe salt
# Blocked by stupidity for some effects
```

## Limb Strategy
```yaml
enabled: false
notes: "Alchemist is humour/affliction-based, not limb-based"
```

## Bashing (PvE)
```yaml
attack_command: "WRACK <target>" or spec-specific
attack_skill: Alchemy
battlerage_abilities:
  - wrack: "Basic damage"
  - inundate: "Temper-based damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - paralysis: "They wrack this constantly, high priority"
  - asthma: "Restore smoking ability"
  - slickness: "Restore salve application"
  - anorexia: "Restore eating ability"
  - lethargy: "From phlegmatic inundate"
  - weariness: "From 8-temper phlegmatic"
  - tempers: "Cure with ginger before inundate"

dangerous_abilities:
  - phlegmatic_inundate: "Delivers multiple lock afflictions at once"
  - sanguine_inundate: "Massive bleeding"
  - choleric_inundate: "High direct damage"
  - truewrack: "Two afflictions per attack"
  - aurify: "Instant kill at 60% HP/MP"
  - homunculus_shriek: "Blocks focus temporarily"

avoid:
  - "Letting humours build to 8 tempers"
  - "Ignoring paralysis (they spam it)"
  - "Being below 60% HP and MP at same time"
  - "Not eating ginger to cure tempers"

recommended_strategy: |
  EAT GINGER regularly to cure humour tempers.
  Track temper counts on each humour.
  Prioritize curing paralysis - they wrack it constantly.
  Tree/fitness early before they get impatience/weariness.
  Keep HP and MP above 60% to avoid aurify.
  If bleeding heavily, clot but watch mana drain.
  Shield if overwhelmed, but expect EDUCE COPPER.
  Apply stupidity to disrupt their curing.
```

## Implementation Notes
```
Triggers to watch for:
- "tempers your * humour" - temper count increasing
- "inundates your * humour" - major effect incoming
- "wracks you with" - affliction applied
- "truewracks you with" - TWO afflictions applied
- "Your * humour has * tempers" - track temper count
- "bleeds profusely" - sanguine bleed
- "homunculus shrieks" - focus blocked
- Aurify messages

GMCP considerations:
- Track gmcp.Char.Afflictions for afflictions
- Temper counts need message parsing
- Bleeding amount tracking important

Edge cases:
- Stupidity may block some of their abilities
- Four humours tracked separately (sanguine, choleric, melancholic, phlegmatic)
- Ginger cures ALL tempers on that humour
- Choleric at 3 tempers blocks tree/focus attempts randomly
- Truewrack is their fastest affliction method
- Homunculus shriek temporarily blocks focus (not an affliction)
- Aurify requires BOTH HP and MP below 60%
- Corruption makes bleed/clot swap health/mana
- Shield can be broken with EDUCE COPPER + WRACK

Humour Temper Effects by Count:
- Sanguine: Enables faster paralysis wrack
- Choleric: At 3, random focus/tree blocking
- Phlegmatic: Determines afflictions on inundate
  - 1-3: lethargy
  - 4-5: lethargy, anorexia
  - 6-7: lethargy, anorexia, slickness
  - 8: lethargy, anorexia, slickness, weariness
```
