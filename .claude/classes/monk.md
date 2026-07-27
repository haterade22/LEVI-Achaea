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

### Primary Kill: Backbreaker (Tekura, Limb-Based)
```yaml
type: limb
summary: Prep all 6 limbs, break arms+torso then legs, finish with Backbreaker
implementation:
  primary: "tekura6 (002_Tekura_6Limb_Offense.lua) - 6-limb, tekura6.dispatch.run()"
  legacy: "tekura (001_Tekura_Offense.lua) - 3-limb, tekura.dispatch.run()"

phases (TK6):
  1_prep: "PREP - all 6 limbs to 86%+ (one punch, HFP ~14%, from break)"
  2_break_upper: "BREAK_UPPER - combo <tar> mnk <arm> spp <arm> hkp; HRS (Horse stance, breaks arms+torso)"
  3_break_lower: "BREAK_LOWER - combo <tar> wrt torso hfp left hfp right; BRS (Bear stance, wrenches torso + breaks legs, prones)"
  4_kill: "KILL - BBT <tar> (Backbreaker, in Bear stance)"

parry_avoidance: "During PREP skip parried limb; if last limb parried -> kai surge (dismount) -> sweep (prones) -> punch last limb"

kai_modes:
  surge: "31 kai, 3.2s eq, dismount (tekura6.config.kaiMode = 'surge')"
  cripple: "41 kai, 4s eq, dismount + L1 break all limbs ('cripple')"
```

### Alternative Kill: Scythe (Tekura TKD, Telepathy)
```yaml
type: damage
summary: Legacy 3-limb (tekura) system's alternative finisher via Telepathy
implementation: "001_Tekura_Offense.lua - tekura.PHASES.SCYTHE (phase 6)"
notes: "Set via tekura.state.preferScythe; a Telepathy-based kill, not a kick finisher"
```

### Attack Aliases (driver)
```yaml
# aliases/.../levi_062424/
first_attack:  "152 - tekura6.dispatch.run()"   # TK6 6-limb Backbreaker
fourth_attack: "153 - tekura6.dispatch.run()"   # TK6
second_attack: "155 - tekura.dispatch.run()"    # legacy TKD 3-limb
kai:  "kaido/001,006 -> 'kai surge <target>' ; kaido/003 -> 'kai cripple <target>'"
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
  file: "008_CC_Shikudo_Offense_ALL.lua"
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
  effect: "Execute a combo (kick + 2 punches): COMBO <target> <kick> <punch1> <punch2>"
  syntax: "COMBO <target> <kick> <punch> <punch>"
  # Implemented TK6 limb->attack map (tekura6.LIMB_ATTACKS):
  limb_attacks:
    head: "wwk (kick) / ucp (punch)"
    torso: "sdk (kick) / hkp (punch)"
    arms: "mnk left|right (kick) / spp left|right (punch)"
    legs: "snk left|right (kick) / hfp left|right (punch)"

break_and_kill:
  skill: Tekura
  balance: bal
  effect: "Backbreaker kill sequence stance/break moves"
  moves:
    - hrs: "Horse stance - break arms + torso"
    - brs: "Bear stance - wrench torso + break legs (prones)"
    - wrt: "Wrench torso (used with leg break)"
    - bbt: "Backbreaker - the kill (Bear stance)"

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
# Tekura (TK6): prep ALL 6 limbs, then break upper (arms+torso) and lower (legs), then Backbreaker
tekura_target_order: [head, torso, left_arm, right_arm, left_leg, right_leg]
tekura_break_requirements: {all_six_limbs: "86%+ prep -> break"}
# Shikudo (dispatch): prep legs + head + windpipe (via NEEDLE), then DISPATCH
shikudo_target_order: [left_leg, right_leg, head, windpipe]
finisher_options:
  - "BBT <target>"       # Tekura Backbreaker (all limbs broken, prone)
  - "DISPATCH <target>"  # Shikudo (legs + head + windpipe, prone)
```

## Bashing (PvE)
```yaml
# Entry point: ataxiaBasher_monkBashing2 (basher/002_Class_Bashing.lua). Spec resolved from
# charstats: Tekura if vitals.stance present, else Shikudo if vitals.form present.
tekura_attack: "unwield all; combo <tar> sdk ucp ucp"   # rhk instead of sdk when shieldbreak needed
shikudo_attack: "per-form COMBOs via shikudoBashCombo, riding Willow(leaveAt 9) -> Rain(5) -> Oak(5)"
shikudo_notes: "inline TRANSITION suffix on the combo; shatter variant for shieldbreak; kata self-zeroed after transition to avoid a fail loop"
transmute_gapfiller: "transmute to top up HP ONLY when sip balance is down and HP <= transmuteat (default 70)"
crushbash: "if ataxia.settings.crushbash set, sends 'mind crush <target>' instead"
shield: "Monk never spends rage on Splinterkick (spk) to raze - both specs break denizen shields free (shatter / rhk)"

# Battlerage (ataxiaBasher_monkBattlerage). Kit: SBP 14 (small dmg), MIND SCRAMBLE 22 (Clumsy),
# SPK 17 (shieldbreak, never used), MIND BLAST 25 (conditional), RPST 25 (Inhibit), TNK 36 (large dmg).
battlerage_priority:
  1: "RPST (Ripplestrike) -> Inhibit, ONLY vs healer denizens or the 'Sanguine Restoration' Mnemosyne affix"
  2: "TNK (Tornadokick, large) then SBP (Spinningbackfist, small) for damage"
  3: "MIND SCRAMBLE -> Clumsy (mob misses ~33%) with surplus rage (>=22)"
  note: "MIND BLAST deliberately not prioritised (its bonus wants Weakness/Sensitivity, not in Monk kit)"
```

## Fighting Against This Class
```yaml
priority_cures:
  - weariness: "Restores your Fitness if you have it"
  - broken_limbs: "Prevent Backbreaker (Tekura) / Dispatch (Shikudo) setup"
  - prone: "Stand up immediately (Sweep prones for Dispatch/Backbreaker)"
  - windpipe: "Mend/restore head-throat - Dispatch needs damagedwindpipe (from NEEDLE)"
  - mental_affs: "Telepathy can stack mental afflictions"

dangerous_abilities:
  - backbreaker: "Tekura BBT - instant kill once all 6 limbs broken and prone"
  - dispatch: "Shikudo - instant kill with legs + head broken, windpipe damaged, prone"
  - combinations: "Fast limb damage accumulation (COMBO kick + punches/staff)"
  - kai_abilities: "Self-healing, and Kai Surge to dismount you"

avoid:
  - "Letting all limbs (or legs+head) reach break threshold"
  - "Being proned by Sweep with legs broken"
  - "Letting them combo freely"
  - "Ignoring mental afflictions from Telepathy"

recommended_strategy: |
  Parry legs/head to slow the Backbreaker/Dispatch setup.
  Restore your windpipe to deny the Shikudo Dispatch condition.
  Keep restoration salve ready for limb damage; stand up out of prone fast.
  Track their kai balance (Kai Surge dismount / Cripple).
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

primary_file: "008_CC_Shikudo_Offense_ALL.lua"
  header: "Shikudo Offense (Unified)"
  description: "Unified Shikudo offense with mode selector (shikudo.dispatch/status/setMode)"
  includes:
    - "Dispatch mode (limb-based kill)"
    - "Lock mode (affliction lock)"
    - "Riftlock mode (blackout burst + lock - Mystor strategy)"
    - "God Mode (delegates to 009_CC_Shikudo_GodMode.lua)"

# On-disk files (shikudo/ dir holds 001-009):
files:
  001_Shikudo.lua: ""
  002_Shikudo_R2.lua: ""
  003_Dispatch_Dat_Hoe.lua: ""
  004_Levi_Dispatch.lua: ""
  005_Shikudo_Needle_Logic.lua: ""
  006_CC_Shikudo_Dispatch.lua: "Standalone dispatch"
  007_CC_Shikudo_Lock.lua: "Standalone lock"
  008_CC_Shikudo_Offense_ALL.lua: "UNIFIED offense (all modes) - PRIMARY"
  009_CC_Shikudo_GodMode.lua: "God Mode handler (shikudo.godmode.run/status)"

# Mode Selection
mode_system:
  current_mode: "shikudo.mode"
  set_mode: "shikudo.setMode(mode)"
  available_modes: [dispatch, lock, riftlock, godmode]

# God Mode (4th mode): setMode('godmode') -> shikudo.dispatch() delegates to
# shikudo.godmode.run() (009_CC_Shikudo_GodMode.lua). Own calcLimbs/formswap logic,
# PREP_THRESHOLD 92, lock-fork + low-HP (Maelstrom) branches.

# Dispatch behaviour specifics (008_CC_Shikudo_Offense_ALL.lua)
dispatch_specifics:
  staff: "Every attack prepends 'wield staff489282' (artifact staff)"
  mhaldorian_safety: "On a Mhaldorian target, sends INCAPACITATE instead of DISPATCH (friendly-fire safety)"
  kai_surge_dismount: "Auto 'kai surge' (>=31 kai) to dismount a mounted target while in Rain"
  gaital_kai_window: "Kai Surge window in Gaital (ataxiaTemp.kaiSurgeWindow) sweeps to re-prone + hammers the parried limb (~15s no-remount)"
  shield: "If target shielded, combo with 'shatter' to break it"

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
    godmode: "shikudo.setMode('godmode')"

# Current dispatch system (008_CC_Shikudo_Offense_ALL.lua)
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

### Riftlock Implementation (Unified 008_CC_Shikudo_Offense_ALL.lua)
```yaml
file: "008_CC_Shikudo_Offense_ALL.lua"
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

## Mystor Combat Discussion (Full Transcript)
```
Mystor: "You get alot of pressure toward prep that way."
Mystor: "But you lose out on alot of affliction pressure."
You: "I am going to be a bitch."
You: "Hit and run."
You: "Slow prep."
You: "I aint sitting in there with momentum classes."
You: "Doesnt make sense."
You: "To me at least."
Mystor: "As long as you stay within the kata fall off timer its fine."
Mystor: "You ccan sit with alot of the momentum classes."
You: "I usually try and run when they got maybe 3 afflictions on me."
You: "What would you do differently?"
Mystor: "Its just the super fast momentum that gets me."
You: "Serpents, DW."
Mystor: "I try to achieve 9/10 kata for the double up on kuro and ruku."
Mystor: "And then swap immediately."
Mystor: "So I can use the aff burst to pressure next stance."
Mystor: "Oak start gives me the best early hinder I can get."
Mystor: "With par and clumsy."
You: "That makes a lot of sense."
Mystor: "Gaital then gives me good continuance because im transitioning into it with clu hlee leth wea."
Mystor: "Rain I lose a little pressure in."
Mystor: "But I have good options with mind attacks."
Mystor: "Imp batter."
Mystor: "Blackout."
Mystor: "Also illusion."
Mystor: "Illusion for telepathy is huge."
Mystor: "You cannot see through it."
Mystor: "But since Im losing pressure in rain reguardless."
Mystor: "Ill fall back to disrupt the enemy if I can slip it in moments before enemy gets balance."
You: "But you can't attack and do telepathy right."
You: "One or the other."
Mystor: "But telepathy is sped up in rain."
Mystor: "Rain also has hiru."
You: "True."
Mystor: "And an easy prone."
Mystor: "So if you can beat their herb bal."
Mystor: "Slip an imp in."
Mystor: "And frontkick hiru."
Mystor: "Devistating."
You: "Mounted stops frontkick."
You: "Mounted stops a lot of monk."
Mystor: "Kaido."
You: "Pretty wild."
You: "Kai surge sure."
You: "A lot of time."
You: "Time is everything."
Mystor: "You are in rain."
Mystor: "Kai surge is faster in rain."
You: "That big of a difference?"
Mystor: "But Im already planning to lose some momentum in rain."
Mystor: "So kai surge doesnt really hinder me much."
Mystor: "Im also quick witted though."
Mystor: "But yes its a nice difference."
Mystor: "Also if you arent using blackout at all in the rest of your attacks."
Mystor: "Blackout in rain is basically a no brainer."
Mystor: "You can blackout, and then combo 1 time."
Mystor: "And the combo is hidden."
Mystor: "You will force a diag, or enemy to play defensive."
Mystor: "Most people will immediately assume you are disrupting."
Mystor: "And concentrate, so dont."
Mystor: "But you can slip some pretty nasty things in under that blackout."
You: "This is more complex than I was thinking."
Mystor: "Any telepathy attack."
Mystor: "Any combo available in rain."
Mystor: "One of the big things to slip that people dont check for."
Mystor: "Confusion."
Mystor: "Blackout into a frontkick hiru."
You: "Yeah."
You: "True."
Mystor: "If they do not cure confusion you can slip a mind impatience before herb bal."
Mystor: "Then disrupt."
Mystor: "And thats disgusting."
Mystor: "But ultimately, I go for a riftlock attempt in rain."
Mystor: "If I can get to 9 kata in rain with both of your arms prepped."
Mystor: "Ill blackout, mind paralyse."
Mystor: "To stop parry."
Mystor: "And frontkick break 1 arm, kuro ruku the other and a leg."
Mystor: "All in blackout."
Mystor: "You come out of blackout with ra2 la2 rl2 clu hlee wea leth."
Mystor: "And im transitioning into oak with that state."
Mystor: "Oak giving ast sli, now ast is kelpstack buried they can eat mag for sli but you have perfect info."
Mystor: "Followed by par sli."
Mystor: "Then mind imp, watch their cures."
Mystor: "And transition willow or gaital for finisher."
You: "That is a great rift lock."
Mystor: "Im not sure if nimble monk is fast enough to hide mind par and a combo within the blackout."
Mystor: "But honestly not hiding the combo isnt that big of a deal."
Mystor: "Its big for me because my balance is a little slower."
Mystor: "So I delay the salve apply until they regain balance and notice their arms are broken and leg is broken with prone."
Mystor: "If they apply leg to stand you have forever to finish a full lock."
Mystor: "If they apply an arm, you go into gaital with them prone and one leg already broken."
You: "You go quick witted?"
Mystor: "If they dont apply then you are already won."
Mystor: "Yeah im quick witted."
Mystor: "It makes dispatch way harder."
Mystor: "But scythe is a bit smoother."
Mystor: "I have 9 strength when im shikudo."
You: "Yeah."
You: "I didnt even think of scythe with shikudo."
Mystor: "I fork scythe in gaital."
You: "So many options with shikudo."
Mystor: "I sweep rl2, spinkick l3h crthr ll2."
You: "Just probably one of the most difficult to ... eh 'implement'."
Mystor: "And they can mending head for crthr, and if they restoration leg I transition rain and get scythe."
Mystor: "If they restoration h3 I can needle dispatch."
Mystor: "If they hold salve."
Mystor: "I can mind imp."
Mystor: "Mind batter."
Mystor: "On repeat to keep pressuring scythe."
Mystor: "They will have to choose either head or leg first eventually."
Mystor: "Or die to the scythe."
Mystor: "Spinkick to break head instantly elevates to 3."
Mystor: "And it does immense damage to head, if you drop the hyperfocus as you do it."
Mystor: "So basically head prep is like 60%."
Mystor: "Which I get easily because I start in oak."
Mystor: "I can probably start gaital if I want, when I get l3 staff, Im currently only working with l1."
You: "Man that is going to be wild to factor into my shit."
Mystor: "But then I lose out on all the hinderance from oak."
```

## Implementation Notes
```
Triggers to watch for:
- Combination attack patterns (COMBO kick + punches: sdk/ucp/hkp/mnk/spp/snk/hfp etc.)
- "Your * is damaged/broken/mangled" - track limb state
- Backbreaker (BBT) / break-stance moves (HRS/BRS/WRT) - Tekura kill sequence
- Dispatch messages - Shikudo instant kill
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
- Tekura Backbreaker (BBT) requires all 6 limbs broken + prone (TK6); TKD alt kill is Scythe via Telepathy
- Shikudo Dispatch requires legs + head broken, windpipe damaged, and prone
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

## Mnemosyne Boons (Shikudo bashing, v4.7.121-124)

```yaml
kai_unleashed:  # legendary — kai choke bursts magic damage on ALL denizens in the room
  flag: mnemKaiUnleashed
  behavior: "KAI CHOKE <target> PREPENDS to the Rain-form combo at 2+ denizens"
  ability_facts: "AB Kaichoke 896: 4.00s of EQUILIBRIUM (idle during balance combos —
    both land the same round); vs DENIZENS consumes NO kai, only 50 mana (250-mana
    floor); bonus damage vs damaged/mangled head/torso or mind clamp"
  cooldown: "30s on the boon's burst, CONFIRMATION-based: the burst line ('Your
    surroundings ripple like a lake's surface struck...') starts it via trigger 031;
    an eaten choke retries after 6s instead of forfeiting the window"
  live_numbers: "choke 3338→6369 asphyx (coalescence-empowered); burst 8472→25560
    magical (scales; one burst one-shot the primary); eq spend observed ~2.97s"

senseless_flurry:  # balance recovers 30% faster while the numbness defence is up
  flag: mnemSenselessFlurry
  behavior: "NUMB prepends to the Rain-form combo when the numbness defence is down
    (GMCP-tracked, 5s attempt-hold); fires on shielded rounds (self-targeted);
    Kai Choke OUTRANKS it — one eq spender per round"
  ability_facts: "AB Numbness 894: self-only, 3.00s eq; DEFERS incoming damage,
    delivered later in one blow at -40%. Fire line: 'You grit your teeth and will
    your pain out of existence.'"
  crowd_gate: "NEVER numbs at >= the swarm threshold or mid-swarm-tactic: deferral
    pins HP, blinding the damage-rate watchdog, danger levels, and the escape
    ladder until the lump lands — in a crowd that lump can exceed max HP (death
    from 'full HP' with every alarm silent). Thin rooms only."
```
