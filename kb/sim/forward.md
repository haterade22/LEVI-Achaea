---
topic: forward simulator, first stage
confidence: a model, not a measurement
generated_by: tools/kb_sim.py
engine: tools/sim/forward.lua
---

# Forward simulator: asthma + weariness boards

**GENERATED. Do not edit.** Run `python tools/kb_sim.py`.

This page compares the victim's decisions on real boards, 20 s forward, against a strong attacker. It does not say who wins a fight. It does not say what the best system is. A verdict goes live only through the plan's shadow step and the user's word.

## Result

**Sanity: PASS.**
- **One shield now, against holding equilibrium: CONDITIONAL.** Closure rate: the first choice is better in 27 of 60 and worse in 1 (-0.236 to +0.030 of the rate). Worse with: shield allowed while paralysed. Softlock seconds, UNSETTLED: no clear result: better in 0 of 64, worse in 4 (-0.491 to +1.445 s).
- **A shield whenever equilibrium is up, against holding equilibrium: ROBUST.** Closure rate: the first choice is better in 37 of 61 comparisons, and worse in none (-0.379 to +0.000 of the rate). Softlock seconds, CONDITIONAL: the first choice is better in 49 of 64 and worse in 2 (-4.531 to +0.609 s). Worse with: strongest: gap 1.545, impatience at +2 and every 9.31.
- **Tree held for a softlock, against tree at once: ROBUST.** Closure rate: the second choice is better in 46 of 91 comparisons, and worse in none (-0.011 to +0.124 of the rate). Softlock seconds, UNSETTLED: no clear result: better in 0 of 96, worse in 0 (-0.274 to +0.070 s).
- **Asthma at the top of the eat order, against the default order: ROBUST.** Closure rate: the first choice is better in 90 of 96 comparisons, and worse in none (-0.401 to +0.012 of the rate). Softlock seconds, CONDITIONAL: the first choice is better in 63 of 96 and worse in 2 (-3.049 to +0.980 s). Worse with: no timed impatience.
- **Asthma at the top, against the package's Serpent rules, asthma wins the tie: ROBUST.** Closure rate: the first choice is better in 89 of 96 comparisons, and worse in none (-0.337 to -0.008 of the rate). Softlock seconds, CONDITIONAL: the first choice is better in 64 of 96 and worse in 2 (-2.031 to +0.637 s). Worse with: no timed impatience.
- **Asthma at the top, against the package's Serpent rules, paralysis wins the tie: ROBUST.** Closure rate: the first choice is better in 89 of 96 comparisons, and worse in none (-0.380 to +0.013 of the rate). Softlock seconds, CONDITIONAL: the first choice is better in 65 of 96 and worse in 2 (-2.876 to +0.887 s). Worse with: no timed impatience.

A negative number means the first choice is safer. Each comparison uses the same seeds for both choices.

## Rules written before the first run

**Sanity, before any verdict.** At the strongest row, the attacker must be at least as strong as the logs, or a verdict means little.
- **S1.** Each fitness board that reached the `true` label within 20 s in its log must reach it in the sim, with equilibrium held, tree at once and our default priority, for at least one attacker. The loggers ran their own priority tables, so this is not their policy.
- **S2.** Over the fitness boards, the sum of the strongest attacker's chance of `true` must be at or above the number of boards that reached it in the log.
- **S3.** Over all boards, the same for softlock.
- If one fails, the page prints MODEL TOO WEAK, and a verdict counts only as a note.

**A verdict.** For each board and policy, the attacker with the highest closure rate answers. The rates are averaged over the fitness boards. A decision is compared in each row of the sweep, under each setting of the other two decisions. A comparison is live unless both rates are within 3 points of 0 or of 1: such a row cannot compare the two choices.
- **ROBUST:** one choice is better by at least 3 points in at least half of the live comparisons, and worse by 3 points in none.
- **CONDITIONAL:** better by 3 points in some and worse by 3 points in others. The page names the rows on each side.
- **UNSETTLED:** anything else. This includes no difference at all, and fewer than 10 live comparisons.
- The same rule runs on softlock seconds, with a bar of 0.5 s, as a second reading. Every comparison is live there.

**One change came after a smoke test and before any verdict ran.** The first base had the shortest gap and a timed impatience at +2 s. Every board then closed in 100% of runs, whatever the victim did, against 2 of 10 in the logs. A row like that cannot compare decisions. So the base became the median gap with noise, and each board's own logged impatience time. The old base stayed as the strongest row, the sanity check moved to it, and the live rule above was added.

**Four changes came after the first verdict run. No bar moved.** (1) That run read the rule in one direction only, so a decision that was worse in 43 comparisons and better in none read as no result. The rule now reads both ways. (2) The FLAY gap row was added, because a shield verdict depends on it. (3) Runs per cell went from 200 to 400, to reduce noise near the 3 point bar. (4) Two eat orders were added, because the package does not run the default order against a Serpent: `astWear` and `paraAst` in `001_Anti_Priorities.lua`, both active by default. The first run's labels on the closure rate: one shield UNSETTLED, a shield whenever equilibrium is up ROBUST, tree held UNSETTLED, asthma first ROBUST.

## Sanity check

| Check | Sim | Log | Pass |
|---|---|---|---|
| S1 `az:3552`: chance of `true` | 100% | at +10.4 s | yes |
| S1 `az:3669`: chance of `true` | 100% | at +5.4 s | yes |
| S2 fitness boards: `true`, summed | 10.00 | 2 | yes |
| S3 all boards: softlock, summed | 35.00 | 7 | yes |

**Which row looks like the logs.** The policy is the one nearest to the logs. The log column is the same in every row: 2 `true` on the fitness boards, 7 softlocks on all boards.

| Row | `true`, summed over fitness boards | Softlock, summed over all boards | Asthma off in 5 s, our default order | Asthma off in 5 s, asthma first |
|---|---|---|---|---|
| base | 6.93 | 34.92 | 0.17 | 9.71 |
| gap 1.545 (min), no noise | 7.00 | 35.00 | 0.16 | 9.65 |
| gap 1.73 (p10) | 6.97 | 34.99 | 0.17 | 9.69 |
| gap 2.33 (median + 0.5) | 6.72 | 24.89 | 0.46 | 9.77 |
| gap 3.10 (p90) | 3.31 | 7.26 | 0.93 | 9.84 |
| no timed impatience | 4.84 | 34.93 | 0.17 | 9.71 |
| impatience every 9.31 | 9.96 | 35.00 | 0.19 | 9.71 |
| strongest: gap 1.545, impatience at +2 and every 9.31 | 10.00 | 35.00 | 0.01 | 9.52 |
| phi 0.33 (random inside the herb) | 6.95 | 34.96 | 0.10 | 9.69 |
| phi 1.0 (priority always wins) | 6.89 | 34.92 | 0.28 | 9.71 |
| shield cost 2.89 (ours) | 6.92 | 34.94 | 0.17 | 9.71 |
| shield cost 4.00 (Claes) | 6.94 | 34.95 | 0.17 | 9.71 |
| lockout 9.06 | 6.93 | 34.94 | 0.15 | 9.70 |
| lockout 9.97 | 6.94 | 34.95 | 0.16 | 9.71 |
| shield allowed while paralysed | 6.94 | 34.92 | 0.17 | 9.71 |
| FLAY gap 1.64 (median) | 6.92 | 34.94 | 0.19 | 9.71 |

**Log, for the same columns:** 2, 7, and asthma off within 5 s on 7 of 10 fitness boards.

A sim number above the log is expected: this attacker never misses and never stops. Closure is a threshold in the attack rate, so a small change in the gap moves it a lot. **The logs clear asthma far sooner than this attacker lets our default order do.** The loggers ran their own tables, and a real attacker does not re-land paralysis on every strike. So read the asthma-first verdict as "our table against asthma first, under pressure", and not as what those loggers should have done.

## Every policy, at two rows

**At the base,** over the 10 fitness boards:

| Equilibrium | Tree | Eat order | Closure rate | Softlock s | Asthma off in 5 s |
|---|---|---|---|---|---|
| always | now | asthma | 47% | 1.55 | 97% |
| always | hold | asthma | 51% | 1.53 | 97% |
| once | now | asthma | 52% | 1.74 | 97% |
| hold | now | asthma | 60% | 2.07 | 97% |
| once | hold | asthma | 61% | 1.69 | 97% |
| always | now | package | 64% | 1.62 | 60% |
| always | now | packageLate | 66% | 1.42 | 5% |
| hold | hold | asthma | 66% | 2.05 | 97% |
| always | hold | package | 67% | 1.59 | 60% |
| always | now | default | 67% | 1.40 | 2% |
| always | hold | packageLate | 68% | 1.44 | 3% |
| once | now | package | 69% | 2.86 | 60% |
| once | now | default | 69% | 4.18 | 3% |
| once | now | packageLate | 69% | 3.44 | 5% |
| hold | now | default | 69% | 3.94 | 2% |
| hold | now | package | 70% | 3.01 | 60% |
| hold | now | packageLate | 70% | 3.89 | 3% |
| once | hold | packageLate | 70% | 3.38 | 3% |
| once | hold | package | 70% | 2.78 | 60% |
| always | hold | default | 70% | 1.41 | 0% |
| hold | hold | package | 70% | 2.95 | 60% |
| hold | hold | packageLate | 70% | 3.88 | 2% |
| hold | hold | default | 70% | 3.92 | 0% |
| once | hold | default | 70% | 3.96 | 0% |

**At `gap 3.10 (p90)`, the gap row nearest to the logs,** over the 10 fitness boards:

| Equilibrium | Tree | Eat order | Closure rate | Softlock s | Asthma off in 5 s |
|---|---|---|---|---|---|
| always | now | packageLate | 6% | 0.17 | 50% |
| always | hold | packageLate | 6% | 0.17 | 49% |
| always | now | default | 6% | 0.17 | 20% |
| always | hold | default | 6% | 0.17 | 17% |
| once | now | asthma | 7% | 0.00 | 98% |
| always | now | asthma | 7% | 0.00 | 98% |
| always | hold | asthma | 7% | 0.00 | 98% |
| once | hold | asthma | 7% | 0.01 | 98% |
| once | hold | packageLate | 7% | 0.26 | 50% |
| once | now | packageLate | 7% | 0.26 | 51% |
| hold | now | asthma | 8% | 0.03 | 98% |
| hold | hold | asthma | 8% | 0.03 | 98% |
| always | now | package | 8% | 0.39 | 88% |
| always | hold | package | 9% | 0.41 | 88% |
| once | hold | default | 9% | 0.29 | 18% |
| once | now | default | 10% | 0.31 | 23% |
| once | now | package | 12% | 0.37 | 88% |
| once | hold | package | 13% | 0.38 | 88% |
| hold | now | package | 26% | 0.68 | 93% |
| hold | hold | package | 26% | 0.70 | 93% |
| hold | now | packageLate | 32% | 0.80 | 26% |
| hold | hold | packageLate | 33% | 0.81 | 24% |
| hold | hold | default | 33% | 0.78 | 7% |
| hold | now | default | 33% | 0.79 | 9% |

## The mechanism, from the logs

The plan says a winner needs a mechanism in a real log, or it counts as a simulator bug.

- **Asthma first.** In the 10 s after the 10 fitness boards, bloodroot took 27 of 57 eats and kelp took 11. Bloodroot was the first eat on 9 of 10. While asthma stays up the pipe stays shut, so slickness stays, so the salve stays shut (`cure-channels.md`).
- **The shield.** A Serpent flayed a shield 25 times, a median 1.03 s after it went up. The FLAY packet brought exactly one new affliction 21 times, none 5 times. 9 strikes hit a shield and did nothing, which this model does not count. So a shield costs the attacker about one venom, and no time.

## The closure rate per decision, by input

The mean difference over the 10 fitness boards, first choice minus second. The range covers the settings of the other two decisions.

| Input | One shield now, against holding equilibrium | A shield whenever equilibrium is up, against holding equilibrium | Tree held for a softlock, against tree at once | Asthma at the top of the eat order, against the default order | Asthma at the top, against the package's Serpent rules, asthma wins the tie | Asthma at the top, against the package's Serpent rules, paralysis wins the tie |
|---|---|---|---|---|---|---|
| base | -0.076 to -0.000 | -0.148 to -0.001 | +0.007 to +0.090 | -0.203 to -0.039 | -0.175 to -0.039 | -0.189 to -0.039 |
| gap 1.545 (min), no noise | -0.022 to -0.000 | -0.030 to +0.000 | +0.000 to +0.042 | -0.115 to -0.051 | -0.117 to -0.051 | -0.117 to -0.051 |
| gap 1.73 (p10) | -0.061 to +0.000 | -0.101 to +0.000 | +0.003 to +0.087 | -0.173 to -0.026 | -0.166 to -0.026 | -0.171 to -0.026 |
| gap 2.33 (median + 0.5) | -0.134 to -0.087 | -0.379 to -0.145 | -0.011 to +0.065 | -0.401 to -0.131 | -0.337 to -0.162 | -0.380 to -0.093 |
| gap 3.10 (p90) | -0.236 to -0.007 | -0.273 to -0.008 | -0.006 to +0.000 | -0.254 to +0.012 | -0.185 to -0.013 | -0.249 to +0.013 |
| no timed impatience | -0.056 to -0.002 | -0.101 to -0.003 | +0.016 to +0.064 | -0.135 to -0.036 | -0.105 to -0.036 | -0.117 to -0.036 |
| impatience every 9.31 | -0.053 to +0.000 | -0.190 to -0.008 | +0.004 to +0.099 | -0.317 to -0.135 | -0.228 to -0.135 | -0.303 to -0.135 |
| strongest: gap 1.545, impatience at +2 and every 9.31 | -0.031 to +0.000 | -0.047 to +0.000 | +0.000 to +0.039 | -0.127 to -0.054 | -0.125 to -0.054 | -0.127 to -0.054 |
| phi 0.33 (random inside the herb) | -0.078 to -0.000 | -0.193 to -0.000 | +0.005 to +0.078 | -0.244 to -0.044 | -0.224 to -0.044 | -0.225 to -0.044 |
| phi 1.0 (priority always wins) | -0.067 to -0.000 | -0.114 to -0.001 | +0.011 to +0.124 | -0.112 to -0.008 | -0.112 to -0.008 | -0.127 to -0.008 |
| shield cost 2.89 (ours) | -0.072 to +0.000 | -0.138 to -0.019 | +0.008 to +0.095 | -0.163 to -0.038 | -0.165 to -0.038 | -0.169 to -0.038 |
| shield cost 4.00 (Claes) | -0.082 to -0.000 | -0.151 to -0.001 | +0.006 to +0.089 | -0.207 to -0.038 | -0.176 to -0.038 | -0.191 to -0.038 |
| lockout 9.06 | -0.076 to -0.000 | -0.149 to -0.001 | +0.007 to +0.091 | -0.199 to -0.038 | -0.176 to -0.038 | -0.184 to -0.038 |
| lockout 9.97 | -0.073 to +0.000 | -0.141 to -0.000 | +0.006 to +0.081 | -0.196 to -0.042 | -0.162 to -0.042 | -0.180 to -0.042 |
| shield allowed while paralysed | -0.006 to +0.030 | -0.292 to -0.000 | -0.003 to +0.060 | -0.335 to -0.040 | -0.152 to -0.029 | -0.307 to -0.037 |
| FLAY gap 1.64 (median) | -0.050 to +0.000 | -0.097 to +0.000 | +0.008 to +0.083 | -0.176 to -0.043 | -0.157 to -0.043 | -0.173 to -0.043 |

## The boards

| Board | Class | FITNESS | Start | Log: soft, true, impatience (s) | Sim base: true, soft |
|---|---|---|---|---|---|
| `az:1210` | Runewarden | yes | asthma paralysis weariness | -, -, 1.7 | 100%, 100% |
| `az:2163` | Runewarden | yes | asthma darkshade fratricide hypochondria nausea paralysis weariness | -, -, 4.8 | 93%, 100% |
| `az:2713` | Runewarden | yes | asthma darkshade hypochondria paralysis weariness | -, -, 7.5 | 100%, 100% |
| `az:2840` | Runewarden | yes | asthma hypochondria lethargy nausea paralysis slickness weariness | -, -, 2.3 | 100%, 100% |
| `az:3006` | Runewarden | yes | asthma lethargy nausea paralysis weariness | -, -, 1.8 | 100%, 100% |
| `az:3258` | Runewarden | yes | asthma lethargy paralysis weariness | -, -, - | 0%, 100% |
| `az:3552` | Runewarden | yes | asthma darkshade hypochondria paralysis weariness | 8.6, 10.4, 6.8 | 100%, 100% |
| `az:3669` | Runewarden | yes | asthma darkshade hypochondria lethargy nausea paralysis weariness | 3.5, 5.4, 1.8 | 100%, 100% |
| `X:54` | Depthswalker | as if | asthma clumsiness hypersomnia hypochondria paralysis weariness | 11.0, -, 12.8 | 100%, 100% |
| `X:598` | Depthswalker | as if | asthma clumsiness fratricide hypersomnia masochism nausea paralysis weariness | -, -, - | 0%, 100% |
| `X:1175` | Depthswalker | as if | asthma clumsiness darkshade paralysis weariness | 15.3, -, - | 0%, 100% |
| `X:1450` | Depthswalker | as if | addiction asthma clumsiness darkshade paralysis weariness | 5.4, -, - | 0%, 100% |
| `X:2022` | Depthswalker | as if | addiction asthma epilepsy fratricide haemophilia masochism nausea paralysis vertigo weariness | -, -, - | 0%, 100% |
| `X:2442` | Depthswalker | as if | asthma clumsiness weariness | -, -, - | 0%, 100% |
| `X:2565` | Depthswalker | as if | asthma fratricide paralysis weariness | -, -, - | 0%, 100% |
| `X:2663` | Depthswalker | as if | asthma clumsiness fratricide paralysis weariness | -, -, - | 0%, 100% |
| `X:2769` | Depthswalker | as if | asthma fratricide haemophilia nausea paralysis weariness | -, -, - | 0%, 100% |
| `X:3008` | Depthswalker | as if | asthma clumsiness haemophilia nausea weariness | -, -, - | 0%, 100% |
| `X:3584` | Depthswalker | as if | asthma clumsiness fratricide weariness | -, -, - | 0%, 100% |
| `X:4267` | Depthswalker | as if | asthma clumsiness paralysis weariness | -, -, - | 0%, 100% |
| `X:4944` | Depthswalker | as if | addiction asthma clumsiness fratricide hypersomnia hypochondria paralysis weariness | -, -, 8.3 | 100%, 100% |
| `X:5504` | Depthswalker | as if | asthma paralysis weariness | -, -, - | 0%, 100% |
| `X:5712` | Depthswalker | as if | addiction asthma clumsiness paralysis weariness | -, -, - | 0%, 100% |
| `X:5925` | Depthswalker | as if | addiction asthma hypersomnia paralysis weariness | -, -, - | 0%, 100% |
| `Z5:203` | Alchemist | as if | asthma paralysis weariness | -, -, - | 0%, 96% |
| `Z5:539` | Alchemist | as if | asthma stupidity weariness | -, -, - | 0%, 100% |
| `Z5:940` | Alchemist | as if | addiction asthma fratricide hypersomnia stupidity weariness | -, -, - | 0%, 97% |
| `Z5:1124` | Alchemist | as if | asthma clumsiness fratricide hypersomnia paralysis weariness | -, -, - | 0%, 100% |
| `Z5:1694` | Alchemist | as if | asthma fratricide paralysis weariness | -, -, - | 0%, 100% |
| `Z5:1930` | Alchemist | as if | addiction asthma fratricide nausea paralysis weariness | -, -, - | 0%, 100% |
| `Z5:4121` | Alchemist | as if | asthma paralysis weariness | -, -, 15.9 | 64%, 100% |
| `Z5:4316` | Alchemist | as if | asthma fratricide paralysis weariness | 18.2, -, 10.6 | 98%, 100% |
| `Z5:5081` | Alchemist | as if | addiction asthma fratricide hypochondria impatience lethargy nausea paralysis vertigo weariness | 4.7, -, 0.0 | 100%, 100% |
| `g:1148` | Monk | yes | asthma clumsiness darkshade fratricide generosity paralysis weariness | -, -, - | 0%, 100% |
| `g:2020` | Monk | yes | asthma clumsiness darkshade fratricide generosity paralysis weariness | -, -, - | 0%, 100% |

A board with FITNESS "as if" comes from a logger with another class cure. It counts only in S3 and the softlock column.

## The model

| Input | Value | Source |
|---|---|---|
| Eat, smoke, short salve, focus, tree | 1.50, 1.48, 0.92, 2.43, 13.96 s | `clocks.json`, with the measured noise |
| Priority | the package's table | `ataxia_defaultCuringPrios()`, the real function |
| Herb for each affliction | the first eat option | `afflictions.json` |
| DSTAB | two venoms | MEASURED: 1 or 2 new afflictions in most packets |
| FLAY of a shield | one venom, same gap | MEASURED: `azbErKcK`, the shield line and the whip are one attack |
| Shield cost | the logger's own | Claes 4.00, Elmer and Nikita 3.40, ours 2.89 (`Equilibrium used`) |

## What this stage cannot say

- **The attacker is strong, not proven worst.** It is the strongest of three fixed orders.
- **It has few suppliers:** DSTAB, FLAY, one timed impatience, and the hypochondria chain. It has no BITE, no hypnosis snap, no fratricide relapse and no limb damage.
- **No rebounding and no parry.** Both favour the attacker here.
- **Few boards.** The verdicts rest on 10 boards from two loggers (`az`, `g`), who fought the same two Serpents.
- **No balance or mana economy.** The victim does nothing but cure. Holding offence is not tested, and a shield has no cost here except equilibrium and a late FITNESS.
- **Margins under 0.5 s are not resolved** (foundations.md, item 13). A result that depends on one is not a result.

