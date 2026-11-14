---
topic: class-cures
confidence: mixed (see Confidence column)
sources:
  - kb/raw/help/conditional-afflictions-for-the-achaean-forms.txt   # HELP file; uses OLD skill names (Chivalry, Harmonic)
  - kb/raw/guides/active-and-passive-cures-with-fire-lines.txt      # community guide; source of the lines
  - kb/raw/players/fitness-2026-11-01.txt                           # the user: fitness needs balance and eq
  - kb/raw/logs/                                                    # Fitness in detail: 11 fires
  - kb/raw/live/mnemosyne-sprightly-permanent-clumsiness_2026-11-13.txt  # a boon's permanent affliction
code: src_new/triggers/levi_ataxia/for_levi/leviticus/passive_active/
last_verified: 2026-11-13
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
| Serpent | Shrugging (Venom) | 1 aff | **weariness** | "X hunches his shoulders and lets out a soft hiss." Ours: "Focusing inward, you purge your body of afflictions.", then the cured affliction's own line: it took confusion in the one capture (`raw/live/shrugging_2026-11-08.txt`) | 015: -weariness, +1 random. Ours: `curing_bals/006`:42 and `serpent/008_Shruggin`:34 | HELP + guide; our own line live, the user's paste, n=1 |
| Shaman | Daina / Purification (Spiritlore) | 1 aff | **selarnia** | "A pale mist begins to rise from the skin of X." | 011: -selarnia, +1 random | HELP + guide |
| Fire Lord | Slough | 1 aff | **prone** | "The fiery outer layers of X fall away, turning to dust..." | 016: -prone, +1 random (fixed v4.7.395; it used to erase weariness, and its full-line pattern could not survive the wrap) | HELP |
| Water Lord | Purify | 1 aff | **weariness** | (two lines, see trigger) | 012: -weariness, +1 random | HELP |
| Earth Lord | Eruption | 1 aff | **weariness** | "Magma erupts forth from beneath the plates that cover X." | 017: +1 random (does not remove weariness) | HELP |
| Knights | Rage | varies by line | (not in sources) | "X's eyes flash with rage." | 013 | code only |
| Monk | Continuation | 1 aff | (not in sources) | "X gives a great shout of exertion." | 018: -weariness, +1 random | code only |
| Sylvan | Root | 1 aff | (not in sources) | "X stands suddenly upright, rooted to the earth." | 020: -haemophilia, +1 random | code only |

### Fitness in detail (2026-11-01)

| Fact | Value | Confidence |
|---|---|---|
| Needs | balance and equilibrium, as the user said. The wiki lists balance only | CONFIRMED (live), n=1 on our seat: with equilibrium down, `fitness` ran only when equilibrium returned, 3.3 s later (`raw/live/probes_2026-11-01.txt`). 11 logged fires agree |
| With no asthma | it still runs and spends balance: `You are already quite fit.`, then `Balance used: 2.8s.` | CONFIRMED (live), n=1. A stray FITNESS costs 2.8 s of balance. Whether it starts the lockout is not known |
| Spends | balance only: 2.8 s printed, against 3.00 stated on the wiki. Our seat: printed 2.8, our stopwatch 2.785 (`raw/live/seebalances_2026-11-01.txt`) | CONFIRMED (live), n=7 |
| Lockout | about 10 s; earliest 9.06 s | CONFIRMED (live), n=8 pairs. Our seat: 9.97, 9.81, 9.06. The other 5 have 1 s stamps and all read 10 |
| While paralysed | works in the logs; the user (2026-11-13) and the game's record (`Useable paralysed: No`, `raw/abadmin/discipline_fitness_520.txt`) say it does not | CONFLICT, `../CONFLICTS.md` #82. 3 FITNESS fires under real paralysis: `raw/logs/2026-10-11_mystor_shikudo-vs-apostate_win_LcJC-rJ5.txt`:3811-3816 (the game refused his other commands with "You are paralysed and unable to do that." in the same batch), `2026-11-01_claes_runewarden-vs-apostate_loss_LcJC-rJ5.txt`:744-760, `2026-11-01_elmer_shikudo-vs-runewarden_win_2N1HTSWZ.txt`:4616-4617. The code still lets it fire |
| Under weariness | refused, and the lockout clock keeps running | CONFIRMED (live) |

**Equilibrium evidence.** The logs hold 11 fires. 5 came with equilibrium up, 5 right after it returned, 1
is not visible, and 0 came with it visibly down. The clearest is
`raw/logs/2026-11-01_elmer_shikudo-vs-runewarden_win_2N1HTSWZ.txt`:4611-4618: the prompt flags read `-xd-` with
asthma up, equilibrium returns, the flags read `-exd-`, `fitness` is typed, and it fires. Each client
may gate this on its own, so the logs alone do not prove a game rule. The live probe does, because our send went out
with equilibrium down and the game held it.

**Lines.**
- Fire: `You inhale deeply, purging yourself of your asthmatic condition.`
- Lockout over: `You may purge your lungs once again.`
- Tried during the lockout: `You may not purge your lungs again as of this time.`
- Used with no asthma: `You are already quite fit.`
- Short of balance, with auto-queue on: `You must regain balance first.`, then
  `fitness was added to your balance queue.` It runs on recovery (`raw/logs/ours/2026-10-27_112717_Tabethys.log`:12659-12676).

**Code.** `ataxia_activeCureHeldForEq` (`can(x)/003_Lock_breakers.lua`:113) holds our send while equilibrium is down, for FITNESS and, since v4.7.480, SHRUGGING, because the
game's auto-queue would otherwise fire it later, even with the asthma gone. It tests before the 1.5 s throttle, so the
send goes out on the prompt where equilibrium returns. With balance down, the send still goes out and the auto-queue
holds it (`raw/logs/ours/2026-10-27_112717_Tabethys.log`:12659-12676). How the game treats a shrug sent with equilibrium down is not measured; the user approved the hold ("shrugging yes", 2026-11-08).

"Too weary" prints during the lockout as well, so that refusal says nothing about the clock.
`abilities.json` has no lockout: its `cooldown` field means balance spent.

## Our own class cure while bashing (v4.7.484)

The user, 2026-11-09: "we should be using our class active cures if we have 3 or more afflictions
on us especially if we have miracle boon." The user chose bashing only, and 3 with or without the
boon. PvP keeps the lock-only rule. Code: `ataxia_loadCure*` in `can(x)/003_Lock_breakers.lua`, and
the round in `ataxiaBasher_assembleAttack` (`basher/001`).

**Miracle** (uncommon): "Your class-related active curing ability now cures an additional
affliction." (`mnemosyne/010_Boon_Seed.lua`). It needs no code. The game cures the extra affliction,
and GMCP reports it. Whether FITNESS counts as that ability is not known.

**What counts toward the 3:** our afflictions that are in `treeCurableAffsV3`. ASSUMED: a class cure
takes from the same pool as the tree. The game's flag `NoRandomCure` supports this
([database.md](database.md)), so prone, laceratedthroat and a damaged limb do not count. The pool
leaves out 13 afflictions that have no such flag, among them the stacking fractures, so the count
can read low. That leaves the cure idle. It does not waste it.

**A boon's permanent affliction does not count (v4.7.495).** The user, 2026-11-13, with Sprightly
("Your dexterity is increased by 5, but you suffer permanent clumsiness."): "When we take boons that
give permanent afflictions we are not immune from the system needs to account for that" and "We dont
need to tree or use actives if we have this affliction on us". What the log shows
([raw/live/mnemosyne-sprightly-permanent-clumsiness_2026-11-13.txt](../raw/live/mnemosyne-sprightly-permanent-clumsiness_2026-11-13.txt)):

- CONFIRMED: the class cure fired at "3 afflictions" on `[ [ IMP clu PAR ]]`, with the permanent
  clumsiness as one of the 3 (row 171). Magnesium then took the paralysis, and the shrug took the
  impatience. The same happened on `crackedribs (1) clu PAR sen` (row 148).
- CONFIRMED: our blackout tree (`aconfig treeblackout`) went three times with only blackout and the
  clumsiness known, and each time printed "Your tree of life tattoo glows faintly for a moment then
  fades, leaving you unchanged." (rows 32, 64, 79). Blackout's only cure is time
  ([database.md](database.md)). The prompt showed `?` or `??` (afflictions we cannot see) at those
  times, and the tree still took nothing.
- CONFIRMED: clumsiness stayed up for the whole run after cures and eats, and the game still says
  "Clumsiness gets the better of you and you fumble the attack, wasting your battlerage." (row 75).
- INFERRED: the last 3,220 lines of the buffer hold no kelp eat, with the clumsiness up the whole
  time, so SSC seems to know the affliction is permanent. The package changes no SSC priority for it.

The code (`mnemosyne/004_Parsers.lua`): `M._permanentAffsFrom(desc)` reads the affliction names after
the word "permanent" ("permanent dehydration and tenderskin" gives two). `M.runPermanentAffs()` reads
this run's claims, less what a held boon makes us immune to (Poindexter's permanent dizziness costs
nothing with Sure-Footed). `ataxia_permanentAff(aff)` gives the boon's name, and nil outside the
tower. A cost clause that does not say "permanent" does not count: Sohtanate's Suffering names
stupidity, and stupidity still cures. Its readers:

- `ataxia_randomCurableCount()` (`can(x)/003`) skips a permanent affliction, so the user's board is 2.
- FITNESS and the lock-breaker's asthma test (`ataxia_curableAffed("asthma")`) skip a permanent asthma.
- `ataxia_treeOnlyPermanent()` (`can(x)/003`) is true when every tree-curable affliction we know of,
  blackout aside, is permanent and at least one is up. The blackout tree (`004_Aff_gains_losses`) and
  the fire elemental's mask trigger (`unknown_checks/005_FIRE_SCALD`) do not touch the tree then.
  With nothing else up, the blackout tree still goes, as before: that case is not in any log.
- A Mnemosyne recovery (`S._blockingAffs`, `009_Swarm_Tactics`) does not wait for it.

The lock checks still count a permanent affliction: a channel that a boon closes stays closed.

| Class | Sent | Extra condition |
|---|---|---|
| Serpent | `shrugging` | equilibrium up (the v4.7.480 hold) |
| Alchemist | `educe salt` | 200 mana (wiki) |
| Depthswalker | `chrono accelerate boost` | plain `chrono accelerate` while prone or above `ataxiaBasher.dwAgeCap` (400). CONFIRMED: a boost adds 340 years (`raw/logs/2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt`:2094) |
| Magi | `cast bloodboil` | 75 mana; `magiBashing` owns the round, so its battlerage rides |
| Shaman | `invoke purification` | |
| Jester, Occultist | `fling fool at me` | not prone (HELP) |
| Dragon | `dragonheal` | |
| Earth Lord | `terran eruption` | |
| Knights, Monk, Blademaster, Druid, Sentinel | `fitness` | **asthma up**, equilibrium up. FITNESS cures nothing else |

**Not wired.** Each needs our first-person lines captured, or we cannot see the cure go out:
Blademaster ALLEVIATE (2.75 s equilibrium, 75 mana), Druid and Sentinel MIGHT (4.5 s equilibrium),
Druid and Sylvan GROVE CURE (5 s equilibrium), Psion EXPUNGE (3 s equilibrium). Psion has no row in
`ACTIVE_CURE_BLOCKERS`, so `ataxia_canActive` is false and EXPUNGE does not fire for a lock either.

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

## Third-party cure lines need skill access (since 2026-10-23)

**CONFIRMED (announcement)**, Misc 232 in `kb/raw/announcements/classleads_2026-10-23.txt`:
"Third party affliction cures now only show to those who have relevant skill access where
appropriate." It covers 25 afflictions: bloodfire, coldfate, conflagration, constricted,
degenerate, earworm, enmeshed, guilt, hatred, horror, inquisition, kkractlebrand, latched,
lovers, mindravaged, mycalium, petrified, rebbies, reeling, retribution, shadowmadness, snared,
tension, all unweavings, and whisperingmadness. ASSUMED: "relevant skill access" means the skill
that gives the affliction.

Why it matters: a cure line is how we see these afflictions leave a TARGET. Without the giver's
skill we no longer see it, so an affliction that came in by party relay can stay in V3 forever.
- Removal triggers that now go silent without the skill: `third-person_removes/001-007`
  (mycalium, rebbies, shadowmadness, the three unweavings, guilt), `other_things_fading/002`,
  `004`, `008` (lovers, mindravaged, horror stack-down), `herbs/016` (earworm, retribution),
  `606_Petrify_Cured` (petrified).
- Still seen: removals read from the target's own herb and salve lines (goldenseal, lobelia,
  bellwort, the applies), and inquisition's own 20 s timer.
- No backstop: none of the 25 has an entry in `ataxia_TARGET_AFF_SECONDS`.

Open as kb/CONFLICTS.md #43. Details: [../changes/2026-10-23_classleads.md](../changes/2026-10-23_classleads.md).

## Conflicts

Fixed in v4.7.395: Magi Harmony (now trigger 029), Paladin Healing (024), Dragonheal (005) and
Slough (016). See `src_new/tests/test_class_cure_triggers.lua`.

Still open (also in ../CONFLICTS.md):
- **Grove Cure** (Druid/Sylvan) has no trigger, and it has no blocker, so it can always break a
  lock. Its line still needs to be captured.
