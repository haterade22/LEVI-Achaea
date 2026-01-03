# Blademaster

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
  description: "Salve balance manipulation"
  steps:
    1: "Prep legs, head, AND torso"
    2: "Break HEAD + TORSO in one slash"
    3: "Enemy applies to head (most common)"
    4: "Break LEGS (prone) right as they apply to leg"
    5: "IMPALE + IMPALESLASH + BLADETWISTx2"
    6: "Re-impale or BROKENSTAR"
  advantage: "Ensures no salve balance to heal torso before leg break"

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
battlerage_abilities:
  - slash: "Basic damage"
  - multislash: "Multiple hits"
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
6. **PARRY BYPASS** - If parrying and no shin for airfist, use CENTRESLASH UP (hits torso/head)
7. **INFUSE ICE + STERNUM** - After ANY leg broken, switch to ice for damage
8. **MANGLE STRATEGY** - After double-break, hit the leg with HIGHER % for level 3 break
9. **COMPASSSLASH** - Used to balance legs ONLY during prep (no broken legs)
10. **MOUNT-AWARE DISMOUNT** - When target is mounted + hamstrung + final prep hit, use KNEES to dismount BEFORE double-break

**Key Insights**:
- Breaking BOTH legs simultaneously is critical vs experienced players
- After double-break, stay in ICE phase even if one leg heals
- MANGLE (level 3 break) requires 2 restoration applications to heal = huge advantage
- Always hit the HIGHER % broken leg when going for mangle
- **MOUNTED TARGETS**: KNEES on mounted target DISMOUNTS but doesn't PRONE. Must dismount first, then double-break for prone.

### Commands
```yaml
bmd: Main dispatch attack (blademaster.dispatch.run())
bmstatus: Display status panel (blademaster.dispatch.status())
```

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
- INFUSE ICE only while PRONE (switch to lightning when they stand)
- If PRONE + any leg broken: LEGSLASH the OFF-LEG (targeted second) + STERNUM
- Goal: MANGLE (level 3 break) = 2 restoration applications to heal
- If they STAND UP: Switch to LIGHTNING, continue hitting broken leg
- Target is frozen + leg broken = massive damage
- MULTISLASH burst when HP < 30%
```

**Mangle Strategy**: After double-break:
- While PRONE: Stay in ICE phase, hit OFF-LEG (targeted second), STERNUM
- If they STAND UP: Switch to LIGHTNING, continue hitting broken leg
- One leg broken: Always hit the broken leg for mangle

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
| Parrying leg + no shin for airfist + other leg prepped | CENTRESLASH | UP (torso/head) |
| Both legs broken (ice phase) | LEGSLASH | OFF-LEG (targeted second) |
| One leg broken | LEGSLASH | Broken leg |
| Gap too big (prep phase only) | COMPASSSLASH | Lower leg (SE/SW) |
| Normal prep | LEGSLASH | Lower leg |

**NOTE**: BALANCESLASH is never used - always LEGSLASH in ice phase for mangle.
**NOTE**: After double-break, hit the OFF-LEG (the leg that got secondary damage). It was "targeted second" in the legslash.

### Shin Mechanics
- **Generation**: 8 per strike normally, 12 in Sanya stance
- **Infuse cost**: 5 shin
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

Additional check functions:
- `blademaster.checkDoubleBreakReady()` - Both legs at 90%+
- `blademaster.checkBothLegsBroken()` - Both legs at 100%+
- `blademaster.checkAnyLegBroken()` - At least one leg at 100%+
- `blademaster.checkLegAboutToBreak()` - Either leg will hit 100% on next hit
- `blademaster.checkWillDoubleBreak()` - BOTH legs will break on next hit (causes prone)
- `blademaster.shouldSwitchToBody()` - Parry bypass logic (no shin for airfist)

### Status Display
```
+============================================+
|     BLADEMASTER DOUBLE-PREP DISPATCH      |
+============================================+
| Target: <name> (HP: X%)
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
