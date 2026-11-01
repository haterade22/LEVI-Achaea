# Timing probes: one in-game session (step 2)

These tests replace guesses in `kb/mechanics/foundations.md` and `kb/CONFLICTS.md` with game replies. They take about
20 minutes. Tests A to D need a safe room and no partner. Test E needs a partner.

Each probe line below is one line to type into Mudlet. Mudlet splits `;`, so the commands go out in order.

## Before you start

1. Log in on your Monk (Shikudo), with package v4.7.469 or later.
2. Go to a safe room where nobody can attack you.
3. Run this command:

```
fightlog on probe
```

## A. Find the option that prints the true cost

**DONE (2026-11-01).** `CONFIG SEEBALANCES` prints the line (`kb/raw/live/seebalances_2026-11-01.txt`).

Keep it on. Tell me if a highlight or an attack echo looks wrong: 12 files act on "the next line", and this adds a line.
**To undo:** `config seebalances no`. Since v4.7.470, `aconfig seebalances on` sends it at every login. That setting is off by
default, so the game keeps what you set here.

**Still wanted:** the reply to `config universalafflictionmessages`. Its help text may say whether it shows a target's cures.

## B. Does FITNESS need equilibrium?

**DONE (2026-11-01). Yes.** With equilibrium down, FITNESS ran only when equilibrium returned, 3.3 s later. With no asthma, it
still spent 2.8 s of balance (`kb/raw/live/probes_2026-11-01.txt`).

## C. Does a queued alias read its text when it fires?

**Parts 1 and 3 DONE (2026-11-01). Yes.** You said "Two." In one alias, "One." came first, and all three replies came before
one prompt. Say-like commands have their own limit, so the second and third gave the same refusal, and their order cannot be
seen. What an off-balance attack inside an alias does is open, and the first alias fight answers it
(`kb/raw/live/probes_2026-11-01.txt`).

**Optional:** the long alias below. The longest alias seen in a log is 142 characters, and step 3 caps at 138 to be cautious.
Without this test, step 3 will not use a longer one.

4. Test a long alias:

```
setalias lvprobe say 012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345
touch shield;queue addclear free lvprobe
```

5. Remove the alias:

```
alias clear lvprobe
```

**This decides:** the round delivery fix in step 3.

## D. A game separator that Mudlet does not split

**Caution:** this changes a game setting. Do steps 1 to 3 together, and do not fight until step 3 is done.

1. Set the game's separator to `|`:

```
config commandseparator |
```

2. Try one queue line that holds two commands:

```
touch shield;queue addclear free say one|say two
```

**Expected if this works:** you say "one" and then "two" when equilibrium returns.

3. Set the separator back:

```
config commandseparator ;
```

**This decides:** whether a simpler delivery fix exists. It cannot change the round after it is queued, as the alias can.

## Capture the settings in force

```
kbcapture help aliases | curing priority list
```

Wait for it to finish. `kbcapture` shows progress.

## E. A spar against a partner who can give asthma and weariness

A Serpent, a Sentinel or a Shaman can give both. Ask the partner to keep the pressure steady for a few minutes.

```
fightlog on <partner>
```

1. **FITNESS lockout.** With no asthma, send `fitness`. Then, within 5 s, send it again with asthma up. Keep both replies.
   This shows whether a stray FITNESS starts the 10 s lockout. Skip it if the fight does not allow it.
2. **Contested aurum.** With asthma, weariness and clumsiness or sensitivity all up, send `curing prioaff asthma`. Note
   which affliction the next aurum cures. Repeat at least 5 times.
3. **Two prioaffs.** With asthma and weariness up, send `curing prioaff asthma` and then `curing prioaff weariness`.
   Keep both replies, and note which one the next aurum cures.

**This decides:** how far we can steer a cure inside one herb, and whether a second `prioaff` replaces the first.

## F. Two recordings at the current version

No log of ours is newer than v4.7.462.

1. **Control fight.** One normal fight as Shikudo, at least 2 minutes, with `fightlog on <partner>`.
2. **Bash log.** Run `fightlog on`, bash for about 5 minutes, and then run `fightlog off`.

## When you finish

1. Run this command:

```
fightlog off
```

2. Tell me that you are done. I import the logs and captures, and file each reply.

**If you skip a test,** the facts that depend on it stay marked ASSUMED, and only the steps that need them wait.
