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
  description: "Resource spent every balance via `psi transcend <blast|excise|muddle|shatter> <target>`"
  spend_types: "blast (mind ravaged), excise (mana kill), muddle (muddled), shatter (fallback/flurry setup)"
  note: "Shield is NOT a transcend function — it is stripped via `weave cleave <target>`"

impatience_delivery:
  requirement: "Target must be PRONE or have DAMAGED HEAD"
  note: "They will hit you with both simultaneously"
```

## Modes & Commands (our offense)
```yaml
# psion namespace — psion/001_Levi_Psion_Logic.lua
modes:
  mind:   "Primary — unweave pressure + mana kill via psi blast/excise (default)"
  flurry: "Damage — invert unweaves to spirit, then flurry for burst damage"

aliases:
  psmind:   "Set mind mode + dispatch"
  psflurry: "Set flurry mode + dispatch"
  psstatus: "Status display (unweave/critical levels, kill conditions, transcendence, target mana)"
  psreset:  "Reset combat state"
  psdebug:  "Toggle debug echoes"
dispatch: "zz — main attack dispatch (152_First_Attack); psion.setMode() / psion.dispatch()"

attack_wrapper:
  prefix: "wield right shield"
  suffix: "enact lightbind <target> (if not active) :: assess <target> :: contemplate <target>"
  note: "contemplate feeds target mana% into the `pm` global gating psi excise at 30%"

filler_afflictions:  # once both unweaves (mind+body) applied
  sever:   "clumsiness"
  puncture: "weariness"
  priority: "Priest/Occultist/Pariah get weariness first (blocks Fitness); others get clumsiness first"
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
  2: "Apply Unweaving Spirit (or invert an existing critical mind/body unweave to spirit)"
  3: "Let UWS level up (auto-levels every 4s)"
  4: "At high level (4-5), FLURRY for massive burst"
  5: "Follow up with damage to finish"

flurry_mode_mechanics: |
  In flurry mode the system converts critical unweaves to spirit before flurrying:
  - `weave invert <target> mind spirit` (when criticalmind, no criticalspirit)
  - `weave invert <target> body spirit` (when criticalbody, no criticalspirit)
  Once inverted + spirit unweave present: `psi transcend shatter <target>` then
  `weave flurry <target>`.

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
  weakness: "Stripped with `weave cleave <target>` (prioritized when shielded), not transcend"

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
  syntax: "weave prepare <prep> :: weave <attack> <target>"
  notes: |
    Split into two queued sub-commands: `weave prepare <prep>` (free aff)
    then `weave <attack> <target>` (attack = overhand/backhand/deathblow/
    unweave/deconstruct/flurry/cleave). Prep is the free affliction on
    every attack.
  weave_prepare_affs:
    disruption: paralysis
    laceration: haemophilia/bleed
    vapours: asthma
    rattle: epilepsy
  prepare_priority: |
    laceration if mind-ravaged (bleed pressure) → disruption (paralysis)
    → laceration (haemophilia) → vapours (asthma) → rattle (epilepsy/fallback).
    Flurry mode: rattle when impatience present but no epilepsy.
  head_attacks:
    overhand: "Break head + deliver impatience (needs damaged head OR prone)"
    backhand: "Break head + deliver stupidity/dizziness"
    deathblow: "Break head + deliver asthma + bleed"

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
  syntax: "enact lightbind <target>"
  applied_as: "Suffix on every attack when lightbind not already active"
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
  syntax: "weave flurry <target>"
  setup: "Preceded by `psi transcend shatter <target>`; flurry mode inverts unweaves to spirit first (weave invert <target> mind|body spirit)"
  damage: "Level 5 UWS = ~90% max health"

# Psionics
psi_blast:
  skill: Psionics
  balance: eq
  effect: "Apply mind ravaged (every hit saps mana)"
  syntax: "psi transcend blast <target>"
  requirement: "3 of: unweavingmind, blackout, epilepsy, stupidity, impatience, dizziness"
  notes: "Key to mana kill route. Blast is one of the psi transcend spend types."

psi_excise:
  skill: Psionics
  balance: eq
  effect: "Instant kill at 30% mana"
  syntax: "psi excise <target>"
  requirement: "Target at 30% mana or below (target mana% tracked via `contemplate` suffix → `pm` global)"
  notes: "Main mana execute; transcend spends `psi transcend excise <target>` when mana <= 30%"

# Unweaving
unweave_mind:
  skill: Weaving
  balance: eq
  effect: "Apply unweaving mind (auto-levels, mana drain)"
  syntax: "weave unweave <target> mind"
  cure: "Eat goldenseal/plumbum herb"
  blocked_by: [impatience, stupidity, dizziness, epilepsy]

unweave_body:
  skill: Weaving
  balance: eq
  effect: "Apply unweaving body (auto-levels)"
  syntax: "weave unweave <target> body"
  cure: "Eat ferrum herb"
  blocked_by: [addiction, haemophilia, lethargy]

unweave_spirit:
  skill: Weaving
  balance: eq
  effect: "Apply unweaving spirit (auto-levels, setup for flurry)"
  syntax: "weave unweave <target> spirit"
  cure: "Smoke valerian (ONE level at a time)"
  blocked_by: [asthma]
  special: "Cures one level per smoke, not all at once"

deconstruct:
  skill: Weaving
  balance: eq
  effect: "Instant kill when 2 unweaves at level 3+"
  syntax: "weave deconstruct <target>"
  requirement: "Any TWO unweave types at level 3+ (readiness detected via the criticalmind/criticalbody/criticalspirit afflictions, >= 2 present)"

psi_transcend:
  skill: Psionics
  balance: eq
  effect: "Resource spend, chosen every balance"
  syntax: "psi transcend <blast|excise|muddle|shatter> <target>"
  types:
    excise: "Mana execute (<= 30% mana)"
    blast: "Apply mind ravaged (psi blast condition met, not yet ravaged)"
    muddle: "Apply muddled (when not already muddled)"
    shatter: "Fallback / flurry setup"
  note: "There is no bare TRANSCEND command. Shield is stripped separately via `weave cleave <target>`."

weave_cleave:
  skill: Weaving
  balance: eq
  effect: "Strip target's shield"
  syntax: "weave cleave <target>"
  note: "Prioritized when target is shielded"
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

## Bashing (PvE) — v4.7.128 overhaul
```yaml
attack_command: "weave deathblow <target>"
attack_skill: Weaving
panoply_boon: "weave flurry <target> replaces deathblow while psionPanoply (Mnemosyne, v4.7.126 — flurry damage scales 60-200% per strike landed)"
full_transcendence: "psi shatter <target> then weave (transcendence == 100)"

shielded: |
  rageraze + rage>=17: "weave pulverise <t>;<weave>" — pulverise breaks on RAGE (no
  balance), so the damage weave lands the SAME round. Otherwise: "weave cleave <t>"
  always (the pre-128 branch could build an EMPTY command without rageraze, or
  double-break with it).

battlerage: |
  Psion OWNS its battlerage (ataxiaBasher_psionBattlerage, 002) — triggers 330-332
  have no Psion fire-lines, so the old assembler branch (gated on
  battleRage_Timers.special) was Regrowth-only forever. Timer-free send-side epoch
  stamps (ataxiaTemp.psionBrAt) with wiki cooldowns. Priority:
    reap (culling, 36 rage) > psi devastate (36, 23s) > weave whirlwind (25, 23s)
    > weave barbedblade (14, 16s filler).
  Regrowth (anti-heal vines, 24 rage, 35s): OPT-IN via ataxiaBasher.psionRegrowth
  (lua-set flag, no alias yet) — priority when enabled; for self-healing denizen
  areas ("tending his wounds" mobs).
  v4.7.129 hardening (found by the Golden Dragon review of this same pattern):
  (1) a pick stays PENDING (ataxiaTemp.psionBrPending, ~3s) and replays verbatim
  across the basher's 0.3s addclearfull re-queue loop — stamping per rebuild burned
  the rotation phantom-style (only the last rebuild's pick ever fired); the rotation
  advances only after the hold expires. (2) psionBashing computes the battlerage
  LAZILY after the shielded early-return — the shielded branch sends no battlerage,
  so the eager call burned the pick's cooldown stamp unsent every shielded round.

eq_riders: |
  enact roth  — below 50% HP, 185s send stamp; rides eq beside the balance swing,
                fires even on shielded rounds (heal first). Grants clarity+rupture.
  psi transcend — re-upped when the GMCP psitranscend defence drops (10s hold);
                the shatter loop previously assumed it active with NO maintenance.

keepers: |
  weave secondskin — re-woven when the defence drops; BALANCE-based (3.0s) so it
  REPLACES that round's swing; skipped while shielded (break the shield first).
  Defence name map (v4.7.128) also recognizes indomitability + clarity now.
```

## PvE Ability Audit (2026-07-27, full wiki review: Psion/Weaving/Psionics/Emulation)

Four-page sweep, every ability categorized for denizen hunting. Wiki caveats: no skill
ranks or mana/willpower costs render on any page (only balance/eq times); `PSI SHATTER`
and the Panoply boon post-date the wiki entirely (shatter is presumably the newer
transcendence-100 spender). Weaving costs BALANCE (2.2–2.6s); Psionics/Emulation cost
EQUILIBRIUM — the two channels interleave, and at transcendence 100 one psionics action
fires off-eq at zero cost.

### In use by the basher today
| Ability | Why |
|---|---|
| `WEAVE DEATHBLOW` (2.20s bal) | Fastest single-target damage weave — the default bash |
| `WEAVE FLURRY` (2.60s bal) | The bash under the Panoply boon (60–200% per strike) |
| `WEAVE CLEAVE` (2.30s bal) | Strips shield AND rebounding, prones — the shield answer |
| `PSI TRANSCEND` / `PSI SHATTER` | Bashing weaves charge transcendence to 100 → free off-eq shatter |
| Battlerage raze | Shielded targets only |

### Should wire next (priority order)
| Ability | Cost | PvE case |
|---|---|---|
| `ENACT ROTH` | 1.30s eq, 3-min cd, needs HP<50% | Emergency heal + free clarity/rupture defs — belongs in the danger/heal ladder before any flee |
| `WEAVE SECONDSKIN` | 3.00s bal, defence | Resistance to ALL damage types — belongs in defence keepup |
| Battlerage rotation | rage | Barbedblade 14 (DoT opener) → Whirlwind 25 → Devastate 36 (nuke); **Pulverise 17 = rage-cost shieldbreak** (saves the cleave balance); Regrowth 24 vs self-healing denizens ("tending his wounds"!); skip Terror (fear scatters mobs) |
| `WEAVE RALLY` | 2.30s bal | Self-heal that OVERHEALS — costs a swing, so: pre-pull overheal + low-HP alternative to fleeing |
| `PSI EXPAND` | 3.00s eq | Mana top-up between pulls (big under Haemophiliac's +20% mana costs) |
| `PSI MANIPULATE` | 3.30s eq | Act THROUGH paralysis — synergy with the basher's attack-gate (paralysing denizens) |

### Test in game before wiring
| Ability | Question |
|---|---|
| `WEAVE MIRIAD` | Copies mirror every attack at 50% damage onto RANDOM room targets — free cleave in Mnemosyne swarm rooms IF they hit denizens without pulling extra aggro |
| `ENACT INDOMITABILITY` | Absorb-images (3 hits each), Self-targeted with no adventurers-only flag — if they block denizen swings, refresh between pulls |
| `PSI SPLINTER` (2.00s eq, denizen-legal) | Eq-based shieldbreak — as the transcendence-100 spender it could strip shields for FREE without touching weave balance |
| `ENACT GUIDEDSTRIKE` | Crit buff — but does NOT stack with a paragon artefact; redundant for us (armour system runs paragons) unless a profile drops them |
| `ENACT CLARITY` | Faster eq recovery — helps the eq-side utility cadence; Roth grants it free |
| `WEAVE PREPARE INSUBSTANTIAL` | Page hints at a rebounding/reflection-bypass mode — AB check needed |

### Utility (situational)
`PSI PROJECTION` (safe-room anchor: pre-place, swap back after a flee — 3 swaps),
`ENACT COMPANION` Aklan (remote room-content scouting — recon synergy with Bloodscent),
`ENACT BARTER` (gold → endurance on marathons), `ENACT WAVESURGE` (random-direction
panic teleport — last resort only), `PSI EXPUNGE` (self mental-cure, impatience first),
`PSI VANISH` (slip past aggro — unverified vs denizens).

### PvP-only (no PvE value — do not wire into the basher)
All affliction weaves (overhand, backhand, hamstring, entwine, lightsteal, puncture,
sever, exsanguinate, launch, prepare's affliction modes), the entire unweave kill route
(unweave, invert, deconstruct, sensitivity), the mana-kill chain (psi blast, excise,
contemplation), psi combustion/foresight/muddle/radiate/link/perception/insertion/
ironwill/breakthrough, and Emulation's destruction/imposition/painshift (all flagged
adventurers-only), lightbind, lifebond, soulmark, reprise, discordance, upheaval
(blocks our own escape routes), rupture (denizen bleed value marginal; Roth grants it
free anyway).

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
- Transcend = resource spent every balance (blast/excise/muddle/shatter); shield stripped via weave cleave
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


## PvE: the battlerage replay record stores the KEY (v4.7.193)

`ataxiaTemp.psionBrPending` must be `{ verb = ab.key, cmd = <full command> }`. The ready-line
feed (`basher/011`) releases a held pick by comparing `pend.verb` against the `BR_READY_MAP`
key (`barbedblade`, `whirlwind`, `devastate`, `regrowth`). Storing the command string
(`"weave barbedblade"`) there -- as this rotation did until v4.7.193 -- means the release never
matches and a stale pick is replayed for the rest of its 3s window after the game has already
said the ability is ready.
