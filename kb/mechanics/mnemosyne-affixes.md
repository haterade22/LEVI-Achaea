---
topic: mnemosyne-affixes
confidence: mixed (tagged per claim)
sources:
  - kb/raw/live/mnemosyne-tashla-prey_2026-11-10.txt
  - the user's Mnemosyne history file (run 223 affix list, read live through Mudlet MCP, 2026-11-10)
code:
  - src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/009_Swarm_Tactics.lua
  - src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua
  - src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/007_History.lua
last_verified: 2026-11-10
---

# Mnemosyne affixes that change a fight

A wade's affixes are recorded in the history file (`M.history.affixes`, one row per affix with its
`run`). `M.hasAffix(name)` (`007_History.lua`:300) matches a SUBSTRING of this run's affix names.
This page holds the affixes whose effect on a fight we have seen in a log.

## Facts

### Prey: "All denizens are trackers and will chase should you flee."
- In the 2026-11-10 death, a tash'la warrior and a tash'la interceptor followed our leap. The leap
  landed at 12:47:15.977 and both arrived by 12:47:16.541, about 0.6 s later.
- So a ground retreat (leap, tumble, walk) gains nothing. It costs a balance, and the escape holds
  the attacks while it runs.
- **Confidence:** CONFIRMED for this one pair of denizens (one log). Roll Hide and Terror of the
  Skies shed pursuers by their boon text; under Prey this is UNTESTED.
- **Code (v4.7.486):** `S._preyTracks()` (009:567) matches the affix name WHOLE, for this run only,
  and returns false with Roll Hide or Terror of the Skies. `S._retreatBlock` (009:582) then refuses
  every ground retreat. The recovery hover is not a ground retreat and still flies.

### Sanguine Restoration: "Pools of blood shall heal nearby denizens."
- Room prose with a pool: `An ichorous pool of blood sprawls across the ground.`
- The heal, one line per denizen:
  `A tash'la warrior is shrouded by a crimson nimbus as the bloody pool roils with profane intent.`
- In the log the pool healed both denizens twice, 10 s apart (12:47:18.3 and 12:47:28.2). The log
  does not show how much it healed.
- The pool was already there when we leapt into the room. Its source (an earlier kill, or our own
  bleeding) is not known.
- **Confidence:** CONFIRMED lines (one log); the heal amount and the pool's source are UNKNOWN.
- **Code:** only the Monk battlerage reads this affix (Ripplestrike for Inhibit, basher/001). No code
  records pool rooms yet; the user chose not to build that on 2026-11-10.

### Meldscorned: "Denizens cause additional Shadowmancy afflictions on their attacks."
- Each tash'la warrior hit printed `Your own shadow betrays you, leaving your thoughts scattered and
  wan.`, and the next line gave one more affliction: `You feel your strength being leeched away.`,
  `Everything seems so pointless.` (depression), `A terrible sense of unease comes over you.`
  (hypochondria) or `Your sanity begins to escape you.` (`shm` on the prompt). After three of the
  eight hits the prompt also showed stupidity and paralysis (`stu par`).
- Stupidity replaced three of our commands with emotes: `You get down on one knee and serenade the
  world.`, `You pick your nose absently.` and `What do you want to eat?`.
- **Confidence:** CONFIRMED (one log).

### The tash'la pair, for scale
- Warrior: about 2,400-2,800 per hit (physical blunt); the elbow drop breaks a limb.
- Interceptor: about 1,200-2,400 per hit; the spear-butt hit breaks a leg, the chain throw makes us
  prone, the hair whip deals blunt and cutting together.
- One round from each about every 2.5-2.7 s, about 2,000 HP/s together.
- Our healing in the same window (Death's Demise held, so no death-cape life-steal): elixir sips of
  1,600-3,700 and potash of about 1,040, about 1,030 HP/s. The user gags sip lines, so a sip shows
  only as a health jump on the prompt.
- **Confidence:** CONFIRMED (one log), INFERRED for the sip amounts (prompt differences).

## What the death taught

The swarm's one retreat went into a Prey pursuit and a blood pool. After it, every exit was
refused, and `ataxiaBasher_canShield()` (`can(x)/002`:18) is false while any target-list denizen
is in the room and `noShieldBreak` does not name it, which in the tower is every fight. From 28%
to 15% health the only action left was another attack. **The last stand (v4.7.486,
basher/001:580-736)** shields in that case and holds the attacks until 70% health; see
`.claude/projects/basher/05-safety-systems.md`. **v4.7.490:** the v4.7.486 stand let the next
attack round delete its queued shield (two errant frost elementals, 2026-11-11,
`raw/live/mnemosyne-frost-elemental-laststand_2026-11-11.txt`). A stand now holds every round
from its first `touch shield`, clears the queue first, and gives up after 2 tries.
