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

### Shielded denizens: never spend rage (v4.7.143)

**Rage is for damage, not shields** — the same doctrine that keeps Magi off Disintegrate
(it casts the free `erode`) and Monk off Splinterkick (shatter is free). Depthswalker's
only razer is **Nakail, a 17-rage battlerage**, so the default answer to a shielded
denizen is to keep swinging and let the shield lapse. Nothing stalls: trigger 336 sets
`ataxiaBasher.shielded` with a ~3.1s self-clearing timer and, when `shieldswap` is on with
another mob available, retargets outright instead. `bash rageraze on` is the explicit
opt-in for spending the rage (and even then nakail needs 17 rage *and* a free word
balance).

> Correction to the v4.7.142 note: that release called the missing razer a "shield stall"
> and made nakail unconditional. That was wrong on both counts — the shield flag
> self-clears, so there was never an infinite bounce, and firing a battlerage at a shield
> is exactly what `rageraze` exists to prevent by default.

### What was actually broken (two defects, both fixed)

1. **CULLING SUPPRESSION** (the real dead-rotation cause — *not* the Psion/GDragon
   missing-fire-line bug; DW's fire-lines exist at triggers 330:43 and 331:43). The shared
   culling branch in `001_Bashing_Functions` heads the elseif chain and excluded only
   Bard/Blademaster/Magi/Psion, so with culling on DW returned `""` every round below
   36/54 rage and neither drain nor lash ever fired. DW is now excluded there and owns
   culling itself.
2. **SEPARATOR CORRUPTION.** `brage..sp` on a battlerage that already ended in `sp`
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

### Terminus buffs — one-time defences (`dw setup` + a drop-only keeper)

**Terminus words are almost all ONE-TIME defences**: intone once and they persist. The
exceptions are the ones with a "Works against" field (Laiad/Hailad target denizens) —
those are repeatable actions, not defences. So raising them is a setup chore, not
something the bashing rotation re-asserts.

`intone` spends the **word balance**, a resource separate from attack balance/equilibrium
— and all words share that one balance, so they can't be batched.

**`dw setup`** (`class_things/003_Depthswalker_Setup.lua`) queues the one-time buffs and
sends **one per word balance**, chained off the game's own
`You may intone another word of power.` line (trigger `depthswalker/010`), so it
self-paces exactly. Denizen-facing buffs go first, so an interrupted run still lands the
ones that matter for bashing. `dw setup force` re-intones even standing defences;
`dw setup stop` clears the queue.

| Word | Effect | Defence flag |
|---|---|---|
| `intone trusad` | **raises critical-hit chance vs DENIZENS** | `precision` |
| `intone tsuura` | **reduces damage taken from DENIZENS** | `durability` (?) |
| `intone mainaas` | augments skin vs cutting/blunt | `bodyaugment` (?) |
| `intone mainaad scythe` | scythe cutting edge (+damage) | none |
| `intone balateth scythe` | scythe speed | none |
| `intone tah'maal` | cloak fire resist + rebirth recovery | none |
| `intone ukhia` | clot without spending willpower | none |
| `intone qamad` | deeper meditation regen | none |
| `intone dalem` | +5 phylactery shadows | none |

Deliberately excluded: **Kail** raises a prismatic barrier, which stops *us* attacking
too (emergency command, not a standing buff); **Laiad/Hailad** are denizen-targeted
actions; **Tooros** damages the caster.

**The bashing keeper** (`ataxiaBasher_dwKeeper`) only re-ups a buff when GMCP reports the
defence actually **dropped** — and therefore only covers the three with defence flags.
The flagless words can't be observed, so re-asserting them mid-bash would be blind spam;
they live in `dw setup` only. The keeper yields the word balance whenever a shield is
standing.

The `(?)` mappings are **inferred** from the AB text, not confirmed against a live `DEF`
— correct them in `ataxiaTables.defenceWords` (`deffing/004`) if wrong. `defs valid` now
prints the raising command beside the protocol name (`Precision (trusad)`) so the mapping
is visible in game.

### Toggles

`bash dw boinad on|off` (default off — 32 rage + the shared word balance for a 5s charm),
`bash dw cull on|off` (default off), `bash dw keepers on|off` (default on).

### Mnemosyne boon: Flashforward (v4.7.146)

> *"You deal 20% bonus damage while you possess the chrono blur defence."*

`blur` is one of the GMCP-tracked Depthswalker defences, so this is a keep-it-up job --
but `CHRONO BLUR` is an **Aeonics** command paid in **age and equilibrium**, not the word
balance, so it rides beside the balance swing and never competes with nakail or the
Terminus buffs. It fires on shielded rounds too: the buff is on *us*, and a shield round
still ends with a swing.

`ataxiaBasher_dwFlashforward` (basher/002) re-ups only while `dwFlashforward` is set and
`ataxia.defences.blur` is down, with an 8s attempt-hold for the defence line to land, and
capped by `ataxiaBasher.dwAgeCap` (default **400** -- the yellow/orange boundary in
`getAgeColour`) so bashing can never price out the chrono kit. Standard boon lifecycle:
claim intercept, BOONS-row trigger `mnemosyne/038_Flashforward`, cleared on run
start/end.

### Live-log findings (2026-07-29, Mnemosyne, Death Knight + soldier of Osterrych)

**Confirmed fire lines** (all now wired):
- **Chrono Curse** → `Bending your formidable will upon <t>, you slow the passage of time
  about him to a crawl.` — the first confirmed denizen-AEON *apply* line in the whole
  system (`BR_AFFS.aeon.apply` was nil for every class). Trigger
  `denizen_attacks_misc_lines/015`, which also calls `ataxiaBasher_dwConfirm("curse")`.
- **Curse wear-off** → `<t> abruptly begins to move at normal speed again.` (trigger 016).
- **Shadow Drain** → `You command the shadow of <t> to begin siphoning away the life of
  its host.` (already matched by trigger 330); ticks as `<t> grows paler as her shadow
  grows more opaque.`; ends `The shadow of <t> is no longer siphoning away her life.`
  Observed duration ~9s, ticking 239 → 512 → 2048 → 128 → 32 (unblockable).

**MEASURED: denizen aeon lasts ~5.6s** (landed 12:15:14.0, expired 12:15:19.7) against
curse's **35s cooldown** — about 16% uptime. That killed the rage-banking rule: holding 24
rage and skipping the filler to guarantee a 5-second mitigation window loses more damage
than it saves. Curse now fires when affordable and yields otherwise.

**Two intone wordings, one balance.** Outward words print `Imbuing your voice with power,
you intone, "X".`; Augmentation self-buffs print `Taking a steadying breath, you turn your
focus inward and proclaim, "X".` The second was unmatched, so `wordBal` stayed TRUE after
Mainaas and the next word would be sent into a balance we didn't have. Same balance,
confirmed by timing: Mainaas at 12:15:06.4 → `You may intone another word of power.` at
12:15:12.5 = 6.1s ≈ its 6.50s cost.

**Reap damage samples** (Agith'maal's ire, psychic): base non-crit vs the Death Knight
**2515**, with crits at 5030 (2x), 10060 (4x) and one 25180 vs the soldier. A second
cluster of **599/750/786** hits appeared under conditions not yet identified — use
`bash probe on` to separate them rather than guessing.

**The atrophy DoT is gear, not class.** `<t>'s form begins to atrophy as your attack
kindles ethereal mist...` + `Time wreaks ruin upon <t>...` (~178/tick, decaying to 88/92/5)
fired here on Depthswalker, having first been seen on Golden Dragon — so the
`highlighting/029` trigger is correctly class-agnostic.

**Problems seen, worth watching:**
- HP rode at **1-3% for ~15 seconds** while the basher kept swinging. This was a
  Mnemosyne (no-flee) fight, so fleeing was off the table, but nothing shielded either.
- The keeper intoned **Mainaas at 12% HP while prone** — fixed in v4.7.145 by gating the
  keeper on `dangerLevel() == "attack"`.
- **Shield bounces cost ~5 rounds** (`A dizzying beam of energy strikes you as your attack
  rebounds off...`), across three separate shields of ~2.5-3s each. Rage deliberately
  isn't spent on shields; with a second denizen present, `shieldswap` retargeting is the
  lever worth checking.
- Three `You must wait a short time before you can use a battlerage ability again.`
  rejections — trigger 329 arms the global cooldown reactively, so this self-corrects,
  but it means the 1s gate is occasionally optimistic.

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
