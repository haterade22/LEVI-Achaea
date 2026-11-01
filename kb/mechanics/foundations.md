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
| MK, INF | `ours/2026-10-27_112717_Tabethys.log`, `ours/2026-10-27_135412_Tabethys.log` | 1 |
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
   [Stated against observed](#stated-against-observed). MEASURED.
8. **An opponent's stated cost does not predict their next attack. Measure it per ability.** A clock gives the
   EARLIEST action and never says when. 31-48% of attack gaps fall outside +-0.25 s of the median. MEASURED.
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
| Moss, potash | 5.9 | 104 | A clock of its own (CONFLICTS #11) |
| Tree | 13.95 | 124 | |
| FITNESS lockout | about 10 | 8 pairs | Earliest 9.06. It keeps running under weariness |
| Immunity sip | 7.3-7.7 | 2 | Separate from the health sip |
| Dagaz rune (passive) | 15.03 | 59 ticks | One rune. `locks.md` says "about 10 s" |
| Humour | 1.55 | 41 | |

**Opponents share these clocks.** From third-person lines, their floor is the clock + 0.03-0.1 s, and under pressure
the clock + 0.13-0.2 s. Typical gaps are longer: herb 1.69, tree 15.35. A clock therefore gives the earliest cure.

**Visible from our seat:** every eat, tree, focus, smoke, salve and sip by another person prints a line.
**Not visible:** what a herb took, the salve type (restoration and mending print the same line), failed sends, and
the opponent's balance.

## Stated against observed

`kb/classes/abilities.json` holds stated values in a field named `cooldown`, which mostly means balance spent. It has
1,196 clean rows and real holes: Shikudo 0 of 31, Kaido 13 of 33. It has no recharge lockouts. READ and MEASURED.

The game prints the true cost to the player who spends it: `Balance used: 2.1s.` and `Equilibrium used: 3.40s.` These
are game text. Our logs do not show them, and the option that enables them is not yet known. Printed cost against
the measured time to recovery: median -0.02 s, 89% within +-0.15 s (balance, n=264). MEASURED.

| Own cost | Stated | Printed | Ratio |
|---|---|---|---|
| FITNESS | 3.00 | 2.8 | 0.93 |
| Truewrack | 2.80 | 2.6 | 0.93 |
| Shield tattoo (equilibrium) | none listed | 4.00, 3.40, 2.89 | 1, 0.85, 0.72 by character and form |
| Homunculus attack | 3.00 | 2.55 | 0.85 |
| Pommelstrike, 1 s stamps | 1.50 | 1.1 | about 0.73 |

So **a cost = stated x k**, where k depends on the character, the channel and sometimes the form. Rain form adds
x0.85 on equilibrium. Weariness, asthma, clumsiness and paralysis did not change a reap's cost. MEASURED.

| Opponent's ability | Stated | Gap to next attack, median | n |
|---|---|---|---|
| Serpent DSTAB | 2.80 | 1.83 (Thato 1.81, Archaeon 1.82, Seurimas 1.83, Kalys 1.85) | 141 |
| Serpent BITE | 4.00 | 1.70 | 18 |
| Serpent FLAY | 2.00 | 1.64-1.70 | 65 |
| Apostate STARE | 1.90 | 2.04 | 129 |

The cause of the Serpent gap is not visible from our seat. A speed effect or a stale wiki value could both explain it.

## Timed effects

| Effect | Delay | Evidence |
|---|---|---|
| Rebounding after the smoke | 8.51 s median, p10 8.44, p90 8.58 | MEASURED, n=67 |
| Infest relapses, no attacker line | 5.34-6.69 s, then 11.02-12.78 s | MEASURED, n=5, n=4. Supplied a plague in Vr, WK, 4c |
| Hypochondria chain | nausea +3.12, lethargy +6.24, impatience +9.31 s | MEASURED, one fight (Z5) |
| Fratricide relapse | 2.0-2.9 s | MEASURED, n=7 in X, 5 in Z5 |
| Anorexia after SNAP | 9.0-11.0 s | MEASURED, 7 of 7, one player (az), not independently checked |
| Serpent's snake bite | about every 8.1 s | MEASURED, one fight (g) |
| Air Lord pressure gain | 1 + manaleech and deadening held | Fit 6 of 6 MEASURED, cause INFERRED (s98) |
| Kata lapse | 19.53-19.73 s | MEASURED, n=3 |

## The asthma + weariness case

The user's rule: with asthma and weariness up on a fitness class, go defensive and cure out of asthma.

**Evidence.** 61 windows, 7 fatal. Classified by what is known when the window STARTS: 50 began with the two alone, 20
of those gained slickness or anorexia (a median 3.0 s later), and 4 died. 11 began with a partner, and 3 died.
MEASURED. Four of the 7 fatal windows began alone, so the alarm belongs at the first prompt.

**What FITNESS needs.** Balance and, per the user, equilibrium (CONFLICTS #50). It works while paralysed, and weariness
refuses it ([class-cures](../afflictions/class-cures.md)).

**The two hand-written answers look like one rule that lacks a clock.** Against a Sentinel the code cures weariness
first. Against a Serpent it boosts asthma (`001_Anti_Priorities.lua:190`, `:579`). INFERRED: when FITNESS is ready, an
aurum that takes either affliction frees you, and when FITNESS is far from ready, only asthma helps. Weakly tested:
only 2 real tests of the first case, and no logged win of the second (asthma re-landed at +0.51 s and +2 s). Do not
treat this as settled. A live probe and step 6 of the plan come first.

**What is safe to do.** From the first such prompt: raise aurum above magnesium and plumbum, and spend no equilibrium.
Holding offence stays a hypothesis.

## Refuted: do not rebuild on these

| Claim | What the check found |
|---|---|
| "Asthma + weariness alone is safe" | Look-ahead bias. It counted windows by what happened later. See above |
| "A new SEALED alert is new signal" | The existing `true` prompt label warns the same: 14.5 s against 15 s, both 0 false alarms |
| "Locks land while the victim's cures are on cooldown" | Clock-dark at closure in 1 of 5. Keys shut by clock OR blocker is the real contrast |
| "Winners strike just after a key is spent" | Within 2 s of FOCUS: 4 of 31, with about 2.5 expected by chance |
| "An enemy's earliest action is about 0.8x stated" | No single multiplier fits: 0.43 to 0.95 by ability |
| "SSC acts with no delay" | "May eat" to eat: median 0.18 s and 0.10 s, in two logs |
| "Paralysis beats haemophilia inside magnesium" | Haemophilia is a ferrum cure, 20 of 20 |
| "Both balances up 25-34% of the time is wasted" | Inside attack bursts it is 7-8%. The rest was roaming or chasing |
| "FITNESS fired 4.59 s late for lack of a hook" | Equilibrium was down until that moment (S:2040, 2097) |
| "FITNESS lockout 8.7 s" | No pair reproduces it. 9.06-10 on 8 pairs |
| "`Balance used` and `[Bal Spent]` are loggers' echoes" | Game text. It prints before recovery, and in the same colour as `Health lost` |

## Limits

- **Few players.** Six logs are Mystor against one opponent, and nine are Claes. Several were played within 30 minutes.
  The samples are not independent, so do not calibrate noise from them as if they were.
- **These are mostly 1v1 logs.** Our own recorded fights are group fights. One death there was 10,400 damage in the last
  5 s with no route (MK:12842). This page does not explain group kills.
- **No log at all:** Occultist, Jester, Priest, Psion, Druid, Paladin, Sylvan, Unnamable, the dragons, and some lords.
- **Loggers' boards are beliefs,** and each client adds or gags lines. See [raw/logs/README.md](../raw/logs/README.md).

## Joined to the code

- **No decision reads a measured balance time.** The stopwatches in `ataxia/014_Balance_Timers.lua` are display only.
- **A press is the trigger,** and nothing reasons about time ahead, apart from a few small cases.
- `ataxia_lockEscapes` (`003_Lock_breakers.lua:285-291`) knows smoke, focus and FITNESS by blocker. It omits eat, salve
  and tree, and it never asks how long until a channel returns.
- The clock constants disagree between files: tree 13 and 14, restoration five values, focus four values.
