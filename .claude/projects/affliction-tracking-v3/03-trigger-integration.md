# V3 Trigger Integration

## Overview

V3 integrates with existing triggers by adding function calls that update the branching state tracker. The V3 calls run alongside existing V2/legacy tracking for redundancy.

**Not a V1 erase after a V3 cure.** V3 copies its result into `tAffs`. A V1 erase chain that runs after it reads that copy and takes a SECOND affliction. Since v4.7.479 the bloodroot trigger runs its V1 chain only with V3 off (see Bloodroot below).

**A proof goes before an erase.** `erAff` strips an affliction from each branch, so a branch the line has ruled out would keep its weight. Call `proveAffAbsentV3(aff)` first. (Applies at 391, 392, 393, 395, 396 and herbs/013; the tree at 389 through 008.)

The 2026-11-08 changes below are covered by `src_new/tests/test_v3_core_fixes.lua`, `test_target_cure_lines.lua` and `test_tracker_followups.lua`. None has run in Mudlet.

## Herb Triggers

### Integration Pattern
Each herb trigger should call `onHerbCureV3()` after detecting the target eating:

```lua
if isTargeted(matches[2]) then
    -- Existing code...
    targetAteWrapper("herbname")

    -- V3 integration
    if onHerbCureV3 then onHerbCureV3("herbname") end

    -- Rest of existing code...
end
```

### Integrated Herb Triggers

#### Herbs (`triggers/levi_ataxia/for_levi/leviticus/herbs/`)

| File | Herb | V3 Call |
|------|------|---------|
| `001_Goldenseal(U).lua` | goldenseal | `targetAteWrapper("goldenseal")` |
| `002_Goldenseal_(Madness).lua` | goldenseal | through `ataxia_randomCureV3` (Known-cure lines) |
| `003_Kelp_(Unknown).lua` | kelp | through `ataxia_randomCureV3` |
| `004_Goldenseal_(Mycalium).lua` | goldenseal | replaces 002's cure (`ataxia_knownCureV3`) |
| `005_Bloodroot_TEST.lua` | bloodroot | `onHerbCureV3("bloodroot")` |
| `006_Ash.lua` | ash | `targetAteWrapper("ash")`, unless crescendo is up (Crescendo below) |
| `007_Ginseng.lua` | ginseng | through `ataxia_randomCureV3` |
| `008_Ginseng_with_Flushings.lua` | ginseng | through `ataxia_randomCureV3`, only when 007 did not charge the eat |
| `009_Bellwort_Cuprum.lua` | bellwort | `targetAteWrapper("bellwort")` |
| `010_Lobelia.lua` | lobelia | `targetAteWrapper("lobelia")` |
| `013_Quicksilver.lua` | - | `proveAffAbsentV3("slickness")` |

`targetAteWrapper` (`affliction_tracking_core/008_V3_Integration.lua:48-52`) calls `onHerbCureV3` and nothing else.

#### Known-cure lines

Some cures print a second line that names what they took: "Archaeon eats a plumbum flake." then "Lucidity returns to the eyes of Archaeon." (`kb/raw/logs/2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt:536-537`). The eat's random cure and the named erase took two afflictions from one eat. Since 2026-11-08 the named line REPLACES the random cure (`ataxia_randomCureV3` / `ataxia_knownCureV3`, 02-api-reference):

| Cure | Recorded by | Named by | Guards |
|------|-------------|----------|--------|
| goldenseal | herbs/002 | herbs/004 (mycalium), third-person_removes/006 (unweavingmind), 001 (mycalium), 003 (shadowmadness) | same person, same kind, 0.5 s, branches unchanged apart from the named one |
| kelp | herbs/003 | third-person_removes/002 (rebbies) | same |
| ginseng | herbs/007, 008 | third-person_removes/004 (unweavingbody) | same |
| smoke | 390 | third-person_removes/005 (unweavingspirit) | same |
| focus | 398 | 399 (lovers, the clarity line after a focus) | same |

A mercury erase must come BEFORE the random-cure wrap: the named line compares the branches with the copy taken just after the random cure. The named trigger still calls `erAff`, or leaves that to one that already does it on the same line. An eat strips anorexia in place, a smoke or focus re-applies its proof (`ataxia_knownCureV3`, `:417`). The first-person forms are in five logs; of the third-person forms only Lucidity is in a log.

`008_Ginseng_with_Flushings` cures nothing itself. With flushings up one eat takes one other affliction and this line follows it, flushings still on the next prompt (5 of 5 first-person rows, e.g. `kb/raw/logs/2026-11-01_claes_runewarden-vs-pariah_loss_Vr.NkCGD.txt:853-857`). It used to charge a second cure and erase a third. It now charges only when 007 did not, which happens when the target was still a part name. `flushingsProc` has no callers.

#### Crescendo (`herbs/006_Ash.lua`)

An ash eat with crescendo up is charged to crescendo alone: 2 or more goes to 1, and 1 to 0. This is measured only with no other ash affliction up (kAQnlFAW, L8LSw7xD). With another ash affliction up, which one the eat takes is unknown (`kb/mechanics/foundations.md` #6), and crescendo-first is an assumption, not a game rule.

#### Bloodroot (`herbs/005_Bloodroot_TEST.lua`), since v4.7.479

The 2026-11-07 Serpent spar found three faults here (`kb/raw/logs/ours/2026-11-07_164635_Saibel.log`).

- **The target's own eat never set her clocks, and anyone else's eat erased our target's afflictions.** A stray `else` closed `if matches[2] == target`. The target's eat still ran the cures above it, but the code after the `else` ran only for a bystander's eat, and it erased our target's paralysis, pyramides or slickness. So the target's eat never set `tBals.plant`, `targetIshere` or `predictBal`, and her 29 magnesium eats in the spar never stopped the TargetOutOfRoom timer. Now the match is `isTargeted(matches[2])` (`005:41`), as in the other herb triggers, so a part-name target (`t sai`) works too. The target's eat sets the plant clock, `targetIshere` and `predictBal("herb", 1.55)` (`005:129-148`). A bystander's eat only turns the line red (`005:151-152`).
- **Each eat took two afflictions.** With V3 on, the V1 erase chain still ran after `onHerbCureV3`. `tAffs.paralysis` was already false by then, so the chain erased slickness too. Now `005:70-87` runs `onHerbCureV3("bloodroot")` alone when `affConfigV3.enabled`. The V1 chain after it runs only with V3 off.
- **A V3 cure left no `-tar` row.** The V1 erase raised "target cured aff", and `onHerbCureV3` raises nothing. Now each bloodroot affliction (`curingTable.bloodroot`, else `curingTableV3.bloodroot`) that V3 had before the eat and holds below 0.01 after it is reported through `ataxia_tarAffFaded` (`005:72-85`). That call also stops a timed clock. A cure that V3 only branched over is a guess, so it is not reported.
- **"Held" (2026-11-08).** Only an affliction the tracker HELD is reported: in `tAffs` or at 30% or more before the eat, the rule of the tree (`curing/002`) and the passive (`008`). An unheld one is taken out with `removeAffV3`, silently. Her eat at `kb/raw/logs/ours/2026-11-07_164635_Saibel.log:1950` met paralysis at 0.22 (not in `tAffs`) and slickness at 0.44, in separate branches: both leave V3, only the slickness is reported. Two held afflictions in separate branches are both reported (row 1483, 0.32 and 0.68).

`onTargetBloodrootV2` still runs on every target eat (`005:55`). Tests: `src_new/tests/test_target_presence_lines.lua` (the "005:" blocks).

## Smoke Trigger

### File: `390_Smoked.lua`

```lua
if isTargeted(matches[2]) then
    -- V2 integration
    if onTargetSmokeV2 then onTargetSmokeV2(matches[2]) end

    -- V3 integration: handle smoke cure (proves asthma absent AND branches on smoke-curable affs)
    if onSmokeCureV3 then
        if ataxia_randomCureV3 then
            ataxia_randomCureV3("smoke", matches[2], onSmokeCureV3)
        else
            onSmokeCureV3()
        end
    end

    -- Rest of existing code...
end
```

The `onSmokeCureV3()` function:
1. Calls `collapseAffAbsentV3("asthma")` - proves asthma is absent
2. Branches on which smoke-curable affliction was removed

## Salve Triggers

### Integration Pattern
Each salve trigger should call `onSalveCureV3()` with the body part after detecting the target applying salve:

```lua
if isTargeted(matches[2]) then
    -- Existing V2 code...
    if onTargetSalveBodyV2 then onTargetSalveBodyV2(matches[2]) end

    -- V3 integration
    if onSalveCureV3 then onSalveCureV3("body") end

    -- Rest of existing code...
end
```

### Integrated Salve Triggers (`triggers/levi_ataxia/for_levi/leviticus/`)

| File | Body Part | V3 Call |
|------|-----------|---------|
| `391_Applied_Body_Skin.lua` | body or skin | `onSalveCureV3("body")` or `("skin")` |
| `392_Applied_Head.lua` | head | `onSalveCureV3("head")` |
| `393_Applied_Torso.lua` | torso | no cure call; `proveAffAbsentV3("slickness", "salve")` only |
| `395_Applied_Limbs.lua` | limbs (arms/legs) | `onSalveCureV3("limbs")` |
| `396_Salves.lua` | generic (any) | `onTargetApplySalveV3()` — slickness proof and salve clock only |

391-395 each prove slickness first. 396 runs after them on the same line (folder order). `onSalveCureV3` stamps `salveChargedAtV3`, and `onTargetApplySalveV3` returns at once when that stamp is under 0.1 s old. Before, 391-395 had already started the salve clock, so 396 read the same application as a second one on salve balance, called it an illusion and left a pending herb guess open. A torso line, or an application 391 and 392 leave to the restoration path, is still charged by 396.

`herbs/013_Quicksilver` proves slickness with no cure clock, and does not touch the salve clock: a berry or a droplet is not on salve balance, and the game prints them inside each other's 0.8 s (`kb/raw/logs/ours/2026-11-03_081532_Tabethys.log:1435/1455`; `kb/raw/logs/ours/2026-10-27_112717_Tabethys.log:1328`).

### Salve Cure Tables

The lists are in the [README](README.md) ("Cure Tables"). Torso has none.

The `onSalveCureV3(salveType)` function:
1. Calls `collapseAffAbsentV3("slickness")` — proves slickness is absent (can't apply if slick)
2. Closes the pending guess of an earlier eat or smoke (`killNegativeConfirmV3`)
3. Branches on which salve-curable affliction was removed from the body part's cure list

## Tree and Focus

`389_Tree(U).lua`: with V3 on, `ataxia_targetTreeV3` (`curing/002:206-243`) lets `onTargetTreeV3` charge the one cure. The proof of paralysis comes first, because it needs the branches as they are. The erase of paralysis after it only catches one that `tAffs` alone held. Since 2026-11-08 one tree reports only afflictions the tracker held.

`398_Focus_(UNK).lua` runs `onTargetFocusV3` through `ataxia_randomCureV3` and counts `serpent.trackCure("focus")`. `399_Focus_(known).lua` only reads the clarity (lovers) line after a focus and undoes 398's random cure, so the focus counts once. It was dead before: 398 had cleared `tBals.focus` a line earlier.

## Target's Paralysis Lines (420)

A line that GIVES paralysis (a curare hit, the bees, a shield into the spine) adds it to every branch. It used to call `onTargetParalysisBlockV3`, a collapse meant for a line that SHOWS paralysis already there, so an ally's curare after a branched eat deleted the branch where slickness was cured and read slickness as gone (`kb/raw/logs/ours/2026-11-03_081532_Tabethys.log:25-28`). 420 raises no second "tar afflicted" when `isAffCertainV3("paralysis")` is already true.

## Party Calls (426, 428, 436)

Every called word goes through `paAff` (`ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:282`): a venom name becomes its affliction (curare -> paralysis) and is added with `tarAffed`, so a herb, a tree or a focus can cure it. The raw word used to go to `tarAffed` and `confirmAffV2`, which put "curare" into V3 as an affliction of its own, while `paAff` wrote the real one to `tAffs` alone.

## Affliction Application Triggers

### Third-Person Hit Triggers
When we see our venom hit the target, apply the affliction:

```lua
-- Example: paralysis hit trigger
if isTargeted(matches[2]) then
    tarAffed("paralysis")

    -- V3 integration
    if applyAffV3 then applyAffV3("paralysis") end
end
```

### DWC Venom Hits
The DWC system has integrated V3 calls in venom hit handlers:

```lua
-- In 001_Infernal_DWC_Vivisect.lua
function infernalDWC.onVenomHit(venom, target)
    local aff = venomToAff[venom]
    if aff and applyAffV3 then
        applyAffV3(aff)
    end
end
```

## Verification Triggers

### Fumble Detection
When target fumbles, proves clumsiness is present:

```lua
-- Fumble trigger
if isTargeted(matches[2]) then
    if collapseAffPresentV3 then collapseAffPresentV3("clumsiness") end
end
```

### Smoke Detection (Asthma Absent)
Already handled in `onSmokeCureV3()`.

### Prone Detection
When target is prone, can collapse certain states:

```lua
if isTargeted(matches[2]) then
    if collapseAffPresentV3 then collapseAffPresentV3("prone") end
end
```

## Adding V3 to New Triggers

### Step 1: Identify the event type
- Herb cure → `onHerbCureV3(herbname)`
- Smoke cure → `onSmokeCureV3()`
- Salve cure → `onSalveCureV3(salveType)` — salveType: "body", "skin", "head", "torso", "limbs"
- Affliction applied → `applyAffV3(affname)`
- Affliction confirmed present → `collapseAffPresentV3(affname)`
- Affliction confirmed absent → `collapseAffAbsentV3(affname)`
- An action that could not have happened with it → `proveAffAbsentV3(affname)`, before any erase
- A cure line that names what a random cure took → `ataxia_randomCureV3` on the first line, `ataxia_knownCureV3` on the named one

### Step 2: Add the call with nil check

```lua
-- Always wrap in nil check for safety
if onHerbCureV3 then onHerbCureV3("kelp") end
```

### Step 3: Place after existing tracking calls

```lua
-- Existing V2 tracking
if onTargetKelpV2 then onTargetKelpV2(matches[2]) end

-- V3 tracking (add after V2)
if onHerbCureV3 then onHerbCureV3("kelp") end
```

## Echo Output

V3 produces consolidated echo output for cure tracking:

```
(LEVI): [V3] bloodroot cured: paralysis
(LEVI): [V3] kelp eaten - branched into 3 states
(LEVI): [V3] smoke cured: slickness
(LEVI): [V3] body salve cured: anorexia
(LEVI): [V3] head salve - branched into 4 states
(LEVI): [V3] Collapsed 2 branches (proved slickness absent)
(LEVI): [V3] Neg-confirm timeout -- branch kept: paralysis, slickness
(LEVI): [V3] ILLUSION: target applied salve while on salve balance
```

The output is consolidated (one line per cure event, not per branch).
