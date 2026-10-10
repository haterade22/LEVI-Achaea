---
topic: class-cures
confidence: mixed (see Confidence column)
sources:
  - kb/raw/help/conditional-afflictions-for-the-achaean-forms.txt   # HELP file; uses OLD skill names (Chivalry, Harmonic)
  - kb/raw/guides/active-and-passive-cures-with-fire-lines.txt      # community guide; source of the lines
code: src_new/triggers/levi_ataxia/for_levi/leviticus/passive_active/
last_verified: 2026-10-10
---

# Class cures: how the target fights back

Herbs and salves are available to everyone. On top of them, each class has its own cures, and
**those are what decide whether a lock holds.** Read this page to know which affliction shuts
a class's extra cure (its "lock affliction") and what that cure looks like on screen.

There are two kinds:
- **Active cures** spend balance or equilibrium, and **one affliction stops each of them**.
- **Passive cures** fire on their own, about every 10 seconds, and **always cure voyria
  first**. Voyria opens a window: stack another affliction while they spend the passive on
  it, then reapply voyria. (Both sources agree on this.)

**How our triggers use these lines.** Each trigger calls `onClassCureV3(specificAffs, numRandom)`
(`affliction_tracking_core/007:1437`). `specificAffs` are removed outright and `numRandom`
more are removed at random through V3's branching. A blocker goes in `specificAffs` because
**seeing the cure proves the blocker was absent**: fitness cannot happen through weariness,
so a fitness line means "no weariness". That inference is only valid when the affliction
blocks the cure **on its own** (see Dragonheal below).

## Active cures

| Class | Cure (skill) | Cures | Blocked by | Line seen | Our trigger -> V3 | Confidence |
|---|---|---|---|---|---|---|
| Alchemist | Salt (Alchemy) | 1 aff | **stupidity** | "X sketches out a symbol in the air with his finger in the shape of a bisected circle." | 014: -stupidity, +1 random | HELP + guide |
| Blademaster | Alleviate | 1 aff | **paralysis** | "As X massages key pressure points, a look of relief comes over X's face as his ailments ease." | 003: -paralysis, +1 random | guide |
| Blademaster | Phoenix | **all** afflictions | **prone** | "Throwing back his head, X shouts out in defiance as blazing flames consume him for a single, glorious instant before dying away." | 010: full V3 reset when not prone | guide |
| Depthswalker | Accelerate (Aeonics) | 1, or 2 boosted (they visibly age) | **recklessness**; the boost is also blocked by **prone** | "A look of relief comes over X as he grows less pale." (+ "X grows older before your eyes." when boosted) | 002: -recklessness, +1 or +2 random | HELP + guide |
| Druid, Sentinel | Might (Metamorphosis) | 1 aff | **prone** | "X lets out a mighty roar." | 009: -prone, +1 random | HELP + guide |
| Knights (HELP names Infernal, Paladin, Runewarden), Monk, Blademaster, Druid, Sentinel | Fitness | **asthma only** | **weariness** | "X draws a deep, measured breath." | 007: -asthma, -weariness (class-agnostic) | HELP + guide |
| Druid, Sylvan | Grove Cure (Groves) | 1 aff | **nothing** | (not captured) | **no trigger** | HELP |
| Dragon | Dragonheal (Dragoncraft) | 3 affs (1 if prone) | **weariness AND recklessness together** | "X lets out a great keening, casting the impurities from her form." | 005: +3 random (1 if prone); removes neither blocker, since only BOTH together block it (fixed v4.7.395) | HELP + guide |
| Magi | Bloodboil (Elementalism) | 1 aff | **haemophilia**, or **both** arms broken | "Perspiration suddenly breaks out on X's forehead." | 004: -haemophilia, +1 random | HELP + guide |
| Jester, Occultist | Fool (Tarot) | 3 affs; can be used on others | **paralysis** or **prone** | "X presses a tarot to his forehead, producing a wan smile." (or "to Y's forehead") | 008: -paralysis, +3 random | HELP + guide |
| Psion | Expunge (Psionics) | impatience first, otherwise a mental | **confusion** | "A slight tightening of the eyes is the only sign X makes that he has made a great effort of will." | 006: -confusion, -impatience if tracked, else a mental from a list | HELP + guide |
| Serpent | Shrugging (Venom) | 1 aff | **weariness** | "X hunches his shoulders and lets out a soft hiss." | 015: -weariness, +1 random | HELP + guide |
| Shaman | Daina / Purification (Spiritlore) | 1 aff | **selarnia** | "A pale mist begins to rise from the skin of X." | 011: -selarnia, +1 random | HELP + guide |
| Fire Lord | Slough | 1 aff | **prone** | "The fiery outer layers of X fall away, turning to dust..." | 016: -prone, +1 random (fixed v4.7.395; it used to erase weariness, and its full-line pattern could not survive the wrap) | HELP |
| Water Lord | Purify | 1 aff | **weariness** | (two lines, see trigger) | 012: -weariness, +1 random | HELP |
| Earth Lord | Eruption | 1 aff | **weariness** | "Magma erupts forth from beneath the plates that cover X." | 017: +1 random (does not remove weariness) | HELP |
| Knights | Rage | varies by line | (not in sources) | "X's eyes flash with rage." | 013 | code only |
| Monk | Continuation | 1 aff | (not in sources) | "X gives a great shout of exertion." | 018: -weariness, +1 random | code only |
| Sylvan | Root | 1 aff | (not in sources) | "X stands suddenly upright, rooted to the earth." | 020: -haemophilia, +1 random | code only |

## Passive cures (about every 10s, voyria first)

| Class | Cure (skill) | Line seen | Our trigger | Confidence |
|---|---|---|---|---|
| Apostate | Syphon (Apostasy); needs the Baalzadeen at 100+ health, and drains it | "A demonic crimson glow emanates from X." | 026 | HELP + guide |
| Bard | Hallelujah | "A song can be heard on the edge of hearing as the air distorts about X." | 025 (Bard only) | HELP + guide |
| Magi | Harmony (Crystalism) | "A soft chiming emanates from X." | 029 (fixed v4.7.395; it was in the Bard-only 025) | HELP + guide |
| Druid, Sylvan | Panacea (Groves); faster in Viridian form | "X is surrounded in a cool, refreshing mist." | 001 | HELP + guide |
| Jester, Occultist | Sun (Tarot) | "The globe of light illuminates X with its brilliance." | 023 | HELP + guide |
| Pariah | Leech; can be cast on someone other than the target | "Something pulses from within the chest of X, and he seems more vital." | 028 | HELP + guide |
| Priest | Healing (Devotion) | "A gentle glow surrounds X." | 024 | HELP + guide |
| Paladin | Healing (Devotion) | "A gentle glow surrounds X." | 024 (fixed v4.7.395; it was Priest-only) | HELP + guide |
| Priest | Angel Care (guardian angel). Does not stack with Healing; it takes priority and cures slightly faster | "The guardian angel of X shimmers and he gives a sigh of relief." | 024 | HELP + guide |
| Runewarden | Dagaz (Runelore) | "A rune like a rising sun upon the ground flares, bathing X with healing magic." | 027 (also handles our own rune) | HELP + guide |
| Air Lord | Susurration | "The tempestuous form of X is cleansed by a purifying breeze." | 022 | HELP + guide |

## Lock affliction by class (derived from the tables above)

What a lock needs **on top of** venomlock, to shut each class's extra cure:

| Shut it with | Classes |
|---|---|
| weariness | Fitness users (Knights, Monk, Blademaster, Druid, Sentinel), Serpent, Water/Earth Lord |
| voyria | every passive: Apostate, Bard, Priest, Paladin, Pariah, Runewarden, Druid/Sylvan, Jester/Occultist, Magi, Air Lord |
| stupidity | Alchemist |
| recklessness | Depthswalker |
| haemophilia | Magi (Bloodboil), Sylvan (Root, per code) |
| confusion | Psion |
| paralysis (already in venomlock) | Blademaster (Alleviate), Jester/Occultist (Fool) |
| prone | Druid/Sentinel (Might), Fire Lord (Slough), Blademaster (Phoenix), Fool, Dragonheal's 3-cure |
| selarnia | Shaman |
| weariness + recklessness together | Dragon |

This is the per-class view. `.claude/classes/lock_types.md` has the established table, and the
two should agree.

## Conflicts

Fixed in v4.7.395: Magi Harmony (now trigger 029), Paladin Healing (024), Dragonheal (005) and
Slough (016). See `src_new/tests/test_class_cure_triggers.lua`.

Still open (also in ../CONFLICTS.md):
- **Grove Cure** (Druid/Sylvan) has no trigger, and it has no blocker, so it can always break a
  lock. Its line still needs to be captured.
