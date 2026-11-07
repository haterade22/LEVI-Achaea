---
topic: whole-fight engine rules
confidence: tagged per rule
generated_by: tools/kb_rules.py
---

# The engine's rules

**GENERATED. Do not edit.** Run `python tools/kb_rules.py`. Hand rules live in `kb/sim/rules_hand.json`.

Every rule of the whole-fight engine (`tools/sim/fight.lua`) is here, with its tag and its source. A run of
`tools/theorycraft.py` lists the ASSUMED, PLAYER and WIKI rules it read. Those are model inputs, not facts, and each one
has alternatives so a sweep can run it.

Freeze file `tools/sim/gates_whole.json`, sha256 `1de3efb56ed6f8f7de1ab27e3f767688b1c2f433f5d28d118f718b723f41217b`.

| Tag | Rules | Means |
|---|---|---|
| MEASURED | 42 | counted from log rows |
| READ | 379 | stated in a file or in the code |
| WIKI | 3 | the wiki only; an in-game AB wins |
| PLAYER | 0 | a player said so |
| ASSUMED | 41 | nothing supports it yet |

## Rules of play

| Rule | Value | Alternatives | Tag | n | Source | Note |
|---|---|---|---|---|---|---|
| `attack.bite` | one venom; sileris or fangbarrier blocks it | sileris does not block | WIKI |  | kb/raw/wiki/Venom.wiki:23; kb/raw/wiki/Subterfuge.wiki:80 | 'BITE <target> [<venom>]' (Venom.wiki:23). Flaying the sileris coating is what lets the fangs sink in again (Subterfuge.wiki:80). The pet's bite meets 'the waxy coating' in all four logs (rule snake lines, kb/sim/events.md) |
| `attack.dstab.venoms` | 2 | 1 | WIKI |  | kb/raw/wiki/Subterfuge.wiki:312 | the census on kb/sim/events.md counts the second-venom line ('Striking like a snake ...') against the pricks |
| `attack.flay` | the attacker names what to strip: FLAY <target> SHIELD or REBOUNDING strips that one, a bare FLAY strips the sileris coating; the venom lands if neither shield nor rebounding is left | attack.flay.order | WIKI |  | kb/raw/wiki/Subterfuge.wiki:76,80 | .claude/classes/serpent.md:569 reads the same. A bare FLAY in the logs (no 'flays away' line): g 945-948 and X 3189-3194 (the coating ripped, then the whip and paralysis). A named FLAY also takes the coating: rule attack.flay.coating |
| `attack.flay.coating` | a FLAY that strips the shield or rebounding also strips the sileris coating |  | MEASURED | 23 | kb/raw/logs/2026-11-01_claes_runewarden-vs-serpent_loss_azbErKcK.txt:269-270,558,1169,2235,2465,2659,2931,3217,3598; kb/raw/logs/2026-11-01_elmer_shikudo-vs-serpent_noresult_g-lD00-h.txt:1244,2100; kb/raw/logs/2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt:545,817,2190,2363,2509,2799,3461,3816,4105,4654,5162,5857 | 23 of 23 FLAYs of the shield or rebounding made with the coating up ripped it in the same packet (az 9, g 2, X 12): 'The protective coating covering your skin is ripped away along with your protections.' None of the 33 made with it down printed that line. X 5328: a whip with no strip line left the coating up (snake bites met it at 5385, 5565 and 5776); read as a named FLAY whose defence was already gone (ASSUMED). tools/test_kb_rules.py re-counts it |
| `attack.flay.order` | named | auto: shield, else rebounding, else sileris | ASSUMED |  | tools/sim/attackers.lua (A.apply, flay) | named follows the wiki's syntax. auto is the engine's own order for a FLAY that names nothing (--flay-order auto): forward.lua has no FLAY of a defence (its strike() turns a shielded DSTAB into a one-venom FLAY) |
| `attack.gap.own` | none | 1.545 / 1.73 / 1.83 / 2.33 / 2.8 / 3.1 | ASSUMED |  | kb/mechanics/clocks.json stated.opponents | our own DSTAB, FLAY and BITE costs are not measured (no log of our Serpent). The CLI needs --gap until the spar lands |
| `attack.gap.own.sd` | 0.09 | 0.0 / 0.2 | MEASURED | 264 | kb/mechanics/foundations.md:116 | our printed cost against the measured time to recovery: 89% within +-0.15 s, about 0.09 s as a standard deviation |
| `attack.give` | adds the named afflictions at once | off | ASSUMED |  | kb/mechanics/foundations.md:150-154 | a scripted supply with no attacker line: a hypnosis snap, a relapse, a timed impatience |
| `attack.rebounding` | the venoms rebound onto the attacker |  | READ |  | kb/raw/logs/2026-11-01_claes_runewarden-vs-serpent_loss_azbErKcK.txt:523 | 'The attack rebounds back onto <name>!' |
| `attack.shield` | blocks the attack |  | READ |  | kb/raw/logs/2026-11-01_elmer_shikudo-vs-serpent_noresult_g-lD00-h.txt:24 | '<name>'s attack rebounds off your magical shield.' |
| `channel.eat.blocked_by` | anorexia |  | READ |  | kb/afflictions/cure-channels.md:19 |  |
| `channel.eat.lungs_items` | pear / calcite |  | MEASURED | 29 | kb/afflictions/cure-channels.md:33 | eaten, but they spend the lungs clock (29 of 29) |
| `channel.focus.blocked_by` | impatience |  | READ |  | kb/afflictions/cure-channels.md:23 |  |
| `channel.salve.blocked_by` | slickness |  | READ |  | kb/afflictions/cure-channels.md:20 |  |
| `channel.smoke.blocked_by` | asthma |  | READ |  | kb/afflictions/cure-channels.md:21 |  |
| `channel.tree.blocked_by` | paralysis |  | READ |  | kb/afflictions/cure-channels.md:24 |  |
| `class.accelerate` | classes Depthswalker, cures class.accelerate.cures, blocked_by recklessness, needs eq, spends eq class.accelerate.eq, lockout class.accelerate.lockout |  | READ |  | kb/afflictions/class-cures.md:39 | it needs and spends equilibrium: the prompt went from exT to xT (2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt rows 2086-2098) |
| `class.accelerate.cures` | 1 | 2 | ASSUMED |  | kb/raw/logs/2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt:2088-2092 | one affliction, or two when boosted. The only fire in the four logs was boosted and took two (fratricide, asthma) |
| `class.accelerate.eq` | 2.12 | 1.5 / 3.0 | MEASURED | 1 | kb/raw/logs/2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt:2096 | 'Equilibrium used: 2.12s.' after the one (boosted) fire. n=1, so it is swept |
| `class.accelerate.lockout` | 19.45 | 15.0 / 19.45 / 25.0 | MEASURED | 1 | kb/raw/logs/2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt:2088,2097,2409 | the fire at 2088 (stamp 53743.36), a refusal at 2097, 'ACCELERATE BACK. You may accelerate time ...' at 2409 (53762.81). One fire, so it is swept |
| `class.cure.policy` | at once | hold | ASSUMED |  | kb/afflictions/class-cures.md:34-54 | the victim fires its class cure as soon as it is open and useful |
| `class.dagaz` | classes Runewarden, passive True, period clock.dagaz, cures one, first voyria |  | READ |  | kb/afflictions/class-cures.md:103 | voyria first: azbErKcK rows 3856-3857 |
| `class.dagaz.phase` | random | half a period | ASSUMED |  | kb/afflictions/class-cures.md:103 | when the rune ticks relative to the fight. --median puts the first tick at half a period |
| `class.fitness` | classes Infernal / Paladin / Runewarden / Monk / Blademaster / Druid / Sentinel, cures asthma, blocked_by weariness, needs bal / eq, spends bal 2.8, lockout clock.fitness, while_paralysed True |  | READ |  | kb/afflictions/class-cures.md:41,60-65 |  |
| `class.salt` | classes Alchemist, cures one, blocked_by stupidity, needs eq, spends eq class.salt.eq, lockout clock.salt |  | READ |  | kb/afflictions/class-cures.md:36 | which affliction salt takes is not known: random, as the tree. It needs and spends equilibrium (class.salt.eq) |
| `class.salt.eq` | 2.55 | 3.0 | MEASURED | 7 | kb/raw/logs/2026-11-01_elmer_alchemist-vs-serpent_loss_Z5cyffxx.txt:497,824,1783,2232,4033,4497,4920 | 'Equilibrium used: 2.55s.' three rows before each of the 7 'Directing the energy of salt' lines (two before 'Drawing upon the latent alchemical energies'). The wiki says 3.00 (kb/raw/wiki/Alchemy.wiki:92); Elmer's shield shows the same 0.85 ratio (3.40 of 4.00) |
| `cure.options_join` | or |  | READ |  | kb/afflictions/cure-channels.md:23 | the groups of cure_options are alternatives: focus alone cures anorexia. kb_affliction_db.py joins them with 'and' (kb/CONFLICTS.md #60) |
| `defence.rebounding.delay` | clock.rebounding |  | MEASURED | 460 | kb/mechanics/clocks.json, clocks.rebounding (n=460; kb/mechanics/foundations.md:148 gives the older n=67) | the aura comes up this long after the smoke, and the smoke spends the lungs clock. n is the clock's |
| `defence.rebounding.smoke` | skullcap / malachite |  | MEASURED | 49 | kb/sim/events.json streams: kb/raw/logs/2026-11-01_claes_runewarden-vs-serpent_loss_azbErKcK.txt (skullcap, 16), kb/raw/logs/2026-11-01_elmer_shikudo-vs-serpent_noresult_g-lD00-h.txt (malachite, 9), kb/raw/logs/2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt (malachite, 24); first pair az 102 -> rebounding.up 8.52 s later | the smoke items that raise rebounding. 48 of the 49 smokes of these items saw 'You feel an aura of rebounding surround you' 7.59-8.59 s later, before the next such smoke (g 2887 did not: the log ends). One of az's 16 is its firefly pipe's own line (az 573, after '[Curing]: SMOKE SKULLCAP'; the aura came at 743, 8.475 s later), which kb_events reads since review R3-docs-2. No smoke of another item (valerian, slippery elm, realgar) comes before a rebounding line without one of these first. A fork reads a logged smoke of these items as rebounding on its way (tools/theorycraft.py). tools/test_kb_rules.py re-counts it |
| `defence.shield.cost` | 3.4 | 2.89 / 4.0 | ASSUMED |  | kb/sim/rules.json defence.shield.cost.* | a victim with no logger: the cost two of the three loggers show |
| `defence.shield.cost.Claes` | 4.0 |  | MEASURED | 13 | kb/raw/logs/2026-11-01_claes_runewarden-vs-serpent_loss_azbErKcK.txt:1258,1521,2041 | 'Equilibrium used: 4.00s.' after all 13 of Claes's shields |
| `defence.shield.cost.Elmer` | 3.4 |  | MEASURED | 12 | kb/raw/logs/2026-11-01_elmer_alchemist-vs-serpent_loss_Z5cyffxx.txt:36,663,1386; kb/raw/logs/2026-11-01_elmer_shikudo-vs-serpent_noresult_g-lD00-h.txt:445,2285 | 3.40 s after 11 of Elmer's 12 shields (Z5 7, g 4); 2.89 s once (g row 2285) |
| `defence.shield.cost.Nikita` | 3.4 |  | MEASURED | 10 | kb/raw/logs/2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt:528,729,2146 | 'Equilibrium used: 3.40s.' after all 10 of Nikita's shields |
| `defence.shield.reraise` | median 5.826, sd 4.129, min 2.59, p10 3.238, p90 13.821, max 15.277 | 3.238 / 5.826 / 13.821 | MEASURED | 19 | kb/sim/events.json: a FLAY of the shield (flay.shield) to the next shield.up within 20 s | 19 of the 26 FLAYs of the shield in the four logs saw the shield again within 20 s; 7 did not, and the engine raises it again after every FLAY. Only a FLAY starts the re-raise: a shield down with no FLAY (the logger's own movement or action dropped it) stays down (review R3-fork-1, R3-fork-2). The next attack came first every time (1.48-2.53 s later). The engine draws from these quantiles (min, p10, median, p90, max). tools/test_kb_rules.py re-measures it |
| `defence.shield.while_paralysed` | False | True | MEASURED | 4 | tools/kb_sim.py:59 | 3 of 4 shield rows show paralysis cured first |
| `defence.sileris.harden` | median 10.0, sd 0.035, min 9.753, p10 9.947, p90 10.037, max 10.119 |  | MEASURED | 43 | kb/sim/events.json streams: sileris.apply to the next sileris.up, before the next apply, in the four logs (az 12, Z5 9, g 7, X 15); first pair az 24 -> 10 s later | the coating hardens this long after the apply line ('You apply a sileris berry' or 'a quicksilver droplet to yourself'). 6 of the 49 applies printed no hardening line before the next apply or the log's end (az 3616; Z5 1891, 4096, 4712, 4951, 5284). A hit before the 10 s mark does not explain it: 36 of the 43 that hardened took a bite or a FLAY in that time too. Slickness at the mark does: rule defence.sileris.slickness_harden. The engine does not re-apply the coating; a fork reads an apply with no hardening line yet as the coating on its way (tools/theorycraft.py, review R3-fork-8). tools/test_kb_rules.py re-measures it |
| `defence.sileris.slickness` | slickness that lands strips the sileris coating |  | MEASURED | 8 | kb/raw/logs/2026-11-01_elmer_alchemist-vs-serpent_loss_Z5cyffxx.txt:451,869,1262,1487,1861,4075; kb/raw/logs/2026-11-01_elmer_shikudo-vs-serpent_noresult_g-lD00-h.txt:1649; kb/raw/logs/2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt:146 | 8 of 8 slickness gains in a packet that starts with the coating up printed 'The protective covering coating your skin sloughs off.' in the same packet (X 144-146: the second venom, 'You have been afflicted with slickness.', then the slough line). No slickness with the coating up left it on. All 8 are DSTABs. The engine strips it on a DSTAB, a give or a FLAY's venom and prints sileris.down (tools/sim/attackers.lua); the give and the FLAY are by analogy, no log shows them. A BITE lands only with the coating down. Review R4-engine-1. tools/test_kb_rules.py re-counts it |
| `defence.sileris.slickness_harden` | an apply does not harden while slickness is on at its hardening time |  | MEASURED | 49 | kb/sim/events.json streams: each sileris.apply, and slickness on or off at the apply + 10 s; kb/raw/logs/2026-11-01_claes_runewarden-vs-serpent_loss_azbErKcK.txt:3616,3734; kb/raw/logs/2026-11-01_elmer_alchemist-vs-serpent_loss_Z5cyffxx.txt:1891,2308,2310,4096,4454,4712,4881,4951,5218,5284,5402 | 0 of the 43 applies that hardened had slickness on at the apply + 10 s (10 of them took slickness in the wait, and it was cured before the mark). 5 of the 6 applies that never hardened had it on (az 3616; Z5 4096, 4712, 4951, 5284). The sixth, Z5 1891, had slickness cured at +9.90 (row 2308) and a new apply in that packet (row 2310). The engine raises no coating at the mark when slickness is on (tools/sim/fight.lua timed). tools/test_kb_rules.py re-counts it |
| `draw.shape` | quantiles: linear between lo, p10, median, p90 and hi, 10% of the draws in each tail; lo and hi are one p10-p90 width past p10 and p90, held inside min and max | normal: the median +/- 3 sd (three uniform draws), held inside min and max | ASSUMED |  | tools/sim/victim.lua (V.clock, V.tails) | the shape of a drawn clock; --median takes the median and draws nothing, except in a fork: there a clock already running (a channel down at the row, a FLAY of the shield, a smoke for rebounding, an apply of the coating) takes the median of the part of its spread above the time already run, and that part rests on this shape (review R3-engine-2). The --seeds runs of a --median page draw too. A log's min and max are often a lost line or a slowing affliction (clock.rebounding: 0.026 and 250.253 around a median of 8.49; clock.focus max 4.992 against p90 2.542), so a tail never reaches them unless they lie within one width. --clock-draw normal runs the alternative |
| `focus.order` | mental first, anorexia last | anorexia first | READ |  | tools/kb_replay.py:431 | LOCK_EXITS: focus cures anorexia, or a mental first |
| `label.true` | kb_replay.is_true |  | READ |  | tools/kb_replay.py:645-679 | softlock (asthma, slickness or bloodfire, anorexia), impatience or sandfever, paralysis, and the class cure shut |
| `random_cure.pool` | NoRandomCure off | paralysis / slickness / anorexia / asthma / sensitivity / clumsiness / weariness / epilepsy / haemophilia / nausea / dizziness / shyness / stupidity / confusion / dementia / paranoia / hallucinations / impatience / hypersomnia / addiction / darkshade / healthleech / brokenleftleg / brokenrightleg / brokenleftarm / brokenrightarm / blackout | ASSUMED |  | kb/afflictions/database.md:11-14; src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/008_V3_Integration.lua:264 (treeCurableAffsV3, the alternative) | every affliction the game does not mark NoRandomCure. The package's tree pool holds 27 (--random-pool package) |
| `ssc.delay` | min 0.1, median 0.14, max 0.18 | 0.1 / 0.18 | MEASURED | 2 | kb/mechanics/foundations.md:192 | 'may eat' to eat: medians 0.18 and 0.10 s in two logs. The draw between them is uniform (ASSUMED shape) |
| `ssc.order` | package default priorities | asthma first / the logger's own table | ASSUMED |  | src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Default_Curing_Prios.lua | the loggers ran their own tables (kb/sim/forward.md). The priority numbers are READ from the code; using them for a victim is ASSUMED |
| `ssc.phi` | 0.6 | 0.33 / 1.0 | MEASURED | 27 | kb/mechanics/foundations.md:53 | inside one herb the top affliction wins with this chance: aurum took asthma 16 of 27 with weariness up |
| `timed.fratricide` | min 2.0, max 2.9 |  | MEASURED | 12 | kb/mechanics/foundations.md:152 | not yet used by the engine |
| `timed.hypochondria` | nausea 3.12, lethargy 6.2, impatience 9.31 | off | MEASURED | 5 | kb/sim/events.json, census.<log>.suppliers.hypochondria.* (kb/sim/events.md, Suppliers) | the pooled median of every sample in three logs (az, Z5, X; g has no step): nausea 3.124 (n=8, 3.09-3.15), lethargy 6.198 (n=7, 3.08-9.31), impatience 9.311 (n=5, 9.11-12.42). n is the smallest step's. Curing the hypochondria ends the chain. tools/test_kb_rules.py re-derives the medians from kb/sim/events.json |
| `tree.cures` | one random affliction |  | READ |  | kb/afflictions/cure-channels.md:24 |  |
| `tree.pick` | random | priority | ASSUMED |  | kb/afflictions/cure-channels.md:24 | uniform over the curable afflictions up. A run with --median takes the top priority instead, so it has no draw |
| `tree.policy` | now | hold | ASSUMED |  | tools/sim/forward.lua:155-167 | the victim touches the tree whenever it is up and an affliction is up; hold keeps it for a softlock |

## Clocks

Seconds. A clock that is not usable is swept over the range in the last column.

| Rule | Median | SD | p10 | p90 | n | Usable | Swept | Source |
|---|---|---|---|---|---|---|---|---|
| `attack.gap.others.bite` | 1.690 | 0.080 | 1.585 | 1.790 | 21 | no | 1.585 / 1.69 / 1.79 | kb/mechanics/clocks.json stated.opponents BITE |
| `attack.gap.others.dstab` | 1.830 | 0.533 | 1.730 | 3.097 | 195 | no | 1.73 / 1.83 / 3.097 | kb/mechanics/clocks.json stated.opponents DSTAB |
| `attack.gap.others.flay` | 1.642 | 0.380 | 1.530 | 2.503 | 64 | no | 1.53 / 1.642 / 2.503 | kb/mechanics/clocks.json stated.opponents FLAY |
| `attack.gap.others.stare` | 2.037 | 0.468 | 1.874 | 3.074 | 143 | no | 1.874 / 2.037 / 3.074 | kb/mechanics/clocks.json stated.opponents Stare |
| `clock.dagaz` | 15.095 | 0.105 | 15.002 | 15.272 | 46 | no | 15.002 / 15.095 / 15.272 | kb/mechanics/clocks.json clocks.dagaz |
| `clock.eat` | 1.504 | 0.090 | 1.380 | 1.610 | 1478 | no | 1.38 / 1.504 / 1.61 | kb/mechanics/clocks.json clocks.eat |
| `clock.eat.Claes` | 1.530 | 0.073 | 1.432 | 1.620 | 338 | yes |  | kb/mechanics/clocks.json clocks.eat.by_logger (Claes, printed) |
| `clock.eat.Elmer` | 1.492 | 0.075 | 1.401 | 1.593 | 232 | yes |  | kb/mechanics/clocks.json clocks.eat.by_logger (Elmer, line) |
| `clock.eat.Nikita` | 1.540 | 0.055 | 1.460 | 1.600 | 249 | yes |  | kb/mechanics/clocks.json clocks.eat.by_logger (Nikita, line) |
| `clock.fitness` | 9.807 | 0.326 | 9.131 | 9.967 | 5 | no | 9.059 / 9.807 / 9.969 | kb/mechanics/clocks.json clocks.fitness |
| `clock.focus` | 2.430 | 0.083 | 2.330 | 2.542 | 159 | no | 2.33 / 2.43 / 2.542 | kb/mechanics/clocks.json clocks.focus |
| `clock.humour` | 1.546 | 0.073 | 1.435 | 1.622 | 41 | yes |  | kb/mechanics/clocks.json clocks.humour |
| `clock.immunity` | 7.470 | 0.147 | 7.371 | 7.749 | 3 | no | 7.346 / 7.47 / 7.819 | kb/mechanics/clocks.json clocks.immunity |
| `clock.moss` | 5.912 | 0.078 | 5.800 | 6.001 | 143 | no | 5.8 / 5.912 / 6.001 | kb/mechanics/clocks.json clocks.moss |
| `clock.rebounding` | 8.490 | 0.069 | 8.397 | 8.575 | 460 | yes |  | kb/mechanics/clocks.json clocks.rebounding |
| `clock.restoration` | 4.019 | 0.042 | 3.935 | 4.042 | 30 | yes |  | kb/mechanics/clocks.json clocks.restoration |
| `clock.salt` | 9.313 | 0.288 | 9.165 | 9.903 | 7 | no | 9.117 / 9.313 / 9.999 | kb/mechanics/clocks.json clocks.salt |
| `clock.salve_short` | 0.915 | 0.069 | 0.820 | 0.997 | 173 | yes |  | kb/mechanics/clocks.json clocks.salve_short |
| `clock.salve_unknown` | 0.863 | 0.878 | 0.779 | 3.029 | 14 | no | 0.779 / 0.863 / 3.029 | kb/mechanics/clocks.json clocks.salve_unknown |
| `clock.sip` | 4.401 | 0.077 | 4.307 | 4.504 | 417 | yes |  | kb/mechanics/clocks.json clocks.sip |
| `clock.smoke` | 1.481 | 0.071 | 1.399 | 1.583 | 279 | yes |  | kb/mechanics/clocks.json clocks.smoke |
| `clock.tree` | 13.957 | 0.064 | 13.885 | 14.050 | 193 | yes |  | kb/mechanics/clocks.json clocks.tree |

## Class cures shut by

From the code, so the engine's `true` label replays what the package does today.

| Class | Blocker |
|---|---|
| Alchemist | stupidity |
| Blademaster | weariness |
| Depthswalker | recklessness |
| Druid | weariness |
| Infernal | weariness |
| Jester | paralysis |
| Magi | haemophilia |
| Monk | weariness |
| Occultist | paralysis |
| Paladin | weariness |
| Runewarden | weariness |
| Sentinel | weariness |
| Serpent | weariness |
| Shaman | selarnia |

## Venoms

ASSUMED. 23 of the 29 come from the package's own table (`venom_to_aff`), so truth and belief agree by construction. The other 6 come from the wiki's text only. The runnable alternative of each is `off` (the venom gives nothing); the wiki's text is a reference. `a|b` means a, else b: the package breaks the left limb first.

| Venom | Gives | On a weapon | From | Source | The wiki's text |
|---|---|---|---|---|---|
| aconite | stupidity | yes | package | .claude/databases/venoms.yaml:15; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:212 (venom_to_aff) | Cause sheer stupidity in your opponent. Afflict your victim with sheer stupidity. |
| camus | nothing here | no | wiki | .claude/databases/venoms.yaml:22 (wiki) | A more powerful version of Sumac. A more powerful version of Sumac poison. This venom can not be used to envenom a weapon. |
| colocasia | blindness, deafness | yes | wiki | .claude/databases/venoms.yaml:29 (wiki) | Gives blindness and deafness. Cause both blindness and deafness in your victim. |
| curare | paralysis | yes | package | .claude/databases/venoms.yaml:36; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:207 (venom_to_aff) | A venom of muscular paralysis. Cause your victim's body to freeze with paralysis. |
| darkshade | darkshade | yes | package | .claude/databases/venoms.yaml:43; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:207 (venom_to_aff) | Makes the victim allergic to sunlight. Give your target an allergy to sunlight. |
| delphinium | sleeping | yes | package | .claude/databases/venoms.yaml:50; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:213 (venom_to_aff) | Put your victim to sleep. Put your victim to sleep. |
| digitalis | shyness | yes | package | .claude/databases/venoms.yaml:57; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:206 (venom_to_aff) | Causes unbearable shyness. Cause unbearable shyness in your victim. |
| epseth | brokenleftleg\|brokenrightleg | yes | package | .claude/databases/venoms.yaml:64; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:215 (venom_to_aff) | Cause the legs of your victim to become useless. Cause the legs of your victim to become useless. |
| epteth | brokenleftarm\|brokenrightarm | yes | package | .claude/databases/venoms.yaml:71; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:215 (venom_to_aff) | Shrivel up the arms of your unlucky victim. Cause your victim's arms to shrivel. |
| euphorbia | nausea | yes | package | .claude/databases/venoms.yaml:78; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:209 (venom_to_aff) | Induces spasmodic vomiting. Induces spasmodic vomiting. |
| eurypteria | recklessness | yes | package | .claude/databases/venoms.yaml:85; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:205 (venom_to_aff) | Gives the victim delusions of invulnerability. Afflict your victim with recklessness. |
| gecko | slickness | yes | package | .claude/databases/venoms.yaml:92; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:212 (venom_to_aff) | Causes the recipient to become foully oily. Cause your victim to secrete foul oils from his skin. |
| kalmia | asthma | yes | package | .claude/databases/venoms.yaml:99; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:206 (venom_to_aff) | Inhibits the respiratory system. Afflict your victim with severe asthma. |
| larkspur | dizziness | yes | package | .claude/databases/venoms.yaml:106; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:210 (venom_to_aff) | Causes great dizziness. Cause great dizziness in your target. |
| loki | random | yes | wiki | .claude/databases/venoms.yaml:113 (wiki) | An unpredictable toxin. This unpredictable toxin will afflict your victim with a random venom. |
| monkshood | disloyalty | yes | package | .claude/databases/venoms.yaml:120; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:208 (venom_to_aff) | Disfigure your victim, causing disloyalty in those around. Causes your victim to become disfigured making their loyal servants turn on them. |
| nechamandra | shivering | yes | package | .claude/databases/venoms.yaml:127; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:214 (venom_to_aff) | A venom that chills the veins. A venom that chills the veins. |
| notechis | haemophilia | no | package | .claude/databases/venoms.yaml:134; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:211 (venom_to_aff) | Induce haemophilia in a target. Induce haemophilia in your target. This venom can not be used to envenom a weapon. |
| oculus | nothing here | yes | wiki | .claude/databases/venoms.yaml:141 (wiki) | Forces the recipient's eyelids open. Forces your victim's eyelids open clearing his eyes of blindness. |
| oleander | blindness | yes | wiki | .claude/databases/venoms.yaml:148 (wiki) | Blindness. Cause blindness in your target. |
| prefarar | sensitivity | yes | package | .claude/databases/venoms.yaml:155; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:208 (venom_to_aff) | Increase the recipient's sensitivity. Increase your victim's sensitivity to pain. |
| scytherus | scytherus | yes | package | .claude/databases/venoms.yaml:162; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:214 (venom_to_aff) | A venom that thins the blood. A nasty venom that will thin the victim's blood allowing your toxins to be more effective. |
| selarnia | selarnia | yes | package | .claude/databases/venoms.yaml:169; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:216 (venom_to_aff) | Forcing your victim back into mortal form. This venom will force the spirit animals out of those pesky forestals. |
| slike | anorexia | yes | package | .claude/databases/venoms.yaml:176; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:210 (venom_to_aff) | Give the curse of anorexia to your victim. Causes your victim to fall prey to anorexia. |
| sumac | nothing here | no | wiki | .claude/databases/venoms.yaml:183 (wiki) | Minor damage. This venom will cause minor damage to adventurers and denizens. This venom cannot be used to envenom a weapon. |
| vardrax | addiction | yes | package | .claude/databases/venoms.yaml:190; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:211 (venom_to_aff) | Grants an insatiable addiction. This potent venom will instill an addiction in your victim that will not be sated. |
| vernalius | weariness | yes | package | .claude/databases/venoms.yaml:197; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:209 (venom_to_aff) | A venom that weakens the muscles. A venom that weakens the muscles. |
| voyria | voyria | yes | package | .claude/databases/venoms.yaml:204; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:213 (venom_to_aff) | The deadliest venom known to mankind. This deadly venom will induce a quick death for its victim. |
| xentio | clumsiness | yes | package | .claude/databases/venoms.yaml:211; src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:205 (venom_to_aff) | Loss of coordination. Cause a loss of coordination in your target. |

## Cures

READ from `kb/afflictions/afflictions.json`. The options are alternatives (`cure.options_join`). The priority is the package's default (`prio.*`); a lower number goes first. NoRandomCure is the game's flag; what it means for the tree is the ASSUMED rule `random_cure.pool`. Channel `lungs` is pear or calcite (eaten, shut by anorexia, on the lungs clock) and `elixir` is APPLY HEALTH: the engine runs neither yet.

| Affliction | Options | Herb (mineral) | NoRandomCure | Priority |
|---|---|---|---|---|
| ablaze | salve mending to body |  | no |  |
| accentato | time |  | yes |  |
| addiction | eat ginseng; eat ferrum | ginseng (ferrum) | no | 9 |
| aeon | smoke elm; smoke cinnabar; time |  | no | 2 |
| agoraphobia | eat lobelia; eat argentum; focus | lobelia (argentum) | no | 16 |
| airfisted | time |  | yes |  |
| amnesia |  |  | yes |  |
| anorexia | salve epidermal to body; focus |  | no | 4 |
| asphyxiating | time |  | yes |  |
| asthma | eat kelp; eat aurum | kelp (aurum) | no | 7 |
| betrayal | time |  | yes |  |
| blackout | time |  | no |  |
| blindness | salve epidermal to head |  | yes | 26 |
| blistered | time |  | yes |  |
| bloodfire |  |  | yes |  |
| bound | writhe |  | yes | 2 |
| breathless | time |  | yes |  |
| brokenleftarm | salve mending to arms |  | no | 10 |
| brokenleftleg | salve mending to legs |  | no | 7 |
| brokenrightarm | salve mending to arms |  | no | 10 |
| brokenrightleg | salve mending to legs |  | no | 7 |
| bruisedribs | time |  | yes |  |
| burning | salve mending to body |  | no | 9 |
| calcifiedskull | restoration restoration to head |  | yes | 2 |
| calcifiedtorso | restoration restoration to body |  | yes | 2 |
| claustrophobia | eat lobelia; eat argentum; focus | lobelia (argentum) | no | 16 |
| clumsiness | eat kelp; eat aurum | kelp (aurum) | no | 7 |
| coldfate | time |  | yes |  |
| concussion | restoration restoration to head |  | yes | 12 |
| condemned | time |  | yes |  |
| conflagration |  |  | yes |  |
| confusion | eat ash; eat stannum; focus | ash (stannum) | no | 8 |
| constricted | time |  | yes |  |
| convergence |  |  | yes |  |
| corruption | time |  | yes |  |
| crackedribs | elixir health to torso |  | no | 9 |
| cremated | time |  | yes |  |
| crescendo | eat ash; eat stannum | ash (stannum) | yes | 9 |
| crushedthroat | salve mending to head |  | no | 5 |
| daeggerimpale | writhe |  | yes | 2 |
| damagedhead | restoration restoration to head |  | yes | 8 |
| damagedleftarm | restoration restoration to arms |  | yes | 11 |
| damagedleftleg | restoration restoration to legs |  | yes | 8 |
| damagedrightarm | restoration restoration to arms |  | yes | 13 |
| damagedrightleg | restoration restoration to legs |  | yes | 8 |
| darkshade | eat ginseng; eat ferrum | ginseng (ferrum) | no | 9 |
| dazed | smoke elm; smoke cinnabar |  | no | 5 |
| dazzled | salve mending to head; time |  | no | 7 |
| deadening | smoke elm; smoke cinnabar |  | no | 14 |
| deafness | salve epidermal to head |  | yes | 26 |
| deathsickness | time |  | yes |  |
| deepsleep |  |  | yes |  |
| degenerate | time |  | yes |  |
| dehydrated | time |  | yes |  |
| dementia | eat ash; eat stannum; focus | ash (stannum) | no | 10 |
| demonstain | time |  | yes |  |
| depression | eat goldenseal; eat plumbum | goldenseal (plumbum) | no | 6 |
| deteriorate | time |  | yes |  |
| diminished | eat bellwort; eat cuprum | bellwort (cuprum) | no | 12 |
| disfigurement | smoke valerian; smoke realgar |  | no |  |
| disloyalty | smoke valerian; smoke realgar |  | no | 15 |
| disrupted | concentrate |  | yes | 2 |
| dissonance | eat goldenseal; eat plumbum | goldenseal (plumbum) | yes | 14 |
| dizziness | eat goldenseal; eat plumbum; focus | goldenseal (plumbum) | no | 9 |
| earworm | smoke elm; smoke cinnabar |  | no | 8 |
| empoweredloshre | time |  | yes |  |
| empoweredmannaz | time |  | yes |  |
| enlightenment |  |  | yes |  |
| enmesh | time |  | yes |  |
| ensorcelled | time |  | yes |  |
| entangled | writhe |  | yes | 2 |
| epilepsy | eat goldenseal; eat plumbum; focus | goldenseal (plumbum) | no | 8 |
| fear | compose |  | no | 5 |
| flamefisted | time |  | yes |  |
| flushings | eat ginseng; eat ferrum | ginseng (ferrum) | no | 5 |
| fratricide | eat lobelia; eat argentum | lobelia (argentum) | no | 25 |
| freezing | salve caloric |  | no |  |
| frostbite | salve caloric |  | no | 5 |
| frozen | salve caloric |  | no | 15 |
| fulminated | eat goldenseal; eat plumbum | goldenseal (plumbum) | no | 8 |
| generosity | eat bellwort; eat cuprum | bellwort (cuprum) | no | 16 |
| grievouswounds | elixir health to torso |  | no | 3 |
| guilt | eat lobelia; eat argentum | lobelia (argentum) | no | 8 |
| haemophilia | eat ginseng; eat ferrum | ginseng (ferrum) | no | 11 |
| hallucinations | eat ash; eat stannum; focus | ash (stannum) | no | 9 |
| hamstrung | time |  | yes |  |
| hatred | time |  | yes |  |
| healthleech | eat kelp; eat aurum | kelp (aurum) | no | 8 |
| heartseed | restoration restoration to body |  | yes | 2 |
| hecatecurse | time |  | yes |  |
| hellsight | smoke valerian; smoke realgar |  | no | 12 |
| hindered | time |  | yes |  |
| homunculusmercury | time |  | yes |  |
| horror | eat lobelia; eat argentum | lobelia (argentum) | yes | 9 |
| hypersomnia | eat ash; eat stannum | ash (stannum) | no | 9 |
| hypochondria | eat lobelia; eat argentum | lobelia (argentum) | no | 5 |
| hypothermia | restoration restoration to body |  | yes | 2 |
| icebound | writhe |  | yes | 2 |
| icefisted | time |  | yes |  |
| impaled | writhe |  | yes | 2 |
| impatience | eat goldenseal; eat plumbum | goldenseal (plumbum) | no | 4 |
| indifference | eat bellwort; eat cuprum | bellwort (cuprum) | no | 25 |
| inquisition |  |  | yes |  |
| insomnia | eat goldenseal; eat plumbum | goldenseal (plumbum) | yes | 26 |
| internalbleeding | restoration restoration to body |  | yes | 8 |
| isolation |  |  | yes |  |
| itching | salve epidermal to body |  | no | 5 |
| justice | eat bellwort; eat cuprum | bellwort (cuprum) | no | 16 |
| kaisurge | time |  | yes |  |
| kkractlebrand | sip health |  | yes | 5 |
| laceratedthroat | restoration restoration to head |  | yes | 19 |
| lapsingconsciousness | time |  | no |  |
| latched | sip health |  | yes | 2 |
| lethargy | eat ginseng; eat ferrum | ginseng (ferrum) | no | 11 |
| lightbind | time |  | yes |  |
| loneliness | eat lobelia; eat argentum; focus | lobelia (argentum) | no | 16 |
| lovers | eat bellwort; eat cuprum; focus | bellwort (cuprum) | no | 14 |
| lovestruck | time |  | yes |  |
| manaleech | smoke valerian; smoke realgar |  | no | 13 |
| mangledhead | restoration restoration to head |  | yes | 8 |
| mangledleftarm | restoration restoration to arms |  | yes | 14 |
| mangledleftleg | restoration restoration to legs |  | yes | 8 |
| mangledrightarm | restoration restoration to arms |  | yes | 14 |
| mangledrightleg | restoration restoration to legs |  | yes | 8 |
| masochism | eat lobelia; eat argentum; focus | lobelia (argentum) | no | 8 |
| mildtrauma | restoration restoration to body |  | yes | 17 |
| mindclamp |  |  | yes |  |
| mindravaged | time |  | yes |  |
| muddled | time |  | yes |  |
| mycalium | eat goldenseal; eat plumbum | goldenseal (plumbum) | no | 5 |
| nausea | eat ginseng; eat ferrum | ginseng (ferrum) | no | 8 |
| numbedleftarm | time |  | yes |  |
| numbedrightarm | time |  | yes |  |
| pacified | eat bellwort; eat cuprum; focus | bellwort (cuprum) | no | 3 |
| palpatarfeed | time |  | yes |  |
| paralysis | eat bloodroot; eat magnesium | bloodroot (magnesium) | no | 3 |
| paranoia | eat ash; eat stannum; focus | ash (stannum) | no | 10 |
| parasite | eat kelp; eat aurum | kelp (aurum) | no | 7 |
| peace | eat bellwort; eat cuprum; focus | bellwort (cuprum) | no | 2 |
| penitence |  |  | yes |  |
| petrified | time |  | yes |  |
| phlogisticated | time |  | no |  |
| pinshot | time |  | yes |  |
| pressure | lungs pear; lungs calcite |  | yes | 25 |
| prone | stand |  | yes | 2 |
| pyramides | eat bloodroot; eat magnesium | bloodroot (magnesium) | no | 6 |
| pyre | eat bellwort; eat cuprum | bellwort (cuprum) | yes | 9 |
| rebbies | eat kelp; eat aurum | kelp (aurum) | no | 7 |
| recklessness | eat lobelia; eat argentum; focus | lobelia (argentum) | no | 8 |
| reeling | time |  | yes |  |
| retribution | eat bellwort; eat cuprum | bellwort (cuprum) | no | 6 |
| revealed | time |  | yes |  |
| sandfever | eat goldenseal; eat plumbum | goldenseal (plumbum) | no | 4 |
| scalded | time |  | yes | 16 |
| scrambledbrains | time |  | yes |  |
| scytherus | eat ginseng; eat ferrum | ginseng (ferrum) | no | 3 |
| selarnia | salve mending to body |  | no | 20 |
| sensitivity | eat kelp; eat aurum | kelp (aurum) | no | 7 |
| serioustrauma | restoration restoration to body |  | yes | 17 |
| shadowmadness | eat goldenseal; eat plumbum | goldenseal (plumbum) | no | 6 |
| shivering | salve caloric |  | no | 15 |
| shyness | eat goldenseal; eat plumbum; focus | goldenseal (plumbum) | no | 12 |
| silenced | time |  | yes |  |
| silver | time |  | no |  |
| skullfractures | elixir health to head |  | no | 8 |
| slashedthroat | salve epidermal to head |  | no | 19 |
| sleeping | wake |  | yes | 2 |
| slickness | smoke valerian; smoke realgar; eat bloodroot; eat magnesium | bloodroot (magnesium) | no | 3 |
| slimeobscure | time |  | yes |  |
| snared | time |  | yes |  |
| solarburn | time |  | yes |  |
| speechless | time |  | yes |  |
| spiritburn | eat lobelia; eat argentum | lobelia (argentum) | no | 11 |
| stridulating | eat bellwort; eat cuprum | bellwort (cuprum) | yes | 24 |
| stupidity | eat goldenseal; eat plumbum; focus | goldenseal (plumbum) | no | 8 |
| stuttering | salve epidermal to head; focus |  | no | 19 |
| succumbed | time |  | yes |  |
| temperedcholeric | eat ginger; eat antimony | ginger (antimony) | yes | 14 |
| temperedmelancholic | eat ginger; eat antimony | ginger (antimony) | yes | 14 |
| temperedphlegmatic | eat ginger; eat antimony | ginger (antimony) | yes | 14 |
| temperedsanguine | eat ginger; eat antimony | ginger (antimony) | yes | 14 |
| tenderskin | eat lobelia; eat argentum | lobelia (argentum) | no | 11 |
| tension | smoke elm; smoke cinnabar |  | no | 16 |
| timeflux | time |  | yes |  |
| timeloop | eat bellwort; eat cuprum | bellwort (cuprum) | no | 4 |
| tonguetied | restoration restoration to head |  | yes | 18 |
| torntendons | elixir health to legs |  | no | 10 |
| transfixation | writhe |  | yes | 2 |
| trueblind | time |  | yes |  |
| unconsciousness | time |  | yes |  |
| unweavingbody | eat ginseng; eat ferrum | ginseng (ferrum) | yes | 25 |
| unweavingmind | eat goldenseal; eat plumbum | goldenseal (plumbum) | yes | 25 |
| unweavingspirit | smoke elm; smoke cinnabar |  | no | 25 |
| vertigo | eat lobelia; eat argentum; focus | lobelia (argentum) | no | 9 |
| vinewreathed | time |  | yes |  |
| vitiated | time |  | yes |  |
| vitrified | time |  | yes |  |
| voidfisted | time |  | yes |  |
| voyria | sip immunity |  | no | 2 |
| waterbonds | time |  | yes |  |
| weakenedmind |  |  | yes |  |
| weariness | eat kelp; eat aurum | kelp (aurum) | no | 6 |
| webbed | writhe |  | yes | 2 |
| whisperingmadness | eat lobelia; eat argentum | lobelia (argentum) | yes | 11 |
| woeconstrained | time |  | yes |  |
| wristfractures | elixir health to arms |  | no | 11 |

## Priorities with no cure row

The package's default priority for a stack (`burning4`) or an affliction afflictions.json does not list.

| Rule | Priority | Source |
|---|---|---|
| `prio.burning4` | 6 | src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Default_Curing_Prios.lua ataxia_defaultCuringPrios() |
| `prio.burning5` | 4 | src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Default_Curing_Prios.lua ataxia_defaultCuringPrios() |
| `prio.pyre3` | 5 | src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Default_Curing_Prios.lua ataxia_defaultCuringPrios() |
| `prio.unweavingbody3` | 2 | src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Default_Curing_Prios.lua ataxia_defaultCuringPrios() |
| `prio.unweavingbody4` | 2 | src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Default_Curing_Prios.lua ataxia_defaultCuringPrios() |
| `prio.unweavingbody5` | 2 | src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Default_Curing_Prios.lua ataxia_defaultCuringPrios() |
| `prio.unweavingmind3` | 2 | src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Default_Curing_Prios.lua ataxia_defaultCuringPrios() |
| `prio.unweavingmind4` | 2 | src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Default_Curing_Prios.lua ataxia_defaultCuringPrios() |
| `prio.unweavingmind5` | 2 | src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Default_Curing_Prios.lua ataxia_defaultCuringPrios() |
| `prio.unweavingspirit3` | 2 | src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Default_Curing_Prios.lua ataxia_defaultCuringPrios() |
| `prio.unweavingspirit4` | 2 | src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Default_Curing_Prios.lua ataxia_defaultCuringPrios() |
| `prio.unweavingspirit5` | 2 | src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Default_Curing_Prios.lua ataxia_defaultCuringPrios() |

## Inputs

| File | sha256 (16) |
|---|---|
| `kb/sim/rules_hand.json` | `e66acfb4890f2c95` |
| `kb/mechanics/clocks.json` | `ba2f7943f4e490c0` |
| `kb/afflictions/afflictions.json` | `1fe2c0394ca42b4b` |
| `.claude/databases/venoms.yaml` | `ef137a5cd8214ad7` |
| `src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Default_Curing_Prios.lua` | `5fa60d4229dfd770` |
| `src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua` | `4f3cccaf6c09db12` |
| `src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/008_V3_Integration.lua` | `0a4b93e9fa221aa8` |
| `src_new/scripts/levi_ataxia/levi/ataxia/can(x)/003_Lock_breakers.lua` | `837e6b4465b22614` |
| `tools/sim/gates_whole.json` | `1de3efb56ed6f8f7` |
