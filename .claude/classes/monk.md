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

### Alternative Kill: Shikudo Lock Route (Affliction-Based)
```yaml
type: affliction
summary: Pure affliction lock using Shikudo + Telepathy, damage through truelock

lock_progression:
  softlock: "asthma + anorexia + slickness"
  venomlock: "softlock + paralysis"
  hardlock: "venomlock + impatience (Telepathy)"
  truelock: "hardlock + weariness (blocks Fitness)"

shikudo_afflictions:
  hiraku: "anorexia + stuttering (Willow form)"
  livestrike: "asthma (Oak/Maelstrom)"
  ruku_torso: "slickness (Rain/Oak/Gaital/Maelstrom)"
  nervestrike: "paralysis (Oak)"
  kuro: "weariness/lethargy (Rain/Oak/Gaital)"

telepathy_afflictions:
  mindlock: "Required for Telepathy abilities"
  impatience: "Required for hardlock"
  batter: "stupidity + epilepsy + dizziness"
  paralyse: "Backup for paralysis"

form_strategy:
  1: "Start in Willow - get anorexia via Hiraku"
  2: "Transition to Rain - build kata, apply slickness"
  3: "Transition to Oak - apply asthma, paralysis, weariness"
  4: "Stay in Oak - maintain afflictions, use Telepathy for impatience"

kill_method: "Pure damage pressure through staff attacks + Telepathy once truelocked"

implementation:
  file: "010_Shikudo_Offense.lua"
  mode: "lock"
  activate: "sklock() or shikudolock()"
  dispatch: "shikudo.dispatch() (after mode set)"
  status: "shikudo.status() or skstatus()"
```

### Shikudo Kill: Dispatch (Limb-Based) - PRIMARY
```yaml
type: limb
summary: Prep legs AND head, SWEEP to prone + break legs, SPINKICK/NEEDLE head, DISPATCH

prerequisites:
  - Target must be prone (from SWEEP)
  - At least one leg broken (100%+) - keeps them prone
  - Head broken/damaged (100%+ or damagedhead affliction)
  - Windpipe damaged (from NEEDLE - gives damagedwindpipe or crushedthroat)

# CRITICAL: NEVER break legs until head is also prepped!
# Breaking legs prematurely wastes the setup.

kill_flow:
  phase_1_prep_legs:
    form: "Rain (24 kata capacity)"
    attacks: "KURO left/right"
    goal: "Both legs to 90.8% (one hit from break)"
    protection: "Once prepped, use LIGHT attacks to avoid breaking"
    transition: "Rain → Oak when kata >= 5 and legs prepped"

  phase_2_prep_head:
    form: "Oak"
    attacks: "NERVESTRIKE, RISINGKICK head"
    goal: "Head to ~92% (one hit from break)"
    protection: "Use LIGHT on legs if hitting them, or hit torso/arms"
    transition: "Oak → Gaital when kata >= 5 and all limbs prepped"

  phase_3_kill:
    form: "Gaital"
    combo_1: "SWEEP + KURO (prones + breaks both legs in one combo)"
    combo_2: "SPINKICK + NEEDLE (breaks head + applies windpipe)"
    combo_3: "DISPATCH (instant kill)"

dynamic_thresholds:
  description: "Prepped = ONE HIT away from breaking (100%)"
  calculation: "threshold = 100 - attack_damage"
  examples:
    kuro_9.2_percent: "Leg prepped at 90.8%"
    thrust_14.5_percent: "Leg prepped at 85.5%"
    nervestrike_7.8_percent: "Head prepped at 92.2%"
  note: "Actual damage depends on target health - use shikudo_limbDamage table"

edge_cases:
  partial_prep: "If legs not fully prepped in Rain, Oak can finish with KURO"
  kata_constraint: "Rain at kata 21+ ALWAYS goes to Oak (any transition resets kata)"
  waiting_for_kata: "Use LIGHT attacks or hit torso/arms if can't transition yet"
  parried_limbs: "Switch to alternate limb or use LIGHT on parried limb"

key_mechanics:
  spinkick:
    standing: "Hits TORSO"
    prone: "Hits HEAD with massive damage"
    prone_damaged_head: "Instantly MANGLES head (level 2 → level 3)!"
  sweep:
    effect: "Knocks target prone"
    cost: "Uses BOTH arm balances - only one kick allowed with sweep"
  light_modifier:
    effect: "Reduces limb damage, builds kata safely"
    usage: "Use on prepped limbs to avoid premature breaks"
  forms:
    transition: "Need 5+ kata to transition between forms"
    kata_reset: "ANY transition resets kata to 0"
    kata_limit: "12 per form (24 for Rain)"

kill_condition_check: |
  tAffs.prone
  AND (lb[target].hits["left leg"] >= 100 OR lb[target].hits["right leg"] >= 100)
  AND (lb[target].hits["head"] >= 100 OR tAffs.damagedhead)
  AND (tAffs.damagedwindpipe OR tAffs.crushedthroat)
  → DISPATCH

notes: |
  NEVER break legs until head is also prepped!
  The correct sequence is: prep both legs → prep head → Gaital → sweep/break → kill.
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

# Optimal form cycle: Willow → Rain → Oak → Gaital (when ready)
#
# Willow: Start here, HEAD prep with hiru/hiraku, transition to Rain at 6 kata
# Rain: PRIMARY LEG prep with kuro (24 kata capacity!), can also prep head with hiru
# Oak: HEAD prep with nervestrike, ONLY go to Gaital when BOTH legs AND head prepped
# Gaital: KILL form - sweep, needle, spinkick, dispatch
#
# If kill fails in Gaital: Maelstrom → Oak → (continue cycle)
#
# Key: NEVER enter Gaital until both legs AND head are prepped
# Key: Rain has 24 kata = ~8 combos of sustained prep time
```

## Shikudo Implementation (LEVI System)
```yaml
# UNIFIED OFFENSE SYSTEM
# All Shikudo offense modes consolidated into single file

primary_file: "010_Shikudo_Offense.lua"
  description: "Unified Shikudo offense with mode selector"
  includes:
    - "Dispatch mode (limb-based kill)"
    - "Lock mode (affliction lock)"
    - "Riftlock mode (blackout burst + lock - Mystor strategy)"
    - "Limb damage tracking (from 002_Shikudo_Limb_Counter.lua)"
    - "Form transition helpers (from 003_Shikudo_Extras.lua)"

# Legacy files (deprecated - functionality moved to unified file)
legacy_files:
  006_CC_Shikudo.lua: "Old dispatch (use 010 instead)"
  007_CC_Shikudo_Lock.lua: "Old lock (use 010 instead)"
  008_CC_Shikudo_RiftLock.lua: "Old riftlock (use 010 instead)"
  002_Shikudo_Limb_Counter.lua: "Old limb counter (integrated into 010)"
  003_Shikudo_Extras.lua: "Old form helpers (integrated into 010)"
  200_Shikudo.lua: "V1 Dispatch system (obsolete)"
  201_Shikudo_V2.lua: "V2 Dispatch system (obsolete)"

# Mode Selection
mode_system:
  current_mode: "shikudo.mode"
  set_mode: "shikudo.setMode(mode)"
  available_modes: [dispatch, lock, riftlock]

# Quick Commands (mode shortcuts)
quick_commands:
  dispatch_mode:
    - "skdispatch()"
    - "levishikudodispatch()"
  lock_mode:
    - "sklock()"
    - "shikudolock()"
  riftlock_mode:
    - "skriftlock()"
    - "shikudoriftlock()"

# Common Commands (work in any mode)
commands:
  attack: "shikudo.dispatch()"
  status: "shikudo.status() or skstatus()"
  reset: "shikudo.reset()"
  mode_switch:
    dispatch: "shikudo.setMode('dispatch')"
    lock: "shikudo.setMode('lock')"
    riftlock: "shikudo.setMode('riftlock')"

# Current dispatch system (006_CC_Shikudo.lua)
current_system:
  description: "Dynamic threshold-based dispatch with leg protection"

  dynamic_thresholds:
    purpose: "Calculate 'prepped' based on actual damage per hit"
    functions:
      - "shikudo.getLimbDamage(limb) → safely gets lb[target].hits[limb] or 0"
      - "shikudo.getLegPrepThreshold() → 100 - kuro_damage (~90.8%)"
      - "shikudo.getHeadPrepThreshold() → 100 - form_attack_damage"
      - "shikudo.isLegPrepped(leg) → true if leg >= threshold"
      - "shikudo.areBothLegsPrepped() → true if both legs prepped"
      - "shikudo.isDynamicHeadPrepped() → true if head >= threshold"
      - "shikudo.isLegSafe(leg) → true if safe to hit (head prepped or leg not prepped)"
      - "shikudo.getFocusLeg() → returns leg with LESS damage (hit first to balance prep)"
      - "shikudo.getOffLeg() → returns leg with MORE damage (secondary target)"

  limb_tracking:
    source: "lb[target].hits table from Romaen's limb counter"
    access_pattern: 'lb[target].hits["left leg"], lb[target].hits["right leg"], lb[target].hits["head"]'
    helper: "shikudo.getLimbDamage(limb) provides safe access with nil checks"
    note: "NOT tLimbs - that's for a different limb tracking system"

  hyperfocus:
    description: "Bypasses parry on a limb at cost of HALF damage"
    syntax: "HYPERFOCUS <limb|NONE>"
    balance_cost: "3.4 seconds"
    strategy: "ALWAYS hyperfocus HEAD at combat start, never switch"
    reason: "Head is key prep target; 3.4s cost makes switching impractical"
    damage_adjustment: "Head prep threshold changes from ~92% to ~96% (half damage)"
    functions:
      - "shikudo.setHyperfocus(limb) → set by trigger when hyperfocus message seen"
      - "shikudo.getHyperfocusCommand() → returns 'hyperfocus head' if not already set"
      - "shikudo.isHyperfocusSet() → true if head is hyperfocused"
    auto_behavior: "First dispatch() call will set hyperfocus head before attacking"

  transition_priority:
    flow: "Willow → Rain → Oak → Gaital (when ready)"
    0_all_ready: "BOTH legs AND head prepped → Go to Gaital for kill"
    1_willow:
      early_exit: "Willow at 6+ kata → Rain (head prep done, go to leg prep)"
    2_rain:
      legs_prepped: "Rain legs prepped + kata 9+ → Oak (for nervestrike head prep)"
      overflow: "Rain kata 21+ → ALWAYS go to Oak (safety transition before 24 stumble)"
    3_oak:
      all_ready: "Oak with both prepped → Gaital for kill"
      not_ready: "Oak at 9+ kata and NOT ready → Willow (cycle back for more prep)"
    4_gaital:
      kill_ready: "Stay for dispatch"
      stuck: "Kata 9+ and not ready → Maelstrom → Oak (cycle out)"

  transition_syntax:
    description: "Transitions are inline within the combo command"
    example: "combo target risingkick head nervestrike livestrike transition willow"
    note: "Non-Rain forms transition at 9 kata to avoid stumbling at 12"

  leg_protection:
    principle: "NEVER break legs until head is also prepped"
    method: "Use LIGHT staff attacks on prepped legs; Willow uses isLegSafe() check"
    forms_protected: [Rain, Oak, Tykonos, Willow]
    willow_behavior: "If legs prepped but head not ready, hit already-broken leg if possible"

  kill_sequence:
    phase_1: "Willow: START HERE, head prep with hiru/hiraku, transition to Rain at 6 kata"
    phase_2: "Rain: PRIMARY LEG prep with kuro (24 kata!), can also prep head with hiru"
    phase_3: "Oak: HEAD prep with NERVESTRIKE FIRST (paralysis prevents parry!)"
    phase_4: "Gaital: ONLY when both legs AND head prepped → sweep + break → dispatch"
    fallback: "If kill fails in Gaital: Maelstrom → Oak → (continue cycle)"

  attack_ordering:
    description: "Combo syntax is flexible: COMBO target attack1 attack2 attack3"
    principle: "Order attacks to maximize affliction/prone benefits"

    oak:
      order: "staff1 + staff2 + kick (STAFF FIRST)"
      reason: "Nervestrike paralysis prevents parrying subsequent attacks"
      example: "combo target nervestrike kuro left risingkick head"

    rain:
      order: "kick + staff1 + staff2 (KICK FIRST - default)"
      reason: "Frontkick can prone, which bypasses parry for staff attacks"
      example: "combo target frontkick left kuro left kuro right"

    gaital_sweep:
      order: "sweep + kick (SWEEP FIRST)"
      reason: "Sweep prones target, kick hits while prone"
      example: "combo target sweep flashheel left"
      note: "Sweep uses both arm balances - only one kick allowed"

    maelstrom_sweep:
      order: "sweep + kick (SWEEP FIRST)"
      reason: "Same as Gaital - sweep prones, kick follows"
      example: "combo target sweep risingkick head"

    maelstrom_normal:
      order: "kick + staff1 + staff2 (KICK FIRST - default)"
      reason: "Risingkick stuns if prone, crescent for damage"
      example: "combo target risingkick head livestrike ruku torso"

    other_forms:
      order: "kick + staff1 + staff2 (default)"
      reason: "No special affliction ordering needed"
```

## Advanced Shikudo Combat Strategies (Mystor's Insights)

### Fighting Momentum Classes
```yaml
principle: "Hit and run, slow prep"
strategy:
  - "Don't sit in combat against momentum classes (Serpents, DW)"
  - "Run when they have ~3 afflictions on you"
  - "Stay within kata fall off timer"
  - "Super fast momentum classes are the biggest threat"
  - "Time is everything - manage your windows carefully"

mounted_counter:
  problem: "Mounted stops frontkick and many monk abilities"
  solution: "Use KAI SURGE to dismount"
  note: "Kai surge is faster in Rain stance"
```

### Kata Double-Up Strategy (9/10 Kata)
```yaml
goal: "Achieve 9/10 kata for double up on kuro and ruku"
execution:
  1: "Build to 9-10 kata"
  2: "Use double kuro + ruku combo for max affliction burst"
  3: "Swap immediately after burst"
  4: "Use the aff burst to pressure next stance"

benefit: "Massive affliction pressure in single combo window"
```

### Stance Strategy Flow
```yaml
oak_start:
  description: "Best early hinder"
  afflictions: [paralysis, clumsiness]
  reason: "Par and clumsy provide immediate combat pressure"

gaital_transition:
  description: "Transition into Gaital with strong aff state"
  entering_with: [clumsiness, healthleech, lethargy, weariness]
  benefit: "Good continuance because transitioning with strong affliction stack"

rain_strategy:
  description: "Lose some affliction pressure, gain mind attack options"
  loses: "Some direct affliction pressure"
  gains:
    - "Mind attacks: imp, batter, blackout, illusion"
    - "Telepathy is SPED UP in Rain"
    - "Hiru for dizziness (confusion if prone)"
    - "Easy prone with frontkick"
    - "Kai surge is faster in Rain"

  hiru_combo:
    description: "Devastating frontkick hiru combo"
    execution: "If you beat their herb bal, slip imp in, then frontkick hiru"
    result: "Prone + dizziness + confusion if prone"
```

### Blackout Tactics (Rain Stance)
```yaml
description: "Blackout is a no-brainer in Rain if not using elsewhere"

hidden_combo:
  mechanic: "Blackout, then combo 1 time - combo is hidden"
  effect: "Forces diag or enemy plays defensive"
  psychology: "Most people assume you're disrupting and concentrate"

things_to_slip_under_blackout:
  - "Any telepathy attack"
  - "Any combo available in Rain"
  - "Strip a defence (if feeling lucky)"
  - "Confusion via frontkick hiru"

confusion_pressure:
  combo: "Blackout into frontkick hiru"
  follow_up: "If they don't cure confusion, slip mind impatience before herb bal"
  finisher: "Then disrupt - devastating"
  note: "Confusion extends equilibrium recovery by 100%"
```

### Riftlock Attempt (Rain Stance)
```yaml
setup:
  requirements:
    - "9 kata in Rain"
    - "Both arms prepped"

execution:
  1: "Blackout"
  2: "Mind paralyse (stops parry)"
  3: "Frontkick break 1 arm"
  4: "Kuro + ruku the other arm and a leg"
  5: "All done within blackout"

result_state:
  limbs: "RA2, LA2, RL2"
  afflictions: [clumsiness, healthleech, weariness, lethargy]

oak_continuation:
  description: "Transition into Oak with that state"
  affliction_sequence:
    1: "Oak gives asthma + slickness"
    2: "Asthma is kelpstack buried - they can eat mag for slickness but you have perfect info"
    3: "Follow with paralysis + slickness"
    4: "Then mind impatience, watch their cures"
    5: "Transition to Willow or Gaital for finisher"

# CRITICAL: Opponent CANNOT SEE what happens during blackout!
# No combat messages at all - they must DIAGNOSE to know what hit them
blackout_psychology:
  - "Opponent sees nothing during blackout"
  - "Most assume you're just disrupting and CONCENTRATE"
  - "Meanwhile you've paralyzed them, burst limbs, stacked affs"
  - "When blackout ends, they're in terrible state with ZERO info"
  - "They waste time with DIAGNOSE while you transition to Oak"
```

### Riftlock Implementation (Unified 010_Shikudo_Offense.lua)
```yaml
file: "010_Shikudo_Offense.lua"
mode: "riftlock"
commands:
  activate: "skriftlock() or shikudoriftlock()"
  attack: "shikudo.dispatch() (after mode set)"
  status: "shikudo.status() or skstatus()"
  reset: "shikudo.reset()"

phases:
  OAK_SETUP:
    description: "Build hindrance (paralysis + clumsiness)"
    form: Oak
    attacks: "nervestrike (para), ruku (clumsy)"
    transition_to: "Willow -> Rain when para+clumsy established"

  RAIN_PREP:
    description: "Build kata for blackout burst"
    form: Rain
    attacks: "kuro (weariness/lethargy), ruku (clumsy), hiru (dizziness)"
    goal: "Reach 9+ kata with mindlock established"
    transition_to: "BLACKOUT_BURST when ready"

  BLACKOUT_BURST:
    description: "Execute the hidden burst combo"
    form: Rain
    execution:
      1: "BLACKOUT (opponent goes blind)"
      2: "Mind PARALYSE (stops parry - they can't see this!)"
      3: "Frontkick + Kuro + Ruku burst (all hidden)"
    transition_to: "Oak for continuation"

  OAK_CONTINUATION:
    description: "Apply lock afflictions after burst"
    form: Oak
    attacks: "livestrike (asthma), ruku torso (slickness), nervestrike (para)"
    telepathy: "Mind impatience for hardlock"
    transition_to: "LOCK_PRESSURE when truelocked"

  LOCK_PRESSURE:
    description: "Pure damage pressure on truelocked target"
    forms: [Oak, Gaital, Rain]
    goal: "Kill through sustained damage"

key_functions:
  isReadyForBurst: "Returns true when in Rain with 9+ kata and mindlock"
  canBlackout: "Returns true if EQ available and cooldown elapsed"
  updatePhase: "Automatically detects and updates current phase"

synergies:
  - "Telepathy is FASTER in Rain stance (EQ balance decrease bonus)"
  - "Kai Surge is faster in Rain (for mounted targets)"
  - "Blackout hides ALL combat messages from opponent"
  - "Frontkick can prone (confusion via hiru if already prone)"

telepathy_rule:
  critical: "ONLY use Telepathy in RAIN form!"
  reason: "Rain provides EQ balance decrease bonus - telepathy is faster"
  exception: "Mindlock can be established in any form (one-time setup)"
  all_other_telepathy: "blackout, paralyse, impatience, batter - RAIN ONLY"
```

### Scythe Fork Strategy (Gaital)
```yaml
description: "Fork the opponent into choosing between head or leg death"

setup_combo:
  - "SWEEP RL2 (prone + leg damage)"
  - "SPINKICK L3H (leg level 3 + crushed throat)"
  - "Hit LL2 (other leg damage)"

enemy_choices:
  mending_head:
    action: "They mending head for crushed throat"
    counter: "If they restoration leg → transition Rain and get scythe"

  restoration_head:
    action: "They restoration head level 3"
    counter: "Needle dispatch available"

  hold_salve:
    action: "They hold salve"
    counter: "Mind imp, mind batter on repeat to pressure scythe"

outcome: "They choose head or leg first, or die to scythe"
```

### Spinkick Head Prep Optimization
```yaml
mechanic: "Spinkick to break head instantly elevates to level 3"
damage_boost: "Does immense damage to head if you drop hyperfocus as you do it"
oak_synergy: "Head prep is ~60% when starting in Oak"
hyperfocus_tip: "Drop hyperfocus right before spinkick for max damage"
```

### Character Build Considerations
```yaml
quick_witted:
  benefit: "Scythe is smoother"
  drawback: "Makes dispatch harder"
  recommendation: "Good for scythe-focused play"

strength:
  mystor_build: "9 strength when Shikudo"
  note: "Low strength, optimized elsewhere"

artifact_staff:
  level_1: "Current - Oak start recommended for hindrance"
  level_3: "Can start Gaital directly"
  tradeoff: "Gaital start loses Oak hindrance but faster kill route"
```

### Illusion for Telepathy
```yaml
stance: Rain
description: "Illusion for telepathy is huge - cannot be seen through"
usage: "Use when losing pressure in Rain anyway"
timing: "Slip in moments before enemy gets balance to disrupt"
synergy: "Rain speeds up telepathy, making illusion more viable"
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
- Hyperfocus: "You will now focus on bypassing attempts to deflect blows when striking the *"
  → Call shikudo.setHyperfocus(matches[2]) to track state
- Hyperfocus clear: "You stop focussing upon bypassing your target's parry"
  → Call shikudo.setHyperfocus(nil) to clear state

GMCP considerations:
- Track gmcp.Char.Vitals for limb percentages if available
- ataxia.vitals.form - current Shikudo form
- ataxia.vitals.kata - current kata count
- lb[target].hits["limb"] - enemy limb damage tracking (e.g., lb[target].hits["left leg"])
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
- Form transitions require 5+ kata (can transition anytime after 5 if conditions met)
- Rain form has 24 kata max (all others have 12)
- Willow transitions at 6 kata (2 combos) to avoid over-prepping legs
- Rain stays and preps head with hiru if legs already prepped (no rush, 24 kata)
- Oak at 9 kata goes to Gaital if ready, otherwise cycles back to Willow for more prep
- Gaital at 9 kata goes to Maelstrom if kill not ready (Maelstrom → Oak → Gaital cycle)
- Other non-Rain forms transition at 9 kata
- Transitions are inline: "combo target kick staff1 staff2 transition form"
- LIGHT modifier only works for STAFF attacks, not kicks
- Willow's flashheel can only hit legs - uses isLegSafe() to avoid premature breaks
```
