# V3 target affliction tracking: the reference that was in CLAUDE.md

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

### Target Affliction Tracking System (V3 Branching Probability Engine)

V3 is the **single source of truth** for target affliction tracking. It models multiple possible world states simultaneously with probability weights, resolving ambiguous cures via branching and collapsing branches via verification signals.

**Full documentation**: See `.claude/projects/affliction-tracking-v3/` (API, data structure, algorithm, verification signals, performance, commands)

**Quick API reference:**
- `tarAffed(...)` — Add afflictions (sets tAffs + V3 + raises event)
- `erAff(what)` — Remove affliction (clears tAffs + V3 + raises event)
- `haveAff(what)` — Query (routes to V3 at 30% threshold, fallback tAffs during load)
- `getAffProbabilityV3(aff)` — Exact probability 0.0–1.0
- `isAffCertainV3(aff)` — every branch holds it (or it is simple-tracked). Ask this, **never `getAffProbabilityV3(aff) >= 1.0`**: the cache sums the branches, and a certain impatience read 0.99999999999999978 (007:833)
- `proveAffAbsentV3(aff[, cureType])` — a line proved it absent; call it BEFORE any erase (see below)
- `ataxia_targetClass()` — our TARGET's class, lowercase or `""`; the one source for it (see below)
- Always use the public API — never call `applyAffV3()`/`removeAffV3()` directly

**V3 never lowers a burning level above 1 (open since v4.7.420).** `applyAffV3("burning")` adds a level per
application (cap 5); a body mending cures burning only at level 1, and resets the level only when burning is
the one body-salve affliction it can cure; `erAff` leaves the level, and only `resetStatesV3` clears a
higher one. So two applications on one target leave a burning no mending clears, unless a mending between
them cured the first as the only candidate: hence `enamation/001` gives V3 one burning for two ablaze stacks
(`kb/CONFLICTS.md` #32). Drop this note once V3 (`affliction_tracking_core/007`) counts mendings down.

**One target tree is one charge (v4.7.419, every class).** Trigger 389 calls `ataxia_targetTreeV3()`
(`curing/002`), then `tSingleRandom({ noErase = true })`, which only returns its pick: V3 branches the
cure, what it took for certain leaves tAffs too, and one level-1 broken limb (simple-tracked) goes only
when nothing branch-tracked was there. Read `ataxiaTemp.targetTreeAt` only while `tBals.tree` is false.
A tree proves paralysis absent (008:338), so paralysis takes no share of the cure, and with V3 on 389 no longer erases it
before the tree. The tree leaves the Magi burn count alone: burning is no tree cure, and the game's lines own it (`general/025`).
**The tree pool is every tracked affliction the game marks `NoRandomCure: No` (v4.7.479).** `treeCurableAffsV3`
(`affliction_tracking_core/008`) grew from 27 to 77. Burning and the fractures stay out: they come in levels or stacks,
and V3 holds each as one affliction. In the 2026-11-07 Serpent spar Saibel's tree most likely took recklessness (INFERRED, CONFLICTS #65), her only
affliction then by our record, and the old pool kept it for 5 more rounds. `kb/afflictions/database.md` is regenerated from it.
`passiveCurableAffsV3` (008:452) is the same 77 with voyria first; the name is `pacified`, not `pacifism`. An
accepted tree also restarts 389's echoes at 0/4/9/14 s; it returned while one was still pending, so a tree just before
the 14 s echo got none.
**`tBals` is the TARGET's cure balances, and `ataxia_resetTargetBals()` (`016`) is its one reset (2026-11-01, not yet
released).** Do not write `tBals = {...}` by hand. Running timers write to the global table, so a replaced table left
the old target's 13 s tree timer alive, and it marked the new target's tree up early and cleared its timer id. Two of
the five old sites also dropped `salve` and `passive`, so `not tBals.salve` read true. `basher/001`'s load-time seed
keeps the same shape, and `test_target_tree.lua` pins both. The focus knocks (`homunculus/001`, `water_lord/011`) name their
timer as 398 does, so the reset can kill it. Our OWN tree is `ataxiaTemp.usedTree`. Its touch line (`curing_bals/003`) no
longer hangs under `[Curing]: TOUCH TREE` (002), so a touch we send ourselves also sets it. `levilogin()` clears it, because a
dropped link can miss the ready line.
**The target's focus clock (398) starts only for the target's own focus line.** It ran for anyone's, so a
bystander's focus made the gate refuse the target's real cure. Under shadowmadness it waits 4.8 s (measured 4.82-4.99,
n=6); 5 s refused real cures. 398 owns the focus: it charges V3 (through `ataxia_randomCureV3`), counts
`serpent.trackCure("focus")` and starts the clock. 399 only reads the next line (v4.7.479): the clarity line names lovers.
It used to repeat 398's work behind `tBals.focus`, which 398 had just set false, so it never ran.
**The sync (v4.7.420, `affliction_tracking_core/007`):** `syncToOldSystemV3` clears from tAffs, once, every key
V3 held at its last sync and holds nowhere now, and every key whose probability drops from 30% or more to under
30% (tAffs agrees with haveAff). It touches V3's own keys only. `resetStatesV3` forgets the remembered set rather
than clearing tAffs, because its callers write their own defaults first. With V3 on, trigger 318 does not erase a
passive's cure: `onPassiveCureV3` charges it, takes a level-1 limb when no branch can pay, and reports certain
cures through `ataxia_tarAffFaded`. A contradiction in `collapseAffAbsentV3` removes only the disproved one.
**One eat is one cure, and V3 picks it (herbs/005 Bloodroot, v4.7.479).** With V3 on, the V1 erase chain no longer runs
after `onHerbCureV3("bloodroot")`: it read tAffs after V3's copy, so it took a SECOND affliction per eat (the spar's
slickness vanished this way). A cure V3 made certain is reported through `ataxia_tarAffFaded` (the fight log's `-tar`
row), as the passive does; a cure V3 only branched over is a guess and is not reported. **A cure is reported only if the
tracker HELD it** (in tAffs, or at 30% or more, before the cure: tree `curing/002`, passive 008:497, bloodroot 005). What it
only guessed at leaves V3 with `removeAffV3` and no `-tar` row. 005 also had a stray `else`
that made the TARGET's own eat skip her clocks (no `targetIshere`, plant clock or herb prediction; the cure still ran) and made ANY bystander's
eat erase our target's paralysis or slickness. It now matches with `isTargeted`, like the other herb triggers.
**A "not here" refusal is not the target leaving (641, v4.7.479).** The game gives the same three lines for any command
that names someone absent, ours included. In the spar the Serpent round's `order adder kill <target>` (no adder out)
drew them, and each one started the 1.4 s TargetOutOfRoom timer: 7 erasing ticks and 2 `resetStatesV3` while she stood
in the room and cured. 641 now changes nothing while `ataxia.playersHere` lists the target (case-blind; a listed name may
start with the target's, never the reverse: with target Kaiden and only Kai listed, Kaiden is gone). GMCP RemovePlayer still
starts the timer when the target leaves. The reading is wrong for a target GMCP lists but our commands cannot see (a hidden
player, `kb/CONFLICTS.md` #38).
**Masochism's self-harm lines (433, v4.7.479):** "rams <his|her> fist into <his|her> jaw", "drives a clenched fist into
<his|her> gut" and "uses <his|her> right foot to stomp on <his|her> left as hard as possible", beside the revulsion line.
Before, 433 read the jaw line only with "her" and not the other two: 3 of the spar's 5 lines recorded nothing.
**Nothing unfolds a cure (v4.7.479).** `onNegativeConfirmExpiredV3` (007:1488) only echoes. The 1.3/2.0/2.5 s windows still
exist and a second cure action still kills them (`killNegativeConfirmV3`), but expiry changes no branch. It used to put the
cured candidate back, so a branched eat had cured nothing. An eat, smoke or apply line is a fact: it cured one of the
candidates. The herb window (1.3 s) was also shorter than the target's fastest next eat in the spar (1.506 s), and replaying
that spar unfolded 11 times before this and never after. A later proof settles the branches instead.
**Pruning never empties the tracker, and the cap is 300 (v4.7.479).** The 1% floor (`minProbability`) only trims: when every
branch is under it, or more than 10% of the weight is, `pruneStatesV3` keeps them all and the cap makes room (007:931-934). It
fell back to the empty state, so Dragonheal or a third tree over ten afflictions (C(10,3) = 120 branches at 1/120) wiped every
target affliction, a certain pinshot among them, from V3 and tAffs. With only "every branch" as the test, an aurum eat right after
that Dragonheal cut 59% of the weight and read asthma 0.00 where it is 0.38. A passive trims back to the cap between its cures
(008, `onPassiveCureV3`), because every branch expands each round: a second Dragonheal over 14 + 4 afflictions took about
0.5 s in plain Lua 5.1, in one trigger. That trim only runs past the cap, so the floor does not cut a board mid-expansion when it fits.
`affConfigV3.maxStates = 300` (007:78) is assigned outside the `X = X or {...}` table, so a reload in a running session takes
it. Past the cap `table.sort` orders equal branches arbitrarily, so a board over 300 branches can still read uneven.
**A line that proves an affliction absent calls `proveAffAbsentV3(aff[, cureType])` BEFORE any erase (007:758, v4.7.479).**
`erAff` strips it inside each branch, and a branch the line ruled out then keeps its weight. This drops those branches. Where
every branch holds it, it only comes off, with no WARNING. With `cureType` it does nothing while that cure clock runs: the
tracker calls such a line an illusion. Users: the tree (paralysis), the five salve triggers 391/392/393/395/396 and `herbs/013`
(slickness); the focus collapses impatience (008:396). `herbs/013` is not on salve balance, so it neither reads nor starts the
salve clock. `salveChargedAtV3` (007:701) stops 396 calling the application 391, 392 or 395 just charged an illusion. An eat
still strips anorexia inside each branch (open).
**A named cure line replaces the random one: `ataxia_randomCureV3` and `ataxia_knownCureV3` (`ataxia/001`:384, :401, v4.7.479).**
Some cures print a second line that names what they took, and one eat then took two afflictions. Wrap the line that charges the
random cure in `ataxia_randomCureV3(kind, name, cure)`, and call `ataxia_knownCureV3(kind, name, aff)` on the naming line before
`erAff`. `kind` is a herb, "smoke" or "focus". It restores the branches from before the random cure, re-applies what the action
proved (anorexia for an eat, asthma for a smoke, impatience for a focus) and takes out `aff`. It acts only for the same person
and kind, inside `ataxia_KNOWN_CURE_WINDOW` (0.5 s), with the branches unchanged apart from `aff`, so a hit that landed between
the two lines is never undone. A mercury erase goes BEFORE the wrap (herbs/002, 003, 007): the naming line compares against the
copy taken after the cure. Used by herbs/002, 003, 004, 007 and 008, smoke 390, focus 398 and 399, and `third-person_removes/001-006`. `herbs/008`
charges the eat only when 007 did not, so one flushings eat is one removal. Only the Lucidity line is in any log we hold.
**A line that GIVES an affliction adds it; only a symptom collapses (420, v4.7.479).** 420 called the paralysis-symptom collapse on
lines that give paralysis, so it deleted the branch where a bloodroot eat had cured slickness. Now it adds paralysis to every
branch, with no second event when `isAffCertainV3` says it is already there. Party calls (426, 428, 436) go through `paAff`
(`ataxia/001`:282), which maps a venom word to its affliction and calls `tarAffed`, so a cure can take them.
**`isTargeted` (016:250) completes only a part name (v4.7.479).** An exact case-blind match is the target. A LONGER name on a line
completes a target that is still part of a name (`t sai`). Once GMCP lists the target exactly (`listedHere`) or a line has named
or completed it (`fullTargetName`), it is a full name and stays. A SHORTER name on a line is someone else. Before, target Kaiden
and "Kai eats ..." charged Kaiden and made Kai the target. **Presence checks are a separate rule:** `switchTarget` (016:98),
`tprio.switchTo` (`mage/006`), 638 and 641 ask whether a listed name starts with the target's, case-blind, never the reverse.
`switchTarget` and `tprio.switchTo` also stop `TargetOutOfRoom`, whose ticks erased what we landed on the new target.
**Every departure trigger gates its presence and chase state on the target, not only its echo (634, 637, 638, 640).** 640 opened
the chase and started `TargetOutOfRoom` on anyone's flight. 638's line names no one, so it acts only when GMCP no longer lists
the target, on the line and again after the packet (`tempTimer(0)`). 638 and 641 each hold a copy of the listed-here compare.
**The class our DEFENCES answer is `ataxia_facingClass()` (same file): whoever hit us last in this fight, else the target's class
(`kb/CONFLICTS.md` Resolved, was #75). A new defence reads it; a new offence reads `ataxia_targetClass()`.**
**Our target's class is `ataxia_targetClass()` (`ataxia/007_Pariah_things.lua`:68, v4.7.479): the one source for Serpent and
Pariah.** It reads the NDB entry first (`classDetect.setAttackerClass`, `onTargetChanged` and the API lookup all write it), then
classDetect's class only when that attacker IS the target. `classDetect.state.attackerClass` alone is whoever last hit US, and
it is nil whenever two or more attackers are tracked, in or out of a party (`class_detect/001`:351-354). `ataxia_wantClumsiness`
(:110) defaults to it. The global `tarClass` is gone: nothing ever assigned it, so the gate always said yes and the class list
never ran before v4.7.479. Tests stub the class (`ataxiaNDB_getClass`), not the gate. The anti-class defences key on our
target's NDB class too, not on who attacks us (open, `Algedonic.ApplySwaps`).
**Also since v4.7.479:** a new target has no coating assumed (`sileris`/`fangbarrier` false at 016:531-532; 442 and 707 teach it),
`dazzled` is the game's key (017; `priest/003` passes it), and the six `[V3] ILLUSION:` refusals print through `illusionEcho` (008:76).
