# Infernal

## Metadata
- **Type**: Knight
- **Combat Style**: Limb | Affliction (depends on spec)
- **Difficulty**: Medium
- **Lock Affliction**: Weariness (blocks Fitness passive cure)

## Skills
```
Malignity: Dark powers, entropy, and curses (Infestation, Belch)
Oppression: Aura-based abilities and control (Gravehands)
Weaponmastery: Combat with various weapon specializations (DWC, DWB, SnB, 2H)
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
summary: Break all 4 limbs to level 1 (withered), then vivisect

prerequisites:
  - All four limbs at level 1 break (withered/damaged state)
  - Note: Does NOT require prone (unlike disembowel)

finisher:
  command: "VIVISECT <target>"
  cooldown: "4.00 seconds equilibrium"
  effect: "Instant kill, bypasses starburst tattoo resurrection"
```

#### DWC Timing
```yaml
attack_balance: "1.8 - 2.1 seconds per DSL"
attacks_per_window: "~4 DSLs in 8 second prone window"
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
  - right_leg: "Primary prone source"
  - left_leg: "Backup prone + vivisect req"
  - arm: "Either arm, vivisect req"

prep_phase:
  1: "Prep right leg to near-break (DO NOT BREAK YET)"
  2: "Prep left leg to near-break (DO NOT BREAK YET)"
  3: "Prep arm to near-break (DO NOT BREAK YET)"

execute_phase:
  4: "DSL right leg with delphinium - breaks leg, prones, forces restoration"
  5: "DSL left leg with epteth/epseth - breaks + stacks salve demands"
  6: "DSL prepped arm to break"
  7: "DSL final arm with epteth/epseth while salve overwhelmed"
  8: "VIVISECT when all 4 limbs level 1"

why_three_limbs: |
  Most opponents can restore fast enough to heal 2 unprepped limbs.
  With 3 prepped, you only need to break 1 unprepped limb while
  their salve balance is overwhelmed.
```

#### Parry Bypass (Knight Mechanic)
```yaml
method: "Stick nausea on target"
effect: "Nausea prevents effective parrying"
usage: "When target is parrying your prep limb, stick nausea first"
```

#### Limb Tracking
```yaml
damage_percentage: "lb[target].hits['<limb>'] tracks 0-100%+"
level_1_break: "100% damage = level 1 (withered/damaged)"
prep_ready: "d2prepped = one DSL will break the limb"
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
