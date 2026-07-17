# Runewarden

## Metadata
- **Type**: Knight
- **Combat Style**: Limb | Affliction (depends on spec)
- **Difficulty**: Medium
- **Lock Affliction**: Weariness (blocks Fitness passive cure)

## Skills
```
Runelore: Mystical runes for combat and utility
Discipline: Passive abilities and combat enhancements
Weaponmastery: Combat with various weapon specializations (DWC, DWB, SnB, 2H)
```

## Specializations (Weaponmastery)
```yaml
DWC (Dual Wield Cutting):
  weapons: [scimitar, scimitar] or [longsword, longsword]
  style: Fast attacks, double venom application
  strength: Speed, venom stacking

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
  style: High damage, strip defenses
  strength: Best damage, passive para cure, strips rebounding/shield
```

> **Implementation note**: Only **Dual Blunt (DWB)** has an implemented dispatch offense
> (`dwbRunie`, `dwb_runie/001_DWB_Runie_Logic.lua`). The `zz`/attack aliases gate it on
> `gmcp.Char.Vitals.charstats[3] == "Spec: Dual Blunt"`
> (`aliases/.../152_First_Attack_(All_Classes).lua:23-26`). DWC / SnB / 2H specs have no
> RW-specific offense — they only run through the shared basher (see Bashing below).

## Kill Routes (DWB — `dwbRunie`)

The implemented offense (`dwb_runie/001_DWB_Runie_Logic.lua`) has **three modes**, selected via
`dwbRunie.setMode(...)` (aliases `rwtorso` / `rwpulp` / `rwgroup`). All kills are momentum-fuelled
damage, not disembowel/behead. Shared finishers (checked in `dispatch()` before mode routing):
**BISECT** at low health and **PULP** on a mangled head or 5+ skull fractures while prone.

### Mode: Torso Damage (`rwtorso`, default)
```yaml
type: limb + damage
summary: Break both legs (expend → prone) + torso, then assault the torso with flails
steps:
  1: "Prep left leg, right leg, torso (doublewhirl, lower-damage limb first)"
  2: "whirl right leg expend  → prone"
  3: "doublewhirl left leg torso  → break both"
  4: "assault <target> torso (flails) when momentum ≥3, doubled at ≥6"
  5: "morningstar doublewhirl torso pressure to rebuild momentum between assaults"
fork: "If target RESTOREs torso while legs still broken → pivot to skull fractures → PULP"
evidence: "dwb_runie:475-533"
```

### Mode: Head Pulp (`rwpulp`)
```yaml
type: limb + execute
summary: Break legs (prone) + head, assault head to mangle, build skull fractures, PULP
steps:
  1: "Prep left leg, right leg, head, torso (torso prepped for fork options)"
  2: "whirl right leg expend → prone; doublewhirl left leg head → break both"
  3: "assault <target> head at momentum ≥7 (mangles head)"
  4: "skull-fracture loop (doublewhirl head head [expend]) toward 5 fractures"
  5: "dismount;pulp <target> once head mangled OR 5+ skull fractures + prone"
fork: "Tumble fork — if target escapes prone → pivot to torso (already prepped)"
evidence: "dwb_runie:539-612"
```

### Mode: Group (`rwgroup`)
```yaml
type: limb + damage (team)
summary: Prone + torso damage with party callouts for pile-on coordination
notes: "Same break/execute shape as torso; sends 'pt <target> PRONE + TORSO BROKEN - PILE ON' via partyrelay"
evidence: "dwb_runie:618-654"
```

### Shared finishers (dispatch, all modes)
```yaml
bisect:  "assess <= 34 (config.bisectThreshold) and no shield → wield bastard;bisect <target>"
pulp:    "prone + (head mangled: 200% or concussion) OR skull fractures >= 5 → dismount;pulp <target>"
evidence: "dwb_runie:230-232,205-212,716-728"
```

## Momentum (core resource)
```yaml
# dwbRunie.getMomentum() = tonumber(ataxia.vitals.class)  (dwb_runie:189-204)
source: ataxia.vitals.class
thresholds:
  assault_torso:        ">= 3   (canAssaultTorso)"
  double_assault_torso: ">= 6   (canDoubleAssaultTorso — two torso assaults in one action)"
  assault_head:         ">= 7   (canAssaultHead — mangles head instantly)"
notes: |
  Momentum drives every mode. Morningstar doublewhirl builds it; flail assault spends it.
  Parry response and skull-fracture loops branch on 2+ / 1 / 0 momentum.
```

## Mode Aliases
```yaml
# aliases/.../dual_blunt/009_DWB_Runie_Mode.lua (regex ^rw(torso|pulp|group|status)$)
rwtorso:  "dwbRunie.setMode('torso')"
rwpulp:   "dwbRunie.setMode('pulp')"
rwgroup:  "dwbRunie.setMode('group')"
rwstatus: "dwbRunie.status()  — echoes mode, momentum, per-limb damage, skull fractures/cracked ribs"
# attack keys (152_First_Attack): zz → setMode('torso') + dispatch(); gated on Spec: Dual Blunt
```

## Offensive Abilities (DWB — actual fire commands)
```yaml
# These are the commands dwbRunie actually issues (dwb_runie:442-448,485-488,566,718,725,732)
whirl:
  effect: "Single-weapon limb hit (e.g. break a leg with 'expend')"
  syntax: "whirl <target> <limb> [expend]"

doublewhirl:
  effect: "Both weapons; prep or break one/two limbs. 'expend' consumes momentum"
  syntax: "doublewhirl <target> <limb> [expend] [<limb2> [expend]]"

assault:
  effect: "Flail/morningstar momentum-damage strike; torso ≥3 mom (≥6 doubled), head ≥7 mom (mangles)"
  syntax: "assault <target> torso | head"

pulp:
  effect: "Head execute — mangled head or 5+ skull fractures while prone"
  syntax: "dismount;pulp <target>"

bisect:
  effect: "Low-health finish (assess <= 34, no shield); wields a bastard sword first"
  syntax: "wield bastard;bisect <target>"

fracture:
  effect: "Used in the raze/strip path to remove rebounding/shield"
  syntax: "falcon track <target>;falcon slay <target>;fracture <target>"

falcon:
  effect: "Falcon companion — slay (prepended to assaults), track/rake, plus 'falcon rake' bash pet hit"
  syntax: "falcon slay | track | rake <target>"

# Runes are applied as WEAPON EMPOWERMENT, not standalone sketches (see below)
empower:
  effect: "Sets the rune empower priority on wielded weapons before attacking"
  syntax: "empower priority set isaz wunjo sowulu"
```

### Rune / weapon setup
```yaml
# dwb_runie:36-44,56-69,254-281 — runes here are weapon empowerment, NOT ground sketches / touch effects
loadout: "Dual morningstar + dual flail (per-weapon wield IDs in dwbRunie.config.weapons)"
per_weapon: "sketch nairat on each weapon; sketch configuration wielded isaz wunjo sowulu"
empower:    "'empower priority set isaz wunjo sowulu' sent once on weapon-type switch (anti-spam)"
switching:  "morningstar for prep/breaks/head; flail for torso assault"
```

## Defensive Abilities
```yaml
fitness:
  skill: Weaponmastery
  effect: "Passively cures asthma"
  cures: [asthma]
  blocked_by: [weariness]
  trigger: "Automatic when asthma is gained"

sowulu:
  skill: Runelore
  effect: "Weapon-empower rune in this system (part of the isaz/wunjo/sowulu empower set), not a self-heal"
  syntax: "empower priority set isaz wunjo sowulu"
  note: "isaz, wunjo and nairat are likewise applied here as offensive weapon runes, not touch/ground effects"

thurisaz:
  skill: Runelore
  effect: "Defensive barrier rune"
  syntax: "SKETCH THURISAZ"
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
# DWB prep set depends on mode (dwb_runie:476,540,620)
prep_set:
  torso_mode: [left leg, right leg, torso]
  pulp_mode:  [left leg, right leg, head, torso]
break_sequence: "whirl right leg expend (→ prone), then doublewhirl left leg + <torso|head>"
finisher: "assault torso / PULP head / BISECT (see Kill Routes) — no DISEMBOWEL exists in code"

## Parry Handling (dwb_runie:218-228,367-383)
parried_limb_source: "ataxiaTemp.parriedLimb ('none' when clear)"
disable_parry: "doublewhirl ... left arm expend  → applies 'numbedleftarm' (isParryDisabled)"
parry_response_by_momentum:
  "2+": "doublewhirl <primary> expend left arm expend  (disable + progress)"
  "1":  "doublewhirl left arm expend <unprepped non-parried limb>"
  "0":  "untargeted doublewhirl to generate momentum"

## Restoration forks
torso_mode: "torso RESTOREd while legs broken → pivot to skull fractures → PULP (dwb_runie:502-504)"
pulp_mode:  "head RESTOREd or target stands (tumble) → pivot to torso assault (dwb_runie:546-560,574-584)"

## Misc gates (dwb_runie:441,708-714,730-735)
clumsiness: "auto-cured with 'discipline' before breaking legs"
anti_serpent: "shield on impatience vs Serpent until cured"
instant_cath: "myinstantcath → touch shield"
raze_path: "rebounding/shield → falcon track;falcon slay;fracture <target>"
```

## Bashing (PvE)
```yaml
# ataxiaBasher_runewardenBashing() is spec-branched on ataxia.vitals.knight
# (basher/002_Class_Bashing.lua:658-693)
attack_skill: Weaponmastery
spec_branches:
  Dual Cutting: { raze: "rsl <target>",                         bash: "dsl <target>" }
  Two Handed:   { raze: "battlefury focus speed;carve <target>", bash: "battlefury focus speed;slaughter <target>" }
  Dual Blunt:   { raze: "fracture <target>",                     bash: "doublewhirl <target>" }
  else (SnB):   { raze: "combination <target> raze smash",       bash: "combination <target> slice smash" }
battlerage:
  raze: "ataxiaBasher.battlerage.Runewarden.raze (used when shielded + rageraze + rage >= 17)"
  # There is no 'slash'/'rend' battlerage — that was fictional.

# Falcon rake (ataxiaBasher)
# Free pet attack prepended to the bash when off cooldown (mirrors Infernal hyena maul).
falcon_rake:
  command: "FALCON RAKE <target>"
  cooldown: "30s (ataxiaBasher.falconRakeCooldownSec)"
  behavior: "Prepended to the spec bash string when ataxiaBasher.falconRakeReady is true"
  tracking: "basher/005_Falcon_Cooldowns.lua (triggers 370/371, timer fallback)"
```

## Fighting Against This Class
```yaml
priority_cures:
  - paralysis: "Prevents tree, allows them to continue attacking"
  - weariness: "Restores your Fitness if you have it"
  - broken_limbs: "Prevent disembowel setup"

dangerous_abilities:
  - disembowel: "Instant kill if limbs broken"
  - impale: "Locks you in place (SnB)"
  - runes: "Room control and utility"

avoid:
  - "Letting both legs get broken"
  - "Being prone with broken limbs"
  - "Ignoring limb damage"
  - "Standing on sketched runes (algiz, lagul, wunjo)"

recommended_strategy: |
  Focus on keeping limbs healthy with restoration/mending.
  Parry legs to slow their prep.
  If they're 2H spec, watch for high damage and passive para cure.
  If they're DWC spec, prioritize curing venoms quickly.
  Be aware of runes on the ground - they provide room control.
  Watch for sowulu (healing) and thurisaz (defense) runes.
```

## Limb Tracking
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

# dwbRunie thresholds (config, dwb_runie:65-68,179-183)
break_levels:
  prep:    "prepThreshold 99.9 — isPrepped: one/two whirl hits would reach this (not yet broken)"
  break:   "breakThreshold 100 — isBroken: damage >= 100 OR the 'damaged<limb>' aff"
  mangled: "200 — isMangled: damage >= 200 (or 'concussion' aff for head)"

pulp_check: |
  hasAff("prone")
  AND ( isMangled("head")  -- head >= 200% or concussion aff
        OR ataxiaTemp.fractures.skullfractures >= 5 )  -- config.skullFracturesForPulp
  → dismount;pulp <target>

bisect_check: |
  ataxiaTemp.lastAssess <= 34  -- config.bisectThreshold
  AND not hasAff("shield")
  → wield bastard;bisect <target>
```

## Implementation Notes
```
Triggers to watch for:
- "You have been impaled" - need to writhe
- "Your * is damaged/broken/mangled" - track limb state
- Venom messages for DWC tracking
- "sketches a rune" - rune being placed
- Rune activation messages

GMCP considerations:
- Track gmcp.Char.Vitals for limb percentages if available
- lb[target].hits["limb"] - enemy limb damage tracking
- Room items may include runes

Edge cases:
- 2H spec cures paralysis passively when attacking
- SnB has shield bash that can give random afflictions
- Runes persist until triggered or erased
- Some runes affect movement/positioning
```
