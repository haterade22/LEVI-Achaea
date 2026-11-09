---
topic: foundations
confidence: mixed (tagged per claim)
sources:
  - kb/raw/logs/          # 31 text logs and 4 of our own recordings
  - kb/classes/abilities.json
  - kb/afflictions/cure-channels.md
  - kb/afflictions/class-cures.md
code:
  - src_new/scripts/levi_ataxia/levi/ataxia/can(x)/003_Lock_breakers.lua
  - src_new/scripts/levi_ataxia/levi/levi_scripts/algedonic_defense_1.0/001_Anti_Priorities.lua
last_verified: 2026-11-01
---

# Foundations: how a fight works

This page is the model to hold when you write offence, curing or a simulator. It comes from a study of
all logs on 2026-11-01. An adversarial reviewer tried to refute the main claims against the raw lines. The
claims that failed are listed in [Refuted](#refuted-do-not-rebuild-on-these), so that nobody rebuilds them.

**Tags.** MEASURED: counted from log rows. READ: stated in a file. INFERRED: a reasoned reading, not proven.
Nothing here was run as a live test unless it says so. Every "last exit" below is a counterfactual.

**Log keys.** All files are in `kb/raw/logs/`. A citation such as `Z5:4360` is a row in that file.

| Key | File contains | Row base |
|---|---|---|
| S | `2026-08-19_..._Sentinel.txt` | 1 |
| T54, Eve, LcJ | Mystor against a Shaman, a Depthswalker, an Apostate (ids `t54WWU6b`, `EveP2TVe`, `LcJC-rJ5`) | 1 |
| MK, INF, FL | `ours/2026-10-27_112717_Tabethys.log`, `ours/2026-10-27_135412_Tabethys.log`; FL is `ours/2026-11-07_164635_Saibel.log`, our Serpent spar (our seat only, added 2026-11-07) | 1 |
| az, Vr, WK, 4c, Cx, s98, Lc, WO, J7 | Claes: `azbErKcK`, `Vr.NkCGD`, `WKuEakBZ`, `4c_SeyaA`, `CxxKSMq`, `s98kPGv6`, `2026-11-01_..._LcJC-rJ5`, `WO7tC3kL`, `J7Xnr_Jg` | 0 |
| X, K, L | Nikita: `X8pRorzR`, `kAQnlFAW`, `L8LSw7xD` | 0 |
| T, A, g, Z5 | Elmer: `2N1HTSWZ`, `3ys7NuHA`, `g-lD00-h`, `Z5cyffxx` | 0 |
| Ow, JD, uW | An Earth Lord: `OwkA-G99`, `JDvzR7j7`, `uW_VbgR` | 0 |

## The model

1. **A fight is many fixed clocks running side by side.** Curing runs beside offence. See [Clocks](#clocks).
   Clock lengths agree across players to about 0.1 s. MEASURED.
2. **A channel shuts by an affliction or by its own clock.** Anorexia blocks eat, slickness blocks salve,
   asthma blocks smoke, impatience blocks focus, paralysis blocks tree, weariness blocks FITNESS
   ([cure-channels](../afflictions/cure-channels.md)). READ.
3. **A lock is reachability: can any open channel cure a blocker?** All keys shut, by blocker or by clock: fatal
   2 of 2 (S:2413, T54:2899). One key open: survived 3 of 3 (S:2027, T54:354, T54:2102). MEASURED, small sample.
   One key collapses a lock fast, because SSC runs every open channel at once: 0.073 s at S:2106-2117.
4. **A kill route is conditions that are true at the same time.** Health at death was 90-99% in several fights
   where the prompt shows true health (Vr, WK, 4c, s98). MEASURED. Routes come in four families: lock, limb,
   timed, and threshold. [kill-paths](../../docs/kill-paths.md) lists them with their tells.
5. **Attack inflow beats the eat clock, so the attacker chooses what your eats go on.** The Sentinel log ate 27
   magnesium and no weariness cure in the last rebuild. Seurimas's stab gap of 1.85 s against an eat gap of 1.66 s
   leaves about one spare eat in nine (Z5). MEASURED.
6. **Priority steers the herb. It only partly steers the affliction inside that herb.** Asthma at priority 1
   won aurum 4 of 7. With asthma and weariness both up, aurum took asthma 16, weariness 8, clumsiness 3 (n=27).
   MEASURED. The cure's choice inside a herb is unknown.
7. **Our costs follow the stated cost, times a multiplier for our character.** Error about +-0.15 s. See
   [Stated against observed](#stated-against-observed). MEASURED. This has one known exception, Engage (CONFLICTS #55), and few
   real tests, because a character with one stated ability fits its multiplier by construction.
8. **An opponent's stated cost does not predict their next attack. Measure it per ability.** A clock gives the
   EARLIEST action and never says when. Outside +-0.25 s of the median, by the gap rule in [clocks.md](clocks.md): DSTAB 23%,
   BITE 10%, FLAY 19%, Stare 36% (its `Within 0.25 of median` column holds the current figures). MEASURED.
9. **Attackers run a rhythm and choose inside it.** Most strikes land in the same packet as the balance line:
   reaps 83 of 115, slices 66 of 133. So predict WHEN from the last line and WHAT from the board. MEASURED.
10. **Defenders answer the last hit, not the plan, and pre-emption works.** Two defenders salved legs while a parked
    head waited (T, A). A pre-emptive head salve at about 88% cost the attacker 67 s (A, t76.5). Curing
    hypochondria inside its window prevented the impatience 3 of 3 (Z5). MEASURED, two fights each.
11. **Some suppliers are timed and hidden, with no attacker line.** See [Timed effects](#timed-effects).
12. **Leaving the room resets the race.** Latency came 10.3 s later when the victim left first (WK against Vr).
    Nikita made 8 re-engagements in one fight (X). MEASURED. A failed leave costs 0.85-0.98 s of balance (MK).
13. **Milliseconds are not the prize.** The server queue fires within 2 ms of recovery (median, n=57). Round trip is
    about 0.11 s. Margins under 0.5 s are unresolved in these logs. The value is in WHICH decision. MEASURED.
14. **The round that fires is often not the round we chose.** See
    [balance-and-queueing](balance-and-queueing.md). Fixing delivery comes before any new decision.

## Clocks

**The current numbers are in [clocks.md](clocks.md):** GENERATED from every log by `tools/kb_timing.py`, by logger, with n, method, filed date and
version, and a usable or not verdict. This table is the study's summary. The generated medians agree with it to within 0.1 s, except
FITNESS: 9.81 on stamps of 0.01 s or better (n=5) and 10 on 1 s stamps (n=5).

Printed timers start at the action line, so latency does not change these lengths on average. Noise is additive:
p90-p10 is 0.18-0.27 s whether the clock is 1.5 s or 14 s. MEASURED across four players' systems.

| Channel | Median s | n | Notes |
|---|---|---|---|
| Eat | 1.50 | 902 | Herbs and minerals. Excludes moss, pear, quartz |
| Smoke (lungs) | 1.48 | 233 | **Pear and calcite spend this one** ([cure-channels](../afflictions/cure-channels.md)) |
| Salve, short | 0.9 | 60 | Mending, epidermal, caloric |
| Salve, restoration | 4.0 | 21 | The limb cure lands at the end of this clock |
| Focus | 2.42 | 97 | 4.82-4.99 with shadowmadness (n=6) |
| Sip | 4.40 | 281 | Skull fractures add about 1.35 s (n=4 against 2) |
| Moss, potash | 5.9 | 104 | A clock of its own: Saibel's 4 potash eats in FL ignored her eat clock (CONFLICTS, Resolved 2026-11-07, was #11) |
| Tree | 13.95 | 124 | |
| FITNESS lockout | about 10 | 10 pairs | 9.06-10 on 10 pairs, unresolved under 0.5 s. It keeps running under weariness |
| Immunity sip | 7.3-7.7 | 2 | Separate from the health sip |
| Dagaz rune (passive) | 15.03 | 59 ticks | One rune. `locks.md` says "about 10 s" |
| Humour | 1.55 | 41 | |

**Opponents share these clocks.** From third-person lines, their floor is the clock + 0.03-0.1 s, and under pressure
the clock + 0.13-0.2 s. Typical gaps are longer: herb 1.69, tree 15.35. A clock therefore gives the earliest cure.

**Visible from our seat:** every eat, tree, focus, smoke, salve and sip by another person prints a line.
**Not visible:** what a herb took, the salve type (restoration and mending print the same line), failed sends, and
the opponent's balance.

## Stated against observed

`kb/classes/abilities.json` holds stated values in a field named `cooldown`, which mostly means balance spent. By the rule in
[clocks.md](clocks.md), 1,237 rows read as one number on one balance: 1,052 plain balance or equilibrium, 145 another named balance, and 40 with
a symbol, channels or unique suffix. It has real holes: Shikudo 0 of 31, Kaido 13 of 33. It has no recharge lockouts. READ and MEASURED.

The game prints the true cost to the player who spends it: `Balance used: 2.1s.` and `Equilibrium used: 3.40s.` These
are game text, enabled by `CONFIG SEEBALANCES` (CONFIRMED live, `raw/live/seebalances_2026-11-01.txt`). It was off for us
until 2026-11-01, so our earlier logs do not show them. Since v4.7.470, `aconfig seebalances on` sends it at every login (off by default, until the
extra line is shown to break nothing). On our seat FITNESS printed 2.8 s, and our own stopwatch read
2.785 s (n=1). Printed cost against
the measured time to recovery: median -0.02 s, 89% within +-0.15 s (balance, n=264). MEASURED. **Our Serpent seat (FL, 2026-11-07) does not show this from the cost line:** 21 of 52 cost lines are within +-0.15 s timed from the cost line, and 50 of 52 timed from the round's first reply (DSTAB 1.634 and 1.75 against a printed 1.8). Each cost line came in the round's second packet, about 0.09 s after the first reply. Which time the server counts is open ([CONFLICTS](../CONFLICTS.md) #69).

| Own cost | Stated | Printed | Ratio |
|---|---|---|---|
| FITNESS | 3.00 | 2.8 | 0.93 |
| Truewrack | 2.80 | 2.6 | 0.93 |
| Shield tattoo (equilibrium) | none listed | 4.00, 3.40, 2.89 | 1, 0.85, 0.72 by character and form |
| Homunculus attack | 3.00 | 2.55 | 0.85 |
| Pommelstrike, 1 s stamps | 1.50 | 1.1 | about 0.73 |
| Engage (Claes) | 2.50 | 2.00, 29 of 29 | 0.80, **not his k** (CONFLICTS #55) |

So **a cost = stated x k**, where k depends on the character, the channel and sometimes the form. Rain form adds
x0.85 on equilibrium. Weariness, asthma, clumsiness and paralysis did not change a reap's cost. MEASURED. **Engage is an exception:** Claes prints
the shield at 4.00 and Concentrate at 2.00, which Elmer's k of 0.85 puts at their base, so Claes's k is 1.00 and Engage should read 2.50. This table
is a small part of the printed costs: [clocks.md](clocks.md) says how much it covers, and the Shikudo combos are not in it. Our Serpent's own costs (FL: DSTAB 1.8, BITE 1.7, IMPULSE 1.44 of equilibrium, FLAY 1.7, PINSHOT 1.8, printed) are in clocks.md's Own costs table, and an IMPULSE with a venom spends balance as well as equilibrium (CONFLICTS #68).

| Opponent's ability | Stated | Gap to next attack, median | n |
|---|---|---|---|
| Serpent DSTAB | 2.80 | 1.83 (Thato 1.81, Archaeon 1.82, Seurimas 1.83, Kalys 1.85) | 141 |
| Serpent BITE | 4.00 | 1.70 | 18 |
| Serpent FLAY | 2.00 | 1.64-1.70 | 65 |
| Apostate STARE | 1.90 | 2.04 | 129 |

The cause of the Serpent gap is not visible from our seat. A speed effect or a stale wiki value could both explain it.
[clocks.md](clocks.md) regenerates this table with one written rule for what a gap is, so its n differ from these. It adds p10 and min. **p10 is
not a floor:** about 10% of gaps come sooner. DSTAB reads p10 1.73 and min 1.54, and that min is a real gap: the prompts on both sides of az:315 and
az:350 put it at 1.539-1.557 s.

## Timed effects

| Effect | Delay | Evidence |
|---|---|---|
| Rebounding after the smoke | 8.51 s median, p10 8.44, p90 8.58 | MEASURED, n=67 (`clocks.json` now: 8.49, n=460). The smoke is skullcap or malachite: 48 of 49 such smokes in the four Serpent logs brought the aura 7.59-8.59 s later (az 573 is the firefly pipe's own smoke line, [CONFLICTS](../CONFLICTS.md) #66); no other item came first (rule `defence.rebounding.smoke`, [sim/rules.md](../sim/rules.md)) |
| Infest relapses, no attacker line | 5.34-6.69 s, then 11.02-12.78 s | MEASURED, n=5, n=4. Supplied a plague in Vr, WK, 4c |
| Hypochondria chain | nausea +3.10-3.13, lethargy +4.66-6.23, impatience +9.23-9.32 s (medians per log; Z5's lethargy 4.66 is the median of +3.08 and +6.24); pooled 3.12, 6.20, 9.31 (rule `timed.hypochondria`) | MEASURED in three logs: az (n=4, 4, 3), Z5 (2, 2, 1), X (2, 1, 1). g has 2 gains and no chain step. One Z5 lethargy came at +3.08, and az has a late step at +9.30 and +12.42 ([sim/events.md](../sim/events.md), Suppliers) |
| Sileris or quicksilver hardens after the apply | 10.00 s median, p10 9.95, p90 10.04 (9.75-10.12) | MEASURED, n=43 in the four Serpent logs (rule `defence.sileris.harden`). 6 of 49 applies printed no hardening line; a bite or FLAY before the 10 s mark does not explain it (36 of the 43 that hardened took one too). Slickness at the mark does: none of the 43 had it on, 5 of the 6 did (rule `defence.sileris.slickness_harden`). Slickness that lands also strips a hardened coating: 8 of 8 (rule `defence.sileris.slickness`) |
| Fratricide relapse | 2.0-2.9 s | MEASURED, n=7 in X, 5 in Z5 |
| Anorexia after SNAP | 9.0-11.0 s | MEASURED, 7 of 7, one player (az). The suggested-anorexia line comes after no SNAP in the other three logs (11 SNAPs). It is what that Serpent suggested, not a property of SNAP ([CONFLICTS](../CONFLICTS.md) #61) |
| Serpent's snake bite | about every 8.1 s | MEASURED in all four logs: medians 8.07, 8.09, 8.09, 8.19 s (n=8, 20, 8, 24; az, Z5, g, X). Z5's pet is a saw-scaled viper, X's a rattlesnake ([sim/events.md](../sim/events.md)) |
| Air Lord pressure gain | 1 + manaleech and deadening held | Fit 6 of 6 MEASURED, cause INFERRED (s98) |
| Kata lapse | 19.53-19.73 s | MEASURED, n=3 |

## The asthma + weariness case

The user's rule: with asthma and weariness up on a fitness class, go defensive and cure out of asthma.

**Evidence.** 61 windows, 7 fatal. Classified by what is known when the window STARTS: 50 began with the two alone, 20
of those gained slickness or anorexia (a median 3.0 s later), and 4 died. 11 began with a partner, and 3 died.
MEASURED. Four of the 7 fatal windows began alone, so the alarm belongs at the first prompt.

**What FITNESS needs.** Balance and equilibrium: a live probe held it 3.3 s until equilibrium returned (CONFIRMED live).
So any equilibrium spend with asthma up delays our lock breaker. It works while paralysed, and weariness refuses it
([class-cures](../afflictions/class-cures.md)).

**The two hand-written answers look like one rule that lacks a clock.** Against a Sentinel the code cures weariness
first. Against a Serpent it boosts asthma (`001_Anti_Priorities.lua:213-217`, `:604`). INFERRED: when FITNESS is ready, an
aurum that takes either affliction frees you, and when FITNESS is far from ready, only asthma helps. Weakly tested:
only 2 real tests of the first case, and no logged win of the second (asthma re-landed at +0.51 s and +2 s). Do not
treat this as settled. A live probe and step 6 of the plan come first.

**What is safe to do.** From the first such prompt: raise aurum above magnesium and plumbum, and spend no equilibrium.
Holding offence stays a hypothesis.

**What the simulator adds.** [sim/forward.md](../sim/forward.md) supports the aurum half: ROBUST on the closure rate, also against the rules the
package runs today. It does not support "spend no equilibrium": a shield whenever equilibrium is up lowered the closure rate, and was
worse in no comparison ([CONFLICTS](../CONFLICTS.md) #57). This is a model on 10 boards, not a live result, and no live code changed.

## Refuted: do not rebuild on these

| Claim | What the check found |
|---|---|
| "Asthma + weariness alone is safe" | Look-ahead bias. It counted windows by what happened later. See above |
| "A new SEALED alert is new signal" | The existing `true` prompt label warns the same: 14.5 s against 15 s, both 0 false alarms |
| "Locks land while the victim's cures are on cooldown" | Clock-dark at closure in 1 of 5. Keys shut by clock OR blocker is the real contrast |
| "Winners strike just after a key is spent" | Within 2 s of FOCUS: 4 of 31, with about 2.5 expected by chance |
| "An enemy's earliest action is about 0.8x stated" | No single multiplier fits: 0.43 to 0.95 by ability |
| "SSC acts with no delay" | "May eat" to eat: median 0.18 s and 0.10 s, in two logs. **Since 2026-11-07 the delay is split by case** ([sim/rules.md](../sim/rules.md), from the race in the four Serpent logs, `kb/sim/events.json`): onto an open eat, `ssc.delay.gain`, median 0.104 s (p10 0.064, p90 0.198, n=23: az 9, Z5 5, g 2, X 7); on an eat that comes back with an affliction waiting, `ssc.delay.return`, median 0.145 s (p10 0.050, p90 0.239, n=163). Both hold the logger's own reaction too, not SSC alone. One opponent seen from our seat, Saibel in FL, gave 0.055 s (n=9, `ssc.delay.gain.Saibel`): an alternative only, never a victim default |
| "Paralysis beats haemophilia inside magnesium" | Haemophilia is a ferrum cure, 20 of 20 |
| "Both balances up 25-34% of the time is wasted" | Inside attack bursts it is 7-8%. The rest was roaming or chasing |
| "FITNESS fired 4.59 s late for lack of a hook" | Equilibrium was down until that moment (S:2040, 2097) |
| "FITNESS lockout 8.7 s" | **Not refuted, only unsupported.** 8.7 was not seen as a stamped value, but the S:2105-2328 bracket of 8.49-9.26 s cannot exclude it. The pairs do not fit one fixed lockout: that bracket and T:4616-4929 (9.12-9.65 s) lie under Lc:759-949 (9.86-9.97 s) |
| "`Balance used` and `[Bal Spent]` are loggers' echoes" | Game text. It prints before recovery, and in the same colour as `Health lost` |

## Clumsiness

PLAYER (the user, 2026-11-08): "33 percent chance to miss your target is huge. Additionally, it starts the kelp stack needed to stick Asthma."
The game's own record says only that it "makes it hard for you to physically hit your target" ([database](../afflictions/database.md)). No log
measures the 33 percent. `.claude/classes/sentinel.md`:167 gives the same figure with no measurement behind it, and it was written from a Blademaster seat, our 2026-08-19
death log. So it corroborates nothing, and it sits oddly beside the Blademaster on the list below.

Immune, also PLAYER: "Tekura Monk, Sylvan, Magi, Blademaster, and Elemental Lords are all immune to clumsiness." The code follows the user (`ataxia_wantClumsiness`,
`ataxia/ataxia/007_Pariah_things.lua`:93-111). The words do not say whether immune means no miss or no affliction, and the logs do not settle it: a Blademaster and an
Earth Lord both take the affliction and spend a cure on it, and three rows show an Earth Lord's clumsy miss ([CONFLICTS](../CONFLICTS.md) #81).

## Limits

- **Few players.** Six logs are Mystor against one opponent, and nine are Claes. Several were played within 30 minutes.
  The samples are not independent, so do not calibrate noise from them as if they were.
- **These are mostly 1v1 logs.** Our own recorded fights are group fights. One death there was 10,400 damage in the last
  5 s with no route (MK:12842). This page does not explain group kills.
- **No log at all:** Occultist, Jester, Priest, Psion, Druid, Paladin, Sylvan, Unnamable, the dragons, and some lords.
- **Loggers' boards are beliefs,** and each client adds or gags lines. See [raw/logs/README.md](../raw/logs/README.md). [replay.md](replay.md)
  checks them: every client with enough to compare agrees 98.6% or better with the game's gain and cure lines and with its own lock echoes.
- **The hand-written route rules failed the stricter bars of their offline gate** ([replay.md](replay.md), 2026-11-01): G1 2 where 4 are needed, G2 2
  attackers where 3 are needed, G3 1 of 2, G4 Air Lord 0.75 against softlock 0.647. If those bars stand, the plan keeps hand-written rules and builds no
  general evaluator. **The plan's own gate sentence has no UNTESTED, G3 or G4 term. Read alone it gives 6 of 6 from 4 attackers. This FAIL comes from the
  stricter bars. The user decided on 2026-11-01 that these bars stand, so step 5, the general evaluator, is on hold.** That 6 is generous: it is 5 if the rule must match the kill, and 3 if its chain must
  still be on within 5 s of death. An alarm at the fight's first hit would also clear it. No Pariah or Blademaster fight exists that its logger survived,
  so those rules cannot be tested for false alarms. MEASURED, in-sample.

## Joined to the code

- **No decision reads a measured balance time.** The stopwatches in `ataxia/014_Balance_Timers.lua` are display only.
- **A press is the trigger,** and nothing reasons about time ahead, apart from a few small cases.
- `ataxia_lockEscapes` (`003_Lock_breakers.lua:517-523`) knows smoke, focus and FITNESS by blocker. It omits eat, salve
  and tree, and it never asks how long until a channel returns.
- The clock constants disagree between files: tree 13 and 14, restoration five values, focus four values.
- Trigger 398 starts the target's focus clock only for the target's own focus line, and under shadowmadness it waits
  4.8 s, just under the measured 4.82. A wait of 5 s refused real cures. Both changes shipped in v4.7.470.
- `tBals` is the TARGET's cure balances. Our own tree is `ataxiaTemp.usedTree`: the touch line sets it on every touch of ours,
  and `levilogin()` clears it. `ataxia_resetTargetBals` (`016`) is the one reset. It kills running timers, because they write
  to the global table and could mark a new target's balance up early. The focus knocks name their timer, so it can kill them. **The target tracker takes a cure line as a fact (2026-11-08, not run in Mudlet):** a branched cure stays split when its confirm window closes (`007_Branching_State_Tracker.lua`:1488), and a tree, focus, smoke or apply drops the branches it rules out. The herb window is 1.3 s and Saibel's shortest eat-to-eat is 1.506 s, so the old unfold undid most branched eats: 11 times in a replay of FL ([cure-channels](../afflictions/cure-channels.md)).
