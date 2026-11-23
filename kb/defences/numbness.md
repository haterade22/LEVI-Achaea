---
topic: numbness
confidence: mixed (tagged per claim)
sources:
  - kb/raw/abadmin/kaido_numbness_894.txt
  - kb/raw/live/kaido-numbness-cycles_2026-11-23.txt
code:
  - src_new/scripts/levi_ataxia/levi/ataxia/basher/016_Numb_Debt.lua
  - src_new/triggers/levi_ataxia/for_levi/leviticus/highlighting/060_Numb.lua
  - src_new/triggers/levi_ataxia/for_levi/leviticus/highlighting/074_Numb_Faded.lua
  - src_new/triggers/levi_ataxia/for_levi/leviticus/highlighting/075_Numb_Absorbed_Hit.lua
  - src_new/triggers/levi_ataxia/for_levi/leviticus/highlighting/076_Numb_Recovery.lua
last_verified: 2026-11-23
---

# NUMBNESS (Kaido NUMB)

A defence (its name is in the game's DEF list, [README.md](README.md)). The Monk gets it from
Kaido, ability 894. The Legend Deck can give it too ("for 10 seconds, you gain numbness defence",
`legend_deck/002_Legend_Deck_DB.lua`); that source has no log.

## What the game says (BASE)

`NUMB`, self, 3.00 seconds of equilibrium. "With a very clever method of concentration, you are now
able to numb yourself to damage received, at least temporarily. When the numbness wears off, all
the damage you would have taken, minus 40%, will be received in one blow."
**Source:** `kb/raw/abadmin/kaido_numbness_894.txt`. The text gives no duration and no recovery.

So numbness defers ALL the damage of a hit, and the 40% is taken off the total at the end. (Two of
our documents said "defers 40% of incoming damage" until 2026-11-23. That was wrong.)

## What we measured (OURS: Leviticus, Monk, 2026-11-23, a Mnemosyne run)

All figures are from one session of the user's live buffer. The filed rows are
`kb/raw/live/kaido-numbness-cycles_2026-11-23.txt`: two whole cycles, and one fade with a refusal.
Our equilibrium for NUMB printed as "Equilibrium used: 2.55s" (3.00 x 0.85, the Aldar Diadem).

| Fact | Reading | Cycles |
|---|---|---|
| Up line to fade line | 9.07 to 10.03 s | 24 |
| Fade line to ready line | 2.05 to 2.74 s | 14 |
| Up line to ready line | 11.34 to 12.59 s | 14 |
| Absorbed hits in one cycle | 3 to 12 | 28 |
| The blow at the fade | 1,400 to 11,036 health, of a 20,061 pool (7% to 55%) | 28 |
| The blow for each absorbed hit | 732 mean (115,601 health for 158 hits) | 28 |
| That figure against our mean typed hit before the cycle | 0.30 to 1.60, median 0.60 | 27 |

The median of 0.60 agrees with the AB text ("minus 40%"). One cycle alone is a poor reading: the
typed hits before it can come from other denizens.

### The lines

| Line | Meaning |
|---|---|
| `You grit your teeth and will your pain out of existence.` | NUMB is up (row 2 of the filed log) |
| `You smile as the blow falls painlessly on you.` | One hit was absorbed. One line for each hit. It follows the denizen's attack line (row 11) |
| `You cry out in agony as the effects of your numbness fade away and you feel your wounds once more.` | The fade: the blow lands now (row 200). 99 columns, so it fits one row |
| `You have recovered enough to numb your body once again.` | NUMB can be sent again (row 266) |
| `You may not numb again so soon.` | A NUMB sent between the fade and the ready line (row 760). Seen 11 times |

### What the game does not print

- **An absorbed hit has no figure.** No "Health lost: N (type)." line follows it: 0 typed lines
  inside 28 cycles, against 158 absorbed hits. The size of the debt is never shown.
- **The blow at the fade has no "Health lost:" line.** It shows only as a fall of health in
  Char.Vitals (the next prompt): 20041 -> 11450 at 11:15:04.
- **Bleeding is not deferred.** "Health lost: N (raw)." printed inside 14 of the first 24 cycles,
  17 to 290 health a line, and health fell by that amount at once.

### Health during a cycle

Health does not fall for a denizen's hit while numbness is up, and healing works as usual. In most
cycles health was back at its maximum before the fade. That is the danger: for about ten seconds
the health number shows a fight that goes well, and then up to half the pool goes in one prompt.

### Order of the fall of health and the fade line

In the cycle of 11:15:04 the package's damage alarm printed BEFORE the fade line, and that alarm
reads Char.Vitals. So the fall of health came first there. **Confidence:** one cycle; the code
does not depend on the order (`.claude/AGENTS.md`, "Do not depend on the order of GMCP and text").

## What the package does (v4.7.512)

- Highlights the up line (turquoise) and the fade line (`orange_red`), and echoes the blow:
  `NUMB WORE OFF: -8591 HP (20041 -> 11450, 42% of max) from 8 absorbed hits. Estimate was 7200.`
- Keeps the **numbness debt** (`basher/016_Numb_Debt.lua`): each absorbed hit adds an estimate,
  the basher's safeties and the swarm ladder read health minus the debt, and the fall of health at
  the fade is not counted as incoming damage a second time. The design is in
  `.claude/projects/basher/05-safety-systems.md` ("The numbness debt").
- Holds the Senseless Flurry keeper until the ready line (`ataxia_numbCooling`).

## Open

- Whether NUMB can be sent while numbness is up (to renew it). The keeper never tries.
- Whether a second NUMB resets the debt. The code keeps the debt.
- What else is not deferred, apart from bleeding. A typed line inside a cycle would show it.
- The Legend Deck's numbness: its up line, and whether it shares the recovery.
- Whether the refusal line costs equilibrium.
