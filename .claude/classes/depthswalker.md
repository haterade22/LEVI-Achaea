# Depthswalker

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Damage | Mana Kill
- **Difficulty**: Hard
- **Lock Affliction**: Recklessness (blocks Accelerate passive cure)

## Skills
```
Aeonics: Time manipulation, retardation, aeon, timeloop
Shadowmancy: Shadow manipulation, instills, affliction delivery
Terminus: Death/void powers, mutilate, dictate, room hinders
```

## Core Combat Mechanics

### Attack Pattern
The standard DW attack sequence:
```
shadow attune <target> to <attune>
shadow instill scythe with <instill>
chrono assert|chrono loop [boost]
shadow reap <target> [venom]
```

### Dual-Slot System
Unlike some classes, DW has **two independent affliction delivery methods per attack**:
- **Instill slot**: Delivers DW-specific stacking afflictions
- **Venom slot**: Delivers standard venom afflictions via shadow reap

When using **chrono loop**, the venom slot is sacrificed for double instill application (timeloop aff + doubled instill effect).

### Instill System
```yaml
description: "Primary DW affliction delivery via weapon instill"
syntax: "shadow instill <weapon> with <instill_type>"

valid_instills:
  - degeneration
  - depression
  - retribution
  - madness
  - leach
  - impatience

IMPORTANT: "timeloop is NOT an instill - it comes from chrono loop command"
```

### Instill Stacks (Affliction Progression)
Each instill type gives afflictions in a specific order. If target already has an affliction, the next one in the stack is applied:

```yaml
degeneration:
  stack: [clumsiness, weariness, paralysis]
  cure: kelp
  capstone: "Damage burst"
  notes: "Capstone damage is HALVED without shadow claimed"

depression:
  stack: [depression, nausea, hypochondria]
  cure: goldenseal
  capstone: "depression + anorexia + masochism (all three)"
  notes: "Masochism causes self-damage when target cures"

retribution:
  stack: [justice, retribution]
  cure: bellwort
  capstone: "Mana sap"
  notes: "Both justice and retribution are bellwort-cured"

madness:
  stack: [shadowmadness, vertigo, hallucinations]
  cure: ash
  capstone: "Stun"
  notes: "Stun provides window for depression capstone"

leach:
  stack: [parasite, healthleech, manaleech]
  cure: kelp (healthleech, manaleech) / goldenseal (parasite)
  capstone: "Enables shadow claim"
  notes: "healthleech and manaleech are kelp-cured - need kelp pressure first!"

impatience:
  stack: [impatience]
  cure: goldenseal
  capstone: none
  notes: "Direct affliction, no stack. ONLY way DW can give impatience"
```

### Chrono Commands
```yaml
chrono_assert:
  effect: "Standard attack timing"
  usage: "Default when not using timeloop"

chrono_loop:
  effect: "Applies timeloop affliction + doubles instill effect"
  requirement: "Age < 250 years (unboosted)"
  usage: "Fast affliction stacking"

chrono_loop_boost:
  effect: "Same as chrono loop but works at any age"
  requirement: "None (boosted version)"
  usage: "Critical for healthleech→manaleech transition"
  notes: "Costs 10 lessons in Aeonics to unlock"
```

### Timeloop Mechanics
```yaml
description: "Timeloop doubles the instill affliction delivery"

when_to_use:
  - "CRITICAL: When healthleech stuck but not manaleech - use chrono loop boost"
  - "Building toward capstone (3-4 DW affs)"
  - "Lock mode when rushing affliction count"
  - "Bellwort phase to apply timeloop affliction"

important: |
  Timeloop is NOT an instill. It comes from chrono loop command.
  When chrono loop fires, target gets timeloop affliction AND
  the instill effect is doubled (2 afflictions from the stack).
```

### Bellwort Stack Strategy
```yaml
description: "Bury target with bellwort-cured afflictions"

bellwort_affs:
  - timeloop: "From chrono loop"
  - justice: "From instill retribution (first stack)"
  - retribution: "From instill retribution (second stack)"

strategy: |
  All three are bellwort-cured. Target can only eat bellwort once
  per balance, so with 3 bellwort affs, 2 remain stuck at all times.
  This creates massive DW aff pressure toward capstone.

how_to_apply:
  - "Use chrono loop to apply timeloop"
  - "Use instill retribution to get justice (first)"
  - "Use instill retribution again to get retribution (second)"
```

### Shadow Resource
```yaml
description: "Critical resource for executes and damage"

how_to_claim:
  - "Stack leach afflictions: parasite → healthleech → manaleech"
  - "When all 3 present + capstone ready (5 DW affs): leach capstone fires"
  - "After leach capstone: SHADOW CLAIM <target>"

trigger_pattern: "^You claim the shadow of (\\w+), storing it within your phylactery.$"
trigger_message: "You claim the shadow of <target>, storing it within your phylactery."

usage:
  - "Required for Mutilate execute"
  - "Enhances damage (degeneration capstone HALVED without shadow)"

global_variable: "haveshadow (set by triggers)"
```

## Kill Routes

### Lock Route
```yaml
type: affliction
summary: "Build toward truelock with bellwort stack + standard lock affs"

phases:
  1_kelp:
    description: "Stick clumsiness for kelp pressure"
    instill: degeneration
    venom: curare
    chrono: assert
    notes: "They must cure paralysis (curare) instead of clumsiness"

  2_shadow:
    description: "Build leach stack toward shadow claim"
    instill: leach
    venom: curare
    chrono: "loop boost when healthleech stuck"
    notes: "healthleech/manaleech are kelp-cured - need kelp pressure first!"

  3_bellwort:
    description: "Bury target with bellwort affs"
    instill: retribution (for justice, then retribution)
    venom: varies
    chrono: "loop when timeloop missing"
    notes: "3 bellwort affs = 2 always stuck"

  4_lock:
    description: "Standard lock progression"
    instill: depression/impatience
    venom: kalmia → gecko → curare → slike
    notes: "Impatience ONLY via instill"

required_afflictions:
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying"
  - paralysis: "blocks tree"
  - impatience: "blocks focus (ONLY via instill)"
  - recklessness: "blocks Accelerate passive cure"
```

### Damage Route
```yaml
type: damage
summary: "Claim shadow, then spam degeneration for capstone damage"

IMPORTANT: "Degeneration capstone damage is HALVED without shadow!"

phases:
  1_kelp:
    description: "Spam degeneration + curare for kelp pressure"
    instill: degeneration
    venom: curare
    chrono: assert
    notes: "Need clumsiness stuck before going for leach"

  2_shadow:
    description: "Build leach stack toward shadow claim"
    instill: leach
    venom: "curare (default) / kalmia (when healthleech stuck)"
    chrono: "loop boost when healthleech stuck"
    notes: |
      Critical timing: When healthleech stuck, switch to kalmia.
      Asthma blocks herb cure, so manaleech will stick.
      Use chrono loop boost to double-apply leach.

  3_damage:
    description: "Shadow claimed - spam degeneration"
    instill: degeneration
    venom: curare
    chrono: assert
    notes: "Full capstone damage with shadow"

venom_strategy: |
  - Default: curare for paralysis pressure
  - When healthleech stuck: kalmia to block herb cure for manaleech
```

### Dictate Route (Mana Kill)
```yaml
type: execute
summary: "Drain mana with retribution capstone, execute with dictate"

threshold_formula: "40% + (5% × DW_affliction_count)"

threshold_examples:
  0_affs: "40% mana"
  3_affs: "55% mana"
  5_affs: "65% mana"
  7_affs: "75% mana"

strategy:
  1: "Build bellwort stack (adds 3 DW affs)"
  2: "Stack additional DW affs (depression, madness, degeneration)"
  3: "Use retribution capstone for mana sap"
  4: "When mana below threshold: SHADOW DICTATE <target>"
```

### Madpression Route
```yaml
type: combo
summary: "Madness capstone (stun) → Depression capstone (anorexia + masochism)"

strategy:
  1: "Build to 5 DW afflictions"
  2: "Fire madness capstone → target stunned"
  3: "Fire depression capstone → target gets masochism"
  4: "Target cures while stunned → takes masochism damage"
  5: "Continue pressure or finish with damage/execute"

notes: |
  Very effective burst strategy.
  Masochism causes damage when target cures.
  Stun provides free window to apply depression capstone.
```

## Offense Implementation (015_CC_Depthswalker.lua)

### Namespace Structure
```lua
depthswalker = depthswalker or {}

depthswalker.state = {
    mode = "lock",           -- lock/damage/dictate/madpression/group
    haveShadow = false,      -- synced from global 'haveshadow'
    distorted = false,       -- synced from global 'depdistort'
}

depthswalker.config = {
    lockThreshold = 0.3,             -- V3 probability threshold
    highConfidence = 0.7,            -- for truelock detection
    scytheId = "scythe20431",        -- weapon ID
    cullHealthThreshold = 35,        -- HP% for cull
    mutilateHealthThreshold = 40,    -- HP% for mutilate
    mutilateManaThreshold = 30,      -- MP% for mutilate
    debugEcho = false,               -- show debug info
}

depthswalker.DW_AFFS = {
    "depression", "retribution", "parasite", "madness",
    "degeneration", "healthleech", "manaleech", "justice", "timeloop"
}
```

### V3 Integration
```lua
-- Routes to V3 when enabled, falls back to V2/V1
function depthswalker.hasAff(aff)
    if affConfigV3 and affConfigV3.enabled and haveAffV3 then
        return haveAffV3(aff)
    end
    -- V2/V1 fallback...
end

-- Get probability from V3 (for threshold decisions)
function depthswalker.getAffProb(aff)
    if affConfigV3 and affConfigV3.enabled and getAffProbabilityV3 then
        return getAffProbabilityV3(aff)
    end
    return depthswalker.hasAff(aff) and 1.0 or 0.0
end
```

### Key Functions
```lua
-- Main entry point
depthswalker.dispatch()

-- Mode setter
depthswalker.setMode(mode)  -- "lock", "damage", "dictate", "madpression", "group"

-- Status display
depthswalker.status()

-- Selection functions
depthswalker.selectInstill()     -- returns instill type
depthswalker.selectVenom()       -- returns venom name
depthswalker.shouldTimeloop()    -- returns true/false
depthswalker.getChronoCommand()  -- returns "chrono assert"/"chrono loop"/"chrono loop boost"
```

### Aliases
```
dw          - depthswalker.dispatch()
dwm <mode>  - depthswalker.setMode(matches[2])
dws         - depthswalker.status()
dwd         - toggle debugEcho
```

### Global Variables Used
```lua
target          -- current target name
haveshadow      -- shadow claimed (set by triggers)
depdistort      -- distort active (set by triggers)
envenomList     -- populated by dispatch() with selected venom
php             -- target health %
pm              -- target mana %
```

## Trigger Integration

### envenomList Pattern
The offense populates `envenomList` before attacking. Triggers read this to know which venom was applied:

```lua
-- In dispatch():
envenomList = {}
if not depthswalker.selections.useTimeloop and depthswalker.selections.venom then
    table.insert(envenomList, depthswalker.selections.venom)
end

-- In triggers:
local venomName = (envenomList and envenomList[1]) or "unknown"
```

### V3 Tracking in Triggers
Triggers should call both V1/V2 tracking AND V3:
```lua
tarAffed("affliction")
if applyAffV3 then applyAffV3("affliction") end
```

## Capstones
```yaml
description: "When 5+ DW afflictions present, next instill triggers capstone"

trigger_condition: "depthswalker.capstoneReady() returns true when 5+ DW affs"

capstone_type: "Matches the instill type being used"

capstones:
  degeneration: "Damage burst (HALVED without shadow!)"
  depression: "depression + anorexia + masochism"
  madness: "Stun"
  retribution: "Mana sap"
  leach: "Enables shadow claim"
```

## Room Hinder Abilities
```yaml
distort:
  skill: Terminus
  effect: "Room-wide hinder"
  syntax: "DISTORT"
  notes: "Slows enemy movement/actions in room"

preempt:
  skill: Terminus
  effect: "Prevents fleeing"
  syntax: "PREEMPT"
  notes: "Keeps target in room for kills"

retardation:
  skill: Aeonics
  effect: "Create retardation field - extreme action slow"
  syntax: "RETARDATION"
  notes: "Room-wide slow effect, dangerous for everyone"
```

## Defensive Abilities
```yaml
accelerate:
  skill: Aeonics
  effect: "Passive cure for DW"
  blocked_by: [recklessness]
  notes: "Class-specific passive cure"

shift:
  skill: Shadowmancy
  effect: "Shadow movement ability"
  syntax: "SHIFT <direction>"
  notes: "Escape mechanism"

rewind:
  skill: Aeonics
  effect: "Revert to previous state"
  syntax: "REWIND"
  notes: "Powerful defensive reset"
```

## Fighting Against This Class
```yaml
priority_cures:
  - aeon: "SMOKE ELM - extremely important!"
  - asthma: "Restore smoking for aeon cure"
  - timeloop: "Doubles their affliction output"
  - recklessness: "Restores Accelerate if you're DW"
  - paralysis: "Maintain ability to tree/act"
  - masochism: "Prevents self-damage when curing"

dangerous_abilities:
  - mutilate: "Instant kill at 40% HP / 30% MP with shadow"
  - dictate: "Mana kill at 40% + 5% per DW aff"
  - aeon: "Slows ALL actions significantly"
  - chrono_loop_boost: "Doubles affliction application"
  - madness_capstone: "Stun at 5 DW affs"
  - depression_capstone: "Anorexia + masochism at 5 DW affs"

watch_for:
  - "5+ DW afflictions = capstone ready"
  - "Shadow claimed = Mutilate possible"
  - "High DW aff count = lower Dictate threshold"
  - "Bellwort stack (timeloop+justice+retribution) = sustained pressure"
```

## Limb Strategy
```yaml
enabled: false
notes: "Depthswalker is affliction-based, not limb-based"
```

## Bashing (PvE) — v4.7.142 overhaul

The old entry here ("BATTLERAGE SHADOWSTRIKE") was wrong; the basher has always swung
`shadow reap`. Rewritten from a wiki audit (Depthswalker / Aeonics / Shadowmancy /
Terminus) + a code audit, 2026-07-29.

```yaml
primary_swing: "shadow reap <target>"     # fast/low damage; `shadow cull` is slow/high
alternate_swing: "shadow cull <target>"   # `bash dw cull on` -- UNMEASURED, see A/B note
entry_point: ataxiaBasher_depthswalkerBashing   # basher/002_Class_Bashing.lua
```

### The whole battlerage kit is denizen-legal

Unusual among classes: **all six** DW battlerage abilities read "Works on: Denizens"
(AB), so nothing in the kit is wasted in PvE.

| Ability | Cmd | Rage | CD | PvE effect |
|---|---|---|---|---|
| Curse | `chrono curse <t>` | 24 | 35s | **denizen AEON** — every mob action slowed |
| Erasure | `chrono erasure <t>` | 25 | 23s | CONSUMES weakness/amnesia for a damage spike |
| Boinad | `intone boinad <t>` | 32 | 38s | **denizen CHARM** 5s — mob fights its allies |
| Lash | `shadow lash <t>` | 36 | 23s | big direct damage |
| Drain | `shadow drain <t>` | 14 | 16s | DoT filler |
| Nakail | `intone nakail <t>` | 17 | — | **shield break** (needs Terminus) |

### Rotation (`ataxiaBasher_dwBattlerage`, DW_BR — timer-free, the Psion/GDragon pattern)

Culling reap (36, owned, floor-exempt) → **Erasure** (only when the mob carries
weakness/amnesia) → **Curse** (skipped if aeon is already up; BANKS rage when off
cooldown but unaffordable) → **Boinad** (opt-in) → **Lash** → **Drain**.

- **Erasure is group-only by construction.** It consumes weakness or amnesia and DW can
  apply neither, so solo it never fires and costs nothing; it lights up beside a
  Blademaster's Nerveslash (weakness) or a Golden Dragon's Psidaze (amnesia).
- **Boinad charms the mob we are NOT killing** (`stormhammerTargets[2]`, the Bard rule)
  and records `ataxiaTemp.brCharmTgt` so the denizen-state layer attributes the charm to
  the right id.
- Send-side epoch stamps in `ataxiaTemp.dwBrAt`, a 3s in-flight pick replay in
  `ataxiaTemp.dwBrPending` (the 0.3s `queue addclearfull` re-queue loop would otherwise
  burn cooldowns unsent), the shared ~1s global BR gate, and `ataxiaBasher_rageAfford`
  on everything except reap.

### What was actually broken (three defects, all fixed)

1. **SHIELD STALL.** The shielded branch only razed when `ataxiaBasher.rageraze` was on —
   and it defaults **off** — so a shielded denizen bounced forever. Nakail is now sent
   whenever rage >= 17 and the word balance is free, gated on neither the rageraze toggle
   nor the rage floor: breaking the shield *is* the round.
2. **CULLING SUPPRESSION** (the real dead-rotation cause — *not* the Psion/GDragon
   missing-fire-line bug; DW's fire-lines exist at triggers 330:43 and 331:43). The shared
   culling branch in `001_Bashing_Functions` heads the elseif chain and excluded only
   Bard/Blademaster/Magi/Psion, so with culling on DW returned `""` every round below
   36/54 rage and neither drain nor lash ever fired. DW is now excluded there and owns
   culling itself.
3. **SEPARATOR CORRUPTION.** `brage..sp` on a battlerage that already ended in `sp`
   produced `shadow drain 7;;shadow reap 7`, or a leading `;` when empty.

**Do NOT add a `special` key to the Depthswalker config in `_groups.yaml`** — trigger 332
has no Depthswalker block, so `battleRage_Timers.special` is never set and a config
`special` would reproduce the Psion v4.7.128 dead-rotation bug verbatim. New abilities go
in `DW_BR`, which is timer-free.

### Nakail shield-clear (no fire-line exists)

`intone nakail` has no capturable fire-line, and the shielded round deliberately emits no
battlerage, so 330/331/332 never run and `ataxiaBasher.shielded` would never clear —
nakail would re-fire every round, burning 17 rage *and* the word balance. The word-balance
echo (`Imbuing your voice with power, you intone, "nakail".`, trigger
`depthswalker/009_Word_Bal_Used`) is the one line guaranteed to print, so it clears the
flag and emits a `(BR)` alert.

### Terminus buffs — the PvE keeper (`ataxiaBasher_dwKeeper`, DW_KEEPERS)

`intone` words spend the **word balance**, a resource separate from attack
balance/equilibrium — so these are free damage and survivability while the scythe swings.
Keepers yield to nakail (shared word balance) and are skipped when their GMCP defence is
already up. From the character's live `AB TERMINUS`:

| Word | Effect | Defence flag |
|---|---|---|
| `intone trusad` | **raises critical-hit chance vs DENIZENS** | `precision` (assumed) |
| `intone tsuura` | **reduces damage taken from DENIZENS** | `durability` (assumed) |
| `intone mainaas` | augments skin vs cutting/blunt | `bodyaugment` (assumed) |
| `intone mainaad scythe` | scythe cutting edge (+damage) | none known (30m hold) |
| `intone balateth scythe` | scythe speed (faster attacks) | none known (30m hold) |

The three defence-name mappings are **inferred**, not confirmed — verify with `DEF` and
correct `DW_KEEPERS` if wrong (a wrong mapping only means a redundant re-intone).

**Not researched on this character** (worth buying — direct PvE value): **Laiad**
(`INTONE LAIAD <denizen>`, 2s word balance, Works: Denizens — inhibits denizen danger
sense *and increases scythe attack damage*) and **Hailad**. Laiad would slot into the
keeper as a per-target opener.

### Toggles

`bash dw boinad on|off` (default off — 32 rage + the shared word balance for a 5s charm),
`bash dw cull on|off` (default off), `bash dw keepers on|off` (default on).

### Open questions (live capture needed)

- **reap vs cull**: the wiki gives no damage and no balance figures for either. Use
  `bash probe on` and compare — this is the single biggest DPS unknown.
- **Aeon uptime**: `BR_AFFS.aeon.dur` is 6s against Curse's 35s cooldown. If that is
  accurate the control-banking rule may not pay; capture the aeon wear-off line and
  measure. Dropping `control = true` from the Curse row disables banking with no other
  change.
- **Erasure's inputs**: does *aeon* also satisfy it? The AB text names only weakness and
  amnesia. If aeon counts, Curse → Erasure becomes a self-sufficient solo combo and the
  whole priority order changes.
- **Nakail**: real cooldown (the AB cooldown field is present but empty), and the
  shield-destruction line, to replace the intone-echo proxy.
- **332:53** (`You hold out one hand towards <t> as something made of shadow and ice
  rises...`) is unattributed and shadow-flavoured — likely `chrono curse`. Confirm, then
  wire `ataxiaBasher_dwConfirm("curse")` + `dsSetAff(target, "aeon")`; that would finally
  fill `BR_AFFS.aeon.apply`, which is nil for every class today.
- **Phylactery**: do denizen kills yield shadows? If not, the whole Assimilate/Mutilate
  tier is dead weight in PvE and should be documented as such.
```yaml
deferred_not_worth_wiring:
  chrono_deteriorate: "only Aeonics ability whose works-against names denizens, but the
    effect is -1 INT per affliction + increased depression damage -- an INT debuff and a
    PvP curse multiplier, neither converts to denizen kill speed. 300 age for nothing."
  shadowmancy_instills: "pure affliction ladders (degeneration/depression/madness/
    retribution/leach) -- denizens ignore them"
  dictate_kill_route: "executes below 40% max MANA -- irrelevant to denizens"
  tooros: "AoE that damages the caster too, and Works: Adventurers"
```
