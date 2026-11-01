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

1. Type `CONFIG`.
2. Look for an option that shows balance or equilibrium used. Other players' logs print `Balance used: 2.1s.`
3. If you find it, turn it on.

## B. Does FITNESS need equilibrium?

The shield tattoo spends equilibrium and not balance, so FITNESS is tried with balance up and equilibrium down.

```
touch shield;fitness
```

If the reply says you do not have asthma, this test is void. Repeat it in test E with asthma up.

Then spend both, and try again:

1. Spend balance with any attack on a denizen.
2. In the same second, run the line above.

**What to keep:** the reply, for example `You must regain equilibrium first.` or `fitness was added to your ... queue.`

**This decides:** whether a shield with asthma up delays our lock breaker (CONFLICTS #50).

## C. Does a queued alias read its text when it fires?

1. Set the alias, then wait a second:

```
setalias lvprobe say one
```

2. Queue it, and rewrite it before equilibrium returns:

```
touch shield;queue addclear free lvprobe;setalias lvprobe say two
```

**Expected:** when equilibrium returns, you say "two". If you say "one", the alias method fails.

3. Test several commands in one alias:

```
setalias lvprobe say one/say two/say three
touch shield;queue addclear free lvprobe
```

**Expected:** you say all three, in order.

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

1. **FITNESS.** With asthma up and no weariness, run `touch shield;fitness`. Keep the reply. Do this only if test B was void.
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
