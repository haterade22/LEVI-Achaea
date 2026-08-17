# Blademaster

## Divine Thunder Cataclysm (Mnemosyne boon) -- thunderstorm as a crowd rider
```yaml
# ataxiaBasher_bmThunderstorm, basher/002. Flag mnemDivineThunder (trigger mnemosyne/054).
boon:     "Your Shindo thunderstorm ability now deals electric damage to all denizens in
           your location."
ability:  "SHIN THUNDERSTORM -- AB 314, Works on/against: Room, 4.00s of EQUILIBRIUM,
           30 Shin energy. Already a room ability; the boon is what makes it hit DENIZENS."
rides:    "EQUILIBRIUM, so it is prefixed ALONGSIDE the balance swing and costs no attack.
           Contrast the Runewarden Thunderclap bisect (4s BALANCE), which REPLACES the
           swing. Same crowd-AoE idea, wired oppositely because the resource differs --
           check the resource type first for any new AoE."
gate:     "3+ denizens (ataxiaBasher.thunderstormAt), higher than the 2+ used for the
           balance-spending crowd swings, because the binding resource is SHIN not balance:
           30 per cast from a pool infuse and SHIN AUGMENT also draw on
           (ataxiaBasher.thunderstormReserve keeps a buffer)."
cooldown: "Stamped on send, RE-STAMPED from the confirmed strike line (trigger
           highlighting/036 -> ataxiaBasher_bmThunderstormConfirm)."
fire_lines: |
  cast:   "Wind swells about your form as you build a tremendous galvanic charge..."
  strike: "A clap of thunder presages the unleashed storm, forks of brilliant lightning..."
  Highlighted cast=dark_sea_green (intent), strike=chartreuse bold (damage landing).
  NEAR-MISS: the Thunderclap bisect line also says "a clap of thunder" -- that one is
  "...heralding your strike." anchored on "Lightning follows the path of". Non-overlapping.
caveat:   "Shares the equilibrium slot with the Bladed Reflexes SHIN AUGMENT; on a round
           where both fire the storm queues behind it and can be wiped, self-healing inside
           the 4s window."
not_modelled: "'jangle the nerves' is presumably epilepsy on the denizens -- BR_AFFS has no
           epilepsy entry and the apply line is uncaptured."
```

## Metadata
- **Type**: Base Class
- **Combat Style**: Limb | Bleed | Affliction
- **Difficulty**: Hard
- **Lock Affliction**: Weariness (blocks Fitness passive cure)

## Skills
```
TwoArts: Stance-based combat with paired blades
Striking: Precise strikes with affliction delivery (pommelstrike)
Shindo: The Way - mental discipline, Shin resource, and special abilities
```

## Stances
```yaml
# Stances ordered by acquisition in TwoArts
doya:
  speed: "Slow"
  damage: "Highest (10% more than Arash)"
  accuracy: "Best"
  limb_damage: "Increased"
  defense: "Normal"
  notes: "Slow but accurate with high limb damage"

thyr:
  speed: "Fastest"
  damage: "Lowest"
  accuracy: "High"
  limb_damage: "Reduced"
  defense: "Normal"
  priority: "Primary 1v1 stance - speed and precision"

mir:
  speed: "Slowest"
  damage: "Just under unstanced"
  accuracy: "Normal"
  limb_damage: "Normal"
  defense: "Greatly increased"
  priority: "Defensive stance when targeted in groups"

arash:
  speed: "Medium (slower than Thyr, faster than Sanya)"
  damage: "Tremendous (+second highest)"
  accuracy: "Lowest"
  limb_damage: "Highest per hit"
  defense: "20% MORE damage taken"
  priority: "Burst damage when safe, group combat opener"
  warning: "Only use when you can survive shortly after"

sanya:
  speed: "Medium"
  damage: "Normal"
  accuracy: "Normal"
  limb_damage: "Normal"
  defense: "Normal"
  shin_gain: "12 per strike (vs normal 8)"
  priority: "Well-rounded, increased Shin generation"

# Priority Order
1v1_priority: [thyr, sanya, mir, arash, doya]
group_priority: [arash, thyr, mir, sanya, doya]
```

## Core Combat Mechanics
```yaml
primary_kill: "BrokenStar"
brokenstar_requirement: "700+ bleeding on target"

impaleslash:
  description: "Critical ability - makes clotting use more mana"
  importance: "Must stick this before any bleed strategy works"
  how_to_stick:
    - "Paralysis/prone/web removes dex-based dodging -> impale guaranteed"
    - "Pommelstrike/strike knees after they hit you, impale before they stand"
    - "Paralysis stacking (3x with lvl3 band, 4x with lvl0 band) beats herb balance"
    - "After they shield: raze/strike knees, get balance before them, impale"

shin_resource:
  generation: "8 per strike normally, 12 in Sanya stance"
  usage: "Powers special Shindo abilities"

parry_bypass:
  ability: "Airfist"
  effect: "100% parry bypass against all forms of parrying"
  usage: "Critical for breaking legs against smart opponents"
  cost: "20 shin (+ 5 for infuse = 25 total)"
  cooldown: "NONE - only shin requirement"
```

## Kill Routes

### Primary Kill: BrokenStar (Bleed Kill)
```yaml
type: bleed
summary: Stack 700+ bleeding via impale/bladetwist, then BrokenStar

prerequisites:
  - Must stick Impaleslash first (makes clotting cost more mana)
  - Target needs 700+ bleeding minimum

basic_method_two_legs:
  description: "Easiest method, less effective vs experienced fighters"
  steps:
    1: "Prep both legs with legslash (alternate left/right)"
    2: "Legslash/strike knees to break BOTH legs simultaneously"
    3: "IMPALE (they can't dodge while prone)"
    4: "BLADETWIST x4 (time permits before writhe)"
    5: "They writhe - you get balance for BROKENSTAR before they stand"
  bleeding: "~700-800 from 4 twists"
  notes: "Breaking limbs simultaneously is CRITICAL vs experienced players"

two_legs_torso:
  description: "Burst bleeding method"
  steps:
    1: "Prep both legs for break"
    2: "Prep torso with centreslash or compassslash"
    3: "Break TORSO first"
    4: "Break LEGS immediately after (prone)"
    5: "IMPALE + IMPALESLASH on balance"
    6: "BLADETWIST x2"
    7: "They writhe - re-impale or BROKENSTAR based on bleeding"
  notes: |
    Broken torso increases bladetwist bleeding.
    This burst usually outstrips clotting.

head_torso_two_legs:
  description: "Salve balance manipulation (BMBS dispatch)"
  command: "bmbs / bmdispatchbs"
  phases:
    1_upper_prep: "Centreslash up/down to get torso+head to 90%+"
    2_leg_prep: "Legslash alternating to get both legs to 90%+"
    3_upper_break: "Centreslash up/down to break torso+head (100%+)"
    4_leg_break: "Legslash + KNEES to break legs and prone"
    5_impale: "Impale the prone target"
    6_impaleslash: "Slash arteries for bleeding"
    7_bladetwist: "Twist until 700+ bleeding (discern on 3rd)"
    8_withdraw: "Withdraw blade (or skip if writhed free)"
    9_brokenstar: "Execute instant kill"

  centreslash_direction:
    up: "Torso = primary (18.1%), Head = secondary (12.1%)"
    down: "Head = primary (18.1%), Torso = secondary (12.1%)"
    auto_selection: "System hits LOWER limb as primary (like getFocusLeg for legs)"
    reason: "Balances damage so both prep/break at same time"

  advantage: |
    - Broken torso increases bladetwist bleeding
    - Forces enemy to choose between healing head or torso
    - Ensures no salve balance to heal torso before leg break

  notes: |
    - Centreslash applies strikes (hamstring/paralysis during prep, clumsiness during break)
    - If target writhes free but is still prone: FREE RE-IMPALE
    - If target writhes free and stands with 700+ bleed: BROKENSTAR immediately

six_limb:
  description: "Hardest to execute, provides lock option"
  steps:
    1: "Prep both legs, head, torso, both arms"
    2: "Break HEAD + TORSO"
    3: "Break ARMS"
    4: "Break LEGS"
    5: "With broken arms, can go for LOCK or BROKENSTAR"
  timing_options:
    - "Fast: Break legs immediately after arms (they apply to legs after head)"
    - "Slow: Force them to apply to arms first, get extra bladetwist time"
  notes: "Enemies have many escape options - use arm breaks as decoys"
```

### Alternative Kill: Damage (Arash Burst)
```yaml
type: damage
summary: Use Arash stance for tremendous damage output

steps:
  1: "Prep both legs for break (any stance)"
  2: "LEAVE ROOM - switch to ARASH stance"
  3: "Return - enemy doesn't know you switched"
  4: "FLAMEFIST (negates rebounding, allows attack strings)"
  5: "Break legs"
  6: "Continue LEGSLASH RIGHT (curing is left>right)"
  7: "Mangle RIGHT leg (requires 2 restoration to cure)"
  8: "Keep them prone longer, deal massive damage"

ice_infuse:
  afflictions: [shivering, frozen, disrupt]
  benefits:
    - "Changes damage type to ice (less mitigated)"
    - "Bonus damage on frozen target"
    - "Throws off salve timing (they may apply caloric)"

fire_infuse:
  affliction: ablaze
  effect: "Small damage increase on each hit after ablaze"
  notes: "Inferior to ice"

engage:
  usage: "After multislash - if they survive and try to run, engage hits them"
```

### Alternative Kill: Affliction Lock
```yaml
type: affliction
summary: Use limb breaks to create affliction stacking window

method_arms_legs:
  steps:
    1: "Prep both legs"
    2: "Prep both arms"
    3: "Break LEGS first"
    4: "Break ARMS so they cure legs and stand before applying to arms"
    5: "9-10 SECONDS of unhindered affliction time"
    6: "Stack with POMMELSTRIKE (fastest affliction method)"

affliction_targets:
  chest: impatience
  shoulder: weariness
  stomach: anorexia
  underarm: slickness
  throat: asthma
  neck: paralysis
  knees: prone
  feet: prone

lock_strategy: |
  Hypochondria is the ONLY way Blademaster gives impatience.
  Must stick hypochondria FIRST to seal the lock.
  Break arms with Addiction affliction to eat away precaching.

paralysis_stacking:
  description: "Beat herb balance with repeated pommelstrikes"
  lvl0_band: "Every 4th pommelstrike beats herb balance"
  lvl3_band: "Every 3rd pommelstrike beats herb balance"
  example: "neck, neck, neck, throat -> asthma follows paralysis cure"
```

### Retardation/Aeon Strategy
```yaml
type: special
summary: Exploit slowed curing in ret/aeon

steps:
  1: "PRONE or PARALYZE target"
  2: "IMPALE"
  3: "SHEATHE BLADE (critical! attacks don't work without sheathed blade)"
  4: "BLADETWIST until ~700 bleeding (usually only 3 twists needed)"
  5: "BROKENSTAR"

notes: |
  Ret/aeon removes ability to clot effectively.
  Sheathing blade after impale is PARAMOUNT - takes balance.
  Use Striking abilities to keep paralysis and push hypochondria lock.

thunderstorm:
  skill: Shindo
  effect: "Gives hamstring to everyone in room"
  usage: "Prevents leaping out of retardation"
```

## Offensive Abilities
```yaml
# TwoArts - Slashes
legslash:
  skill: TwoArts
  balance: bal
  effect: "Slash targeting leg"
  syntax: "LEGSLASH <target> LEFT/RIGHT"
  notes: "Alternate sides to prep, break both simultaneously"

centreslash:
  skill: TwoArts
  balance: bal
  effect: "Slash targeting torso"
  syntax: "CENTRESLASH <target>"

compassslash:
  skill: TwoArts
  balance: bal
  effect: "Alternative torso slash"
  syntax: "COMPASSSLASH <target>"

multislash:
  skill: TwoArts
  balance: bal
  effect: "Multiple rapid slashes"
  syntax: "MULTISLASH <target>"

# TwoArts - Impale
impale:
  skill: TwoArts
  balance: bal
  effect: "Impale target (prevents writhe for a balance)"
  syntax: "IMPALE <target>"
  notes: "Guaranteed balance of action before they writhe"

impaleslash:
  skill: TwoArts
  balance: bal
  effect: "Slash while impaled, makes clotting cost more mana"
  syntax: "IMPALESLASH <target>"
  notes: "CRITICAL - must stick this for bleed strategies"

bladetwist:
  skill: TwoArts
  balance: bal
  effect: "Twist impaled blade, causes heavy bleeding"
  syntax: "BLADETWIST <target>"
  notes: "~175-200 bleeding per twist, more with broken torso"

brokenstar:
  skill: TwoArts
  balance: bal
  effect: "Instant kill at 700+ bleeding"
  syntax: "BROKENSTAR <target>"
  requirement: "700+ bleeding minimum"

# TwoArts - Infuse
flamefist:
  skill: TwoArts
  balance: bal
  effect: "Negates rebounding, allows attack strings"
  syntax: "FLAMEFIST <target>"

# Striking
pommelstrike:
  skill: Striking
  balance: bal
  effect: "Fast affliction delivery"
  syntax: "POMMELSTRIKE <target> <location>"
  locations:
    chest: impatience
    shoulder: weariness
    stomach: anorexia
    underarm: slickness
    throat: asthma
    neck: paralysis
    knees: prone
    feet: prone

airfist:
  skill: Striking
  balance: bal
  effect: "100% parry bypass"
  syntax: "AIRFIST <target>"
  cost: "20 shin (+ 5 for infuse = 25 total)"
  cooldown: "NONE"
  notes: "Critical for breaking limbs vs smart opponents. No cooldown, only shin requirement!"

# Shindo
thunderstorm:
  skill: Shindo
  balance: eq
  effect: "Hamstring to everyone in room"
  syntax: "THUNDERSTORM"
  notes: "Prevents leaping out of retardation"
```

## Defensive Abilities
```yaml
fitness:
  skill: Striking
  effect: "Passively cures asthma"
  cures: [asthma]
  blocked_by: [weariness]

mir_stance:
  skill: TwoArts
  effect: "Greatly increased defense"
  notes: "Switch to this when targeted in groups"

dodge:
  skill: TwoArts
  effect: "Dexterity-based dodging"
  removed_by: [paralysis, prone, web]
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
primary_targets: [left_leg, right_leg, torso]
break_requirements:
  legs: "Prep both, break simultaneously"
  torso: "Break for increased bladetwist bleeding"
  arms: "Break for affliction window or extra twist time"

leg_curing_order: "LEFT leg cured before RIGHT"
strategy: |
  Prep both legs by alternating legslash left/right.
  Must break BOTH legs at once vs experienced players.
  Use Airfist for 100% parry bypass.
  Continuing to legslash RIGHT after break mangles it (2 restos to cure).
```

## Bashing (PvE)
```yaml
attack_command: "SLASH <target>" or stance-appropriate attacks
attack_skill: TwoArts
# Basher melee (ataxiaBasher_blademasterBashing, basher/002): "infuse fire ; drawslash <t> sternum"
# (razes first on a shielded mob). Mnemosyne "White Heaven's Shattered Star" boon buffs multislash
# (+3 strikes = 6 total); while bmShatteredStar is set the basher swaps the verb to
# "multislash <t> sternum". Flag set on boon claim / the BOONS-list row (trigger mnemosyne/012),
# cleared on Mnemosyne run start + confirmed run-end -- mirrors the Bard Warmarch boon (bardWarmarch).
# Shindo AUGMENT (AB verified 2026-07-24): "SHIN AUGMENT <ALL|amount>", resource Shin energy --
# channels shin into augmented reflexes (deflect limb blows even when prone; conjunction with
# parry). Lines: start "You focus inward, drawing upon your reserves of shin energy.", busy
# "You are already beginning the process of augmenting your body with shin energy.", complete
# "You channel your accumulated shin energy into enhancing your defensive bladework." Tracked
# as the `bodyaugment` defence (deffing keep-map, with the other Shindo defs blur/disperse/
# durability). Mnemosyne "Bladed Reflexes" boon = 20% reduced damage while augmented: with
# bmBladedReflexes set (claim alias / BOONS row trigger mnemosyne/019, reset each run) the
# basher prepends "shin augment <n>" (n = ataxiaBasher.bmAugmentAmount, default 20 since
# v4.7.269) whenever shin >= n, bodyaugment is down, the 7s attempt-hold
# (ataxiaTemp.bmAugmentAttempted) has cleared and the cooldown is over.
#
# ALL FIVE LINES OF THE CYCLE (captured 2026-08-12, triggers highlighting/050-054):
#   "You focus inward, drawing upon your reserves of shin energy."                  channel begins
#   "You are already beginning the process of augmenting your body with shin energy." REFUSED, busy
#   "You channel your accumulated shin energy into enhancing your defensive bladework." cover STARTS
#   "The shin energy enhancing your body dissipates."                                cover ENDS
#   "You may augment yourself with shin energy once again."                          cooldown OVER
# A sixth line exists and is NOT wired: "Regardless of your skill, augmenting yourself with shin
# energy so soon would be fatal." -- the COOLDOWN refusal, distinct from the busy one above.
#
# USER-STATED MECHANICS (2026-08-12): duration SCALES with the spend, ~10s to ~1.5min, and is
# explicitly NOT one shin per second; 4 seconds to activate in all cases; on ending it goes on
# cooldown EQUAL TO THE DURATION it was up for. Therefore uptime can never exceed 50%, and the 4s
# activation is a fixed tax a short augment pays proportionally more of.
#
# FOUR MEASUREMENTS, AND THEY DO NOT ALL AGREE -- which is why `bash shinprobe` exists:
#   2026-07-26 (Pinnacle, ~3k HP/s incoming): 1-shin augment DISSIPATED ~12ms later, twice;
#              3-shin augment lasted ~2.0s; re-up refused, recovery line ~6s later.
#   2026-08-12 (adjacent prompt timestamps): dissipate 10:25:09.886 -> ready 10:25:12.886 =
#              cooldown 3.0s EXACTLY; focus 10:25:15.257 -> cover 10:25:18.916 = activation 3.66s,
#              which corroborates the stated 4s.
# The activation is settled. The duration is not: a 3-shin augment lasting 2.0s cannot be squared
# with a floor of ~10s. The ABLATIVE hypothesis remains the only reading that fits both -- augment
# absorbs a POOL proportional to the shin spent and ends early when the pool is consumed, so ~10s
# is its unspent lifetime and 12ms is what 1 shin buys under boss-tier fire. It is now TESTABLE
# rather than idle: the probe brackets each duration between the cover-starts and dissipates lines,
# so a WIDE spread at one spend is evidence for ablative and a tight cluster is evidence against.
# Cooldown-equals-duration is also unconfirmed (2.0s up vs ~6s down contradicts it; 3.0s down is
# consistent with a 3s duration) -- which is exactly why the ready LINE is now the authority and
# the derived wait is only a backstop for a missed line.
# Battlerage kit (commands/costs verified vs basher/001 ataxiaBasher_blademasterBattlerage
# and _groups.yaml get_Battlerage Blademaster config). Blademaster OWNS its battlerage:
# it is EXCLUDED from the shared culling check and spends rage by priority so it never idles.
battlerage_abilities:
  - leapstrike:  { command: "LEAPSTRIKE <t>",   rage: 14, cooldown: "16s", role: "cheap damage filler / execute (yaml small)" }
  - shatter:     { command: "SHIN SHATTER <t>",  rage: 17, cooldown: "~global", role: "shield breaker (yaml raze)" }
  - nerveslash:  { command: "NSL <t>",           rage: 22, cooldown: "31s", role: "afflicts Weakness (yaml specialafflict)" }
  - headstrike:  { command: "STRIKE <t> HEAD",   rage: 25, cooldown: "23s", role: "CONDITIONAL bonus damage vs reckless/feared (yaml specialuse)" }
  - daze:        { command: "SHIN DAZE <t>",     rage: 26, cooldown: "33s", role: "afflicts Stun - key mitigation (yaml special)" }
  - spinslash:   { command: "SPINSLASH <t>",     rage: 36, cooldown: "23s", role: "big single-target dump (yaml large)" }
  - reap:        { command: "REAP <t>",          rage: 36, role: "Culling Blade AoE finisher (owned by this rotation, not the shared check)" }
  - provoke:     { command: "PROVOKE <t>",       rage: 32, cooldown: "20s", role: "level-100 taunt (inverse of charm); NOT wired into the basher rotation" }
priority: |
  In Mnemosyne (no-flee): Culling -> Daze/Stun -> Headstrike/Spinslash -> Nerveslash/Weakness -> Leapstrike.
  Outside Mnemosyne: damage-forward, spending surplus rage down the list so it never idles.
  Respects the global ~1s battlerage cooldown (ataxiaTemp.brGlobalReadyAt).
see_also: |
  PvE battlerage usage and the denizen-affliction rotation are documented in
  .claude/projects/basher/battlerage-pve.md and .claude/projects/basher/denizen-lines-catalog.md.
```

## Fighting Against This Class
```yaml
priority_cures:
  - weariness: "Restores your Fitness"
  - broken_legs: "Prevent impale setup"
  - broken_torso: "Reduces bladetwist bleeding"
  - bleeding: "CLOT to stay below 700"
  - hypochondria: "Only way they give impatience"
  - paralysis: "Enables their impale"

dangerous_abilities:
  - brokenstar: "Instant kill at 700+ bleeding"
  - impaleslash: "Makes clotting expensive"
  - bladetwist: "~175-200 bleeding per twist"
  - airfist: "100% parry bypass"
  - simultaneous_breaks: "Both legs at once"
  - arash_stance: "Massive damage burst"

avoid:
  - "Reaching 700+ bleeding"
  - "Being prone without clotting"
  - "Static parrying (they use Airfist)"
  - "Letting both legs get prepped"
  - "Fighting in Arash without pressure"
  - "Staying in retardation"

clotting_strategy: |
  Clot aggressively - MUST stay below 700 bleeding.
  Impaleslash makes clotting cost more mana - watch mana.
  After they impaleslash, clotting is less effective.

parry_strategy: |
  Parry legs to slow prep.
  They WILL use Airfist for 100% bypass.
  Track which legs are prepped.

recommended_strategy: |
  Clot aggressively - 700 bleeding = death.
  Don't let both legs get prepped simultaneously.
  Apply weariness to block their Fitness.
  Watch for stance switches (Arash = incoming burst).
  If impaled, they get guaranteed balance - prepare to clot.
  In ret/aeon, they only need ~3 twists - escape immediately.
  Broken torso increases twist bleeding - prioritize resto.
```

## Implementation Notes
```
Triggers to watch for:
- "legslashes your *" - leg being prepped
- "Your * is damaged/broken/mangled" - track limb state
- "impales you" - incoming impaleslash/twist
- "twists the blade" - heavy bleeding incoming
- "stance shifts to *" - stance change (Arash = danger)
- "BrokenStar" - instant kill attempt
- "Airfist" - parry being bypassed
- "Flamefist" - rebounding negated
- Bleeding amount messages

GMCP considerations:
- Track gmcp.Char.Vitals for limb percentages
- CRITICAL: Track bleeding amount (700 = death)
- Parse stance change messages

Edge cases:
- Airfist gives 100% parry bypass
- Both legs must break simultaneously vs good players
- Leg curing order is LEFT then RIGHT
- Mangled right leg needs 2 restoration applies
- Impaleslash makes clotting cost more mana
- Broken torso increases bladetwist bleeding
- In ret/aeon, only ~3 twists needed (can't clot effectively)
- Sheathing blade after impale takes balance (in ret)
- Thunderstorm prevents leaping out of ret
- Arash stance = 20% more damage TAKEN by them

Stance Damage Order (highest to lowest):
Doya > Arash > Sanya > Mir > Thyr

Stance Speed Order (fastest to slowest):
Thyr > Arash > Sanya > Mir > Doya

Band Levels affect paralysis stacking:
- lvl3 band: Every 3rd pommelstrike beats herb balance
- lvl0 band: Every 4th pommelstrike beats herb balance
```

---

## Ice Dispatch System (005_CC_BM_Ice.lua)

### Overview
A double-prep dispatch system focused on breaking BOTH legs simultaneously, then switching to ice damage phase for the kill.

### Kill Route
```
Lightning prep → double-break both legs → Ice damage (mangle) phase
```

### Key Mechanics
1. **DOUBLE-PREP** - Alternate legs to keep both roughly equal until 90%+
2. **INFUSE LIGHTNING** - During prep phase (lightning gives clumsiness automatically)
3. **AIRFIST** - When target parries our leg (requires 25 shin: 20 + 5 for infuse, NO cooldown)
4. **HAMSTRING** - Always keep up to prevent fleeing (10 second duration, timestamp-tracked)
5. **KNEES** - When ANY leg is about to break (will hit 100% on next hit), prone on same hit as break
6. **PARRY BYPASS** - AIRFIST is the only parry bypass (needs 25 shin); no centreslash-up fallback exists
7. **INFUSE ICE + STERNUM** - After ANY leg broken, switch to ice for damage
8. **MANGLE STRATEGY** - While PRONE, legslash RIGHT leg to 200% (mangle), then LEFT (curing applies left first)
9. **COMPASSSLASH** - Used to balance legs ONLY during prep (no broken legs)
10. **MOUNT-AWARE DISMOUNT** - When target is mounted + hamstrung + final prep hit, use KNEES to dismount BEFORE double-break

**Key Insights**:
- Breaking BOTH legs simultaneously is critical vs experienced players
- After double-break, stay in ICE phase even if one leg heals
- MANGLE (level 3 break) requires 2 restoration applications to heal = huge advantage
- Mangle order is fixed RIGHT-first to 200%, then LEFT (curing applies to left leg first)
- **MOUNTED TARGETS**: KNEES on mounted target DISMOUNTS but doesn't PRONE. Must dismount first, then double-break for prone.

### Commands
```yaml
# Strategy 1: Double-Prep (Legs Only)
bmd: Main dispatch attack - legs only (blademaster.dispatch.runDoublePrep())
bmstatus: Display status panel (blademaster.dispatch.statusDoublePrep())

# Strategy 2: Quad-Prep (Arms + Legs)
bmdq: Quad-prep dispatch - arms + legs (blademaster.dispatch.runQuadPrep())
bmstatusq: Display quad-prep status (blademaster.dispatch.statusQuadPrep())

# Strategy 3: Brokenstar (Upper + Legs + Kill)
bmbs: Brokenstar dispatch - upper + legs + impale route (blademaster.dispatch.runBrokenstar())

# Strategy 4: Group (Pommelstrike Lock)
bmgroup: Pommelstrike affliction-lock dispatch (blademaster.dispatch.runGroup())

# Reset
bmreset: Full state reset - mode->double, flamefist, prone timer, brokenstar state (blademaster.fullReset())
```

Each mode also exposes an equivalent global-function wrapper alias: `bmdispatch` (double),
`bmdispatchquad` (quad), `bmdispatchbs` (brokenstar) - thin wrappers that set the mode and call
`blademaster.run()`, same as `bmd`/`bmdq`/`bmbs`.

### Strategy 2: Quad-Prep (Arms + Legs) phase notes
6-phase `getPhaseQuadPrep()`: arm_prep -> leg_prep -> flamefist -> arm_break -> leg_break -> mangle.
- **FLAMEFIST gate**: arm_break is only entered after FLAMEFIST has been sent (`state.flamefistDone`).
  When all 4 limbs are prepped and flamefist is not yet done, the phase is `flamefist` (send flamefist,
  raze if shielded) before any break.
- **Always RIGHT**: both `leg_break` and `mangle` always `legslash right` - curing applies to the left
  leg first, so the right stays broken longer. Mangle also adds STERNUM.
- Like double-prep, `mangle` is entered on PRONE alone.

### Strategy 4: Group (Pommelstrike Lock)
Affliction-lock mode driven entirely by POMMELSTRIKE + `infuse ice`. `selectStrikeGroup()` picks the
strike by fixed priority (fill the first missing lock aff):
1. hamstring
2. paralysis (neck)
3. asthma (throat)
4. slickness (underarm)
5. anorexia (stomach) - only if impatience AND slickness already present
6. class locking affliction via `getLockingAffliction()` mapped through `blademaster.lockAffToStrike`
   (paralyse->neck, weariness->shoulder, plague->eyes, stupid->temple, reckless->groin)
7. hypochondria (chest)
8. sternum (all lock affs present - pump damage / maintain lock)

### Shared Dispatch Plumbing (all modes)
`blademaster.run()` is the single entry point; every mode passes through the same guards before
delegating to its `run*` function:
- **attackInFlight gate**: re-dispatch blocked until the previous attack resolves. The flag is set in
  `sendAttack()` and cleared by a `gmcp.Char.Vitals` handler when balance returns (`bal == 1`).
- **Aeon gate**: returns early while `ataxia.afflictions.aeon` is set.
- **Rebound hold**: `reboundHold.gate(blademaster.run)` delays the attack until rebounding drops.
- **Target-change reset**: on a new `target`, clears `flamefistDone`, brokenstar state, and prone timer.
- **Lock-break shortcut**: `sendAttack()` defers to `ataxia_lockBreak()` when `ataxia_needLockBreak()` is true.
- **Echo debounce**: `shouldEcho()` throttles status echoes to once per 0.3s during rapid mashing.

### Combat Phases

#### Phase 1: Lightning Prep
```
- INFUSE LIGHTNING (gives clumsiness automatically!)
- LEGSLASH alternating (always hit LOWER damage leg)
- COMPASSSLASH if gap between legs is too big
- Strike: HAMSTRING > NECK (para) > CHEST (hypo) > SHOULDER (weary) > EARS (clumsy fallback)
- Goal: Get both legs to 90%+
```

#### Phase 2: Double-Break
```
- Both legs at 90%+
- LEGSLASH + KNEES = break BOTH legs + prone in one hit
- Transition to Ice phase
```

#### Phase 3: Ice Damage / Mangle
```
- Mangle phase is entered on PRONE alone (getPhaseDoublePrep returns "mangle" whenever prone,
  no leg-broken condition)
- INFUSE ICE only while PRONE (switch to lightning when they stand)
- While PRONE: LEGSLASH RIGHT leg to 200% (mangle), then LEGSLASH LEFT + STERNUM
- Goal: MANGLE (level 3 break) = 2 restoration applications to heal
- If they STAND UP: Switch to LIGHTNING, continue hitting broken leg
- Target is frozen + leg broken = massive damage
```
(Note: `killHealthThreshold = 30` is defined in config but never read - there is no low-HP
MULTISLASH burst branch in the dispatch.)

**Mangle Strategy**: While PRONE:
- Stay in ICE phase; legslash RIGHT leg until 200% (mangle), then legslash LEFT + STERNUM
- Fixed right-first order because curing applies to the left leg first, so the right stays broken longer
- If they STAND UP: Switch to LIGHTNING, continue hitting broken leg

### Strike Priority (All Phases)
| Priority | Strike | Affliction | Condition |
|----------|--------|------------|-----------|
| 1 | AIRFIST | Parry bypass | When parrying our leg (needs 25 shin, NO cooldown) |
| 2 | STERNUM | Max damage | PRONE (they're locked down, use ice infuse) |
| 3 | KNEES | Dismount | Mounted + hamstrung + final prep hit (dismount before double-break) |
| 4 | KNEES | Prone | Double-break imminent (both legs will break) |
| 5 | KNEES | Prone | Single leg about to break |
| 6 | HAMSTRING | Prevents flee | Always keep up (10s duration, timestamp-tracked) |
| 7 | NECK | Paralysis | Lightning gives clumsy, so strike para |
| 8 | CHEST | Hypochondria | Blocks focus curing |
| 9 | SHOULDER | Weariness | Blocks Fitness passive cure |
| 10 | EARS | Clumsiness | Fallback |

### Sword Attack Selection
| Condition | Attack | Direction |
|-----------|--------|-----------|
| Shield/Rebounding | RAZE | - |
| Mangle (PRONE), right leg < 200% | LEGSLASH | RIGHT (mangle to 200%) |
| Mangle (PRONE), right leg >= 200% | LEGSLASH | LEFT |
| Normal prep | LEGSLASH | Lower leg (getFocusLeg) |

**NOTE**: BALANCESLASH is never used - always LEGSLASH in ice phase for mangle.
**NOTE**: In the mangle (prone) phase the dispatch hits the RIGHT leg to 200% then the LEFT - a fixed
right-first order (curing applies left first). `selectAttackDoublePrep()` only ever returns airfist or
legslash; there is no centreslash-up parry-bypass fallback in the double-prep path.

### Shin Mechanics
- **Generation**: 8 per strike normally, 12 in Sanya stance
- **Infuse cost**: 5 shin -- **UNVERIFIED.** This figure appears only here, with no AB capture
  behind it; the sole code enforcing the arithmetic is the PvP airfist gate (`25 = 20 + 5`) as an
  opaque total, and no AB text for INFUSE exists anywhere in the tree. The PvE shin budget
  (v4.7.269) deliberately does NOT compute its threshold from this number.
- **Augment** (user-confirmed 2026-08-12, none of it in AB 316): duration **SCALES** with the shin
  spent, ~10s to ~1.5min, and is **NOT** 1 shin per second -- the curve is UNKNOWN and `bash
  shinprobe` measures it. Takes **4 seconds to activate** in all cases, and on ending goes on
  **cooldown equal to the duration it was up for** -- so uptime can never exceed 50%. `bmAugmentAmount`
  defaults to 20 as a provisional middle. Lines captured: `You focus inward, drawing upon your
  reserves of shin energy.` (accepted), `You are already beginning the process of augmenting your
  body with shin energy.` (refused -- already channelling; seen 5x in 0.45s because `shin augment`
  costs no balance and so executes on every re-queue), `You channel your accumulated shin energy
  into enhancing your defensive bladework.` (cover starts), `The shin energy enhancing your body
  dissipates.` (cover ends), `You may augment yourself with shin energy once again.` (**cooldown
  over** -- so v4.7.271 stopped predicting the cooldown and waits for this instead; the derived
  wait survives only as a backstop for a missed line). Still uncaptured: the COOLDOWN refusal
  ("...so soon would be fatal"), which is a different line from the already-channelling one.
  **Measured, and not yet consistent** -- cooldown 3.0s on 2026-08-12 vs ~6s on 2026-07-26, and a
  3-shin augment lasting ~2.0s cannot be squared with a ~10s floor; see the augment block above for
  the ablative hypothesis the probe can now test.
- **SHIN PHOENIX** (AB 321): requires 80 shin, **consumes ALL of it**, cleanses almost every
  affliction **and restores full health** (the heal is user-confirmed and NOT in the AB text). The
  strongest button in the kit, and what the PvE infuse budget exists to protect. Auto-fires at
  `ataxiaBasher.phoenixAt` (10% HP) with 80+ shin. Our own cast line is uncaptured -- the only
  phoenix trigger in the tree is the opponent-side line.
- **Airfist cost**: 20 shin
- **Total for Airfist**: 25 shin (20 + 5 for infuse)
- **Airfist cooldown**: NONE (only shin requirement)

### Damage Tracking
The system dynamically captures damage values from combat:
- **Primary damage**: ~17.3% to focused leg
- **Secondary damage**: ~11.5% to off-leg
- **Compassslash damage**: ~14.9% to single leg

These values update automatically from combat triggers.

### Limb Tracking
Uses `lb[target].hits["limb"]` format to match the rest of the BM offense system.
**NOT tLimbs** - use Romaen's limb counter format:
- `lb[target].hits["left leg"]` - Left leg damage %
- `lb[target].hits["right leg"]` - Right leg damage %

Helper functions:
- `blademaster.getLimbDamage(limb)` - Get damage % for any limb
- `blademaster.getLL()` - Shorthand for left leg
- `blademaster.getRL()` - Shorthand for right leg
- `blademaster.getLA()` - Shorthand for left arm
- `blademaster.getRA()` - Shorthand for right arm
- `blademaster.getTorso()` - Shorthand for torso
- `blademaster.getHead()` - Shorthand for head

Affliction tracking helpers (V3-only):
- `blademaster.hasAff(aff)` - Check if target has affliction (calls global `haveAff(aff)`)
- `blademaster.getAffProb(aff)` - Get affliction probability 0.0-1.0 (via `getAffProbabilityV3`, else 0)
- `blademaster.getTrackingSystem()` - Always returns "V3"

Leg check functions:
- `blademaster.checkBothLegsPrepped()` - Both legs effectively prepped (90%+, or would break on next hit)
- `blademaster.checkBothLegsBroken()` - Both legs at 100%+
- `blademaster.checkAnyLegBroken()` - At least one leg at 100%+
- `blademaster.checkWillDoubleBreakLegs()` - BOTH legs will break on next hit (causes prone)
- `blademaster.checkWillPrepBothLegs()` - BOTH legs will reach 90%+ on next hit
- `blademaster.getFocusLeg()` - Returns "left" or "right" based on which leg is lower

Upper body check functions (Brokenstar):
- `blademaster.checkUpperPrepped()` - Both torso AND head at 90%+
- `blademaster.checkUpperBroken()` - Both torso AND head at 100%+
- `blademaster.checkWillPrepUpper()` - BOTH torso and head will reach 90%+ on next centreslash
- `blademaster.checkWillBreakUpper()` - BOTH torso and head will break on next centreslash
- `blademaster.getCentreslashDirection()` - Returns "up" or "down" based on which limb is lower

### Status Display
```
+============================================+
|     BLADEMASTER DOUBLE-PREP DISPATCH      |
+============================================+
| Target: <name> (HP: X%) | Track: V3
| Phase: LIGHTNING (prep) / ICE (damage)
| Focus Leg: left/right (alternating to keep even)
| Parried: <limb>
| Damage: P=17.3% S=11.5% C=14.9%
+--------------------------------------------+
| DOUBLE-PREP STATUS:
|   L Leg: XX.X% [##########]
|   R Leg: XX.X% [##########] <-
|   Double-Break: YES/NO (need both 90%+)
|   Path: X hits to double-break (sequence: LRLR)
+--------------------------------------------+
| AFFLICTIONS:
|   Hamstring:  YES/NO/EXPIRING
|   Clumsiness: YES/NO
|   Paralysis:  YES/NO
|   Prone:      YES/NO
|   Frozen:     YES (ICE BONUS!)
|   Shin:       XX (25 needed for airfist+infuse)
+--------------------------------------------+
| KILL CONDITIONS:
|   Both Legs Broken: YES/NO
|   Target Low HP: YES/NO (< 30%)
+============================================+
```

### Hamstring Tracking
The dispatch uses timestamp-based tracking to prevent hamstring reapplication:
- `blademaster.state.lastHamstringTime` - Timestamp of last hamstring application
- `blademaster.onHamstringApplied()` - Callback from hamstring trigger (002_Hamstring.lua)
- `blademaster.config.hamstringDuration` - 10 seconds

The hamstring trigger (002_Hamstring.lua) calls `blademaster.onHamstringApplied()` to update the timestamp.

---

## Changelog

### 2026-01-29 - V3 Affliction Tracker Integration

**Files Modified:**
- `005_CC_BM_Ice.lua` - Main dispatch

**New Features:**

1. **V3 Affliction Tracking Support** - All affliction checks now route through V3/V2/V1
   - Added `blademaster.hasAff(aff)` - Routes V3 → V2 → V1 based on active tracking system
   - Added `blademaster.getAffProb(aff)` - Returns probability (0.0-1.0) for V3, binary for V2/V1
   - Added `blademaster.getTrackingSystem()` - Returns "V3", "V2", or "V1"
   - Replaced all 22 direct `tAffs.xxx` reads with `blademaster.hasAff("xxx")` calls
   - Follows identical pattern to `infernalDWC.hasAff()` in DWC Vivisect reference

2. **Tracking System Status Display** - Status panels now show active tracking system
   - All 5 status displays (runDoublePrep, runQuadPrep, runBrokenstar, statusDoublePrep, statusQuadPrep) show `| Track: V1/V2/V3`

3. **Nil-Safety Guards** - Defensive coding for V3 module load order
   - `blademaster.hasAff()` checks `haveAffV3` exists before calling (graceful V2/V1 fallback)
   - `blademaster.getAffProb()` checks `getAffProbabilityV3` exists before calling

4. **Dual-Check Shield/Rebounding** - Belt-and-suspenders for critical defenses
   - All 3 shield/rebounding checks (`selectAttackDoublePrep`, `selectAttackQuadPrep`, `selectAttackBrokenstar`) use dual-check pattern matching DWC reference
   - Pattern: `blademaster.hasAff("shield") or blademaster.hasAff("rebounding") or (tAffs and (tAffs.shield or tAffs.rebounding))`
   - Ensures defenses are never missed even if V2/V3 desyncs with V1 table

**Afflictions Migrated (22 total):**
- `airfisted`, `hamstring` (5 locations), `paralysis` (2), `hypochondria`, `weariness`, `clumsiness` (2), `prone` (7), `shield` (3), `rebounding` (3)

**Not Changed (intentional):**
- `tmounted` (4 locations) - mount tracking, not affliction system
- `tparrying` / `ataxiaTemp.parriedLimb` - parry tracking, not affliction system
- `tAffs = tAffs or {}` initializations (5 locations) - kept for V1 fallback safety

---

### 2026-01-02 - Brokenstar Upper Body Prep & Trigger Fixes

**Files Modified:**
- `005_CC_BM_Ice.lua` - Main dispatch

**New Features:**

1. **Dynamic Centreslash Direction** - Upper body prep now balances torso/head damage
   - Like `getFocusLeg()` for legs, `getCentreslashDirection()` chooses UP or DOWN
   - **UP**: Torso primary (18.1%), Head secondary (12.1%)
   - **DOWN**: Head primary (18.1%), Torso secondary (12.1%)
   - Always hits the LOWER limb as primary to balance damage
   - Prevents torso breaking before head is prepped

2. **Strikes During Upper Prep/Break** - Centreslash now applies afflictions
   - Upper Prep: Uses `selectPrepStrike()` (hamstring > paralysis > hypochondria, etc.)
   - Upper Break: Uses `selectIceStrike()` (clumsiness > paralysis)
   - Command format: `centreslash <target> <up|down> <strike>`

**Bug Fixes:**

3. **Bladetwist Count on Button Spam** - Fixed count incrementing on every button press
   - Removed increment from `buildComboBrokenstar()` (was called on each press)
   - Added `onBladetwistSuccess()` callback triggered when bladetwist actually fires
   - Added trigger: `BLADETWIST [|] BLADETWIST [|] BLADETWIST`
   - Count now only increments when the triple-bladetwist actually executes

4. **Bleeding Trigger Not Capturing** - Fixed bleeding value not updating
   - Changed pattern from `^You observe .+ \\[(\\d+)\\]$` to `You observe .+ \\[(\\d+)\\]`
   - Removed strict anchors that could fail in Mudlet
   - Now correctly captures bleeding values: [370], [850], [900], etc.
   - Enables brokenstar to trigger when bleeding >= 700

5. **Brokenstar at 900 Bleeding** - System should now properly go to brokenstar phase
   - When target writhes free at 900 bleeding: `isImpaled = false`, `bleedingReady = true`
   - Phase check: `bleedingReady and not isImpaled` → returns "brokenstar"
   - No longer falls back to upper_prep when bleeding threshold met

**New State/Functions:**
- `blademaster.getCentreslashDirection()` - Returns "up" or "down" based on which limb is lower
- `blademaster.onBladetwistSuccess()` - Callback for bladetwist trigger
- `blademaster.state.torsoDamage` / `headDamage` - Separate damage tracking for torso/head

**Upper Body Damage Values:**
```lua
torsoDamage = 18.1  -- Primary damage from centreslash
headDamage = 12.1   -- Secondary damage from centreslash
```

---

### 2026-01-02 - Mount-Aware Dismount & Brokenstar Prone Fix

**Files Modified:**
- `005_CC_BM_Ice.lua` - Main dispatch

**Bug Fixes:**

1. **Mount-Aware Dismount** - Added dismount logic before double-break
   - KNEES on mounted target DISMOUNTS instead of PRONING
   - When mounted + hamstring + final prep hit → use KNEES to dismount first
   - Then KNEES on double-break will properly prone the target
   - Added status message: "*** DISMOUNT - KNEES to dismount before double-break! ***"
   - Applied to both `selectStrikeDoublePrep()` and `selectStrikeBrokenstar()`

2. **Brokenstar KNEES Missing** - Fixed brokenstar route not proning target
   - `selectStrikeBrokenstar()` was returning `nil` for leg_break phase → now returns "knees"
   - `buildComboBrokenstar()` wasn't appending strike for leg_break phase → now appends strike
   - Target dodged impale because they weren't prone
   - Command now outputs: `infuse ice;legslash <target> <leg> knees`

3. **Writhe Escape Detection** - Fixed brokenstar getting stuck after target writhes free
   - Added trigger to detect: "manages to writhe \w+self free of the weapon which impaled"
   - Calls `onTargetUnimpaled()` which now fully resets brokenstar state via `resetBrokenstarState()`
   - System returns to leg_prep phase after writhe escape

4. **Bleeding Value Tracking** - Now tracks actual bleeding value instead of just 700+ boolean
   - Added `blademaster.state.targetBleeding` to store actual value
   - Added trigger to capture bleeding from: "You observe ... [280]"
   - Status display now shows actual value with color coding (red <300, yellow 300-699, green 700+)
   - Helps track bladetwist progress even if target escapes

5. **Removed Impale2 Phase** - Skip second impale, go directly to bladetwist after impaleslash
   - After impaleslash, target is still impaled - no need to re-impale
   - Reduces window for target to writhe free
   - New flow: Impale → Impaleslash → Bladetwist (skip impale2)
   - Bladetwist message now shows bleeding progress: "Building bleeding (280/700)"

### 2024-12-30 - Bug Fixes and Improvements

**Files Modified:**
- `005_CC_BM_Ice.lua` - Main dispatch
- `002_Hamstring.lua` - Hamstring trigger
- `001_Anti_Priorities.lua` - Defense priorities

**Bug Fixes:**

1. **Limb Tracking Mismatch** - Fixed dispatch using `tLimbs` instead of `lb[target].hits`
   - Added `blademaster.getLimbDamage()`, `getLL()`, `getRL()` helper functions
   - Now correctly reads from `lb[target].hits["left leg"]` / `lb[target].hits["right leg"]`

2. **Lightning + Clumsiness Redundancy** - Fixed striking clumsiness (ears) during lightning prep
   - Lightning infusion ALREADY gives clumsiness automatically
   - New priority: Paralysis > Hypochondria > Weariness > Clumsiness (fallback)

3. **Hamstring Reapplication** - Fixed hamstring being applied multiple times within 10s
   - Added timestamp-based tracking via `blademaster.state.lastHamstringTime`
   - Hamstring trigger calls `blademaster.onHamstringApplied()` callback

4. **Quicksilver Application** - Fixed "I don't see the container" error
   - Changed to `outr 1 quicksilver;apply quicksilver to skin`

5. **Knees Priority** - Fixed knees only triggering on double-break ready
   - Now triggers when ANY leg is about to break (100% on next hit)
   - Added `blademaster.checkLegAboutToBreak()` function

6. **Parry Bypass** - Added centreslash up option when can't airfist
   - When parrying a leg and no shin for airfist and other leg is prepped
   - Uses CENTRESLASH UP to hit torso/head instead of wasting damage

7. **Airfist Cooldown** - Removed non-existent cooldown check
   - Airfist has NO cooldown, only shin requirement (25 shin)
   - Removed `airfistCooldown` config and `lastAirfist` state tracking

### 2024-12-31 - Ice Phase and Double-Break Overhaul

**Files Modified:**
- `005_CC_BM_Ice.lua` - Main dispatch

**Bug Fixes:**

1. **ICE Infuse on Double-Break** - Switch to ICE when double-break imminent
   - `getPhase()` now returns "ice" when `checkWillDoubleBreak()` is true
   - Get frozen damage bonus on the double-break hit itself

2. **KNEES on Double-Break** - Use KNEES (not STERNUM) when both legs will break
   - Prone on the same hit as double-break
   - Changed `selectStrike()` to return "knees" for `checkWillDoubleBreak()`

3. **STERNUM in Mangle Phase** - Use STERNUM when prone + any leg broken
   - No need for KNEES if already prone - just pump damage
   - Added `checkAnyLegBroken()` check with prone gate

4. **KNEES Safeguard** - Only use KNEES when target is NOT prone
   - KNEES is wasted on already-prone targets
   - Added `and not tAffs.prone` gate to single-leg break KNEES check

5. **Removed BALANCESLASH** - Never use BALANCESLASH
   - In ice phase with broken legs, always LEGSLASH for mangle
   - Removed BALANCESLASH from `selectSwordAttack()` and combo builder

6. **Phase Reset After Partial Heal** - Fixed system reverting to COMPASSSLASH when one leg healed
   - Updated `getPhase()` to return "ice" when ANY leg is broken (≥100%)
   - No longer falls back to prep phase after double-break

7. **Mangle Strategy** - Proper post-double-break attack selection
   - Both legs broken: Hit OFF-LEG (targeted second, got secondary damage)
   - One leg broken: Continue hitting broken leg
   - COMPASSSLASH catch-up only used during prep (no broken legs)

**New Helper Functions:**
- `blademaster.checkWillDoubleBreak()` - BOTH legs will break on next hit
- `blademaster.checkAnyLegBroken()` - At least one leg at 100%+

**Strike Priority (Updated):**
1. AIRFIST (parry bypass)
2. STERNUM (both legs broken - ice phase)
3. KNEES (double-break imminent - prone on break)
4. STERNUM (prone + any leg broken - mangle phase)
5. KNEES (single leg about to break AND not prone)
6. HAMSTRING → NECK → CHEST → SHOULDER → EARS

### 2024-12-31 - Phase and Damage Tracking Fixes

**Files Modified:**
- `005_CC_BM_Ice.lua` - Main dispatch

**Bug Fixes:**

1. **ICE Phase Only When Prone** - Fixed ice phase triggering when target stands up
   - `getPhase()` now requires PRONE + any leg broken for ice phase
   - When they stand up, switches back to LIGHTNING (clumsiness)
   - Double-break imminent still triggers ice phase

2. **COMPASSSLASH When Leg Broken** - Fixed compassslash triggering with broken leg
   - `needsCompassslash()` now returns false if any leg is broken (≥100%)
   - COMPASSSLASH only used during prep phase with no broken legs

3. **Damage Tracking Pattern** - Fixed pronoun pattern not matching "faes"
   - Changed trigger pattern from `(?:his|her)` to `\w+`
   - Now matches all pronouns: his, her, its, faes, etc.
   - Damage values should now update correctly from combat

**Phase Logic (Updated):**
- **ICE phase**: PRONE OR double-break imminent
- **PREP phase**: Lightning - all other cases (standing)

**Strike Logic (Updated):**
- **PRONE** → Always STERNUM (maximize damage with ice)
- **Double-break imminent** → KNEES (prone on break)
- **Leg about to break** → KNEES (prone on break)
- **Otherwise** → HAMSTRING > afflictions

### 2025-01-02 - Mount-Aware Dismount Logic

**Files Modified:**
- `005_CC_BM_Ice.lua` - Main dispatch

**Bug Fix:**

1. **Mounted Target Not Proning** - Fixed double-break on mounted target only dismounting, not proning
   - **Problem**: KNEES on a mounted target DISMOUNTS instead of PRONING
   - So double-break + KNEES while mounted = dismount only, target still standing
   - **Solution**: Use KNEES on final prep hit to dismount BEFORE double-break
   - Conditions: `tmounted + tAffs.hamstring + checkWillPrepBothLegs()`
   - Result: Dismount on prep hit, then KNEES on double-break prones them

**Updated `selectStrikeDoublePrep()` logic:**
```lua
if phase == "leg_prep" then
  -- Dismount during final prep hit if mounted + hamstrung
  if tmounted and tAffs.hamstring and blademaster.checkWillPrepBothLegs() then
    return "knees"  -- Dismount now, so KNEES on double-break will prone
  end
  return blademaster.selectPrepStrike()
end
```

**Attack Sequence (Mounted Target):**
- Hit 1-N: Prep legs with hamstring/afflictions
- Hit N+1 (final prep): KNEES dismounts (mounted + hamstrung)
- Hit N+2 (double-break): KNEES prones (now dismounted)


## PvE: shin is a contended pool (v4.7.193)

`SHIN AUGMENT` (Bladed Reflexes boon) and `SHIN THUNDERSTORM` (Divine Thunder Cataclysm boon)
both take the equilibrium and both draw on shin, so the basher sends at most ONE of them per
round -- augment first, storm on the following round. The storm's helper is not called at all
on an augment round, because `ataxiaTemp.bmThunderstormAt` is stamped inside it and a
discarded return value would still buy a 4s lockout. `INFUSE` also draws shin but is cheap
enough to ride alongside. See `ataxiaBasher_blademasterBashing`, basher/002.


## PvE: the shin room-nuke is one slot with two damage types (v4.7.195)

Two Mnemosyne boons grant a Shindo room nuke, and they are mechanically identical:

| boon | ability | damage |
|---|---|---|
| Divine Thunder Cataclysm | `SHIN THUNDERSTORM` (AB 314) | electric |
| Midnight Snow's Icy Heart | `SHIN BLIZZARD` (AB 315) | cold |

Both are "Works on/against: Room", **4.00s of equilibrium, 30 Shin energy**. Identical cost
means they share one slot -- `ataxiaBasher_bmShinStorm` casts exactly one per round (stamp
`ataxiaTemp.bmShinStormAt`), and it still yields the round entirely to `SHIN AUGMENT`.

Holding both is a genuine advantage rather than a redundancy: the ripple's suppression affix
names a damage *type*, so the picker takes whichever is not nulled (Iceproof -> thunderstorm;
an electric-nulling ripple -> blizzard; both -> cast anyway). Tune with
`ataxiaBasher.bmStormPrefs` (default `{lightning, ice}`) and `ataxiaBasher.blizzardAt`
(defaults to `thunderstormAt`, 3+).

Blizzard's fire line is **uncaptured** -- no confirm trigger exists yet, so the send-side
stamp is the only cooldown source. Its AB also leaves "a temporary obscuring snowstorm" in
the room, which nothing models; check it first if mob tracking degrades after a blizzard.
