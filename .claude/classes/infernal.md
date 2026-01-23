# Infernal

## Metadata
- **Type**: Knight
- **Combat Style**: Limb | Affliction (depends on spec)
- **Difficulty**: Medium
- **Lock Affliction**: Weariness (blocks Fitness passive cure)

## Skills
```yaml
Malignity:
  description: "Demonic hyena companion, archery, and aggressive combat abilities"
  components:
    - Hyena Companion: "Trainable demonic beast with Maul attack (30s cooldown)"
    - Archery: "Longbow, Crossbow, Darkbow for LOS (line of sight) combat"
    - Combat Buffs: "Battlecry (stun), Fury (+2 str), Fitness (cure asthma)"
  key_abilities: [Infestation, Belch, Battlecry, Fury, Putrefaction]

Oppression:
  description: "Hellforge system - profane weapons/armor with necromantic power"
  components:
    - Hellforge: "Core mechanic for channeling/investing abilities"
    - Armor Channels: "Max 2 active - Relentless, Conqueror, Bloodlust, etc."
    - Weapon Investments: "Replace venoms - Exploit, Torture, Torment, Punishment"
  resource: "Life essence (not personal health drain)"
  key_abilities: [Gravehands/Tyranny, Quash, Cripple, Vivisect, Agony]

Weaponmastery:
  description: "Combat with various weapon specializations"
  specs: [DWC, DWB, SnB, 2H]
  key_abilities: [DSL, Raze, Impale, Disembowel, Vivisect, Devastate]
```

## Specializations (Weaponmastery)
```yaml
DWC (Dual Wield Cutting):
  weapons: [scimitar, scimitar] or [longsword, longsword]
  style: Fast attacks, double venom application, limb breaking
  strength: Speed, venom stacking, faster limb prep
  kill_routes: [vivisect (primary), damage]

DWB (Dual Wield Blunt):
  weapons: [mace, mace] or [flail, flail]
  style: Limb breaking, double breaks per attack
  strength: Best limb prep, breaks through parry

SnB (Sword and Board):
  weapons: [longsword, shield] or [broadsword, shield]
  style: Impale/stun combos, defensive
  strength: Damage mitigation, reliable disembowel

2H (Two-Handed):
  weapons: [bastard sword] or [warhammer]
  style: Fractures, devastate, high damage
  strength: Best damage, passive para cure, strips rebounding/shield
  kill_routes: [vivisect, disembowel, damage, cleave/skullcrush]
```

## Two-Handed Mechanics (2H Spec)
```yaml
fracture_system:
  description: "2H relies on accruing fractures on opponent"
  types:
    torn_tendons:
      target: legs
      effect: "Less likely to leave room, periodic lethargy"
    wrist_fractures:
      target: arms
      effect: "Periodic clumsiness"
    cracked_ribs:
      target: torso
      effect: "Periodic sensitivity, reduced sip amount"
    skull_fractures:
      target: head
      effect: "Increased sip balance time (most deadly)"

skull_fracture_sip_times:
  0: "5s"
  1: "6s"
  2: "7s"
  3: "8s"
  4: "9s"
  5: "10s"
  6: "11s"
  7: "11s"

battlefury_focus:
  speed:
    effect: "More damage, quicker balance recovery"
    fractures: "Single fracture/tendon"
  precision:
    effect: "Less damage, slower recovery"
    fractures: "TWO fractures/tendons"

perceive:
  syntax: "BATTLEFURY PERCEIVE <target>"
  effect: "Shows fracture levels AND which limb is being parried"
  cost: "Requires battlefury balance but does not use it"
  usage: "Use every time you regain battlefury balance"

devastate_mechanics:
  description: "Converts fractures/tendons into limb breaks"
  wrist_fractures:
    2: "Level 1 break BOTH arms"
    4: "Level 2 break BOTH arms"
    6+: "Level 3 break BOTH arms"
  torn_tendons:
    2: "Level 1 break BOTH legs"
    4: "Level 2 break BOTH legs"
    6+: "Level 3 break BOTH legs"
  stacking: "If limb already broken, devastate raises it a level"
  example: "1 broken leg + 4 tendons + devastate = level 3 + level 2"

weapon_choice:
  bastard_sword:
    pros: ["Single venom strikes", "More damage"]
    cons: ["More hits to break limbs"]
  warhammer:
    pros: ["Faster balance", "Bonus limb damage", "3-4 hits to break"]
    cons: ["Less overall damage"]
    note: "Must learn proficiency in Hashan"
```

## Oppression Mechanics (Hellforge System)

### Core Concept
Hellforge allows Infernals to forge and profane weapons/armor at the Lord of Evil's temple, binding necromantic abilities to equipment.

```yaml
hellforge:
  location: "Lord of Evil's temple"
  resource: "Life essence (costs essence, not personal health)"
  types:
    channeled: "Armor-based abilities - max 2 active at once"
    invested: "Weapon-based abilities - replaces venoms"
```

### Armor Channels (Max 2 Active)
| Channel | Effect | Usage |
|---------|--------|-------|
| **Relentless** | Immunity to fear effects (affliction received but ineffective) | Always on for bashing |
| **Conqueror** | Regain balance/health on adventurer kills | Recommended for bashing |
| **Bloodlust** | Kills restore health/mana and cure afflictions | PvP sustain |
| **Pitiless** | Strike enemies upon your death; victims go to Halls of Finality | PvP revenge |
| **Anguish** | Causes periodic suffering to enemies; faster respawn via Halls | PvP pressure |

**Recommended Bashing Config**: Relentless + Conqueror

### Weapon Investments
See [Venoms & Hellforge Investments](#venoms--hellforge-investments) section for full details.

| Investment | Affliction | Best Use |
|------------|------------|----------|
| **INVEST TORTURE** | Haemophilia | Enable Agony healing |
| **INVEST EXPLOIT** | Paranoia + Weariness | Softlock pressure, block Fitness |
| **INVEST TORMENT** | Healthleech | Damage focus |
| **INVEST PUNISHMENT** | Scaling damage | Finish low-health targets |

### Passive Abilities (Oppression)
```yaml
relentless:
  effect: "Immunity to fear effects (affliction received but ineffective)"
  type: passive

unswayed:
  effect: "Damage resistance while wearing hellforged armor"
  type: passive

agony:
  effect: "Feed on bleeding targets - heal at 100+ bleed, cure affliction at 200+"
  trigger: "Automatic when enemy bleeds"
  synergy: "Use Torture investment or colocasia venom to enable"
  type: passive
```

## Hyena Companion System (Malignity)

### Training Stats
| Stat | Effect |
|------|--------|
| **Stamina** | Increases hyena health |
| **Speed** | Faster attacks and movement |
| **Strength** | More power and carrying capacity |

### Commands
```yaml
management:
  - HYENA ASSESS: "Check hyena status"
  - HYENA RECALL: "Call hyena to you"
  - HYENA SANCTUARY: "Send hyena to safety"
  - HYENA TRAIN <stat>: "Train Stamina/Speed/Strength"
  - HYENA REPORT: "Get status report"
  - HYENA FEED RAT: "Feed your hyena"

combat:
  - ORDER HYENA SLAY <target>: "Attack target"
  - ORDER HYENA MAUL <target>: "Direct attack (30s cooldown)"
  - ORDER HYENA HUNT: "Set to hunting mode"
  - ORDER HYENA FLEE: "Order retreat"

utility:
  - HYENA SEEK <target>: "Find target"
  - HYENA FOLLOW <target>: "Track someone"
  - HYENA TRACK: "Hunt down target"
  - HYENA SCENT: "Detect presence"
  - HYENA STARTLE <target>: "Interrupt target"
  - HYENA RETRIEVE <item>: "Fetch items"
  - HYENA DELIVER <item> TO <target>: "Bring items"
```

### Maul Attack
```yaml
maul:
  cooldown: "30 seconds"
  syntax: "ORDER HYENA MAUL <target>"
  usage: "PVE ONLY - not effective in PVP combat"
  tracking: "Implemented in 013_Infernal_Hyena_PVE.lua"
  triggers:
    cooldown_start: "A daemonic hyena snarls as she hurls herself at"
    cooldown_end: "You may command your hyena to maul your foes once more."
    on_cooldown: "You cannot yet order your hyena to maul another foe."
```

## Archery (Malignity - LOS Combat)

Used for **Line of Sight** combat when not in the same room as target.

### Weapon Types
| Weapon | Characteristics |
|--------|-----------------|
| **Longbow** | Standard ranged, more accurate |
| **Crossbow** | Higher damage, less accuracy |
| **Darkbow** | Superior accuracy (preferred) |

### Usage
```yaml
syntax: "SHOOT <target> <direction>"
example: "SHOOT enemy north"
usage: "LOS combat only - when not in same room as target"
accessories: ["Quiver", "Aiming skill"]
```

## Universal Combat Concepts

### Salve Balance Pressure (Limb Combat)
```yaml
description: |
  Core mechanic for all limb-based kill routes.
  Like "lock" for affliction combat, salve pressure is the
  foundation of limb combat strategy.

salve_balance:
  cooldown: "4 seconds"
  shared_by: [Restoration, Mending, Caloric]

curing_limb_breaks:
  level_1_break: "Restoration (4s salve balance)"
  level_2_break: "Restoration (4s) + Mending (4s) = 8 seconds minimum"

victim_priority: |
  Most players prioritize restoration on legs (to stand up).
  This creates predictable salve usage we can exploit.

the_exploit: |
  Break leg → they restoration (4s balance down) → can't mending yet
  They're prone for at least 8 seconds while curing the leg.

  Use epteth/epseth venoms to inflict MORE level 1 breaks.
  Each break demands another restoration application.
  Stack salve demands faster than they can cure = overwhelm.

the_math: |
  8 second prone window ÷ ~2 second attacks = ~4 attacks
  That's enough attacks to break remaining limbs while they can't stand.
```

## Kill Routes

### Two-Handed: Vivisection
```yaml
type: execute
summary: Stack 6+ tendons and 4+ fractures, devastate, upset, vivisect

prerequisites:
  - All four limbs must be at least level 1 breaks
  - Target must be prone

standard_setup:
  tendons: "6+ torn tendons"
  fractures: "4+ wrist fractures"

steps:
  1: "Stack torn tendons by hitting legs"
  2: "Stack wrist fractures by hitting arms"
  3: "At 6+ tendons, 4+ fractures: DEVASTATE LEGS <target>"
  4: "BATTLEFURY UPSET <target> (prones them)"
  5: "Target now has level 3 leg breaks - lots of time"
  6: "DEVASTATE ARMS <target> (level 2 arm breaks)"
  7: "VIVISECT <target>"

alternative_setup:
  description: "With less tendons"
  tendons: "4 torn tendons"
  fractures: "4 wrist fractures"
  steps:
    1: "Break one leg with weapon"
    2: "DEVASTATE LEGS (makes level 3 + level 2)"
    3: "DEVASTATE ARMS"
    4: "VIVISECT"
```

### Two-Handed: Disembowel
```yaml
type: execute
summary: Use tendons + torso prep for double disembowel

prerequisites:
  - 6+ torn tendons for double disembowel window
  - Torso damage for kill confirmation
  - Target must be prone

mechanics:
  double_disembowel: "With 6+ tendons, can disembowel TWICE after devastate/upset"
  torso_requirement: "Experienced fighters watch for torso break - hide it"

steps:
  1: "Prep one leg and torso to near-break"
  2: "Stack 6+ torn tendons"
  3: "BATTLEFURY SPEED/HEW LEG with epseth venom"
  4: "Target cures shriveled limb, then applies restoration (extra time)"
  5: "Break torso with epseth"
  6: "DEVASTATE LEGS/UPSET"
  7: "IMPALE"
  8: "DISEMBOWEL"
  9: "IMPALE"
  10: "DISEMBOWEL"
  11: "If needed, follow with TAINT or ARC"

torso_hiding_tip: |
  Most will parry head, leaving torso open.
  Cracked ribs: 1) Decreases sip amount, 2) Ticks sensitivity.
  High cracked ribs = guaranteed kill (low sips + sensitivity).
```

### Two-Handed: Damage Kill
```yaml
type: damage
summary: Use high 2H damage output to kill through health

steps:
  1: "Stack cracked ribs (reduces sip effectiveness, gives sensitivity)"
  2: "Stack skull fractures (increases sip balance time)"
  3: "Continue dealing damage while they can't heal effectively"
  4: "Kill through sustained damage"

synergy: "Cracked ribs + skull fractures = can't sip enough, can't sip often enough"
```

### Two-Handed: Cleave/Skullcrush
```yaml
type: execute
summary: Head-focused route with skull fractures

steps:
  1: "Focus attacks on head"
  2: "Stack skull fractures"
  3: "CLEAVE or SKULLCRUSH when conditions met"

notes: "Most will parry head - may need to feint or outplay parry"
```

### Standard Kill: Disembowel (Limb-Based)
```yaml
type: limb
summary: Break both legs and an arm, then disembowel for instant kill

prerequisites:
  - Target must be prone
  - Both legs broken (level 2)
  - One arm broken (level 2)

steps:
  1: "Prep limbs - focus legs first, then arm"
  2: "Knock target prone"
  3: "DISEMBOWEL <target>"

required_limbs:
  left_leg: 2
  right_leg: 2
  left_arm: 2  # or right_arm
```

### Alternative Kill: Behead (Limb-Based)
```yaml
type: limb
summary: Break head to level 3 (mangled), then behead

steps:
  1: "Focus all damage on head"
  2: "Get head to 200% (level 3 mangled)"
  3: "BEHEAD <target>"

required_limbs:
  head: 3
```

### DWC: Vivisect (Primary Kill Path)
```yaml
type: limb
summary: Break all 4 limbs to level 1+ (withered), then vivisect

prerequisites:
  - All four limbs at level 1+ break (withered/damaged state)
  - Note: Does NOT require prone (unlike disembowel)

finisher:
  command: "VIVISECT <target>"
  cooldown: "4.00 seconds equilibrium"
  effect: "Instant kill, bypasses starburst tattoo resurrection"
```

#### Understanding Break Levels
```yaml
level_1_break:
  sources:
    - "Epteth venom (arm break level 1)"
    - "Epseth venom (leg break level 1)"
  effect: "Limb is 'withered' - counts for vivisect requirement"
  cure: "Single restoration application (4s salve balance)"

level_2_break:
  sources:
    - "Physical limb damage reaching 100%+"
    - "Undercut on prepped leg"
  effect: "Limb is 'broken/crippled' - also counts for vivisect"
  cure: "Restoration (4s) + Mending (4s) = 8 seconds minimum"

key_insight: |
  Epteth and epseth venoms give level 1 breaks to non-targeted limbs!
  This means a single DSL with epteth/epseth can affect multiple limbs:
  - Physically breaks the targeted limb (level 2)
  - Applies level 1 break to opposite arm (epteth)
  - Applies level 1 break to opposite leg (epseth)
```

#### DWC Timing
```yaml
attack_balance: "1.8 - 2.1 seconds per DSL"
attacks_per_window: "~4 DSLs in 8 second prone window"
undercut_salve_lock: "4 seconds (forces restoration, blocks mending)"
```

#### Optimized Two-Attack Kill (Undercut + DSL)
```yaml
summary: |
  The fastest vivisect route - only 2 attacks after prep phase.
  Uses battleaxe undercut for prone + break, then scimitars for final break.

prerequisites:
  - Both arms prepped to 90%+
  - Left leg prepped to 90%+

execute_sequence:
  step_0:
    weapon: "Battleaxe"
    action: "UNDERCUT <target> left leg"
    investment: "HELLFORGE INVEST EXPLOIT"
    effects:
      - "Breaks left leg (level 2)"
      - "4 second salve lock (forces restoration, blocks mending)"
      - "Target is effectively locked for 4 seconds"
    note: "Undercut does NOT prone, but 4s salve lock is better"

  step_1:
    weapon: "Scimitars (DSL)"
    action: "DSL <target> right arm epteth epseth"
    effects:
      - "Breaks right arm (level 2 from physical damage)"
      - "Epteth gives level 1 to LEFT ARM"
      - "Epseth gives level 1 to RIGHT LEG"
    result: "All 4 limbs now at level 1+ → VIVISECT"

  kill:
    action: "VIVISECT <target>"
    condition: "All 4 limbs at level 1+"

why_this_works: |
  1. Undercut breaks leg + 4s salve lock
  2. DSL with epteth/epseth on right arm:
     - Physically breaks right arm (level 2)
     - Epteth poisons left arm (level 1)
     - Epseth poisons right leg (level 1)
  3. Result: 4 limbs broken in just 2 attacks!

timing_window: |
  - Undercut: ~2s balance + 4s salve lock on target
  - DSL: ~2s balance
  - Total window: ~4s before they can mending
  - That's enough for DSL + vivisect
```

#### Strategy: Two-Limb Prep (vs weaker opponents)
```yaml
summary: Prep 2 limbs to near-break, then execute break sequence

prep_phase:
  1: "Prep leg to near-break (DO NOT BREAK YET)"
  2: "Prep other limb to near-break (DO NOT BREAK YET)"

execute_phase:
  3: "DSL leg with delphinium - breaks leg, prones target, forces restoration"
  4: "DSL prepped limb with epteth + epseth - breaks it + inflicts more lvl 1 breaks"
  5: "Continue DSL with epteth/epseth - overwhelm salve balance"
  6: "VIVISECT when all 4 limbs level 1"
```

#### Strategy: Three-Limb Prep (vs most opponents)
```yaml
summary: Prep 3 limbs to near-break, then execute break sequence

target_limbs:
  - left_leg: "Primary undercut target"
  - left_arm: "Prep for backup"
  - right_arm: "DSL target with epteth/epseth"

prep_phase:
  1: "Prep left leg to 90%+ (DO NOT BREAK YET)"
  2: "Prep left arm to 90%+ (DO NOT BREAK YET)"
  3: "Prep right arm to 90%+ (DO NOT BREAK YET)"

execute_phase:
  4: "UNDERCUT left leg - breaks leg, 4s salve lock"
  5: "DSL right arm with epteth/epseth - breaks + gives level 1 to left arm and right leg"
  6: "VIVISECT - all 4 limbs at level 1+"

why_three_limbs: |
  Provides redundancy if target mends during prep.
  With 3 prepped, undercut + single DSL is enough for vivisect.
```

#### RIFTLOCK Mode (Counter to RESTORE)
```yaml
trigger: "Target uses RESTORE ability (heals all limbs)"
detection: "<target> crackles with blue energy that wreathes itself about his limbs."

strategy: |
  When target uses RESTORE, all limb progress is lost.
  Switch to riftlock mode to punish them and prevent further use.

riftlock_goal:
  - "Break arms (prevents rifting herbs)"
  - "Stick anorexia (prevents eating)"
  - "Stick slickness (prevents applying salves)"
  - "Stick addiction (eating triggers cooldown)"
  - "Maintain paralysis (prevents tree)"

execute_sequence:
  step_1:
    action: "DSL left arm with kalmia/vardrax"
    effect: "Prep arm + asthma + addiction"

  step_2:
    action: "DSL left arm with slike/gecko"
    effect: "Break arm + weariness + slickness"

  step_3:
    action: "DSL right arm with euphorbia/curare"
    effect: "Prep arm + anorexia + paralysis"

  step_4:
    action: "Continue pressure until locked"

affliction_priority:
  v1_choices:
    - "slike (anorexia) - blocks eating"
    - "gecko (slickness) - blocks applying"
    - "vardrax (addiction) - eating triggers cooldown"
  v2_constant: "curare (paralysis) - always"

exit_condition: "Manual exit or target dead"
```

#### Parry Bypass (Knight Mechanic)
```yaml
method: "Stick nausea on target"
effect: "Nausea prevents effective parrying"
usage: "When target is parrying your prep limb, stick nausea first"
```

#### Limb Tracking
```yaml
# Uses lb[target].hits["limb"] format for limb damage tracking
# NOT tLimbs - use Romaen's limb counter format

access_pattern:
  left_leg: 'lb[target].hits["left leg"]'
  right_leg: 'lb[target].hits["right leg"]'
  left_arm: 'lb[target].hits["left arm"]'
  right_arm: 'lb[target].hits["right arm"]'
  head: 'lb[target].hits["head"]'
  torso: 'lb[target].hits["torso"]'

damage_percentage: "lb[target].hits['<limb>'] tracks 0-100%+"
level_1_break: "100% damage = level 1 (withered/damaged)"
prep_ready: "d2prepped = one DSL will break the limb"

disembowel_check: |
  lb[target].hits["left leg"] >= 100
  AND lb[target].hits["right leg"] >= 100
  AND (lb[target].hits["left arm"] >= 100 OR lb[target].hits["right arm"] >= 100)
  AND tAffs.prone
  → DISEMBOWEL
```

## Combat Preparation
```yaml
infestation:
  skill: Malignity
  effect: "Afflicts ENEMIES with one affliction every 10 seconds"
  usage: "Start of battle"
  notes: "Won't lock as 2H, but helps hinder opponent"

gravehands:
  skill: Oppression
  effect: "Sometimes stops non-Mhaldorians from leaving, balance penalty"
  usage: "FIRST action in group combat from any necromancer"
  syntax: "HANDS OF THE GRAVE"

belch:
  skill: Malignity
  effect: "Makes EVERYONE else in room weak from hunger"
  syntax: "BELCH"
  warning: "Very deadly - use chivalrously"
```

## Venoms & Hellforge Investments

**Sources:** [Venom (Skill)](https://wiki.achaea.com/Venom_(Skill)), [Oppression](https://wiki.achaea.com/Oppression)

### Standard Venoms (Weaponmastery ENVENOM)

#### Cure Herb Reference
| Herb | Afflictions Cured |
|------|-------------------|
| **kelp** | clumsiness, healthleech, weariness, asthma, sensitivity, hypochondria, parasite |
| **ginseng** | nausea, haemophilia, addiction, darkshade, flushings, lethargy, scytherus |
| **goldenseal** | stupidity, impatience, depression, sandfever, epilepsy, dizziness, dissonance, shyness |
| **lobelia** | recklessness, vertigo, spiritburn, tenderskin, loneliness, claustrophobia, masochism, agoraphobia |
| **ash** | confusion, hypersomnia, hallucinations, paranoia, dementia, crescendo |
| **bellwort** | timeloop, justice, lovers, peace, pacified, generosity, indifference, diminished |
| **bloodroot** | paralysis |

#### Venom → Affliction → Cure Reference
| Venom | Affliction | Cure | Combat Use |
|-------|------------|------|------------|
| **curare** | paralysis | bloodroot | Venomlock, prevent tree |
| **kalmia** | asthma | **kelp** | Softlock, block smoking |
| **xentio** | clumsiness | **kelp** | Kelp stack, 33% miss chance |
| **euphorbia** | nausea | **ginseng** | Block parry, enable limb prep |
| **gecko** | slickness | **kelp** | Softlock, block salves |
| **slike** | anorexia | **kelp** | Softlock, block eating |
| **prefarar** | sensitivity (or removes deafness) | **kelp** | Damage amplification |
| **vardrax** | addiction | **ginseng** | Riftlock helper, eating triggers cooldown |
| **delphinium** | sleep | wake/insomnia | Sleeplock, prone via leg break |
| **epseth** | crippled leg (level 1) | mending | Limb pressure |
| **epteth** | crippled arm (level 1) | mending | Limb pressure |
| **voyria** | voyria (sip damage) | antidote | Lock aff for healers |
| **eurypteria** | recklessness | **lobelia** | Lock aff for Depthswalker |
| **digitalis** | shyness | **goldenseal** | Mental stack |
| **larkspur** | dizziness | **goldenseal** | Mental stack |
| **monkshood** | disloyalty | **lobelia** | Hinder loyalty-based abilities |
| **aconite** | stupidity | **goldenseal** | Mental stack, focus bait |
| **darkshade** | darkshade (light allergy) | **ginseng** | Hinder targeting |
| **notechis** | haemophilia | **ginseng** | Lock aff for Magi/Sylvan, Agony synergy |
| **sumac** | impatience | **goldenseal** | Truelock completion |
| **vernalius** | weakness | **kelp** | Hinder physical actions |
| **oleander** | blindness | smoke | Hinder targeting |
| **colocasia** | blindness + deafness | smoke + deafness | Full sensory denial |
| **loki** | random affliction | varies | Unpredictable pressure |

### Hellforge Investments (Oppression)
Investments **replace venoms** on weapons with Oppression effects. Only the main hand weapon can be invested.

| Investment | Affliction | Cure | Notes |
|------------|------------|------|-------|
| **INVEST TORTURE** | haemophilia | **ginseng** | Enables Agony passive healing |
| **INVEST EXPLOIT** | weariness + paranoia | **kelp + ash** | Two affs at once, blocks Fitness |
| **INVEST TORMENT** | healthleech | **kelp** | Sustained damage, confusion if already has healthleech |
| **INVEST PUNISHMENT** | scaling damage | n/a | More damage on wounded targets |

### Focus Lock Venom Strategy (PREP Phase)
The focus lock strategy alternates kelp/ginseng afflictions to overwhelm curing, then baits focus with goldenseal:

**Phase 1: Kelp/Ginseng Stack (with curare)**
1. xentio → clumsiness (**kelp**)
2. euphorbia → nausea (**ginseng**)
3. torment → healthleech (**kelp**) - hellforge
4. torture → haemophilia (**ginseng**) - hellforge
5. kalmia → asthma (**kelp**)

**Phase 2: Focus Bait (once asthma stuck)**
- aconite/exploit → stupidity (**goldenseal**) + weariness + paranoia (**kelp + ash**)
- They'll want to FOCUS to clear stupidity, but exploit adds 2 more affs

**Phase 3: Lock Layer (ONLY if asthma still stuck)**
- gecko/slike → slickness + anorexia (both **kelp**)
- **IMPORTANT**: Only enter this phase if asthma is stuck! Slickness can be cured by smoking valerian if asthma is cured.
- Stacks on existing kelp affs, overwhelms kelp curing
- Slickness blocks apply, anorexia blocks eating

**Phase 4: Riftlock Transition**
- Once addiction + slickness stuck → epteth/epteth to break limbs

### Venom Strategy by Goal
```yaml
for_softlock:
  venoms: [kalmia, gecko, euphorbia]
  goal: "Block eating, smoking, salves"

for_venomlock:
  venoms: [curare, kalmia, gecko, euphorbia]
  goal: "Softlock + paralysis blocks tree"

for_truelock:
  venoms: [curare, kalmia, gecko, euphorbia, sumac, slike]
  goal: "Venomlock + impatience blocks focus + weariness blocks Fitness"

for_limb_pressure:
  venoms: [epseth, epteth, delphinium]
  goal: "Break limbs, prone with delphinium"

for_damage_amp:
  venoms: [prefarar, colocasia]
  goal: "Sensitivity + haemophilia for Agony healing"
```

### DWC Dual Blade Mechanics
```yaml
dual_blade_setup:
  left_hand: "MAIN sword - can use HELLFORGE INVEST"
  right_hand: "OFF-HAND sword - uses normal ENVENOM only"
  note: "Only the main sword (left hand) can be invested"

syntax: "DSL <target> <limb> <venom1> <venom2>"
```

### DWC DSL Venom Combinations
```yaml
# Limb Pressure Phase
for_breaking_legs:
  combination: [delphinium, delphinium]
  timing: "When both legs prepped and ready to prone"
  effect: "Break leg + force sleep (strips insomnia, then gypsum, then sleeps)"

for_limb_overwhelm:
  combinations:
    - [epteth, epteth]   # Double arm break
    - [epseth, epseth]   # Double leg break
    - [epteth, epseth]   # Mixed arm+leg break
  timing: "After first leg broken to overwhelm salve balance"
  effect: "Stack limb damage faster than they can restore"

# Affliction Building Phase
for_lock_building:
  combinations:
    - [curare, euphorbia]   # Paralysis + Anorexia (via nausea)
    - [curare, kalmia]      # Paralysis + Asthma
    - [gecko, kalmia]       # Slickness + Asthma
    - [aconite, slike]      # Stupidity + Weariness (mental stack + lock)
  timing: "When prepping softlock/venomlock"

for_truelock_finish:
  combinations:
    - [sumac, slike]        # Impatience + Weariness
    - [curare, sumac]       # Paralysis + Impatience
  timing: "When softlocked and pushing for truelock"

# With Hellforge Investments
investment_plus_venom:
  note: "Investment on MAIN sword + venom on OFF-HAND sword"
  per_dsl: "You get: Investment effect (main) + 1 venom (off-hand)"
  examples:
    - invest: exploit      # Main sword: Paranoia + Weariness
      venom: curare        # Off-hand: Paralysis
      result: "3 afflictions per DSL (para + paranoia + weariness)"
    - invest: exploit      # Main sword: Paranoia + Weariness
      venom: epteth        # Off-hand: Arm break
      result: "Limb damage + 2 afflictions (paranoia + weariness)"
    - invest: torture      # Main sword: Haemophilia
      venom: epteth        # Off-hand: Arm break
      result: "Limb damage + bleed for Agony healing"
    - invest: torment      # Main sword: Healthleech
      venom: prefarar      # Off-hand: Sensitivity
      result: "Damage amplification combo"

investment_decision_logic:
  use_exploit: "When softlocked (has anorexia + asthma + slickness) and no weariness"
  use_torture: "When target already has haemophilia (for Agony passive)"
  use_torment: "When focused on damage output"
  use_punishment: "When target is low health (scaling damage)"

no_investment_mode:
  note: "Without investment, both swords use normal venoms"
  syntax: "DSL <target> <limb> <venom1> <venom2>"
  example: "DSL enemy left_leg curare kalmia"
```

## Offensive Abilities
```yaml
# Weaponmastery - General
slash:
  skill: Weaponmastery
  balance: bal
  effect: "Basic attack with cutting weapon"
  damage_type: cutting
  syntax: "SLASH <target>"

raze:
  skill: Weaponmastery
  balance: bal
  effect: "Strip shield or rebounding"
  syntax: "RAZE <target>"

impale:
  skill: Weaponmastery
  balance: bal
  effect: "Impale target, prevents movement"
  syntax: "IMPALE <target>"
  notes: "SnB spec, also used in 2H disembowel combo"

disembowel:
  skill: Weaponmastery
  balance: bal
  effect: "Instant kill if legs and arm broken, target prone"
  syntax: "DISEMBOWEL <target>"

vivisect:
  skill: Weaponmastery
  balance: bal
  effect: "Instant kill if all four limbs at least level 1"
  syntax: "VIVISECT <target>"
  requirement: "All limbs level 1+ broken"

# Two-Handed Specific
battlefury_focus:
  skill: Weaponmastery
  balance: battlefury
  effect: "Set speed or precision for next attack"
  syntax: "BATTLEFURY FOCUS <SPEED/PRECISION>"
  speed: "More damage, faster balance, 1 fracture"
  precision: "Less damage, slower balance, 2 fractures"

battlefury_perceive:
  skill: Weaponmastery
  balance: battlefury
  effect: "See fracture levels and parried limb"
  syntax: "BATTLEFURY PERCEIVE <target>"
  notes: "Requires but doesn't consume battlefury balance"

battlefury_upset:
  skill: Weaponmastery
  balance: bal
  effect: "Prone target"
  syntax: "BATTLEFURY UPSET <target>"

devastate:
  skill: Weaponmastery
  balance: bal
  effect: "Convert fractures/tendons to limb breaks"
  syntax: "DEVASTATE <LEGS/ARMS> <target>"
  conversion:
    2: "Level 1 both limbs"
    4: "Level 2 both limbs"
    6+: "Level 3 both limbs"

hew:
  skill: Weaponmastery
  balance: bal
  effect: "Two-handed attack targeting limb"
  syntax: "HEW <limb> <target>"

# Malignity
entropy:
  skill: Malignity
  balance: eq
  effect: "Causes damage over time"
  syntax: "ENTROPY <target>"

infestation:
  skill: Malignity
  balance: eq
  effect: "Afflicts enemies every 10 seconds"
  syntax: "INFESTATION"

taint:
  skill: Malignity
  balance: eq
  effect: "Followup damage"
  syntax: "TAINT <target>"

arc:
  skill: Malignity
  balance: eq
  effect: "Damage attack"
  syntax: "ARC <target>"

# Soulspears (Group)
soulspears:
  skill: Malignity
  balance: eq
  effect: "Instantly raises gravehands, shatters shield, deals damage"
  syntax: "SOULSPEAR <target>"
  notes: "Very useful in group combat"

# Oppression
tyranny:
  skill: Oppression
  balance: eq
  effect: "Summon gravehands, prones non-Mhaldorians"
  cost: "3% life essence"
  syntax: "HANDS OF THE GRAVE"

quash:
  skill: Oppression
  balance: bal
  effect: "Hand-strike removing magical shields + damage"
  syntax: "QUASH <target>"

cripple:
  skill: Oppression
  balance: bal
  effect: "Break two limbs simultaneously"
  syntax: "CRIPPLE <target>"
  notes: "Accelerates vivisect setup"

exterminate:
  skill: Oppression
  balance: eq
  effect: "Clear plant life from room"
  cost: "5% essence (scales on repeat)"
  syntax: "EXTERMINATE"

rampage:
  skill: Oppression
  balance: bal
  effect: "Chase fleeing enemies"
  syntax: "RAMPAGE <target>"
  notes: "Instant with gravehands present"

predator:
  skill: Oppression
  balance: eq
  effect: "Detect targets across planes via oppressive gaze"
  syntax: "PREDATOR <target>"

desecration:
  skill: Oppression
  balance: eq
  effect: "Sever devotional rites from locations"
  syntax: "DESECRATE"

# Malignity Combat
battlecry:
  skill: Malignity
  balance: eq
  effect: "Stun target"
  cooldown: "4s equilibrium"
  syntax: "BATTLECRY <target>"
```

## Defensive Abilities
```yaml
fitness:
  skill: Weaponmastery
  effect: "Passively cures asthma"
  cures: [asthma]
  blocked_by: [weariness]
  trigger: "Automatic when asthma is gained"

putrefaction:
  skill: Malignity
  effect: "Liquefies skin - increases blunt and cutting resistance"
  syntax: "PUTREFACTION"
  notes: "Always have this up"

weathering:
  skill: Chivalry
  effect: "Adds one point of CON"
  syntax: "WEATHERING"

resistance:
  skill: Chivalry
  effect: "Resistance to magical damage"
  syntax: "RESISTANCE"

gripping:
  skill: Chivalry
  effect: "Hold weapons tightly"
  syntax: "GRIPPING"
  notes: "Also attach fist sigils for safety"

swiftmount:
  skill: Chivalry
  effect: "VAULT without using balance"
  syntax: "VAULT <mount>"
  notes: "Access to MOUNTJUMP and FLY with legendary mounts"

# Oppression Passives
relentless:
  skill: Oppression
  effect: "Immunity to fear effects (affliction received but ineffective)"
  type: passive

unswayed:
  skill: Oppression
  effect: "Damage resistance while wearing hellforged armor"
  type: passive

agony:
  skill: Oppression
  effect: "Feed on bleeding targets - heal at 100+ bleed, cure affliction at 200+"
  trigger: "Automatic when enemy bleeds"
  synergy: "Use Torture investment or colocasia venom"
  type: passive

# Malignity Combat Abilities
fury:
  skill: Malignity
  balance: eq
  effect: "+2 strength temporarily"
  cooldown: "2s equilibrium"
  syntax: "FURY ON/OFF"

rage:
  skill: Malignity
  balance: none
  effect: "Cure pacifying afflictions"
  cost: "150 mana"
  syntax: "RAGE"

clotting:
  skill: Malignity
  balance: none
  effect: "Reduce bleeding"
  cost: "60 mana"
  syntax: "CLOT"
```

## Equipment Recommendations
```yaml
armor:
  best: "Fullplate armour"
  budget: ["Fieldplate", "Splintmail"]

weapons_2h:
  bastard_sword: "Default proficiency, more damage, single venom"
  warhammer: "Faster, bonus limb damage (3-4 hits vs 8), needs Hashan proficiency"

ranged:
  bow_types:
    longbow: "More accurate, less damage"
    crossbow: "Less accurate, more damage"
    darkbow: "Balanced accuracy/damage (preferred)"
  accessories: ["Quiver", "Aiming skill"]

falcon:
  abilities: "Knocks off balance, strips defenses (with talons)"
  usage: "Solo and group combat"
  commands:
    - "DROP FALCON"
    - "ORDER FALCON FOLLOW <target>"
    - "ORDER FALCON SLAY <target>"
  notes: "Attacks ENEMIES list - reorder after kills"

mount:
  benefits: ["Raises avoidance", "Harder for monks/blademasters to kill"]
  abilities: ["SWIFTMOUNT", "MOUNTJUMP", "FLY (legendary)"]
```

## Passive Cures
```yaml
fitness:
  cures: [asthma]
  blocked_by: [weariness]
  trigger: "Passive, automatic on asthma gain"

2h_paralysis_cure:
  cures: [paralysis]
  trigger: "When attacking with 2H weapon"
  notes: "2H spec only"
```

## Limb Strategy
```yaml
enabled: true

2h_strategy:
  fracture_targets:
    legs: "Torn tendons - hinders fleeing, gives lethargy"
    arms: "Wrist fractures - gives clumsiness"
    torso: "Cracked ribs - reduces sips, gives sensitivity"
    head: "Skull fractures - increases sip balance time"

  vivisect_setup:
    tendons: 6
    fractures: 4
    sequence: "Devastate legs -> Upset -> Devastate arms -> Vivisect"

  disembowel_setup:
    tendons: 6
    torso: "Prepped and broken"
    sequence: "Devastate/Upset -> Impale -> Disembowel -> Impale -> Disembowel"

standard_strategy:
  target_order: [left_leg, right_leg, left_arm]
  break_requirements:
    left_leg: 2
    right_leg: 2
    left_arm: 2
  finisher: "DISEMBOWEL <target>"
```

## Bashing (PvE)
```yaml
attack_command: "BATTLERAGE SLASH <target>" or spec-specific
attack_skill: Weaponmastery
battlerage_abilities:
  - slash: "Basic damage"
  - rend: "Additional damage"

# Pre-Combat Legend Deck (ataxiaBasher)
# Automatically draws cards before attacking dangerous multi-target rooms
ldeck_draws:
  elite_mhun_keepers:
    count: "3+"
    cards: [Maran, Matic]
    note: "Both barrier and damage boost"
  mhun_knights:
    count_3: "Maran only"
    count_4_plus: "Maran + Matic"
  queue_command: "queue add free ldeck draw <card>"

# Recommended Oppression Config
armor_channels:
  recommended: [Relentless, Conqueror]
  note: "Max 2 channels active at once"
  relentless: "Fear immunity - always useful"
  conqueror: "Regain balance/health on adventurer kills"

# Hyena Usage
hyena:
  maul:
    cooldown: "30 seconds"
    syntax: "ORDER HYENA MAUL <target>"
    tracking: "Implemented in 013_Infernal_Hyena_PVE.lua"
  slay:
    syntax: "ORDER HYENA SLAY <target>"
    note: "Continuous attack mode"

# Optional Abilities
battlecry:
  usage: "Stun high-priority targets"
  cooldown: "4s equilibrium"
  syntax: "BATTLECRY <target>"

fury:
  usage: "+2 strength for tough fights"
  syntax: "FURY ON"
```

## Fighting Against This Class
```yaml
priority_cures:
  - paralysis: "Prevents tree, allows them to continue attacking"
  - weariness: "Restores your Fitness if you have it"
  - broken_limbs: "APPLY RESTORATION - prevent disembowel/vivisect setup"
  - sensitivity: "EAT KELP - from cracked ribs"
  - lethargy: "EAT GINSENG - from torn tendons"
  - clumsiness: "EAT KELP - from wrist fractures"

dangerous_abilities:
  - disembowel: "Instant kill if limbs broken"
  - vivisect: "Instant kill if all 4 limbs level 1+"
  - devastate: "Converts fractures to massive limb breaks"
  - impale: "Locks you in place"
  - soulspear: "Shatters shield, raises gravehands"

avoid:
  - "Letting both legs get broken"
  - "Being prone with broken limbs"
  - "Ignoring limb damage"
  - "Letting fractures stack (2H)"
  - "High skull fractures (sip time increases)"

vs_2h_spec:
  watch_for:
    - "Fracture stacking - track torn tendons and wrist fractures"
    - "DEVASTATE incoming when fractures high"
    - "Torso prep for disembowel"
    - "Skull fractures increasing sip time"
  counters:
    - "Parry based on PERCEIVE tracking"
    - "Cure fracture effects (sensitivity, lethargy, clumsiness)"
    - "Watch torso - they're hiding prep for disembowel"
    - "2H cures paralysis when attacking - don't rely on para"

recommended_strategy: |
  Focus on keeping limbs healthy with restoration/mending.
  Parry legs to slow their prep.
  If they're 2H spec:
    - Track fracture counts (6+ tendons = danger)
    - Watch for DEVASTATE (converts fractures to breaks)
    - They cure para when attacking - don't rely on it
    - Skull fractures increase sip time dramatically
    - Cracked ribs reduce sip amount and give sensitivity
  If they're DWC spec:
    - Prioritize curing venoms quickly
  Apply weariness to block their Fitness.
```

## Implementation Notes
```
Triggers to watch for:
- "You have been impaled" - need to writhe
- "Your * is damaged/broken/mangled" - track limb state
- Venom messages for DWC tracking
- Fracture messages (torn tendon, wrist fracture, cracked rib, skull fracture)
- "devastates" - major limb break incoming
- "perceives" - they're tracking your parry
- "BATTLEFURY" messages

GMCP considerations:
- Track gmcp.Char.Vitals for limb percentages if available
- Otherwise parse damage messages
- Track fracture counts via messages

Edge cases:
- 2H spec cures paralysis passively when attacking
- SnB has shield bash that can give random afflictions
- Devastate converts fractures: 2=lvl1, 4=lvl2, 6+=lvl3 BOTH limbs
- Devastate raises existing break levels
- Perceive shows parried limb - they'll adapt
- Soulspears raise gravehands instantly
- Belch affects EVERYONE in room (dangerous)
- Infestation afflicts every 10 seconds
- Falcon attacks enemies list - needs reordering after kills

Skull Fracture Sip Times:
0=5s, 1=6s, 2=7s, 3=8s, 4=9s, 5=10s, 6=11s, 7=11s

Devastate Thresholds:
- 2 fractures/tendons = Level 1 both limbs
- 4 fractures/tendons = Level 2 both limbs
- 6+ fractures/tendons = Level 3 both limbs
```
