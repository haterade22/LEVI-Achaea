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
  cost: "200 mana, 3.00s of equilibrium (wiki; no separate cooldown -- the old '10s' was wrong)"
  blocked_by: stupidity

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
  cost: "200 mana, 3.00s of equilibrium (wiki; no separate cooldown -- the old '10s' was wrong)"
  blocked_by: stupidity

robes:
  skill: Alchemy (ABADMIN 3)
  effect: "Up to four symbols, each blocks one damage type"
  syntax: "ROBES SUMMON / ROBES IMBUE WITH <up to four symbols>"
  cost: equilibrium
  symbols: "lead blunt, iron cutting, salt magic, tin psychic, copper electric, sulphur asphyxiation, silver cold, gold fire, mercury poison"
  note: "IMBUE WITH wipes the old symbols; a symbol appears at most once"
```

### Robes automation (v4.7.422, `class_things/004_Alchemist_Robes.lua`)

Robes are not a DEF line, so SSC cannot keep them. Like METABOLISE, the system sends them itself:

- **Defup** (`checkSSCErrors`, the Alchemist branch) and **login** (17 s timer) call `ataxia_robesSummon`.
  It sends `queue add eq robes summon` once per session, then `queue add eq robes imbue with <four>`
  when that set is not already on.
- **Which four** (`aconfig robes auto`, the default): the damage types that cost us the most, from
  `bashStats.incomingByType` (the "Health lost: N (physical blunt)." line). The ranking is used after
  5 typed hits; until then, and to fill empty places, the set is **lead iron gold mercury**. "raw" and
  "unblockable" have no symbol and are skipped. A fresh Mnemosyne run resets `bashStats`, so in the
  tower the ranking is this run's.
- **In the tower** (`ataxiaBasher.inMnemosyne`) every typed hit calls `ataxia_robesCheck`. When the
  top four change, it re-imbues, at most once per 120 s, because each imbue costs one equilibrium.
  Outside the tower it never re-imbues by itself.
- `aconfig robes` shows the mode, the next set and the set last imbued. `aconfig robes lead iron gold
  mercury` fixes a set, `auto` restores the ranking, `off` stops it, `now` imbues now, `summon`
  summons a new set and imbues it.
- Unconfirmed: the game's lines for summon and imbue are not captured yet, so the "set on now" value
  is what we sent, not what the game confirmed.

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
attack_command: "EDUCE IRON <target>"   # ataxiaBasher_alchemistBashing, basher/002_Class_Bashing.lua
lead_in: "WIELD SHIELD"                 # every attack (v4.7.422); educe needs no weapon
shielded_target: "EDUCE COPPER <target>, or the battlerage raze at 17+ rage"
stat: int                               # basher/007_Mob_Damage_DB.lua
wrack: "WRACK <target> <affliction>, 2.00s of BALANCE, 60 mana; vs a denizen it must name an affliction"
```

### Mnemosyne boons (v4.7.424, `ataxiaBasher_alchemistBashing`)

Latched by `M.BOON_FLAGS` (`mnemosyne/004_Parsers.lua`); a boon we do not hold changes nothing.

| Boon | Text | What the rotation does |
|---|---|---|
| Pavonian (`mnemPavonian`) | Wrack does unblockable damage, +25% | `wrack <target> <aff>` rides beside the educe: wrack is balance, educe is equilibrium. Not into a shield. Aff from `ataxiaBasher.alchemistWrackAff`, default paralysis (the type does not matter, the damage is unblockable). |
| Purifying Salt (`mnemPurifyingSalt`) | Salt deals magic damage to all denizens in the room | `educe salt` replaces `educe iron` at `ataxiaBasher.alchemistSaltAt` (default 2) or more denizens: 3.00s against 4.00s of equilibrium, and the whole room. Never while stupid (stupidity blocks salt). |
| Rust (`mnemRust`) | Educe iron deals fire damage and afflicts sensitivity | No change: iron stays the attack. |

Not yet confirmed live: the size of wrack's balance penalty against an untempered (denizen) humour.
If it pushes balance past educe iron's 4.00s, the round waits on balance.

### Extispicy on rat kills (v4.7.422, `class_things/005_Alchemist_Extispicy.lua`)

`DISSECT <rat corpse>` (ABADMIN 8, 4.00 s of balance, 100 mana) raises the critical strike chance.
Rats live in the cities. GMCP shows the defence as `extispicy`.

- The kill line "You have slain <x>, retrieving the corpse." puts the corpse in the pack, so no GET.
- After a rat kill (`340_Slain` calls `ataxia_extispicyOnKill`), when the defence is down and mana is
  100 or more, the system sends `ii corpse`, takes the first row whose name holds the word "rat", and
  sends `queue addclear bal dissect <id>`.
- `ataxiaTemp.dissectHold` stops the basher (`ataxiaBasher_tryAttack` and `ataxiaBasher_attack`) from
  the probe until the queued dissect runs. Each attack sends `queue addclearfull`, and a cleared room
  moves on at once; either would lose the dissect. `queue_Scan` releases the hold on the
  "Running queued ... command: DISSECT" line; timers release it after 3 s with no rat corpse, or 8 s
  after the dissect is queued.
- "rat" is matched as a word: "a young rat" and "an old black rat" count, "a ratman" does not.
- `aconfig extispicy on|off`. Rats still have to be in the city's target list (`addmob`, or the
  automatic add on a kill).
- The homunculus ("a diminutive homunculus resembling <name>") is an own-denizen keyword (v4.7.422):
  the basher never targets it, never learns it, and the swarm count skips it.

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
