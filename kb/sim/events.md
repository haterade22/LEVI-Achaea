---
topic: the Serpent logs as events, and the race between the DSTAB and the eat
confidence: MEASURED (counted from log rows; boards are the loggers' beliefs)
generated_by: tools/kb_events.py
---

# The Serpent logs: census and race

**GENERATED. Do not edit.** Run `python tools/kb_events.py`. Plan step 7.2, stage 1a: the logs first, before the engine.

Freeze file `tools/sim/gates_whole.json`, sha256 `1de3efb56ed6f8f7de1ab27e3f767688b1c2f433f5d28d118f718b723f41217b`.

## The race, in one row

At a DSTAB, is the victim's eat still down? **PHASE** is the time until the eat comes back: positive means down, negative
means up that long already. A pair (this DSTAB, the next attack) is won by **the strike** when the eat is still down at the
next attack, and by **the herb** when it is back. The clock lengths alone do not decide it: where each clock stands does.

**Golden row: PASS.** `Z5` row 196: PHASE +0.602 at the strike; the next attack at row 248, 1.807 s later; the eat clock 1.613 s; the strike first by 0.567 s.

## The race, per log

| Log | DSTABs | Paired | Strike first | of them, eat down at the strike | Herb first | One eat between | PHASE at the strike, median | Gap, median | Eat clock, median | Delay to the first eat, median |
|---|---|---|---|---|---|---|---|---|---|---|
| az | 45 | 43 | 30 | 22 | 13 | 26 | +0.506 | 1.800 | 1.526 | 0.140 |
| Z5 | 49 | 47 | 39 | 34 | 8 | 31 | +0.567 | 1.840 | 1.499 | 0.159 |
| g | 24 | 22 | 22 | 19 | 0 | 15 | +0.859 | 1.898 | 1.510 | 0.134 |
| X | 86 | 82 | 74 | 69 | 8 | 59 | +0.815 | 1.820 | 1.540 | 0.110 |
| all | 204 | 194 | 165 | 144 | 29 | 131 | +0.685 | 1.830 | 1.530 | 0.134 |

- A DSTAB is unpaired when no attack follows within 10 s (`kb_timing.DISENGAGED`), or when the log shows no eat and
  recovery pair around the next attack. An eat whose recovery line comes more than 3.0 s later counts as not shown.
- Rows in one packet share a stamp. On a tie the row order decides: a recovery line after the attack line means the
  eat was still down.
- **One eat between**: the victim ate once between the two attacks. In a strike-first pair, that eat came back and was
  spent again before the next attack: the herb cured one thing, and the next strike landed on a spent eat.
- The delay to the first eat runs from the later of the strike and the eat's return, to the first eat before the next
  attack. A negative delay (an eat in the same packet as the strike) is left out of its median. It is the logger's
  reaction, not a pure SSC delay: an affliction the logger did not cure with the eat also waits here.
- The loggers ran their own curing, so these are THEIR races, not ours.
- 12 paired rows tie at the stamp (the eat's return and the next attack in one packet). The row order gave 8 to the
  strike and 4 to the herb: az 1092, az 1699, az 2077, Z5 864, Z5 1482, Z5 2186, Z5 3796, g 549, X 1269, X 1550, X 3727, X 6116.

## Census

Game lines only: a client's own echoes are not counted. The 'gaze' line is an IMPULSE that bites: each of the 22 BITEs
has it in its packet, and each of the 22 'gaze' lines a BITE (az 1238-1242, Z5 534-537, X 293-296).

The second-venom line follows every DSTAB, hit or miss: second-venom lines = pricks + misses in az yes, Z5 yes, g yes, X yes.

| Line | az | Z5 | g | X |
|---|---|---|---|---|
| DSTAB: 'quickly pricks you with his dirk' | 45 | 49 | 24 | 86 |
| DSTAB, second venom: 'Striking like a snake, ... follows the first attack with another' (follows hits and misses) | 48 | 52 | 24 | 93 |
| DSTAB missed: 'misses you with his dirk' | 3 | 3 | 0 | 7 |
| BITE: 'sinks his fangs into your body' | 7 | 8 | 0 | 7 |
| FLAY of the shield | 12 | 5 | 4 | 5 |
| FLAY of rebounding | 13 | 0 | 3 | 14 |
| FLAY, the whip lands: 'With fluid grace, ... snaps his wrist' | 26 | 6 | 7 | 19 |
| An attack stopped by our shield | 1 | 1 | 5 | 2 |
| An attack rebounded onto the Serpent: 'The attack rebounds back onto ...!' | 3 | 0 | 2 | 2 |
| 'The attack rebounds off your aura of protection!' | 3 | 0 | 2 | 3 |
| SNAP: 'snaps his fingers in front of you' | 7 | 5 | 2 | 4 |
| SNAP, bare: 'snaps his fingers.' | 0 | 0 | 1 | 0 |
| IMPULSE: 'fixes his gaze to yours and hisses a sharp command' (in the packet of each BITE, 22 of 22) | 7 | 8 | 0 | 7 |
| 'Your equilibrium is thrown off by an awakened mental impulse' | 0 | 0 | 0 | 4 |
| 'A terrible sense of unease comes over you' (the hypochondria gain line) | 7 | 4 | 2 | 4 |
| The Serpent's SHRUG: 'hunches his shoulders and lets out a soft hiss' | 3 | 3 | 0 | 9 |
| A pet's bite lands (az and g: a tree snake, X: a rattlesnake, Z5: a saw-scaled viper) | 7 | 18 | 7 | 14 |
| A pet's bite meets the waxy coating | 4 | 3 | 2 | 15 |
| 'You scream out in agony as a vicious venom tears through your body' | 2 | 5 | 0 | 4 |
| Nausea's vomit line | 3 | 2 | 0 | 3 |
| Darkshade's burn: 'Your skin prickles and burns.' (a gain only when the board lacks darkshade) | 2 | 0 | 0 | 6 |
| Eat, on the eat clock | 96 | 85 | 49 | 174 |
| Eat moss or potash (own clock) | 1 | 0 | 0 | 4 |
| Eat pear or calcite (spends the lungs) | 0 | 0 | 0 | 0 |
| Smoke | 24 | 14 | 10 | 27 |
| Salve | 5 | 1 | 0 | 2 |
| Salve on slick skin: 'The salve slides off your oily skin' (no salve clock spent) | 0 | 0 | 0 | 2 |
| Sip | 9 | 11 | 2 | 19 |
| Tree | 12 | 7 | 2 | 22 |
| Focus | 3 | 11 | 0 | 25 |
| FITNESS | 0 | 0 | 0 | 0 |
| Salt (Alchemist) | 0 | 7 | 0 | 0 |
| Accelerate (Depthswalker) | 0 | 0 | 0 | 1 |
| Dagaz rune tick | 11 | 0 | 0 | 0 |
| Our shield goes up | 13 | 7 | 5 | 10 |
| Our rebounding comes up | 17 | 0 | 9 | 24 |
| Sileris applied | 13 | 14 | 7 | 15 |
| Sileris hardens: the coating is up | 12 | 9 | 7 | 15 |
| The coating goes: ripped away, dissolves, or sloughs off | 13 | 10 | 7 | 16 |
| Our shield falls: we moved or acted | 1 | 2 | 2 | 5 |
| Our rebounding falls: 'Your aura of weapons rebounding disappears' | 4 | 0 | 6 | 9 |
| Refused: paralysis | 12 | 30 | 2 | 4 |
| Refused: too weary | 3 | 0 | 0 | 0 |
| Refused: a salve on slick skin | 0 | 0 | 0 | 2 |
| Refused: balance or equilibrium | 0 | 0 | 0 | 1 |
| Refused: the humour clock | 0 | 5 | 0 | 0 |
| Refused: Salt in its lockout | 0 | 3 | 0 | 0 |
| Refused: Accelerate in its lockout | 0 | 0 | 0 | 1 |
| Refused: the Alchemist's STUDY in its lockout | 0 | 1 | 0 | 0 |
| 'Equilibrium used: N s.' (the game's cost line) | 24 | 22 | 9 | 96 |
| 'Balance used: N s.' | 0 | 8 | 21 | 78 |
| 'You have recovered equilibrium' | 23 | 21 | 10 | 96 |
| 'You have recovered balance on all limbs' | 41 | 55 | 11 | 79 |
| Salt is back: 'You may channel alchemical energy to heal yourself once again' | 0 | 7 | 0 | 0 |
| Accelerate is back: 'You may accelerate time to cleanse your afflictions once again' | 0 | 0 | 0 | 1 |
| Death | 1 | 1 | 0 | 0 |
| Events after the last prompt (stamped at that prompt, marked late) | 2 | 3 | 0 | 0 |

**Afflictions gained, by the game's own line** (`afflictions.json` `afflicted_msg`, plus the 8 lines in `kb_events.EXTRA_GAINS`, each with the rows that tag it), the ten most:

Where afflictions.json gives several afflictions one message, `kb_events.SHARED` picks one from the loggers' own tags (the ugliness lines are disloyalty). An unresolved shared message names all of them, joined by `|`.

- `az`: paralysis 56, darkshade 12, weariness 11, asthma 10, clumsiness 10, anorexia 8, slickness 8, disrupted 7, fratricide 7, hypochondria 7
- `Z5`: paralysis 51, fratricide 18, slickness 18, disloyalty 11, asthma 10, weariness 9, clumsiness 6, stupidity 6, epilepsy 5, impatience 5
- `g`: paralysis 26, clumsiness 11, fratricide 7, darkshade 5, weariness 5, asthma 2, disrupted 2, generosity 2, hypochondria 2, slickness 2
- `X`: paralysis 100, clumsiness 20, weariness 20, asthma 16, fratricide 14, recklessness 9, darkshade 8, nausea 8, vertigo 8, addiction 7

## Suppliers, re-measured in every log

`kb/mechanics/foundations.md` (Timed effects) calls each of these single-source. Median (min-max, n); `-` means none.

| Supplier | foundations.md before 2026-11-07 | az | Z5 | g | X |
|---|---|---|---|---|---|
| Hypochondria to nausea | +3.12, one fight (Z5) | 3.13 (3.09-3.15, n=4) | 3.13 (3.12-3.14, n=2) | - | 3.10 (3.09-3.11, n=2) |
| Hypochondria to lethargy | +6.24, one fight (Z5) | 6.20 (6.12-9.30, n=4) | 4.66 (3.08-6.24, n=2) | - | 6.23 (n=1) |
| Hypochondria to impatience | +9.31, one fight (Z5) | 9.23 (9.11-12.42, n=3) | 9.31 (n=1) | - | 9.32 (n=1) |
| SNAP to anorexia | 9.0-11.0, 7 of 7, one player (az) | 9.99 (9.02-10.99, n=7) | - | - | - |
| Snake line to snake line | about 8.1, one fight (g) | 8.07 (0.52-16.43, n=8) | 8.09 (5.60-18.79, n=20) | 8.09 (0.55-16.38, n=8) | 8.19 (3.31-17.17, n=24) |

A chain delay runs from the hypochondria gain to the first gain of that affliction before the hypochondria is
cured. A SNAP delay runs to the next suggested anorexia line ('The thought of food revolts you all of a sudden.')
within 15 s. A venom's anorexia does not count.
A snake gap runs between two pet lines (a hit or the waxy coating) within 20 s.
Late events (after the last prompt) are left out of these delays.

## Every DSTAB

| Log | Row | t | PHASE | Next | Next row | Gap | Eats between | Eat clock | Winner | By | First eat | Delay |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| az | 126 | 69283.312 | -0.098 | dstab | 168 | 1.789 | 2 | 1.497 | strike | 1.437 | bloodroot leaf | +0.131 |
| az | 168 | 69285.101 | +1.437 | dstab.miss | 219 | 3.217 | 2 | 1.399 | strike | 1.399 | bloodroot leaf | +0.265 |
| az | 316 | 69293.526 | +1.272 | dstab | 351 | 1.545 | 1 | 1.462 | strike | 1.287 | bloodroot leaf | +0.098 |
| az | 351 | 69295.071 | +1.287 | dstab | 403 | 3.089 | 1 | 1.237 | herb | 0.107 | piece of kelp | +0.458 |
| az | 403 | 69298.160 | -0.107 | dstab | 522 | 3.705 | 3 | 1.597 | strike | 1.364 | bloodroot leaf | +0.174 |
| az | 522 | 69301.865 | +1.364 | flay | 558 | 1.685 | 0 | 1.597 | herb | 0.321 | - | - |
| az | 660 | 69308.496 | -1.617 | dstab | 701 | 1.710 | 2 | 1.502 | strike | 1.496 | bloodroot leaf | +0.095 |
| az | 701 | 69310.206 | +1.496 | dstab | 746 | 2.362 | 1 | 1.301 | strike | 0.667 | bloodroot leaf | +0.232 |
| az | 746 | 69312.568 | +0.667 | - | - | - | - | - | - | - | - | - |
| az | 982 | 69324.336 | -11.101 | dstab | 1049 | 3.103 | 2 | 1.481 | strike | 0.096 | bloodroot leaf | +0.104 |
| az | 1049 | 69327.439 | +0.096 | dstab | 1092 | 1.731 | 1 | 1.537 | herb | 0.007 | bloodroot leaf | +0.091 |
| az | 1092 | 69329.170 | -0.007 | dstab | 1113 | 1.787 | 1 | 1.598 | strike | 0.000 | bloodroot leaf | +0.189 |
| az | 1113 | 69330.957 | +0.000 | flay | 1169 | 1.797 | 2 | 1.664 | strike | 1.581 | bloodroot leaf | +0.157 |
| az | 1205 | 69334.692 | +1.324 | bite | 1242 | 1.697 | 1 | 1.405 | strike | 1.221 | bloodroot leaf | +0.189 |
| az | 1665 | 69368.540 | -1.366 | dstab | 1699 | 1.555 | 1 | 1.480 | herb | 0.069 | bloodroot leaf | +0.006 |
| az | 1699 | 69370.095 | -0.069 | dstab | 1729 | 1.897 | 1 | 1.715 | strike | 0.000 | bloodroot leaf | +0.182 |
| az | 1729 | 69371.992 | +0.000 | bite | 1760 | 1.894 | 1 | 1.585 | herb | 0.204 | bloodroot leaf | +0.105 |
| az | 1805 | 69375.471 | +1.464 | dstab.miss | 1844 | 1.794 | 0 | 1.470 | herb | 0.330 | - | - |
| az | 1879 | 69379.120 | -0.108 | dstab | 1929 | 2.918 | 2 | 1.590 | strike | 0.276 | bloodroot leaf | +0.080 |
| az | 1929 | 69382.038 | +0.276 | dstab | 1974 | 1.715 | 1 | 1.426 | strike | 0.089 | bloodroot leaf | +0.102 |
| az | 1974 | 69383.753 | +0.089 | flay | 2020 | 1.815 | 1 | 1.531 | herb | 0.110 | bloodroot leaf | +0.085 |
| az | 2077 | 69388.943 | +0.080 | dstab | 2102 | 1.780 | 1 | 1.517 | strike | 0.000 | bloodroot leaf | +0.183 |
| az | 2102 | 69390.723 | +0.000 | dstab | 2158 | 1.714 | 1 | 1.541 | herb | 0.088 | bloodroot leaf | +0.085 |
| az | 2158 | 69392.437 | -0.088 | flay | 2235 | 1.862 | 2 | 1.563 | strike | 1.360 | bloodroot leaf | +0.080 |
| az | 2524 | 69408.757 | +1.517 | dstab | 2543 | 1.944 | 1 | 1.230 | strike | 1.222 | ginseng root | +0.419 |
| az | 2543 | 69410.701 | +1.222 | dstab.miss | 2581 | 1.688 | 1 | 1.362 | strike | 1.176 | bloodroot leaf | +0.280 |
| az | 2605 | 69414.164 | +1.046 | flay | 2659 | 1.794 | 1 | 1.459 | strike | 0.913 | bloodroot leaf | +0.202 |
| az | 2708 | 69417.536 | +0.928 | flay | 2766 | 1.801 | 1 | 1.464 | strike | 0.686 | bloodroot leaf | +0.095 |
| az | 2804 | 69420.964 | +0.675 | dstab | 2834 | 1.764 | 1 | 1.501 | strike | 0.506 | ginseng root | +0.094 |
| az | 2834 | 69422.728 | +0.506 | flay | 2876 | 1.842 | 1 | 1.526 | strike | 0.390 | bloodroot leaf | +0.200 |
| az | 3001 | 69430.305 | +1.140 | bite | 3025 | 1.778 | 1 | 1.508 | strike | 1.043 | bloodroot leaf | +0.173 |
| az | 3105 | 69435.422 | +0.995 | flay | 3217 | 3.447 | 2 | 1.481 | strike | 0.852 | bloodroot leaf | +0.081 |
| az | 3253 | 69440.641 | +0.722 | flay | 3285 | 1.758 | 1 | 1.450 | strike | 0.634 | bloodroot leaf | +0.220 |
| az | 3310 | 69444.043 | +0.660 | flay | 3354 | 1.895 | 1 | 1.547 | strike | 0.461 | bloodroot leaf | +0.149 |
| az | 3446 | 69451.282 | +0.087 | dstab | 3481 | 1.895 | 2 | 1.622 | strike | 1.337 | bloodroot leaf | +0.006 |
| az | 3481 | 69453.177 | +1.337 | dstab | 3511 | 1.704 | 1 | 1.573 | strike | 1.213 | bloodroot leaf | +0.007 |
| az | 3511 | 69454.881 | +1.213 | dstab | 3547 | 1.813 | 1 | 1.559 | strike | 1.195 | bloodroot leaf | +0.236 |
| az | 3547 | 69456.694 | +1.195 | flay | 3598 | 1.800 | 1 | 1.518 | strike | 0.996 | bloodroot leaf | +0.083 |
| az | 3665 | 69461.732 | +0.986 | bite | 3696 | 1.800 | 1 | 1.538 | strike | 0.953 | ginseng root | +0.229 |
| az | 3729 | 69465.272 | +1.135 | bite | 3756 | 1.857 | 0 | 1.637 | herb | 0.722 | - | - |
| az | 3769 | 69468.782 | -2.375 | bite | 3799 | 2.526 | 0 | 1.637 | herb | 4.901 | - | - |
| az | 3828 | 69474.491 | -8.084 | dstab | 3845 | 1.775 | 0 | 1.637 | herb | 9.859 | - | - |
| az | 3845 | 69476.266 | -9.859 | dstab | 3861 | 1.832 | 0 | 1.637 | herb | 11.691 | - | - |
| az | 3861 | 69478.098 | -11.691 | bite | 3874 | 1.819 | 0 | 1.637 | herb | 13.510 | - | - |
| az | 3886 | 69481.623 | -15.216 | - | - | - | - | - | - | - | - | - |
| Z5 | 122 | 71.115 | +0.775 | dstab | 196 | 1.814 | 1 | 1.489 | strike | 0.602 | magnesium chip | +0.152 |
| Z5 | 196 | 72.929 | +0.602 | dstab | 248 | 1.807 | 1 | 1.613 | strike | 0.567 | magnesium chip | +0.159 |
| Z5 | 248 | 74.736 | +0.567 | dstab | 328 | 1.844 | 1 | 1.533 | strike | 0.494 | magnesium chip | +0.238 |
| Z5 | 328 | 76.580 | +0.494 | dstab | 370 | 1.783 | 1 | 1.366 | strike | 0.308 | aurum flake | +0.231 |
| Z5 | 370 | 78.363 | +0.308 | dstab | 446 | 1.876 | 1 | 1.546 | strike | 0.110 | magnesium chip | +0.132 |
| Z5 | 446 | 80.239 | +0.110 | bite | 537 | 1.913 | 2 | 1.446 | strike | 1.446 | magnesium chip | +0.145 |
| Z5 | 589 | 83.746 | +1.445 | flay | 694 | 3.688 | 2 | 1.471 | strike | 1.049 | magnesium chip | +0.259 |
| Z5 | 712 | 89.054 | +1.199 | dstab | 788 | 2.138 | 1 | 1.452 | strike | 0.681 | magnesium chip | +0.168 |
| Z5 | 788 | 91.192 | +0.681 | dstab | 864 | 2.470 | 1 | 1.593 | strike | 0.007 | magnesium chip | +0.203 |
| Z5 | 864 | 93.662 | +0.007 | bite | 937 | 1.754 | 1 | 1.512 | strike | 0.000 | magnesium chip | +0.235 |
| Z5 | 1018 | 97.011 | +1.515 | dstab | 1078 | 1.989 | 1 | 1.538 | strike | 1.173 | magnesium chip | +0.109 |
| Z5 | 1078 | 99.000 | +1.173 | dstab | 1119 | 1.772 | 1 | 1.512 | strike | 0.925 | magnesium chip | +0.012 |
| Z5 | 1119 | 100.772 | +0.925 | bite | 1167 | 1.923 | 1 | 1.499 | strike | 0.754 | magnesium chip | +0.253 |
| Z5 | 1208 | 104.385 | +0.606 | dstab | 1257 | 1.874 | 1 | 1.583 | strike | 0.535 | magnesium chip | +0.220 |
| Z5 | 1257 | 106.259 | +0.535 | - | - | - | - | - | - | - | magnesium chip | +0.097 |
| Z5 | 1482 | 122.589 | -5.385 | flay | 1524 | 1.620 | 1 | 1.418 | strike | 0.000 | magnesium chip | +0.202 |
| Z5 | 1549 | 125.797 | +0.000 | dstab | 1621 | 1.840 | 1 | 1.542 | herb | 0.140 | magnesium chip | +0.158 |
| Z5 | 1621 | 127.637 | -0.140 | dstab | 1689 | 1.752 | 2 | 1.542 | strike | 1.442 | magnesium chip | +0.099 |
| Z5 | 1689 | 129.389 | +1.442 | dstab | 1738 | 1.919 | 1 | 1.521 | strike | 1.285 | magnesium chip | +0.241 |
| Z5 | 1738 | 131.308 | +1.285 | dstab | 1856 | 3.483 | 2 | 1.464 | strike | 1.036 | magnesium chip | +0.201 |
| Z5 | 1856 | 134.791 | +1.036 | dstab | 1925 | 1.787 | 1 | 1.529 | strike | 0.961 | magnesium chip | +0.183 |
| Z5 | 1925 | 136.578 | +0.961 | dstab | 1996 | 1.788 | 1 | 1.382 | strike | 0.708 | magnesium chip | +0.153 |
| Z5 | 1996 | 138.366 | +0.708 | dstab | 2058 | 1.833 | 1 | 1.545 | strike | 0.573 | magnesium chip | +0.153 |
| Z5 | 2058 | 140.199 | +0.573 | dstab | 2122 | 1.839 | 1 | 1.447 | strike | 0.318 | magnesium chip | +0.137 |
| Z5 | 2122 | 142.038 | +0.318 | dstab | 2186 | 1.756 | 1 | 1.453 | strike | 0.125 | magnesium chip | +0.110 |
| Z5 | 2186 | 143.794 | +0.125 | dstab | 2283 | 1.779 | 1 | 1.410 | strike | 0.000 | magnesium chip | +0.244 |
| Z5 | 2283 | 145.573 | +0.000 | dstab.miss | 2371 | 2.000 | 2 | 1.553 | strike | 1.343 | magnesium chip | +0.121 |
| Z5 | 2524 | 151.185 | +0.880 | - | - | - | - | - | - | - | magnesium chip | +0.200 |
| Z5 | 3796 | 194.907 | -9.743 | dstab | 3843 | 1.729 | 1 | 1.635 | strike | 0.000 | magnesium chip | +0.094 |
| Z5 | 3843 | 196.636 | +0.000 | dstab | 3912 | 1.779 | 2 | 1.593 | strike | 1.574 | magnesium chip | +0.239 |
| Z5 | 3912 | 198.415 | +1.574 | dstab.miss | 3980 | 1.920 | 1 | 1.402 | strike | 1.319 | magnesium chip | +0.263 |
| Z5 | 4070 | 202.129 | +1.049 | dstab | 4116 | 1.757 | 1 | 1.499 | strike | 0.922 | magnesium chip | +0.131 |
| Z5 | 4116 | 203.886 | +0.922 | dstab | 4233 | 3.519 | 2 | 1.524 | strike | 0.707 | magnesium chip | +0.276 |
| Z5 | 4233 | 207.405 | +0.707 | dstab | 4309 | 1.789 | 1 | 1.499 | strike | 0.640 | magnesium chip | +0.223 |
| Z5 | 4309 | 209.194 | +0.640 | dstab | 4383 | 1.834 | 1 | 1.462 | strike | 0.390 | magnesium chip | +0.122 |
| Z5 | 4383 | 211.028 | +0.390 | dstab | 4449 | 1.752 | 1 | 1.540 | strike | 0.303 | magnesium chip | +0.125 |
| Z5 | 4449 | 212.780 | +0.303 | dstab | 4528 | 1.794 | 1 | 1.455 | strike | 0.186 | magnesium chip | +0.222 |
| Z5 | 4528 | 214.574 | +0.186 | dstab | 4565 | 1.835 | 1 | 1.548 | strike | 0.098 | magnesium chip | +0.199 |
| Z5 | 4565 | 216.409 | +0.098 | dstab | 4642 | 1.940 | 1 | 1.615 | herb | 0.122 | magnesium chip | +0.105 |
| Z5 | 4642 | 218.349 | -0.122 | blocked.shield | 4764 | 4.104 | 3 | 1.425 | strike | 0.619 | magnesium chip | +0.060 |
| Z5 | 4827 | 225.681 | +0.909 | dstab | 4879 | 1.699 | 1 | 1.492 | strike | 0.958 | magnesium chip | +0.256 |
| Z5 | 4879 | 227.380 | +0.958 | dstab | 4907 | 1.847 | 0 | 1.492 | herb | 0.889 | - | - |
| Z5 | 4907 | 229.227 | -0.889 | bite | 4938 | 1.998 | 0 | 1.492 | herb | 2.887 | - | - |
| Z5 | 4971 | 232.765 | +1.438 | flay | 5022 | 1.949 | 0 | 1.438 | herb | 0.511 | - | - |
| Z5 | 5076 | 236.270 | +0.402 | flay | 5185 | 3.160 | 2 | 2.257 | strike | 1.408 | magnesium chip | +0.145 |
| Z5 | 5216 | 240.981 | -0.143 | flay | 5376 | 5.981 | 4 | 1.463 | strike | 0.422 | magnesium chip | +0.092 |
| Z5 | 5400 | 248.482 | +0.562 | bite | 5464 | 1.875 | 0 | 1.446 | herb | 1.313 | - | - |
| Z5 | 5482 | 252.003 | -2.959 | dstab | 5506 | 1.769 | 0 | 1.446 | herb | 4.728 | - | - |
| Z5 | 5506 | 253.772 | -4.728 | bite | 5537 | 1.860 | 0 | 1.446 | herb | 6.588 | - | - |
| g | 60 | 24.465 | - | dstab | 126 | 1.956 | 0 | - | - | - | - | - |
| g | 126 | 26.421 | - | dstab | 207 | 1.875 | 2 | 1.570 | strike | 1.305 | bloodroot leaf | +0.018 |
| g | 207 | 28.296 | +1.305 | dstab | 246 | 1.905 | 1 | 1.515 | strike | 1.088 | bloodroot leaf | +0.173 |
| g | 246 | 30.201 | +1.088 | dstab | 319 | 1.840 | 1 | 1.565 | strike | 1.019 | aurum flake | +0.206 |
| g | 319 | 32.041 | +1.019 | blocked.shield | 487 | 7.094 | 4 | 1.552 | strike | 0.623 | bloodroot leaf | +0.017 |
| g | 549 | 40.821 | -1.063 | dstab | 579 | 1.603 | 1 | 1.488 | strike | 0.000 | aurum flake | +0.115 |
| g | 579 | 42.424 | +0.000 | dstab | 673 | 1.783 | 2 | 1.487 | strike | 1.374 | bloodroot leaf | +0.118 |
| g | 673 | 44.207 | +1.374 | dstab | 761 | 1.846 | 1 | 1.574 | strike | 1.113 | bloodroot leaf | +0.011 |
| g | 761 | 46.053 | +1.113 | dstab | 844 | 2.259 | 1 | 1.560 | strike | 0.529 | bloodroot leaf | +0.115 |
| g | 844 | 48.312 | +0.529 | flay | 946 | 2.013 | 1 | 1.474 | strike | 0.110 | bloodroot leaf | +0.120 |
| g | 1051 | 52.422 | +1.232 | dstab | 1088 | 1.735 | 1 | 1.381 | strike | 0.989 | bloodroot leaf | +0.111 |
| g | 1088 | 54.157 | +0.989 | flay | 1120 | 2.090 | 1 | 1.512 | strike | 0.659 | bloodroot leaf | +0.248 |
| g | 1143 | 57.894 | +0.788 | flay | 1244 | 2.824 | 2 | 1.509 | strike | 1.201 | bloodroot leaf | +0.134 |
| g | 1422 | 65.797 | +1.106 | dstab | 1478 | 1.726 | 1 | 1.467 | strike | 0.975 | bloodroot leaf | +0.128 |
| g | 1478 | 67.523 | +0.975 | dstab | 1527 | 1.822 | 1 | 1.542 | strike | 0.808 | aurum flake | +0.113 |
| g | 1527 | 69.345 | +0.808 | dstab | 1594 | 1.762 | 1 | 1.566 | strike | 0.827 | bloodroot leaf | +0.215 |
| g | 1594 | 71.107 | +0.827 | dstab | 1647 | 1.999 | 1 | 1.323 | strike | 0.393 | bloodroot leaf | +0.242 |
| g | 1647 | 73.106 | +0.393 | blocked.shield | 1748 | 3.847 | 3 | 1.399 | strike | 1.399 | bloodroot leaf | +0.242 |
| g | 1814 | 81.720 | -0.144 | dstab | 1898 | 1.810 | 2 | 1.431 | strike | 1.327 | bloodroot leaf | +0.097 |
| g | 1898 | 83.530 | +1.327 | dstab | 1978 | 2.185 | 1 | 1.517 | strike | 0.891 | bloodroot leaf | +0.232 |
| g | 1978 | 85.715 | +0.891 | dstab | 2015 | 1.892 | 1 | 1.481 | strike | 0.680 | bloodroot leaf | +0.200 |
| g | 2015 | 87.607 | +0.680 | flay | 2100 | 1.913 | 1 | 1.486 | strike | 0.405 | bloodroot leaf | +0.152 |
| g | 2182 | 91.010 | +0.531 | blocked.shield | 2301 | 3.967 | 2 | 1.558 | strike | 0.006 | bloodroot leaf | +0.342 |
| g | 2356 | 98.175 | +0.221 | - | - | - | - | - | - | - | bloodroot leaf | +0.163 |
| X | 49 | 53658.160 | +0.940 | dstab | 101 | 2.690 | 2 | 1.580 | strike | 1.580 | magnesium chip | +0.200 |
| X | 101 | 53660.850 | +1.580 | dstab | 141 | 1.800 | 1 | 1.590 | strike | 1.400 | magnesium chip | +0.030 |
| X | 141 | 53662.650 | +1.400 | dstab | 167 | 1.750 | 1 | 1.520 | strike | 1.380 | magnesium chip | +0.210 |
| X | 167 | 53664.400 | +1.380 | dstab | 227 | 1.790 | 1 | 1.550 | strike | 1.230 | magnesium chip | +0.090 |
| X | 227 | 53666.190 | +1.230 | bite | 296 | 3.020 | 2 | 1.660 | strike | 1.650 | magnesium chip | +0.010 |
| X | 413 | 53672.610 | +1.120 | dstab | 492 | 1.780 | 1 | 1.540 | strike | 1.040 | plumbum flake | +0.160 |
| X | 492 | 53674.390 | +1.040 | flay | 545 | 1.840 | 1 | 1.630 | strike | 1.010 | magnesium chip | +0.180 |
| X | 593 | 53677.760 | +1.160 | dstab | 629 | 1.830 | 1 | 1.430 | strike | 0.850 | magnesium chip | +0.090 |
| X | 629 | 53679.590 | +0.850 | dstab | 713 | 4.670 | 3 | 1.630 | strike | 1.170 | magnesium chip | +0.210 |
| X | 713 | 53684.260 | +1.170 | flay | 747 | 1.720 | 1 | 1.480 | strike | 1.140 | argentum flake | +0.210 |
| X | 771 | 53687.640 | +1.070 | flay | 817 | 3.080 | 2 | 1.510 | strike | 1.200 | piece of kelp | +0.060 |
| X | 846 | 53692.250 | +1.260 | dstab | 868 | 1.720 | 1 | 1.460 | strike | 1.130 | magnesium chip | +0.130 |
| X | 868 | 53693.970 | +1.130 | dstab | 888 | 1.800 | 1 | 1.500 | strike | 0.930 | magnesium chip | +0.100 |
| X | 888 | 53695.770 | +0.930 | dstab | 952 | 1.830 | 1 | 1.540 | strike | 0.700 | magnesium chip | +0.060 |
| X | 952 | 53697.600 | +0.700 | dstab | 1077 | 7.750 | 4 | 1.480 | strike | 0.750 | magnesium chip | +0.050 |
| X | 1077 | 53705.350 | +0.750 | dstab | 1113 | 1.810 | 1 | 1.460 | strike | 0.490 | magnesium chip | +0.090 |
| X | 1113 | 53707.160 | +0.490 | dstab | 1136 | 1.850 | 1 | 1.610 | strike | 0.350 | magnesium chip | +0.100 |
| X | 1136 | 53709.010 | +0.350 | dstab | 1169 | 1.770 | 1 | 1.560 | strike | 0.310 | magnesium chip | +0.170 |
| X | 1169 | 53710.780 | +0.310 | dstab | 1219 | 1.870 | 1 | 1.540 | strike | 0.190 | magnesium chip | +0.210 |
| X | 1219 | 53712.650 | +0.190 | dstab | 1269 | 1.720 | 1 | 1.380 | strike | 0.090 | magnesium chip | +0.240 |
| X | 1269 | 53714.370 | +0.090 | dstab | 1318 | 1.780 | 1 | 1.540 | herb | 0.000 | magnesium chip | +0.150 |
| X | 1318 | 53716.150 | -0.000 | dstab | 1383 | 2.800 | 2 | 1.510 | strike | 0.550 | magnesium chip | +0.120 |
| X | 1383 | 53718.950 | +0.550 | dstab | 1445 | 1.770 | 1 | 1.530 | strike | 0.380 | magnesium chip | +0.070 |
| X | 1445 | 53720.720 | +0.380 | dstab | 1503 | 1.730 | 1 | 1.520 | strike | 0.220 | magnesium chip | +0.050 |
| X | 1503 | 53722.450 | +0.220 | dstab | 1550 | 1.860 | 1 | 1.610 | strike | 0.100 | magnesium chip | +0.130 |
| X | 1550 | 53724.310 | +0.100 | dstab | 1582 | 1.810 | 1 | 1.550 | herb | 0.000 | ginseng root | +0.160 |
| X | 1582 | 53726.120 | -0.000 | flay | 1616 | 1.780 | 0 | 1.550 | herb | 1.780 | - | - |
| X | 1726 | 53732.180 | +1.410 | bite | 1779 | 1.780 | 1 | 1.550 | strike | 1.370 | piece of kelp | +0.190 |
| X | 1949 | 53739.090 | +0.810 | dstab | 2016 | 1.840 | 1 | 1.570 | strike | 0.560 | ginseng root | +0.020 |
| X | 2016 | 53740.930 | +0.560 | dstab | 2104 | 3.240 | 2 | 1.640 | strike | 0.590 | magnesium chip | +0.030 |
| X | 2104 | 53744.170 | +0.590 | flay | 2154 | 1.700 | 1 | 1.650 | strike | 0.550 | magnesium chip | +0.010 |
| X | 2219 | 53749.060 | +0.540 | dstab | 2245 | 1.810 | 1 | 1.530 | strike | 0.310 | magnesium chip | +0.050 |
| X | 2245 | 53750.870 | +0.310 | flay | 2363 | 8.840 | 4 | 1.500 | herb | 2.070 | magnesium chip | +0.080 |
| X | 2394 | 53761.250 | +0.100 | dstab | 2421 | 1.800 | 2 | 1.620 | strike | 1.580 | magnesium chip | +0.040 |
| X | 2421 | 53763.050 | +1.580 | dstab | 2437 | 1.810 | 1 | 1.390 | strike | 1.300 | magnesium chip | +0.140 |
| X | 2437 | 53764.860 | +1.300 | dstab | 2456 | 1.850 | 1 | 1.530 | strike | 1.080 | piece of kelp | +0.100 |
| X | 2456 | 53766.710 | +1.080 | dstab | 2478 | 1.850 | 1 | 1.500 | strike | 0.810 | magnesium chip | +0.080 |
| X | 2478 | 53768.560 | +0.810 | flay | 2509 | 1.880 | 1 | 1.550 | strike | 0.550 | piece of kelp | +0.070 |
| X | 2560 | 53772.110 | +0.610 | dstab | 2618 | 2.670 | 2 | 1.500 | strike | 1.240 | magnesium chip | +0.060 |
| X | 2618 | 53774.780 | +1.240 | dstab | 2658 | 1.860 | 1 | 1.480 | strike | 0.970 | magnesium chip | +0.110 |
| X | 2658 | 53776.640 | +0.970 | dstab | 2694 | 1.720 | 1 | 1.510 | strike | 0.820 | magnesium chip | +0.060 |
| X | 2694 | 53778.360 | +0.820 | bite | 2727 | 1.790 | 1 | 1.560 | strike | 0.650 | magnesium chip | +0.060 |
| X | 2764 | 53782.780 | +1.300 | flay | 2799 | 1.770 | 1 | 1.550 | strike | 1.140 | magnesium chip | +0.060 |
| X | 2834 | 53787.080 | +0.330 | blocked.shield | 2875 | 2.220 | 2 | 1.570 | strike | 1.350 | magnesium chip | +0.060 |
| X | 2980 | 53794.190 | +1.380 | dstab | 3003 | 1.820 | 1 | 1.550 | strike | 1.310 | magnesium chip | +0.200 |
| X | 3003 | 53796.010 | +1.310 | - | - | - | - | - | - | - | piece of kelp | +0.140 |
| X | 3211 | 53814.350 | +0.090 | dstab | 3369 | 9.630 | 3 | 1.540 | herb | 1.980 | magnesium chip | +0.140 |
| X | 3369 | 53823.980 | -1.980 | dstab | 3407 | 1.770 | 2 | 1.480 | strike | 1.480 | magnesium chip | +0.200 |
| X | 3407 | 53825.750 | +1.480 | flay | 3461 | 3.180 | 2 | 1.530 | strike | 1.530 | magnesium chip | +0.170 |
| X | 3487 | 53830.580 | -0.120 | dstab | 3540 | 1.830 | 2 | 1.610 | strike | 1.440 | magnesium chip | +0.080 |
| X | 3540 | 53832.410 | +1.440 | dstab | 3579 | 1.760 | 1 | 1.590 | strike | 1.430 | magnesium chip | +0.160 |
| X | 3579 | 53834.170 | +1.430 | dstab | 3598 | 1.850 | 1 | 1.560 | strike | 1.310 | piece of kelp | +0.170 |
| X | 3598 | 53836.020 | +1.310 | flay | 3649 | 1.820 | 1 | 1.540 | strike | 1.070 | magnesium chip | +0.040 |
| X | 3688 | 53839.530 | +0.990 | dstab | 3727 | 1.780 | 1 | 1.550 | strike | 0.930 | magnesium chip | +0.170 |
| X | 3727 | 53841.310 | +0.930 | dstab | 3769 | 2.640 | 1 | 1.520 | herb | 0.000 | magnesium chip | +0.190 |
| X | 3769 | 53843.950 | -0.000 | flay | 3816 | 1.750 | 1 | 1.460 | herb | 0.110 | magnesium chip | +0.180 |
| X | 3841 | 53847.270 | -0.000 | - | - | - | - | - | - | - | magnesium chip | +0.120 |
| X | 4145 | 53872.070 | -0.000 | dstab | 4201 | 1.990 | 2 | 1.510 | strike | 1.310 | magnesium chip | +0.200 |
| X | 4201 | 53874.060 | +1.310 | dstab | 4221 | 1.730 | 1 | 1.550 | strike | 1.240 | magnesium chip | +0.110 |
| X | 4221 | 53875.790 | +1.240 | dstab | 4262 | 1.790 | 1 | 1.560 | strike | 1.080 | magnesium chip | +0.070 |
| X | 4262 | 53877.580 | +1.080 | flay | 4305 | 1.830 | 1 | 1.450 | strike | 0.860 | magnesium chip | +0.160 |
| X | 4329 | 53881.140 | +0.860 | - | - | - | - | - | - | - | magnesium chip | +0.170 |
| X | 4488 | 53894.170 | -5.270 | dstab.miss | 4533 | 1.840 | 2 | 1.590 | strike | 1.540 | magnesium chip | +0.050 |
| X | 4569 | 53898.120 | +1.200 | dstab | 4608 | 1.760 | 1 | 1.530 | strike | 1.130 | magnesium chip | +0.160 |
| X | 4608 | 53899.880 | +1.130 | flay | 4654 | 1.930 | 1 | 1.510 | strike | 0.930 | magnesium chip | +0.220 |
| X | 4698 | 53903.490 | +0.930 | dstab.miss | 4750 | 2.890 | 2 | 1.500 | strike | 1.380 | magnesium chip | +0.030 |
| X | 4796 | 53908.220 | +1.050 | dstab | 4840 | 1.750 | 1 | 1.510 | strike | 0.910 | magnesium chip | +0.100 |
| X | 4840 | 53909.970 | +0.910 | flay | 4873 | 1.820 | 1 | 1.580 | strike | 0.730 | magnesium chip | +0.060 |
| X | 4939 | 53913.500 | +0.660 | dstab | 5021 | 2.950 | 2 | 1.670 | strike | 1.090 | magnesium chip | +0.150 |
| X | 5021 | 53916.450 | +1.090 | dstab | 5064 | 1.740 | 1 | 1.530 | strike | 0.990 | magnesium chip | +0.110 |
| X | 5064 | 53918.190 | +0.990 | dstab | 5099 | 1.810 | 1 | 1.580 | strike | 0.760 | magnesium chip | +0.000 |
| X | 5099 | 53920.000 | +0.760 | flay | 5162 | 3.110 | 2 | 1.570 | strike | 0.950 | magnesium chip | +0.220 |
| X | 5370 | 53938.790 | +0.080 | dstab | 5414 | 1.780 | 2 | 1.660 | strike | 1.580 | magnesium chip | +0.080 |
| X | 5414 | 53940.570 | +1.580 | dstab | 5454 | 2.460 | 1 | 1.450 | strike | 0.690 | magnesium chip | +0.120 |
| X | 5454 | 53943.030 | +0.690 | dstab | 5499 | 1.750 | 1 | 1.530 | strike | 0.520 | magnesium chip | +0.050 |
| X | 5499 | 53944.780 | +0.520 | dstab | 5547 | 1.860 | 1 | 1.610 | strike | 0.310 | magnesium chip | +0.040 |
| X | 5547 | 53946.640 | +0.310 | dstab | 5606 | 2.980 | 2 | 1.540 | strike | 0.550 | magnesium chip | +0.180 |
| X | 5606 | 53949.620 | +0.550 | dstab | 5659 | 1.730 | 1 | 1.490 | strike | 0.510 | magnesium chip | +0.200 |
| X | 5659 | 53951.350 | +0.510 | dstab | 5703 | 1.840 | 1 | 1.530 | strike | 0.300 | magnesium chip | +0.100 |
| X | 5703 | 53953.190 | +0.300 | dstab.miss | 5756 | 1.800 | 1 | 1.510 | strike | 0.090 | magnesium chip | +0.080 |
| X | 5920 | 53961.050 | +0.540 | dstab | 5985 | 1.770 | 1 | 1.560 | strike | 0.400 | magnesium chip | +0.070 |
| X | 5985 | 53962.820 | +0.400 | dstab | 6047 | 1.830 | 1 | 1.550 | strike | 0.300 | magnesium chip | +0.180 |
| X | 6047 | 53964.650 | +0.300 | dstab | 6116 | 1.770 | 1 | 1.570 | strike | 0.110 | magnesium chip | +0.010 |
| X | 6116 | 53966.420 | +0.110 | bite | 6169 | 1.830 | 1 | 1.530 | herb | 0.000 | magnesium chip | +0.190 |
| X | 6377 | 53973.480 | +1.200 | dstab | 6471 | 2.690 | 1 | 1.470 | strike | 0.180 | magnesium chip | +0.200 |
| X | 6471 | 53976.170 | +0.180 | - | - | - | - | - | - | - | magnesium chip | +0.050 |
