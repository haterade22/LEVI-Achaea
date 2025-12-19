# Monk

## Metadata
- **Type**: Base Class
- **Combat Style**: Limb | Affliction (Hybrid)
- **Difficulty**: Hard
- **Lock Affliction**: Weariness (blocks Fitness passive cure)

## Skills
```
Tekura: Unarmed martial arts combat (default)
  -OR-
Shikudo: Staff-based martial arts (requires Trans Tekura to unlock)
Kaido: Internal energy manipulation and healing
Telepathy: Mental powers and afflictions
```

## Specializations
```yaml
Tekura:
  description: "Default unarmed martial arts"
  style: "Punches, kicks, and combinations"
  strength: "Versatile combos, good affliction application"
  unlock: "Default for all monks"

Shikudo:
  description: "Staff-based martial arts"
  style: "Staff strikes and sweeps"
  strength: "Better limb damage, different combo routes"
  unlock: "Requires Trans Tekura first"
```

## Kill Routes

### Primary Kill: Throatchop (Limb-Based)
```yaml
type: limb
summary: Break throat to level 3, then throatchop for instant kill

prerequisites:
  - Throat must be at 200% damage (level 3 mangled)
  - Target must be prone or unable to parry

steps:
  1: "Focus attacks on throat/head"
  2: "Use combination attacks for limb damage"
  3: "Get throat to level 3 (200%)"
  4: "THROATCHOP <target> when throat mangled"

required_limbs:
  throat: 3
```

### Alternative Kill: SSK (Super Side Kick) - Damage
```yaml
type: damage
summary: High damage kick when target is prone with broken legs

prerequisites:
  - Target must be prone
  - Both legs broken

steps:
  1: "Break both legs with leg-targeting attacks"
  2: "Knock target prone"
  3: "SSK <target> for massive damage"
  4: "Repeat until dead"

notes: "SSK does huge damage to prone targets with broken legs"
```

### Alternative Kill: Affliction Lock via Telepathy
```yaml
type: affliction
summary: Use Telepathy to stack mental afflictions toward lock

steps:
  1: "Use Telepathy abilities for mental afflictions"
  2: "Apply mind lock afflictions"
  3: "Combine with Tekura attacks for venom application"
  4: "Work toward true lock"
  5: "Damage to death through lock"

notes: "Monk has mental affliction pressure through Telepathy"
```

### Shikudo Kill: Dispatch (Limb-Based) - PRIMARY
```yaml
type: limb
summary: Break legs, prone via SWEEP, break head, damage windpipe, DISPATCH for instant kill

prerequisites:
  - Target must be prone (from SWEEP)
  - At least one leg broken (100%+) - keeps them prone
  - Head broken/damaged (100%+ or damagedhead affliction)
  - Windpipe damaged (from NEEDLE - gives damagedwindpipe or crushedthroat)

steps:
  1: "Prep legs to 90%+ using KURO (Rain/Oak/Gaital forms)"
  2: "Prep head to 90%+ using NERVESTRIKE/NEEDLE/HIRU"
  3: "Transition to Gaital form (requires kata >= 5)"
  4: "SWEEP + FLASHHEEL (prone + break leg in one combo)"
  5: "NEEDLE + SPINKICK (windpipe damage + instant head mangle)"
  6: "DISPATCH <target> for instant kill"

key_mechanics:
  spinkick:
    standing: "Hits TORSO"
    prone: "Hits HEAD with massive damage"
    prone_damaged_head: "Instantly MANGLES head (level 2 → level 3)!"
  sweep:
    effect: "Knocks target prone"
    cost: "Uses BOTH arm balances - only one kick allowed with sweep"
  forms:
    transition: "Need 5+ kata to transition between forms"
    kata_limit: "12 per form (24 for Rain)"

kill_condition_check: |
  tAffs.prone
  AND (tLimbs.LL >= 100 OR tLimbs.RL >= 100)
  AND (tLimbs.H >= 100 OR tAffs.damagedhead)
  AND (tAffs.damagedwindpipe OR tAffs.crushedthroat)
  → DISPATCH

notes: |
  Breaking legs is CRITICAL - it keeps them prone (can't stand up).
  SPINKICK is the key - if head is already damaged (level 2), SPINKICK
  on a prone target instantly mangles it (level 3), setting up dispatch.
```

## Offensive Abilities
```yaml
# Tekura (Unarmed)
punch:
  skill: Tekura
  balance: bal
  effect: "Basic punch attack"
  syntax: "PUNCH <target>"

kick:
  skill: Tekura
  balance: bal
  effect: "Basic kick attack"
  syntax: "KICK <target>"

combination:
  skill: Tekura
  balance: bal
  effect: "Execute a combo of attacks"
  syntax: "<combo> <target>"
  combos:
    - smp: "Side Punch + Mid Punch"
    - sdk: "Side Kick + Double Kick"
    - ucp: "Upper Cut Punch"
    - hfk: "High Front Kick"
    - many_more: "See COMBO LIST"

ssk:
  skill: Tekura
  balance: bal
  effect: "Super Side Kick - massive damage to prone target"
  syntax: "SSK <target>"
  notes: "Huge damage if both legs broken and prone"

throatchop:
  skill: Tekura
  balance: bal
  effect: "Instant kill when throat is mangled (level 3)"
  syntax: "THROATCHOP <target>"

# Shikudo (Staff) - Alternative spec
# Shikudo uses COMBO syntax: COMBO <target> <kick> <staff1> <staff2>

combo:
  skill: Shikudo
  balance: bal
  effect: "Execute a combo of kick + staff strikes"
  syntax: "COMBO <target> <kick> <staff1> [staff2]"
  notes: "Primary attack method - up to 3 attacks per combo"

sweep:
  skill: Shikudo
  balance: bal
  effect: "Knocks target prone"
  syntax: "COMBO <target> sweep <kick>"
  notes: "Uses BOTH arm balances - only ONE kick allowed with sweep"
  forms: [Tykonos, Gaital]

needle:
  skill: Shikudo
  balance: bal
  effect: "High head damage + windpipe damage (required for Dispatch)"
  syntax: "COMBO <target> <kick> needle [needle]"
  forms: [Gaital]
  critical: "Windpipe damage is REQUIRED for Dispatch kill"

kuro:
  skill: Shikudo
  balance: bal
  effect: "Leg damage + weariness/lethargy affliction"
  syntax: "COMBO <target> <kick> kuro left/right"
  forms: [Rain, Oak, Gaital]
  notes: "Primary leg prep attack"

nervestrike:
  skill: Shikudo
  balance: bal
  effect: "Head damage + paralysis affliction"
  syntax: "COMBO <target> <kick> nervestrike"
  forms: [Oak]

ruku:
  skill: Shikudo
  balance: bal
  effect: "Arm/torso damage + clumsiness (arms) or slickness (torso)"
  syntax: "COMBO <target> <kick> ruku left/right/torso"
  forms: [Rain, Oak, Gaital, Maelstrom]
  notes: "Clumsiness is highly valuable - makes enemy miss attacks"

hiru:
  skill: Shikudo
  balance: bal
  effect: "Head damage + dizziness (confusion if prone)"
  syntax: "COMBO <target> <kick> hiru"
  forms: [Willow, Rain]

livestrike:
  skill: Shikudo
  balance: bal
  effect: "Torso damage + asthma affliction"
  syntax: "COMBO <target> <kick> livestrike"
  forms: [Oak, Maelstrom]

# Shikudo Kicks
spinkick:
  skill: Shikudo
  balance: bal
  effect: "Torso damage (standing) or HEAD damage (prone)"
  syntax: "COMBO <target> spinkick <staff1> <staff2>"
  forms: [Gaital]
  critical: "If prone + damaged head → INSTANTLY MANGLES head!"

flashheel:
  skill: Shikudo
  balance: bal
  effect: "High leg/knee damage"
  syntax: "COMBO <target> flashheel left/right <staff1> <staff2>"
  forms: [Willow, Gaital]

risingkick:
  skill: Shikudo
  balance: bal
  effect: "Head/torso damage, stuns if prone"
  syntax: "COMBO <target> risingkick head/torso <staff1> <staff2>"
  forms: [Tykonos, Oak, Maelstrom]

frontkick:
  skill: Shikudo
  balance: bal
  effect: "Arm damage"
  syntax: "COMBO <target> frontkick left/right <staff1> <staff2>"
  forms: [Rain]

dawnkick:
  skill: Shikudo
  balance: bal
  effect: "Head damage + epilepsy (repeats if prone)"
  syntax: "COMBO <target> dawnkick <staff1> <staff2>"
  forms: [Gaital]

dispatch:
  skill: Shikudo
  balance: bal
  effect: "INSTANT KILL when conditions met"
  syntax: "DISPATCH <target>"
  requirements:
    - "Target must be prone"
    - "At least one leg broken (100%+)"
    - "Head broken/damaged (100%+)"
    - "Windpipe damaged (from NEEDLE)"

# Kaido
kai:
  skill: Kaido
  balance: kai
  effect: "Various kai abilities"
  syntax: "KAI <ability>"
  abilities:
    - heal: "Heal HP"
    - cripple: "Self-damage for affliction cure"
    - transmute: "Convert health to mana"

# Telepathy
mindblast:
  skill: Telepathy
  balance: eq
  effect: "Mental damage and affliction"
  syntax: "MINDBLAST <target>"

mindlock:
  skill: Telepathy
  balance: eq
  effect: "Apply mental lock"
  syntax: "MINDLOCK <target>"
```

## Defensive Abilities
```yaml
fitness:
  skill: Tekura
  effect: "Passively cures asthma"
  cures: [asthma]
  blocked_by: [weariness]

kai_heal:
  skill: Kaido
  balance: kai
  effect: "Heal HP using kai"
  syntax: "KAI HEAL"
  notes: "Uses kai balance, separate from regular balance"

kai_cripple:
  skill: Kaido
  balance: kai
  effect: "Self-damage to cure affliction"
  syntax: "KAI CRIPPLE"
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
enabled: true
target_order: [throat, left_leg, right_leg]  # for throatchop or SSK
break_requirements:
  throat: 3  # for throatchop
  left_leg: 2  # for SSK
  right_leg: 2  # for SSK
finisher_options:
  - "THROATCHOP <target>"  # throat level 3
  - "SSK <target>"  # legs broken + prone
```

## Bashing (PvE)
```yaml
attack_command: "BATTLERAGE PUNCH <target>" or combos
attack_skill: Tekura
battlerage_abilities:
  - punch: "Basic damage"
  - kick: "Basic damage"
```

## Fighting Against This Class
```yaml
priority_cures:
  - weariness: "Restores your Fitness if you have it"
  - broken_limbs: "Prevent throatchop/SSK setup"
  - prone: "Stand up immediately"
  - mental_affs: "Telepathy can stack mental afflictions"

dangerous_abilities:
  - throatchop: "Instant kill if throat mangled"
  - ssk: "Massive damage when legs broken and prone"
  - combinations: "Fast limb damage accumulation"
  - kai_abilities: "Self-healing and utility"

avoid:
  - "Letting throat get to level 3"
  - "Being prone with both legs broken"
  - "Letting them combo freely"
  - "Ignoring mental afflictions from Telepathy"

recommended_strategy: |
  Parry throat/head to slow throatchop route.
  Parry legs if they're going SSK route.
  Keep restoration salve ready for limb damage.
  Track their kai balance for timing.
  Cure mental afflictions from Telepathy.
  Apply weariness to block their Fitness.
```

## Shikudo Forms
```yaml
# Shikudo uses 6 forms with different attacks available per form
# Must have 5+ kata to transition between forms
# Each form has a maximum kata before you stumble (lose kata)

Tykonos:
  max_kata: 12
  staff_attacks: [thrust, sweep]
  kicks: [risingkick]
  transitions_to: [Willow]
  style: "Defensive, basic attacks"
  notes: "Starting form, limited offensive options"

Willow:
  max_kata: 12
  staff_attacks: [dart, hiru, hiraku]
  kicks: [flashheel]
  transitions_to: [Rain]
  style: "Speed-focused"
  notes: "Good for head damage (hiru, hiraku)"

Rain:
  max_kata: 24  # DOUBLE chain length!
  staff_attacks: [kuro, hiru, ruku]
  kicks: [frontkick]
  transitions_to: [Tykonos, Oak]
  style: "Best for damage building"
  notes: "PRIMARY PREP FORM - 24 kata = ~8 combos of sustained damage"

Oak:
  max_kata: 12
  staff_attacks: [kuro, nervestrike, livestrike, ruku]
  kicks: [risingkick]
  transitions_to: [Willow, Gaital]
  style: "Power and afflictions"
  notes: "Good for paralysis (nervestrike) and asthma (livestrike)"

Gaital:
  max_kata: 12
  staff_attacks: [needle, sweep, kuro, ruku, jinzuku]
  kicks: [spinkick, flashheel, dawnkick]
  transitions_to: [Rain, Maelstrom]
  style: "KILL FORM"
  notes: "Has SWEEP, NEEDLE, SPINKICK, DISPATCH - the kill combo lives here"
  critical: "This is where you execute the Dispatch kill sequence"

Maelstrom:
  max_kata: 12
  staff_attacks: [ruku, livestrike, jinzuku, sweep]
  kicks: [risingkick, crescent]
  transitions_to: [Oak]
  style: "Death form"
  notes: "Alternative kill with CRESCENT"

# Form Transition Paths
transition_map:
  Tykonos: [Willow]
  Willow: [Rain]
  Rain: [Tykonos, Oak]
  Oak: [Willow, Gaital]
  Gaital: [Rain, Maelstrom]
  Maelstrom: [Oak]

# Optimal path to Gaital (kill form):
# Rain → Oak → Gaital (best)
# OR any form → build kata → transition toward Gaital
```

## Shikudo Implementation (LEVI System)
```yaml
# Implementation files in src/ataxia/
files:
  200_Shikudo.lua: "V1 Dispatch system (both legs 90%+ before sweep)"
  201_Shikudo_V2.lua: "V2 Dispatch system (focus fire, clumsy first)"
  081_Shikudo_Limb_Counter.lua: "Limb damage tracking formulas"
  082_Shikudo_Extras.lua: "Form transition helpers"

commands:
  v1:
    attack: "shikudo.dispatch() or levishikudodispatch()"
    status: "skstatus() or shikudo.status()"
  v2:
    attack: "shikudov2.dispatch() or levishikudov2()"
    status: "skv2status() or shikudov2.status()"

v1_vs_v2:
  v1:
    leg_targeting: "Alternate left/right legs"
    head_prep: "90% before sweep"
    clumsiness: "Weave in when legs ready"
    kill_combo: "needle + needle"
  v2:
    leg_targeting: "Focus fire ONE leg until 100% broken"
    head_prep: "100% (damaged), then SPINKICK instant mangle"
    clumsiness: "Apply FIRST, always (clumsy is king)"
    paralysis: "Early priority in Oak"
    kill_combo: "needle + spinkick (instant mangle)"
```

## Implementation Notes
```
Triggers to watch for:
- Combination attack patterns (SMP, SDK, etc.)
- "Your * is damaged/broken/mangled" - track limb state
- "executes a super side kick" - SSK incoming
- "chops at your throat" - throatchop attempt
- Telepathy ability messages

Shikudo-specific triggers:
- Form messages: "You are in the * form" - track current form
- Kata tracking: "You have * kata remaining" or GMCP
- Sweep messages: "sweeps * legs" - prone applied
- Needle messages: "jabs * with the staff" - windpipe damage
- Dispatch messages: "dispatches *" - kill executed
- SPINKICK on prone: "spins and kicks * in the head" - massive damage
- Stumble: "You lose your rhythm" - kata reset, form may change

GMCP considerations:
- Track gmcp.Char.Vitals for limb percentages if available
- ataxia.vitals.form - current Shikudo form
- ataxia.vitals.kata - current kata count
- tLimbs.H, tLimbs.LL, tLimbs.RL - enemy limb damage tracking
- tAffs.prone, tAffs.damagedwindpipe, tAffs.damagedhead - kill conditions
- Kai balance separate from regular bal/eq

Edge cases:
- Kai abilities use separate kai balance
- Shikudo requires Trans Tekura to unlock
- Combinations can hit multiple body parts
- SSK damage scales with leg breaks + prone
- Throatchop requires level 3 throat specifically
- Mental afflictions from Telepathy can add lock pressure
- SPINKICK behavior changes based on target state:
  - Standing: hits TORSO
  - Prone: hits HEAD with massive damage
  - Prone + damaged head: INSTANTLY MANGLES head (level 2 → 3)
- SWEEP uses BOTH arm balances - only one kick allowed
- Form transitions require 5+ kata
- Rain form has 24 kata max (all others have 12)
```
